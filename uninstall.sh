#!/bin/bash
# Uninstall claude-keep-awake: unload the LaunchAgent and remove installed files.
# Logs at ~/Library/Logs/caffeinated-claude*.log are left in place.

set -u

LABEL="com.user.caffeinated-claude"
BIN_DIR="${HOME}/bin"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"

if [[ -f "$PLIST" ]]; then
  launchctl unload -w "$PLIST" 2>/dev/null && echo "unloaded: $LABEL"
  rm -f "$PLIST" && echo "removed:  $PLIST"
else
  echo "no plist at $PLIST"
fi

for f in "${BIN_DIR}/caffeinated-claude.sh" "${BIN_DIR}/caffeinated-claude-ctl"; do
  if [[ -f "$f" ]]; then
    rm -f "$f" && echo "removed:  $f"
  fi
done

echo "Done. (Logs left at ~/Library/Logs/caffeinated-claude*.log)"
