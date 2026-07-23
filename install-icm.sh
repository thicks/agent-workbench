#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICM_DIR="$REPO_DIR/icm"

echo "agent-workbench — ICM install"
echo "=============================="
echo

read -rp "Target project path [$HOME]: " TARGET
TARGET="${TARGET:-$HOME}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || { echo "Path not found: $TARGET"; exit 1; }

echo
echo "Which tool(s)?"
echo "  1) Claude Code"
echo "  2) Cursor"
echo "  3) opencode"
echo "  4) All"
read -rp "> [4] " TOOL
TOOL="${TOOL:-4}"

echo
echo "Will install ICM variant into $TARGET."
echo "Existing files will be backed up to *.bak before overwrite."
read -rp "Proceed? [y/N] " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

backup_if_exists() {
  if [[ -e "$1" ]]; then
    cp -R "$1" "${1}.bak"
    echo "  backed up: $1"
  fi
}

prompt_overwrite() {
  local target="$1"
  local description="$2"
  echo "  ⚠ $description already exists at $target"
  read -rp "  Overwrite? [y/N/b=backup only] " resp
  case "$resp" in
    [Yy]) return 0 ;;
    [Bb]) backup_if_exists "$target"; return 1 ;;
    *) echo "  skipped"; return 1 ;;
  esac
}

install_file_safe() {
  local src="$1"
  local dest="$2"
  local desc="${3:-$(basename "$dest")}"

  if [[ -e "$dest" ]]; then
    if cmp -s "$src" "$dest"; then
      echo "  unchanged: $desc"
      return 0
    fi
    prompt_overwrite "$dest" "$desc" || return 1
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "  installed: $desc"
}

install_dir_safe() {
  local src_dir="$1"
  local dest_dir="$2"
  local desc="$3"

  if [[ ! -d "$src_dir" ]]; then
    return 0
  fi

  mkdir -p "$dest_dir"
  local file_count=0
  local skip_count=0

  for src_file in "$src_dir"/*; do
    local filename="$(basename "$src_file")"
    local dest_file="$dest_dir/$filename"

    if [[ -d "$src_file" ]]; then
      # Recursive for subdirectories
      if [[ -d "$dest_file" ]]; then
        prompt_overwrite "$dest_file" "$desc/$filename" || { ((skip_count++)); continue; }
        rm -rf "$dest_file"
      fi
      cp -R "$src_file" "$dest_file"
      echo "  installed: $desc/$filename/"
    else
      if install_file_safe "$src_file" "$dest_file" "$desc/$filename"; then
        ((file_count++))
      else
        ((skip_count++))
      fi
    fi
  done
}

# The workflows/ tree is installed — it's the heart of the ICM variant
if [[ -d "$TARGET/workflows" ]]; then
  prompt_overwrite "$TARGET/workflows" "workflows/" || backup_if_exists "$TARGET/workflows"
fi
if [[ ! -d "$TARGET/workflows" ]]; then
  cp -R "$ICM_DIR/workflows" "$TARGET/workflows"
  echo "  installed: workflows/"
else
  # If target workflows exist, safely merge in structural files
  install_dir_safe "$ICM_DIR/workflows" "$TARGET/workflows" "workflows"
fi

# Assemble skills and references from repo-root canonical sources
mkdir -p "$TARGET/workflows/dev-workflow/skills"
for skill_file in "$REPO_DIR/skills/"*.md; do
  filename="$(basename "$skill_file")"
  install_file_safe "$skill_file" "$TARGET/workflows/dev-workflow/skills/$filename" "workflows/dev-workflow/skills/$filename"
done

mkdir -p "$TARGET/workflows/dev-workflow/references"
for ref_file in "$REPO_DIR/references/"*.md; do
  filename="$(basename "$ref_file")"
  install_file_safe "$ref_file" "$TARGET/workflows/dev-workflow/references/$filename" "workflows/dev-workflow/references/$filename"
done

install_claude() {
  echo
  echo "Installing Claude Code adapter..."
  mkdir -p "$TARGET/.claude/agents"

  install_dir_safe "$ICM_DIR/adapters/claude/agents" "$TARGET/.claude/agents" ".claude/agents"

  install_file_safe "$ICM_DIR/adapters/claude/CLAUDE.md" "$TARGET/CLAUDE.md" "CLAUDE.md"
}

install_cursor() {
  echo
  echo "Installing Cursor adapter..."
  install_file_safe "$ICM_DIR/adapters/cursor/.cursorrules" "$TARGET/.cursorrules" ".cursorrules"
}

install_opencode() {
  echo
  echo "Installing opencode adapter..."
  mkdir -p "$TARGET/.opencode"
  install_file_safe "$ICM_DIR/adapters/opencode/instructions.md" "$TARGET/.opencode/instructions.md" ".opencode/instructions.md"
}

case "$TOOL" in
  1) install_claude ;;
  2) install_cursor ;;
  3) install_opencode ;;
  4) install_claude; install_cursor; install_opencode ;;
  *) echo "Invalid choice"; exit 1 ;;
esac

echo
echo "Done. ICM agent-workbench installed at $TARGET."
echo "Read $TARGET/workflows/dev-workflow/WORKFLOW.md to start."
echo "Set \$ARTIFACT_DIR via .claude/settings.local.json, project .env, or your shell."
