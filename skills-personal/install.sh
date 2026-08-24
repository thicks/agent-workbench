#!/usr/bin/env bash
# Install skills listed in skills-personal/manifest.json.
# Local entries are copied from this tree. Remote entries are cloned only when
# INSTALL_REMOTE=1. NONINTERACTIVE=1 installs every local skill without prompts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST_FILE="$SCRIPT_DIR/manifest.json"
TARGET="${TARGET:-$PWD}"
SKILLS_DIR="${SKILLS_DIR:-$TARGET/.claude/skills}"
NONINTERACTIVE="${NONINTERACTIVE:-0}"
INSTALL_REMOTE="${INSTALL_REMOTE:-0}"

if [[ ! -f "$MANIFEST_FILE" ]]; then
  echo "Error: manifest.json not found at $MANIFEST_FILE" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required to read $MANIFEST_FILE" >&2
  exit 1
fi

echo "Skill Installation Manager (manifest)"
echo "====================================="
echo

mkdir -p "$TARGET/skills-personal"
cp "$MANIFEST_FILE" "$TARGET/skills-personal/manifest.json"
echo "  installed: skills-personal/manifest.json"

install_local() {
  local name="$1" rel="$2" file="$3"
  local src_dir="$SCRIPT_DIR/$rel"
  local src="$src_dir/$file"
  local dest_dir="$SKILLS_DIR/$name"
  local extra

  if [[ ! -f "$src" ]]; then
    echo "  missing local skill file: $src" >&2
    return 1
  fi

  mkdir -p "$dest_dir"
  cp "$src" "$dest_dir/$(basename "$file")"
  echo "  installed: $dest_dir/$(basename "$file")"

  for extra in "$src_dir"/*; do
    [[ -f "$extra" ]] || continue
    [[ "$(basename "$extra")" == "$(basename "$file")" ]] && continue
    cp "$extra" "$dest_dir/$(basename "$extra")"
    echo "  installed: $dest_dir/$(basename "$extra")"
  done
}

install_remote() {
  local name="$1" repo="$2" file="$3"
  local temp_dir

  if [[ -z "$repo" || "$repo" == "null" ]]; then
    echo "  skip remote $name: no repo"
    return 0
  fi

  temp_dir="$(mktemp -d)"
  if ! git clone --depth 1 "$repo" "$temp_dir"; then
    rm -rf "$temp_dir"
    echo "  failed to clone $repo" >&2
    return 1
  fi
  if [[ ! -f "$temp_dir/$file" ]]; then
    rm -rf "$temp_dir"
    echo "  file not found: $file in $repo" >&2
    return 1
  fi
  mkdir -p "$SKILLS_DIR/$name"
  cp "$temp_dir/$file" "$SKILLS_DIR/$name/$(basename "$file")"
  echo "  installed: $SKILLS_DIR/$name/$(basename "$file") (remote)"
  rm -rf "$temp_dir"
}

while IFS=$'\t' read -r source name rel file repo; do
  [[ -n "$name" ]] || continue
  echo "  manifest: $name ($source)"

  if [[ "$source" == "local" ]]; then
    if [[ "$NONINTERACTIVE" == "1" ]]; then
      install_local "$name" "$rel" "$file"
      continue
    fi
    read -r -p "  Install $name? [y/N] " resp </dev/tty || resp="n"
    [[ "$resp" =~ ^[Yy]$ ]] && install_local "$name" "$rel" "$file"
    continue
  fi

  if [[ "$NONINTERACTIVE" == "1" && "$INSTALL_REMOTE" != "1" ]]; then
    echo "  skipped remote: $name"
    continue
  fi

  if [[ "$NONINTERACTIVE" == "1" ]]; then
    install_remote "$name" "$repo" "$file"
    continue
  fi
  read -r -p "  Install remote $name from $repo? [y/N] " resp </dev/tty || resp="n"
  [[ "$resp" =~ ^[Yy]$ ]] && install_remote "$name" "$repo" "$file"
done < <(python3 - "$MANIFEST_FILE" <<'PY'
import json, sys
from pathlib import Path
manifest = json.loads(Path(sys.argv[1]).read_text())
for entry in manifest.get("skills", []):
    source = entry.get("source", "remote")
    name = entry["skill"]
    rel = entry.get("path", name)
    filename = entry.get("file", "SKILL.md")
    repo = entry.get("repo") or ""
    print(f"{source}\t{name}\t{rel}\t{filename}\t{repo}")
PY
)

echo
echo "Done. Manifest skills installed under $SKILLS_DIR"
