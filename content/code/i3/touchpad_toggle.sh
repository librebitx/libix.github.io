#!/bin/bash

# 定义触控板
ID="SYNA32EC:00 06CB:CEE7 Touchpad"

# 获取当前的启用状态 (1 为开启, 0 为关闭)
STATUS=$(xinput list-props "$ID" | grep "Device Enabled" | awk '{print $NF}')

if [ "$STATUS" -eq 1 ]; then
    xinput disable "$ID"
    dunstify -u low -i input-touchpad-symbolic "Touchpad" "Disabled"
else
    xinput enable "$ID"
    dunstify -u low -i input-touchpad-symbolic "Touchpad" "Enabled"
fi
