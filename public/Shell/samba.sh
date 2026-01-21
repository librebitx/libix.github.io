#!/bin/bash

SERVER="192.168.0.100"
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

ssh root@$SERVER

echo "-- Close the 'Files' window !!! --"
echo 3 ; sleep 1 ;echo 2 ;sleep 1 ;echo 1;sleep 1;
sudo umount "//$SERVER/fun" "$MNT_FUN"
sudo umount "//$SERVER/resource" "$MNT_RES"
 
ssh root@$SERVER
echo "
-------------------------------------------------------------------------------------------------------------------------------------------
smbclient -L 192.168.1.100 -U libix%redhat --option='client min protocol=SMB2' --option='client max protocol=SMB3'		
																
sudo mount -t cifs //192.168.1.100/fun /home/libix/192.168.1.100/fun -o username=libix,password=redhat,vers=3.0,uid=1000,gid=1000
sudo mount -t cifs //192.168.1.100/resource /home/libix/192.168.1.100/fun -o username=libix,password=redhat,vers=3.0,uid=1000,gid=1000
																					
sudo umount //192.168.1.100/fun /home/libix/192.168.1.100/fun
sudo umount //192.168.1.100/resource /home/libix/192.168.1.100/resource
------------------------------------------------------------------------------------------------------------------------------------------"

echo "Samba off"
