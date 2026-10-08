#!/usr/bin/env bash
#
# sync-skills.sh — pull the latest skills/principles and re-link them.
#
# Meant to run unattended from cron/launchd, once a day, on every machine
# that clones this repo. Logs to _debug/ per this repo's own PRINCIPLES.md
# convention, so a failed run is visible without needing a live session.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANCH="$(git -C "$SCRIPT_DIR" rev-parse --abbrev-ref HEAD)"

WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$WORKSPACE_ROOT/_debug/mitya-skills-sync"
LOG_FILE="$LOG_DIR/sync.log"
mkdir -p "$LOG_DIR"

{
  echo "=== $(date -Iseconds) ==="
  cd "$SCRIPT_DIR"
  git pull --ff-only origin "$BRANCH"
  ./install-principles.sh
  echo "ok"
} >>"$LOG_FILE" 2>&1
