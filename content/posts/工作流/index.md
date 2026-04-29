---
title: "工作流"
date: 2026-02-13T00:47:28+08:00
draft: false
tags:
  - "notes"
---



## cockpit

```
# debian
. /etc/os-release
sudo apt install -t ${VERSION_CODENAME}-backports cockpit

# fedora
sudo dnf install cockpit -y
sudo systemctl enable --now cockpit.socket
sudo firewall-cmd --add-service=cockpit
sudo firewall-cmd --add-service=cockpit --permanent
```

## kvm

```
# 安装 KVM

# 检查输出中是否包含 VMX (Intel) 或 SVM (AMD)
lscpu | grep Virtualization

# 安装虚拟化核心、工具及图形化管理器
sudo dnf install @virtualization
sudo dnf install libguestfs-tools -y
# 在新版 Fedora 中，这个才是包含 virt-customize 的本体
sudo dnf install guestfs-tools -y

# 启动并设置开机自启
sudo systemctl enable --now libvirtd

# 检查运行状态
systemctl status libvirtd

# 将当前用户加入 libvirt 组
sudo usermod -aG libvirt $(whoami)


# virt-customize 在虚拟机启动前直接修改磁盘镜像，拥有至高无上的 Root 权限

sudo mv noble-server-cloudimg-amd64.qcow2 openclaw.qcow2

sudo qemu-img resize openclaw.qcow2 20G

# Fedora 43 上运行 virt-customize，如果不显式指定 LIBGUESTFS_BACKEND=direct，由于权限过严，它经常会因为无法连接 libvirtd 而报错挂起
export LIBGUESTFS_BACKEND=direct
sudo virt-customize -a openclaw.qcow2 \
  --root-password password:123456 \
  --timezone Asia/Shanghai \
  --hostname openclaw \
  --write /etc/cloud/cloud.cfg.d/99_local.cfg:"datasource_list: [ NoCloud, None ]" \
  --run-command 'rm /etc/ssh/sshd_config.d/60-cloudimg-settings.conf' \
  --run-command 'useradd -m -s /bin/bash -G sudo libix' \
  --run-command "echo 'libix: ' | chpasswd" \
  --run-command 'echo "libix ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/libix' \
  --chmod 0440:/etc/sudoers.d/libix \
  --run-command 'mkdir -p /etc/systemd/system/systemd-networkd-wait-online.service.d' \
  --run-command 'printf "[Service]\nTimeoutStartSec=10\nExecStart=\nExecStart=/lib/systemd/systemd-networkd-wait-online --any\n" > /etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf'


sudo virt-install \
  --name openclaw \
  --memory 6144 \
  --vcpus 4 \
  --cpu host-passthrough \
  --disk openclaw.qcow2 \
  --import \
  --network network=default \
  --os-variant ubuntu24.04 \
  --graphics none \
  --console pty,target_type=serial \
  --noautoconsole
  
sudo virsh console openclaw

# 快照
sudo virsh snapshot-list openclaw --tree

sudo virsh snapshot-revert openclaw Snap-02
```



## V2rayA

```
# 宿主机操作，对虚拟机的nat网卡开启7897端口，用于连接宿主机代理
sudo firewall-cmd --zone=libvirt --add-port=7897/tcp --permanent
sudo firewall-cmd --reload


export http_proxy="http://192.168.122.1:7897"
export https_proxy="http://192.168.122.1:7897"
curl -I https://www.google.com

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  
# 把当前用户加入 docker 组
sudo usermod -aG docker $USER
# 立刻刷新组权限（不需要重启，也不需要注销）
newgrp docker

# 验证
docker ps


# 创建配置目录
sudo mkdir -p /etc/systemd/system/docker.service.d

# 创建代理配置文件写入以下内容（假设你的宿主机代理端口是 `7890`，请根据实际情况修改）
cat <<EOL | sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null
[Service]
Environment="HTTP_PROXY=http://192.168.122.1:7897"
Environment="HTTPS_PROXY=http://192.168.122.1:7897"
Environment="NO_PROXY=localhost,127.0.0.1"
EOL

# 重载并重启
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

docker pull mzz2017/v2raya
  
docker run -d \
  --name v2raya \
  --restart=always \
  --network=host \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -v /etc/v2raya:/etc/v2raya \
  -e V2RAYA_NFTABLES_SUPPORT=off \
  -e IPTABLES_MODE=legacy \
  mzz2017/v2raya
  
# fedora  
docker run -d \
  --name v2raya \
  --restart=always \
  --privileged \
  --network host \
  -v /lib/modules:/lib/modules:ro \
  -v /etc/resolv.conf:/etc/resolv.conf \
  -v /etc/v2raya:/etc/v2raya \
  mzz2017/v2raya
  
# 配置后
unset http_proxy https_proxy all_proxy no_proxy
sudo rm -rf /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker
curl -I https://www.google.com
```

## openclaw

```

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env

curl -fsSL https://openclaw.ai/install.sh | bash

# 配置 telegram bot
source ~/.bashrc
openclaw pairing approve telegram Z4JRBG46
```



## n8n

**[n8n](https://github.com/n8n-io/n8n)** 是一个**“可视化自动流程设计器”**。

在 n8n 里写程序，不需要敲满屏幕的代码。你用**线**把它们连起来。数据就会顺着这根线流淌。

本质上，它把复杂的编程逻辑，变成了一个连连看游戏。

n8n 是 AI Agent 的“躯干”，这是 n8n 最近爆火的原因。

- **大模型 (LLM) 是大脑：** 会思考，但它没有手，没法帮你发邮件、查库存。
- **n8n 是躯干和手脚：** 负责连接真实世界的软件。

![image-20260213025118565](image-20260213025118565.png)

```bash
docker volume create n8n_data

docker run -d \
  --name n8n \
  -p 5678:5678 \
  -e GENERIC_TIMEZONE="Asia/Shanghai" \
  -e TZ="Asia/Shanghai" \
  -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
  -e N8N_RUNNERS_ENABLED=true \
  -e N8N_SECURE_COOKIE=false \
  -e N8N_COOKIE_SAMESITE=lax \
  -e N8N_ENCRYPTION_KEY=my_custom_secret_key_2026 \
  -v n8n_data:/home/node/.n8n \
  --restart unless-stopped \
  docker.n8n.io/n8nio/n8n
```

