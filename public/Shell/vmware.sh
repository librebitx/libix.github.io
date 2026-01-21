#!/bin/bash

DISK="/dev/nvme0n1p1"
MOUNTPATH="/media/libix"

# mountpoint 是最稳妥的方式
if mountpoint -q "${MOUNTPATH}"; then
    echo "磁盘已挂载 ${DISK} → ${MOUNTPATH}"
else
    echo "未检测到挂载，正在尝试挂载 ${DISK} → ${MOUNTPATH} ..."
    sudo mount "${DISK}" "${MOUNTPATH}"

    if mountpoint -q "${MOUNTPATH}"; then
        echo "挂载成功。"
    else
        echo "挂载失败，脚本终止。"
        exit 1
    fi
fi

echo "请选择一个操作："

options=("ChinaSkills" "Windows 10" "K8s" "Myblogsite" "Close All")

select opt in "${options[@]}"
do
    case $opt in      

# ------------------------------------------------------------------------  
        "ChinaSkills")
# 根据虚拟机数量添加        
VM_1="appsrv"
VM_2="storagesrv"
VM_3="routersrv"
VM_4="insidecli"
#VM_5=""

VM_FILE_PATH="/media/libix/Storage/ChinaSkills"

VM_1_PATH="${VM_FILE_PATH}/${VM_1}/${VM_1}.vmx"
VM_2_PATH="${VM_FILE_PATH}/${VM_2}/${VM_2}.vmx"
VM_3_PATH="${VM_FILE_PATH}/${VM_3}/${VM_3}.vmx"
VM_4_PATH="${VM_FILE_PATH}/${VM_4}/${VM_4}.vmx"
#VM_5_PATH="${VM_FILE_PATH}/${VM_5}/${VM_5}.vmx"

VMRUN_CMD="vmrun"

echo "正在启动 ${VM_1}: ${VM_1_PATH}"

# vmrun -T ws start /home/user/vmware/VM1/VM1.vmx
"${VMRUN_CMD}" -T ws start "${VM_1_PATH}"

# 检查上一个命令是否成功
if [ $? -eq 0 ]; then
    echo "${VM_1} 启动成功。"
else
    echo "${VM_1} 启动失败。"
fi

echo "正在启动 ${VM_2}: ${VM_2_PATH}"
"${VMRUN_CMD}" -T ws start "${VM_2_PATH}"

if [ $? -eq 0 ]; then
    echo "${VM_2} 启动成功。"
else
    echo "${VM_2} 启动失败。"
fi

echo "正在启动 ${VM_3}: ${VM_3_PATH}"
"${VMRUN_CMD}" -T ws start "${VM_3_PATH}"

if [ $? -eq 0 ]; then
    echo "${VM_3} 启动成功。"
else
    echo "${VM_3} 启动失败。"
fi

echo "正在启动 ${VM_4}: ${VM_4_PATH}"
"${VMRUN_CMD}" -T ws start "${VM_4_PATH}"

if [ $? -eq 0 ]; then
    echo "${VM_4} 启动成功。"
else
    echo "${VM_4} 启动失败。"
fi

echo "所有虚拟机启动命令已发送。"
            break
            ;;
# ------------------------------------------------------------------------            
        "Windows 10")
VM="Windows 10 x64"

VM_FILE_PATH="/media/libix/Storage"

VM_PATH="${VM_FILE_PATH}/${VM}/${VM}.vmx"

VMRUN_CMD="vmrun"

echo "正在启动 ${VM}: ${VM_PATH}"

"${VMRUN_CMD}" -T ws start "${VM_PATH}"

if [ $? -eq 0 ]; then
    echo "${VM} 启动成功。"
else
    echo "${VM} 启动失败。"
fi
            break          
            ;;
# ------------------------------------------------------------------------
        "K8s")
VM_1="master"
VM_2="node1"
VM_3="node2"
#VM_4="insidecli"
#VM_5=""

VM_FILE_PATH="/media/libix/K8s"

VM_1_PATH="${VM_FILE_PATH}/${VM_1}/${VM_1}.vmx"
VM_2_PATH="${VM_FILE_PATH}/${VM_2}/${VM_2}.vmx"
VM_3_PATH="${VM_FILE_PATH}/${VM_3}/${VM_3}.vmx"
#VM_4_PATH="${VM_FILE_PATH}/${VM_4}/${VM_4}.vmx"
#VM_5_PATH="${VM_FILE_PATH}/${VM_5}/${VM_5}.vmx"

VMRUN_CMD="vmrun"

echo "正在启动 ${VM_1}: ${VM_1_PATH}"

# vmrun -T ws start /home/user/vmware/VM1/VM1.vmx
"${VMRUN_CMD}" -T ws start "${VM_1_PATH}"

# 检查上一个命令是否成功
if [ $? -eq 0 ]; then
    echo "${VM_1} 启动成功。"
else
    echo "${VM_1} 启动失败。"
fi

echo "正在启动 ${VM_2}: ${VM_2_PATH}"
"${VMRUN_CMD}" -T ws start "${VM_2_PATH}"

if [ $? -eq 0 ]; then
    echo "${VM_2} 启动成功。"
else
    echo "${VM_2} 启动失败。"
fi

echo "正在启动 ${VM_3}: ${VM_3_PATH}"
"${VMRUN_CMD}" -T ws start "${VM_3_PATH}"

if [ $? -eq 0 ]; then
    echo "${VM_3} 启动成功。"
else
    echo "${VM_3} 启动失败。"
fi

echo "所有虚拟机启动命令已发送。"
            break
            ;;
# ------------------------------------------------------------------------             
        "Close All")

VMRUN_CMD="vmrun"

echo "正在获取所有运行中的虚拟机列表..."

# sed '1d' 用于过滤掉输出的第一行 "Total running VMs: x"

RUNNING_VMS=$("${VMRUN_CMD}" list | sed '1d')

if [ -z "${RUNNING_VMS}" ]; then
    echo "当前没有虚拟机在运行。"
    exit 0
fi

echo "以下正在运行的虚拟机："
echo "${RUNNING_VMS}"
echo "------------------------------"

# 循环遍历每个虚拟机的 .vmx 路径并执行停止操作
IFS=$'\n' # 设置内部字段分隔符为换行符，以便正确处理包含空格的路径
for VMX_PATH in ${RUNNING_VMS}; do
    echo "正在尝试正常关机 VM: ${VMX_PATH}"    

    # stop 命令用于正常关机。如果想强制关闭（类似拔电源），请将 stop 替换为 stop VMX_PATH hard
    "${VMRUN_CMD}" -T ws stop "${VMX_PATH}"

    if [ $? -eq 0 ]; then
        echo "VM: ${VMX_PATH} 关机命令已发送。"
    else
        echo "VM: ${VMX_PATH} 关机失败或出现警告。可能需要手动强制停止。"
    fi
done

echo "------------------------------"
echo "所有运行中的虚拟机关机命令已发送完成。"
echo '------------------------------
## 克隆虚拟机（完整克隆）
vmrun -T ws clone ~/vm.vmx ~/vm.vmx full

## 创建链克隆（Linked Clone）
vmrun -T ws clone ~/vm.vmx ~/vm.vmx linked

# 创建快照（Snapshot）
vmrun snapshot /path/to/vm.vmx "快照名称"

## 查看快照列表
vmrun listSnapshots /path/to/vm.vmx

## 恢复快照（Revert）
vmrun revertToSnapshot /path/to/vm.vmx "快照名称"

## 删除快照
vmrun deleteSnapshot /path/to/vm.vmx "快照名称"
'
            break
            ;;
# ------------------------------------------------------------------------  
        "Myblogsite")
VM="Debian 12.12.0"

VM_FILE_PATH="/media/libix"

VM_PATH="${VM_FILE_PATH}/${VM}/${VM}.vmx"

VMRUN_CMD="vmrun"

echo "正在启动 ${VM}: ${VM_PATH}"

"${VMRUN_CMD}" -T ws start "${VM_PATH}"

if [ $? -eq 0 ]; then
    echo "${VM} 启动成功。"
else
    echo "${VM} 启动失败。"
fi
            break 
            ;;
# ------------------------------------------------------------------------              
        *)
            echo "无效选项 $REPLY"
            ;;
    esac
done

