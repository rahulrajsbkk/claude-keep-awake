#!/bin/bash
# claude-keep-awake watcher
# Holds a macOS idle-sleep assertion (via `caffeinate -i`) while any of the
# following are running:
#   - Claude Code VS Code extension     (anthropic.claude-code-*)
#   - Claude Code CLI (Homebrew cask)   (Caskroom/claude-code/*, /opt/homebrew/bin/claude, /usr/local/bin/claude)
#   - Claude desktop app                (/Applications/Claude.app/*)
#
# Override the match pattern with $CAFFEINATED_CLAUDE_PATTERN.
# Override the poll interval (seconds) with $CAFFEINATED_CLAUDE_INTERVAL.

set -u

LOG="${HOME}/Library/Logs/caffeinated-claude.log"
INTERVAL="${CAFFEINATED_CLAUDE_INTERVAL:-30}"
PATTERN="${CAFFEINATED_CLAUDE_PATTERN:-anthropic\.claude-code-|Caskroom/claude-code/|/opt/homebrew/bin/claude|/usr/local/bin/claude|/Applications/Claude\.app/}"

CAFF_PID=""

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"; }

release() {
  if [[ -n "$CAFF_PID" ]] && kill -0 "$CAFF_PID" 2>/dev/null; then
    kill "$CAFF_PID" 2>/dev/null
    log "released caffeinate (pid $CAFF_PID)"
  fi
  CAFF_PID=""
}

cleanup() { release; exit 0; }
trap cleanup INT TERM EXIT

mkdir -p "$(dirname "$LOG")"
log "watcher started (pid $$, interval ${INTERVAL}s)"

while true; do
  if pgrep -f "$PATTERN" >/dev/null 2>&1; then
    if [[ -z "$CAFF_PID" ]] || ! kill -0 "$CAFF_PID" 2>/dev/null; then
      /usr/bin/caffeinate -i &
      CAFF_PID=$!
      log "claude detected, holding caffeinate -i (pid $CAFF_PID)"
    fi
  else
    if [[ -n "$CAFF_PID" ]]; then
      release
    fi
  fi
  sleep "$INTERVAL"
done
