#!/bin/bash

INTERVAL=5
NET_IF="wlo1"
TOP_N=10

read_cpu() {
    awk '/^cpu /{
        idle=$5
        for(i=2;i<=8;i++) total+=$i
        print idle, total
    }' /proc/stat
}

read_net() {
    awk -v i="$NET_IF" '$1 ~ i":" {print $2, $10}' /proc/net/dev
}

read_mem() {
    free -m | awk '/Mem:/ {print $2, $3}'
}

read -r prev_idle prev_total <<< "$(read_cpu)"
read -r rx_prev tx_prev <<< "$(read_net)"

while sleep "$INTERVAL"; do
    read -r idle total <<< "$(read_cpu)"
    read -r rx tx <<< "$(read_net)"
    read -r mem_total mem_used <<< "$(read_mem)"

    cpu=$((100 * ( (total-prev_total) - (idle-prev_idle) ) / (total-prev_total)))
    mem=$((100 * mem_used / mem_total))
    rx_rate=$(( (rx-rx_prev) / INTERVAL / 1024 ))
    tx_rate=$(( (tx-tx_prev) / INTERVAL / 1024 ))

    prev_idle=$idle
    prev_total=$total
    rx_prev=$rx
    tx_prev=$tx

    clear
    cat <<EOF
[System Monitor - $USER@$HOSTNAME]
Time: $(date)

CPU: ${cpu}%
Mem: ${mem}% (${mem_used}MB / ${mem_total}MB)

$NET_IF
↓ ${rx_rate} KB/s
↑ ${tx_rate} KB/s

PID        Program             Memory(MB)
------------------------------------------
EOF

    ps -eo rss,pid,comm --no-headers | awk '
    {
        mem[$3]+=$1
        if ($1 > max[$3]) { max[$3]=$1; pid[$3]=$2 }
    }
    END {
        for (p in mem)
            printf "%-10d %-20s %.1f\n", pid[p], p, mem[p]/1024
    }' | sort -k3 -nr | head -n "$TOP_N"

done
