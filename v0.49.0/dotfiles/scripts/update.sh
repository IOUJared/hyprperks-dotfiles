#!/bin/bash

$(dirname "$0")/refresh.sh

. ~/.local/share/hyprland-de/token

bash -c "$(curl -fsSL https://dl.hypr.land/desktop/update.sh)"

sleep 2

qs msg update updated