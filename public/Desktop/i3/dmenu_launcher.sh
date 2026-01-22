#!/bin/bash

choice=$(dmenu_path | dmenu -i -p "Run:")

[ -z "$choice" ] && exit

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=ibus

case "$choice" in
    *google-chrome*|*chrome*)
        exec google-chrome-stable --proxy-server="http://127.0.0.1:7897"
        ;;
        
    *chromium*)
        exec chromium --proxy-server="http://127.0.0.1:7897"
        ;;

    *)
    
        exec $choice
        ;;
esac
