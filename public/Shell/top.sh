#!/bin/bash

INTERVAL=4
BAT_PATH="/sys/class/power_supply/BAT0"
# 输入要监控的网卡名称
NET_IF="wlo1"
#NET_IF="enx002432238a18"

read_cpu() {
  awk '/^cpu / {
    for(i=2;i<=8;i++) sum+=$i;
    print $5, sum
  }' /proc/stat
}

get_battery_capacity() {
  if [ ! -d "$BAT_PATH" ]; then
    echo "无电池"
    return
  fi
  if [ -f "$BAT_PATH/capacity" ]; then
    cat "$BAT_PATH/capacity"
    return
  fi
  energy_now=$(cat "$BAT_PATH/energy_now" 2>/dev/null)
  energy_full=$(cat "$BAT_PATH/energy_full" 2>/dev/null)
  charge_now=$(cat "$BAT_PATH/charge_now" 2>/dev/null)
  charge_full=$(cat "$BAT_PATH/charge_full" 2>/dev/null)

  if [[ -n "$energy_now" && -n "$energy_full" && "$energy_full" -ne 0 ]]; then
    echo $(( 100 * energy_now / energy_full ))
  elif [[ -n "$charge_now" && -n "$charge_full" && "$charge_full" -ne 0 ]]; then
    echo $(( 100 * charge_now / charge_full ))
  else
    echo "未知"
  fi
}

get_battery_status() {
  if [ -d "$BAT_PATH" ] && [ -f "$BAT_PATH/status" ]; then
    cat "$BAT_PATH/status"
  else
    echo "无"
  fi
}



get_bytes() {
  awk -v iface="$NET_IF" '$0 ~ iface":" {print $2, $10}' /proc/net/dev
}

get_gpu_usage() {
  gpu_info=$(lspci | grep -i 'vga\|3d\|display')

  if command -v nvidia-smi >/dev/null 2>&1; then
    usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null)
    mem_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null)
    mem_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null)
    temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null)
    echo "使用率: ${usage}% | 显存 ${mem_used}/${mem_total} MiB | 温度 ${temp}°C"
    return
  fi

  if [ -f /sys/class/drm/card0/device/gpu_busy_percent ]; then
    usage=$(cat /sys/class/drm/card0/device/gpu_busy_percent)
    echo "使用率: ${usage}%"
    return
  fi

  if [ -d /sys/class/drm/card0 ] && lsmod | grep -q i915; then
    if [ -f /sys/class/drm/card0/gt/cur_freq ]; then
      cur=$(cat /sys/class/drm/card0/gt/cur_freq)
      max=$(cat /sys/class/drm/card0/gt/max_freq)
      usage=$(( 100 * cur / max ))
      echo "使用率: ${usage}%"
      return
    fi
    echo "Intel GPU: 无法读取使用率"
    return
  fi

  if lspci | grep -i nvidia >/dev/null && lsmod | grep -q nouveau; then
    if [ -f /sys/class/drm/card0/device/clock ]; then
      freq=$(cat /sys/class/drm/card0/device/clock)
      echo "NVIDIA Nouveau: GPU 频率 ${freq} MHz（无负载数据）"
      return
    fi
  fi

  echo "未知 GPU 或不支持读取使用率"
}

read -r prev_idle prev_total <<< "$(read_cpu)"
read -r rx_prev tx_prev <<< "$(get_bytes)"

while true; do
  sleep $INTERVAL

  read -r idle total <<< "$(read_cpu)"
  idle_diff=$((idle - prev_idle))
  total_diff=$((total - prev_total))
  prev_idle=$idle
  prev_total=$total
  cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))

# 无论你系统是中文还是英文，free 都会输出英文关键字 Mem:
  mem_total=$(LC_ALL=C free -m | awk '/Mem:/ {print $2}')
  mem_used=$(LC_ALL=C free -m | awk '/Mem:/ {print $3}')
  mem_percent=$((100 * mem_used / mem_total))

  battery_capacity=$(get_battery_capacity)
  battery_status=$(get_battery_status)

  read -r rx tx <<< "$(get_bytes)"
  rx_rate=$(( (rx - rx_prev) / INTERVAL / 1024 ))
  tx_rate=$(( (tx - tx_prev) / INTERVAL / 1024 ))
  rx_prev=$rx
  tx_prev=$tx

  cpu_model=$(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo | sed 's/^ *//')

  clear
  echo "[System Monitor - $USER@$HOSTNAME]"
  echo "更新时间: $(date)"
  echo "CPU - $cpu_model | 使用率: ${cpu_usage}%"
  echo "GPU - $(lspci | awk '/VGA compatible controller/{sub(/.*: /,""); print; exit}') | $(get_gpu_usage)"
  echo "内存使用率: ${mem_percent}% (${mem_used}MB / ${mem_total}MB)"
  echo "网络接口: $NET_IF"
  echo "下载速度: ${rx_rate} KB/s"
  echo "上传速度: ${tx_rate} KB/s"
  echo "电池容量: ${battery_capacity}%"
  echo "电池状态: ${battery_status}"


TOP_N=10

echo ""
echo "PID        Program             Memory(MB)"
echo "----------------------------------------------"

ps -eo rss,pid,comm --no-headers | awk '
{
    mem[$3] += $1

    # 找出该程序“内存占用最大的那个进程 PID”
    if ($1 > rss_max[$3]) {
        rss_max[$3] = $1
        pid_max[$3] = $2
    }
}
END {
    for (app in mem) {
        printf "%-10d %-20s %.1f\n", pid_max[app], app, mem[app]/1024
    }
}' | sort -k3 -nr | head -n $TOP_N



done
