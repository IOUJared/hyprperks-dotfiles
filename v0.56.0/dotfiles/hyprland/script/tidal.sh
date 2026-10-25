#!/bin/bash

# Wait for Hyprland to be fully initialized
while ! hyprctl clients >/dev/null 2>&1; do
    sleep 0.5
done

# Create temporary Hyprland config for workspace rule
temp_config=$(mktemp)
echo "windowrule = workspace 3 silent, class:^(tidal-hifi)$" > "$temp_config"

# Apply the temporary rule
hyprctl reload "$temp_config"

# Launch Tidal HiFi with Wayland flags
uwsm app -- tidal-hifi \
    --enable-features=UseOzonePlatform \
    --ozone-platform=wayland \
    --no-sandbox \
    --no-zygote &

# Clean up temporary config after a delay
(sleep 5; rm -f "$temp_config") &
