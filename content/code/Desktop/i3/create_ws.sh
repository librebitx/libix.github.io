#!/bin/bash

MAX_WS=$(i3-msg -t get_workspaces | jq '[.[].num] | max // 0')

NEXT_WS=$((MAX_WS + 1))

if [ "$NEXT_WS" -gt 10 ]; then
    notify-send -u critical -t 2000 \
        -h string:x-dunst-stack-tag:ws \
        "上限已达，最大只允许创建 10 个工作区"
    exit 1
fi

i3-msg workspace number "$NEXT_WS" > /dev/null

notify-send -u normal -t 800 \
    -h string:x-dunst-stack-tag:ws \
    "新建工作区 $NEXT_WS"
