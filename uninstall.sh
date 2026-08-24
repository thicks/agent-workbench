#!/usr/bin/env bash
# Remove files listed in <target>/.agent-workbench-installed.txt
set -euo pipefail

TARGET="${1:-$PWD}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || { echo "Path not found: $TARGET" >&2; exit 1; }
LIST="$TARGET/.agent-workbench-installed.txt"

if [[ ! -f "$LIST" ]]; then
  echo "No install manifest at $LIST" >&2
  exit 1
fi

while IFS= read -r rel || [[ -n "$rel" ]]; do
  [[ -n "$rel" ]] || continue
  path="$TARGET/$rel"
  if [[ -e "$path" || -L "$path" ]]; then
    rm -rf "$path"
    echo "  removed: $rel"
  fi
done < "$LIST"

rm -f "$LIST"
echo "Uninstalled files recorded for $TARGET."
