#!/bin/bash

i3-msg workspace "$1" > /dev/null

sleep 0.1

WS_JSON=$(i3-msg -t get_workspaces)

#    - CURRENT_WS: 当前聚焦的工作区号码
#    - TOTAL_COUNT: 当前工作区的总数量
CURRENT_WS=$(echo "$WS_JSON" | jq -r '.[] | select(.focused==true).num')
TOTAL_COUNT=$(echo "$WS_JSON" | jq 'length')

if [ -n "$CURRENT_WS" ]; then
    if [ "$TOTAL_COUNT" -eq 1 ]; then        
        notify-send -t 800 \
            -h string:x-dunst-stack-tag:ws \
            "唯一工作区: $CURRENT_WS"
    else       
        notify-send -t 800 \
            -h string:x-dunst-stack-tag:ws \
            "工作区: $CURRENT_WS"
    fi

else
    notify-send -t 800 -h string:x-dunst-stack-tag:ws "工作区 ???"
fi
