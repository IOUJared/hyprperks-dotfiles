#!/usr/bin/env bash
# Regression test for the monitor-selection settings UI. The category files
# called an unqualified fromCommaList(), which threw ReferenceError and
# dropped every edit made through the monitor/MPRIS text fields.
set -euo pipefail

dotfiles_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
qml_dir="$dotfiles_dir/quickshell"
failures=0

fail() {
    echo "FAIL $*"
    failures=$((failures + 1))
}

grep -q 'function fromCommaList' "$qml_dir/config/Config.qml" ||
    fail "Config.qml does not define fromCommaList"

# Every use must go through the Config singleton.
if grep -rnE '(^|[^.A-Za-z])fromCommaList\(' "$qml_dir/settings/categories" |
    grep -vE 'C\.Config\.fromCommaList'; then
    fail "settings categories call fromCommaList unqualified"
fi

# The fork's bar belongs on DP-1 only.
grep -q 'monitorChoiceMode: 1' "$qml_dir/config/Config.qml" ||
    fail "default monitor choice mode is not include"
grep -q 'includedMonitors: \["DP-1"\]' "$qml_dir/config/Config.qml" ||
    fail "default included monitor is not DP-1"

# Enter must commit the text field and be consumed, or TextEdit inserts a newline.
grep -q 'Qt.Key_Return || event.key == Qt.Key_Enter' \
    "$qml_dir/settings/categories/settings/TextValue.qml" ||
    fail "TextValue does not handle Enter"

if ((failures != 0)); then
    echo "$failures assertion(s) failed"
    exit 1
fi
echo "quickshell settings test passed"
