#!/bin/bash

set -euo pipefail

SUBIN=""

if command -v sudo > /dev/null ; then
    SUBIN="sudo"
elif command -v doas > /dev/null ; then
    SUBIN="doas"
elif command -v run0 > /dev/null ; then
    SUBIN="run0"
else
    echo -ne "No supported superuser binary found. You need sudo/doas/run0."
    exit 1
fi

# setup wallust
mkdir -p ~/.config/wallust
cp -r ./wallust ~/.config

# setup matugen
mkdir -p ~/.config/matugen
cp -r ./matugen ~/.config

# setup image
if [ ! -f ~/avatar.jpg ]; then
  cp ./anon.jpg ~/avatar.jpg
fi

# setup Hyprland configs
mkdir -p ~/.config/hypr
rm -rf ~/.config/hypr/conf.d
cp ./hyprland/hyprland.conf ~/.config/hypr
cp ./hyprland/hyprpaper.conf ~/.config/hypr
cp ./hyprland/hyprlock.conf ~/.config/hypr
cp -r ./hyprland/conf.d ~/.config/hypr
cp -r ./hyprland/assets ~/.config/hypr

if [ ! -d ~/.config/hypr/custom.d ]; then
    cp -r ./hyprland/custom.d ~/.config/hypr
fi

# setup cursor themes
mkdir -p ~/.icons/
cp -r ./third-party/xcursor-pro-dark/XCursor-Pro-Dark ~/.icons
cp -r ./third-party/xcursor-pro-hyprcursor/XCursor-Pro-Dark-Hyprcursor ~/.icons
gsettings set org.gnome.desktop.interface cursor-theme 'XCursor-Pro-Dark'
gsettings set org.gnome.desktop.interface cursor-size '24'

# setup kitty
mkdir -p ~/.config/kitty
cp ./kitty/hl.conf ~/.config/kitty
if [ ! -f ~/.config/kitty/kitty.conf ]; then
    echo -ne "include ./hl.conf\n# You can add your own configuration options for kitty below. They will not be overwritten.\n\n" > ~/.config/kitty/kitty.conf
else
    cat ~/.config/kitty/kitty.conf | grep "hl.conf" || echo -ne "\ninclude ./hl.conf" >> ~/.config/kitty/kitty.conf
fi

# setup walker
mkdir -p ~/.config/walker
cp -r ./walker ~/.config

# setup quickshell
mkdir -p ~/.config/quickshell
cp -r ./quickshell ~/.config

# setup qt6 theme
mkdir -p ~/.config/Kvantum
cp -r ./third-party/fluent-kde/Kvantum ~/.config
cp ./kvantum/kvantum.kvconfig ~/.config/Kvantum
mkdir -p ~/.config/qt6ct
cp -r ./qt6ct ~/.config
sed -i -e "s/USERNAME/$USER/g" ~/.config/qt6ct/qt6ct.conf
cp ./kde/kdeglobals ~/.config

if [[ ! -v HLDE_NOSUDO ]]; then
    echo "HLDE_NOSUDO not present, installing global things..."

    if grep -q QT_QPA_PLATFORMTHEME "/etc/environment"; then
        $SUBIN sed -i -e 's/QT_QPA_PLATFORMTHEME\=.*/QT_QPA_PLATFORMTHEME\=qt6ct/g' /etc/environment
    else
        echo QT_QPA_PLATFORMTHEME=qt6ct | $SUBIN tee -a /etc/environment
    fi

    # setup icon theme
    $SUBIN mkdir -p /usr/share/icons
    $SUBIN cp -r ./third-party/papirus/Papirus-Dark/ /usr/share/icons
else
    echo "HLDE_NOSUDO present, not installing global things..."
fi

gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'

# setup gtk theme
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'

rm -rf ~/.config/gtk-3.0/*
rm -rf ~/.config/gtk-4.0/*

cp -r ./gtk-3.0/ ~/.config
cp -r ./gtk-4.0/ ~/.config

# setup fonts
mkdir -p ~/.config/fontconfig
cp -r ./fontconfig ~/.config

gsettings set org.gnome.desktop.interface font-name 'Lato'

# setup random shit
cp ./code-flags.conf ~/.config
cp ./codium-flags.conf ~/.config
cp ./electron-flags.conf ~/.config
cp ./spotify-flags.conf ~/.config

# fix plasma menus
mkdir -p ~/.config/menus
cp ./kde/applications.menu ~/.config/menus
kbuildsycoca6

# setup hyprland-de config dir
mkdir -p ~/.config/hyprland-de

if [ ! -f ~/.config/hyprland-de/wallpaper.conf ]; then
    echo "~/.config/hypr/assets/wallpaper.png" > ~/.config/hyprland-de/wallpaper.conf
fi

cp -r ./scripts/ ~/.config/hyprland-de/
chmod +x ~/.config/hyprland-de/scripts/*

# polkit
systemctl --user enable --now hyprpolkitagent

# setup wallpaper with scripts
~/.config/hyprland-de/scripts/wallpaper.sh "$(cat ~/.config/hyprland-de/wallpaper.conf)" || echo "Skipping wallpaper"

hyprctl reload
