#!/usr/bin/env bash
# Regression test for the volume mixer icon lookup:
# - Quickshell must use the same icon theme as the rest of the desktop.
# - The mixer must not treat Quickshell.iconPath()'s image:// URL as a name.
set -euo pipefail

dotfiles_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
qml_dir="$dotfiles_dir/quickshell"
failures=0

fail() {
    echo "FAIL $*"
    failures=$((failures + 1))
}

# The root config has to select the Rosé Pine icon theme; Quickshell otherwise
# falls back to hicolor, where speaker/audio-speakers do not exist.
head -5 "$qml_dir/shell.qml" | grep -q 'pragma IconTheme rose-pine-icons' ||
    fail "shell.qml does not set //@ pragma IconTheme rose-pine-icons"

# The fallback icon must actually exist in that theme.
find /usr/share/icons/rose-pine-icons -iname 'audio-speakers.*' 2>/dev/null |
    grep -q . || fail "audio-speakers icon missing from rose-pine-icons"

# Candidate names are checked with hasThemeIcon; the old code compared an
# image:// URL against the literal string "speaker", so it never fell through.
grep -q 'Quickshell.hasThemeIcon' "$qml_dir/leftmenu/settingsSlice/VolumeMixerEntry.qml" ||
    fail "VolumeMixerEntry does not use Quickshell.hasThemeIcon"
grep -q 'audio-speakers' "$qml_dir/leftmenu/settingsSlice/VolumeMixerEntry.qml" ||
    fail "VolumeMixerEntry has no audio-speakers fallback"
if grep -q 'iconPath(icon, "speaker") !== "speaker"' \
    "$qml_dir/leftmenu/settingsSlice/VolumeMixerEntry.qml"; then
    fail "VolumeMixerEntry still compares an image:// URL to a literal string"
fi

# Runtime check: Quickshell resolves the theme and the fallback icon.
if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v qs >/dev/null; then
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/quickshell-icon-test.XXXXXX")"
    trap 'rm -rf "$tmp"' EXIT
    cat >"$tmp/shell.qml" <<'EOF'
//@ pragma UseQApplication
//@ pragma IconTheme rose-pine-icons
import QtQuick
import Quickshell

ShellRoot {
  Component.onCompleted: {
    console.log("ICONCHECK audio-speakers=" + Quickshell.hasThemeIcon("audio-speakers"));
    console.log("ICONCHECK speaker=" + Quickshell.hasThemeIcon("speaker"));
    Qt.quit();
  }
}
EOF
    out="$(timeout 8 qs -p "$tmp" 2>&1 || true)"
    grep -q 'ICONCHECK audio-speakers=true' <<<"$out" ||
        fail "Quickshell cannot resolve audio-speakers with the configured theme"
    grep -q 'ICONCHECK speaker=true' <<<"$out" ||
        fail "Quickshell cannot resolve speaker with the configured theme"
fi

if ((failures != 0)); then
    echo "$failures assertion(s) failed"
    exit 1
fi
echo "quickshell icon test passed"
