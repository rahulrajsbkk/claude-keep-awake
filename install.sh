#!/bin/bash
# Install claude-keep-awake: copy scripts into ~/bin, install a LaunchAgent,
# and load it so it runs at every login.
#
# Idempotent: safe to re-run to update.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
LABEL="com.user.caffeinated-claude"
BIN_DIR="${HOME}/bin"
AGENT_DIR="${HOME}/Library/LaunchAgents"
PLIST="${AGENT_DIR}/${LABEL}.plist"

echo "==> installing from ${REPO_DIR}"

mkdir -p "$BIN_DIR" "$AGENT_DIR" "${HOME}/Library/Logs"

# Copy and make executable
install -m 0755 "${REPO_DIR}/bin/caffeinated-claude.sh"   "${BIN_DIR}/caffeinated-claude.sh"
install -m 0755 "${REPO_DIR}/bin/caffeinated-claude-ctl"  "${BIN_DIR}/caffeinated-claude-ctl"
echo "    installed: ${BIN_DIR}/caffeinated-claude.sh"
echo "    installed: ${BIN_DIR}/caffeinated-claude-ctl"

# Render the plist with $HOME substituted
sed "s|__HOME__|${HOME}|g" "${REPO_DIR}/LaunchAgents/com.user.caffeinated-claude.plist" > "${PLIST}"
chmod 0644 "${PLIST}"
echo "    installed: ${PLIST}"

# (Re)load
if launchctl list | grep -q "${LABEL}"; then
  echo "==> reloading LaunchAgent"
  launchctl unload -w "${PLIST}" 2>/dev/null || true
fi
launchctl load -w "${PLIST}"
echo "==> loaded LaunchAgent ${LABEL}"

# Friendly status
sleep 1
if launchctl list | grep -q "${LABEL}"; then
  echo
  echo "Done. Check status any time with:"
  echo "  ${BIN_DIR}/caffeinated-claude-ctl status"
  echo
  echo "Make sure ${BIN_DIR} is on your \$PATH to call it as 'caffeinated-claude-ctl'."
else
  echo "WARNING: LaunchAgent did not show up in launchctl list. Check logs:"
  echo "  ~/Library/Logs/caffeinated-claude.err.log"
  exit 1
fi
