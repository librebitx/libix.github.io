#!/bin/bash

# 1. 获取当前聚焦的工作区编号
WS_NUM=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).num')

# 2. 提取该工作区下所有窗口的软件名称 (Class)
# 通过 i3-msg 的树状结构精准定位当前工作区下的节点
APPS=$(i3-msg -t get_tree | jq -r "
  recurse(.nodes[]) | 
  select(.type==\"workspace\" and .focused==true) | 
  recurse(.nodes[], .floating_nodes[]) | 
  select(.window_properties != null) | 
  .window_properties.class" | sort | uniq | tr '\n' ',' | sed 's/,$//; s/,/  •  /g')

# 如果工作区是空的
if [ -z "$APPS" ]; then
    APPS="桌面空空如也"
fi

# 3. 发送通知 (延续灵动岛风格)
notify-send -u normal -t 2000 \
    -h string:x-dunst-stack-tag:ws_island \
    "🏢 工作区 $WS_NUM" \
    "$APPS"
