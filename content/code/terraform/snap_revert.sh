#!/bin/bash
# 用法: ./snap-revert.sh <快照名>
VM1=kmaster
VM2=knode1
VM3=knode2
SNAP_NAME=$1
echo "正在将所有节点回滚到: $SNAP_NAME ..."
# 必须要先关机才能安全恢复状态 (或者使用 --force)
sudo virsh destroy $VM1
sudo virsh destroy $VM2
sudo virsh destroy $VM3

sudo virsh snapshot-revert --domain $VM1 --snapshotname $SNAP_NAME --running
sudo virsh snapshot-revert --domain $VM2 --snapshotname $SNAP_NAME --running
sudo virsh snapshot-revert --domain $VM3 --snapshotname $SNAP_NAME --running
echo "读档完成！集群已复活。"
