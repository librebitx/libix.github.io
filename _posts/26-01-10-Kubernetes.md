---
layout: default
title:  "Kubernetes"
date:   2026-01-09
blog-label: Notes
---

# 什么是 kubernetes？

**Kubernetes（简称 K8s） 是一个“自动化管理容器的操作系统级平台”**用来 **部署、调度、扩缩容、修复、升级** 容器化应用。

可以把它理解为给服务器用的**容器调度操作系统**

当有几十上百台机器时，人已经管不过来了，Kubernetes 就是为了解决这个问题诞生的。

![](/public/K8S/kubernetes-cluster-architecture.svg)

# 搭建 Kubernetes 集群

```bash
### Ubuntu 22.04
# 临时关闭
sudo swapoff -a

# 永久关闭 (注释掉 /etc/fstab 中的 swap 行)
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# 应用配置
sudo sysctl --system

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# 添加 Docker 的 GPG Key (使用阿里云源)
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 添加 Docker 仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install apt-transport-https

# 安装 Containerd
sudo apt-get update
sudo apt-get install -y containerd.io

# 生成默认配置
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# 1. 将 SystemdCgroup 设置为 true
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# 2. 将 sandbox_image 替换为阿里云镜像 (registry.k8s.io 替换为 registry.aliyuncs.com/google_containers)
sudo sed -i 's/registry.k8s.io\/pause/registry.aliyuncs.com\/google_containers\/pause/g' /etc/containerd/config.toml

# 重启 containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# 添加阿里云 K8s GPG Key
curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# 添加仓库
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# 锁定版本
sudo apt-mark hold kubelet kubeadm kubectl

### 仅 master 节点
# 请确保将 192.168.0.10 替换为 Master IP
sudo kubeadm init \
  --apiserver-advertise-address=192.168.0.10 \
  --image-repository registry.aliyuncs.com/google_containers \
  --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> /etc/profile
source /etc/profile
```

## Calico 网络插件

### 导入 calico 镜像（所有节点）

将 calico 离线镜像 tar 包分别上传 3 个节点。crictl 查询的所有镜像，来自于底层 k8s.io 命名空间，使用 ctr 将 tar 包导入 k8s.io 命名空间。

```bash
# 导入 calico 镜像到 kmaster
# 执行导入
~#
sudo ctr -n k8s.io image import apiserver-v3.28.0.tar
sudo ctr -n k8s.io image import cni-v3.28.0.tar csi-v3.28.0.tar
sudo ctr -n k8s.io image import csi-v3.28.0.tar
sudo ctr -n k8s.io image import kube-controllers-v3.28.0.tar
sudo ctr -n k8s.io image import node-driver-registrar-v3.28.0.tar
sudo ctr -n k8s.io image import node-v3.28.0.tar
sudo ctr -n k8s.io image import operator-v1.34.0.tar
sudo ctr -n k8s.io image import pod2daemon-flexvol-v3.28.0.tar
sudo ctr -n k8s.io image import typha-v3.28.0.tar

~# crictl images            # 查看当前已下载的容器镜像列表

IMAGE                                                             TAG                 IMAGE ID            SIZE
docker.io/calico/apiserver                                        v3.28.0             6c07591fd1cfa       97.9MB
docker.io/calico/cni                                              v3.28.0             107014d9f4c89       209MB
docker.io/calico/csi                                              v3.28.0             1a094aeaf1521       18.3MB
docker.io/calico/kube-controllers                                 v3.28.0             428d92b022539       79.2MB
docker.io/calico/node-driver-registrar                            v3.28.0             0f80feca743f4       23.5MB
docker.io/calico/node                                             v3.28.0             4e42b6f329bc1       355MB
docker.io/calico/pod2daemon-flexvol                               v3.28.0             587b28ecfc62e       13.4MB
docker.io/calico/typha                                            v3.28.0             a9372c0f51b54       71.2MB
quay.io/tigera/operator                                           v1.34.0             01249e32d0f6f       73.7MB
registry.aliyuncs.com/google_containers/coredns                   v1.11.1             cbb01a7bd410d       18.2MB
registry.aliyuncs.com/google_containers/etcd                      3.5.10-0            a0eed15eed449       56.6MB
registry.aliyuncs.com/google_containers/kube-apiserver            v1.29.2             8a9000f98a528       35.1MB
registry.aliyuncs.com/google_containers/kube-controller-manager   v1.29.2             138fb5a3a2e34       33.4MB
registry.aliyuncs.com/google_containers/kube-proxy                v1.29.2             9344fce2372f8       28.4MB
registry.aliyuncs.com/google_containers/kube-scheduler            v1.29.2             6fc5e6b7218c7       18.5MB
registry.aliyuncs.com/google_containers/pause                     3.6                 6270bb605e12e       302kB
registry.aliyuncs.com/google_containers/pause                     3.9                 e6f1816883972       322kB
~#

# node1、node2 同理
```

### 部署 calico（仅 master 节点）

将两个 yaml 文件上传到 master，并按照顺序分别执行

```bash
~/calico# 
kubectl create -f tigera-operator-v3.28.0.yaml

kubectl create -f custom-resources-v3.28.0.yaml

~/calico# kubectl get pod -n calico-system
NAME                                      READY   STATUS    RESTARTS   AGE
calico-kube-controllers-56fd574ff-xnjfm   1/1     Running   0          70s
calico-node-52xjm                         1/1     Running   0          70s
calico-node-mvddg                         1/1     Running   0          70s
calico-node-thn86                         1/1     Running   0          70s
calico-typha-8799df89c-bfhj6              1/1     Running   0          65s
calico-typha-8799df89c-nxvt2              1/1     Running   0          70s
csi-node-driver-9b275                     2/2     Running   0          70s
csi-node-driver-ghknb                     2/2     Running   0          70s
csi-node-driver-lgrt8                     2/2     Running   0          70s

~/calico# kubectl get nodes
NAME      STATUS   ROLES           AGE   VERSION
kmaster   Ready    control-plane   29m   v1.30.0
knode1    Ready    <none>          26m   v1.30.0
knode2    Ready    <none>          26m   v1.30.0
```

## 配置 Containerd 代理

默认情况下，镜像会从 **Docker Hub (docker.io)** 拉取。在 Kubernetes 中，镜像名称如果是不完整的（Unqualified），系统会应用默认规则进行补全。当你输入 nginx 时，容器运行时（Container Runtime，如 containerd 或 CRI-O）会将其解析为完整的标准路径：`docker.io/library/nginx:latest`。

这个路径由四部分组成：
*   **Registry (仓库地址):** 默认为 `docker.io` (Docker Hub)。
*   **Namespace (命名空间/项目):** 对于 Docker Hub 的官方镜像，默认为 `library`。
*   **Image Name (镜像名):** 你指定的 `nginx`。
*   **Tag (标签):** 如果你没有指定版本（例如没有写 `nginx:1.24`），默认自动加上 `:latest`。

```bash
# 每台主机都要做
mkdir -p /etc/systemd/system/containerd.service.d
cat > /etc/systemd/system/containerd.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://192.168.0.5:7897"
Environment="HTTPS_PROXY=http://192.168.0.5:7897"
Environment="NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16,10.244.0.0/16,.svc,.cluster.local"
EOF
systemctl daemon-reload
systemctl restart containerd
```

## 配置命令行自动补全

```bash
~# apt-get update && apt-get install -y bash-completion
source /usr/share/bash-completion/bash_completion
cat <<EOL>> /etc/profile

source <(kubectl completion bash)
EOL
source /etc/profile
```

# namespace

在 Kubernetes 中，命名空间 (Namespaces) 提供了一种将集群资源划分为多个独立、逻辑隔离的“**虚拟集群**”的方式。它们是 Kubernetes 中用于组织和隔离资源的一种机制。

```bash
~# kubectl create namespace ns-test        # 新建命名空间
namespace/ns-test created

~# kubectl get namespace            # 查看所有命名空间
NAME               STATUS   AGE
calico-apiserver   Active   2d1h
calico-system      Active   2d1h
default            Active   2d2h
kube-node-lease    Active   2d2h
kube-public        Active   2d2h
kube-system        Active   2d2h
ns-test            Active   6s
tigera-operator    Active   2d1h

~# kubectl describe namespaces ns-test             # 显示详情
Name:         ns-test
Labels:       kubernetes.io/metadata.name=ns-test
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.

~# kubectl delete namespaces ns-test             # 删除
namespace "ns-test" deleted

~# kubectl get pod        # 默认处于 default 命名空间
No resources found in default namespace.

~# kubectl config get-contexts            # 列出所有配置的上下文
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin   
# 此时命名空间列为空，代表默认命名空间为 default

~# kubectl config set-context --current --namespace kube-system            # 修改默认命名空间为 kube-system
Context "kubernetes-admin@kubernetes" modified.
```

## **kubens**

使用 `kubens` 脚本可以更方便的更换所在命名空间。该脚本必须移动到 `/bin` 目录下使用！

```bash
~# 
mv kubens /bin/
chmod +x /bin/kubens

~# kubens            # 查看所有命名空间
calico-apiserver
calico-system
default
kube-node-lease
kube-public
kube-system
tigera-operator

~# kubens default            # 切换所在命名空间为 default
Context "kubernetes-admin@kubernetes" modified.
Active namespace is "default".

~# kubectl get pod
No resources found in default namespace.
```

# Pod

## **镜像拉取策略**

创建 pod 的前提是要有对应的镜像，在 yaml 文件里可以指定创建 pod 时使用镜像的方式：
*   **Always**：它每次都会联网检查最新的镜像，不管你本地有没有。
*   **Never**：它只会使用本地镜像，从不下载。
*   **IfNotPresent**：它如果检测本地没有镜像，才会联网下载；如果有，则联网检测版本；如果联不通外网，则直接用本地。

可以把 `crictl` 类比为 Kubernetes 时代的“精简版 docker 命令”。`crictl pull` 调用的是 CRI 运行时，拉取的镜像会出现在 `crictl images` 中。

## **创建 pod**

在 k8s 集群里面，k8s 调度的最小单位是 pod，pod 里面跑容器。如何创建一个 pod：1.命令行 2.yaml 文件（推荐后者）。

Kubernetes 有一个叫做 **调度器 (scheduler)** 的组件。当您创建一个 Pod 时，调度器会自动选择一个最合适的节点来运行这个 Pod。

### **命令行创建 pod**

```bash
~# kubectl run pod1 --image nginx
pod/pod1 created

~# kubectl get pod
NAME   READY   STATUS              RESTARTS   AGE
pod1   0/1     ContainerCreating   0          9s

~# kubectl get pod -o wide            # 获取 Pod 详细信息
NAME   READY   STATUS    RESTARTS   AGE   IP               NODE     NOMINATED NODE   READINESS GATES
pod1   1/1     Running   0          83s   10.244.195.133   knode1   <none>           <none>

~# kubectl describe pod pod1            # 查看 Pod1 详细信息

~# crictl pull nginx:1.20    
~# crictl images | grep nginx
docker.io/library/nginx                                           1.20                0584b370e957b       56.7MB

~# kubectl run pod5 --image nginx --image-pull-policy IfNotPresent    # 本地有直接启动，没有再下载
# 提前在所有 node 上拉取 nginx:1.20
~# kubectl run testpod --image=nginx:1.20 --image-pull-policy=Never
pod/testpod created

~# kubectl get pods
NAME      READY   STATUS      RESTARTS   AGE
pod1      0/1     Completed   0          111m
testpod   1/1     Running     0          2s
```

### **yaml 文件创建 pod**

```bash
~# kubectl run pod1 --image nginx --image-pull-policy IfNotPresent --dry-run=client -o yaml > pod2.yaml
# 以 dry-run（试运行）模式生成 YAML，不实际创建 Pod。

~# cat <<EOL> pod1.yaml
apiVersion: v1            # API 版本
kind: Pod                 # 资源类型
metadata:                 # 元数据
  creationTimestamp: null
  labels:
    run: pod1            # 标签
  name: pod1             # Pod 名称
spec:                     # 期望状态
  nodeName: knode1        # 指定调度节点
  containers:
  - image: crpi-bkg7bvmf5xyivcsd.cn-shanghai.personal.cr.aliyuncs.com/onlymyself/onlymyself-hub:wordpress
    imagePullPolicy: IfNotPresent
    name: pod1
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
EOL

~# kubectl apply -f pod1.yaml
~# kubectl get pod -o wide
NAME   READY   STATUS    RESTARTS   AGE     IP               NODE     NOMINATED NODE   READINESS GATES
pod1   1/1     Running   0          3m14s   10.244.195.152   knode1   <none>           <none>
```

## **create 与 apply 的区别**
在使用 yaml 文件创建 pod 时，如果是初次创建，二者无区别；若需更改 yaml 后更新配置，只有 `apply` 可以更新并创建，`create` 则会报错。

## **一个 pod 里面启动多个容器**

```bash
~# cat <<EOL> pod11.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod11
  name: pod11
spec:
  containers:
  - args:
    - sleep
    - "3600"
    image: nginx
    imagePullPolicy: IfNotPresent
    name: r1
    resources: {}
  - image: crpi-bkg7bvmf5xyivcsd.cn-shanghai.personal.cr.aliyuncs.com/onlymyself/onlymyself-hub:wordpress
    imagePullPolicy: IfNotPresent
    name: r2
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
EOL

~# kubectl exec -ti pod11 -c r1 -- bash            # 进入指定容器
```

## **删除 pod**

```bash
kubectl delete -f pod1.yaml
kubectl delete pods pod1
kubectl delete pods pod{3,4,5}
kubectl delete pods --all
```

## **pod 重启策略**

*   **Always**: 总是重启（默认）。
*   **Never**: 永不重启。
*   **OnFailure**: 仅在故障时重启。

## **静态 pod**

静态 Pod 是由 **kubelet** 进程直接管理并运行在特定节点上的 Pod，而不需要通过 API Server 进行调度。
在集群目录 /etc/kubernetes/manifests/ 下会放着一些 yaml 文件，这些都是静态 pod 所属的文件。主要是为集群提供功能支撑的。只需要把文件放在里面，就会在集群里面创建一个 pod，把文件移走，pod 就会自动删除。
K8s 的核心组件本质上就是运行在 K8s 里的 Pod；K8s 是一个用 Pod 管理 Pod 的递归系统。 只有最底层的 kubelet 和 容器引擎 是钉在操作系统上的，其他的都可以是容器。

# Label

标签分为两种类型：node 标签、pod 标签
标签规范: 键=值
beta.kubernetes.io/arch=amd64
aaa.bbb=ccc
aaa.bbb/ccc=ddd
## **node 标签**

```bash
~# kubectl get nodes --show-labels            # 查看集群中所有节点的标签信息
NAME      STATUS   ROLES           AGE     VERSION   LABELS
kmaster   Ready    control-plane   2d19h   v1.30.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=kmaster,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=
knode1    Ready    <none>          2d19h   v1.30.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=knode1,kubernetes.io/os=linux
knode2    Ready    <none>          2d19h   v1.30.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=knode2,kubernetes.io/os=linux
~# kubectl label nodes knode2 aaa=bbb            # 在节点 knode2 上添加或更新标签 aaa=bbb

node/knode2 labeled
~# kubectl label nodes knode2 zzz=yyy disk=ssd          # 为节点 knode2 添加/修改多个标签
~# kubectl get nodes knode2 --show-labels            # 查看节点 knode2 的所有标签信息
NAME     STATUS   ROLES    AGE     VERSION   LABELS
knode2   Ready    <none>   5d23h   v1.29.2   aaa=bbb,beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,disk=ssd,kubernetes.io/arch=amd64,kubernetes.io/hostname=knode2,kubernetes.io/os=linux,zzz=yyy

~# kubectl label nodes knode2 aaa-            # 删除 node 标签
node/knode2 unlabeled
# node 上的特殊标签
# node-role.kubernetes.io/control-plane=            # 是一个节点标签，标识运行集群核心控制组件的节点，用于标识集群中的控制平面节点（Control Plane Node），也通常被称为主节点（Master Node）
#     node-role.kubernetes.io            # 这是 Kubernetes 约定俗成的标签前缀，用于表示节点的角色 (role)
#     control-plane                      # 这是角色的具体名称，明确指出该节点承担控制平面功能

~# kubectl label nodes kmaster node-role.kubernetes.io/control-plane-            # 从主节点 kmaster 上移除控制平面角色标签
node/kmaster unlabeled
~# kubectl get nodes kmaster -o wide
NAME      STATUS   ROLES    AGE     VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION              CONTAINER-RUNTIME
kmaster   Ready    <none>   2d20h   v1.30.0   192.168.100.200   <none>        CentOS Linux 8   4.18.0-305.3.1.el8.x86_64   containerd://1.6.32

~# kubectl label nodes kmaster node-role.kubernetes.io/master=            # 为主节点 kmaster 添加或更新控制平面角色标签
node/kmaster labeled
~# kubectl label nodes knode1 node-role.kubernetes.io/work1=
node/knode1 labeled
~# kubectl label nodes knode2 node-role.kubernetes.io/work2=
node/knode2 labeled
~# kubectl get nodes -o wide
NAME      STATUS   ROLES    AGE     VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION              CONTAINER-RUNTIME
kmaster   Ready    master   2d20h   v1.30.0   192.168.100.200   <none>        CentOS Linux 8   4.18.0-305.3.1.el8.x86_64   containerd://1.6.32
knode1    Ready    work1    2d20h   v1.30.0   192.168.100.201   <none>        CentOS Linux 8   4.18.0-305.3.1.el8.x86_64   containerd://1.6.32
knode2    Ready    work2    2d20h   v1.30.0   192.168.100.202   <none>        CentOS Linux 8   4.18.0-305.3.1.el8.x86_64   containerd://1.6.32
~#
```

## **pod 标签**
**pod 上的标签是给 deployment 管理用的**

```bash
~# kubectl label pods pod1 aaa=bbb ccc=ddd            # 新增 pod 标签
pod/pod1 labeled

~# kubectl get pods --show-labels            # 查看 pod 标签
NAME   READY   STATUS    RESTARTS   AGE   LABELS
pod1   1/1     Running   0          92s   aaa=bbb,ccc=ddd,run=pod1

~# kubectl label pods pod1 aaa- ccc-            # 删除 pod 标签
pod/pod1 unlabeled
~# kubectl get pods --show-labels
NAME   READY   STATUS    RESTARTS   AGE    LABELS
pod1   1/1     Running   0          116s   run=pod1
```

## **将 pod 发放到指定节点**
**nodeName**
这个字段允许直接指定 Pod 调度到目标节点 (node)
**nodeSelector**
nodeSelector 是 Pod 规范（Spec）中的一个字段。它通过 **键值对（Key-Value Pair）** 的方式，让 Pod 与 Node 的 **标签（Labels）** 进行匹配。键（Key）和值（Value）都**必须完全匹配，缺一不可。**
Pod 会告诉调度器，我只想去那些身上贴了特定“标签”的 Node 上工作。
如果集群中没有节点满足**所有**标签条件，那么该 Pod 将会一直处于 Pending 状态，直到有合适的节点出现。

```bash
~# cat <<EOL> pod4.yaml
apiVersion:v1
kind:Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod4
  name: pod4
spec:
  nodeSelector:            # 借助 nodeSelector 调度字段
    aaa: bbb
  containers:
  - image: crpi-bkg7bvmf5xyivcsd.cn-shanghai.personal.cr.aliyuncs.com/onlymyself/onlymyself-hub:wordpress
    imagePullPolicy: Never
    name: pod4
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: OnFailure
status:{}
EOL

~# kubectl get nodes --show-labels
NAME      STATUS   ROLES    AGE     VERSION   LABELS
kmaster   Ready    master   2d20h   v1.30.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=kmaster,kubernetes.io/os=linux,node-role.kubernetes.io/master=,node.kubernetes.io/exclude-from-external-load-balancers=
knode1    Ready    work1    2d20h   v1.30.0   aaa=bbb,beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=knode1,kubernetes.io/os=linux,node-role.kubernetes.io/work1=
knode2    Ready    work2    2d20h   v1.30.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,ccc=ddd,kubernetes.io/arch=amd64,kubernetes.io/hostname=knode2,kubernetes.io/os=linux,node-role.kubernetes.io/work2=

~# kubectl apply -f pod4.yaml
pod/pod4 created


~# kubectl get pods -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP               NODE     NOMINATED NODE   READINESS GATES
pod1   1/1     Running   0          22m   10.244.195.137   knode1   <none>           <none>
pod4   1/1     Running   0          21s   10.244.195.138   knode1   <none>           <none>
~# kubectl delete -f pod4.yaml
pod "pod4" deleted
~# kubectl label nodes knode1 aaa-
node/knode1 unlabeled
~# kubectl apply -f pod4.yaml
pod/pod4 created
~# kubectl get pods -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP               NODE     NOMINATED NODE   READINESS GATES
pod1   1/1     Running   0          27m   10.244.195.137   knode1   <none>           <none>
pod4   0/1     Pending   0          2s    <none>           <none>   <none>           <none>
~# kubectl label nodes knode2 aaa=bbb
node/knode2 labeled
~# kubectl get pods -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP               NODE     NOMINATED NODE   READINESS GATES
pod1   1/1     Running   0          29m   10.244.195.137   knode1   <none>           <none>
pod4   1/1     Running   0          54s   10.244.69.199    knode2   <none>           <none>
```

## **cordon / drain / taint**
在 Kubernetes 中管理**节点 (node)** 状态和工作负载时非常重要的工具
cordon 警戒线：用于将一个节点标记为**不可调度 (unschedulable)**。
drain 驱逐：一旦设置了 drain，不仅会 cordon，还会 evicted 驱逐。（本意是把该节点上的 pod 删除掉，并在其他 node 上启动）
taint 污点：一但设置了 taint，默认调度器会直接过滤掉，不会调度到该 node 上，但是可以通过 tolerations 关键字来强制的运行。

### **cordon**
用于将一个节点标记为 **不可调度 (unschedulable)** 。一旦对某个节点设置了 cordon，那么就告诉 k8s 集群，未来发放的 pod 不要再调度到该节点上了；
对于节点上已经存在的 pod 不受影响。
比如有两个节点，当创建一个 pod 的时候，会根据 scheduler 调度算法，分布在不同的节点上。现在有 knode1 和 knode2 两个节点，如果 knode1 节点要维护或检查，设置 cordon 后，新创建的 pod 就不能再调度到 node1 上了。

```bash
~# kubectl cordon knode2            # 开启 cordon
node/knode2 cordoned
~# kubectl apply -f pod2.yaml
pod/pod2 created
~# kubectl apply -f pod3.yaml
pod/pod3 created
~# kubectl get pods -o wide
NAME   READY   STATUS    RESTARTS      AGE     IP               NODE     NOMINATED NODE   READINESS GATES
pod1   1/1     Running   1 (10m ago)   5h16m   10.244.195.143   knode1   <none>           <none>
pod2   1/1     Running   0             11s     10.244.195.144   knode1   <none>           <none>
pod3   1/1     Running   0             8s      10.244.195.145   knode1   <none>           <none>
~# kubectl delete pods pod2 pod3
pod "pod2" deleted
pod "pod3" deleted
~# kubectl uncordon knode2            # 取消 cordon
node/knode2 uncordoned
~# kubectl apply -f pod2.yaml
pod/pod2 created
~# kubectl apply -f pod3.yaml
pod/pod3 created
~# kubectl get pods -o wide
NAME   READY   STATUS    RESTARTS      AGE     IP               NODE     NOMINATED NODE   READINESS GATES
pod1   1/1     Running   1 (14m ago)   5h19m   10.244.195.143   knode1   <none>           <none>
pod2   1/1     Running   0             8s      10.244.69.204    knode2   <none>           <none>
pod3   1/1     Running   0             3s      10.244.69.205    knode2   <none>           <none>
```

### drain

对比 cordon ， drain 多了一个驱逐的动作。包含两个动作（ cordon / evicted ）。

**自动 cordon 节点：**
drain 命令首先会自动将目标节点标记为不可调度 (unschedulable)，就像执行了 kubectl cordon 一样，以防止新的 Pod 在驱逐过程中被调度上来。

**安全驱逐 Pod：**
它会优雅地终止节点上的 Pod。这意味着它会向 Pod 发送 SIGTERM 信号，并等待 Pod 的 terminationGracePeriodSeconds (默认 30 秒) 结束。如果 Pod 在此期间没有自行终止，则会发送 SIGKILL 强制终止。

它会尊重 PodDisruptionBudgets (PDBs)。PDB 是一种机制，用于确保在自愿中断（如 drain）期间，一个应用至少有多少个副本保持运行状态。如果驱逐某个 Pod 会违反其应用的 PDB，drain 操作会暂时阻塞，直到可以安全驱逐为止（或者超时）。

**处理不同类型的 Pod：**

- **普通 Pod (由 ReplicaSet, Deployment, StatefulSet 等控制器管理的)：** 这些 Pod 被删除后，控制器通常会自动在其他可用节点上创建新的副本，以维持期望的副本数。
- **DaemonSet 管理的 Pod：**默认情况下，drain 不会删除 DaemonSet 管理的 Pod，因为 DaemonSet 的设计就是要在每个（或特定）节点上都运行一个副本。如果你确实想删除它们，需要使用 --ignore-daemonsets 标志。即使删除了，如果节点恢复并且 DaemonSet 控制器仍然认为该节点需要一个副本，它通常会重新创建。
- **没有控制器的裸 Pod (Bare Pods)：** 默认情况下，drain 不会删除没有被任何控制器（如 Deployment, ReplicaSet 等）管理的 Pod，因为删除它们后，这些 Pod 就不会被自动重建。你需要使用 --force 标志来强制删除这类 Pod。
- **使用 emptyDir 卷的 Pod：** 如果 Pod 使用了 emptyDir 卷，当 Pod 被删除时，emptyDir 中的数据会丢失。drain 命令默认会失败，除非你指定 --delete-emptydir-data (Kubernetes 1.13 及之后版本，早期版本可能是 --delete-local-data) 来确认你知道并同意删除这些数据。

你可以把它想象成：酒店要进行全面装修，不仅不再接受新客人 (cordon)，还会礼貌地请现有客人退房 (evict)，并帮他们安排到其他酒店（如果 Pod 有控制器管理）。

单个 pod 看不到效果，配合 deployment 可以看到效果。

### **Taint**
Taint (污点) 就是用来实现这种 “排斥” 需求的。
主控节点 (Master/Control-Plane Node) 运行着 Kubernetes 的核心组件，非常重要，你不希望普通的应用 Pod 占用它们的资源或可能影响它们的稳定性。
具有特殊硬件的节点，比如带有 GPU 的节点，你可能只想让需要 GPU 的特定应用在上面运行。
需要维护的节点，你可能想临时阻止新的 Pod 调度到某个节点上，并驱逐现有 Pod，以便进行维护。

**什么是 Taint (污点)？**
Taint 是应用到节点 (Node) 上的一个属性。它会 “排斥” 那些不能 “容忍” 这个污点的 Pod。也就是说，默认情况下，Pod 不会被调度到带有它不能容忍的污点的节点上。
可以把 Taint 看作是节点给 Pod 设置的一个 “门槛” 或者 “条件”。

**Taint 的组成**
一个 Taint 由三个部分组成：
**键 (Key):** 必需的，是一个字符串，例如 gpu、node-role.kubernetes.io/master。
**值 (Value):** 可选的，也是一个字符串，与键一起描述污点的具体含义，例如 true、nvidia-tesla-v100。如果不需要值，可以省略。
**效果 (Effect):** 必需的，决定了当 Pod 不能容忍这个污点时会发生什么。
**格式：** =: ( 如果值为空，则是 : )
**Taint 的效果 (Effect)**
有三种主要的效果：
**NoSchedule (不调度):** 这是最常用的效果。
如果一个 Pod 不能容忍带有 NoSchedule 效果污点的节点，那么 Kubernetes 调度器不会将这个 Pod 调度到该节点上。
NoSchedule 只影响新调度的 Pod。对于那些在节点被打上污点之前就已经在该节点上运行的 Pod，它们不会被驱逐。
**PreferNoSchedule (倾向于不调度):** 这是一个 “软” 限制。
Kubernetes 调度器会尽量避免将不能容忍此污点的 Pod 调度到该节点上。
但是，如果没有其他更合适的节点可以调度，调度器仍然可能将该 Pod 调度到这个带有 PreferNoSchedule 污点的节点上。
**NoExecute (不执行并驱逐):** 这是最强的效果。
如果 Pod 不容忍，不但阻止新的 Pod 调度到该节点，而且驱逐 (evict) 节点上已经运行的、且不能**容忍**该污点的 Pod。

对于一个典型的 Kubernetes 控制平面节点 (master/control-plane node)，会看到至少一个默认的污点。这是 Kubernetes 为了保护控制平面组件不被普通用户工作负载干扰而设置的。

```bash
~# kubectl describe nodes kmaster | grep -i taint            # 查看当前节点存在的污点
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
~# kubectl describe nodes knode1 | grep -i taint
Taints:             <none>

# 体现 NoSchedule 效果
~# kubectl get pods -o wide
NAME   READY   STATUS    RESTARTS   AGE    IP               NODE     NOMINATED NODE   READINESS GATES
pod1   1/1     Running   0          103s   10.244.195.146   knode1   <none>           <none>
~# kubectl taint nodes knode1 memeda=hehehe:NoSchedule
node/knode1 tainted
~# kubectl taint nodes knode2 memeda=hehehe:NoSchedule
node/knode2 tainted

~# kubectl apply -f pod2.yaml
pod/pod2 created
~# kubectl get pods -o wide
NAME   READY   STATUS    RESTARTS   AGE    IP               NODE     NOMINATED NODE   READINESS GATES
pod1   1/1     Running   0          112s   10.244.195.146   knode1   <none>           <none>
pod2   0/1     Pending   0          3s     <none>           <none>   <none>           <none>

# 体现 PreferNoSchedule 效果
~# kubectl describe nodes | grep -i taint
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
Taints:             memeda=hehehe:NoSchedule
Taints:             memeda=hehehe:NoSchedule
~# kubectl taint node knode1 memeda=hehehe:NoSchedule-            # 移除污点
node/knode2 untainted
~# kubectl taint node knode2 memeda=hehehe:NoSchedule-
node/knode1 untainted
~# kubectl taint nodes knode1 memeda=hehehe:PreferNoSchedule
node/knode2 tainted
~# kubectl taint nodes knode2 memeda=hehehe:PreferNoSchedule
node/knode1 tainted
~# kubectl apply -f pod2.yaml
pod/pod2 created

~# kubectl get pods -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP               NODE     NOMINATED NODE   READINESS GATES
pod1   1/1     Running   0          14m   10.244.195.141   knode1   <none>           <none>
pod2   1/1     Running   0          30s   10.244.69.204    knode2   <none>           <none>

# 体现 NoExecute 效果
~# kubectl describe nodes | grep -i taint
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
Taints:             memeda=hehehe:NoExecute
Taints:             memeda=hehehe:NoExecute
~# cat <<EOL> pod2.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod2
  name: pod2
spec:
  tolerations:                   # 用于声明 Pod 可以容忍哪些污点
  - key: "memeda"                # 定义了 Pod 容忍的污点键
    operator: "Equal"            # 定义了匹配污点的方式
    value: "hehehe"              # 定义了 Pod 容忍的污点值
    effect: "NoExecute"          # 定义了 Pod 容忍的污点效果，这里留空表示容忍所有效果
  containers:
  - image: crpi-bkg7bvmf5xyivcsd.cn-shanghai.personal.cr.aliyuncs.com/onlymyself/onlymyself-hub:wordpress
    imagePullPolicy: Never
    name: pod2
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: OnFailure
status: {}
EOL

~# kubectl apply -f pod2.yaml
pod/pod2 created

~# kubectl get pods -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP               NODE     NOMINATED NODE   READINESS GATES
pod2   1/1     Running   0          2s    10.244.195.144   knode1   <none>           <none>
~# kubectl delete pods pod2
pod "pod2" deleted

~# kubectl apply -f pod1.yaml
pod/pod1 created
~# kubectl get pods -o wide
No resources found in default namespace.
```

现在我们知道了 Taint 会排斥 Pod，那么如果一个 Pod 确实想运行在一个有污点的节点上呢？这就需要 Toleration (容忍)。

### Toleration
Toleration（容忍） 是定义在 **Pod** 的 spec 中的。它允许（但并不保证）Pod 被调度到带有匹配污点的节点上。
属于**不可变字段**，禁止在线修改，除了 tolerationSeconds；
一个 Toleration 的组成：
**key:** 要容忍的污点的键
**value (可选):** 要容忍的污点的值
**operator (可选):**
​	**Exists (存在即可):** 只要与污点的 key 或者 effect 匹配，就认为容忍。此时 value 字段会被忽略（即使你写了）。	

| 组合方式           | 匹配效果                                                     | 运维场景                                                     |
| ------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 有 Key + 有 Effect | 精确匹配。只容忍特定 Key 的特定效果。                        | 针对性容忍。如：只容忍 node1 上的 NoExecute 驱逐。           |
| 有 Key + 无 Effect | 半模糊匹配。只要 Key 对上了，管你是 NoSchedule 还是 NoExecute 全都容忍。 | 最推荐用法。防止节点状态变化（如从不可调度变成驱逐）导致 Pod 掉线。 |
| 无 Key + 无 Effect | 超级通配符。容忍集群里所有节点的所有污点。                   | 核心组件专用。如日志收集、监控插件（Prometheus, Fluentd）。  |
| 无 Key + 有 Effect | 容忍该 Effect 下的所有 Key。                                 | 希望监控插件能部署在集群中所有“活着”的节点上，不管这些节点是因为磁盘满了还是网络延迟。 |
​	**Equal  (相等才行):** 污点的 key、value (如果污点有值) 和 effect **都必须**和 Toleration 中定义的**完全匹配**。这是默认的 operator（操作符）。
**effect (可选): 可以容忍的污点的效果**
​	如果 effect 为空，则表示容忍所有效果（NoSchedule, PreferNoSchedule, NoExecute）的具有相同 key 和 value (根据 operator 判断) 的污点。
​	如果指定了 effect，则只容忍具有特定效果的污点。
**tolerationSeconds (可选, 仅用于 NoExecute 效果):**
tolerationSeconds 字段指定了在节点被 NoExecute 污点标记时，具有相应容忍度的 Pod 可以在该节点上继续运行多长时间，然后才会被驱逐。
当一个节点被添加了 NoExecute 效果的污点时：
​	没有容忍该污点的 Pod：会立即被驱逐。
​	容忍该污点但没有指定 tolerationSeconds 的 Pod：会永远绑定在该节点上（即不会被驱逐），只要节点上的污点仍然存在。
​	容忍该污点且指定了 tolerationSeconds 的 Pod：它们会被允许在节点上继续运行指定的时间（秒）。
​		如果在这个时间段内，节点上的污点被移除了，那么这个 Pod 就不会被驱逐，继续正常运行。
​		如果在这个时间段结束后，节点上的污点仍然存在，那么**节点生命周期控制器（Node Lifecycle Controller）**就会将这个 Pod 从节点上驱逐掉。
taint 的效果（即节点对 Pod 的排斥行为）必须通过 Pod YAML 文件中的 spec.tolerations 部分来抵消或“容忍”，这样 Pod 才能被调度到带有相应污点的节点上，或者在 NoExecute 效果下不被驱逐。
Taint (污点) **作用在节点（node）上**；
Toleration (容忍) **作用在 Pod 上**，没有 Toleration，Pod 就会受到 taint 的排斥作用，不会运行在 node 上

```bash
~# cat <<EOL> pod22.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod22
  name: pod22
spec:
  tolerations:
  - key: "memeda"
    operator: "Equal"
    value: "hehehe"
    effect: "NoExecute"
    tolerationSeconds: 10            # 表示容忍污点的时间
  containers:
  - image: crpi-bkg7bvmf5xyivcsd.cn-shanghai.personal.cr.aliyuncs.com/onlymyself/onlymyself-hub:wordpress
    imagePullPolicy: Never
    name: pod22
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: OnFailure
status: {}
EOL

~# kubectl get pods -o wide
NAME    READY   STATUS    RESTARTS   AGE     IP               NODE     NOMINATED NODE   READINESS GATES
pod1    1/1     Running   0          11m     10.244.195.145   knode1   <none>           <none>
pod2    1/1     Running   0          10m     10.244.69.205    knode2   <none>           <none>
pod22   1/1     Running   0          5m49s   10.244.69.206    knode2   <none>           <none>

~# kubectl describe nodes | grep -i taint
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
Taints:             <none>
Taints:             <none>

~# kubectl taint nodes knode1 memeda=hehehe:NoExecute
node/knode1 tainted
~# kubectl taint nodes knode2 memeda=hehehe:NoExecute
node/knode2 tainted
~# kubectl get pods -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP              NODE     NOMINATED NODE   READINESS GATES
pod2    1/1     Running   0          15m   10.244.69.205   knode2   <none>           <none>
pod22   1/1     Running   0          10m   10.244.69.206   knode2   <none>           <none>
~#
~# kubectl get pods -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP              NODE     NOMINATED NODE   READINESS GATES
pod2   1/1     Running   0          15m   10.244.69.205   knode2   <none>           <none>
~#
# 可以看到 pod1 立马就被驱逐了，pod22 在 10s 后也被驱逐了
```
可以想象 node 是一个饭店，pod 是客人，taint 是饭店的缺点，价格呀，卫生呀，客人能够容忍这个饭店的哪些缺点就会来吃饭，饭店的缺点不是客人能够容忍的，客人就不会去吃饭。
tolerationSeconds 就是客人能够容忍在有缺点的饭店吃饭的时间有多久。
即 node 上的 taint 如果在 pod 的 Toleration 中没有定义，则 pod 就不会运行在该 node 上
**使用 deployment 控制器体现驱逐 drain**
```bash
[root@kmaster 328]# kubectl create deployment web1 --image nginx --dry-run=client -o yaml > web1.yaml
[root@kmaster 328]# ls
pod1.yaml  pod2.yaml  pod3.yaml  pod4.yaml  pod5.yaml  pod6.yaml  pod7.yaml  web1.yaml
[root@kmaster 328]# cat web1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: web1
  name: web1
spec:
  replicas: 6
  selector:
    matchLabels:
      app: web1
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: web1
    spec:
      containers:
      - image: crpi-bkg7bvmf5xyivcsd.cn-shanghai.personal.cr.aliyuncs.com/onlymyself/onlymyself-hub:wordpress
        imagePullPolicy: IfNotPresent
        name: nginx
        resources: {}
status: {}

[root@kmaster 328]# kubectl apply -f web1.yaml
deployment.apps/web1 created
[root@kmaster 328]# kubectl get pod -o wide
NAME                    READY   STATUS              RESTARTS   AGE   IP       NODE     NOMINATED NODE   READINESS GATES
web1-74b86ff946-8z729   0/1     ContainerCreating   0          3s    <none>   knode1   <none>           <none>
web1-74b86ff946-b2n2m   0/1     ContainerCreating   0          3s    <none>   knode2   <none>           <none>
web1-74b86ff946-czlb6   0/1     ContainerCreating   0          3s    <none>   knode1   <none>           <none>
web1-74b86ff946-f7lhp   0/1     ContainerCreating   0          3s    <none>   knode2   <none>           <none>
web1-74b86ff946-z2tx7   0/1     ContainerCreating   0          3s    <none>   knode2   <none>           <none>
web1-74b86ff946-zm8gc   0/1     ContainerCreating   0          3s    <none>   knode1   <none>           <none>
[root@kmaster 328]# kubectl get pod -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP               NODE     NOMINATED NODE   READINESS GATES
web1-74b86ff946-8z729   1/1     Running   0          27s   10.244.195.139   knode1   <none>           <none>
web1-74b86ff946-b2n2m   1/1     Running   0          27s   10.244.69.206    knode2   <none>           <none>
web1-74b86ff946-czlb6   1/1     Running   0          27s   10.244.195.138   knode1   <none>           <none>
web1-74b86ff946-f7lhp   1/1     Running   0          27s   10.244.69.208    knode2   <none>           <none>
web1-74b86ff946-z2tx7   1/1     Running   0          27s   10.244.69.207    knode2   <none>           <none>
web1-74b86ff946-zm8gc   1/1     Running   0          27s   10.244.195.140   knode1   <none>           <none>

现在一共6个pod，node1和node2上分别运行了3个。

[root@kmaster 328]# kubectl get nodes 
NAME      STATUS   ROLES           AGE     VERSION
kmaster   Ready    control-plane   5d23h   v1.26.0
knode1    Ready    node1           5d23h   v1.26.0
knode2    Ready    node2           5d23h   v1.26.0
[root@kmaster 328]# 
[root@kmaster 328]# kubectl drain knode1
node/knode1 cordoned
error: unable to drain node "knode1" due to error:cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): calico-system/calico-node-9kmm4, calico-system/csi-node-driver-q5z7m, kube-system/kube-proxy-x88s7, continuing command...
There are pending nodes to be drained:
 knode1
cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): calico-system/calico-node-9kmm4, calico-system/csi-node-driver-q5z7m, kube-system/kube-proxy-x88s7

对knode1进行驱逐操作
[root@kmaster 328]# kubectl drain knode1 --ignore-daemonsets --force
node/knode1 already cordoned
Warning: ignoring DaemonSet-managed Pods: calico-system/calico-node-9kmm4, calico-system/csi-node-driver-q5z7m, kube-system/kube-proxy-x88s7
evicting pod tigera-operator/tigera-operator-54b47459dd-f56jg
evicting pod calico-apiserver/calico-apiserver-688757cbb5-tsqs8
evicting pod calico-system/calico-typha-6cfbbcb7d4-9t4ll
evicting pod default/web1-849556688-fsdcx
evicting pod default/web1-849556688-k6ntr
evicting pod default/web1-849556688-vv9d6
pod/tigera-operator-54b47459dd-f56jg evicted
pod/web1-849556688-k6ntr evicted
pod/web1-849556688-vv9d6 evicted
pod/calico-apiserver-688757cbb5-tsqs8 evicted
pod/web1-849556688-fsdcx evicted
pod/calico-typha-6cfbbcb7d4-9t4ll evicted
node/knode1 drained

# 看到原来运行在 knode1 上的 pod 都在 node2 上被创建了出来
[root@kmaster 328]# kubectl get pod -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP              NODE     NOMINATED NODE   READINESS GATES
web1-849556688-2z29z   1/1     Running   0          83s   10.244.69.209   knode2   <none>           <none>
web1-849556688-47rg8   1/1     Running   0          25s   10.244.69.212   knode2   <none>           <none>
web1-849556688-8nh64   1/1     Running   0          83s   10.244.69.211   knode2   <none>           <none>
web1-849556688-bms2h   1/1     Running   0          83s   10.244.69.210   knode2   <none>           <none>
web1-849556688-tbf75   1/1     Running   0          25s   10.244.69.215   knode2   <none>           <none>
web1-849556688-w8bl7   1/1     Running   0          25s   10.244.69.213   knode2   <none>           <none>
[root@kmaster 328]# 
[root@kmaster 328]# 
[root@kmaster 328]# ls
pod1.yaml  pod2.yaml  pod3.yaml  pod4.yaml  pod5.yaml  pod6.yaml  pod7.yaml  web1.yaml
```
# Storage

docker 默认情况下，数据保存在容器层，一旦删除容器，数据也随之删除。

在 k8s 环境里，pod 运行容器，之前也没有指定存储，当删除 pod 的时候，之前在 pod 里面写入的数据就没有了。

Volume 是 Pod 中容器可访问的目录。它提供了一个抽象层，将容器的文件系统与底层存储解耦。

Volume 的生命周期与 Pod 的生命周期相关联，但比容器的生命周期更长，这意味着即使容器重启，Volume 中的数据依然存在。

## 临时存储

**emptyDir**

对于 emptyDir 来说，会在 pod 所在的物理机上生成一个随机目录。pod 的容器会挂载到这个随机目录上。

当 pod 容器删除后，随机目录也会随之删除。

通常用于容器间的缓存或临时工作目录。

## 本地存储

**hostPath**

将节点（Node）上的某个文件或目录直接挂载到 Pod 中。

生命周期与节点绑定。Pod 删除后，数据仍在节点上。

用途非常有限，通常用于特殊目的，如系统级日志收集、访问节点硬件。

不推荐生产环境使用，因为它破坏了 Pod 的可移植性，且存在安全隐患。

```bash
~# kubectl create ns vol
namespace/vol created
~# kubens vol
Context "kubernetes-admin@kubernetes" modified.
Active namespace is "vol".

~# 
cat <<EOL> podvol1.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: podvol1
  name: podvol1
spec:
  volumes:            # 定义 Pod 可以使用的卷
  - name: v1            # 卷的名称。它就像是一个“ID”，给容器挂载时引用
    emptyDir: {}             # 定义一个名为 v1 的卷，类型是 emptyDir
  - name: v2
    hostPath:                # v2 是 hostPath 类型的卷
      path: /data            # 指定了 Node 上要挂载的路径是 /data，如果 node 上没有则 pod 运行时自动创建
  containers:
  - image: crpi-bkg7bvmf5xyivcsd.cn-shanghai.personal.cr.aliyuncs.com/onlymyself/onlymyself-hub:wordpress
    name: podvol1
    imagePullPolicy: IfNotPresent
    resources: {}
    volumeMounts:            # 定义了容器内部如何挂载 Pod 的卷
    - name: v1               # 指定要挂载的卷是前面定义的 v1 卷
      mountPath: /abc1            # v1 卷将被挂载到容器内部的 /abc1 目录下
    - name: v2
      mountPath: /abc2            # v2 卷即 node 的/data 将被挂载到容器内部的 /abc2 下
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
EOL

# 这个 Pod 定义了两个卷：
# v1 是一个临时的 emptyDir 卷，用于 Pod 内部的临时存储或容器间数据共享。
# v2 是一个 hostPath 卷，它将宿主机的 /data 目录挂载到了容器的 /abc2 路径下。这意味着容器可以直接读写宿主机 /data 目录中的内容。

~# kubectl apply -f podvol1.yaml
pod/podvol1 created

~# kubectl get pod -o wide
NAME      READY   STATUS    RESTARTS   AGE   IP              NODE     NOMINATED NODE   READINESS GATES
podvol1   1/1     Running   0          17s   10.244.69.207   knode2   <none>           <none>

# 在 pod 里面 abc1 ,abc2 目录已经创建
~# kubectl exec -ti podvol1 -- bash
root@podvol1:~# ls /
abc1  abc2  bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
root@podvol1:~# touch /abc1/abc1.txt
root@podvol1:~# touch /abc2/abc2.txt
root@podvol1:~# ls /abc1
abc1.txt
root@podvol1:~# ls /abc2
abc2.txt
root@podvol1:~# 
# 在 knode2 上尝试在 pod 里面写数据
[root@knode2 ~]# crictl ps
CONTAINER           IMAGE               CREATED             STATE               NAME                        ATTEMPT             POD ID              POD
ffac8600982a7       c3c92cc3dcb1a       3 minutes ago       Running             podvol1                     0                   21e156d52b2d1       podvol1

[root@knode2 ~]# crictl inspect ffac8600982a7 > aaa
[root@knode2 ~]# vi aaa
# 使用 vim 编辑器快速找到 abc1 目录
[root@knode2 ~]# ls /var/lib/kubelet/pods/b48a75db-39b2-44ef-b857-2b3a62e5ae0d/volumes/kubernetes.io~empty-dir/v1
abc1.txt
[root@knode2 ~]# ls /data
abc2.txt
[root@knode2 ~]# touch /var/lib/kubelet/pods/b48a75db-39b2-44ef-b857-2b3a62e5ae0d/volumes/kubernetes.io~empty-dir/v1/hahaha.txt
[root@knode2 ~]# ls /var/lib/kubelet/pods/b48a75db-39b2-44ef-b857-2b3a62e5ae0d/volumes/kubernetes.io~empty-dir/v1
abc1.txt  hahaha.txt
[root@knode2 ~]# touch  /data/hehehe.txt
[root@knode2 ~]# ls /data
abc2.txt  hehehe.txt
[root@knode2 ~]# 

# 删除 pod 后查看效果
root@podvol1:~# ls /abc1
abc1.txt  hahaha.txt
root@podvol1:~# ls /abc2
abc2.txt  hehehe.txt
root@podvol1:~# exit
exit

~# kubectl delete -f podvol1.yaml 
pod "podvol1" deleted

~# kubectl get pods 
No resources found in vol namespace.
~# 

# emptyDir 是临时的，因此 pod 删除后，该目录也会随之删除；
# hostPath 卷会使得 Pod 与特定的节点强绑定
[root@knode2 ~]# ls /var/lib/kubelet/pods/b48a75db-39b2-44ef-b857-2b3a62e5ae0d/volumes/kubernetes.io~empty-dir/v1
ls: cannot access '/var/lib/kubelet/pods/b48a75db-39b2-44ef-b857-2b3a62e5ae0d/volumes/kubernetes.io~empty-dir/v1': No such file or directory
[root@knode2 ~]# ls /data
abc2.txt  hehehe.txt
[root@knode2 ~]# 
```

## **网络存储**

网络存储是指数据存储在独立的、可以通过网络访问的存储系统上。在 Kubernetes 中，网络存储是实现数据持久性、高可用性和 Pod 可移植性的主要方式。

网络存储支持很多种类型可以作为后端存储来使用。

这是后端存储物理层面上提供服务的方式：

A. 文件存储 (File Storage)

通过网络协议共享目录。

​    代表： NFS, GlusterFS, CephFS, Azure Files。

​    访问模式： 通常支持 RWX (ReadWriteMany)，即多个 Pod 可以同时读写同一个卷。

​    场景： 网站静态资源共享、多个 Pod 共用配置文件。

B. 块存储 (Block Storage)

将远程磁盘直接映射为宿主机的块设备（如 /dev/sdb）。

​    代表： Ceph RBD, iSCSI, AWS EBS, 阿里云盘, vSphere Volume。

​    访问模式： 通常仅支持 RWO (ReadWriteOnce)，即一个卷只能挂载到一个节点。

​    场景： 数据库（MySQL/PostgreSQL）、高性能日志处理。

C. 对象存储 (Object Storage)

通过 API (HTTP/S3) 进行访问。

​    代表： MinIO, Ceph RGW, AWS S3。

​    接入方式： 通常不直接通过 PV/PVC 挂载，而是由应用直接调用 SDK。但也可以通过 s3fs 等 CSI 插件强行挂载为文件系统。

**NFS**

```bash
~# cat pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod
  name: pod
spec:
  tolerations:
  - key: "node1/key"
    value: "value"
    operator: "Equal"
    effect: "NoExecute"
    tolerationSeconds: 180
  nodeSelector:
    xxx: test
    yyy: test
    zzz: test
  volumes:
  - name: vol-1
    emptyDir: {}
  - name: vol-2
    hostPath:
      path: /vol-data
  - name: vol-3
    nfs:
      server: 192.168.0.20
      path: /storage/nfs
  containers:
  - image: nginx:1.20
    imagePullPolicy: Never
    name: pod
    resources: {}
    volumeMounts:
    - name: vol-1
      mountPath: /mountPath-emptyDir
    - name: vol-2
      mountPath: /mountPath-hostPath
    - name: vol-3
      mountPath: /mountPath-nfs
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
~# 

~# kubeval pod.yaml 
PASS - pod.yaml contains a valid Pod (pod)
~# 
~# kubectl apply -f pod.yaml 
pod/pod created
~# 
~# kubectl get pods -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP               NODE    NOMINATED NODE   READINESS GATES
pod    1/1     Running   0          9s    10.244.166.176   node1   <none>           <none>
~# 
~# kubectl exec -it pod -- bash
root@pod:/# 
root@pod:/# ls
bin  boot  dev  docker-entrypoint.d  docker-entrypoint.sh  etc  home  lib  lib64  media  mnt  mountPath-emptyDir  mountPath-hostPath  mountPath-nfs  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
root@pod:/# ls mountPath-emptyDir/
root@pod:/# ls mountPath-hostPath/
test-hostPath-nodetopod
root@pod:/# ls mountPath-nfs/     
test.mp3  test.mp4  test.pdf
root@pod:/# exit
'----------------------------------------------------'
root@node1:~# 
root@node1:~# ls /
bin  boot  cdrom  dev  etc  home  lib  lib32  lib64  libx32  lost+found  media  mnt  opt  proc  root  run  sbin  snap  srv  sys  tmp  usr  var  vol-data
root@node1:~# ls /vol-data/
test-hostPath-nodetopod
root@node1:~# 
root@node1:~# df -h | grep nfs
192.168.0.20:/storage/nfs           18G  3.1G   14G  19% /var/lib/kubelet/pods/52248c76-4ae9-412c-9210-ffe7ea7fe9bd/volumes/kubernetes.io~nfs/vol-3
```

**iscsi**

```

```
如果 ceph 或 glusterfs，worker 节点要配置成对应的客户端。
这种方式看起来很理想，但是配置起来稍有负载，尤其配置 iscsi 的时候，操作麻烦，而且不够安全，为什么说不安全？

多个客户端多个用户连接同一个存储里面的数据，会导致目录重复，后者有没有可能会把整个存储或者某个数据删除掉呢？就会带来一些安全隐患。

**持久化存储**

持久化存储 ( Persistent Storage ) 是指数据在 Pod 或节点的生命周期之外仍然能够保留和访问的存储。

> master 上有很多命名空间，不同用户连接到不同的命名空间里面（后面讲）。业务人员管理 pod，而存储管理员管理存储，分开管理。
> 存储服务器共享多个目录，管理员会在集群中创建 PV，这个 PV 是全局可见的。该 PV 会和存储服务器中的某个目录关联。
> 用户要做的就是创建自己的 PVC，PVC 是基于命名空间进行隔离的。而 PV 是全局可见的。之后把 PVC 和 PV 关联在一起。

Kubernetes 通过一套标准化的 API 和抽象层来管理各种底层存储技术，从而实现持久化存储。主要包括以下几个核心组件：

## **PV  - 持久卷**

PV (PersistentVolume) 是集群中管理员（或存储系统自动）预置（provision）或动态创建的网络存储资源。它代表了实际的物理存储。
PV 是集群中的一种资源，不属于任何命名空间。
PV 独立于 Pod 的生命周期。即使 Pod 被删除，PV 和其中的数据仍然存在。
PV 定义了存储的容量、访问模式（如 ReadWriteOnce、ReadOnlyMany、ReadWriteMany）、存储类型、以及回收策略（Retain、Recycle、Delete）。

##  **PVC - 持久卷声明**
PVC (PersistentVolumeClaim) 是用户（开发者）对存储资源的请求。它声明了 Pod 需要的存储量、访问模式和存储类型。
Pod 不直接挂载 PV，而是通过 PVC 来 “声明” 对存储的需求。
PVC 是命名空间范围内的资源。
Kubernetes 调度器会找到一个符合 PVC 要求的 PV 来绑定这个 PVC。一旦绑定，PVC 就只能使用这个特定的 PV。

## **生命周期状态**

PV 的生命周期状态
    Available: PV 未绑定到任何 PVC，可以被请求。
    Bound: PV 已绑定到一个 PVC。
    Released: PV 绑定的 PVC 已被删除，但 PV 本身尚未根据其回收策略被回收或删除。
    Failed: PV 处于故障状态，例如底层存储系统出现问题，或者回收操作失败。

PVC（持久卷申请）的状态
    Pending（等待中）含义：申请单已经提交，但还没找到合适的 PV。
    Bound（已绑定）：PVC 已经成功拿到了 PV 资源。
    Lost（丢失）：PVC 绑定过的 PV 在集群中消失了（可能被误删了）。

**访问模式 (Access Modes)** 
访问模式决定了存储卷如何挂载到宿主机节点上。

ReadWriteOnce		该卷可以被**一个**节点以**读写**模式挂载
ReadOnlyMany		该卷可以被**多个**节点以**只读**模式挂载
ReadWriteMany		该卷可以被**多个**节点以**读写**模式挂载

**回收策略 (Reclaim Policy):**
persistentVolumeReclaimPolicy 字段决定了当 PVC 被删除后，底层存储和 PV 对象如何处理。
    **Retain (保留)**
        当 PVC 被删除时，PV 仍会存在（状态变为 Released），并且底层存储中的数据也会被保留。
        静态供应 PV 的默认的回收策略。
    **Delete (删除)**
        PVC 删了，PV 自动删除，后端物理存储同步抹除。
        动态供应 PV 的默认回收策略。

**StorageClass（动态存储）**
StorageClass 定义了存储的“类别”或“配置文件”。它抽象了底层存储的具体实现，并允许管理员定义不同质量、性能或成本的存储选项。
StorageClass 的主要作用是实现动态存储供应。
当用户创建 PVC 并指定了一个 storageClassName 时，Kubernetes 会根据这个 StorageClass 的定义，通过其关联的存储供应器 (provisioner) 自动创建匹配的 PV，并将其绑定到 PVC；如果 PVC 没有指定 storageClassName，它通常会尝试绑定到没有 storageClassName 的 PV，或绑定到被标记为默认的 StorageClass 创建的 PV。
StorageClass 大大简化了用户获取持久化存储的过程，无需管理员手动预置 PV。
StorageClass 是实现**存储自动化**的核心组件，如果说 PV 是“现成的资源”，PVC 是“申请单”，那么 StorageClass 就是“自动生产线”。

**Container Storage Interface (CSI) - 容器存储接口**
CSI 是一个行业标准接口，允许存储供应商开发插件（CSI 驱动），使其存储系统能够与 Kubernetes 等容器编排系统无缝集成。
CSI 使得 Kubernetes 能够支持各种各样的存储系统（包括传统的存储阵列、分布式存储、云存储），而无需 Kubernetes 核心代码进行修改。这极大地扩展了 Kubernetes 的存储生态系统。
存储供应商实现 CSI 接口，并部署 CSI 驱动到 Kubernetes 集群中。当 Pod 请求存储时，CSI 驱动会与底层存储系统交互，完成 PV 的创建、挂载、扩展等操作。

## **持久卷管理机制**
持久卷管理机制是一套完整的资源分配、生命周期跟踪和回收流程。
可以将其类比为 Linux 中的“逻辑卷管理（LVM）”，但它多了一层“申请与匹配”的自动化逻辑。
**供应 (Provisioning)**
这是存储准备阶段，将物理存储抽象为 Kubernetes 中的 PV 对象。有两种主要方式：
**静态供应 (Static Provisioning)**
集群管理员手动在底层存储系统上创建实际的存储卷。然后手动创建一个 PV 对象，在 YAML 中指定这个实际存储卷的详细信息（如容量、访问模式、底层存储的地址/ID、以及回收策略）。此时，PV 处于 Available 状态，等待被 PVC 绑定。
适用场景: 当底层存储资源有限、需要严格控制或无法进行动态供应时。
**动态供应 (Dynamic Provisioning)**
这是更现代、更推荐的方式。它依赖于 StorageClass 对象和相应的存储供应器 (Provisioner)。
管理员不再手动创建 PV，而是创建一个 **StorageClass (SC)**。当用户提交 PVC 时，K8s 会根据 SC 的定义，自动调用底层插件（CSI）去创建物理空间并自动生成 PV。
**绑定 (Binding)**
这是 PV 与 PVC 建立一对一关联的过程。
用户创建了 PVC，控制平面（PersistentVolume-Binder 控制器）就会监控该申请，它会尝试寻找一个与之匹配的 PV。
匹配条件包括：
    **容量**: PV 的容量必须**大于或等于** PVC 请求的容量。
    **访问模式**: PV 和 PVC 必须支持**至少一种**共同的访问模式
    **StorageClass**: 
    如果 PVC 指定了 storageClassName，则 PV 也必须具有相同的 storageClassName。
    如果 PVC 未指定 storageClassName，则它会绑定到默认的 StorageClass 创建的 PV，或者尝试绑定任何没有 storageClassName 的静态 PV。
    **标签选择器 (Label Selector)**: PVC 还可以使用 selector 来进一步过滤匹配的 PV。
一旦找到匹配的 PV，Kubernetes 会将 PVC 绑定到该 PV。绑定成功后，PV 和 PVC 都进入 Bound 状态。PV 和 PVC 是一一对应的。一旦绑定，该 PV 就不能再给其他 PVC 使用，直到解绑。
绑定阶段通过在 PV 和 PVC 对象中互相设置 claimRef 字段来实现双向引用。

**使用 (Using)**
一旦 PVC 与 PV 绑定成功，Pod 就可以将 PVC 作为一个卷（Volume）挂载到容器的文件系统中。
调度保护： 为了防止数据冲突，调度器会确保 Pod 被调度到能够访问该存储的节点上。
文件系统锁定： 对于 ReadWriteOnce 的卷，K8s 会通过 CSI 插件确保同一时间只有一个节点能挂载它，防止并发写入导致的文件系统损坏。

**回收 (Reclaiming)**
当 Pod 不再需要存储时，PV 就可以被回收。这通常发生在 PVC 被删除时。回收策略定义了 PV 和底层存储如何处理。
当用户删除 PVC 时，PV 不再被任何 PVC 绑定，PV 的状态会从 Bound 变为 Released。
``` bash
~# cat pv-nfs.yaml 
apiVersion: v1
kind: PersistentVolume   # 资源类型：持久卷
metadata:
  name: pv-nfs             # 这个 PV 在集群里的唯一名称。后续 PVC 绑定时可以根据名称寻找
spec:
  capacity:
    storage: 5Gi        # 定义该卷的大小
  volumeMode: Filesystem            # 卷模式。Filesystem（默认值）意味着该卷将被挂载到 Pod 作为一个目录
  accessModes:          # 定义访问模式
    - ReadWriteOnce
  storageClassName: manual          # 存储类名称。这相当于给 PV 打了一个“标签”。
  persistentVolumeReclaimPolicy: Retain        # 回收策略。
  nfs:
    path: "/storage/nfs"
    server: 192.168.0.20
~# 
~# kubectl apply -f pv-nfs.yaml 
persistentvolume/pv-nfs created
~# kubectl get pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pv-nfs   5Gi        RWO            Retain           Available           manual         <unset>                          4m49s
~# 
# pv 是集群级资源，是全局可见的，不属于任何命名空间
```
创建后的 PV 存放在 Master 节点上的 etcd 数据库中。
此时的 PV 只是集群数据库里的一条“记录”或“合同”，描述了存储在哪里、有多大、怎么访问。它不占用 Master 节点的磁盘空间（除了 etcd 里那几 KB 的文本信息）。
所以 Master 节点并不需要去连接 nfs 服务器

```bash
~# cat pvc-nfs.yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs
spec:
  storageClassName: manual  # 必须与 PV 中的 storageClassName 完全一致
  accessModes:
    - ReadWriteOnce         # 必须是 PV 支持的模式之一
  resources:
    requests:
      storage: 5Gi          # 申请的大小，不能超过 PV 的容量
~# 
~# kubectl apply -f pvc-nfs.yaml 
persistentvolumeclaim/pvc-nfs created
~# 
~# kubectl get pvc
NAME      STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
pvc-nfs   Bound    pv-nfs   5Gi        RWO            manual         <unset>                 8s
# pvc 创建完成之后，完成自动关联。
~# 
~# kubectl get pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pv-nfs   5Gi        RWO            Retain           Bound    default/pvc-nfs   manual         <unset>                          7m3s
~# 

~# cat pod-test.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-test
  name: pod-test
spec:
  nodeName:
  volumes:
  - name: vol-1
    persistentVolumeClaim:            # 声明这个卷的来源类型是 PVC
      claimName: pvc-nfs              # 指定具体的 PVC 资源名称
  - name: vol-2
    nfs:
      server: 192.168.0.20
      path: /storage/nfs
  containers:
  - image: nginx:1.20
    imagePullPolicy: Never
    name: pod-test
    resources: {}
    volumeMounts:
    - name: vol-1
      mountPath: /mountPath-pvc
    - name: vol-2
      mountPath: /mountPath-nfs
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
~# 
~# kubectl exec -it pod-test -- bash
root@pod-test:/# 
root@pod-test:/# ls
bin  boot  dev  docker-entrypoint.d  docker-entrypoint.sh  etc  home  lib  lib64  media  mnt  mountPath-nfs  mountPath-pvc  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
root@pod-test:/# ls /mountPath-pvc/
test.mp3  test.mp4  test.pdf  test.ppt
root@pod-test:/# 
root@pod-test:/# ls /mountPath-pvc/
test.mp3  test.mp4  test.pdf  test.ppt
root@pod-test:/# ls /mountPath-nfs/
test.mp3  test.mp4  test.pdf  test.ppt
root@pod-test:/# 
root@pod-test:/# exit
exit
~# 
~# kubectl get pods -o wide 
NAME       READY   STATUS    RESTARTS   AGE    IP              NODE    NOMINATED NODE   READINESS GATES
pod-test   1/1     Running   0          105s   10.244.104.15   node2   <none>           <none>
~# 
~# kubectl get pvc
NAME      STATUS        VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
pvc-nfs   Terminating   pv-nfs   5Gi        RWO            manual         <unset>                 67m
~# 
~# kubectl exec -it pod-test -- bash
root@pod-test:/# 
root@pod-test:/# 
~# kubectl delete -f pod-test.yaml 
pod "pod-test" deleted
~# 
~# kubectl get pvc
No resources found in default namespace.
~# 
~# kubectl get pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pv-nfs   5Gi        RWO            Retain           Released   default/pvc-nfs   manual         <unset>                          79m
~# 
```

# **控制器**
在 Kubernetes 中，控制器是一个核心概念，它是 Kubernetes 实现其自动化和自愈能力的关键。你可以把控制器想象成一个永不停止地尝试让当前状态与期望状态一致的循环。
每个控制器都关注特定类型的 Kubernetes 资源（比如 Pod、Deployment、Service 等）。

## **Deployment**
一种资源对象，是 K8s 的**逻辑控制器**。存在于 **Master 节点 (etcd)** 里的配置信息。
在k8s里面，最小的调度单位是 pod，但是 pod 本身不稳定，导致系统不健壮，没有可再生性（自愈功能）。
Deployment 并不直接管理 Pod，它通过 **ReplicaSet (RS)** 来实现版本控制维持 Pod 的副本数量。
集群中只需要告诉 deploy，需要多少个 pod 即可，一旦某个 pod 宕掉，deploy 会生成新的 pod，保证集群中的固定存在 3 个 pod。少一个，生成一个，多一个，删除一个。如果不把 deploy 删除，那么 3 个 pod 是永远删除不掉的。

```bash
~# cat dep-test.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:            # 给 Deployment 本身打标签
    app: dep-test
  name: dep-test            # dep 的名称
spec:
  replicas: 3        # 期望 Pod 数量 = 3
  selector:            # dep 认领哪些 pod
    matchLabels:
      app: dep-test        # dep 只管理标签为 dep-test 的 pod
  template:            # Pod 的“出生模板”，定义 Deployment 创建出来的 Pod 长什么样
    metadata:
      creationTimestamp: null
      labels:
        app: dep-test            # 如果 selector 和 template 的 label 不一致：Deployment 会认为 一个 Pod 都没有然后疯狂新建 Pod（灾难级错误）
    spec:
      containers:
      - image: nginx:1.20
        name: nginx
~# kubectl apply -f dep-test.yaml 
deployment.apps/dep-test created
~# kubectl get pods -o wide
NAME                        READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
dep-test-59bb6d979d-94n5x   1/1     Running   0          8s    10.244.104.20   node2   <none>           <none>
dep-test-59bb6d979d-jbkpr   1/1     Running   0          8s    10.244.104.18   node2   <none>           <none>
dep-test-59bb6d979d-jqg6w   1/1     Running   0          8s    10.244.104.19   node2   <none>           <none>
~# kubectl delete pods dep-test-59bb6d979d-94n5x
pod "dep-test-59bb6d979d-94n5x" deleted
~# kubectl get pods -o wide
NAME                        READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
dep-test-59bb6d979d-ggbc6   1/1     Running   0          2s    10.244.104.21   node2   <none>           <none>
dep-test-59bb6d979d-jbkpr   1/1     Running   0          45s   10.244.104.18   node2   <none>           <none>
dep-test-59bb6d979d-jqg6w   1/1     Running   0          45s   10.244.104.19   node2   <none>           <none>
~# 


~# kubectl get pods --show-labels
NAME                        READY   STATUS    RESTARTS   AGE     LABELS
dep-test-59bb6d979d-ggbc6   1/1     Running   0          3m38s   app=dep-test,pod-template-hash=59bb6d979d
dep-test-59bb6d979d-jbkpr   1/1     Running   0          4m21s   app=dep-test,pod-template-hash=59bb6d979d
dep-test-59bb6d979d-jqg6w   1/1     Running   0          4m21s   app=dep-test,pod-template-hash=59bb6d979d
~# 
~# kubectl get deployments.apps -o wide             # 获取 Kubernetes 集群中所有 Deployment 资源的列表
NAME       READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS   IMAGES       SELECTOR
dep-test   3/3     3            3           5m4s   nginx        nginx:1.20   app=dep-test
~# 
```

### **镜像升级与回滚**

镜像升级（Upgrade）与回滚（Rollback）是 Deployment 最核心的价值体现。它让应用更新告别了传统的“停机维护”，实现了真正的“无缝切换”。

```bash
[root@knode1 ~]# crictl pull nginx:1.9
Image is up to date for sha256:f568d3158b1e871b713cb33aca5a9377bc21a1f644addf41368393d28c35e894
[root@knode1 ~]# crictl img 
IMAGE                                                      TAG                 IMAGE ID            SIZE
docker.io/calico/cni                                       v3.25.0             d70a5947d57e5       88MB
docker.io/calico/node                                      v3.25.0             08616d26b8e74       87.2MB
docker.io/library/alpine                                   latest              042a816809aac       3.37MB
docker.io/library/centos                                   latest              5d0da3dc97646       83.5MB
docker.io/library/mysql                                    latest              05b458cc32b96       153MB
docker.io/library/nginx                                    1.9                 f568d3158b1e8       71.2MB
docker.io/library/nginx                                    latest              9eee96112defa       56.9MB
### 在线修改 pod 镜像
~# kubectl apply -f dep1.yaml 
deployment.apps/dep1 created
~# kubectl get deployments.apps -o wide
NAME   READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES   SELECTOR
dep1   5/5     5            5           16s   nginx        nginx    app=dep1            # 可以看到目前使用的是 nginx 最新版
~# kubectl edit deployments.apps dep1        # 将镜像修改为 nginx:1.9

# 等待一会
~# kubectl get deployments.apps -o wide
NAME   READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES      SELECTOR
dep1   5/5     5            5           4m16s   nginx        nginx:1.9   app=dep1
# 当修改 deployment 的时候，本质上是删除旧的 pod，重新创建新的 pod，这是 deployment 本身的特性。

### 通过 yaml 文件修改 pod 镜像
# 直接修改 yaml 文件，修改为 latest 版本
~# kubectl apply -f dep1.yaml 
deployment.apps/dep1 configured


~# kubectl get deployments.apps -o wide
NAME   READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS   IMAGES         SELECTOR
dep1   5/5     5            5           8m2s   nginx        nginx:latest   app=dep1

### 命令行修改
~# kubectl rollout history deployment dep-test 
deployment.apps/dep-test 
REVISION  CHANGE-CAUSE
1         <none>

~# 
~# kubectl set image deployment/dep-test nginx=nginx:1.22
deployment.apps/dep-test image updated
~# 
~# kubectl get deployments.apps dep-test -o wide 
NAME       READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS   IMAGES       SELECTOR
dep-test   3/4     4            3           3m3s   nginx        nginx:1.22   app=dep-test
~# 
~# kubectl rollout history deployment dep-test 
deployment.apps/dep-test 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

~# kubectl set image deployment/dep-test nginx=nginx:1.21 --record
Flag --record has been deprecated, --record will be removed in the future
deployment.apps/dep-test image updated
~# kubectl get deployments.apps dep-test -o wide 
NAME       READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES       SELECTOR
dep-test   4/4     4            4           3m33s   nginx        nginx:1.21   app=dep-test
~# kubectl rollout history deployment dep-test 
deployment.apps/dep-test 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         kubectl set image deployment/dep-test nginx=nginx:1.21 --record=true

~# 

# 这时候有个问题，好像我们所有操作都是无法记录的。比如想查看我们升级或回滚操作记录。
# Kubernetes 默认不自动记录,只有在显式记录 --record 时才有
# 如果发现某个镜像存在缺陷，可以通过上述方法进行更换，也可以进行撤销操作。
~# kubectl set image deployment/dep-test nginx=nginx:1.22 --record
Flag --record has been deprecated, --record will be removed in the future
deployment.apps/dep-test image updated
~# 
~# kubectl rollout history deployment dep-test         # rollout : 和 “版本发布 / 更新过程” 有关的一组子命令。
deployment.apps/dep-test 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
6         <none>
7         kubectl set image deployment/dep-test nginx=nginx:1.20 --record=true
8         kubectl set image deployment/dep-test nginx=nginx:1.22 --record=true

~# 
~# kubectl rollout undo deployment dep-test 
deployment.apps/dep-test rolled back
~# 
~# kubectl get deployments.apps -o wide 
NAME       READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES       SELECTOR
dep-test   1/1     1            1           15h   nginx        nginx:1.20   app=dep-test
~# 
~# kubectl rollout history deployment dep-test 
deployment.apps/dep-test 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
6         <none>
8         kubectl set image deployment/dep-test nginx=nginx:1.22 --record=true
9         kubectl set image deployment/dep-test nginx=nginx:1.20 --record=true

~# 
~# kubectl set image deployment/dep-test nginx=nginx:1.21 --record
Flag --record has been deprecated, --record will be removed in the future
deployment.apps/dep-test image updated
~# 
~# kubectl rollout undo deployment dep-test --to-revision=8
deployment.apps/dep-test rolled back
~# 
~# kubectl get deployments.apps -o wide 
NAME       READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES       SELECTOR
dep-test   1/1     1            1           15h   nginx        nginx:1.22   app=dep-test
~# 
~# kubectl rollout history deployment dep-test 
deployment.apps/dep-test 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
9         kubectl set image deployment/dep-test nginx=nginx:1.20 --record=true
10        kubectl set image deployment/dep-test nginx=nginx:1.21 --record=true
11        kubectl set image deployment/dep-test nginx=nginx:1.22 --record=true

~# 

# 现在有5个pod，在升级的时候，是不是一次性把5个删除，然后一起创建5个pod？如果全部升级，pod无法对外提供服务。

# 滚动升级有两个重要的参数：maxSurge 一次升级多少  maxUnavailable 一次性删除几个
~# kubectl edit deployments.apps dep1
# 默认这个参数没有值，会采用默认值
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%

# 把它改成数量，1
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1

~# kubectl get pods -o wide 
NAME                        READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
dep-test-575cbf6f7f-jjdsf   1/1     Running   0          86s   10.244.104.20   node2   <none>           <none>
dep-test-575cbf6f7f-kpt6d   1/1     Running   0          87s   10.244.104.16   node2   <none>           <none>
dep-test-575cbf6f7f-nfkpn   1/1     Running   0          86s   10.244.104.18   node2   <none>           <none>
dep-test-575cbf6f7f-tt6k4   1/1     Running   0          87s   10.244.104.17   node2   <none>           <none>
~# kubectl set image deployment/dep-test nginx=nginx:1.20
deployment.apps/dep-test image updated
~# kubectl get pods -o wide 
NAME                        READY   STATUS              RESTARTS   AGE    IP              NODE    NOMINATED NODE   READINESS GATES
dep-test-575cbf6f7f-jjdsf   1/1     Running             0          100s   10.244.104.20   node2   <none>           <none>
dep-test-575cbf6f7f-kpt6d   1/1     Running             0          101s   10.244.104.16   node2   <none>           <none>
dep-test-575cbf6f7f-nfkpn   1/1     Running             0          100s   10.244.104.18   node2   <none>           <none>
dep-test-575cbf6f7f-tt6k4   1/1     Terminating         0          101s   10.244.104.17   node2   <none>           <none>
dep-test-76866db9d5-8b6wl   0/1     ContainerCreating   0          1s     <none>          node2   <none>           <none>
dep-test-76866db9d5-vdj2p   0/1     ContainerCreating   0          1s     <none>          node2   <none>           <none>
~# kubectl get pods -o wide 
NAME                        READY   STATUS        RESTARTS   AGE    IP              NODE    NOMINATED NODE   READINESS GATES
dep-test-575cbf6f7f-jjdsf   1/1     Terminating   0          101s   10.244.104.20   node2   <none>           <none>
dep-test-575cbf6f7f-kpt6d   1/1     Running       0          102s   10.244.104.16   node2   <none>           <none>
dep-test-575cbf6f7f-nfkpn   1/1     Terminating   0          101s   10.244.104.18   node2   <none>           <none>
dep-test-76866db9d5-5lx6r   0/1     Pending       0          0s     <none>          node2   <none>           <none>
dep-test-76866db9d5-8b6wl   1/1     Running       0          2s     10.244.104.14   node2   <none>           <none>
dep-test-76866db9d5-vdj2p   1/1     Running       0          2s     10.244.104.19   node2   <none>           <none>
~# kubectl get pods -o wide 
NAME                        READY   STATUS              RESTARTS   AGE    IP              NODE    NOMINATED NODE   READINESS GATES
dep-test-575cbf6f7f-jjdsf   0/1     Terminating         0          102s   10.244.104.20   node2   <none>           <none>
dep-test-575cbf6f7f-kpt6d   1/1     Running             0          103s   10.244.104.16   node2   <none>           <none>
dep-test-575cbf6f7f-nfkpn   1/1     Terminating         0          102s   10.244.104.18   node2   <none>           <none>
dep-test-76866db9d5-5lx6r   0/1     ContainerCreating   0          1s     <none>          node2   <none>           <none>
dep-test-76866db9d5-8b6wl   1/1     Running             0          3s     10.244.104.14   node2   <none>           <none>
dep-test-76866db9d5-vdj2p   1/1     Running             0          3s     10.244.104.19   node2   <none>           <none>
dep-test-76866db9d5-zn8dt   0/1     ContainerCreating   0          1s     <none>          node2   <none>           <none>
~# kubectl get pods -o wide 
NAME                        READY   STATUS              RESTARTS   AGE    IP              NODE    NOMINATED NODE   READINESS GATES
dep-test-575cbf6f7f-kpt6d   1/1     Running             0          103s   10.244.104.16   node2   <none>           <none>
dep-test-575cbf6f7f-nfkpn   0/1     Terminating         0          102s   10.244.104.18   node2   <none>           <none>
dep-test-76866db9d5-5lx6r   0/1     ContainerCreating   0          1s     <none>          node2   <none>           <none>
dep-test-76866db9d5-8b6wl   1/1     Running             0          3s     10.244.104.14   node2   <none>           <none>
dep-test-76866db9d5-vdj2p   1/1     Running             0          3s     10.244.104.19   node2   <none>           <none>
dep-test-76866db9d5-zn8dt   0/1     ContainerCreating   0          1s     <none>          node2   <none>           <none>
~# kubectl get pods -o wide 
NAME                        READY   STATUS              RESTARTS   AGE    IP              NODE    NOMINATED NODE   READINESS GATES
dep-test-575cbf6f7f-kpt6d   1/1     Running             0          104s   10.244.104.16   node2   <none>           <none>
dep-test-575cbf6f7f-nfkpn   0/1     Terminating         0          103s   10.244.104.18   node2   <none>           <none>
dep-test-76866db9d5-5lx6r   0/1     ContainerCreating   0          2s     <none>          node2   <none>           <none>
dep-test-76866db9d5-8b6wl   1/1     Running             0          4s     10.244.104.14   node2   <none>           <none>
dep-test-76866db9d5-vdj2p   1/1     Running             0          4s     10.244.104.19   node2   <none>           <none>
dep-test-76866db9d5-zn8dt   0/1     ContainerCreating   0          2s     <none>          node2   <none>           <none>
~# kubectl get pods -o wide 
NAME                        READY   STATUS        RESTARTS   AGE    IP              NODE    NOMINATED NODE   READINESS GATES
dep-test-575cbf6f7f-kpt6d   1/1     Terminating   0          104s   10.244.104.16   node2   <none>           <none>
dep-test-76866db9d5-5lx6r   1/1     Running       0          2s     10.244.104.21   node2   <none>           <none>
dep-test-76866db9d5-8b6wl   1/1     Running       0          4s     10.244.104.14   node2   <none>           <none>
dep-test-76866db9d5-vdj2p   1/1     Running       0          4s     10.244.104.19   node2   <none>           <none>
dep-test-76866db9d5-zn8dt   1/1     Running       0          2s     10.244.104.24   node2   <none>           <none>
~# kubectl get pods -o wide 
NAME                        READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
dep-test-76866db9d5-5lx6r   1/1     Running   0          3s    10.244.104.21   node2   <none>           <none>
dep-test-76866db9d5-8b6wl   1/1     Running   0          5s    10.244.104.14   node2   <none>           <none>
dep-test-76866db9d5-vdj2p   1/1     Running   0          5s    10.244.104.19   node2   <none>           <none>
dep-test-76866db9d5-zn8dt   1/1     Running   0          3s    10.244.104.24   node2   <none>           <none>
~# 

```

### **修改副本数**

```bash
### 1.在线修改
# 搜索 /replicas 修改为 5
~# kubectl edit deployments.apps dep-test 
deployment.apps/dep-test edited
~# kubectl get deployments.apps -o wide 
NAME       READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES       SELECTOR
dep-test   5/5     5            5           63s   nginx        nginx:1.20   app=dep-test
~# 

### 2.命令行
~#  kubectl scale deployment dep-test --replicas 2        # 即时修改 dep1 部署的副本数量
# kubectl scale: kubectl 执行“伸缩”动作的一个子命令，用于调整资源（如 Deployment、ReplicaSet、StatefulSet 等）的副本数量。不会修改本地的 dep1.yaml 文件
deployment.apps/dep-test scaled
~# 
~# kubectl get deployments.apps -o wide 
NAME       READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES       SELECTOR
dep-test   2/2     2            2           4m12s   nginx        nginx:1.20   app=dep-test
~# 

### 3.修改 yaml 文件
~# cat dep-test.yaml | grep replicas
  replicas: 3
~# 
~# vi dep-test.yaml 
~# 
~# kubectl apply -f dep-test.yaml 
deployment.apps/dep-test configured
~# 
~# kubectl get deployments.apps -o wide 
NAME       READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS   IMAGES       SELECTOR
dep-test   4/4     4            4           7m6s   nginx        nginx:1.20   app=dep-test
~# 
```

以上修改副本数，都是基于手工来修改的，如果面对未知的业务系统，业务并发量忽高忽低，总不能手工来来回回修改，那怎么办呢？

是否可以根据 pod 的负载，让它自动调节？使用 HPA，类似于公有云的弹性负载 AS。

## HPA

HPA (Horizontal Pod Autoscaler) 是 Kubernetes 中实现“弹性伸缩”的核心组件。
水平伸缩 (Horizontal Scaling)：增加或减少 Pod 的数量。就像增加搬运工的人数（这是 HPA 干的活）。
垂直伸缩 (Vertical Scaling)：增加或减少 单个 Pod 的资源（CPU/内存）。就像给搬运工吃大力丸，让他一个人能搬更多东西（这是 VPA 干的活）。
它是应对突发流量、节省服务器成本的终极利器。
HPA 是通过 metric-service 组件来进行检测的，通过 Metrics API 获取 Pod 的实际资源利用率（比如 CPU 使用了多少）。将实际值与你在 HPA 中设定的“目标值”进行对比。计算出需要的副本数，并修改 Deployment 的 replicas 字段。

**配置 metrics-server 插件**

metrics-server 插件用于收集主机和 pod 的内存、CPU 的使用率，是做 HPA 的基础

https://github.com/kubernetes-sigs/metrics-server

> 默认情况下，metrics-server 会尝试验证每个节点 Kubelet 的证书。由于目前的集群是实验环境，证书通常是自签名的，会导致验证失败。
>
> 所以需要修改 components.yaml，在 args 列表中添加 --kubelet-insecure-tls 参数。
>

```bash
~# sed -i '/- --metric-resolution=15s/a \        - --kubelet-insecure-tls' components.yaml
~# kubectl top node
error: Metrics API not available
~#   
~# kubectl apply -f components.yaml 
serviceaccount/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
service/metrics-server created
deployment.apps/metrics-server created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
~# 
~# kubectl top node
NAME     CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
master   105m         5%     2105Mi          55%       
node1    32m          1%     647Mi           35%       
node2    138m         6%     1611Mi          42%       
~#   
```

扩容：发现超过 10%，几秒钟内就开始拉起新 Pod。

缩容：负载降下来后，HPA 会等待一段时间（默认 5 分钟，称为 缩容窗口时间 stabilization window），确认负载真的稳下去了，才会开始删 Pod。

扩容容易，缩容难；防止流量刚走又回来，频繁创建/销毁容器会极大地浪费系统资源和产生网络波动。   

为容器添加 resources.requests 字段是启用基于资源利用率（如 CPU 或内存百分比）的 HPA 的核心前提条件。HPA 正是基于这些“百分比”来决定是否扩容的。 如果你不写 requests，HPA 就会因为找不到计算基数而报错 Unknown。

删除 hpa 后， 现有的 Pod 副本会保持在删除那一刻的数量。

```bash
~# cat dep-test.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: dep-test
  name: dep-test
spec:
  replicas: 4 
  selector:
    matchLabels:
      app: dep-test
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: dep-test
    spec:
      containers:
      - image: nginx:1.20
        name: nginx
        resources:                   # 这是容器的资源管理部分
          requests:            # 定义了容器在调度到节点上时所需的最少资源量
            cpu: 200m            # 指定了 CPU 资源的请求量, m 代表毫核,就是 0.2 个 CPU 核心
status: {}

~# kubectl apply -f dep-test.yaml 
deployment.apps/dep-test configured
~# 
# 创建一个 HPA 对象
# 为 dep1 创建一个 HPA 资源对象，副本最小数为 1 ，副本最大数为 8 ，当 CPU 超过 80% 时触发扩容
~# kubectl autoscale deployment dep-test --min 1 --max 8 --cpu-percent 80
horizontalpodautoscaler.autoscaling/dep-test autoscaled
~# 
~# kubectl get hpa
NAME       REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
dep-test   Deployment/dep-test   0%/80%    1         8         4          2m29s

# HPA 正在等待其默认的 5 分钟缩容稳定期结束（如果 CPU 利用率持续保持低位），HPA 就会开始将 Pod 数量从 4 缩减到 1。
~# kubectl get pods -o wide 
NAME                        READY   STATUS    RESTARTS   AGE     IP              NODE    NOMINATED NODE   READINESS GATES
dep-test-76866db9d5-rzs22   1/1     Running   0          8m17s   10.244.104.44   node2   <none>           <none>
~# 


### 压力测试
# 模拟一个 pod 负载很重
~# kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
dep1-9d9d988c6-tpf6g   1/1     Running   0          31m
~# kubectl exec -it dep1-9d9d988c6-tpf6g -- bash
root@dep1-9d9d988c6-tpf6g:/# cat /dev/zero > /dev/null &
[1] 37
root@dep1-9d9d988c6-tpf6g:/# cat /dev/zero > /dev/null &
[2] 38
root@dep1-9d9d988c6-tpf6g:/# cat /dev/zero > /dev/null &
[3] 39
root@dep1-9d9d988c6-tpf6g:/# exit
exit
~# kubectl get hpa
NAME   REFERENCE         TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
dep1   Deployment/dep1   cpu: 91%/10%   1         6         6          28m
~# kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
dep1-9d9d988c6-975lp   1/1     Running   0          42s
dep1-9d9d988c6-q8ws9   1/1     Running   0          27s
dep1-9d9d988c6-qt7p2   1/1     Running   0          42s
dep1-9d9d988c6-rf9pd   1/1     Running   0          27s
dep1-9d9d988c6-tpf6g   1/1     Running   0          33m
dep1-9d9d988c6-xpzs9   1/1     Running   0          42s
~# kubectl delete pods dep1-9d9d988c6-tpf6g
pod "dep1-9d9d988c6-tpf6g" deleted
~# kubectl get hpa
NAME   REFERENCE         TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
dep1   Deployment/dep1   cpu: 65%/10%   1         6         6          30m
~# kubectl get hpa
NAME   REFERENCE         TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
dep1   Deployment/dep1   cpu: 0%/10%   1         6         6          30m
~# kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
dep1-9d9d988c6-975lp   1/1     Running   0          2m21s
dep1-9d9d988c6-lqfjs   1/1     Running   0          19s
dep1-9d9d988c6-q8ws9   1/1     Running   0          2m6s
dep1-9d9d988c6-qt7p2   1/1     Running   0          2m21s
dep1-9d9d988c6-rf9pd   1/1     Running   0          2m6s
dep1-9d9d988c6-xpzs9   1/1     Running   0          2m21s
~# kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
dep1-9d9d988c6-qt7p2   1/1     Running   0          10m

### 外部访问压力测试
# 为 Kubernetes 中的 Deployment 创建一个 Service ，并将其暴露给集群外部
~# kubectl expose --help | grep dep
~# kubectl expose deployment dep1 --port=80 --target-port=80 --type=NodePort
service/dep1 exposed

# kubectl expose: 这是 kubectl 命令的一个子命令，用于创建 Service 对象，从而将应用程序暴露给网络
# deployment dep1: 指定了要暴露的目标资源类型是 Deployment，名称为 dep1;这个 Service 将会把流量转发到 dep1 Deployment 所管理的 Pods
# --port=80: 定义了 Service 自身的端口;集群内部的其他 Pods 或 Service 想要访问这个 dep1 服务时，会通过 80 端口
# --target-port=80: 定义了 Pod 内部容器监听的端口 (Container Port);流量到达 Service 后，会被转发到后端 Pod 内部的 80 端口
# --type=NodePort: 指定了要创建的 Service 的类型为 NodePort

# NodePort 是 Kubernetes Service 的一种类型，它提供了从集群外部访问 Service 的方式。它的工作原理如下：
# 在集群中的每个节点上开放一个静态的端口（NodePort）。这个端口的范围默认是 30000-32767
# 任何发送到集群中节点的 IP 地址和这个 NodePort 的流量，都会被自动转发到 Service 的 Cluster IP 和 port，进而转发到后端 Pod 的 target-port
# 如果后端有多个 Pod，Service 会在这些 Pod 之间进行负载均衡。

~# kubectl get svc
NAME   TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
dep1   NodePort   10.106.88.38   <none>        80:30470/TCP   6s

# 访问 master 主机 30470，就可以访问 dep1 的这个 service 了,这个 service 会把请求丢给 pod
# 安装 ab 具，ab 是 apachebench 命令的缩写，ab 是 apache 自带的压力测试工具
# CentOS：yum install -y httpd-tools.x86_64
# Debian：sudo apt install apache2-utils -y

~# ab -t 600 -n 1000000 -c 1000 http://192.168.0.200:30470/index.html
This is ApacheBench, Version 2.3 <$Revision: 1843412 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 192.168.0.200 (be patient)
Completed 100000 requests
Completed 200000 requests
Completed 300000 requests
Completed 400000 requests
Completed 500000 requests
Completed 600000 requests
Completed 700000 requests
Completed 800000 requests

# 等待，观察top情况及pod数量
~# kubectl get hpa
NAME   REFERENCE         TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
dep1   Deployment/dep1   cpu: 16%/10%   1         6         1          66m
~# kubectl get hpa
NAME   REFERENCE         TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
dep1   Deployment/dep1   cpu: 19%/10%   1         6         6          66m
```

## DaemonSet

DaemonSet 确保在集群的**每一个（或指定的）节点**上都运行一个 Pod 的副本。
daemonset 也是一种控制器，也是用来创建pod的，但是和dep不一样，dep 需要指定副本数，每个 worker 上都可以运行多个副本。
ds 不需要指定副本数，会自动的在每个 worker上都创建1个副本，不可运行多个。这东西有啥用？
作用就是在每个节点上收集日志、监控和管理等，还记得drain操作吗？里面包含驱逐操作，这个pod是不能删除的。
由于 DaemonSet 的特性是“每台机器一个副本”，它通常用于执行 系统级操作 或 基础服务：
    日志收集：在每个节点运行日志采集 Agent，例如 fluentd 或 logstash。
    节点监控：在每个节点运行监控组件，例如 Prometheus Node Exporter、collectd 或 Datadog agent。
    网络插件：在每个节点运行网络组件，例如 calico-node、flannel 或 kube-proxy。
    存储守护进程：在每个节点运行存储驱动，例如 ceph、glusterd 的客户端。



## StatefulSet



# 实现配置与镜像分离

使用某些镜像例如 mysql，是需要变量来传递密码的，也就是再编写yaml文件的时候，需要在参数里面指定明文密码。这样就会导致一定的安全隐患。

为了安全起见，涉及到密码、Token、证书，一律用 Secret；涉及到环境变量、配置文件，一律用 ConfigMap。
ConfigMap (CM) 和 Secret 是专门用来实现 “配置与镜像分离” 的资源对象。	
ConfigMap 是明文存储的，主要用于存放数据库地址、日志级别、配置文件等非敏感信息。
Secret 虽然在底层也是存在 etcd 里的，但它在 API 层面会有特殊的保护，并且在显示时是 Base64 编码的。最重要的是，K8s 的权限管理（RBAC）通常会把 Secret 的访问权限控制得比 ConfigMap 更严。

Secret 和 ConfigMap 都是属于特定命名空间的。

## Secret

**类型**
默认为 Opaque，base64 编码格式，用来**存储敏感配置数据**，密码和密钥。Base64 只是为了编码二进制，不是加密。
dockerconfigjson：存储私有 docker registry 的认证信息
service-account-token：用于被 serviceaccount 引用。sa 创建的时候，k8s 会创建对应的 secret。如果 pod 使用了 sc，对应的secret会自动挂载到pod目录。

### 创建方式

当执行 kubectl create secret 时，发生了一个“数据迁移”的过程：
读取：kubectl 读取了本地原始数据文件里的内容。
传输：它把内容发给了集群的 API Server。
持久化：API Server 把内容存进了集群的数据库 etcd 里。
一旦存入 etcd，它就和本地原始数据文件彻底“断开联系”了。即使把创建 Secret 时的原始数据文件删了，Pod 照样跑，Secret 照样在。

```bash
### 1.命令行方式
~# kubectl create secret --help
~# kubectl create secret generic --help | grep from
kubectl create secret generic my-secret --from-literal=key1=supersecret --from-literal=key2=topsecret
~# kubectl create secret generic mysec1 --from-literal=name1=redhat     # 当然，如果有第二个第三个可以继续写。
secret/mysec1 created
~# kubectl get secrets 
NAME     TYPE     DATA   AGE
mysec1   Opaque   1      17s
~# 
~# kubectl describe secret 
Name:         mysec1
Namespace:    default
Labels:       <none>
Annotations:  <none>
Type:  Opaque
Data
====
name1:  6 bytes
~# 
# 这样，未来创建需要密码的 pod，直接引用 mysec1 的 key (即 name1）
# Base64 只是为了编码二进制，不是加密。通过解码来获得密码
~# kubectl get secret mysec1 -o yaml | grep name1
  name1: cmVkaGF0
~# echo -n cmVkaGF0 | base64 -d
redhat~# 
~# echo -n redhat | base64
cmVkaGF0
~# 
# ------------------------------------------------------------------------  
### 2.文件方式
~# echo -n redhat > name1
~# cat name1 
redhat~# 
~# kubectl create secret generic mysec2 --from-file=./name1
secret/mysec2 created
# Key：自动变成了文件名（即 name1）。
# Value：自动变成了文件里的全部内容。
~# 
~# kubectl get secret
NAME     TYPE     DATA   AGE
mysec1   Opaque   1      25m
mysec2   Opaque   1      9s
~# 
~# kubectl get secret mysec2 -o yaml | grep name1
  name1: cmVkaGF0
~# 
# ------------------------------------------------------------------------  
### 3.变量方式
~# cat var.txt
name1=redhat1
name2=redhat2
~# kubectl create secret generic mysec3 --from-env-file=var.txt
secret/mysec3 created
~# kubectl get secret
NAME     TYPE     DATA   AGE
mysec1   Opaque   1      46m
mysec2   Opaque   1      20m
mysec3   Opaque   2      10s
~# kubectl get secret mysec3 -o yaml | grep name
  name1: cmVkaGF0MQ==
  name2: cmVkaGF0Mg==
  name: mysec3
  namespace: default
~# 
# ------------------------------------------------------------------------  
### 4.yaml 文件方式
~# cat mysec4.yaml 
apiVersion: v1
kind: Secret
metadata:
  name: mysec4
  namespace: mysec    # 注意 namespace 必须存在
type: Opaque
data:              # 使用 stringData 字段就不需要为 Value 手动做 Base64 编码
  name1: cmVkaGF0MQ==
  name2: cmVkaGF0Mg==
~# 
~# kubectl apply -f mysec4.yaml 
secret/mysec4 created
~# kubectl get secret
NAME     TYPE     DATA   AGE
mysec1   Opaque   1      66m
mysec2   Opaque   1      40m
mysec3   Opaque   2      20m
~# kubectl get secret -n mysec
NAME     TYPE     DATA   AGE
mysec4   Opaque   2      14s
~# kubectl get secret -n mysec -o yaml | grep name
    name1: cmVkaGF0MQ==
    name2: cmVkaGF0Mg==
        {"apiVersion":"v1","kind":"Secret","metadata":{"annotations":{},"name":"mysec4","namespace":"mysec"},"stringData":{"name1":"redhat1","name2":"redhat2"},"type":"Opaque"}
    name: mysec4
    namespace: mysec
~# 
# 即使把创建 Secret 时的原始数据文件删了，Pod 照样跑，Secret 照样在。
~# kubectl get secret -n mysec
NAME     TYPE     DATA   AGE
mysec4   Opaque   2      23h
~# rm -rf name1 var.txt mysec4.yaml 
~# kubectl get secret -n mysec
NAME     TYPE     DATA   AGE
mysec4   Opaque   2      24h
~# 
# ------------------------------------------------------------------------  
### 删除 Secret
~# kubectl delete secrets mysec1
secret "mysec1" deleted
```

### 使用方式

https://kubernetes.io/docs/concepts/configuration/secret/

#### 挂载为文件

Secret 是属于特定命名空间的。Pod 只能挂载与其处于同一个命名空间下的 Secret。
Secret 只是存放在 K8s 数据库里的“原材料”，挂载就是把这些材料加工成容器看得见、摸得着的“文件”。
这种方式适用于证书、复杂的配置文件。K8s 会把 Secret 里的 Key 变成目录下的文件名，Value 变成文件内容。

```bash
~# kubectl get secret
NAME     TYPE     DATA   AGE
mysec1   Opaque   1      24h
mysec2   Opaque   1      24h
mysec3   Opaque   2      23h
~# kubectl get secret -n mysec
NAME     TYPE     DATA   AGE
mysec4   Opaque   2      23h
~# cat pod-test.yaml 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-test
  name: pod-test
  namespace: mysec            # Secret 和 Pod 必须处于同一个 Namespace 才能挂载成功。
spec:
  nodeName: node2
  volumes:
  - name: vol-1
    secret:            # 指定卷的类型为 Secret
      secretName: mysec4        # 指定要读取哪个 Secret 对象
      optional: true
# optional: true（运维的保险丝）：
# false（默认值）：如果找不到 mysec4 这个 Secret，Pod 会一直卡在 ContainerCreating 状态，并且报错。
# 如果设为 true：即使 mysec4 不存在，Pod 也会正常启动。只不过你进去容器看 /mountPath-mysec 目录时，里面会是空的。这对于一些“可选配置”非常有用。
  containers:
  - image: nginx:1.20
    imagePullPolicy: Never
    name: pod-test
    resources: {}
    volumeMounts:
    - name: vol-1
      mountPath: /mountPath-mysec
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
~# 
~# kubectl apply -f pod-test.yaml 
pod/pod-test created
~# kubectl get pods -o wide 
No resources found in default namespace.
~# kubectl get pods -o wide -n mysec 
NAME       READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
pod-test   1/1     Running   0          12s   10.244.104.37   node2   <none>           <none>
~# kubectl exec -it pod-test -- bash
Error from server (NotFound): pods "pod-test" not found
~#
~# kubectl exec -it -n mysec pod-test -- bash
root@pod-test:/# ls
bin  boot  dev  docker-entrypoint.d  docker-entrypoint.sh  etc  home  lib  lib64  media  mnt  mountPath-mysec  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
root@pod-test:/# ls /mountPath-mysec/
name1  name2
root@pod-test:/# cat /mountPath-mysec/name1
redhat1root@pod-test:/# 
root@pod-test:/# cat /mountPath-mysec/name2
redhat2root@pod-test:/# 
root@pod-test:/# 
root@pod-test:/# exit
exit
~# 
# mysec4 在容器中以文件的方式来显示了。文件就是键，内容就是值。
~# kubectl get secret mysec4 -n mysec -o yaml | head -5
apiVersion: v1
data:
  name1: cmVkaGF0MQ==
  name2: cmVkaGF0Mg==
kind: Secret
~# 
~# kubectl get secret -n mysec -o yaml | grep -i name
    name1: cmVkaGF0MQ==
    name2: cmVkaGF0Mg==
        {"apiVersion":"v1","kind":"Secret","metadata":{"annotations":{},"name":"mysec4","namespace":"mysec"},"stringData":{"name1":"redhat1","name2":"redhat2"},"type":"Opaque"}
    name: mysec4
    namespace: mysec
~# 
# ------------------------------------------------------------------------  
### 数据更新同步（热更新）
# 如果我现在 kubectl edit secret mysec4 -n mysec 修改了 name1 的值，过约 1 分钟左右，容器内 /mountPath-mysec/name1 的内容会自动变掉，不需要重启 Pod。
~# kubectl edit secret mysec4 -n mysec 
secret/mysec4 edited
~# 
~# kubectl get secret mysec4 -n mysec -o yaml | head -6
apiVersion: v1
data:
  name1: cmVkaGF0MQ==
  name2: cmVkaGF0Mg==
  name3: cmVkaGF0Mw==
kind: Secret
~# 
~# kubectl get pods -n mysec pod-test -o wide 
NAME       READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
pod-test   1/1     Running   0          58m   10.244.104.37   node2   <none>           <none>
~# 
~# kubectl exec -it -n mysec pod-test -- bash
root@pod-test:/# ls /mountPath-mysec/
name1  name2  name3
root@pod-test:/# cat /mountPath-mysec/name3
redhat3root@pod-test:/# 
root@pod-test:/# exit
exit
~#
```

#### 注入环境变量

作为环境变量使用 Secret，必须写在控制 Pod 运行的 YAML 文件中。

环境变量不支持热更新，这是由 Linux 操作系统的本质决定的：

​    启动快照：当一个容器进程启动时，操作系统会把环境变量分配给该进程。

​    静态性：进程运行过程中，外部环境（K8s）无法强行修改该进程内存中的环境变量。

如果修改了 Secret，而 Pod 是通过 env 引用的，程序会一直拿着旧密码尝试连接，直到手动执行 kubectl rollout restart 为止。

在 Linux 的 Bash Shell 中，变量名是不允许包含连字符（减号 -）的。

```bash
~# cat pod-test.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pod-test
  namespace: mysec
spec:
  nodeName: node2
  containers:
  - image: nginx:1.20
    imagePullPolicy: Never
    name: pod-test
    resources: {}
    env:
    - name: env_mysec            # 给容器内部定义的变量名，在 Linux 的 Bash Shell 中，变量名是不允许包含连字符（减号 -）的。
      valueFrom:                 # 告诉 K8s 这个值不是直接写的，而是从别处引用的
        secretKeyRef:            # 引用来源是一个 Secret 对象
          name: mysec4           # 指定 Secret 的名字叫 mysec4
          key: name3             # 指定取 mysec4 里的哪一个 Key（即 name3 对应的值）
~# 
~# kubectl get pods -n mysec -o wide
NAME       READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
pod-test   1/1     Running   0          4s    10.244.104.36   node2   <none>           <none>
~# kubectl exec -it -n mysec pod-test -- echo $env_mysec
redhat3
~# 
~# kubectl get secret -n mysec mysec4 -o yaml | grep -i name
  name1: cmVkaGF0MQ==
  name2: cmVkaGF0Mg==
  name3: cmVkaGF0Mw==
      {"apiVersion":"v1","kind":"Secret","metadata":{"annotations":{},"name":"mysec4","namespace":"mysec"},"stringData":{"name1":"redhat1","name2":"redhat2"},"type":"Opaque"}
  name: mysec4
  namespace: mysec
~# 
# 上述是一个一个引用的 Key，使用 envFrom 可以直接把 CM 或 Secret 里的所有键值对全量变成容器环境变量。
~# cat pod-test.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pod-test
  namespace: mysec
spec:
  nodeName: node2
  containers:
  - image: nginx:1.20
    imagePullPolicy: Never
    name: pod-test
    resources: {}
    envFrom:
    - secretRef: 
        name: mysec4           
~# kubectl apply -f pod-test.yaml 
pod/pod-test created
~# kubectl exec -it -n mysec pod-test -- env | grep name
name3=redhat3
name1=redhat1
name2=redhat2
~# 
# ------------------------------------------------------------------------  
### 实战场景
# 利用 Secret 资源安全地启动并登录一个数据库，而不在 YAML 文件里暴露任何明文密码。
~# cat pod-test.yaml 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-test
  name: pod-test
  namespace: mysec
spec:
  nodeName: node2
  containers:
  - image: mysql:9.5.0
    imagePullPolicy: Never
    name: pod-test
    resources: {}
    env:
    - name: MYSQL_ROOT_PASSWORD            # 使用官方 MySQL 镜像时，必须设置这个变量
      valueFrom:
        secretKeyRef:
          name: mysec4
          key: name3
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
~# 
~# kubectl apply -f pod-test.yaml 
pod/pod-test created
~# kubectl get pods -n mysec -o wide
NAME       READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
pod-test   1/1     Running   0          4s    10.244.104.40   node2   <none>           <none>
~# 
~# apt install mysql-client -y
~# 
~# kubectl exec -it -n mysec pod-test -- bash
bash-5.1# env | grep MYSQL_ROOT_PASSWORD
MYSQL_ROOT_PASSWORD=redhat3
bash-5.1# 
bash-5.1# mysql -u root -p        
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 12
Server version: 9.5.0 MySQL Community Server - GPL

Copyright (c) 2000, 2025, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> CREATE DATABASE MYSEC;
Query OK, 1 row affected (0.003 sec)

mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| MYSEC              |
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.001 sec)

mysql> EXIT
Bye
bash-5.1# exit
exit
~# 
~# mysql -uroot -predhat3 -h 10.244.104.40
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 13
Server version: 9.5.0 MySQL Community Server - GPL

Copyright (c) 2000, 2025, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| MYSEC              |
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.01 sec)

mysql> EXIT
Bye
~# 
```

#### 拉取私有镜像

默认情况下，K8s 可以自由拉取公共镜像。但如果你的镜像是存在私有 Harbor（公司内部仓库）、阿里云/腾讯云的私有镜像仓库、Docker Hub 	的私有项目；

那么 Kubelet 在拉镜像时就会报 ErrImagePull 或 ImagePullBackOff，因为它没有“登录账号”。
拉取镜像用的 Secret 类型不是 generic，而是 docker-registry。

> kubectl create secret docker-registry  \
> --docker-server=<仓库地址> \
> --docker-username=<用户名> \
> --docker-password=<密码> \
> --docker-email=<邮箱（可选）> \
> -n <命名空间>

```bash
~# kubectl create secret docker-registry mysec5 \
--docker-server=crpi-bkg7bvmf5xyivcsd.cn-shanghai.personal.cr.aliyuncs.com/onlymyself/onlymyself-hub \
--docker-username=aoeiuv123456 \
--docker-password=5Ly9418hh. \
-n mysec
secret/mysec5 created
~# 
~# kubectl get secret -n mysec
NAME     TYPE                             DATA   AGE
mysec4   Opaque                           3      27h
mysec5   kubernetes.io/dockerconfigjson   1      3s
~# cat pod-test.yaml 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-test
  name: pod-test
  namespace: mysec
spec:
  nodeName: node2
  imagePullSecrets:
  - name: mysec5            # 引用创建的 mysec5
  containers:
  - image: crpi-bkg7bvmf5xyivcsd.cn-shanghai.personal.cr.aliyuncs.com/onlymyself/onlymyself-hub:centos-7.9.2009
    imagePullPolicy: Always
    command: ["/bin/bash", "-c", "while true; do sleep 3600; done"]        # 让容器进入死循环休眠
    name: pod-test
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
~# 
# 镜像默认启动的是 /bin/bash；而在 K8s 中，如果你不给 bash 分配一个交互式终端或者一个一直运行的任务，bash 启动后发现没事干，就会立即结束进程。
~# kubectl apply -f pod-test.yaml 
pod/pod-test created
~# kubectl get pods -n mysec
NAME       READY   STATUS    RESTARTS   AGE
pod-test   1/1     Running   0          5s
~# 
~# kubectl exec -it -n mysec pod-test -- bash
[root@pod-test /]# cat /etc/os-release
NAME="CentOS Linux"
VERSION="7 (Core)"
...
[root@pod-test /]# exit
exit
~#
```

## ConfigMap
ConfigMap 是 Kubernetes 用来**存储非敏感配置数据**的资源对象，配置文件（如 nginx.conf）、环境变量、各种开关参数（明文存储）。
实现配置与镜像的分离。不需要为了改一个配置参数而重新打包镜像。
ConfigMap 的创建和 Secret 几乎一样命令极其相似，只是把 secret 换成了 configmap
ConfigMap 的两种用法：注入环境变量、挂载为文件（都和 Secret 完全一致）
ConfigMap 也是属于特定命名空间的。

```bash
### 实战场景
# 通过 ConfigMap 修改 Nginx 的默认网页内容
~# echo '<h1>Hello from Kubernetes ConfigMap!</h1>' > index.html
~# kubectl create configmap myconfig1 --from-file=index.html -n myconfig
configmap/myconfig1 created
~# kubectl get configmaps 
NAME               DATA   AGE
kube-root-ca.crt   1      7d11h
~# kubectl get configmaps -n myconfig 
NAME               DATA   AGE
kube-root-ca.crt   1      82s
myconfig1          1      18s
~# 
# kube-root-ca.crt 是 Kubernetes 自动为每个 Namespace 创建的 ConfigMap，里面存的是集群的根 CA 证书，用来让 Pod / ServiceAccount 校验 API Server 的身份。
# 每创建一个 Namespace，Kubernetes 就会自动创建 kube-root-ca.crt（ConfigMap）
~# kubectl get configmaps -n myconfig myconfig1 -o yaml
apiVersion: v1
data:
  index.html: |
    <h1>Hello from Kubernetes ConfigMap!</h1>
kind: ConfigMap
metadata:
  creationTimestamp: "2025-12-27T03:58:03Z"
  name: myconfig1
  namespace: myconfig
  resourceVersion: "537314"
  uid: be4fe1f3-4e7c-4662-a4bf-6f639c2a0917
~# 
~# cat pod-test.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pod-test
  namespace: myconfig
spec:
  nodeName: node2
  volumes:
  - name: vol-myconfig
    configMap:
      name: myconfig1
  containers:
  - image: nginx:1.20
    imagePullPolicy: Never
    name: pod-test
    volumeMounts:
    - name: vol-myconfig
      mountPath: /usr/share/nginx/html
~# 
~# kubectl apply -f pod-test.yaml
pod/pod-test created
~# kubectl get pods -n myconfig -o wide 
NAME       READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
pod-test   1/1     Running   0          17s   10.244.104.42   node2   <none>           <none>
~# curl 10.244.104.42
<h1>Hello from Kubernetes ConfigMap!</h1>
~# 
# ------------------------------------------------------------------------  
### 数据更新同步（热更新）
~# kubectl edit configmaps -n myconfig myconfig1 
configmap/myconfig1 edited
~# kubectl get configmaps -n myconfig myconfig1 -o yaml
apiVersion: v1
data:
  index.html: |
    <h1>Hello World!</h1>
kind: ConfigMap
metadata:
  creationTimestamp: "2025-12-27T03:58:03Z"
  name: myconfig1
  namespace: myconfig
  resourceVersion: "540126"
  uid: be4fe1f3-4e7c-4662-a4bf-6f639c2a0917
~# 
~# curl 10.244.104.42
<h1>Hello World!</h1>
~# 
# ------------------------------------------------------------------------  
# 当你把 CM 挂载到一个目录（如 /usr/share/nginx/html）时，该目录下原有的所有文件都会被覆盖掉，只显示 CM 里的文件。
# subPath 是 VolumeMount 的一个可选字段，对所有类型的 Volume 都适用。subPath 不支持热更新
# subPath 的意义在于保护了“邻居”，只覆盖同名文件，单个文件精准投放
~# kubectl exec -it -n myconfig pod-test -- ls /usr/share/nginx/html
index.html
~# kubectl run nginx --image nginx:1.20 --image-pull-policy Never
pod/nginx created
~# kubectl get pods -o wide 
NAME    READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          11s   10.244.104.43   node2   <none>           <none>
~# kubectl exec -it nginx -- ls -l /usr/share/nginx/html
total 8
-rw-r--r-- 1 root root 494 Nov 16  2021 50x.html
-rw-r--r-- 1 root root 612 Nov 16  2021 index.html
~# grep -A5 volumeMounts pod-test.yaml
    volumeMounts:
    - name: vol-myconfig
      mountPath: /usr/share/nginx/html/index.html            # 如果不想替换容器原本的 index.html，这里可以起个别名
      subPath: index.html            # ConfigMap 里的 Key (文件名)
~#
~# kubectl apply -f pod-test.yaml
pod/pod-test created
~# kubectl exec -it -n myconfig pod-test -- ls -l /usr/share/nginx/html
total 8
-rw-r--r-- 1 root root 494 Nov 16  2021 50x.html
-rw-r--r-- 1 root root  22 Dec 27 05:03 index.html
~# kubectl get pods -n myconfig -o wide 
NAME       READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
pod-test   1/1     Running   0          59s   10.244.104.45   node2   <none>           <none>
~# curl 10.244.104.45
<h1>Hello World!</h1>
~# 
```
## immutable

immutable 字段是 Secret 和 ConfigMap 专属的“锁定”功能，在 YAML 文件的根层级（和 metadata、data 平级）。

加上 immutable: true ，可以锁定数据，Kubelet 不再监控，性能大提升。

普通配置：Kubelet 会不停地盯着 API Server 问：“这个 Secret 改了没？改了没？”这会消耗集群的 CPU 和带宽。

不可变配置：一旦设为 true，Kubelet 收到后就会把它缓存到内存里，然后彻底不再去管它了。对于有成千上万个 Pod 的大型集群，这能显著减轻数据库（etcd）的压力。

能防止不小心用 kubectl edit 改掉了一个关键配置，导致正在运行的生产系统崩溃。这提供了一个“物理层”的保护。

设置之后不能把 true 改回 false。一旦这个对象被创建为 immutable，它的状态就锁死了

```bash
~# kubectl edit secrets -n mysec mysec4
secret/mysec4 edited
~# kubectl get secret -n mysec -o yaml 
apiVersion: v1
items:
- apiVersion: v1
  data:
    name1: cmVkaGF0MQ==
    name2: cmVkaGF0Mg==
    name3: cmVkaGF0Mw==
  immutable: true
  kind: Secret
...
~# 
~# kubectl edit secrets -n mysec mysec4
error: secrets "mysec4" is invalid
A copy of your changes has been stored to "/tmp/kubectl-edit-994755824.yaml"
error: Edit cancelled, no valid changes were saved.
~# 
```
# Service

在 K8s 中，Pod 是有生命周期的，Pod 会重启、故障、被删除，Pod 每次重建，IP 地址都会发生变化。
如果没有 Service，你的前端程序永远不知道该去哪个 IP 找数据库。
Service 是一个逻辑抽象，它定义了一组 Pod 的访问策略。
Pod 的 ip 只有集群内部可见，master 和 node 可以访问，其他 pod 也是可以访问的。
为何可以内部互通？因为我们配置了calico网络，会建立起很多iptables及转发的规则。但是外接的主机是无法连通这个 pod 的。
如果想让外界访问，我们可以做端口映射，但是有很多弊端：
如果你把这个 Pod 部署到了 node2 上，那么 node2 的 5000 端口就被占用了。
如果你想在 node2 上再开一个同样的 Pod，会失败。因为一个物理机端口只能给一个进程用。K8s 调度器会发现 node2 没端口了，只能去别的机器找地方。
如果你不小心设了个 hostPort: 22（SSH）或者 hostPort: 80（如果物理机装了 Web 服务），会导致冲突，甚至让物理机的关键服务停摆。
如果你的 Pod 漂移到了 node3，你访问的地址就得从 node2_IP:5000 变成 node3_IP:5000。这对于客户端来说简直是灾难。
## 创建 Service
Service 提供了 Pod 的统一入口和负载均衡。
port 是 Service 对外暴露的端口，客户端访问 Service 使用的端口，svc本身不提供业务服务，只是负载均衡器，而 targetport  是后端 pod 本身开放的端口。
Service 通过 Selector 找到 Pod，并通过 Endpoints 列表进行流量分发。
只要 Service IP 不变，后端 Pod 怎么死、怎么换 IP、怎么增减数量，对前端调用者完全透明。
```bash
~# kubectl expose --name svc-test deployment dep-test --port 5500 --target-port 80 --dry-run=client -o yaml > svc-test.yaml
# 没写 type，默认就是 ClusterIP
~# cat svc-test.yaml 
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: dep-test
  name: svc-test
spec:
  ports:
  - port: 5500            # Service 对外暴露的端口；客户端访问的端口
    protocol: TCP
    targetPort: 80        # 后端 Pod 中 容器实际监听的端口
  selector:               # Service 通过 selector 与 Pod 建立关联
    app: dep-test        # Service 会去找标签为 dep-test 的 所有 Pod
status:
  loadBalancer: {}
~# 
~# kubectl apply -f svc-test.yaml 
service/svc-test created
~# kubectl get pods -o wide 
NAME                        READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
dep-test-59bb6d979d-2xkcm   1/1     Running   0          19m   10.244.104.52   node2   <none>           <none>
dep-test-59bb6d979d-qtmlg   1/1     Running   0          19m   10.244.104.25   node2   <none>           <none>
dep-test-59bb6d979d-tsfgn   1/1     Running   0          19m   10.244.104.47   node2   <none>           <none>
~# 
~# kubectl exec -it dep-test-59bb6d979d-2xkcm -- bash
root@dep-test-59bb6d979d-2xkcm:/# echo "111" > /usr/share/nginx/html/index.html
root@dep-test-59bb6d979d-2xkcm:/# exit
exit
~# kubectl exec -it dep-test-59bb6d979d-qtmlg -- bash
root@dep-test-59bb6d979d-qtmlg:/# echo "222" > /usr/share/nginx/html/index.html
root@dep-test-59bb6d979d-qtmlg:/# exit
exit
~# kubectl exec -it dep-test-59bb6d979d-tsfgn -- bash
root@dep-test-59bb6d979d-tsfgn:/# echo "333" > /usr/share/nginx/html/index.html
root@dep-test-59bb6d979d-tsfgn:/# exit
exit
~# kubectl get deployments.apps -o wide 
NAME       READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES       SELECTOR
dep-test   3/3     3            3           26m   nginx        nginx:1.20   app=dep-test
~# 
~# kubectl get services -o wide 
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE     SELECTOR
dep-test     NodePort    10.96.28.47   <none>        80:31161/TCP   2d20h   app=dep-test
kubernetes   ClusterIP   10.96.0.1     <none>        443/TCP        8d      <none>
svc-test     ClusterIP   10.99.89.87   <none>        5500/TCP       9m43s   app=dep-test
~# 
# ------------------------------------------------------------------------  
### 体现负载均衡
~# curl 10.99.89.87:5500
111
~# curl 10.99.89.87:5500
333
~# curl 10.99.89.87:5500
222
~# 
```
**为什么要负载均衡？**

> A. 高可用性（避免单点故障）
> 如果 1 号会计突然晕倒了（Pod 挂了），经理（Service）会立刻发现，并把接下来的所有客户都导向 2 号和 3 号窗口。
> 结果：虽然少了一个人，但银行依然在营业，客户没感觉到服务中断。
> B. 扩展性（应对业务高峰）
> 如果是双十一，客户暴增。你可以通过修改 Deployment 把 replicas 从 3 改成 10（增加到 10 个窗口）。
> 结果：Service 会自动把这 10 个窗口都管起来，哪怕客人再多，平均摊到每个会计头上的活也就没那么重了。
> C. 低延迟
> 多个 Pod 同时处理请求，比一个 Pod 苦哈哈地排队处理，速度要快得多。

## 服务发现
> 服务域名（Service DNS 名）（FQDN）
> <服务名>.<命名空间>.svc.cluster.local
> 跨空间访问：如果你在 default 空间的 Pod 想找 mysec 空间的数据库，就得用这个全名。
> 同空间访问：直接喊名字 svc-test 即可。

A. **环境变量**（旧派做法，不推荐）
	当启动一个 Pod 时，K8s 会把当前集群里所有已存在的 Service 信息以环境变量的形式塞进 Pod。如果先开了 Pod，后开了 Service，那这个 Pod 里的环境变量里就没有那个 Service。这就好比公司才招了新人，你的通讯录里没他。
B. **DNS 域名发现**（现代标准，强烈推荐）
    这是目前最通用的方式。K8s 内部运行着一个叫 CoreDNS 的服务，它像一个自动更新的“电话本”。只要创建了一个叫 svc-test 的 Service，CoreDNS 就会自动生成一条记录。在同一个命名空间下，你不需要输入 IP，直接访问名字就行

```bash
~# kubectl run test-client --image=busybox:1.28 -it --rm -- sh
# -it: 交互式模式
# --rm: 退出后自动删除这个临时 Pod
If you don't see a command prompt, try pressing enter.
/ # wget -qO- svc-test:5500
222
/ # nslookup svc-test
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      svc-test
Address 1: 10.99.89.87 svc-test.default.svc.cluster.local
/ # 
/ # exit
Session ended, resume using 'kubectl attach test-client -c test-client -i -t' command when the pod is running
pod "test-client" deleted
~# 
# 跨空间访问
~# kubectl run test-client --image=busybox:1.28 -it --rm -n mysec -- sh
If you don't see a command prompt, try pressing enter.
/ # nslookup svc-test
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

nslookup: can't resolve 'svc-test'
/ # wget -qO- svc-test.default.svc.cluster.local:5500        
333
/ # exit
Session ended, resume using 'kubectl attach test-client -c test-client -i -t' command when the pod is running
pod "test-client" deleted
~# 
```
## ClusterIP
这是 Service 的默认类型，**用于集群内部通信**。
Service 会获得一个仅在集群内部可访问的虚拟 IP 地址 (ClusterIP)。所有发送到这个 ClusterIP 的流量都会被负载均衡到 Service 关联的后端 Pod 上。
只能从 Kubernetes 集群内部的其他 Pod 或节点访问。集群外部无法直接访问。
ClusterIP 是所有服务访问的“根基”和“终点站”。不管是什么服务发布方式，最终流量都会流向 ClusterIP 。

## 服务的发布
### NodePort
在所有节点（Master 和 Node）上开启一个相同的端口。
```bash
~# cat svc-test.yaml 
apiVersion: v1
kind: Service
metadata:
  name: svc-test
spec:
  type: NodePort            # 修改类型
  selector:
    app: dep-test
  ports:
  - port: 5500              # Service 的端口，ClusterIP 上监听的端口，集群内部访问 Service 用的端口
    targetPort: 80
    nodePort: 31111         # Node 对外暴露的端口（范围 30000-32767）
~# 
~# kubectl apply -f svc-test.yaml
service/svc-test created
~# kubectl get services -o wide 
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE    SELECTOR
dep-test     NodePort    10.96.28.47    <none>        80:31161/TCP     3d7h   app=dep-test
kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP          8d     <none>
svc-test     NodePort    10.106.139.1   <none>        5500:31111/TCP   4s     app=dep-test
~# kubectl get pods -o wide 
NAME                        READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
dep-test-59bb6d979d-2xkcm   1/1     Running   0          11h   10.244.104.52   node2   <none>           <none>
dep-test-59bb6d979d-qtmlg   1/1     Running   0          11h   10.244.104.25   node2   <none>           <none>
dep-test-59bb6d979d-tsfgn   1/1     Running   0          11h   10.244.104.47   node2   <none>           <none>
~# kubectl get nodes -o wide 
NAME     STATUS   ROLES           AGE   VERSION    INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
master   Ready    control-plane   8d    v1.29.15   192.168.0.10   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
node1    Ready    <none>          8d    v1.29.15   192.168.0.11   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
node2    Ready    <none>          8d    v1.29.15   192.168.0.12   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
~# 
~# curl 192.168.0.10:31111
333
~# curl 192.168.0.11:31111
333
~# curl 192.168.0.12:31111
333
~# 
~# curl 10.106.139.1:5500
111
~# 
```
### LoadBalancer
LoadBalancer 用于将集群内服务暴露到集群外部。自动分配 外部可访问 IP，提供 四层负载均衡（L4）
LoadBalancer 正常使用，必须同时具备：
负载均衡器（LB）
可被访问的外部 IP
LB 作用：接收外部流量、把流量分发到多个 Node / Pod、提供高可用
外部 IP 作用：客户端能访问到、提供稳定入口不随 Pod / Node 变化
外部 IP 不一定是公网 IP，只要客户端能路由到它，就可以是内网 IP。

https://metallb.universe.tf/installation/

**MetalLB** 是给裸金属 Kubernetes 集群提供 LoadBalancer 能力的组件。
裸金属 Kubernetes 集群：直接跑在物理服务器上的 Kubernetes 集群

> 在裸金属（Bare Metal）Kubernetes 集群中，默认情况下 LoadBalancer 类型的 Service 是无法工作的。如果你创建了一个 LoadBalancer Service，它的 EXTERNAL-IP 会一直处于  状态。
> 这是因为 Kubernetes 原生并没有自带负载均衡器的实现代码，它只是提供了接口，依赖云服务商（如 AWS、GCP、Azure）的控制器来分配真实的负载均衡器。
> MetalLB 就是为了解决这个问题而生的，它是目前最流行的裸金属 K8s 负载均衡解决方案。

```bash
### 安装 MetalLB
~# kubectl get configmap kube-proxy -n kube-system -o yaml | \
> sed -e "s/strictARP: false/strictARP: true/" | \
> kubectl apply -f - -n kube-system
configmap/kube-proxy configured
~# kubectl get configmap kube-proxy -n kube-system -o yaml | grep strictARP
      strictARP: true
      ...
~#     
# https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml 
~# kubectl apply -f metallb-native.yaml
namespace/metallb-system created
...
~#
# 等待 Pod 就绪
~# kubectl get pods -n metallb-system
NAME                          READY   STATUS    RESTARTS   AGE
controller-6cb594c767-k8k96   1/1     Running   0          7m10s
speaker-hhm2p                 1/1     Running   0          7m10s
speaker-mqsmp                 1/1     Running   0          7m10s
~# 
# 安装完成后，需要告诉 MetalLB 可以在哪个 IP 范围内分配地址。假设你的 K8s 节点所在网段是 192.168.0.0/24，你需要预留一段未被 DHCP 分配且未被占用的 IP 给 MetalLB 使用。
~# cat metallb-config.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.0.240-192.168.0.250 # 替换为实际规划的 IP 范围
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
~# 
~# kubectl apply -f metallb-config.yaml
ipaddresspool.metallb.io/first-pool created
l2advertisement.metallb.io/example created
~# 
~# kubectl get ipaddresspools.metallb.io -n metallb-system 
NAME         AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
first-pool   true          false             ["192.168.0.240-192.168.0.250"]
~# 
# ------------------------------------------------------------------------  
### 使用 LoadBalancer
~# cat svc-test.yaml 
apiVersion: v1
kind: Service
metadata:
  name: svc-test-loadbalancer
  namespace: myconfig
spec:
  type: LoadBalancer
  selector:
    app: dep-test
  ports:
  - port: 5501
    targetPort: 80
~# 
~# kubectl get services -n myconfig -o wide 
NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)          AGE     SELECTOR
svc-test-loadbalancer   LoadBalancer   10.109.156.110   192.168.0.240   5501:32131/TCP   8m14s   app=dep-test
~# curl 192.168.0.240:5501
<h1>Hello World!</h1>
~# 
# 如果再创建一个 NodePort Service 连接同一组 Pod，它们会“并存”。这就像是给同一个科室安装了第二部电话，或者开了第二个办事窗口。
~# cat svc-test.yaml 
apiVersion: v1
kind: Service
metadata:
  name: svc-test-nodeport
  namespace: myconfig
spec:
  type: NodePort
  selector:
    app: dep-test
  ports:
  - port: 5500
    targetPort: 80
    nodePort: 31111
~# kubectl apply -f svc-test.yaml 
service/svc-test-nodeport created
~# kubectl get services -n myconfig -o wide 
NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)          AGE   SELECTOR
svc-test-loadbalancer   LoadBalancer   10.109.156.110   192.168.0.240   5501:32131/TCP   24m   app=dep-test
svc-test-nodeport        NodePort       10.108.8.88      <none>          5500:31111/TCP   15s   app=dep-test
~# curl 192.168.0.12:31111
<h1>Hello World!</h1>
~# curl 192.168.0.240:5501
<h1>Hello World!</h1>
~# 
```

### Ingress
> NodePort 的成本：每个服务都要占一个端口。如果你有 100 个微服务，你的安全组要开 100 个孔，用户访问时得记 IP:30001、IP:30002…… 这不仅难记，而且非常不专业。
> LoadBalancer 的成本：在云上，每个 LoadBalancer 都要绑定一个公网 IP。100 个服务就是 100 个公网 IP，这每月的账单能让老板当场晕倒。
> Ingress 的出现，就是为了解决这两个问题：
> 省钱：只需要 1个 公网 IP（或者一个入口）。
> 专业：只用标准的 80/443 端口，通过域名来分流。

Ingress 的两大组成部分
Ingress 不是一个简单的对象，它由两部分组成：
A. **Ingress Resource**  (Ingress 资源)
这就是你写在 YAML 里的配置。
    内容：规定了如果访问 a.com 就去 Service-A，如果访问 b.com/shop 就去 Service-B。
    状态：它只是一张纸（记录在 etcd 里的数据），没有这张纸，没人干活。
B.  **Ingress Controller** (Ingress 控制器)
这是一个真实运行在 Pod 里的程序（通常是 Nginx、HAProxy 或 Traefik）。
    工作：它不断盯着 API Server 看你写了什么“规则”，然后自动修改自己的 Nginx 配置文件，并实现真正的流量转发。
    注意：K8s 默认不自带控制器。需要自己安装（最流行的是 Nginx Ingress Controller）。
Ingress Controller 根据 Ingress 规则把流量转发给 Service，由 Service 再转发到 Pod。

#### 安装 Nginx Ingress Controller
https://github.com/kubernetes/ingress-nginx
https://kubernetes.github.io/ingress-nginx/deploy/
```bash
# https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.1/deploy/static/provider/cloud/deploy.yaml
~# kubectl apply -f deploy.yaml 
...
~# kubectl get pods,svc -n ingress-nginx
NAME                                           READY   STATUS    RESTARTS   AGE
pod/ingress-nginx-controller-f9f6bc646-25kxv   1/1     Running   0          16m

NAME                                         TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
service/ingress-nginx-controller             LoadBalancer   10.97.106.204   192.168.0.241   80:31421/TCP,443:32226/TCP   16m
service/ingress-nginx-controller-admission   ClusterIP      10.101.48.50    <none>          443/TCP                      16m
~# 
```
#### 配置规则
https://kubernetes.io/docs/concepts/services-networking/ingress/

```bash
~# cat svc-test.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: svc-test-ingress
  namespace: myconfig
  annotations:
    kubernetes.io/ingress.class: "nginx"            # 这一行非常重要，告诉 K8s 这个规则由 nginx 控制器来执行
spec:
  rules:
  - host: web.libix.com             # 你想用的域名
    http:
      paths:
      - path: /                     # 匹配路径，/ 代表所有路径，即 http://web.libix.com/
        pathType: Prefix            # 前缀匹配，匹配所有以 / 开头的路径，即匹配全部
        backend:
          service:
            name: svc-test-loadbalancer          # 转发给哪个 Service
            port:
              number: 5501                       # 必须是 Service 定义的 port
~# 
# 当访问 http://web.libix.com/ 时，由 nginx Ingress Controller 接管流量，并把请求转发给 myconfig 命名空间下的 svc-test-loadbalancer:5501 Service。
~# kubectl get ingress -n myconfig 
NAME               CLASS    HOSTS           ADDRESS         PORTS   AGE
svc-test-ingress   <none>   web.libix.com   192.168.0.241   80      23m
~# 
# 测试
root@storage-node:~# cat /etc/hosts | grep libix
192.168.0.241 web.libix.com
root@storage-node:~# curl http://web.libix.com/
<h1>Hello World!</h1>
root@storage-node:~# curl http://web.libix.com/test/
<h1>Hello Kubernetes!</h1>
root@storage-node:~# 
# ------------------------------------------------------------------------  
### Exact (精确匹配) —— 严谨审计
# 只有访问准确的路径时才匹配。
~# kubectl get ingress -n myconfig svc-test-ingress -o yaml
...
        path: /test/
        pathType: Exact
...
~# 
# 测试
root@storage-node:~# curl http://web.libix.com/
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
root@storage-node:~# curl http://web.libix.com/test/
<h1>Hello Kubernetes!</h1>
root@storage-node:~# 
```
#### Rewrite
Rewrite 的作用： 当用户访问一个不存在的目录时，Ingress 在转发的一瞬间，把不存在的路径重写为某个存在的目录发给 Pod。

A. 静态资源加载（最常见）
	很多前端网页（Vue/React）打包后，里面的图片和 JS 路径都是 /static/xxx.js。如果你把这个网页挂在 web.libix.com/app1/ 下，没有 Rewrite 的话，网页会去 web.libix.com/static/ 找文件，结果就是网页打不开，全是乱码。
B. 灰度发布 / 版本控制
	你想让 web.libix.com/new 访问新版本的 Pod，web.libix.com/old 访问旧版本的 Pod。但这两个 Pod 内部的代码其实是一模一样的（都只认根目录 /）。这时候必须靠 Rewrite 来做翻译。
C. 隐藏后端真实结构
	出于安全考虑，你不想让外界知道你后端真实的文件夹结构。你对外暴露 /search，对内 Rewrite 到后端复杂的 /api/v1/query。

``` bash
root@storage-node:~# curl http://web.libix.com/rewrite
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
root@storage-node:~# 

~# cat svc-test.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: svc-test-ingress
  namespace: myconfig
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /            # 强制将匹配到的路径重写为根目录 /
spec:
  rules:
  - host: web.libix.com
    http:
      paths:
      - path: /rewrite          # 即 http://web.libix.com/rewrite
        pathType: Prefix
        backend:
          service:
            name: svc-test-localbalancer
            port:
              number: 5501
~# kubectl apply -f svc-test.yaml
ingress.networking.k8s.io/svc-test-ingress configured
~# 

root@storage-node:~# curl http://web.libix.com/rewrite
<h1>Hello World!</h1>
root@storage-node:~# 
### 在生产环境中，我们会用 正则表达式 来实现更聪明的重写
```
# Probes

Kubernetes 判断一个 Pod 是否健康的唯一标准是：**容器里的主进程还在不在（PID 是否存活）**。

场景一（假死）：你的程序陷入了死锁，或者内存溢出卡住了，网页打不开。但是，PID 进程号还在。K8s 会觉得：“嗯，进程在，它很健康”，然后继续给它发流量。用户访问全部超时。

场景二（启动慢）：你的应用启动需要加载 1GB 的数据，需要 30 秒。但是容器 1 秒就启动了。K8s 觉得：“进程起了，来接客吧！”。用户在第 2 秒访问，直接报错 500。

**探针（Probes）就是给 K8s 装上“听诊器”，容器是否“存活”、是否“就绪”、是否“启动完成”的检查机制。**

## 三大探针

### Liveness Probe (存活探针)

Readiness Probe (就绪探针)

Startup Probe (启动探针)



## 探测方式

# Helm

Helm 是查找、共享和使用为 Kubernetes 构建的软件的最佳方式 

在 Kubernetes 的世界里，Helm 就相当于 Linux 系统中的 yum 或 apt，或者 macOS 上的 Homebrew。它是管理 Kubernetes 应用的**神器**。
如果没有 Helm，你需要手动编写和管理几十个复杂的 YAML 文件；有了 Helm，你只需要一条命令就能安装、升级或回滚复杂的应用。
**核心术语**
**Chart（图表 / 包）：**
这就相当于一个“安装包”（比如 .deb 或 .msi）。
Helm Chart 是**由 模板化的 Deployment + Service + ConfigMap 组成的 完整应用解决方案**。
**Repository（仓库）：**
存放 Chart 的地方。
这就好比是一个“应用商店”或 Docker Hub，你可以从这里搜索并下载别人写好的 Chart。
最著名的是 Artifact Hub。
**Release（发行版）：**
当你在 K8s 集群中运行一个 Chart 时，生成的实例就叫 Release。
比喻：Chart 是 Docker 镜像，Release 就是运行起来的 Docker 容器。同一个 Chart 可以被安装多次，每次安装都会生成一个新的 Release。

## 安装
https://helm.sh/zh/docs/intro/install
https://github.com/helm/helm/releases
```bash
~# wget https://get.helm.sh/helm-v4.0.4-linux-amd64.tar.gz
~# tar -zxvf helm-v4.0.4-linux-amd64.tar.gz
~# mv linux-amd64/helm /usr/local/bin/helm
~# rm -rf helm-* linux-amd64/
~# 
~# helm version
version.BuildInfo{Version:"v4.0.4", GitCommit:"8650e1dad9e6ae38b41f60b712af9218a0d8cc11", GitTreeState:"clean", GoVersion:"go1.25.5", KubeClientVersion:"v1.34"}
~# 
```

## 添加仓库
Helm 安装好后，默认是空的，我们需要添加一个仓库（Repository）才能下载应用。就像配置 yum 源一样，你需要告诉 Helm 去哪里找包。
```bash
# 添加 Bitnami 仓库（最常用的仓库之一）
~# helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" has been added to your repositories
~# 
# 更新本地缓存
~# helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
~# 
```
## 配置代理
```bash
~# helm search repo nginx			# 搜索相关的包
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION                                       
bitnami/nginx                           22.4.2          1.29.4          NGINX Open Source is a web server that can be a...
bitnami/nginx-ingress-controller        12.0.7          1.13.1          NGINX Ingress Controller is an Ingress controll...
bitnami/nginx-intel                     2.1.15          0.4.9           DEPRECATED NGINX Open Source for Intel is a lig...
~# helm install mycharts bitnami/nginx			# 格式: helm install [发布名称] [Chart名称]
Error: INSTALLATION FAILED: failed to perform "FetchReference" on source: Get "https://registry-1.docker.io/v2/bitnamicharts/nginx/manifests/22.4.2": dial tcp 199.96.59.61:443: i/o timeout
~# 
# 这种方法会让当前用户所有的工具（如 curl, wget, docker, helm）默认都走代理。
~# echo "# 开启 HTTP 和 HTTPS 代理
export http_proxy=http://192.168.x.x:7890
export https_proxy=http://192.168.x.x:7890
# 必须把 localhost、本地回环网段、K8s 的 ClusterIP 网段、以及你服务器的内网 IP 加上
# 否则 Helm 可能会尝试通过代理去连你的 K8s API Server，导致连接集群失败！
export no_proxy=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.svc,.cluster.local" >> ~/.bashrc 
~# 
~# source ~/.bashrc
```
## 使用 Chart
### 安装
```bash
~# helm install mycharts bitnami/nginx
NAME: mycharts
LAST DEPLOYED: Sun Jan 11 19:43:27 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
NOTES:
CHART NAME: nginx
CHART VERSION: 22.4.2
APP VERSION: 1.29.4

⚠ WARNING: Since August 28th, 2025, only a limited subset of images/charts are available for free.
    Subscribe to Bitnami Secure Images to receive continued support and security updates.
    More info at https://bitnami.com and https://github.com/bitnami/containers/issues/83267

** Please be patient while the chart is being deployed **
NGINX can be accessed through the following DNS name from within your cluster:

    mycharts-nginx.default.svc.cluster.local (port 80)

To access NGINX from outside the cluster, follow the steps below:

1. Get the NGINX URL by running these commands:

  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        Watch the status with: 'kubectl get svc --namespace default -w mycharts-nginx'

    export SERVICE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].port}" services mycharts-nginx)
    export SERVICE_IP=$(kubectl get svc --namespace default mycharts-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo "http://${SERVICE_IP}:${SERVICE_PORT}"
WARNING: Rolling tag detected (bitnami/nginx:latest), please note that it is strongly recommended to avoid using rolling tags in a production environment.
+info https://techdocs.broadcom.com/us/en/vmware-tanzu/application-catalog/tanzu-application-catalog/services/tac-doc/apps-tutorials-understand-rolling-tags-containers-index.html
WARNING: Rolling tag detected (bitnami/git:latest), please note that it is strongly recommended to avoid using rolling tags in a production environment.
+info https://techdocs.broadcom.com/us/en/vmware-tanzu/application-catalog/tanzu-application-catalog/services/tac-doc/apps-tutorials-understand-rolling-tags-containers-index.html
WARNING: Rolling tag detected (bitnami/nginx-exporter:latest), please note that it is strongly recommended to avoid using rolling tags in a production environment.
+info https://techdocs.broadcom.com/us/en/vmware-tanzu/application-catalog/tanzu-application-catalog/services/tac-doc/apps-tutorials-understand-rolling-tags-containers-index.html

WARNING: There are "resources" sections in the chart not set. Using "resourcesPreset" is not recommended for production. For production installations, please set the following values according to your workload needs:
  - cloneStaticSiteFromGit.gitSync.resources
  - resources
+info https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
~# 
~# helm list			# 查看当前安装了哪些应用
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
mycharts        default         1               2026-01-11 19:43:27.621857325 +0800 CST deployed        nginx-22.4.2    1.29.4     
~# 
~# kubectl get all -l app.kubernetes.io/instance=mycharts			# 查看带有 mycharts 标签的所有资源
NAME                                 READY   STATUS    RESTARTS   AGE
pod/mycharts-nginx-76787cd55-zgcrc   1/1     Running   0          13m

NAME                     TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
service/mycharts-nginx   LoadBalancer   10.96.205.198   192.168.0.242   80:32590/TCP,443:32458/TCP   13m

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mycharts-nginx   1/1     1            1           13m

NAME                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/mycharts-nginx-76787cd55   1         1         1       13m
~# 
```
### 更新
```bash
# 格式: helm upgrade [发布名称] [Chart名称] --set [参数名]=[新值]
~# helm upgrade mycharts bitnami/nginx --set service.type=NodePort
Release "mycharts" has been upgraded. Happy Helming!
NAME: mycharts
LAST DEPLOYED: Sun Jan 11 20:21:19 2026
NAMESPACE: default
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
TEST SUITE: None
NOTES:
CHART NAME: nginx
CHART VERSION: 22.4.2
APP VERSION: 1.29.4
...
~# 
~# kubectl get svc | grep mycharts
mycharts-nginx   NodePort    10.96.205.198   <none>        80:32590/TCP,443:32458/TCP   38m
~# 
# --set 这种命令行参数的方式修改了配置，这对于改一个参数很方便。
# 但是，如果你要改 10 个参数呢？（比如同时改镜像版本、改端口、改密码...） 敲一行几百字长的命令?而且也没法保存记录呀！！？
# 接下来,使用 values.yaml 文件来管理配置。
~# cat my-values.yaml
# 1. 把副本数改成 2，实现高可用
replicaCount: 2

# 2. 固定端口号，不再随机生成
service:
  type: NodePort
  nodePorts:
    http: 30008

# 3. 注入自定义 Nginx 配置，修改返回内容
# 注意：这会覆盖默认的 nginx.conf server 部分
serverBlock: |-
  server {
    listen 8080;
    location / {
      default_type text/html;
      return 200 "<h1>Hello! I learned Helm today! 🚀</h1>\n";
    }
  }
~# 
~# helm upgrade mycharts bitnami/nginx -f my-values.yaml			# -f 参数指定我们的配置文件
Release "mycharts" has been upgraded. Happy Helming!
...
~# 
~# kubectl get pods -o wide 
NAME                              READY   STATUS    RESTARTS   AGE     IP              NODE    NOMINATED NODE   READINESS GATES
mycharts-nginx-57cf6ff4c6-stv5r   1/1     Running   0          2m42s   10.244.104.16   node2   <none>           <none>
mycharts-nginx-57cf6ff4c6-vpt2h   1/1     Running   0          2m53s   10.244.104.18   node2   <none>           <none>
~# 
```
### 回滚
```bash
~# helm history mycharts
REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION     
1               Sun Jan 11 19:43:27 2026        superseded      nginx-22.4.2    1.29.4          Install complete
2               Sun Jan 11 20:21:19 2026        superseded      nginx-22.4.2    1.29.4          Upgrade complete
3               Sun Jan 11 20:28:21 2026        deployed        nginx-22.4.2    1.29.4          Upgrade complete
~# 
~# helm rollback mycharts 1
Rollback was a success! Happy Helming!
~# 
~# helm history mycharts
REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION     
1               Sun Jan 11 19:43:27 2026        superseded      nginx-22.4.2    1.29.4          Install complete
2               Sun Jan 11 20:21:19 2026        superseded      nginx-22.4.2    1.29.4          Upgrade complete
3               Sun Jan 11 20:28:21 2026        superseded      nginx-22.4.2    1.29.4          Upgrade complete
4               Sun Jan 11 20:39:23 2026        deployed        nginx-22.4.2    1.29.4          Rollback to 1   
~# kubectl get pods -o wide
NAME                             READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
mycharts-nginx-76787cd55-lggdc   1/1     Running   0          35s   10.244.104.51   node2   <none>           <none>
~# kubectl get svc | grep mycharts
mycharts-nginx   LoadBalancer   10.96.205.198   192.168.0.242   80:30008/TCP,443:32458/TCP   56m
~# 
~# helm uninstall mycharts			# 彻底删除应用
release "mycharts" uninstalled
~# 
~# kubectl get pods -o wide 
No resources found in default namespace.
~# helm list
NAME    NAMESPACE       REVISION        UPDATED STATUS  CHART   APP VERSION
~# 
```
## 编写 Chart
```bash
~# helm create hello-helm
Creating hello-helm
~# tree hello-helm/
hello-helm/
├── Chart.yaml
├── charts
├── templates
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── hpa.yaml
│   ├── httproute.yaml
│   ├── ingress.yaml
│   ├── service.yaml
│   ├── serviceaccount.yaml
│   └── tests
│       └── test-connection.yaml
└── values.yaml

3 directories, 11 files
~# helm install test-run ./hello-helm/ --debug --dry-run
# --debug: 输出详细调试信息
# --dry-run: 演习模式，不真安装
level=WARN msg="--dry-run is deprecated and should be replaced with '--dry-run=client'"
level=DEBUG msg="Original chart version" version=""
level=DEBUG msg="Chart path" path=/root/hello-helm
level=DEBUG msg="number of dependencies in the chart" dependencies=0
NAME: test-run
LAST DEPLOYED: Tue Jan 13 02:55:32 2026
NAMESPACE: default
STATUS: pending-install
REVISION: 1
DESCRIPTION: Dry run complete
...
~# 
~# helm list
NAME    NAMESPACE       REVISION        UPDATED STATUS  CHART   APP VERSION
~# 
~# helm install mylocalchart ./hello-helm/
NAME: mylocalchart
LAST DEPLOYED: Tue Jan 13 03:00:50 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
...
~# 
~# kubectl get pods -o wide 
NAME                                       READY   STATUS    RESTARTS   AGE   IP              NODE    NOMINATED NODE   READINESS GATES
mylocalchart-hello-helm-5cc7577ffd-n57wn   1/1     Running   0          62s   10.244.104.30   node2   <none>           <none>
~# helm list
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
mylocalchart    default         1               2026-01-13 03:00:50.340761993 +0800 CST deployed        hello-helm-0.1.0        1.16.0     
~# kubectl get svc | grep mylocalchart
mylocalchart-hello-helm   ClusterIP   10.98.157.153   <none>        80/TCP         2m9s
~# vi ./hello-helm/values.yaml 
~# 
~# helm upgrade mylocalchart ./hello-helm/
Release "mylocalchart" has been upgraded. Happy Helming!
NAME: mylocalchart
LAST DEPLOYED: Tue Jan 13 03:05:14 2026
NAMESPACE: default
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
...
~# 
~# kubectl get svc | grep mylocalchart
mylocalchart-hello-helm   NodePort    10.98.157.153   <none>        80:32289/TCP   4m30s
~# 
```

### **通用 Chart 模板**
学会 `range`（循环）、`if`（判断）和 `include`（引用辅助模板）。
```bash
~# helm create my-app
Creating my-app
~# cd my-app/templates/
root@master ~/m/templates# rm -rf deployment.yaml service.yaml ingress.yaml hpa.yaml serviceaccount.yaml NOTES.txt httproute.yaml tests/
root@master ~/m/templates# ls
_helpers.tpl
# 为什么要留着 _helpers.tpl？ 这是一个工业级 Chart 的标配。它里面定义了如何生成规范的 Resource Name 和 Label。
# 工作中千万不要手写 Label，一定要引用 helper，否则升级时 Label 不匹配会导致 Deployment 重建失败。

~# cat my-app/values.yaml
# 基础信息
replicaCount: 2			# Pod 副本数
image:
  repository: nginx			# 镜像仓库名
  tag: "1.23"
  pullPolicy: IfNotPresent

# 环境变量 (工作中通常用来传数据库地址、开关等) -> 我们要学 range 循环
env:
  - name: APP_ENV
    value: "production"
  - name: DB_HOST
    value: "192.168.0.10"

# 资源限制 (生产环境必须有！)
# CPU 单位是 m，即 millicores，500m 是 0.5 个 CPU 核，内存单位是 Mi（Mebibyte）
resources:
  limits:			# 资源限制，超过限制会被限流或杀死
    cpu: 500m
    memory: 512Mi
  requests:			# 请求的资源量，保证 Pod 启动和运行的最小资源
    cpu: 100m
    memory: 128Mi

# 服务暴露
service:
  type: ClusterIP
  port: 80

# 域名配置 (开关控制) -> 我们要学 if 判断
ingress:
  enabled: true
  host: web.libix.com			# 绑定的域名
  
# 自定义配置文件 (我们要演示如何把这个注入到容器里)
appConfig:			# 没有魔法含义，只是一个自定义逻辑分组
  config.json: |			# | 表示：原样保留换行
# 生成一个文件 config.json ，内容如下：
    {
      "database": "mysql",
      "timeout": 5000,
      "features": ["new-ui", "fast-login"]
    }
~# 
~# cat my-app/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  # 通过调用 _helpers.tpl 中的 my-app.fullname 函数来生成规范的服务名称
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}			# nindent 是缩进函数，换行并缩进4个空格
spec:
  replicas: {{ .Values.replicaCount }}			# .Values 代表 values.yaml 中传入的参数
  selector:
    matchLabels:
      {{- include "my-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-app.selectorLabels" . | nindent 8 }}
    spec:
      # 声明卷来源
      # Kubernetes 在 Pod 里准备了一个“配置卷”，内容来自 my-app-config 这个 ConfigMap
      volumes:
        - name: config-volume
          configMap:
            name: {{ include "my-app.fullname" . }}-config
            
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          
          ### Range 循环
          # 自动遍历 values.yaml 里的 env 列表，生成 env 配置
          env:
            {{- range .Values.env }}
            - name: {{ .name }}
              value: {{ .value | quote }}			# quote 函数会给字符串加双引号
            {{- end }}

		  # 容器内挂载路径
          volumeMounts:
            - name: config-volume
              mountPath: /app/config

          ### 直接转录 YAML
          # toYaml 函数把 values 里的对象直接转成 YAML 格式，省去了一行行写的麻烦
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
~# 
~# cat my-app/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "my-app.selectorLabels" . | nindent 4 }}
~# 
~# cat my-app/templates/ingress.yaml
### If 条件判断
# 只有当 values.yaml 里 ingress.enabled 为 true 时，才生成下面这些代码
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  rules:
    - host: {{ .Values.ingress.host }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ include "my-app.fullname" . }}
                port:
                  number: {{ .Values.service.port }}
{{- end }}
~# 
~# cat my-app/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "my-app.fullname" . }}-config
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
data:
  # 这里不需要 range，直接把 values 里的整个对象转成 YAML 格式
  {{- toYaml .Values.appConfig | nindent 2 }}
~# 
# YAML 语法极其严格：严禁使用 Tab 键（制表符）进行缩进，只能使用空格
~# helm install my-app-test ./my-app/
NAME: my-app-test
LAST DEPLOYED: Tue Jan 13 20:59:08 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
~# 
~# kubectl get pods -o wide 
NAME                           READY   STATUS    RESTARTS   AGE     IP              NODE    NOMINATED NODE   READINESS GATES
my-app-test-75857f97f9-f6d7c   1/1     Running   0          5m13s   10.244.104.49   node2   <none>           <none>
my-app-test-75857f97f9-gj56x   1/1     Running   0          5m11s   10.244.104.54   node2   <none>           <none>
~# kubectl get svc | grep my
my-app-test   ClusterIP   10.96.107.187   <none>        80/TCP         111m
~# kubectl get ingress
NAME          CLASS    HOSTS           ADDRESS   PORTS   AGE
my-app-test   <none>   web.libix.com             80      111m
~# kubectl get configmap
NAME                 DATA   AGE
kube-root-ca.crt     1      24d
my-app-test-config   1      5m48s
~# 
~# kubectl exec my-app-test-75857f97f9-f6d7c -- cat /app/config/config.json			# 检验挂载 ConfigMap
{
  "database": "mysql",
  "timeout": 5000,
  "features": ["new-ui", "fast-login"]
}  
~# 
~# helm lint ./my-app			# 检查语法和最佳实践
==> Linting ./my-app
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
~# 
~# helm package ./my-app/			# 打包
Successfully packaged chart and saved it to: /root/my-app-0.1.0.tgz
~# vi my-app/Chart.yaml 
~# cat my-app/Chart.yaml | grep version
version: 0.2.0
~# helm package ./my-app/
Successfully packaged chart and saved it to: /root/my-app-0.2.0.tgz
~# 
```


## 依赖管理 (Dependencies)

想象一下，你的应用依赖 Redis 和 MySQL。如果没有 Helm 的依赖管理，你需要分别跑三个 `helm install` 命令，还要手动去查数据库的 Service IP 填给你的应用。有了依赖管理，你可以把 Redis 和 MySQL 定义为你 Chart 的**子 Chart**。 
效果： 用户只需一条命令 `helm install my-app`，Redis 和 MySQL 就会自动作为一个整体被安装起来，并且网络自动互通。

> **Redis** 是一个跑在内存里的超快 Key-Value 数据库，常用来当缓存。
>
> 部署在应用和数据库之间的中间件，缓存经常需要访问的数据到内存中，减少查找数据库的频率，用来抵抗高并发场景。

**模拟实战：构建 Umbrella Chart**

> Umbrella Chart = 一个“大 Helm Chart”，专门用来统一安装和管理多个子 Chart。

**任务目标：** 构建一个博客系统，它包含：

WordPress	（ WordPress Helm Chart 自带了一个 MariaDB 子 Chart 作为数据库依赖。）

统计服务     	 ( 模拟自研微服务 )

**一个 Chart** 安装，并且**共享配置**。

```bash
# 真实业务环境的 Helm Chart 里不会把数据库作为依赖，业务应用和数据库通常是分开管理和运维的两个系统
~# cat my-blog-stack/Chart.yaml 
apiVersion: v2
name: my-blog-stack
description: A Helm chart for Kubernetes
type: application
version: 0.1.0
appVersion: "1.16.0"
# 声明依赖
dependencies:
  - name: wordpress
    version: 28.1.2
    repository: https://charts.bitnami.com/bitnami

  # 注意：本地依赖不需要 repository，只需要 version
  - name: stats-service
    version: 0.1.0
    repository: file://./charts/stats-service
~# 
# 关闭持久化是为了你现在的环境能跑起来，生产环境这里肯定是开启的
~# 
helm install prod-db bitnami/mariadb \
  --set auth.rootPassword=ChinaSkill22! \
  --set auth.database=blog_data \
  --set primary.persistence.enabled=false
~# kubectl get pods -o wide 
NAME                READY   STATUS    RESTARTS   AGE    IP             NODE    NOMINATED NODE   READINESS GATES
prod-db-mariadb-0   1/1     Running   0          115s   10.244.104.8   node2   <none>           <none>
~# 

~# helm dependency build ./my-blog-stack/			# 从仓库下载子 Chart 放到本地 charts/ 目录
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 3 charts
Downloading wordpress from repo https://charts.bitnami.com/bitnami
Pulled: registry-1.docker.io/bitnamicharts/wordpress:28.1.2
Digest: sha256:0492a5fc75145b7f53acaff67a77e55588bdea15d60c4aeb820ab3523f2117de
Downloading mariadb from repo https://charts.bitnami.com/bitnami
Pulled: registry-1.docker.io/bitnamicharts/mariadb:24.0.3
Digest: sha256:88cec731463d9ee47d976ff7f6d450eb238bd7dd9d55898038dcaa6abf2830b0
Deleting outdated charts
~# ls my-blog-stack/charts/
mariadb-24.0.3.tgz  stats-service  stats-service-0.1.0.tgz  wordpress-28.1.2.tgz
~# 
~# sed -i '/^[[:space:]]*#/d' my-blog-stack/values.yaml 			# 删除所有以 # 开头的行
# ^：行首
# [[:space:]]*：允许前面有空格（YAML 很常见）
# -i：原地修改文件
~# cat <<'EOF' >> my-blog-stack/values.yaml 
> # 针对特定子 Chart 的配置
wordpress:
  service:
    type: NodePort
    nodePorts:
      http: 30080
  mariadb:
    enabled: false  		# 告诉 wordpress 子 Chart 不启用并使用同包内的 mariadb 服务
  persistence:
    enabled: false		# 关闭持久化，意味着数据库数据不会保存在持久卷（PV）上，而是存在 Pod 临时存储中，Pod 重启或删除后数据会丢失
  externalDatabase:
    host: prod-db-mariadb.default.svc.cluster.local			# 完全限定域名 FQDN
    user: root
    password: ChinaSkill22!
    database: blog_data
    port: 3306

stats-service:
  replicaCount: 1
> EOF
~# 
~# helm lint my-blog-stack/
==> Linting my-blog-stack/
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
~# 
~# helm install myblogstack ./my-blog-stack/
NAME: myblogstack
LAST DEPLOYED: Thu Jan 15 04:08:15 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
~# 
~# kubectl get pods -o wide 
NAME                                         READY   STATUS    RESTARTS   AGE     IP              NODE     NOMINATED NODE   READINESS GATES
myblogstack-stats-service-764d76b44f-8zn8w   1/1     Running   0          3m32s   10.244.104.15   node2    <none>           <none>
myblogstack-wordpress-57846d9bc7-4h569       1/1     Running   0          3m32s   10.244.104.13   node2    <none>           <none>
prod-db-mariadb-0                            1/1     Running   0          19m     10.244.104.8    node2    <none>           <none>
~# kubectl get svc
NAME                           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
kubernetes                     ClusterIP   10.96.0.1        <none>        443/TCP                      26d
myblogstack-stats-service      ClusterIP   10.101.50.245    <none>        80/TCP                       14m
myblogstack-wordpress          NodePort    10.110.110.145   <none>        80:30080/TCP,443:31655/TCP   14m
prod-db-mariadb                ClusterIP   10.104.23.78     <none>        3306/TCP                     30m
prod-db-mariadb-headless       ClusterIP   None             <none>        3306/TCP                     30m
~# 
# 打开浏览器访问10.110.110.145:30080/wp-admin ，用户 user
~# kubectl get secret --namespace default myblogstack-wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode
Qrw7XPRgcx~# 			# 密码：Qrw7XPRgcx
~# 
# 后续修复
# 漏洞 1：裸奔的密码
# 漏洞 2：数据“阅后即焚”
# 漏洞 3：资源无限制
# 漏洞 4：单点故障
# 漏洞 5：网络暴露太随意
# 漏洞 6：探针缺失
```



# 现象描述

## 集群节点资源占用不均衡

在当前的 Kubernetes 集群运行状态中，**node2** 节点的内存占用率（75%）显著高于 **node1** 节点（约 25%-30%）。经系统底层进程分析发现，资源消耗主要集中在 Kubernetes 基础设施组件及其 management 进程上，其中 kubelet、calico-typha 和 operator 为主要内存占用源。

技术分析：为什么 node2 占用更高？

*   **管理组件的集中调度**：
    Kubernetes 调度器会将集群级别的单副本或多副本管理组件（如 Calico 网络插件的 typha 中继进程和 operator 管理进程）分配到特定的 Worker 节点。在您的集群中，这些高负载的“基建”组件恰好都被调度到了 node2。
*   **Kubelet 的线性开销**：
    kubelet 进程的内存占用与它所管理的容器数量成正比。由于 node2 运行了更多的系统级容器（Typha, Operator 等），其 kubelet 需要维护更多的对象缓存和状态监控，导致其自身内存占用（约 748MB）远高于基础节点。
*   **小内存环境的放大效应**：
    由于您的虚拟机仅分配了 2GB 物理内存，属于 K8s 运行的底线配置。这些额外的基建组件多占用的 300-500MB 内存，在 2GB 的基数下，表现为百分比上涨了近 25% - 40%，造成了视觉上的巨大差异。

**运维结论：** **此现象属于 Kubernetes 集群运行中的正常状态，而非系统故障。**

Kubernetes 的设计哲学是“以集群为中心”，调度器会平衡业务 Pod，但对于系统基础组件，通常会分散或随机分布。node2 目前承担了更多的集群管理职责（类似“值班经理”），因此资源占用更高。只要内存占用未触发 MemoryPressure（通常高于 85%-90%）导致 Pod 频繁重启，该状态即为健康。

## **关于 RFC 1123 的命名规范**

在 Kubernetes 的世界里，几乎所有的资源名称、卷名称、容器名称都必须遵循严格的**小写字母**准则。

```bash
~# kubectl apply -f dep-test.yaml
The Deployment "dep-test" is invalid: 
* spec.template.spec.volumes[0].name: Invalid value: "vol-CM": a lowercase RFC 1123 label must consist of lower case alphanumeric characters or '-', and must start and end with an alphanumeric character (e.g. 'my-name',  or '123-abc', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?')
* spec.template.spec.containers[0].volumeMounts[0].name: Not found: "vol-CM"
~# 
```
