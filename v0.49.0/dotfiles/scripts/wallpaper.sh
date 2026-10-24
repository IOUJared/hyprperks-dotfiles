#!/bin/bash

if [ -z "$1" ]; then
    echo "No path supplied"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "File doesn't exist"
    exit 1
fi

echo "$(realpath $1)" > ~/.config/hyprland-de/wallpaper.conf

cat <<EOF > ~/.config/hypr/hyprpaper.conf
preload=$1
wallpaper=,$1
EOF

killall hyprpaper > /dev/null || echo ""
hyprctl dispatch exec hyprpaper
wallust run $1 > /dev/null & disown
matugen image $1 > /dev/null & disown
killall walker > /dev/null || echo ""
GSK_RENDERER=cairo walker --gapplication-service & disown

echo "Done!"
