#!/bin/bash
# 用法: ./snap-save.sh <快照名>
VM1=kmaster
VM2=knode1
VM3=knode2
SNAP_NAME=$1
echo "正在为所有节点创建快照: $SNAP_NAME ..."
sudo virsh snapshot-create-as --domain $VM1 --name $SNAP_NAME --description "Terraform snapshot" --atomic
sudo virsh snapshot-create-as --domain $VM2 --name $SNAP_NAME --description "Terraform snapshot" --atomic
sudo virsh snapshot-create-as --domain $VM3 --name $SNAP_NAME --description "Terraform snapshot" --atomic
echo "存档完成！"
