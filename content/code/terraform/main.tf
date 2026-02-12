### 变量定义  -----------------------------------------------------------------
variable "cluster_nodes" {
  type = map(object({
    hostname     = string
    ip_last_byte = string
    memory       = string   # <--- 新增：定义内存字段
    vcpu         = number   # <--- 新增：定义CPU字段
  }))
  default = {
    # 在这里为每一台机器分别指定内存和CPU
    "0" = { 
      hostname = "kmaster", 
      ip_last_byte = "10", 
      memory = "4096",      # Master 可以给多一点，比如 "4096"
      vcpu   = 2 
    }
    "1" = { 
      hostname = "knode1", 
      ip_last_byte = "11", 
      memory = "2048", 
      vcpu   = 2 
    }
    "2" = { 
      hostname = "knode2", 
      ip_last_byte = "12", 
      memory = "2048", 
      vcpu   = 2 
    }
  }
}

variable "network_prefix" { default = "192.168.0" }
variable "gateway" { default = "192.168.0.1" }
variable "dns_servers" { default = ["192.168.1.1", "192.168.0.1"] }

### Terraform 插件配置 -----------------------------------------------------------------
terraform {
  required_providers {
    libvirt = {
      # 指定使用第三方维护的 Libvirt 插件（用于管理 KVM）
      source  = "dmacvicar/libvirt"
      version = "0.7.6" # 指定版本
    }
  }
}

## 连接本地 Libvirt 系统服务
provider "libvirt" {
  uri = "qemu:///system" # 表示以系统级权限连接，可以管理桥接网络等高级资源
}

# ## 自定义镜像存储池
# 实验环境可以自定义存储池，修改 /etc/libvirt/qemu.conf 文件，添加 user = "root" ， group = "root" ，security_driver = "none" 然后重启 libvirtd 服务
# 工作环境不要修改  KVM 默认存储池，避免影响其他虚拟机
# resource "libvirt_pool" "image-pool" {
#   name = "image-pool" 	# 给池子起个逻辑名字
#   type = "dir"
#   path = "/home/libix/Desktop/terraform" 		# 实际物理路径
# }

### 硬盘配置：定义虚拟机的系统盘  -----------------------------------------------------------------
resource "libvirt_volume" "Disk" {
  for_each = var.cluster_nodes
  name     = "${each.value.hostname}.qcow2" # 在 for_each 循环中，根据每个节点的 hostname 动态生成唯一的磁盘名称
  pool     = "default"                      # 使用 KVM 默认存储池 /var/lib/libvirt/images/
  # pool = libvirt_pool.image-pool.name  # 使用定义的自定义存储池,这里的 name 指的是上面 image-pool 资源的 name 属性值，即 "image-pool"
  # Terraform 会自动把这个文件复制一份作为新虚拟机的硬盘，不会破坏原文件
  source = "/var/lib/libvirt/images/ubuntu-template.qcow2" # 镜像来源
  format = "qcow2"
}

# ### 定义 Cloud-Init ISO -----------------------------------------------------------------
# # Terraform 会根据这些内容生成一个 .iso 镜像，挂载给虚拟机读取
resource "libvirt_cloudinit_disk" "commoninit" {
  for_each = var.cluster_nodes
  name     = "init-${each.value.hostname}.iso"
  pool     = "default"
  # pool = libvirt_pool.image-pool.name  # 使用定义的自定义存储池

  user_data = <<EOF
#cloud-config
hostname: ${each.value.hostname}
manage_etc_hosts: true
timezone: Asia/Shanghai

users:
  - name: libix
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    passwd: "$6$nuR8GV0zikMlNqOc$agrrbn//ZTLLW.6lI2w.I/Qn5EFKuZE5eujKFArblY/REERhwbc2ht5BOoIwRXlzM5tBP0.cPmZ64WVkoOd9I/"
    ssh_authorized_keys:
      - ${file("/home/libix/.ssh/id_ed25519.pub")}
 
package_update: true
packages:
  - qemu-guest-agent
  - net-tools
  - curl
  - vim
  - wget
  - tree
  - lsof
  - tcpdump
  - sysstat
  - unzip
  - iputils-ping
  - bash-completion

write_files:
  # 禁用 Cloud-Init 自带的网络配置，防止冲突
  - path: /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
    content: "network: {config: disabled}"

  # Terraform 会在生成 ISO 前，遍历 cluster_nodes 变量，把所有节点都写进去
  - path: /etc/hosts.cluster
    content: |
      127.0.0.1 localhost
      ::1 localhost
      
      # Cluster Nodes
      %{for id, node in var.cluster_nodes~}
      ${var.network_prefix}.${node.ip_last_byte} ${node.hostname}
      %{endfor~}

  # 写入自动配置脚本
  - path: /usr/local/bin/auto-net.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e
      
      sleep 2
      
      # 注意：在 Terraform EOF 中，Shell 的 $ 不需要转义，除非后面紧跟 {
      IFACE=$(ip -o link show | awk -F': ' '$2 != "lo" && $2 !~ /docker|veth|cni|virbr|cali|flannel/ {print $2; exit}')
      
      if [ -z "$IFACE" ]; then
        echo "Error: No physical interface found!"
        exit 1
      fi
      
      echo "Found interface: $IFACE"
      
      mkdir -p /etc/systemd/network
      
      cat <<'NET' > /etc/systemd/network/10-static.network
      [Match]
      Name=$IFACE
      
      [Network]
      Address=${var.network_prefix}.${each.value.ip_last_byte}/24
      Gateway=${var.gateway}
      DNS=${var.dns_servers[0]}
      DNS=${var.dns_servers[1]}
      IPv6AcceptRA=no
      NET
      
      sed -i "s/\$IFACE/$IFACE/g" /etc/systemd/network/10-static.network

      rm -f /etc/netplan/*.yaml
      systemctl enable systemd-networkd
      systemctl restart systemd-networkd
      
      ip link set "$IFACE" up

runcmd:
  - [ bash, /usr/local/bin/auto-net.sh ]
  - [ systemctl, enable, --now, qemu-guest-agent ]
  - [ cp, /etc/hosts.cluster, /etc/hosts ]
  - [ rm, /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]
EOF
}

## 虚拟机开关机状态控制
# 一键开/关机 terraform apply -var="vm_state=true/false"
variable "vm_state" {
  type    = bool
  default = true # 默认是开启
}

### 定义虚拟机实例 -----------------------------------------------------------------
resource "libvirt_domain" "terraform_test" {
  for_each = var.cluster_nodes
  name     = each.value.hostname # 虚拟机显示名称
  running  = var.vm_state        # 根据变量控制虚拟机开关机状态
  memory   = each.value.memory              # 内存大小 (MB)
  vcpu     = each.value.vcpu                   # CPU 核心数

  # # 核心配置：将上面定义的 Cloud-Init ISO 挂载到这台虚拟机上
  # cloudinit = libvirt_cloudinit_disk.commoninit.id
  cloudinit = libvirt_cloudinit_disk.commoninit[each.key].id

  ## 配置网络接口
  network_interface {
    # network_name = "default"    # 使用 KVM 默认的 NAT 网络
    bridge         = "br0" # 桥接模式， "br0" 必须是宿主机上真实存在的网桥名称
    wait_for_lease = false # 等待虚拟机启动并分配到 IP，这对自动化后续操作非常有用，需要确保镜像中安装并启动了 qemu-guest-agent 服务，否则会超时失败，或者设置为 false
  }

  ## 挂载对应的硬盘
  disk {
    volume_id = libvirt_volume.Disk[each.key].id # 关联上面定义的硬盘资源，根据索引号一一对应  
  }
  # libvirt_volume.Disk.id 是一个引用表达式，我们可以把它拆解为三部分来看：
  # libvirt_volume (资源类型)： 告诉 Terraform：“我要找一个存储卷（硬盘）类型的资源”。
  # Disk (资源名称)： 这是自定义的名字。
  # .id (属性)： 这是结果。当 Terraform 创建完那个硬盘后，Libvirt 会给那个硬盘分配一个唯一的标识符（通常是文件路径或 UUID）。.id 就是让 Terraform 自动把这个“身份证号”填到这里。

  ## 配置图形界面
  # 不过在真实的工作场景中，完全不需要、甚至会刻意禁止配置图形界面
  # graphics {
  #   type        = "spice"     # SPICE 是 KVM/QEMU 体系中最常用、性能最好的显示协议
  #   listen_type = "address"    # 监听地址，默认本地
  #   autoport    = true  # 自动分配端口
  # }

  ## 配置串口控制台 (Serial Console)
  # 即使 SSH 挂了，我们也可以通过 virsh console 连接虚拟机
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

}

resource "local_file" "ansible_inventory" {
  content = <<CFG
[masters]
%{ for id, node in var.cluster_nodes ~}
%{ if node.hostname == "kmaster" ~}
${node.hostname} ansible_host=${var.network_prefix}.${node.ip_last_byte} ansible_user=libix ansible_ssh_private_key_file=~/.ssh/id_ed25519
%{ endif ~}
%{ endfor ~}

[workers]
%{ for id, node in var.cluster_nodes ~}
%{ if node.hostname != "kmaster" ~}
${node.hostname} ansible_host=${var.network_prefix}.${node.ip_last_byte} ansible_user=libix ansible_ssh_private_key_file=~/.ssh/id_ed25519
%{ endif ~}
%{ endfor ~}

[k8s:children]
masters
workers
CFG

  filename = "${path.module}/ansible/inventory.ini"
}
