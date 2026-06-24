#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${SOURCE_DIR:-$HOME/.agents/skills}"
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$REPO_DIR/skills"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Source skills directory does not exist: $SOURCE_DIR" >&2
  exit 1
fi

if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "This script must live at the root of the mitya-skills git repo." >&2
  exit 1
fi

if [[ "$TARGET_DIR" != "$REPO_DIR/skills" ]]; then
  echo "Refusing to remove unexpected target directory: $TARGET_DIR" >&2
  exit 1
fi

echo "Replacing $TARGET_DIR with $SOURCE_DIR"
rm -rf -- "$TARGET_DIR"
cp -a -- "$SOURCE_DIR" "$TARGET_DIR"

echo
echo "Update complete. Review changes with:"
echo "  cd \"$REPO_DIR\""
echo "  git status"
echo "  git diff"
