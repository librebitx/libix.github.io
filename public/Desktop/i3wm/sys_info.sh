#!/bin/bash

# === 获取数据 ===
DATE=$(LC_TIME=en_US.UTF-8 date '+%m/%d %a %H:%M:%S')
DISK=$(df -h / | awk 'NR==2 { print $5 }')
BAT=$(acpi -b | awk -F, '{print $2}' | tr -d ' ')
UPTIME=$(uptime -p | sed 's/up //; s/ days,/d/; s/ hours,/h/; s/ minutes/m/')

# ===== Load Average (1 min) =====
load=$(awk '{print $1}' /proc/loadavg)

# ===== Root FS Usage =====
read -r used total <<<$(df -kP / | awk 'NR==2 {print $3, $2}')
used_gb=$(awk "BEGIN {printf \"%.2f\", $used/1024/1024}")
total_gb=$(awk "BEGIN {printf \"%.2f\", $total/1024/1024}")
use_perc=$(awk "BEGIN {printf \"%.0f\", ($used/$total)*100}")

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

notify-send -u normal -t 5000 \
    -h string:x-dunst-stack-tag:sysinfo \
"$DATE
Battery: $BAT
Load: $load
Usage of / : ${use_perc}% ( ${used_gb}GB / ${total_gb}GB )
Memory usage: ${mem_usage}% ( ${mem_used_gb}GB / ${mem_total_gb}GB )
$UPTIME
"
