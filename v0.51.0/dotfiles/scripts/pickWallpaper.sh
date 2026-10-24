#!/bin/bash

if [[ ! -v HLDE_DEFAULT_WALLPAPER_PICK_PATH ]]; then
    SELECTION=$(zenity --file-selection --title="Choose a new wallpaper" --file-filter="Image files | *.jpg *.jpeg *.png *.webp")
else
    SELECTION=$(zenity --file-selection --filename="$HLDE_DEFAULT_WALLPAPER_PICK_PATH/" --title="Choose a new wallpaper" --file-filter="Image files | *.jpg *.jpeg *.png *.webp")
fi

echo "selected: $SELECTION"

if [ -z "$SELECTION" ]; then
    echo "No wallpaper chosen"
fi

$(dirname "$0")/wallpaper.sh "$SELECTION"