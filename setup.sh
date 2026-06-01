#!/bin/bash
# One-line deploy for claude-keep-awake.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/rahulrajsbkk/claude-keep-awake/main/setup.sh | bash
#
# Clones (or updates) the repo into ~/.local/share/claude-keep-awake and
# runs install.sh. Re-run any time to update.
#
# Overrides:
#   REPO_URL=...   git URL to clone from (default: this repo)
#   DEST=...       where to keep the local checkout
#   BRANCH=...     branch to track (default: main)
#   NO_GIT=1       force tarball download path even if git is installed

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/rahulrajsbkk/claude-keep-awake.git}"
TARBALL_URL="${TARBALL_URL:-https://github.com/rahulrajsbkk/claude-keep-awake/archive/refs/heads/main.tar.gz}"
DEST="${DEST:-${HOME}/.local/share/claude-keep-awake}"
BRANCH="${BRANCH:-main}"

echo "==> claude-keep-awake one-click deploy"

# Sanity checks
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: macOS only (uses launchctl + caffeinate). Detected: $(uname -s)" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"

if [[ -z "${NO_GIT:-}" ]] && command -v git >/dev/null 2>&1; then
  if [[ -d "$DEST/.git" ]]; then
    echo "==> updating existing clone at $DEST"
    git -C "$DEST" fetch --quiet origin "$BRANCH"
    git -C "$DEST" reset --hard "origin/${BRANCH}"
  else
    echo "==> cloning $REPO_URL into $DEST"
    rm -rf "$DEST"
    git clone --quiet --depth 1 --branch "$BRANCH" "$REPO_URL" "$DEST"
  fi
else
  echo "==> git not available (or NO_GIT set); downloading tarball"
  rm -rf "$DEST"
  mkdir -p "$DEST"
  curl -fsSL "$TARBALL_URL" | tar -xz -C "$DEST" --strip-components=1
fi

bash "$DEST/install.sh"

echo
echo "==> done. ${DEST} is the source of truth — re-run setup.sh any time to update."
