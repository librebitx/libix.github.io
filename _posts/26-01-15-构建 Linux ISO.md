---
layout: default
title:   "构建 Linux ISO"
date:   2026-01-14
blog-label: Fun
---

# 构建 Linux Live CD

## 准备文件系统
### 安装工具
在你的宿主机上打开终端：
```
apt-get update
apt-get install -y \
    debootstrap squashfs-tools xorriso \
    grub-efi-amd64-bin grub-pc-bin mtools dosfstools qemu-system-x86 ovmf
```

### 创建工作目录
```
# 创建目录结构
mkdir -p /root/mylinux/chroot
mkdir -p /root/mylinux/image/live
mkdir -p /root/mylinux/image/boot/grub

cd /root/mylinux
```

### 拉取基础系统 (Debootstrap)
这一步会从 Debian 官网下载最核心的文件（约 300MB）
``` bash
# 这里的 bookworm 代表 Debian 12
debootstrap --arch=amd64 bookworm ./chroot https://mirrors.aliyun.com/debian/
```

*`debootstrap` 就像是一个超级解压工具，它把 Debian 系统解压到了 `./chroot` 文件夹里。现在这个文件夹里看起来就像是一个 C 盘。*

## 配置内核与环境

### 利用 `chroot` 进入新文件夹内部

```  bash
mkdir -p chroot/{dev,run,proc,sys}

cat > enter-chroot.sh <<EOF
#!/bin/bash
# 挂载必要接口，在新系统能工作前，它需要借用宿主机的硬件接口。
mount --bind /dev ./chroot/dev
mount --bind /run ./chroot/run
mount -t proc /proc ./chroot/proc
mount -t sysfs /sys ./chroot/sys

# 进入 Chroot
echo "进入定制环境，请进行操作。完成后输入 'exit' 退出。"
chroot ./chroot

# 退出后卸载接口，把借用的接口还回去。
umount -lf ./chroot/sys
umount -lf ./chroot/proc
umount -lf ./chroot/run
umount -lf ./chroot/dev
echo "已安全退出并卸载挂载点。"
EOF

chmod +x enter-chroot.sh
```
*注意看提示符：现在你的终端提示符应该变了。你现在是在 `./chroot` 这个文件夹里操作，就像是在另一台电脑里一样。*

### 初始化系统

```bash
bash enter-chroot.sh

# 设置主机名
echo "my-custom-os" > /etc/hostname

# 更新源
echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list

apt-get update

# 安装 Linux 内核、Live启动支持和网络工具
# 这一步非常关键，没有内核就无法启动
apt-get install -y --no-install-recommends \
    linux-image-amd64 \
    live-boot \
    systemd-sysv \
    network-manager \
    iputils-ping \
    vim \
    zstd \
    firmware-realtek 

# 设置 root 密码
echo "root: " | chpasswd

# 清理缓存
apt-get clean
rm -rf /var/lib/apt/lists/*

# 退出新系统，回到宿主机
exit
```

## 打包与引导
### 提取内核文件
把内核文件从系统文件夹里放到光盘的启动目录里。
```bash
# 提取最新的内核和 initrd 到 live 目录
cp ./chroot/boot/vmlinuz-* ./image/live/vmlinuz
cp ./chroot/boot/initrd.img-* ./image/live/initrd.img
```

### 压缩文件系统

将 `chroot` 目录压缩成只读的 `squashfs` 文件。

```bash
# 打包文件系统，排除 boot 目录
mksquashfs ./chroot ./image/live/filesystem.squashfs -comp xz -e boot
```

### 编写 GRUB 启动菜单

```bash
# 创建 grub.cfg 文件
cat > ./image/boot/grub/grub.cfg <<EOF
set default=0
set timeout=5

# 加载图形模块（可选，防止黑屏）
insmod efi_gop
insmod efi_uga
insmod font
if loadfont \${prefix}/fonts/unicode.pf2
then
    insmod gfxterm
    set gfxmode=auto
    set gfxpayload=keep
    terminal_output gfxterm
fi

menuentry "Start My Custom Linux" {
    # 这里非常关键：告诉 GRUB 内核在哪里
    linux /live/vmlinuz boot=live quiet
    initrd /live/initrd.img
}
EOF
```

## 生成 ISO
使用 grub-mkrescue 命令。这是一个超级强大的工具，它会自动帮你生成 EFI 分区文件 (efiboot.img)，自动把必要的 EFI 驱动打包进去，生成的 ISO 既能在 UEFI 电脑上跑，也能在老电脑上跑。

```
# 确保你在 /root/mylinux 目录下
grub-mkrescue -o mycustomlinux.iso ./image
```
### QEMU 快速测试

```
# 使用 QEMU 模拟器启动测试
qemu-system-x86_64 -m 8G -smp 2 -cdrom Downloads/mycustomlinux.iso -vga virtio -usb -device usb-tablet
# Ctrl + A 进入 QEMU 命令模式的前缀
# X 退出
```

![](/assest/DOB/image-20260115064252119.png)

### 写入 U 盘

```
ls -lh mycustomlinux.iso

# 请务必确认 /dev/sdb 是 U 盘
dd if=my*.iso of=/dev/sdb bs=4M status=progress && sync
```



## Live System 持久化（失败）

Live 系统将主要的操作系统文件 (`filesystem.squashfs`) 挂载为**只读**。它使用 **OverlayFS** 在内存（RAM）中创建一个临时可写层。重启后，内存中的修改就会消失。要启用持久化，我们需要在 U 盘上创建一个专门的分区，并告诉 Live 系统将它的可写层（Overlay）放在这个分区上，而不是内存中。

**注意：这个操作需要在你的 ISO 成功烧录到 U 盘后，在宿主机上对 U 盘进行操作。**

```bash
# 创建持久化分区
root@Debian:~# fdisk /dev/sdc

Welcome to fdisk (util-linux 2.41).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

GPT PMBR size mismatch (1341883 != 15728639) will be corrected by write.
The backup GPT table is not on the end of the device. This problem will be corrected by write.
The device contains 'iso9660' signature and it will be removed by a write command. See fdisk(8) man page and --wipe option for more details.

Command (m for help): n
Partition number (5-176, default 5): 
First sector (1341836-15728594, default 1343488): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (1343488-15728594, default 15726591): 

Created a new partition 5 of type 'Linux filesystem' and of size 6.9 GiB.

Command (m for help): t
Partition number (1-5, default 5): 
Partition type or alias (type L to list all): 83		# 输入 83 (代表 Linux filesystem)

Changed type of partition 'Linux filesystem' to 'Linux root verity (S390X)'.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.

root@Debian:~# lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda           8:0    1     0B  0 disk 
sdb           8:16   1     0B  0 disk 
sdc           8:32   1   7.5G  0 disk 
|-sdc1        8:33   1   122K  0 part 
|-sdc2        8:34   1   2.8M  0 part 
|-sdc3        8:35   1 651.9M  0 part 
|-sdc4        8:36   1   300K  0 part 
`-sdc5        8:37   1   6.9G  0 part 

# 格式化并命名分区
mkfs.ext4 -L persistence /dev/sdc5
### 卷标 persistence 是强制性的，Live 系统启动时会根据这个卷标来寻找持久化数据！

# 挂载新分区
mkdir /mnt/U
mount /dev/sdc5 /mnt/U
echo "/ union" | sudo tee /mnt/U/persistence.conf

# 配置完成后，必须安全卸载
umount /mnt/U
```

**`persistence.conf` 文件的内容：**

| **    配置行** | **  作用** | **解释**               |
| ------------- | ------------------ | ------------------------------------------------------------ |
| `/ union`     | 所有数据持久化 | 这是最常用的设置。它将整个根文件系统 (`/`) 启用持久化。你在 `/home`、`/etc`、`/usr` 等目录下的所有修改都将保存。 |
| `/home union` | 只保存用户数据 | 如果你只想保存文档和浏览器配置等，可以只保存 `/home` 目录。系统文件 (如 `/etc`) 不会持久化。 |
