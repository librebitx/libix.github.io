#!/bin/bash

# 1. 获取当前最大的桌面号
MAX_WS=$(i3-msg -t get_workspaces | tr , '\n' | grep '"num":' | cut -d : -f 2 | sort -rn | head -1)

# 2. 如果获取失败，默认设为 0
if [ -z "$MAX_WS" ]; then
    MAX_WS=0
fi

# 3. 计算下一个号码
NEXT_WS=$((MAX_WS + 1))

# 4. === 限制逻辑：如果大于 10，则不创建 ===
if [ "$NEXT_WS" -gt 10 ]; then
    # 发送一条紧急通知（红色图标或 critical 级别）
    notify-send -u critical -t 2000 -h string:x-dunst-stack-tag:ws "🚫 上限已达！" "最大只允许创建 10 个工作区"
    exit 1
fi

# 5. 没超过 10，正常切换并通知
i3-msg workspace number $NEXT_WS
notify-send -t 800 -h string:x-dunst-stack-tag:ws "✨ 新工作区 $NEXT_WS"
