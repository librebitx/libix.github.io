---
layout: default
title:   "Terraform"
date:   2026-01-17
blog-label: Notes
---

# 什么是 Terraform？

[Terraform](https://developer.hashicorp.com/terraform) 是 HashiCorp 出品的一款 **开源基础设施即代码（Infrastructure as Code，IaC）工具**。

使用声明式语言，用代码定义云资源和本地基础设施，帮助自动化创建、管理和变更这些资源。

Terraform 的核心就是解决基础设施管理的复杂性和自动化问题，帮助更高效、更安全、更可控地管理各种云资源和本地资源。

Terraform 通过各种 **Provider 插件** 支持成百上千个不同的平台和服务，覆盖云、私有环境、容器编排、网络设备、SaaS 等，几乎可以管理基础设施的所有层面。

# 安装

二进制安装

https://releases.hashicorp.com/terraform/

```bash
~/Downloads$ chmod +x terraform_1.14.3_linux_amd64.zip 
~/Downloads$ unzip terraform_1.14.3_linux_amd64.zip 
Archive:  terraform_1.14.3_linux_amd64.zip
  inflating: LICENSE.txt             
  inflating: terraform               
~/Downloads$ sudo mv terraform /usr/local/bin/
~/Downloads$ sudo chmod +x /usr/local/bin/terraform 
~/Downloads$ 
~/Downloads$ terraform --version
Terraform v1.14.3
on linux_amd64
~/Downloads$ 
# 卸载	sudo rm /usr/local/bin/terraform
```

# **工作机制**

Terraform 通过各种 **Provider 插件**，把声明式代码“翻译”成对应**平台**的 API 调用，然后由那些平台自身负责具体执行和管理资源。

```bash
~$ mkdir ~/Desktop/terraform & cd ~/Desktop/terraform
~/Desktop/terraform$ cat main.tf 
# 使用本地资源提供者 (Local Provider)
resource "local_file" "hello_debian" {
  content  = "你好，这是由 Terraform 在 Debian 13 (Trixie) 上自动生成的文件！\n创建时间：2026-01-17"
  filename = "${path.module}/hello_terraform.txt"
}
~/Desktop/terraform$ 
~/Desktop/terraform$ terraform init			# 初始化 Terraform 工作目录
# 下载并安装所需的 Provider 插件（比如 local Provider）。
# 初始化工作目录，创建 .terraform 文件夹，并生成 terraform.lock.hcl 文件来记录所需的 Provider 版本	
Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/local...
- Installing hashicorp/local v2.6.1...
- Installed hashicorp/local v2.6.1 (signed by HashiCorp)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary. 
libix@Debian:~/Desktop/terraform$ ls -la
总计 20
drwxrwxr-x 3 libix libix 4096 Jan17日 23:38 .
drwxrwxr-x 6 libix libix 4096 Jan17日 23:37 ..
-rw-rw-r-- 1 libix libix  260 Jan17日 23:37 main.tf
drwxr-xr-x 3 libix libix 4096 Jan17日 23:38 .terraform
-rw-r--r-- 1 libix libix 1153 Jan17日 23:38 .terraform.lock.hcl
libix@Debian:~/Desktop/terraform$ 
# .terraform/ 目录是 Terraform 在初始化一个工作目录时自动创建的文件夹，主要用于存储与 Terraform 工作相关的临时文件和状态信息
# .terraform.lock.hcl 	记录所需的 Provider 版本

~/Desktop/terraform$ terraform plan			# 生成执行计划
# 根据 main.tf 配置文件，分析并生成一个执行计划，展示将要对基础设施做的修改（比如创建、删除、修改资源）
# 看到输出 Terraform 将创建一个 local_file 资源（文件），并展示它将要执行的所有操作（+ create）
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.hello_debian will be created
  + resource "local_file" "hello_debian" {
      + content              = <<-EOT
            你好，这是由 Terraform 在 Debian 13 (Trixie) 上自动生成的文件！
            创建时间：2026-01-17
        EOT
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "./hello_terraform.txt"
      + id                   = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
~/Desktop/terraform$ terraform apply			# 应用配置并实际执行变更
# 根据 terraform plan 生成的执行计划，真正开始创建、修改或删除资源
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.hello_debian will be created
  + resource "local_file" "hello_debian" {
      + content              = <<-EOT
            你好，这是由 Terraform 在 Debian 13 (Trixie) 上自动生成的文件！
            创建时间：2026-01-17
        EOT
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "./hello_terraform.txt"
      + id                   = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

local_file.hello_debian: Creating...
local_file.hello_debian: Creation complete after 0s [id=7185b649cdec3d343015c1d9186d69a1919a0a22]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
~/Desktop/terraform$ ls -a
.  ..  hello_terraform.txt  main.tf  .terraform  .terraform.lock.hcl  terraform.tfstate
~/Desktop/terraform$ cat hello_terraform.txt
你好，这是由 Terraform 在 Debian 13 (Trixie) 上自动生成的文件！
创建时间：2026-01-17
~/Desktop/terraform$ terraform destroy			# 销毁所有由 Terraform 管理的资源
local_file.hello_debian: Refreshing state... [id=7185b649cdec3d343015c1d9186d69a1919a0a22]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # local_file.hello_debian will be destroyed
  - resource "local_file" "hello_debian" {
      - content              = <<-EOT
            你好，这是由 Terraform 在 Debian 13 (Trixie) 上自动生成的文件！
            创建时间：2026-01-17
        EOT -> null
      - content_base64sha256 = "XE0LZIBwMWrVVUFWa03fJ1MxS0dyT+yta41lxZ3OkkI=" -> null
      - content_base64sha512 = "tnsoW9zs13J77qqT9d63zUUXAsOqDfR2ihf3UkLi/ykCNLoX7TzJUR37qdTbp4qgAOvtCZkZMynT4pm9a13jaw==" -> null
      - content_md5          = "cf276572be48d783bc9425b0773a5951" -> null
      - content_sha1         = "7185b649cdec3d343015c1d9186d69a1919a0a22" -> null
      - content_sha256       = "5c4d0b648070316ad55541566b4ddf2753314b47724fecad6b8d65c59dce9242" -> null
      - content_sha512       = "b67b285bdcecd7727beeaa93f5deb7cd451702c3aa0df4768a17f75242e2ff290234ba17ed3cc9511dfba9d4dba78aa000ebed0999193329d3e299bd6b5de36b" -> null
      - directory_permission = "0777" -> null
      - file_permission      = "0777" -> null
      - filename             = "./hello_terraform.txt" -> null
      - id                   = "7185b649cdec3d343015c1d9186d69a1919a0a22" -> null
    }

Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

local_file.hello_debian: Destroying... [id=7185b649cdec3d343015c1d9186d69a1919a0a22]
local_file.hello_debian: Destruction complete after 0s

Destroy complete! Resources: 1 destroyed.
~/Desktop/terraform$ 
~/Desktop/terraform$ ls -a
.  ..  main.tf  .terraform  .terraform.lock.hcl  terraform.tfstate  terraform.tfstate.backup
# terraform.tfstate 是 Terraform 的状态文件，它保存了 Terraform 管理的基础设施的 实际状态
#    当使用 terraform apply 创建、修改或删除资源时，Terraform 会将所有的资源状态（如 ID、属性等）保存在这个文件中
#    通过该文件，Terraform 可以知道基础设施当前的状态，以便在下次执行时进行差异比较，决定哪些资源需要变更
# terraform.tfstate.backup 是 terraform.tfstate 文件的备份，在 Terraform 执行时，它会自动保存一份状态文件的备份。
# 	 这个文件用于防止数据丢失，如果主状态文件 terraform.tfstate 损坏或丢失，你可以通过这个备份文件恢复 Terraform 的状态。
~/Desktop/terraform$ 

```

# 虚拟化平台

## 基于 Libvirt/KVM

https://librebitx.github.io/2026/01/15/KVM/#%E5%AE%89%E8%A3%85-kvm

**最推荐的 Linux 原生方案**，直接调用 Linux 底层虚拟化，性能最高。

**为什么在虚拟机上使用 Terraform？**

> **标准化**：如果你需要开 10 台配置一模一样的虚拟机，手动克隆很容易出错（比如忘记改主机名或 IP），但在 Terraform 里只需要改一个数字 `count = 10`。
>
> **版本化环境**：你可以把开发环境的配置存入 Git。如果你不小心把虚拟机搞崩了，直接 `destroy` 然后 `apply`，30 秒内就能还你一台全新的、配置好的机器。
>
> **Cloud-Init 配合**：Terraform 可以配合 `cloud-init` 脚本，在虚拟机创建的一瞬间就自动设置好 SSH 密钥、安装好 Nginx 和 Docker。

 Terraform 能控制的是：

虚拟机的创建、修改和销毁；

启动前的配置： 例如 `cloud-init` 脚本，就是在虚拟机开机时执行的“首次初始化”；

资源状态的声明式管理：写代码声明想要的状态，Terraform 负责同步达到这个状态。

Terraform 不能控制虚拟机开机后的运行时状态。（可以用 Terraform 触发 Ansible、SaltStack 等配置管理工具）

```bash

```



# 问题解决

## 自定义镜像目录后报错

**Error: error creating libvirt domain: 无法访问存储文件 '/home/libix/Desktop/terraform/ubuntu-template.qcow2'（以 uid:64055、gid:64055身份）: 权限不够**

```bash
# 添加三行代码
libix@Debian:~/Desktop/terraform$ sudo cat /etc/libvirt/qemu.conf
...
user = "libix"
group = "libix"
security_driver = "none"
libix@Debian:~/Desktop/terraform$ sudo systemctl restart ibvirtd
libix@Debian:~/Desktop/terraform$
```

# 基础设施即代码（Infrastructure as Code, IaC）

用代码来描述你想要的基础设施状态，无论它是物理资源还是虚拟资源。

代码写的是期望的资源配置和拓扑，然后 IaC 工具（如 Terraform）帮你自动“申请”、“创建”、“配置”这些资源。

Terraform（管硬件：开服务器） + Ansible（管软件：装配置）
