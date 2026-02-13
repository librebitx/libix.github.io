---
title: "问题收集"
date: 2025-03-05T07:59:10+08:00
draft: false
tags:
  - "notes"
---

# RHEL9 

```bash
# 换阿里源
sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/subscription-manager.conf
yum remove subscription-manager -y

cat <<EOL> /etc/yum.repos.d/aliyun.repo
[BaseOS]
name=Aliyun BaseOS
baseurl=https://mirrors.aliyun.com/centos-stream/9-stream/BaseOS/x86_64/os/
gpgcheck=0
enabled=1

[AppStream]
name=Aliyun AppStream
baseurl=https://mirrors.aliyun.com/centos-stream/9-stream/AppStream/x86_64/os/
gpgcheck=0
enabled=1
EOL

yum clean all
yum makecache
```



## 重置 root 密码

```bash
### 进入 GRUB 引导菜单
# 重启系统，在启动界面出现时快速按下 Esc 或 e 键（不同硬件可能不同）进入 GRUB 菜单。
# 选择默认的启动条目（通常是第一个），按 e 键进入编辑模式。

### 修改内核启动参数
# 找到以 linux 开头的行（可能以 linuxefi 或 linux16 开头）。
# 在行尾追加以下参数（注意空格）
rd.break console=tty0
# 按 Ctrl+X 或 F10 继续启动

### 挂载文件系统并重置密码
# 系统将进入紧急模式（Emergency Shell），执行以下命令挂载根分区为可写
mount -o remount,rw /sysroot

# 切换根目录到系统环境
cd / chroot /sysroot

# 重置密码
passwd root 
# 输入两次新密码，成功后显示 "passwd: all authentication tokens updated successfully"

### 处理 SELinux 安全上下文
# RHEL 9 默认启用 SELinux，需更新文件标签
touch /.autorelabel

# 退出并重启
exit 
reboot -f
```

# Debian 12

```bash
# 换源
cat <<EOL> /etc/apt/sources.list
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
EOL

# 安装并配置 Sudo（推荐，为了长久使用）
su -
apt update
apt install sudo

# 把用户 libix 加入 sudo 组： Debian 的管理员组叫 sudo（RHEL 里叫 wheel）。
usermod -aG sudo libix
```



## 网络配置

**静态 ip**

```bash
# 修改 /etc/network/interfaces
root@debian:~# cat <<EOL> /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug enp2s0    
iface enp2s0 inet static
        address 192.168.0.150
        netmask 255.255.255.0
        gateway 192.168.0.1
        dns-nameservers 192.168.1.1 192.168.0.1
EOL
root@debian:~# systemctl restart networking
root@debian:~#
```

## 配置 tty 终端熄屏

```bash
libix@Debian:~$ sudo mkdir -p /etc/systemd/system/getty@.service.d
libix@Debian:~$ 
libix@Debian:~$ sudo cat /etc/systemd/system/getty@.service.d/override.conf
[Service]
# 指定终端类型，防止 setterm 报错
Environment=TERM=linux
# - 符号表示即使命令失败也不阻断服务启动
# powerdown 0 关闭 VESA 电源管理防止休眠冲突，blank 5 设置 5 分钟黑屏
ExecStartPost=-/bin/sh -c '/usr/bin/setterm -blank 5 -powersave off -powerdown 0 > /dev/%I'
libix@Debian:~$ 
libix@Debian:~$ 
libix@Debian:~$ sudo systemctl daemon-reload
libix@Debian:~$ sudo systemctl restart getty@tty{1..6}
libix@Debian:~$ 
```

## 安装软件代理

```bash
sudo apt -o Acquire::http::Proxy="http://127.0.0.1:7897/" \
-o Acquire::https::Proxy="http://127.0.0.1:7897/" \
install antigravity
```



# **CentOS**

## 模板

```bash
# 1. 清除网卡配置信息
cd /etc/sysconfig/network-scripts/
cat <<EOL> ifcfg-ens32           # 这里根据网卡名称更改
TYPE=Ethernet
BOOTPROTO=dhcp
NAME=ens32
DEVICE=ens32
ONBOOT=yes
EOL
cat ifcfg-ens32

# 2. 清除密钥信息
rm -rf /etc/ssh/ssh_host_*

# 3. 清除 machine id
cat /dev/null > /etc/machine-id
cat /etc/machine-id

# 6. 关闭防火墙及 selinux
setenforce 0
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
cat /etc/selinux/config | grep ^SELINUX=
systemctl stop firewalld ; systemctl disable firewalld

# 5. 关闭虚拟机
poweroff

# 记得不要再开启了，通过完整克隆即可发放新的虚拟机
```



## **CentOS 7.9**

```bash
# 本地源
mount /dev/cdrom /mnt
rm -rf /etc/yum.repos.d/*
cat <<EOL> /etc/yum.repos.d/local.repo
[local]
name=local
baseurl=file:///mnt
enable=1
gpgcheck=0
EOL

yum clean all
yum makecache
```

### 安装 Docker

```bash
yum install -y yum-utils
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker -v
```

### 安装图形界面

```bash
sudo yum groupinstall "GNOME Desktop" -y            # 安装 GNOME 桌面环境
sudo systemctl set-default graphical.target            # 设置图形界面为默认启动目标
sudo systemctl start graphical.target            # 启动图形界面服务
```

### 配置静态 ip

```bash
cat <<EOL> /etc/sysconfig/network-scripts/ifcfg-ens33           # 这里根据网卡名称更改
TYPE=Ethernet
BOOTPROTO=static
NAME=ens33
DEVICE=ens33
ONBOOT=yes

IPADDR=192.168.1.100
PREFIX=24
GATEWAY=192.168.1.1
DNS1=114.114.114.114
DNS2=8.8.8.8
EOL
cat /etc/sysconfig/network-scripts/ifcfg-ens33
```

## Centos 8

```bash
# 本地源
mount /dev/cdrom /mnt

mkdir /etc/yum.repos.d/bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/

cat <<EOF >/etc/yum.repos.d/abc.repo
[baseos]
name = baseos
baseurl = file:///mnt/BaseOS/
gpgcheck = 0

[app]
name = app
baseurl = file:///mnt/AppStream/
gpgcheck = 0
EOF

yum clean all
yum repolist all


yum install -y vim net-tools bash-completion yum-utils
```

# Ubuntu

## 模板

```bash
cat <<EOL> ubuntu.sh
#!/bin/bash
set -e        # 遇到错误立即停止

ufw disable

apt update
apt install -y vim net-tools lrzsz wget tree lsof tcpdump screen sysstat unzip iputils-ping
apt clean
rm -rf /var/lib/apt/lists/*

# 清 SSH key
rm -f /etc/ssh/ssh_host_*

# machine-id
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id

# 清理 Shell 历史和日志
cat /dev/null > /var/log/wtmp
cat /dev/null > /var/log/btmp

hostnamectl set-hostname localhost

poweroff
EOL
bash ubuntu.sh

# 每台虚拟机单独配置静态 IP
sudo rm -rf /etc/netplan/50-cloud-init.yaml
ls -l /etc/netplan/

sudo cat <<EOF> /etc/netplan/01-static.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens32:
      dhcp4: false
      addresses:
        - 192.168.0.10/24
      routes:
        - to: default
          via: 192.168.0.1
      nameservers:
        addresses:
          - 192.168.1.1
          - 192.168.0.1
EOF
ls -l /etc/netplan/
sudo netplan try
sudo netplan apply

sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg <<EOF
network: {config: disabled}
EOF

reboot
```

## **卸载 snap**	

```bash
sudo systemctl stop snapd
sudo apt purge snapd -y
sudo rm -rf /snap /var/snap /var/lib/snapd
```

# MacOS

## 配置终端永久代理

```bash
libix@bogon ~ % touch .zshrc
libix@bogon ~ % cat .zshrc
# Proxy Settings
export http_proxy="http://127.0.0.1:7897"
export https_proxy="http://127.0.0.1:7897"
export all_proxy="socks5://127.0.0.1:7897"
# 关键：排除本地和内网地址
export no_proxy="localhost,127.0.0.1,::1,192.168.*,10.*,*.local"
libix@bogon ~ % 
```



## 配置SSH免密

```bash
libix@libixs-MBP ~ % ssh-keygen -t ed25519 -C "MBP_to_Debian"
Generating public/private ed25519 key pair.
Enter file in which to save the key (/Users/libix/.ssh/id_ed25519): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /Users/libix/.ssh/id_ed25519
Your public key has been saved in /Users/libix/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:uY3loWXNefA6gPtGfnmT824zTeUBayfnm8gV2nhrf+U MBP_to_Debian
The key's randomart image is:
+--[ED25519 256]--+
|                 |
|             .   |
|            . o  |
|         o o B =.|
|        S * = @.+|
|         @.o = =+|
|        =oo +.++*|
|         .o o+=BE|
|         ... ..*O|
+----[SHA256]-----+
libix@libixs-MBP ~ % 
libix@libixs-MBP ~ % ssh-copy-id -i ~/.ssh/id_ed25519.pub libix@192.168.0.5
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/Users/libix/.ssh/id_ed25519.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
libix@192.168.0.5's password: 

Number of key(s) added:        1

Now try logging into the machine, with:   "ssh 'libix@192.168.0.5'"
and check to make sure that only the key(s) you wanted were added.

libix@libixs-MBP ~ % 
libix@libixs-MBP ~ % pwd
/Users/libix
libix@libixs-MBP ~ % cd .ssh
libix@libixs-MBP .ssh % ls -la
total 32
drwx------   6 libix  staff  192  2  8 17:34 .
drwxr-x---+ 27 libix  staff  864  2  8 17:30 ..
-rw-------   1 libix  staff  399  2  8 17:33 id_ed25519
-rw-r--r--   1 libix  staff   95  2  8 17:33 id_ed25519.pub
-rw-------   1 libix  staff  831  2  8 17:30 known_hosts
-rw-r--r--   1 libix  staff   93  2  8 17:30 known_hosts.old
libix@libixs-MBP .ssh % 
libix@libixs-MBP .ssh % cat config
Host debian                # 起别名，以后 ssh debian 就行
    HostName 192.168.0.5  # Debian 的 IP
    User libix       # Debian 的用户名
    Port 22
    IdentityFile ~/.ssh/id_ed25519
libix@libixs-MBP .ssh % 
libix@libixs-MBP .ssh % ssh debian
Linux Debian 6.12.63+deb13-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.12.63-1 (2025-12-30) x86_64
 
Last login: Sun Feb  8 17:30:27 2026 from 192.168.0.3
libix@Debian:~$ 
libix@Debian:~$ exit
logout
Connection to 192.168.0.5 closed.
libix@libixs-MBP .ssh %
```



# 环境配置

## **硬盘分区**

刚安装的新硬盘被 Linux 系统识别后，并不会立即出现在你的文件系统目录树中任意一个你能直接访问的文件夹里。

```bash
### 查看新硬盘的设备名

# 确认系统是否识别了硬盘以及它的设备名。
root@192:~# lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda      8:0    0  59.6G  0 disk
|-sda1   8:1    0  58.7G  0 part /
|-sda2   8:2    0     1K  0 part
`-sda5   8:5    0   975M  0 part [SWAP]
sdb      8:16   1 465.8G  0 disk
`-sdb1   8:17   1 465.8G  0 part
sdc      8:32   1 465.8G  0 disk            # 这就是新硬盘，没有分区和挂载点
root@192:~#
# 从命令输出中，找到你的新硬盘。它通常显示为 sdb、sdc 等（sd 后按字母顺序递增），并且没有相关的分区和挂载点信息。
# 新硬盘必须挂载到目录树中的一个目录（这个目录称为挂载点）上，才能通过该目录访问。

### 为硬盘分区和创建文件系统

# fdisk 直接操作的是磁盘的分区表（如 MBR/GPT），而不是分区内部的文件系统或子分区
root@192:~# fdisk /dev/sdc

Welcome to fdisk (util-linux 2.38.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS (MBR) disklabel with disk identifier 0x65126148.

Command (m for help): n            # 新建分区
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p):

Using default response p.
Partition number (1-4, default 1):
First sector (2048-976773167, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-976773167, default 976773167):    # 这里输入该分区的大小，回车默认全部

Created a new partition 1 of type 'Linux' and of size 465.8 GiB.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.

root@192:~#

root@192:~# lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda      8:0    0  59.6G  0 disk
|-sda1   8:1    0  58.7G  0 part /
|-sda2   8:2    0     1K  0 part
`-sda5   8:5    0   975M  0 part [SWAP]
sdb      8:16   1 465.8G  0 disk
`-sdb1   8:17   1 465.8G  0 part
sdc      8:32   1 465.8G  0 disk
`-sdc1   8:33   1 465.8G  0 part            # 这里可以看到 sdc1 分区
root@192:~#

### 创建文件系统
root@192:~# mkfs.ext4 /dev/sdc1
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 122096390 4k blocks and 30531584 inodes
Filesystem UUID: 41b7efb0-9513-4466-a8fb-b71958a32c1a
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968,
        102400000

Allocating group tables: done
Writing inode tables: done
Creating journal (262144 blocks): done
Writing superblocks and filesystem accounting information: done

root@192:~#
# 此操作会清除该分区上所有数据！

### 创建挂载点：挂载点就是一个普通的空目录。通常可以在 /mnt 或 /media 下创建
root@192:~# mkdir -p /mnt/disk-02

### 挂载硬盘：将硬盘分区挂载到刚刚创建的目录
root@192:~# mount /dev/sdc1 /mnt/disk-02
mount: (hint) your fstab has been modified, but systemd still uses
       the old version; use 'systemctl daemon-reload' to reload.
root@192:~#

### 验证挂载
root@192:~# df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            3.8G     0  3.8G   0% /dev
tmpfs           771M  752K  771M   1% /run
/dev/sda1        58G  2.5G   53G   5% /
tmpfs           3.8G     0  3.8G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           771M     0  771M   0% /run/user/0
/dev/sdc1       458G   28K  435G   1% /mnt/disk-02
root@192:~#
```

## 自动挂载

```bash
### 设置开机自动挂载
# 手动挂载的硬盘在重启后会失效。如需开机自动挂载，需编辑 /etc/fstab 文件
## 获取分区的 UUID（推荐使用UUID而非设备名，更稳定）
root@192:~# blkid /dev/sdc1
/dev/sdc1: UUID="41b7efb0-9513-4466-a8fb-b71958a32c1a" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="65126148-01"
root@192:~#
root@192:~# ls /dev/disk/by-uuid/
41b7efb0-9513-4466-a8fb-b71958a32c1a  51f48aa2-9e13-4ae9-a13b-b9b9723ee8a0  dd21c31c-48d0-4ab9-b273-64fb033c6ac4  df9baabb-96f4-4450-b700-08bbc1857091
root@192:~#

## 编辑 /etc/fstab
root@192:~# echo "/dev/disk/by-uuid/41b7efb0-9513-4466-a8fb-b71958a32c1a /mnt/disk-02 ext4 defaults 0 3" >> /etc/fstab
root@192:~# cat /etc/fstab
UUID=51f48aa2-9e13-4ae9-a13b-b9b9723ee8a0 /               ext4    errors=remount-ro 0       1
UUID=dd21c31c-48d0-4ab9-b273-64fb033c6ac4 none            swap    sw              0       0
UUID=df9baabb-96f4-4450-b700-08bbc1857091 /mnt/disk-01    ext4    defaults        0       2
/dev/disk/by-uuid/41b7efb0-9513-4466-a8fb-b71958a32c1a /mnt/disk-02 ext4 defaults 0 3
root@192:~#
## 测试配置
root@ubuntu:/# mount -a
# 如果没报错，说明配置正确，下次开机就会自动挂载
```



> UUID 能保证唯一性，无需担心两个不同的分区拥有相同的 UUID ; UUID 是绑定到硬盘分区上的文件系统的，而不是与整个物理硬盘的硬件本身永久绑定；
>
> 系统重启、插拔硬盘、更换主板或接口顺序，UUID 均保持不变；格式化分区、更改文件系统、克隆分区/硬盘、手动修改才会改变 UUID 值
>
> blkid -s UUID -o value /dev/vg01/lv01		# 一条命令获取 UUID 值

## 定时任务

```bash
root@ubuntu:~# cat /root/copy.sh
#!/bin/bash
/bin/cp -auv /mnt/disk_sdb/* /mnt/disk_sdc
echo "Copy sucess!"
root@ubuntu:~#
root@ubuntu:~# crontab -e -u root

root@ubuntu:~# crontab -l -u root

* * * * * /root/copy.sh >> /root/copy.log 2>&1

root@ubuntu:~#
```

## 服务配置

### Samba

指定用户可以通过 Samba 访问共享目录并具有写权限，而普通用户依然是只读或 guest 访问

```bash
root@debian:~# cat <<EOL> /etc/samba/smb.conf
[global]
   # 基本信息
   workgroup = WORKGROUP
   server string = Samba Server %v

   # 强制使用现代 SMB 协议
   server min protocol = SMB2
   server max protocol = SMB3

   # 日志设置
   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file

   # 密码和访问设置
   map to guest = Bad User
   usershare allow guests = yes
   encrypt passwords = yes
   obey pam restrictions = yes
   unix password sync = yes
   pam password change = yes

[Video]
   comment = Video Share
   path = /mnt/disk-01
   browseable = yes
   read only = yes
   guest ok = yes
   write list = libix
EOL  
root@debian:~#

root@debian:~# smbpasswd -a libix
root@debian:~# smbpasswd -e libix
# -a ：Add（添加用户到 Samba 数据库）；将指定系统用户添加到 Samba 用户数据库中
# -e ：Enable（启用 Samba 用户）；启用之前添加的 Samba 用户；如果不启用，该用户即使在数据库里也无法登录 Samba
# 先 -a 添加，再 -e 启用

sudo chown -R libix:libix /mnt/disk

# -------------不推荐，风险较高--------------
# 把 libix 加入 root 组
root@debian:~# usermod -aG root libix
-a → append（追加，不会把用户从其他组里移除）
-G → 指定附加组

# 使 root 组可以读写和执行共享目录
root@debian:~# chmod -R 775 /mnt/disk-01/*
root@debian:~# ls /mnt/ -l
total 12
drwxrwxr-x 6 root root 4096 Sep 11 23:38 disk-01
drwxr-xr-x 2 root root 4096 Sep 10 00:44 disk-02

# 此时 root 组中的用户就可以上传和删除文件了

```

### Timeshift

```bash
### 安装 Timeshift
root@debian:~# apt update
root@debian:~# apt install timeshift

### 创建快照，在命令行里指定快照存放位置
root@debian:~# timeshift --create --comments "snapshot $(date +%F-%H%M)" --snapshot-device /dev/sdc1
'
--create 表示创建一个新的快照。
--comments "snapshot $(date +%F-%H%M)"    # 给快照加备注
    $(date +%F-%H%M) 会在命令执行时插入系统时间
        %F = 年-月-日
        %H%M = 小时分钟
--snapshot-device /dev/sdc1    # 指定快照存放的位置
'

# 列出已有快照：
root@debian:~# timeshift --list

### 恢复快照
root@debian:~# timeshift --restore
# 会交互式选择你想恢复的快照

### 删除单个快照
root@debian:~# timeshift --delete --snapshot '2025-09-11_23-50-00'
```

## NFS

```BASH
libix@Debian:~$ sudo mkdir -p /mnt/nfs
libix@Debian:~$ 
libix@Debian:~$ sudo chown -R nobody:nogroup /mnt/nfs/
libix@Debian:~$ sudo chmod 777 /mnt/nfs/
libix@Debian:~$ sudo cat /etc/exports 
/mnt/nfs 192.168.0.0/24(rw,sync,all_squash,anonuid=65534,anongid=65534,no_subtree_check,insecure)
libix@Debian:~$
libix@Debian:~$ sudo exportfs -arv
exporting 192.168.0.0/24:/mnt/nfs
libix@Debian:~$ 
```

# 监控脚本

```bash
# ubuntu 官方
# 1. 先禁用所有欢迎脚本 (chmod -x)
chmod -x /etc/update-motd.d/*

# 只启用系统信息脚本 (chmod +x)
chmod +x /etc/update-motd.d/50-landscape-sysinfo

# 彻底删除那个法律免责声明文件
sudo rm -f /etc/legal

root@node2:~# /etc/update-motd.d/50-landscape-sysinfo

 System information as of Sun Dec 21 10:12:49 PM UTC 2025

  System load:  0.31               Processes:              279
  Usage of /:   42.5% of 17.83GB   Users logged in:        1
  Memory usage: 37%                IPv4 address for ens32: 192.168.0.12    
  Swap usage:   0%
root@node2:~# 
```

# 工具使用

### SCP

scp（Secure Copy Protocol）是通过 SSH 加密进行文件传输的命令行工具，支持本地与远程主机之间的文件上传和下载。

```bash
# 从本地复制到远程
scp /本地/文件 user@remote_ip:/远程/目录/            # 复制文件到远程主机的指定目录
scp -r /本地/目录 user@remote_ip:/远程/路径/            # 复制目录（递归 -r）

# 从远程复制到本地
scp user@remote_ip:/远程/文件 /本地/目录/            # 下载远程文件到本地
scp -r user@remote_ip:/远程/目录 /本地/路径/            # 下载远程目录（递归）

# 远程主机之间复制
scp user1@host1:/文件 user2@host2:/目标路径            # 通过本地中转（需两次验证）
```

### Vim

```bash
yy + p            # 复制光标所在行，在光标下方粘贴
dd             # 剪切光标所在行
3dd            # 删除当前行 + 下面 2 行

# 给 10 到 20 行开头加 #
:10,20s/^/# /
```

### 安装软件包

```bash
# 安装 RPM 包
rpm --checksig your-package.rpm        # 检查 RPM 文件的完整性
rpm -i your-package.rpm        # 安装
rpm -q your-package        # 检验安装

# 安装 DEB 包
sudo dpkg -i install xxx.deb

apt install xxx.deb
```

### 解压文件

```bash
# .tar.xz 格式
tar -xvf file.tar.xz

x → extract 解压
v → verbose 显示过程（可省略）
f → file 后跟文件名

# .rar 格式
### 安装 unrar 工具
# Ubuntu/Debian 系：
sudo apt update && sudo apt install unrar

# CentOS/RHEL/Fedora：
sudo yum install unrar

# 安装完成后，使用以下命令解压：
unrar x 文件名.rar            # 解压到当前目录
# x 选项会保留压缩包中的目录结构。
unrar x 文件名.rar /目标路径/            # 解压到指定目录
```

# **常用命令**

## **查看系统信息**

### **Linux 硬件信息**

\# 查看系统版本信息 cat /etc/os-release cat /etc/centos-release        # 系统的具体版本信息 uname -r        # 显示内核版本 # 主板信息 dmidecode | grep -i 'serial number' # cpu 信息 1. cat /proc/cpuinfo 2. dmesg | grep -i 'cpu' # 硬盘信息 fdisk -l            # 查看分区情况 df -h            # 查看大小情况 du -h            # 查看使用情况 dmesdg | grep sda            # 查看具体的硬盘设备 # 内存信息 1. cat /proc/meminfo 2. dmesg | grep mem 3. free -m 4. vmstat 5. dmidecode | grep -i mem # 网卡信息 1. demsg | grep -i 'eth' 2. lspci | grep -i 'eth'

### **所有监听端口 (TCP & UDP) 并显示进程信息**

sudo ss -tulnp -t: 显示 TCP 端口 -u: 显示 UDP 端口 -l: 仅显示监听状态的端口 -n: 不解析服务名称，直接显示端口号 -p: 显示关联的进程信息 (PID 和程序名)

### **目标节点开放了哪些端口**

telnet （需要安装）只能检查 tcp 端口

telnet <目标IP> <端口号>

如果端口开放：会显示空白屏幕或闪退

如果端口关闭：提示 无法打开连接

Nmap 可以同时检查目标节点开放的 TCP 和 UDP 端口

### 查找目标文件

场景：我现在想查找 Linux 系统中的某一个文件

find / -type f -name "kwrt-*.img" -ls 2>/dev/null /    表示从根目录开始搜索 -type f    表示只查找文件（不包括目录） -name "kwrt-*.img"    指定文件名模式 -ls    查看文件详细信息 2>/dev/null    将错误信息重定向到空设备，避免权限不足的提示干扰

### 当前正在运行的服务

systemctl list-units --type=service --state=running

### 所有已安装的服务及状态

service --status-all

带 [ + ] 表示正在运行

带 [ - ] 表示已停止

带 [ ? ] 表示无法确定（不兼容 systemd 的老脚本）

### 进程

如果只是想看后台运行的守护进程，可以用：

ps aux | grep daemon 或者更广泛的： ps -ef

### 用户组

查看系统所有用户组

cat /etc/group

查看某个用户（例如 libix）属于哪些组

groups libix id libix

## sed

```bash
# 一次性删除配置文件中所有 # 和 ; 开头的注释行，并直接修改原文件，同时保留空行和有效配置
sudo cp <filename> <filename>.bak sudo sed -i '/^\s*[#;]/d' <filename>
```

# PXE

```bash
apt update
apt install dnsmasq -y
mkdir -p /srv/tftp
chmod -R 755 /srv/tftp
cd /srv/tftp
# 下载适用于 amd64 架构的 Debian 12 (Bookworm) netboot 包
wget https://ftp.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/netboot.tar.gz
tar -xzvf netboot.tar.gz
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
vi /etc/dnsmasq.conf
systemctl restart dnsmasq ; systemctl status dnsmasq
```



# 科学上网

## 安装 Clash Verge

https://github.com/clash-verge-rev/clash-verge-rev

## Centos 7.9 配置 Xray

```bash
# 下载并运行 Xray 安装脚本
sudo bash -c "$(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)" @ install --beta

cat <<EOL> /usr/local/etc/xray/config.json
{
  "log": {
    "loglevel": "warning"
  },
  "dns": {
    "hosts": {
      "dns.google": "8.8.8.8",
      "proxy.example.com": "127.0.0.1"
    },
    "servers": [
      {
        "address": "1.1.1.1",
        "skipFallback": true,
        "domains": [
          "domain:googleapis.cn",
          "domain:gstatic.com"
        ]
      },
      {
        "address": "223.5.5.5",
        "skipFallback": true,
        "domains": [
          "geosite:cn"
        ],
        "expectIPs": [
          "geoip:cn"
        ]
      },
      "1.1.1.1",
      "8.8.8.8",
      "https://dns.google/dns-query"
    ]
  },
  "inbounds": [
    {
      "tag": "socks",
      "port": 10808,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ],
        "routeOnly": false
      },
      "settings": {
        "auth": "noauth",
        "udp": true,
        "allowTransparent": false
      }
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "216.24.189.26",
            "port": 443,
            "users": [
              {
                "id": "3e70fa55-14f3-415b-bff8-f41a5430c7f6",
                "email": "t@t.tt",
                "security": "auto",
                "encryption": "none",
                "flow": "xtls-rprx-vision"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "serverName": "defineabc.com",
          "fingerprint": "chrome",
          "show": false,
          "publicKey": "R2gKMF0Tetlnesc1pPkZH9NaOeehw-f5_U9JKG_cLjU",
          "shortId": "",
          "spiderX": ""
        }
      },
      "mux": {
        "enabled": false,
        "concurrency": -1
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api"
      },
      {
        "type": "field",
        "outboundTag": "proxy",
        "domain": [
          "domain:googleapis.cn",
          "domain:gstatic.com"
        ]
      },
      {
        "type": "field",
        "port": "443",
        "network": "udp",
        "outboundTag": "block"
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "geoip:private"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "geosite:private"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "223.5.5.5",
          "223.6.6.6",
          "2400:3200::1",
          "2400:3200:baba::1",
          "119.29.29.29",
          "1.12.12.12",
          "120.53.53.53",
          "2402:4e00::",
          "2402:4e00:1::",
          "180.76.76.76",
          "2400:da00::6666",
          "114.114.114.114",
          "114.114.115.115",
          "114.114.114.119",
          "114.114.115.119",
          "114.114.114.110",
          "114.114.115.110",
          "180.184.1.1",
          "180.184.2.2",
          "101.226.4.6",
          "218.30.118.6",
          "123.125.81.6",
          "140.207.198.6",
          "1.2.4.8",
          "210.2.4.8",
          "52.80.66.66",
          "117.50.22.22",
          "2400:7fc0:849e:200::4",
          "2404:c2c0:85d8:901::4",
          "117.50.10.10",
          "52.80.52.52",
          "2400:7fc0:849e:200::8",
          "2404:c2c0:85d8:901::8",
          "117.50.60.30",
          "52.80.60.30"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "domain:alidns.com",
          "domain:doh.pub",
          "domain:dot.pub",
          "domain:360.cn",
          "domain:onedns.net"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "geoip:cn"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "geosite:cn"
        ]
      }
    ]
  }
}
EOL

systemctl start xray
systemctl status xray
systemctl enable xray

# 查看实时日志
journalctl -u xray -f

# 创建代理配置文件
cat <<EOL> /etc/profile.d/xray_proxy.sh
export ALL_PROXY="socks5://127.0.0.1:10808"
export http_proxy="http://127.0.0.1:10808"
export https_proxy="http://127.0.0.1:10808"
export no_proxy="localhost,127.0.0.1,*.internal.com"
EOL
# 刷新配置
source /etc/profile

# 临时配置命令行代理
curl -v -x socks5h://127.0.0.1:10808 https://www.youtube.com/

```

## 将服务器配置为代理服务器

```bash
修改 Xray 配置文件 /usr/local/etc/xray/config.json
修改 inbounds 部分的 listen 地址：将 listen": "127.0.0.1" 改为 listen": "0.0.0.0"。
0.0.0.0 意味着 Xray 会监听服务器上所有的网络接口。


配置代理客户端：
在代理客户端应用中，创建一个新的代理配置：
协议 (Protocol)： 选择 SOCKS5。
地址 (Address/Server)： 填写你 CentOS 服务器的 公网 IP 地址。
端口 (Port)： 填写 10808。
认证 (Authentication)： 你的 Xray 配置中 auth 是 noauth，所以不需要填写用户名和密码。'
```

## 配置系统代理

```bash
echo '
export http_proxy=http://192.168.0.5:7897
export https_proxy=http://192.168.0.5:7897
export all_proxy=socks5://192.168.0.5:7897

export no_proxy="localhost,127.0.0.1,::1"
' >> ~/.bashrc

source .bashrc
```



# NAS

## 配置自动备份

```bash
root@Debian-Server:~# ls
backup.log  backup.sh  timeshift

root@Debian-Server:~# cat <<EOL> backup.sh
#!/bin/bash
echo "$(date '+[%Y-%m-%d %H:%M:%S]') - Backup task started."
/bin/cp -auv /mnt/fun-share/life/* /mnt/resource-share/life/
/bin/cp -auv /mnt/resource-share/life/* /mnt/fun-share/life/
echo "$(date '+[%Y-%m-%d %H:%M:%S]') - Backup success!"
EOL

root@Debian-Server:~# crontab -u root -l
*/10 * * * * /root/backup.sh >> /root/backup.log 2>&1


root@Debian-Server:~# cat samba.sh
#!/bin/bash

SERVER="192.168.1.100"
USER="libix"
PASS="redhat"   # 这里填你的真实密码，或者用凭证文件更安全

ping $SERVER -c 4

# 挂载点
MNT_FUN="$HOME/$SERVER/fun"
MNT_RES="$HOME/$SERVER/resource"

# 创建目录（如果不存在）
mkdir -p "$MNT_FUN" "$MNT_RES"

# 挂载共享
smbclient -L $SERVER -U $USER%$PASS --option='client min protocol=SMB2' --option='client max protocol=SMB3'

sudo mount -t cifs "//$SERVER/fun" "$MNT_FUN" -o username=$USER,password=$PASS,vers=3.0,uid=$(id -u),gid=$(id -g)
sudo mount -t cifs "//$SERVER/resource" "$MNT_RES" -o username=$USER,password=$PASS,vers=3.0,uid=$(id -u),gid=$(id -g)

echo "
Samba shares mounted:
  fun      -> $MNT_FUN
  resource -> $MNT_RES"

ssh root@192.168.1.100

sudo umount "//$SERVER/fun" "$MNT_FUN"
sudo umount "//$SERVER/resource" "$MNT_RES"
 
echo "
-------------------------------------------------------------------------------------------------------------------------------------------
smbclient -L 192.168.1.100 -U libix%redhat --option='client min protocol=SMB2' --option='client max protocol=SMB3'		
																
sudo mount -t cifs //192.168.1.100/fun /home/libix/192.168.1.100/fun -o username=libix,password=redhat,vers=3.0,uid=1000,gid=1000
sudo mount -t cifs //192.168.1.100/resource /home/libix/192.168.1.100/fun -o username=libix,password=redhat,vers=3.0,uid=1000,gid=1000
																					
sudo umount //192.168.1.100/fun /home/libix/192.168.1.100/fun
sudo umount //192.168.1.100/resource /home/libix/192.168.1.100/resource
------------------------------------------------------------------------------------------------------------------------------------------"

echo "Samba off"
```

# 云计算

## 四种部署模式

### 公共云 (Public Cloud)

*   **定义：** 公共云是由第三方云服务提供商（如AWS、Azure、Google Cloud等）拥有和运营的云基础设施。这些资源通过互联网向公众开放，并以按需付费的方式提供给多个客户共享使用。
*   **特点：**
    *   **多租户（Multi-tenancy）：** 多个用户（租户）共享相同的物理硬件、存储和网络设备，但在逻辑上是隔离的。
    *   **按需付费（Pay-as-you-go）：** 客户只需为他们实际使用的资源付费，无需前期投资。
    *   **高可扩展性（High Scalability）：** 资源几乎是无限的，可以根据需求快速扩展或缩减。
    *   **无需管理（No Management）：** 服务提供商负责所有底层基础设施的维护、更新和安全。
*   **优点：**
    *   **成本效益高：** 无需前期硬件投资，降低运营成本。
    *   **弹性伸缩：** 轻松应对流量高峰或低谷，快速调整资源。
    *   **易于部署：** 快速启动和部署应用。
    *   **全球覆盖：** 数据中心遍布全球，提供低延迟服务。
*   **缺点：**
    *   **控制力较弱：** 客户对底层基础设施的控制和可见性有限。
    *   **潜在的安全和合规问题：** 对于高度敏感的数据和严格的合规要求，可能存在顾虑。
    *   **“邻居噪音”：** 共享资源可能在极端情况下影响性能。
*   **适用场景：** 网站托管、开发测试环境、非敏感数据存储、弹性工作负载。

---

### 私有云 (Private Cloud)

*   **定义：** 私有云是专门为一个组织构建和运营的云基础设施。它可以位于企业内部的数据中心（本地私有云）或由第三方托管和管理（托管私有云），但资源是完全专属于该组织的。
*   **特点：**
    *   **单租户（Single-tenancy）：** 基础设施完全由一个组织独享。
    *   **高控制力：** 组织对云环境拥有完全的控制权，包括硬件、软件、网络和安全策略。
    *   **高安全性与合规性：** 可以根据特定需求定制安全措施和满足严格的合规标准。
*   **优点：**
    *   **安全性极高：** 数据和应用隔离，可以部署更严格的安全控制。
    *   **满足合规性：** 适用于受严格法规（如GDPR、HIPAA）监管的行业。
    *   **高度定制化：** 根据特定业务需求定制云环境。
    *   **更好的性能预测：** 无需担心共享资源的性能波动。
*   **缺点：**
    *   **成本较高：** 需要大量前期投资购买硬件和软件，以及持续的维护和管理成本。
    *   **管理复杂性：** 需要专业的IT团队进行部署、维护和运营。
    *   **扩展性有限：** 相对于公共云，扩展能力受限于自身硬件和预算。
*   **适用场景：** 金融机构、政府部门、医疗保健、拥有高度敏感数据和严格合规要求的企业。

---

### 混合云 (Hybrid Cloud)

*   **定义：** 混合云结合了两种或更多不同类型的云基础设施（私有云、公共云或社区云），这些云各自保持其独立性，但通过专有技术或标准化技术进行互联，使得数据和应用程序可以在它们之间进行移植。
*   **特点：**
    *   **整合与互联：** 内部私有云与外部公共云通过VPN、专线等方式连接。
    *   **工作负载可移植性：** 能够将工作负载在不同云环境之间迁移。
    *   **统一管理：** 通常需要统一的云管理平台来协调和管理不同云资源。
*   **优点：**
    *   **灵活性：** 结合了公共云的扩展性和成本效益，以及私有云的安全性和控制力。
    *   **“云爆发”（Cloud Bursting）：** 可以在私有云负载过高时，将多余的流量或计算任务“溢出”到公共云。
    *   **数据隔离：** 将敏感数据保留在私有云中，非敏感数据或测试环境放在公共云。
    *   **灾难恢复：** 利用公共云作为私有云的备用站点。
*   **缺点：**
    *   **管理复杂：** 整合和管理不同云环境需要高水平的专业知识和工具。
    *   **数据同步和兼容性：** 确保不同云之间的数据同步和应用兼容性是一个挑战。
    *   **网络延迟：** 跨云环境的数据传输可能引入延迟。
*   **适用场景：** 大多数企业级应用，尤其是需要兼顾安全、合规和弹性的场景；应对季节性或突发流量峰值。

---

### 社区云 (Community Cloud)

*   **定义：** 社区云是由若干个具有共同关注点（例如，相同的任务、安全要求、政策和合规性考量）的组织共享的云基础设施。它可以由这些组织共同拥有和管理，或者由第三方运营。
*   **特点：**
    *   **共享利益：** 参与者通常来自同一行业、拥有相似的业务需求或遵循相同的法规。
    *   **成本分摊：** 基础设施的成本和维护可以由社区成员共同承担。
    *   **定制化：** 云环境可以根据社区的特定需求进行定制。
*   **优点：**
    *   **成本效益：** 相对于独立的私有云，可以通过共享资源和管理成本来降低开销。
    *   **满足特定需求：** 云服务和安全策略可以针对行业或社区的特定要求进行优化。
    *   **协作与创新：** 促进社区成员之间的合作和共享最佳实践。
    *   **共同遵守合规：** 社区成员可以共同解决合规性挑战。
*   **缺点：**
    *   **参与者限制：** 仅限于具有共同需求的组织。
    *   **扩展性有限：** 规模不如公共云大。
    *   **治理复杂性：** 需要社区成员之间进行协调和达成共识。
*   **适用场景：** 医疗保健、政府机构、科研机构、教育机构等，当多个组织需要共享一个符合特定标准和安全要求的云环境时。

---

这四种部署模式为企业和个人提供了根据自身需求（如安全性、成本、可扩展性和管理复杂性）选择最合适云环境的灵活性。

## 三种服务模式

### 基础设施即服务 (Infrastructure as a Service - IaaS)

*   **定义：** IaaS是云计算最基础的服务模式。它提供虚拟化的计算资源，如虚拟机（Virtual Machines, VMs）、存储、网络、操作系统等，通过互联网按需提供给客户。客户可以在这些基础设施上部署和运行他们选择的操作系统、应用和数据。
*   **服务提供商管理：**
    *   物理硬件（服务器、网络设备、存储设备）
    *   数据中心设施（电力、冷却、物理安全）
    *   虚拟化层（Hypervisor）
*   **客户管理：**
    *   操作系统
    *   中间件（Middleware）
    *   运行时环境（Runtime）
    *   应用程序
    *   数据
    *   网络配置（部分高级配置）
    *   安全补丁和更新
*   **特点：**
    *   **最高的灵活性和控制力：** 客户对底层基础设施拥有大部分控制权，可以根据需要定制环境。
    *   **按需付费：** 客户只需为他们实际使用的资源付费，无需前期投入。
    *   **高可扩展性：** 可以根据需求快速扩展或缩减计算资源。
    *   **接近传统IT环境：** 对于习惯了管理服务器和网络的IT团队来说，IaaS是进入云的自然过渡。
*   **优点：**
    *   **成本效益：** 无需购买和维护昂贵的物理硬件。
    *   **快速部署：** 可以迅速启动和配置虚拟机。
    *   **灾难恢复和高可用性：** 易于构建冗余系统。
    *   **支持传统应用：** 适合将现有应用迁移到云端。
*   **缺点：**
    *   **管理开销：** 客户仍需管理操作系统、应用、补丁和安全等。
    *   **需要IT专业知识：** 配置和维护基础设施需要一定的技术能力。
*   **典型用例：**
    *   网站托管、开发测试环境
    *   大数据处理
    *   灾难恢复解决方案
    *   高性能计算
*   **服务商示例：** AWS EC2, Azure Virtual Machines, Google Compute Engine

---

### 平台即服务 (Platform as a Service - PaaS)

*   **定义：** PaaS在IaaS之上构建，提供了一个完整的开发和部署环境，包括操作系统、编程语言执行环境、数据库、Web服务器等，使开发者可以专注于应用程序的编写和管理，而无需担心底层基础设施或平台的维护。
*   **服务提供商管理：**
    *   IaaS层的所有内容（物理硬件、虚拟化）
    *   操作系统
    *   中间件（Middleware）
    *   运行时环境（Runtime）
    *   数据库
    *   Web服务器
    *   通常还包括自动扩展和负载均衡
*   **客户管理：**
    *   应用程序代码
    *   应用程序数据
*   **特点：**
    *   **关注应用开发：** 极大地简化了应用程序的开发、部署和管理。
    *   **自动化：** 通常提供自动化的扩展、负载均衡、部署和维护功能。
    *   **快速迭代：** 开发者可以更快地发布新功能和更新。
*   **优点：**
    *   **提高开发效率：** 开发者可以专注于编写代码，减少了基础设施管理的时间。
    *   **降低成本：** 减少了对基础设施和平台的投资和管理成本。
    *   **支持多语言和框架：** 通常支持多种编程语言和开发框架。
    *   **自动扩展：** 轻松应对流量波动。
*   **缺点：**
    *   **供应商锁定（Vendor Lock-in）风险：** 迁移到其他PaaS平台可能比较困难。
    *   **灵活性有限：** 客户对底层操作系统或硬件的控制权较少。
    *   **平台限制：** 只能使用平台支持的编程语言、框架和工具。
*   **典型用例：**
    *   Web应用程序开发和部署
    *   API开发和管理
    *   微服务架构
    *   数据分析和商业智能平台
*   **服务商示例：** AWS Elastic Beanstalk, Azure App Service, Google App Engine, Heroku

---

### 软件即服务 (Software as a Service - SaaS)

*   **定义：** SaaS是云计算最高级的服务模式。它通过互联网向用户提供完整的、可直接使用的应用程序。用户无需安装、维护或管理任何软件或基础设施，只需通过Web浏览器或移动应用即可访问和使用。
*   **服务提供商管理：**
    *   所有一切，包括基础设施、平台、应用程序代码、数据、安全、补丁和更新。
*   **客户管理：**
    *   用户配置和数据（在应用程序内部进行配置）
    *   用户访问管理
*   **特点：**
    *   **开箱即用：** 应用程序已完全部署并准备好使用。
    *   **订阅模式：** 通常按月或按年订阅。
    *   **多租户：** 多个用户共享相同的应用程序实例，但数据是逻辑隔离的。
    *   **自动更新：** 服务提供商负责所有软件的更新和维护。
*   **优点：**
    *   **最低的IT负担：** 客户无需管理任何技术细节。
    *   **随时随地访问：** 通过互联网即可访问，支持移动办公。
    *   **成本效益高：** 无需前期软件许可证费用，按需付费或订阅。
    *   **快速部署和扩展：** 立即开始使用，无需安装。
    *   **自动维护和更新：** 始终使用最新版本，无需用户干预。
*   **缺点：**
    *   **控制力最低：** 客户对应用程序的功能、性能或底层基础设施几乎没有控制权。
    *   **定制化限制：** 通常只能进行有限的界面或功能定制。
    *   **数据安全和隐私担忧：** 数据存储在第三方服务器上。
    *   **依赖互联网连接：** 没有网络就无法使用。
*   **典型用例：**
    *   客户关系管理（CRM）软件（如Salesforce）
    *   企业资源规划（ERP）系统
    *   电子邮件服务（如Gmail, Outlook 365）
    *   办公套件（如Microsoft 365, Google Workspace）
    *   协作工具（如Slack, Zoom）
*   **服务商示例：** Salesforce, Google Workspace, Microsoft 365, Dropbox, Zoom



# AI

## **网页端 VS 命令行**

**网页端（Web UI）**和**命令行（CLI）**的使用场景和交互逻辑完全不同。

对于 Linux 用户来说，最大的区别在于：**网页端是用来“聊天”的，而 CLI 是用来“干活”的（作为工具链的一部分）。**

以下是详细的对比分析：

### 1. 上下文输入

这是 CLI 最核心的优势，符合 Unix 的哲学（一切皆文件，程序间通过文本流通信）。

- **网页端：**
  - 你需要手动打开文件 -> 全选 -> 复制 -> 切换浏览器 -> 粘贴。
  - 如果文件太多，或者想把 `ls -la` 的输出给 AI 看，操作非常繁琐。
- **LLM CLI：**
  - 你可以直接把任何命令的**输出**或者**文件内容**“喂”给 AI。
  - **场景举例：**
    - *帮我写 Git 提交信息：* `git diff | llm "请根据代码变更写一个简洁的 commit message"`
    - *排查报错：* `tail -n 20 error.log | llm "分析这个报错原因"`
    - *解释代码：* `cat complex_script.py | llm "解释这段代码的逻辑"`

### 2. 自动化与脚本化

- **网页端：**

  - 每次任务都是一次性的。你很难“保存”一个复杂的动作让他下次自动执行。

- **LLM CLI：**

  - 你可以把常用的 Prompt 封装成 Shell 别名（Alias）或脚本。

  - **场景举例：**

    你可以定义一个别名 `explain`，实际上运行的是 `llm -s "用简短的中文解释这段代码"`。以后你只需要输入 `cat file.c | explain` 即可。

### 3. 数据隐私与历史记录

- **网页端：**
  - 你的聊天记录都在 Google 的服务器上。
  - 搜索历史记录比较慢，且难以导出。
- **LLM CLI (Simon Willison 版)：**
  - 它默认使用 **SQLite** 在你的本地硬盘（`~/.local/share/llm/`）存储所有对话日志。
  - **优势：** 你拥有数据的完全控制权。你可以用 SQL 查询你过去问过 AI 的所有问题和它的回答。
  - *命令：* `llm logs` 可以查看历史。

### 4. 角色设定

- **网页端：**
  - 虽然现在有“Gems”功能，但切换角色还是需要点击操作。
- **LLM CLI：**
  - 支持 **Templates（模板）** 功能。
  - 你可以预设几十个模板，例如“翻译官”、“Python专家”、“Linux运维”。
  - *命令：* `llm -t python "如何读取json"` （直接调用预设好的 Python 专家模式）。

### 5. 成本与门槛

- **网页端：**
  - 通常完全免费（Gemini Advanced 除外），且不限制并发，不用担心 Token 计费细节。
  - 支持多模态（上传图片/看视频）非常直观，拖进去就行。
- **LLM CLI：**
  - 需要申请 **API Key**。
  - **好消息：** Google Gemini 的 API 目前有**免费层级 (Free Tier)**，对于个人在 CLI 里的使用量来说，几乎是用不完的（限制是每分钟 15 次请求，每日 1500 次请求）。
  - **坏消息：** 在 CLI 里处理图片（虽然 `llm` 支持）不如网页端直观，通常主要处理纯文本。

### 总结对比表

| **特性**     | **网页端 (Web UI)**            | **命令行 (LLM CLI)**               |
| ------------ | ------------------------------ | ---------------------------------- |
| **最佳场景** | 探索性对话、创意写作、看图分析 | 编程辅助、日志分析、脚本自动化     |
| **输入方式** | 打字、拖拽文件                 | 管道 (`                            |
| **输出结果** | Markdown 渲染好，好看          | 纯文本，适合直接存入文件           |
| **历史记录** | 存在云端，网页查看             | 存在本地 SQLite，由于自己掌控      |
| **结合工具** | 无，独立存在                   | 结合 grep, jq, git, vim 等无限可能 |

## LLM

原生的 `llm` 工具**没有**联网搜索能力。

### 安装

```bash
libix@Debian:~$ pipx install llm
  installed package llm 0.28, installed using Python 3.13.5
  These apps are now globally available
    - llm
done! ✨ 🌟 ✨
libix@Debian:~$ llm install llm-gemini
...
Successfully installed ijson-3.4.0.post0 llm-gemini-0.28.2
libix@Debian:~$ llm keys set gemini
Enter key: 
libix@Debian:~$ 
```

### 基础交互

```bash
### 配置终端代理
libix@Debian:~$ echo "export HTTPS_PROXY=http://127.0.0.1:7897" >> ~/.bashrc
libix@Debian:~$ source ~/.bashrc
libix@Debian:~$ 
libix@Debian:~$ llm -m gemini-1.5-flash "你好，请用一句话介绍Debian系统"
Error: 'Unknown model: gemini-1.5-flash'
libix@Debian:~$ 
libix@Debian:~$ llm models			# 列出所有可用模型
OpenAI Chat: gpt-4o (aliases: 4o)
OpenAI Chat: chatgpt-4o-latest (aliases: chatgpt-4o)
OpenAI Chat: gpt-4o-mini (aliases: 4o-mini)
OpenAI Chat: gpt-4o-audio-preview
OpenAI Chat: gpt-4o-audio-preview-2024-12-17
OpenAI Chat: gpt-4o-audio-preview-2024-10-01
OpenAI Chat: gpt-4o-mini-audio-preview
OpenAI Chat: gpt-4o-mini-audio-preview-2024-12-17
OpenAI Chat: gpt-4.1 (aliases: 4.1)
OpenAI Chat: gpt-4.1-mini (aliases: 4.1-mini)
OpenAI Chat: gpt-4.1-nano (aliases: 4.1-nano)
OpenAI Chat: gpt-3.5-turbo (aliases: 3.5, chatgpt)
OpenAI Chat: gpt-3.5-turbo-16k (aliases: chatgpt-16k, 3.5-16k)
OpenAI Chat: gpt-4 (aliases: 4, gpt4)
OpenAI Chat: gpt-4-32k (aliases: 4-32k)
OpenAI Chat: gpt-4-1106-preview
OpenAI Chat: gpt-4-0125-preview
OpenAI Chat: gpt-4-turbo-2024-04-09
OpenAI Chat: gpt-4-turbo (aliases: gpt-4-turbo-preview, 4-turbo, 4t)
OpenAI Chat: gpt-4.5-preview-2025-02-27
OpenAI Chat: gpt-4.5-preview (aliases: gpt-4.5)
OpenAI Chat: o1
OpenAI Chat: o1-2024-12-17
OpenAI Chat: o1-preview
OpenAI Chat: o1-mini
OpenAI Chat: o3-mini
OpenAI Chat: o3
OpenAI Chat: o4-mini
OpenAI Chat: gpt-5
OpenAI Chat: gpt-5-mini
OpenAI Chat: gpt-5-nano
OpenAI Chat: gpt-5-2025-08-07
OpenAI Chat: gpt-5-mini-2025-08-07
OpenAI Chat: gpt-5-nano-2025-08-07
OpenAI Chat: gpt-5.1
OpenAI Chat: gpt-5.1-chat-latest
OpenAI Chat: gpt-5.2
OpenAI Chat: gpt-5.2-chat-latest
OpenAI Completion: gpt-3.5-turbo-instruct (aliases: 3.5-instruct, chatgpt-instruct)
GeminiPro: gemini/gemini-pro (aliases: gemini-pro)
GeminiPro: gemini/gemini-1.5-pro-latest (aliases: gemini-1.5-pro-latest)
GeminiPro: gemini/gemini-1.5-flash-latest (aliases: gemini-1.5-flash-latest)
GeminiPro: gemini/gemini-1.5-pro-001 (aliases: gemini-1.5-pro-001)
GeminiPro: gemini/gemini-1.5-flash-001 (aliases: gemini-1.5-flash-001)
GeminiPro: gemini/gemini-1.5-pro-002 (aliases: gemini-1.5-pro-002)
GeminiPro: gemini/gemini-1.5-flash-002 (aliases: gemini-1.5-flash-002)
GeminiPro: gemini/gemini-1.5-flash-8b-latest (aliases: gemini-1.5-flash-8b-latest)
GeminiPro: gemini/gemini-1.5-flash-8b-001 (aliases: gemini-1.5-flash-8b-001)
GeminiPro: gemini/gemini-exp-1114 (aliases: gemini-exp-1114)
GeminiPro: gemini/gemini-exp-1121 (aliases: gemini-exp-1121)
GeminiPro: gemini/gemini-exp-1206 (aliases: gemini-exp-1206)
GeminiPro: gemini/gemini-2.0-flash-exp (aliases: gemini-2.0-flash-exp)
GeminiPro: gemini/learnlm-1.5-pro-experimental (aliases: learnlm-1.5-pro-experimental)
GeminiPro: gemini/gemma-3-1b-it (aliases: gemma-3-1b-it)
GeminiPro: gemini/gemma-3-4b-it (aliases: gemma-3-4b-it)
GeminiPro: gemini/gemma-3-12b-it (aliases: gemma-3-12b-it)
GeminiPro: gemini/gemma-3-27b-it (aliases: gemma-3-27b-it)
GeminiPro: gemini/gemma-3n-e4b-it (aliases: gemma-3n-e4b-it)
GeminiPro: gemini/gemini-2.0-flash-thinking-exp-1219 (aliases: gemini-2.0-flash-thinking-exp-1219)
GeminiPro: gemini/gemini-2.0-flash-thinking-exp-01-21 (aliases: gemini-2.0-flash-thinking-exp-01-21)
GeminiPro: gemini/gemini-2.0-flash (aliases: gemini-2.0-flash)
GeminiPro: gemini/gemini-2.0-pro-exp-02-05 (aliases: gemini-2.0-pro-exp-02-05)
GeminiPro: gemini/gemini-2.0-flash-lite (aliases: gemini-2.0-flash-lite)
GeminiPro: gemini/gemini-2.5-pro-exp-03-25 (aliases: gemini-2.5-pro-exp-03-25)
GeminiPro: gemini/gemini-2.5-pro-preview-03-25 (aliases: gemini-2.5-pro-preview-03-25)
GeminiPro: gemini/gemini-2.5-flash-preview-04-17 (aliases: gemini-2.5-flash-preview-04-17)
GeminiPro: gemini/gemini-2.5-pro-preview-05-06 (aliases: gemini-2.5-pro-preview-05-06)
GeminiPro: gemini/gemini-2.5-flash-preview-05-20 (aliases: gemini-2.5-flash-preview-05-20)
GeminiPro: gemini/gemini-2.5-pro-preview-06-05 (aliases: gemini-2.5-pro-preview-06-05)
GeminiPro: gemini/gemini-2.5-flash (aliases: gemini-2.5-flash)
GeminiPro: gemini/gemini-2.5-pro (aliases: gemini-2.5-pro)
GeminiPro: gemini/gemini-2.5-flash-lite (aliases: gemini-2.5-flash-lite)
GeminiPro: gemini/gemini-flash-latest (aliases: gemini-flash-latest)
GeminiPro: gemini/gemini-flash-lite-latest (aliases: gemini-flash-lite-latest)
GeminiPro: gemini/gemini-2.5-flash-preview-09-2025 (aliases: gemini-2.5-flash-preview-09-2025)
GeminiPro: gemini/gemini-2.5-flash-lite-preview-09-2025 (aliases: gemini-2.5-flash-lite-preview-09-2025)
GeminiPro: gemini/gemini-3-pro-preview (aliases: gemini-3-pro-preview)
GeminiPro: gemini/gemini-3-flash-preview (aliases: gemini-3-flash-preview)
Default: gpt-4o-mini
libix@Debian:~$ 
libix@Debian:~$ llm -m gemini-2.5-flash "你好，请用一句话介绍Debian系统"
Debian是一个完全由社区开发和维护的自由开源Linux发行版，以其坚若磐石的稳定性、严格的自由软件原则以及作为众多其他流行Linux发行版（如Ubuntu）的基础而闻名。
libix@Debian:~$ 
libix@Debian:~$ llm -m gemini-2.5-pro "最适合桌面使用的Linux系统是哪个？"
Error: You exceeded your current quota, please check your plan and billing details. For more information on this error, head to: https://ai.google.dev/gemini-api/docs/rate-limits. To monitor your current usage, head to: https://ai.dev/rate-limit. 
* Quota exceeded for metric: generativelanguage.googleapis.com/generate_content_free_tier_input_token_count, limit: 0, model: gemini-2.5-pro
* Quota exceeded for metric: generativelanguage.googleapis.com/generate_content_free_tier_input_token_count, limit: 0, model: gemini-2.5-pro
* Quota exceeded for metric: generativelanguage.googleapis.com/generate_content_free_tier_requests, limit: 0, model: gemini-2.5-pro
* Quota exceeded for metric: generativelanguage.googleapis.com/generate_content_free_tier_requests, limit: 0, model: gemini-2.5-pro
Please retry in 28.397400758s.
# API Key 没有权限调用它
libix@Debian:~$ 
libix@Debian:~$ llm models default gemini-2.5-flash			# 设置默认模型
libix@Debian:~$ llm models
...
Default: gemini/gemini-2.5-flash
libix@Debian:~$ 
libix@Debian:~$ llm "你好，打个招呼吧"
你好！很高兴和你打招呼！有什么我可以帮助你的吗？
libix@Debian:~$ 
```

**连续对话模式 (Chat REPL)**

如果你想像在网页上一样多轮对话，进入交互模式：

```
llm chat
```

- 输入内容回车即可对话。
- 输入 `quit` 或 `exit` 退出。
- *注：这种模式适合纯聊天，但在 CLI 里其实不如单次命令好用。*

**3. 接续上文 (-c / --continue)**

这是 CLI 的核心痛点解决。默认情况下，每次 `llm` 命令都是全新的（没有记忆）。

如果你想基于上一条命令继续问：

```bash
# 第一步
llm "帮我生成一个 Python 的 Hello World 代码"

# 第二步（加上 -c）
llm -c "给这段代码加上详细的中文注释"
```

- `-c` 会自动读取你本地数据库里的最后一次对话上下文。

------

### 管道流

可以把任何命令的**输出 (Stdout)** 变成 AI 的**输入 (Stdin)**。

**场景 A：代码解释**

把你刚写的代码“喂”给 AI：

```
cat main.py | llm "请解释这段代码在做什么，并指出潜在的 Bug"
```

**场景 B：Git 提交信息生成 (神器)**

不需要自己绞尽脑汁写 commit message 了：

```
git diff | llm "根据这些代码变更，写一个简洁的 git commit message"
```

**场景 C：日志分析**

服务器报错了？直接把报错日志扔给它：

```
# 读取最后 20 行系统日志并分析
sudo journalctl -n 20 | llm "分析这些日志，为什么我的服务启动失败了？"
```

**场景 D：结果存文件**

AI 的回答直接存入 Markdown 文件，不用复制粘贴：

```
llm "写一份 Debian 系统初始化配置清单" > debian_setup.md
```

------

### 角色模板

不想每次都打 "请你作为一个资深 Python 工程师..."？你可以创建 **模板 (Templates)**。

**1. 临时设定角色 (-s)**

```
llm templates set ops "你是一个运行在 Debian 12 终端里的资深 Linux 系统工程师。你的用户是技术人员。
规则：
1. 回答极其简练，直接切入重点，少用客套话。
2. 默认提供适用于 Debian 的解决方案（例如优先用 apt, systemctl）。
3. 如果用户输入的是报错日志，直接分析原因并给出修复命令。
4. 代码和命令必须包含在 Markdown 代码块中。
5. 对于危险操作（如删除、覆写），必须简短提示风险。"
```

**2. 保存常用模板**

比如你经常需要翻译英文文档，可以存一个 `fanyi` 模板：

```
# 创建模板
llm templates set fanyi "你是一个专业的科技翻译。请直接输出中文翻译结果，不要带任何解释，保留专业术语。"

# 使用模板 (-t)
cat README.md | llm -t fanyi > README_CN.md
```

**查看你有哪些模板：**

```
llm templates list
```

------

### 历史记录查询

你在终端里和 AI 聊过的所有内容，都被存在了本地的 SQLite 数据库里。

**查看最近的对话：**

```
llm logs
```

**查看完整的某条对话（带 ID）：**

```
# 先看 ID
llm logs -n 5 
# 再看详情
llm logs -c <conversation-id>
```

### 优化输出内容

原本的输出带有 markwon 格式符号，影响阅读

```bash
pipx install rich-cli
llm "你觉得使用Debian 13作为桌面使用怎么样？" | rich --markdown -
```



# ---
