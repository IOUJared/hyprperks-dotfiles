#!/bin/bash

set -euo pipefail

SUBIN=""

. /etc/os-release

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

# setup matugen
mkdir -p ~/.config/matugen
cp -r ./matugen/* ~/.config/matugen/

# setup image
if [ ! -f ~/avatar.jpg ]; then
  cp ./anon.jpg ~/avatar.jpg
fi

# setup Hyprland configs
mkdir -p ~/.config/hypr
rm -rf ~/.config/hypr/conf.d
rm -f ~/.config/hypr/hyprland.conf
cp ./hyprland/*.conf ./hyprland/*.lua ./hyprland/*.toml ./hyprland/.luarc.json \
    ./hyprland/xdg-portal-hyprland ~/.config/hypr/
cp -r ./hyprland/conf.d ./hyprland/assets ./hyprland/scheme \
    ./hyprland/script ./hyprland/sounds ~/.config/hypr/
chmod +x ~/.config/hypr/xdg-portal-hyprland ~/.config/hypr/script/*.sh

if [ ! -d ~/.config/hypr/custom.d ]; then
    cp -r ./hyprland/custom.d ~/.config/hypr
else
    mkdir -p ~/.config/hypr/custom.d/init ~/.config/hypr/custom.d/regular
    for f in ./hyprland/custom.d/init/*.lua; do
        target=~/.config/hypr/custom.d/init/$(basename "$f")
        [ -f "$target" ] || cp "$f" "$target"
    done
    for f in ./hyprland/custom.d/regular/*.lua; do
        target=~/.config/hypr/custom.d/regular/$(basename "$f")
        [ -f "$target" ] || cp "$f" "$target"
    done
fi

# setup cursors; Bibata is an external dependency, see README
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
gsettings set org.gnome.desktop.interface cursor-size '20'

# setup kitty
mkdir -p ~/.config/kitty/themes
cp ./kitty/hl.conf ./kitty/kitty.conf ./kitty/current-theme.conf \
    ./kitty/matugen.conf ~/.config/kitty/
cp -r ./kitty/themes/* ~/.config/kitty/themes/

# setup quickshell
mkdir -p ~/.config/quickshell
cp -r ./quickshell/* ~/.config/quickshell/

# setup Qt/Kvantum theme
mkdir -p ~/.config/Kvantum
cp -r ./kvantum/rose-pine-pine ./kvantum/rose-pine-rose ~/.config/Kvantum/
cp ./kvantum/kvantum.kvconfig ~/.config/Kvantum/
mkdir -p ~/.config/qt6ct
cp -r ./qt6ct/* ~/.config/qt6ct/
sed -i -e "s/USERNAME/$USER/g" ~/.config/qt6ct/qt6ct.conf
cp ./kde/kdeglobals ~/.config

if [[ ! -v HLDE_NOSUDO ]]; then
    echo "HLDE_NOSUDO not present, installing global things..."

    if grep -q QT_QPA_PLATFORMTHEME "/etc/environment"; then
        $SUBIN sed -i -e 's/QT_QPA_PLATFORMTHEME\=.*/QT_QPA_PLATFORMTHEME\=qt6ct/g' /etc/environment
    else
        echo QT_QPA_PLATFORMTHEME=qt6ct | $SUBIN tee -a /etc/environment
    fi

    # Enable system services
    $SUBIN systemctl enable NetworkManager
    $SUBIN systemctl enable bluetooth
else
    echo "HLDE_NOSUDO present, not installing global things..."
fi

gsettings set org.gnome.desktop.interface icon-theme 'rose-pine-icons'

# setup gtk theme
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'RosePine-Custom'

rm -rf ~/.config/gtk-3.0/*
rm -rf ~/.config/gtk-4.0/*

cp -r ./gtk-3.0/* ~/.config/gtk-3.0/
cp -r ./gtk-4.0/* ~/.config/gtk-4.0/

# setup fonts
mkdir -p ~/.config/fontconfig
cp -r ./fontconfig/* ~/.config/fontconfig/

gsettings set org.gnome.desktop.interface font-name 'Lato'

# setup random shit
cp ./code-flags.conf ~/.config
cp ./codium-flags.conf ~/.config
cp ./electron-flags.conf ~/.config
cp ./spotify-flags.conf ~/.config

# setup hyprland-de config dir
mkdir -p ~/.config/hyprland-de

if [ ! -f ~/.config/hyprland-de/wallpaper.conf ]; then
    if [ -f ./hyprland-de/wallpaper.conf ] && [ -f "$(cat ./hyprland-de/wallpaper.conf)" ]; then
        cp ./hyprland-de/wallpaper.conf ~/.config/hyprland-de/
    else
        echo "$(realpath ~/.config/hypr/assets/wallpaper.png)" > ~/.config/hyprland-de/wallpaper.conf
    fi
fi

cp -r ./scripts/ ~/.config/hyprland-de/
chmod +x ~/.config/hyprland-de/scripts/*

if [ ! -f ~/.config/hyprland-de/globalConfigs.sh ]; then
    cp ./hyprland-de/globalConfigs.sh ~/.config/hyprland-de
    chmod +x ~/.config/hyprland-de/globalConfigs.sh
fi

cp ./hyprland-de/globalConfigsDefaults.sh ~/.config/hyprland-de
chmod +x ~/.config/hyprland-de/globalConfigsDefaults.sh

# polkit
systemctl --user enable --now hyprpolkitagent

# setup wallpaper with scripts
~/.config/hyprland-de/scripts/wallpaper.sh "$(cat ~/.config/hyprland-de/wallpaper.conf)" || echo "Skipping wallpaper"

hyprctl reload || echo "hyprland not running"

if [ -f ~/.config/hyprland-de/custom.sh ]; then
    ~/.config/hyprland-de/custom.sh & disown
fi
