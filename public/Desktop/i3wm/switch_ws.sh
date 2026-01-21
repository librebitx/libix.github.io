#!/bin/bash

# 1. 执行切换动作
i3-msg workspace "$1" > /dev/null

# 2. 稍微等一下 (0.1秒)，等待 i3 完成切换动作，否则可能获取到旧的桌面号
sleep 0.1

# 3. 使用 jq 精准提取当前聚焦 (focused=true) 的桌面号码 (num)
CURRENT_WS=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).num')

# 4. 如果获取到了，就发送通知
if [ -n "$CURRENT_WS" ]; then
    notify-send -t 800 -h string:x-dunst-stack-tag:ws "$CURRENT_WS"
else
    # 万一出错了（极少情况），显示个问号
    notify-send -t 800 -h string:x-dunst-stack-tag:ws "工作区 ?"
fi
