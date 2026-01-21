#!/bin/bash

# 截图保存地址
DIR="/home/libix/Pictures/screenshots"

# 截图名称
FILE="$DIR/$(date +%Y-%m-%d_%H:%M:%S).png"

# 选区截图 -> 保存 -> 同时复制到剪贴板
maim -s "$FILE" && xclip -selection clipboard -t image/png < "$FILE"
