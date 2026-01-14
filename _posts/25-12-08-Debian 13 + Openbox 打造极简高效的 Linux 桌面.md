---
layout: default
title:  "Debian 13 + Openbox 打造极简高效的 Linux 桌面"
date:   2025-12-08
blog-label: Fun
---



在这篇文章中，我将分享如何在 **Debian 13 上构建一个基于 Openbox 的极简桌面环境**，并对窗口管理、菜单、快捷键、美化、常用工具进行配置。
实现低资源占用、快速响应、自由定制、极简视觉，适合老电脑、虚拟机、极简主义用户等。
为了保持环境纯净，安装时只需保留最基础的系统。

#### 系统配置

```bash
su -

cat <<EOL> /etc/apt/sources.list
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie-updates main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security/ trixie-security main contrib non-free non-free-firmware
EOL

apt update
apt install sudo vim
usermod -aG sudo libix

reboot
```

#### 安装 openbox

```bash
sudo apt update
sudo apt install xorg openbox obconf lxappearance xdg-desktop-portal xdg-desktop-portal-gtk
# obconf 是 Openbox 的图形配置工具，它编辑的是 ~/.config/openbox/rc.xml
# lxappearance 可以设置主题、图标主题、鼠标主题、字体
# xdg-desktop-portal xdg-desktop-portal-gtk 用于跨应用交互（如文件对话框、输入法集成、主题同步）的后端组件
# 启动 openbox
startx
obmenu obmenu-generator nitrogen picom 
```

进入 openbox 后，右击鼠标选择打开终端，默认的 Xterm 缺少太多功能，大家可以安装自己喜欢的终端，我这里选择比较轻量的 Lxterminal

```bash
sudo apt install lxterminal
lxtermianl &
```

#### 主菜单

menu.xml 文件定义了主菜单的结构和选项，可以鼠标右击桌面或设置快捷键打开，下面是一个小模板示范，大家可以根据自己喜好自定义，系统默认配置在 `/etc/xdg/openbox/menu.xml`

```bash
cat <<EOL> /etc/xdg/openbox/menu.xml
<?xml version="1.0" encoding="UTF-8"?>

<openbox_menu xmlns="http://openbox.org/"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://openbox.org/
                file:///usr/share/openbox/menu.xsd">

<menu id="root-menu" label="Openbox 3">
  <!--big title-->
  <!-- separator label="Menu" / -->
  <separator label="Menu" />

  <separator />
  <item label="LXTerminal">
    <action name="Execute"><execute>lxterminal</execute></action>
  </item>

  <item label="Firefox">
    <action name="Execute"><execute>firefox</execute></action>
  </item>

  <item label="PCManFM">
    <action name="Execute"><execute>pcmanfm</execute></action>
  </item>
  
  <item label="Geany">
    <action name="Execute"><execute>geany</execute></action>
  </item>

  <menu id="/Debian" />
  <separator />
  
  <menu id="all-software" label="Common SoftWare">
	  <menu id="vmware" label="VMware Workstation">
		  <item label="VMware">
			<action name="Execute"><execute>vmware</execute></action>
		  </item>	  
		  <item label="VMware Network Edior">
			<action name="Execute"><execute>lxterminal --command='sudo vmware-netcfg'</execute></action>
		  </item>	  
	  </menu>
	  
	  <item label="QQ">
		<action name="Execute"><execute>qq</execute></action>
	  </item>
  </menu>
  
  <separator />
  
  <menu id="diy-software" label="Beauty Tools">
	  <item label="ObConf">
		<action name="Execute"><execute>obconf</execute></action>
	  </item>
	  <item label="Lxappearance">
		<action name="Execute"><execute>lxappearance</execute></action>
	  </item>
  </menu>
  
  <separator />
  
  <item label="Restart">
    <action name="Restart" />
  </item>
  
    <item label="Lock">
		<action name="Execute"><execute>slock</execute></action>
	  </item>

  <item label="Exit">
    <action name="Exit" />
  </item>
</menu>

</openbox_menu>
EOL

openbox --reconfigure		# 刷新 openbox 配置，也可以右击鼠标点击 Restart
```

#### 输入法

Fcitx5 是目前 Linux 社区公认的输入法框架第一选择。与 IBus 相比，Fcitx5 的后台常驻进程更少，内存占用更小。

```bash
sudo apt install fcitx5 fcitx5-chinese-addons fcitx5-config-qt fcitx5-frontend-gtk2 fcitx5-frontend-gtk3 fcitx5-frontend-qt5
```

以下是关于 fcitx5 皮肤安装的链接：

[https://github.com/hosxy/Fcitx5-Material-Color](https://github.com/hosxy/Fcitx5-Material-Color)

[https://github.com/thep0y/fcitx5-themes-candlelight](https://github.com/thep0y/fcitx5-themes-candlelight)

#### 快捷键

快捷键的配置文件 rc.xml 其中也包括了 openbox 主题的配置信息，需要创建在用户家目录下。

以下是本人在使用的快捷键，大家可以根据自己喜好自定义，系统默认配置在 `/etc/xdg/openbox/rc.xml`。``

```bash
mkdir -p ~/.config/openbox
touch ~/.config/openbox/rc.xml

cat > ~/.config/openbox/rc.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc" xmlns:xi="http://www.w3.org/2001/XInclude">
  <resistance>
    <strength>10</strength>
    <screen_edge_strength>20</screen_edge_strength>
  </resistance>
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
    <focusLast>yes</focusLast>
    <underMouse>no</underMouse>
    <focusDelay>100</focusDelay>
    <raiseOnFocus>no</raiseOnFocus>
  </focus>
  <placement>
    <policy>Smart</policy>
    <center>yes</center>
    <monitor>Primary</monitor>
    <primaryMonitor>1</primaryMonitor>
  </placement>
  <theme>
    <name>White</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>no</keepBorder>
    <animateIconify>yes</animateIconify>
    <font place="ActiveWindow">
      <name>Montserrat Medium</name>
      <size>12</size>
      <weight>Normal</weight>
      <slant>Normal</slant>
    </font>
    <font place="InactiveWindow">
      <name>Montserrat Medium</name>
      <size>9</size>
      <weight>Normal</weight>
      <slant>Normal</slant>
    </font>
    <font place="MenuHeader">
      <name>Montserrat</name>
      <size>9</size>
      <weight>Bold</weight>
      <slant>Normal</slant>
    </font>
    <font place="MenuItem">
      <name>Montserrat</name>
      <size>9</size>
      <weight>Bold</weight>
      <slant>Normal</slant>
    </font>
    <font place="ActiveOnScreenDisplay">
      <name>Montserrat Medium</name>
      <size>9</size>
      <weight>Normal</weight>
      <slant>Normal</slant>
    </font>
    <font place="InactiveOnScreenDisplay">
      <name>Montserrat Medium</name>
      <size>9</size>
      <weight>Normal</weight>
      <slant>Normal</slant>
    </font>
  </theme>
  <desktops>
    <number>2</number>
    <firstdesk>1</firstdesk>
    <names>
    </names>
    <popupTime>875</popupTime>
  </desktops>
  <resize>
    <drawContents>no</drawContents>
    <popupShow>Nonpixel</popupShow>
    <popupPosition>Center</popupPosition>
    <popupFixedPosition>
      <x>10</x>
      <y>10</y>
    </popupFixedPosition>
  </resize>
  <margins>
    <top>0</top>
    <bottom>0</bottom>
    <left>0</left>
    <right>0</right>
  </margins>
  <dock>
    <position>Top</position>
    <floatingX>0</floatingX>
    <floatingY>0</floatingY>
    <noStrut>no</noStrut>
    <stacking>Above</stacking>
    <direction>Vertical</direction>
    <autoHide>no</autoHide>
    <hideDelay>300</hideDelay>
    <showDelay>300</showDelay>
    <moveButton>Middle</moveButton>
  </dock>
  <keyboard>
    <chainQuitKey>C-g</chainQuitKey>
    <keybind key="A-Left">
      <action name="GoToDesktop"><to>left</to><wrap>no</wrap></action>
    </keybind>
    <keybind key="A-Right">
      <action name="GoToDesktop"><to>right</to><wrap>no</wrap></action>
    </keybind>
    <keybind key="C-A-Left">
      <action name="SendToDesktop"><to>left</to><wrap>no</wrap></action>
    </keybind>
    <keybind key="C-A-Right">
      <action name="SendToDesktop"><to>right</to><wrap>no</wrap></action>
    </keybind>
    <keybind key="W-Tab">
      <action name="ToggleShowDesktop"></action>
    </keybind>
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>
    <keybind key="A-Escape">
      <action name="Lower"/><action name="FocusToBottom"/><action name="Unfocus"/>
    </keybind>
    <keybind key="C-Tab">
      <action name="ShowMenu"><menu>client-menu</menu></action>
    </keybind>
    <keybind key="W-Left">
      <action name="UnmaximizeFull"/>
      <action name="MoveResizeTo"><x>0</x><y>0</y><width>50%</width><height>100%</height></action>
    </keybind>
    <keybind key="W-Right">
      <action name="UnmaximizeFull"/>
      <action name="MoveResizeTo"><x>50%</x><y>0</y><width>50%</width><height>100%</height></action>
    </keybind>
    <keybind key="A-Tab"><action name="NextWindow"/></keybind>
    <keybind key="W-l">
      <action name="Execute"><command>slock</command></action>
    </keybind>
    <keybind key="W-a">
      <action name="ShowMenu"><menu>root-menu</menu></action>
    </keybind>
    <keybind key="Print">
      <action name="Execute"><command>/home/libix/shell/maimshot.sh</command></action>
    </keybind>
  </keyboard>
  <mouse>
    <dragThreshold>1</dragThreshold>
    <doubleClickTime>500</doubleClickTime>
    <screenEdgeWarpTime>0</screenEdgeWarpTime>
    <screenEdgeWarpMouse>false</screenEdgeWarpMouse>
    <context name="Frame">
      <mousebind button="A-Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="A-Left" action="Click"><action name="Unshade"/></mousebind>
      <mousebind button="A-Left" action="Drag"><action name="Move"/></mousebind>
      <mousebind button="A-Right" action="Press"><action name="Focus"/><action name="Raise"/><action name="Unshade"/></mousebind>
      <mousebind button="A-Right" action="Drag"><action name="Resize"/></mousebind>
      <mousebind button="A-Middle" action="Press"><action name="Lower"/><action name="FocusToBottom"/><action name="Unfocus"/></mousebind>
      <mousebind button="A-Up" action="Click"><action name="GoToDesktop"><to>1</to></action></mousebind>
      <mousebind button="A-Down" action="Click"><action name="GoToDesktop"><to>2</to></action></mousebind>
    </context>
    <context name="Titlebar">
      <mousebind button="Left" action="Drag"><action name="Move"/></mousebind>
      <mousebind button="Left" action="DoubleClick"><action name="ToggleMaximizeFull"/></mousebind>
      <mousebind button="Up" action="Click"><action name="if"><shaded>no</shaded><then><action name="Shade"/><action name="FocusToBottom"/><action name="Unfocus"/><action name="Lower"/></then></action></mousebind>
      <mousebind button="Down" action="Click"><action name="if"><shaded>yes</shaded><then><action name="Unshade"/><action name="Raise"/></then></action></mousebind>
    </context>
    <context name="Titlebar Top Right Bottom Left TLCorner TRCorner BRCorner BLCorner">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/><action name="Unshade"/></mousebind>
      <mousebind button="Middle" action="Press"><action name="Lower"/><action name="FocusToBottom"/><action name="Unfocus"/></mousebind>
      <mousebind button="Right" action="Press"><action name="Focus"/><action name="Raise"/><action name="ShowMenu"><menu>client-menu</menu></action></mousebind>
    </context>
    <context name="Top">
      <mousebind button="Left" action="Drag"><action name="Resize"><edge>top</edge></action></mousebind>
    </context>
    <context name="Left">
      <mousebind button="Left" action="Drag"><action name="Resize"><edge>left</edge></action></mousebind>
    </context>
    <context name="Right">
      <mousebind button="Left" action="Drag"><action name="Resize"><edge>right</edge></action></mousebind>
    </context>
    <context name="Bottom">
      <mousebind button="Left" action="Drag"><action name="Resize"><edge>bottom</edge></action></mousebind>
      <mousebind button="Right" action="Press"><action name="Focus"/><action name="Raise"/><action name="ShowMenu"><menu>client-menu</menu></action></mousebind>
    </context>
    <context name="TRCorner BRCorner TLCorner BLCorner">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/><action name="Unshade"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Resize"/></mousebind>
    </context>
    <context name="Client">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Middle" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Right" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
    </context>
    <context name="Icon">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/><action name="Unshade"/><action name="ShowMenu"><menu>client-menu</menu></action></mousebind>
      <mousebind button="Right" action="Press"><action name="Focus"/><action name="Raise"/><action name="ShowMenu"><menu>client-menu</menu></action></mousebind>
    </context>
    <context name="AllDesktops">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/><action name="Unshade"/></mousebind>
      <mousebind button="Left" action="Click"><action name="ToggleOmnipresent"/></mousebind>
    </context>
    <context name="Shade">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Click"><action name="ToggleShade"/></mousebind>
    </context>
    <context name="Iconify">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Click"><action name="Iconify"/></mousebind>
    </context>
    <context name="Maximize">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/><action name="Unshade"/></mousebind>
      <mousebind button="Middle" action="Press"><action name="Focus"/><action name="Raise"/><action name="Unshade"/></mousebind>
      <mousebind button="Right" action="Press"><action name="Focus"/><action name="Raise"/><action name="Unshade"/></mousebind>
      <mousebind button="Left" action="Click"><action name="ToggleMaximize"/></mousebind>
      <mousebind button="Middle" action="Click"><action name="ToggleMaximize"><direction>vertical</direction></action></mousebind>
      <mousebind button="Right" action="Click"><action name="ToggleMaximize"><direction>horizontal</direction></action></mousebind>
    </context>
    <context name="Close">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/><action name="Unshade"/></mousebind>
      <mousebind button="Left" action="Click"><action name="Close"/></mousebind>
    </context>
    <context name="Desktop">
      <mousebind button="A-Up" action="Click"><action name="GoToDesktop"><to>1</to></action></mousebind>
      <mousebind button="A-Down" action="Click"><action name="GoToDesktop"><to>2</to></action></mousebind>
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Right" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
    </context>
    <context name="Root">
      <mousebind button="Middle" action="Press"><action name="ShowMenu"><menu>client-list-combined-menu</menu></action></mousebind>
      <mousebind button="Right" action="Press"><action name="ShowMenu"><menu>root-menu</menu></action></mousebind>
    </context>
  </mouse>
  <menu>
    <file>/var/lib/openbox/debian-menu.xml</file>
    <file>menu.xml</file>
    <hideDelay>200</hideDelay>
    <middle>no</middle>
    <submenuShowDelay>100</submenuShowDelay>
    <submenuHideDelay>400</submenuHideDelay>
    <showIcons>yes</showIcons>
    <manageDesktops>yes</manageDesktops>
  </menu>
  <applications>
    <application class="*">
      <decor>no</decor>
    </application>
  </applications>
</openbox_config>
EOF

openbox --reconfigure
```

#### 剪贴板配置

openbox 默认不支持复制粘贴图片

```bash
libix@Debian:~$ cat shell/maimshot.sh 
#!/bin/bash

# 截图保存地址
DIR="/home/libix/Pictures/screenshots"

# 截图名称
FILE="$DIR/$(date +%Y-%m-%d_%H:%M:%S).png"

# 选区截图 -> 保存 -> 同时复制到剪贴板
maim -s "$FILE" && xclip -selection clipboard -t image/png < "$FILE"
libix@Debian:~$ 


```



#### 截图

```bash
sudo apt install maim xclip

libix@Debian:~$ cat maimshot.sh 
#!/bin/bash
# 截图保存地址
DIR="~/Pictures/screenshots"
# 截图名称
FILE="$DIR/$(date +%Y-%m-%d_%H:%M:%S).png"
# 选区截图 -> 保存 -> 同时复制到剪贴板
maim -s "$FILE" && xclip -selection clipboard -t image/png < "$FILE"
libix@Debian:~$ 
```



#### 主题和图标

GTK 主题决定了窗口的样式，可以根据喜好选择，我比较喜欢 Kali Linux 的主题和图标

```bash
git clone https://gitlab.com/kalilinux/packages/kali-themes.git
mkdir -p ~/.themes
mv kali-themes/share/themes ~/.themes
mkdir -p ~/.icons
mv kali-themes/share/icons ~/.icons

lxappearance &		# 打开主题设置
```

https://www.gnome-look.org/browse?cat=135&ord=latest

**openbox 主题**决定了标题栏样式和菜单样式，使用 obconf 设置

``` bash
obconf &
```

https://github.com/addy-dclxvi/openbox-theme-collections

#### 字体

在 obconf 中设置标题栏、主菜单字体；
在 lxappearance 中设置桌面显示字体

https://fonts.google.com/

#### 壁纸

推荐使用 feh 设置桌面壁纸
```bash
feh --bg-fill ~/Pictures/wallpaper.jpg &
```

#### 分辨率调整

```bash
libix@Debian:~$ xrandr
Screen 0: minimum 320 x 200, current 1920 x 1080, maximum 16384 x 16384
eDP connected primary (normal left inverted right x axis y axis)
   2880x1800    120.00 + 120.00 +  48.00  
   1920x1200    120.00  
   1920x1080    120.00  
   1600x1200    120.00  
   1680x1050    120.00  
   1280x1024    120.00  
   1440x900     120.00  
   1280x800     120.00  
   1280x720     120.00  
   1024x768     120.00  
   800x600      120.00  
   640x480      120.00  
HDMI-A-0 connected 1920x1080+0+0 (normal left inverted right x axis y axis) 527mm x 296mm
   1920x1080     60.00*+  50.00    59.94  
   1680x1050     59.88  
   1600x900      60.00  
   1280x1024     60.02  
   1440x900      59.90  
   1280x800      59.91  
   1280x720      60.00    50.00    59.94  
   1024x768      60.00  
   800x600       60.32  
   720x576       50.00  
   720x480       60.00    59.94  
   640x480       60.00    59.94  
   720x400       70.08  
DisplayPort-0 disconnected (normal left inverted right x axis y axis)
DisplayPort-1 disconnected (normal left inverted right x axis y axis)
DisplayPort-2 disconnected (normal left inverted right x axis y axis)
DisplayPort-3 disconnected (normal left inverted right x axis y axis)
DisplayPort-4 disconnected (normal left inverted right x axis y axis)
DisplayPort-5 disconnected (normal left inverted right x axis y axis)
libix@Debian:~$ 

# 设置分辨率（例如 1920×1080）
xrandr --output eDP-1 --mode 1920x1080

```



#### 动画与透明

picom

```bash
libix@Debian:~$ sudo apt install picom
libix@Debian:~$ cat ./.config/picom/picom.conf 
backend = "glx";
vsync = true;

glx-no-stencil = true;
glx-no-rebind-pixmap = true;
glx-copy-from-front = false;
use-damage = true;

unredir-if-possible = true;
unredir-if-possible-exclude = [
    "class_g = 'Vlc'"
];
        
corner-radius = 0;

detect-rounded-corners = true;
rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'"
];

shadow = true;
shadow-radius = 18;
shadow-opacity = 0.4;
shadow-offset-x = -15;
shadow-offset-y = -15;

shadow-exclude = [
  "name = 'Notification'",
  "class_g = 'Conky'",
  "class_g = 'fcitx'",
  "class_g = 'fcitx5'",
  "_GTK_FRAME_EXTENTS@:c",
  "class_g = 'firefox' && argb",
  "class_g = 'Google-chrome' && argb"
];

fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;
fade-delta = 4;
no-fading-openclose = false;

active-opacity = 1.0;
inactive-opacity = 0.90;
frame-opacity = 1.0;
inactive-opacity-override = false;

opacity-rule = [
  "100:class_g = 'Firefox'",
  "100:class_g = 'Google-chrome'",
  "100:class_g = 'Chromium'",
  "100:class_g = 'Vlc'",
  "100:class_g = 'fcitx5'",
  "100:fullscreen"
];

blur-method = "dual_kawase";
blur-strength = 5;

blur-background-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'",
  "_GTK_FRAME_EXTENTS@:c"
];

wintypes:
{
  tooltip = { fade = true; shadow = true; opacity = 0.95; focus = true; full-shadow = false; };
  dock = { shadow = false; clip-shadow-above = true; }
  dnd = { shadow = false; }
  popup_menu = { opacity = 1.0; shadow = false; }
  dropdown_menu = { opacity = 1.0; shadow = false; }
  menu = { opacity = 1.0; shadow = false; }
};
libix@Debian:~$ 

```

#### 面板
Polybar 交互式状态栏（能点、能切换、能操作）
Conky 桌面监控仪表（只显示，不交互）
因为 polybar 会占用屏幕顶部小部分空间，而我只需要看看时间和机器状态，所以我选择了 conky

```bash
conky.config = {
    -- 窗口设置
    own_window = true,  -- 启用独立窗口显示模式。避免闪烁，提高性能。
    own_window_type = 'desktop',  -- 显示在桌面层，窗口不会遮挡其他程序
    own_window_transparent = false, -- 背景透明
    own_window_argb_visual = true,
    own_window_argb_value = 0,  -- 0 = 完全透明
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',


    own_window_colour = '#222222', -- 设置窗口背景颜色（这里是黑色）	
    -- 设置窗口类名和窗口标题，方便窗口管理器识别和管理该窗口
    own_window_class = 'Conky',
    own_window_title = 'Conky',

    -- 位置与大小
    alignment = 'center',
    gap_x = 20,	-- 水平边距，距离屏幕边缘 20 像素。
    gap_y = 20,
    minimum_width = 1500, -- 窗口的最小宽度
    maximum_width = 1500,

    -- 绘制参数
    double_buffer = true, -- 双缓冲减少闪烁
    use_xft = true, -- 启用 Xft 字体渲染，支持抗锯齿和更漂亮的字体
    font = 'SF Mono:weight=Light:size=12', -- 默认字体
    xftalpha = 1,
    update_interval = 3,     -- 刷新间隔

    -- 字体颜色设置
    default_color = 'white',
    default_outline_color = 'white', -- 字体轮廓颜色
    default_shade_color = 'white', -- 字体阴影颜色

    -- 边框与背景
    draw_borders = false,
    draw_graph_borders = false, -- 绘制图表的边框
    draw_shades = false,
    draw_outline = false,
}

conky.text = [[
${font SF Mono:weight=Light:size=50}${alignc}${time %y-%m-%d %a}${font}
${font SF Mono:weight=Bold:size=300}${alignc}${time %H:%M}${font}






${font SF Mono:weight=Light:size=15}${alignc}CPU:    ${cpu cpu0}% | Mem:    ${memperc}% | ↓    ${downspeed wlo1} | ↑    ${upspeed wlo1}${font}

	
${alignc}${top_mem name 1}   ${top_mem mem_res 1}
${alignc}${top_mem name 2}   ${top_mem mem_res 2}
${alignc}${top_mem name 3}   ${top_mem mem_res 3}
${alignc}${top_mem name 4}   ${top_mem mem_res 4}
${alignc}${top_mem name 5}   ${top_mem mem_res 5}

]]
```
![](/assest/DOB/2025-12-08_22:41:42.png)
``` bash
conky.config = {

    own_window = true,
    own_window_type = 'desktop',
    own_window_transparent = true,
    own_window_argb_visual = true,
    own_window_argb_value = 0,
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',

    alignment = 'top_middle',
    gap_x = 0,
    gap_y = 4,

    update_interval = 5,
    double_buffer = true,

    use_xft = true,
    font = 'SF Mono:size=11',
    default_color = 'FFFF00',

    draw_borders = false,
    draw_graph_borders = false,
    draw_outline = false,
    draw_shades = false,
};

conky.text = [[
${execi 60 LC_TIME=C date "+%Y-%m-%d %a %H:%M"} | CPU ${cpu}% | MEM ${memperc}% | ↓ ${downspeed wlo1} ↑ ${upspeed wlo1} | IP ${addr wlo1} | UP ${uptime} 
]];
```

#### 登录界面

``` bash
sudo apt install greetd tuigreet 
sudo mkdir -p /etc/greetd
sudo useradd -M -G video greeter
sudo touch /etc/greetd/config.toml
sudo chmod 644 /etc/greetd/config.toml
sudo systemctl enable greetd

cat <<EOL> /etc/greetd/config.toml
[terminal]
vt = 7
[default_session]
# 这里设置登录后执行 startx
command = "/usr/bin/tuigreet --cmd startx --time --time-format '%Y-%m-%d %H:%M' --remember --asterisks"
user = "greeter"
EOL
```

设置 `/etc/default/grub` 中的 `GRUB_CMDLINE_LINUX_DEFAULT`

```bash
# 只修改这一行！！！
cat /etc/default/grub | grep GRUB_CMDLINE_LINUX_DEFAULT
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 rd.systemd.show_status=false"
# loglevel=3：告诉内核只打印报错信息，隐藏普通的状态日志；
# rd.systemd.show_status=false：告诉 systemd 启动时不要刷屏显示 [OK]

sudo update-grub
sudo reboot
```

#### 推荐软件

文件管理		 pcmanfm / thunar 
音量控制 		pavucontrol
剪贴板  			 clipit 
截图     			flameshot 
通知     			dunst 
应用搜索 		   rofi 
音乐    			amberol （听离线）/ VutronMusic
视频播放	VLC

![](/assest/DOB/image-20251226081057349.png)

#### 性能优化建议

#### 问题与解决方案（FAQ）

示例：

1. 开机不启动组件
    → 检查 `autostart` 是否加 `&`
2. 菜单不刷新
    → `openbox --reconfigure`
3. 无中文字体
    → `sudo apt install fonts-noto-cjk`

#### 自动启动配置

使用 startx 启动 openbox 流程是：startx --> ~/.xinitrc

```bash
cat ~/.xinitrc		# X 会话启动脚本
# 不开启会导致部分应用启动时卡住,文件选择对话框延迟
/usr/libexec/xdg-desktop-portal &
/usr/libexec/xdg-desktop-portal-gtk &
# picom 必须保持后台常驻运行，作为 maim 的选区框需要 compositor 的实时渲染支持
# ~/.config/picom/picom.conf 配置了窗口的边角弧度
picom --backend xrender --config ~/.config/picom/picom.conf &
fcitx5 &
conky &
feh --bg-scale ~/Pictures/xxx.jpg
exec openbox-session
```

如果你用 LightDM 或 GDM 登录 openbox，.xinitrc 则不会被执行。

