#!/usr/bin/env bash
#
# install-principles.sh — install PRINCIPLES.md and ./skills for every repo.
#
#   ./install-principles.sh                  # principles for every harness + skills
#   ./install-principles.sh claude codex     # principles for these harnesses + skills
#
# Skills are personal and global. One symlink per skill, aimed at this clone, so
# every repo on the machine sees the same files. Re-run on each machine after
# cloning (paths differ). Re-run after adding or removing a skill. Edits inside
# a skill are live, because the agent reads through the symlink.
#
#   ~/.agents/skills/<name>   Cursor and Codex (canonical personal location)
#   ~/.claude/skills/<name>   Claude Code (does not read ~/.agents/skills)
#   ~/.cursor/skills/<name>   Cursor's own user dir; Cursor dedupes this with the other two
#
# ~/.codex/skills is intentionally not linked. Codex still scans it and would
# show a second copy of every skill already linked in ~/.agents/skills.
#
# Principles: Claude @imports this file, Codex gets a snapshot (re-run after
# edits), Cursor gets a user rule file. No clipboard — that cannot run on
# another machine.
#
# Override targets for testing:
#   CLAUDE_MD=/tmp/x CODEX_AGENTS=/tmp/y CURSOR_RULES=/tmp/z \
#   AGENTS_SKILLS=/tmp/a CLAUDE_SKILLS=/tmp/b CURSOR_SKILLS=/tmp/c \
#   ./install-principles.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRINCIPLES_FILE="$SCRIPT_DIR/PRINCIPLES.md"
SKILLS_DIR="$SCRIPT_DIR/skills"

CLAUDE_MD="${CLAUDE_MD:-$HOME/.claude/CLAUDE.md}"
CODEX_AGENTS="${CODEX_AGENTS:-$HOME/.codex/AGENTS.md}"
CURSOR_RULES="${CURSOR_RULES:-$HOME/.cursor/rules/mitya-principles.mdc}"

AGENTS_SKILLS="${AGENTS_SKILLS:-$HOME/.agents/skills}"
CLAUDE_SKILLS="${CLAUDE_SKILLS:-$HOME/.claude/skills}"
CURSOR_SKILLS="${CURSOR_SKILLS:-$HOME/.cursor/skills}"

BEGIN_MARKER='<!-- BEGIN mitya-principles (managed by install-principles.sh) -->'
END_MARKER='<!-- END mitya-principles -->'

# inject_block <target-file> <payload-text>
# Replaces the existing marker block in place, or appends one if absent.
inject_block() {
  local target="$1" payload="$2"
  mkdir -p "$(dirname "$target")"
  touch "$target"

  local blockfile tmp
  blockfile="$(mktemp)"
  tmp="$(mktemp)"
  {
    printf '%s\n' "$BEGIN_MARKER"
    printf '%s\n' "$payload"
    printf '%s\n' "$END_MARKER"
  } >"$blockfile"

  awk -v bmark="$BEGIN_MARKER" -v emark="$END_MARKER" -v blockfile="$blockfile" '
    function emit(   l) { while ((getline l < blockfile) > 0) print l; close(blockfile) }
    $0 == bmark { emit(); skip = 1; done = 1; next }
    $0 == emark { skip = 0; next }
    skip { next }
    { print }
    END { if (!done) { if (NR > 0) print ""; emit() } }
  ' "$target" >"$tmp" && mv "$tmp" "$target"

  rm -f "$blockfile"
}

# link_skill <source-dir> <dest-path>
# Points dest at source. Refuses to replace a real directory or file.
link_skill() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    ln -sfn "$src" "$dest"
    return 0
  fi
  if [ -e "$dest" ]; then
    echo "  skip $dest (exists and is not a symlink managed by this script)" >&2
    return 0
  fi
  ln -s "$src" "$dest"
}

# Drop symlinks this script created for skills that no longer exist in the clone.
# Leaves real directories and links that point somewhere else alone.
prune_stale_skills() {
  local root="$1" link target name
  [ -d "$root" ] || return 0
  for link in "$root"/*; do
    [ -L "$link" ] || continue
    target="$(readlink "$link")"
    case "$target" in
      "$SKILLS_DIR"/*)
        name="$(basename "$link")"
        if [ ! -d "$SKILLS_DIR/$name" ]; then
          rm "$link"
          echo "  removed stale $link"
        fi
        ;;
    esac
  done
}

install_skills() {
  local roots=("$AGENTS_SKILLS" "$CLAUDE_SKILLS" "$CURSOR_SKILLS")
  local root src name count=0

  [ -d "$SKILLS_DIR" ] || { echo "error: $SKILLS_DIR not found" >&2; exit 1; }

  for root in "${roots[@]}"; do
    mkdir -p "$root"
    prune_stale_skills "$root"
  done

  shopt -s nullglob
  for src in "$SKILLS_DIR"/*; do
    [ -d "$src" ] || continue
    [ -f "$src/SKILL.md" ] || continue
    name="$(basename "$src")"
    for root in "${roots[@]}"; do
      link_skill "$src" "$root/$name"
    done
    count=$((count + 1))
  done
  shopt -u nullglob

  echo "  skills  ->  $count skill(s) symlinked into:"
  echo "            $AGENTS_SKILLS"
  echo "            $CLAUDE_SKILLS"
  echo "            $CURSOR_SKILLS"
}

# --- harness registry -------------------------------------------------------
# Add a harness by writing install_<name>() and listing it in ALL_HARNESSES.

install_claude() {
  # Claude Code supports @import — link, don't copy, so edits to PRINCIPLES.md
  # are picked up live without re-running the installer.
  inject_block "$CLAUDE_MD" "@$PRINCIPLES_FILE"
  echo "  claude  ->  $CLAUDE_MD  (live @import)"
}

install_codex() {
  # Codex has no import syntax — embed a content snapshot. Re-run after editing.
  inject_block "$CODEX_AGENTS" "$(cat "$PRINCIPLES_FILE")"
  echo "  codex   ->  $CODEX_AGENTS  (snapshot — re-run after edits)"
}

install_cursor() {
  # User rules in ~/.cursor/rules apply across projects on this machine.
  # The file must be .mdc; a plain .md in this directory is ignored.
  mkdir -p "$(dirname "$CURSOR_RULES")"
  if [ ! -f "$CURSOR_RULES" ]; then
    cat >"$CURSOR_RULES" <<'EOF'
---
description: Engineering principles from mitya-skills
alwaysApply: true
---
EOF
  fi
  inject_block "$CURSOR_RULES" "$(cat "$PRINCIPLES_FILE")"
  echo "  cursor  ->  $CURSOR_RULES  (user rule, all projects on this machine)"
}

ALL_HARNESSES="claude codex cursor"

# --- dispatch ---------------------------------------------------------------
[ -f "$PRINCIPLES_FILE" ] || { echo "error: $PRINCIPLES_FILE not found" >&2; exit 1; }

targets=("$@")
if [ "${#targets[@]}" -eq 0 ] || [ "${targets[0]}" = "all" ]; then
  read -r -a targets <<<"$ALL_HARNESSES"
fi

echo "Installing principles from $PRINCIPLES_FILE"
for t in "${targets[@]}"; do
  if [ "$(type -t "install_$t" || true)" = "function" ]; then
    "install_$t"
  else
    echo "error: unknown harness '$t' (known: $ALL_HARNESSES)" >&2
    exit 1
  fi
done

echo "Installing skills from $SKILLS_DIR"
install_skills
