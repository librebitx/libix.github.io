#!/bin/bash
set -e

GATEWAY="192.168.0.1"
DNS1="192.168.1.1"
DNS2="192.168.0.1"
PREFIX="24"

declare -A CLUSTER_MAP
CLUSTER_MAP["kmaster"]="192.168.0.10"
CLUSTER_MAP["knode1"]="192.168.0.11"
CLUSTER_MAP["knode2"]="192.168.0.12"
CLUSTER_MAP["storage-node"]="192.168.0.20"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}错误: 请使用 root 权限运行此脚本${NC}"
   exit 1
fi

echo -e "${YELLOW}>>> 当前脚本已预定义以下节点配置：${NC}"
for name in "${!CLUSTER_MAP[@]}"; do
    echo -e " - ${GREEN}$name${NC} \t(IP: ${CLUSTER_MAP[$name]})"
done
echo "----------------------------------------"

while true; do
    read -p "请输入当前机器的角色名称 (例如 kmaster): " TARGET_NAME
    
    if [[ -v CLUSTER_MAP["$TARGET_NAME"] ]]; then
        TARGET_IP=${CLUSTER_MAP["$TARGET_NAME"]}
        echo -e "已选中: ${GREEN}$TARGET_NAME${NC} -> 将配置 IP 为: ${YELLOW}$TARGET_IP${NC}"
        read -p "确认继续吗? [y/N]: " CONFIRM
        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
            break
        fi
    else
        echo -e "${RED}错误: 输入的主机名 '$TARGET_NAME' 不在预定义列表中，请重试。${NC}"
    fi
done

IFACE=$(ip -o link show | awk -F': ' '$2 != "lo" && $2 !~ /docker|veth|cni|virbr|cali|flannel/ {print $2; exit}')

if [ -z "$IFACE" ]; then
    echo -e "${RED}未检测到物理网卡！${NC}"
    exit 1
fi
echo -e "使用网卡接口: ${GREEN}$IFACE${NC}"


echo "设置系统主机名..."
hostnamectl set-hostname "$TARGET_NAME"
echo "$TARGET_NAME" > /etc/hostname


if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "无法检测系统版本"
    exit 1
fi

echo -e "检测到系统: $ID, 正在写入网络配置..."

case $ID in
    ubuntu|debian)

        mkdir -p /etc/netplan/backup
        mv /etc/netplan/*.yaml /etc/netplan/backup/ 2>/dev/null || true
        
        cat <<EOF > /etc/netplan/01-static.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $IFACE:
      dhcp4: no
      addresses:
        - $TARGET_IP/$PREFIX
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses: [$DNS1, $DNS2]
EOF
        chmod 600 /etc/netplan/01-static.yaml
        netplan apply
        echo -e "${GREEN}Netplan 配置已生效${NC}"
        ;;

    centos|rhel|rocky|almalinux)

        systemctl start NetworkManager
        nmcli con mod "$IFACE" ipv4.addresses "$TARGET_IP/$PREFIX"
        nmcli con mod "$IFACE" ipv4.gateway "$GATEWAY"
        nmcli con mod "$IFACE" ipv4.dns "$DNS1 $DNS2"
        nmcli con mod "$IFACE" ipv4.method manual
        nmcli con mod "$IFACE" connection.autoconnect yes
        
        nmcli con down "$IFACE" && nmcli con up "$IFACE"
        echo -e "${GREEN}nmcli 配置已生效${NC}"
        ;;
    *)
        echo -e "${RED}不支持的系统: $ID${NC}"
        exit 1
        ;;
esac


echo "正在更新 /etc/hosts ..."
cp /etc/hosts /etc/hosts.bak

# 清理列表，防止重复定义
sed -i '/127.0.1.1/d' /etc/hosts
sed -i '/# K8s-Cluster-Nodes/d' /etc/hosts

for name in "${!CLUSTER_MAP[@]}"; do
    ip=${CLUSTER_MAP[$name]}
    sed -i "/$ip/d" /etc/hosts
done

sed -i "1i 127.0.1.1\t$TARGET_NAME" /etc/hosts

echo -e "\n# K8s-Cluster-Nodes" >> /etc/hosts
for name in "${!CLUSTER_MAP[@]}"; do
    echo -e "${CLUSTER_MAP[$name]}\t$name" >> /etc/hosts
done

echo -e "${GREEN}>>> 配置完成！${NC}"
echo -e "当前节点: $TARGET_NAME ($TARGET_IP)"
echo -e "Hosts 文件已包含集群内 ${#CLUSTER_MAP[@]} 个节点记录。"
