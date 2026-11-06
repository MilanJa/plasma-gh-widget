#!/usr/bin/env bash
# Install or update the widget for the current user.
set -euo pipefail
cd "$(dirname "$0")"
ID=dev.milan.ghwidget

for cmd in kpackagetool6 gh jq; do
  command -v "$cmd" >/dev/null || { echo "Missing: $cmd" >&2; exit 1; }
done

if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$ID"; then
  kpackagetool6 -t Plasma/Applet -u package
  echo "Updated. Restart Plasma to reload: systemctl --user restart plasma-plasmashell"
else
  kpackagetool6 -t Plasma/Applet -i package
  echo "Installed. Add it via right-click → Add or Manage Widgets… → \"GitHub PRs\""
fi
