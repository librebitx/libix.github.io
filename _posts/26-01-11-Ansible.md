---
layout: default
title:   "Ansible"
date:   2026-01-10
blog-label: Notes
---

# 什么是 Ansible？
**Ansible** 是一个自动化运维工具，专门用来自动化配置管理、应用部署、任务执行等。
它通过 **SSH** 协议远程连接服务器，不需要在被管理的机器上安装代理软件（agent），使用简单，易上手。
Ansible 能够实现统一配置多台服务器的软件环境；自动将代码或应用部署到服务器；远程执行命令；组合多步操作，按顺序执行。

# 安装
也可通过rpm、pip、容器安装Ansible，但都是阉割版且步骤繁琐，推荐源码包安装
下载源码包解压源码包
wget https://releases.ansible.com/ansible/ansible-2.9.0.tar.gz
tar -xzf ansible-2.9.0.tar.gz
进入解压后的目录
cd ansible-2.9.0
ll
配置文件为 ansible.cfg
hosts 为主机清单
**Debian**
```bash
# 安装 pipx
sudo apt update && sudo apt install pipx -y
pipx ensurepath

# 安装最新版 Ansible
pipx install --include-deps ansible

# 安装依赖
apt update && apt install python3-pip -y

# 安装 ansible-navigator
pip3 install ansible-navigator

# 确保其路径在 $PATH 中（通常是 ~/.local/bin）
export PATH=$PATH:~/.local/bin
```

# **配置文件内容**

[defaults]		远程登录的用户、密码(密钥)、远程端口等

[inventory]		与主机清单相关的配置，是不是要设置主机清单的变量,配置主机清单的路径

[privilege_escalation]		提权相关的配置项，普通用户进行连接,要提权到哪个用户，提权的方式?是不是sudo

[paramiko_connection]		ansible管控被控节点的连接,后面都使用了ssh进行管控

[ssh_connection]		ssh连接项，定义SSH的版本,端口,身份验证方式,加速器

[persistent_connection]		持久化连接的配置项，定义多久时间没有任务执行,则退出连接

[accelerate]		加速模式配置

是否要对数据进行压缩加速传输

[selinux]		SELinux相关配置项

selinux是否开启?

[colors]		ansible命令输出提示的颜色

[diff]			在运行ansible命令的时候,是否打印变更前和变更前和变更后差异

```bash
root@master:~# cat <<EOL> ansible.cfg
inventory = ./ansible/inventory
# 指定主机清单的位置

remote_user = libix
# 设置 Ansible 默认登录远程主机的用户名，被控节点上一定要有该用户

roles_path = ./ansible/roles:/usr/share/ansible/roles        
# 定义 Ansible 角色（Roles）的搜索路径，多个路径用:分隔，路径优先级从左到右

collections_path=./ansible/mycollection/:.ansible/collections:/usr/share/ansible/collections
# 定义 Ansible 集合（Collections）的搜索路径，集合是 Ansible 的扩展模块/插件包，路径优先级从左到右

become = True           
# 全局启用权限提升，默认使用 sudo 方式
# 使用该配置后执行 playbook 会自动使用指定的 inventory、用户、roles 路径等

host_key_checking = False        
# 禁用 SSH 主机密钥验证（默认是 True）
EOL
root@master:~#
```



# **配置文件优先级**

ANSIBLE_CONFIG 环境变量 > 当前目录 ansible.cfg > ~/.ansible.cfg > /etc/ansible/ansible.cfg

ANSIBLE_CONFIG 环境变量		临时指定一个特定的配置文件路径。

./ansible.cfg	这是企业项目中最常用的方式。

~/.ansible.cfg	当前登录用户的家目录下的隐藏文件。

/etc/ansible/ansible.cfg	默认安装后的全局配置文件。

# **主机清单**

```bash
[root@RHEL9 ansible]# cat hosts
172.168.0.129                #ip
172.168.0.[1:128]                #循环
nodel        #主机名，一定要做解析，主机名能解析到ip地址
node2
node3.example.com            #域名
[webserver]        #主机组
web01
web02
[mysqlserver]
db01
db02
[test01: children]        #嵌套主机组；此行下面所有的主机都会被识别为主机组
webserver
mysqlserver
[root@RHEL9 ansible]#
```



**查看主机清单的方式:**

1. 直接查询

​      ansible all --list-hosts	-v	#列出当前所有的主机，并显示所使用的主机清单的路径

单个主机查询	ansible node1 --list-hosts

多个主机查询	ansible node1,node2 --list-hosts

主机组查询	ansible webserver --list-hosts

查询不属于任何主机组的主机	ansible ungrouped --list-hosts

2. 通配符查询

查看以 exam 开头的所有主机	ansible exam* --list-hosts

查看以 com 结尾的所有主机	ansible *com --list-hosts

查看存在 ple 的所有主机	ansible ple --list-hosts

3. 正则查询

正则查询，以 e 或者 t 开头的主机	ansible '~^(e|t)' --list-hosts

取反	ansible 'webserver,!mysqlserver' --list-hosts

取交集，逻辑与	ansible 'webserver,&mysqlserver' --list-hosts

组合使用	ansible 'userserver,&webserver,!mysqlserver' --list-hosts

配置文件 

[defaults]

inventory = /etc/ansible/hosts

ask_pass	=True

ask_sudo_pass = Flase

remote_user = devops

[privilege_escalation]

become=True

become_method=sudo

become_user=root

become_ask_pass=False

1.做本地映射解析

ansible node1 -m shell -a 'echo "172.168.0.1129 node1" >> /etc/hosts' -u root -k

2.在被控节点上创建devops用户,修改密码,配置提权

ansible node1 -m shell -a 'useradd devops && echo rehdat|passwd -stdin devops' -u root -k

ansible node1 -m shell -a 'echo "devops ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers' -u root -k

3.设置devops进行免密登录

ssh-keygen

ssh-copy-id devops@node1

# **配置 SSH 免密登录**

```bash
# 在 Master 上生成密钥
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
# 将公钥分发到 Worker 节点
ssh-copy-id libix@node1
ssh-copy-id libix@node2
# 手动验证 SSH 是否免密
ssh libix@node1
# 运行 Ansible 测试
ansible all -m ping -o
```



# **模块**

**命令执行模块**

**command 模块 （Ansible 系统默认模块）**

<>|& 特殊符号无法识别

**raw 模块**

**script 模块**：shell 脚本不需要x执行权限，只是将脚本中的shell指令传输到被控节点执行

**抄写命令**

ansible-doc [模块名]

/EXAMPLES

**command**

默认模块。执行简单命令，**不支持** shell 变量、管道和重定向。

## shell

通过 `/bin/sh` 执行命令，支持管道符 `|`、重定向 `>` 和逻辑运算符 `&&`。在 K8s 环境中常用于执行复杂的安装指令。

```bash
root@master:~# ansible work -m shell -a "cat > /etc/systemd/system/containerd.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://192.168.0.5:7897"
Environment="HTTPS_PROXY=http://192.168.0.5:7897"
Environment="NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16,10.244.0.0/16,.svc,.cluster.local"
EOF
systemctl daemon-reload
systemctl restart containerd" -b -K
BECOME password: 
node1 | CHANGED | rc=0 >>

node2 | CHANGED | rc=0 >>

root@master:~# 
root@master:~# ansible work -m shell -a "cat /etc/systemd/system/containerd.service.d/http-proxy.conf"
node2 | CHANGED | rc=0 >>
[Service]
Environment=HTTP_PROXY=http://192.168.0.5:7897
Environment=HTTPS_PROXY=http://192.168.0.5:7897
Environment=NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16,10.244.0.0/16,.svc,.cluster.local
node1 | CHANGED | rc=0 >>
[Service]
Environment=HTTP_PROXY=http://192.168.0.5:7897
Environment=HTTPS_PROXY=http://192.168.0.5:7897
Environment=NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16,10.244.0.0/16,.svc,.cluster.local
root@master:~# 
```

**`script`**：将本地的脚本传输到远程节点并执行。无需在远程节点预留脚本文件。

## file

设置文件/目录的属性（创建、删除、修改权限、创建软链接）。

## copy

将本地文件复制到远程服务器（类似 `scp`）。

copy 模块的backup就是如果复制过去的文件名与源文件相同，则备份源文件

```bash
# 提权
ansible all -m copy -a "content='libix ALL=(ALL) NOPASSWD: ALL' dest=/etc/sudoers.d/libix mode=0440 owner=root group=root" -b -K
# -b 等同于 --become，告诉 ansible 用提升权限（默认是 sudo）来运行模块或命令。
# -K 表示运行时会提示输入 sudo 密码（become password），适合 sudo 需要密码的场景。
```

\* **`fetch`**：从远程服务器拉取文件到本地（与 copy 相反）。

\* **`template`**：**极重要！** 将本地带有变量的 Jinja2 模板渲染后分发到远程。常用于生成不同节点的 `kubeadm-config.yaml`。

**lineinfile**

在文件中搜索特定的行。如果找到了，就不动；如果没找到，就添加。

\* **`replace`**：正则批量替换文件中的特定内容。

\* **`unarchive`**：解压文件（如将下载好的 Kubernetes 二进制包解压到指定目录）。

\### 3. 软件包管理（环境初始化）

由于你正在使用 **Debian**，你会更频繁地使用 `apt`。

\* **`apt`**：Debian/Ubuntu 系统的软件包管理。

\* **`yum` / `dnf**`：RHEL/CentOS 系统的软件包管理。

\* **`package`**：通用包装模块，会自动根据系统判断调用 apt 或 yum，提高 Playbook 的兼容性。

\* **`get_url`**：从 HTTP/HTTPS 下载文件。常用于下载 CNI 插件或二进制文件。

\### 4. 系统管理与服务模块

\* **`service` / `systemd**`：管理系统服务（启动、停止、重启、开机自启）。建议优先使用 `systemd`，因为它支持 `daemon-reload`。

\* **`sysctl`**：**K8s 必备。** 用于修改内核参数，例如开启 `net.ipv4.ip_forward`。

\* **`hostname`**：批量修改服务器的主机名。

\* **`reboot`**：重启服务器并等待其恢复在线，常用于内核更新后。

\* **`cron`**：管理计划任务。

\### 5. 用户与安全模块

\* **`user`**：管理用户账号（创建、删除、设置密码）。

\* **`group`**：管理用户组。

\* **`authorized_key`**：管理 SSH 公钥，用于配置 Master 到 Worker 的免密登录。

\* **`selinux` / `ufw` / `firewalld**`：管理安全策略（在 K8s 部署中通常需要关闭或配置这些防火墙）。

\### 6. 现代云原生模块（进阶）

当你已经装好了 K8s，想通过 Ansible 操作 K8s 集群内部资源时：

\* **`kubernetes.core.k8s`**：直接在 Playbook 中管理 K8s 对象（Pod, Service, Deployment）。

\* **`kubernetes.core.helm`**：通过 Ansible 部署 Helm Chart。

ansible-doc <模块名>      # 查看完整文档

ansible-doc -s <模块名>   # 查看简要语法参数（最常用）

## Playbook 语法

**handlers**

handlers 可不定义

handlers 与 tasks 同级，且在 playbook 的最后一行，在所有任务执行完成之后才会执行 handlers

**notify** （监听任务）

必须引用 handlers 中定义的 handlers 名称

notify 所监听的模块只有在发生改变（即状态为 changed）时，才会触发 handlers。如果任务没有发生改变（即状态为 ok），则不会触发 handlers。

# **搭建 NFS**

```bash
root@master:~# cat nfs.yaml
---
- name: 配置所有节点的 NFS 客户端环境
  hosts: work
  become: true
  tasks:
    - name: 安装 NFS 客户端工具
      ansible.builtin.apt:
        name: nfs-common
        state: present
        update_cache: yes
- name: 配置 NFS 服务端
  hosts: srv
  become: true
  vars:
    nfs_export_dir: "/storage/nfs/"
    allow_network: "192.168.0.0/24"
  tasks:
    - name: 安装 NFS 服务端软件包
      ansible.builtin.apt:
        name: nfs-kernel-server
        state: present
    - name: 创建共享目录
      ansible.builtin.file:
        path: "{{ nfs_export_dir }}"
        state: directory
        mode: '0777'
        owner: nobody
        group: nogroup
    - name: 配置 /etc/exports 文件
      ansible.builtin.lineinfile:
        path: /etc/exports
        line: "{{ nfs_export_dir }} {{ allow_network }}(rw,sync,no_subtree_check,no_root_squash)"
        create: yes
      notify: restart nfs server

  handlers:
    - name: restart nfs server
      ansible.builtin.systemd:
        name: nfs-kernel-server
        state: restarted
        enabled: yes
root@master:~# 
root@master:~# ansible-playbook --syntax-check nfs.yaml        # 检验语法
playbook: nfs.yaml
root@master:~# 
root@master:~# ansible-playbook nfs.yaml -b -K
BECOME password: 

PLAY [配置所有节点的 NFS 客户端环境] ****************************************************************************************************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************************************************************************************************************
ok: [node1]
ok: [node2]

TASK [安装 NFS 客户端工具] **************************************************************************************************************************************************************************************************
ok: [node2]
ok: [node1]

PLAY [配置 NFS 服务端] ******************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************************************************************************************************************
ok: [storage-node]

TASK [安装 NFS 服务端软件包] ************************************************************************************************************************************************************************************************
ok: [storage-node]

TASK [创建共享目录] *********************************************************************************************************************************************************************************************************
ok: [storage-node]

TASK [配置 /etc/exports 文件] ***********************************************************************************************************************************************************************************************
ok: [storage-node]

PLAY RECAP ******************************************************************************************************************************************************************************************************************
node1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node2                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
storage-node               : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

root@master:~# 

root@node2:~# mkdir -p /vol-data/nfs
root@node2:~# mount -t nfs storage-node:/storage/nfs /vol-data/nfs
root@node2:~# df -h | grep nfs
storage-node:/storage/nfs           18G  3.0G   14G  18% /vol-data/nfs
root@node2:~# 
root@node2:~# cd /vol-data/nfs/
root@node2:/vol-data/nfs# ls
root@node2:/vol-data/nfs# touch test.{mp3,mp4,pdf}
dd if=/dev/zero of=test.mp4 bs=100M count=1
1+0 records in
1+0 records out
104857600 bytes (105 MB, 100 MiB) copied, 0.966907 s, 108 MB/s
root@node2:/vol-data/nfs# 
root@node2:/vol-data/nfs# ls
test.mp3  test.mp4  test.pdf
root@node2:/vol-data/nfs# 

root@storage-node:~# ls /storage/nfs/
test.mp3  test.mp4  test.pdf
root@storage-node:~# 
```

# 监控

```bash
root@master:~# cat > monitor.sh <<'EOF'
#!/bin/bash

# ===== Load Average (1 min) =====
load=$(awk '{print $1}' /proc/loadavg)
echo "System load (1 min avg): $load"

# ===== Root FS Usage =====
read -r used total <<<$(df -kP / | awk 'NR==2 {print $3, $2}')
used_gb=$(awk "BEGIN {printf \"%.2f\", $used/1024/1024}")
total_gb=$(awk "BEGIN {printf \"%.2f\", $total/1024/1024}")
use_perc=$(awk "BEGIN {printf \"%.0f\", ($used/$total)*100}")

echo "Usage of /: ${use_perc}% (${used_gb}GB / ${total_gb}GB)"

# ===== Memory Usage =====
read -r mem_total_kb mem_avail_kb <<<$(awk '
/MemTotal:/     {t=$2}
/MemAvailable:/ {a=$2}
END {print t, a}
' /proc/meminfo)

mem_used_kb=$((mem_total_kb - mem_avail_kb))
mem_usage=$((100 * mem_used_kb / mem_total_kb))

mem_total_gb=$(awk "BEGIN {printf \"%.2f\", $mem_total_kb/1024/1024}")
mem_used_gb=$(awk "BEGIN {printf \"%.2f\", $mem_used_kb/1024/1024}")

echo "Memory usage: ${mem_usage}% (${mem_used_gb}GB / ${mem_total_gb}GB)"

# ===== IPv4 Address (exclude docker/cni) =====
ip_addr=$(ip -4 addr show scope global \
  | awk '!/docker|cni|flannel/ && /inet/ {print $2; exit}' \
  | cut -d/ -f1)

[ -n "$ip_addr" ] && echo "IPv4 address: $ip_addr"
EOF
root@master:~# 
root@master:~# cat ansible/task.yaml
---
- name: task
  hosts: work
  tasks:
    - name: copy
      ansible.builtin.copy:
        src: /root/monitor.sh
        dest: /home/libix/monitor.sh
  handlers:
    - name: error
      ansible.builtin.shell: 
        echo "Error"
root@master:~# 
root@master:~# ansible-playbook --syntax-check ansible/task.yaml 

playbook: ansible/task.yaml
root@master:~# 
root@master:~# ansible-playbook ansible/task.yaml 

PLAY [task2] ***************************************************************************************************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************************************************************************************************
ok: [node1]
ok: [node2]

TASK [copy] ****************************************************************************************************************************************************************************************************************
changed: [node1]
changed: [node2]

PLAY RECAP *****************************************************************************************************************************************************************************************************************
node1                      : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node2                      : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

root@master:~# 
root@master:~# ansible work -m shell -a "bash monitor.sh"
node2 | CHANGED | rc=0 >>
System load (1 min avg): 0.04
Usage of /: 46% (8.21GB / 17.83GB)
Memory usage: 47% (1.79GB / 3.78GB)
IPv4 address: 192.168.0.12
node1 | CHANGED | rc=0 >>
System load (1 min avg): 0.00
Usage of /: 46% (8.16GB / 17.83GB)
Memory usage: 35% (0.68GB / 1.88GB)
IPv4 address: 192.168.0.11
root@master:~# 
```

