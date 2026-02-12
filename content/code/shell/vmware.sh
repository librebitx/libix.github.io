#!/bin/bash
# Script for managing VMware Workstation VMs on a specific mounted disk

# --- Configuration ---
DISK="/dev/nvme0n1p1"
MOUNTPATH="/media/libix"
VMRUN_CMD="vmrun" # Assuming vmrun is in your PATH, e.g., /usr/bin/vmrun

# Enable strict mode for better error handling
set -euo pipefail

# --- Functions ---

# Function to start a single VM
# Arguments: VM_NAME, VMX_PATH, [GUI_MODE] (default: nogui for server-like VMs)
start_vm() {
    local vm_name="$1"
    local vmx_path="$2"
    local gui_mode="${3:-nogui}" # Default to nogui if not specified

    echo "正在启动 ${vm_name}: ${vmx_path}"

    # Check if the VMX file exists
    if [[ ! -f "${vmx_path}" ]]; then
        echo "错误：VMX 文件不存在 → ${vmx_path}"
        return 1
    fi

    # Check if the VM is already running (optional, uncomment if needed)
    # if "${VMRUN_CMD}" list | grep -q "${vmx_path}"; then
    #     echo "${vm_name} 已在运行中。"
    #     return 0
    # fi

    if [[ "${gui_mode}" == "nogui" ]]; then
        "${VMRUN_CMD}" -T ws start "${vmx_path}" nogui
    else
        "${VMRUN_CMD}" -T ws start "${vmx_path}"
    fi

    if [ $? -eq 0 ]; then
        echo "${vm_name} 启动命令已发送。"
    else
        echo "警告：${vm_name} 启动失败或出现错误。请检查VMware日志或手动启动。"
    fi
    return 0
}

# Function to stop a single VM
# Arguments: VMX_PATH, [FORCE_STOP] (default: graceful shutdown)
stop_vm() {
    local vmx_path="$1"
    local force_stop="${2:-no}" # Default to graceful shutdown

    echo "正在尝试关机 VM: ${vmx_path}"

    local stop_command=("${VMRUN_CMD}" -T ws stop "${vmx_path}")
    if [[ "${force_stop}" == "hard" ]]; then
        stop_command+=("hard") # Add 'hard' for force power off
    fi

    if "${stop_command[@]}"; then
        echo "VM: ${vmx_path} 关机命令已发送。"
    else
        echo "警告：VM: ${vmx_path} 关机失败或出现错误。可能需要手动检查或尝试强制关机。"
    fi
}

# --- Main Script Logic ---

echo "--- 虚拟机管理脚本 ---"

# --- Disk Mounting Check ---
echo "检查磁盘挂载情况..."
if ! mountpoint -q "${MOUNTPATH}"; then
    echo "未检测到挂载，正在尝试挂载 ${DISK} → ${MOUNTPATH} ..."
    # Attempt mount, requiring sudo. User might be prompted for password.
    if ! sudo mount "${DISK}" "${MOUNTPATH}"; then
        echo "错误：挂载失败！请检查以下问题并重试："
        echo "1. ${DISK} 是否存在且未损坏？"
        echo "2. ${MOUNTPATH} 目录是否存在？ (请手动创建: sudo mkdir -p ${MOUNTPATH})"
        echo "3. 是否有挂载权限？（可能需要配置 /etc/fstab 以便自动挂载，或配置 sudoers 文件允许当前用户无需密码挂载）"
        exit 1
    fi
    echo "挂载成功。"
fi
echo "磁盘已挂载 ${DISK} → ${MOUNTPATH}"
echo "------------------------------"

# --- Main Menu ---
echo "请选择一个操作："

options=("ChinaSkills" "Windows 10" "K8s" "Myblogsite" "Close All" "Exit")

select opt in "${options[@]}"
do
    case $opt in      
        "ChinaSkills")
            VM_BASE_PATH="${MOUNTPATH}/Storage/ChinaSkills"
            echo "------------------------------"
            echo "正在启动 ChinaSkills 虚拟机组..."
            start_vm "appsrv" "${VM_BASE_PATH}/appsrv/appsrv.vmx"
            start_vm "storagesrv" "${VM_BASE_PATH}/storagesrv/storagesrv.vmx"
            start_vm "routersrv" "${VM_BASE_PATH}/routersrv/routersrv.vmx"
            start_vm "insidecli" "${VM_BASE_PATH}/insidecli/insidecli.vmx"
            echo "所有 ChinaSkills 虚拟机启动命令已发送。"
            echo "------------------------------"
            break
            ;;
            
        "Windows 10")
            VM_BASE_PATH="${MOUNTPATH}/Storage"
            echo "------------------------------"
            # For a desktop OS, you might want a GUI
            start_vm "Windows 10 x64" "${VM_BASE_PATH}/Windows 10 x64/Windows 10 x64.vmx" "gui"
            echo "------------------------------"
            break          
            ;;
            
        "K8s")
            VM_BASE_PATH="${MOUNTPATH}/K8s"
            echo "------------------------------"
            echo "正在启动 K8s 虚拟机组..."
            start_vm "master" "${VM_BASE_PATH}/master/master.vmx"
            start_vm "node1" "${VM_BASE_PATH}/node1/node1.vmx"
            start_vm "node2" "${VM_BASE_PATH}/node2/node2.vmx"
            echo "所有 K8s 虚拟机启动命令已发送。"
            echo "------------------------------"
            break
            ;;
             
        "Myblogsite")
            # Assuming Myblogsite VM is directly under MOUNTPATH
            VM_BASE_PATH="${MOUNTPATH}" 
            echo "------------------------------"
            start_vm "Debian 12.12.0" "${VM_BASE_PATH}/Debian 12.12.0/Debian 12.12.0.vmx"
            echo "------------------------------"
            break 
            ;;
            
        "Close All")
            echo "------------------------------"
            echo "正在获取所有运行中的虚拟机列表..."
            # sed '1d' 用于过滤掉输出的第一行 "Total running VMs: x"
            RUNNING_VMS=$("${VMRUN_CMD}" list | sed '1d' || true) # `|| true` to prevent `set -e` from exiting if no VMs are running

            if [ -z "${RUNNING_VMS}" ]; then
                echo "当前没有虚拟机在运行。"
            else
                echo "以下正在运行的虚拟机将被关机："
                echo "${RUNNING_VMS}"
                echo "------------------------------"

                IFS=$'\n' # 设置内部字段分隔符为换行符，以便正确处理包含空格的路径
                for VMX_PATH in ${RUNNING_VMS}; do
                    stop_vm "${VMX_PATH}"
                done
                echo "------------------------------"
                echo "所有运行中的虚拟机关机命令已发送完成。"
            fi

            echo -e '\n--- vmrun 常用命令参考 ---'
            echo '## 克隆虚拟机（完整克隆）'
            echo 'vmrun -T ws clone /path/to/source.vmx /path/to/new.vmx full'
            echo '## 创建链克隆（Linked Clone）'
            echo 'vmrun -T ws clone /path/to/source.vmx /path/to/new.vmx linked'
            echo '# 创建快照（Snapshot）'
            echo 'vmrun snapshot /path/to/vm.vmx "快照名称"'
            echo '## 查看快照列表'
            echo 'vmrun listSnapshots /path/to/vm.vmx'
            echo '## 恢复快照（Revert）'
            echo 'vmrun revertToSnapshot /path/to/vm.vmx "快照名称"'
            echo '## 删除快照'
            echo 'vmrun deleteSnapshot /path/to/vm.vmx "快照名称"'
            echo "------------------------------"
            break
            ;;

        "Exit")
            echo "脚本退出。"
            break
            ;;
            
        *)
            echo "无效选项 $REPLY"
            ;;
    esac
done

exit 0
