#!/bin/bash

DATE=$(LC_TIME=en_US.UTF-8 date '+%m/%d %a %H:%M:%S')
BAT=$(acpi -b 2>/dev/null | awk -F, '{print $2}' | tr -d ' ' || echo "N/A")
UPTIME=$(uptime -p | sed 's/up //; s/ days,/d/; s/ hours,/h/; s/ minutes/m/')

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

CPU_S1=$(grep 'cpu ' /proc/stat)
RX1=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX1=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

sleep 0.2

CPU_S2=$(grep 'cpu ' /proc/stat)
RX2=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX2=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

CPU1=($CPU_S1)
CPU2=($CPU_S2)
IDLE1=${CPU1[4]}; TOTAL1=0
for val in "${CPU1[@]:1}"; do TOTAL1=$((TOTAL1 + val)); done
IDLE2=${CPU2[4]}; TOTAL2=0
for val in "${CPU2[@]:1}"; do TOTAL2=$((TOTAL2 + val)); done

DIFF_TOTAL=$((TOTAL2 - TOTAL1))
DIFF_IDLE=$((IDLE2 - IDLE1))

if [ "$DIFF_TOTAL" -eq 0 ]; then CPU_USAGE=0; else
    CPU_USAGE=$((100 * (DIFF_TOTAL - DIFF_IDLE) / DIFF_TOTAL))
fi

RX_SPEED=$(awk "BEGIN {printf \"%.0f\", ($RX2 - $RX1) / 1024 / 0.2}")
TX_SPEED=$(awk "BEGIN {printf \"%.0f\", ($TX2 - $TX1) / 1024 / 0.2}")

read -r mem_total_kb mem_avail_kb <<<$(awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} END {print t, a}' /proc/meminfo)
mem_used_kb=$((mem_total_kb - mem_avail_kb))
mem_usage=$((100 * mem_used_kb / mem_total_kb))

STATUS_TEXT=" $DATE  $BAT  CPU: ${CPU_USAGE}%  Mem: ${mem_usage}%  ${TX_SPEED}KB/s  ${RX_SPEED}KB/s  Uptime: $UPTIME "

notify-send -u normal -t 4000 \
    -h string:x-dunst-stack-tag:sysinfo \
    "$STATUS_TEXT"
