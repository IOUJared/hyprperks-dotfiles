#!/usr/bin/env bash
# Live check that Steam/Proton games stay tiled when they arrive as XWayland
# clients. Requires a running Hyprland and PyGObject; skips otherwise.
set -euo pipefail

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || ! command -v hyprctl >/dev/null; then
    echo "SKIP no running Hyprland"
    exit 0
fi
if ! python3 -c 'import gi; gi.require_version("Gtk", "3.0")' >/dev/null 2>&1; then
    echo "SKIP PyGObject/GTK3 not available"
    exit 0
fi

tmp="$(mktemp -d "${TMPDIR:-/tmp}/hypr-xwayland-float-test.XXXXXX")"
trap 'kill "$probe_pid" 2>/dev/null || true; rm -rf "$tmp"' EXIT

# A plain X11 window with a Steam app id as its WM_CLASS. Proton games present
# the same shape (xwayland=true, class=steam_app_<id>).
cat >"$tmp/probe.py" <<'EOF'
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib

w = Gtk.Window()
w.set_wmclass("steam_app_230410", "steam_app_230410")
w.set_default_size(500, 300)
w.show_all()
GLib.timeout_add(6000, Gtk.main_quit)
Gtk.main()
EOF

GDK_BACKEND=x11 python3 "$tmp/probe.py" >/dev/null 2>&1 &
probe_pid=$!

floating=""
for _ in $(seq 1 24); do
    floating="$(hyprctl clients -j 2>/dev/null | python3 -c '
import json, sys
for w in json.load(sys.stdin):
    if w.get("class") == "steam_app_230410":
        print(str(w.get("floating")).lower())
        break
' || true)"
    [[ -n "$floating" ]] && break
    sleep 0.25
done

if [[ -z "$floating" ]]; then
    echo "SKIP probe window did not appear"
    exit 0
fi
if [[ "$floating" != "false" ]]; then
    echo "FAIL steam_app_230410 is floating (XWayland override not applied)"
    exit 1
fi
echo "xwayland float test passed"
