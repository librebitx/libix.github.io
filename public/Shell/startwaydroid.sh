#!/bin/bash
# 1. 先清除残留的环境变量（最关键的一步！）
unset WAYLAND_DISPLAY

# 2. 停止之前的会话，防止冲突
waydroid session stop

# 3. 启动 Weston
# --backend=x11-backend.so : 强制告诉它我们在 X11 (Openbox) 上运行，不要自动检测
weston --backend=x11-backend.so --socket=waydroid-socket --width=1000 --height=800 --shell=kiosk-shell.so &

# 4. 等待 Weston 窗口弹出 (给它 3 秒时间)
sleep 3

# 5. 设置环境变量，告诉 Waydroid 它是运行在刚才那个 socket 里的
export WAYLAND_DISPLAY=waydroid-socket

# 6. 启动安卓界面
waydroid show-full-ui
