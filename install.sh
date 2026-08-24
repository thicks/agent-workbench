#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/install-common.sh
source "$REPO_DIR/lib/install-common.sh"

echo "agent-workbench — install"
echo "==================================="
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
echo "Will install into $TARGET."
echo "Existing files will be backed up to *.bak before overwrite."
read -rp "Proceed? [y/N] " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

PERSONAL_DIR="$REPO_DIR/skills-personal"
PERSONAL_MANIFEST="$PERSONAL_DIR/manifest.json"

# Local personal skills are directories with SKILL.md listed in the manifest.
# Remote manifest entries are not cloned here (sandbox/offline safe).
each_local_personal_skill() {
  local dir name
  [[ -f "$PERSONAL_MANIFEST" ]] || return 0
  for dir in "$PERSONAL_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"
    [[ -f "$dir/SKILL.md" ]] || continue
    grep -q "\"skill\": \"$name\"" "$PERSONAL_MANIFEST" || continue
    printf '%s\n' "$name"
  done
}

install_personal_manifest() {
  [[ -f "$PERSONAL_MANIFEST" ]] || return 0
  mkdir -p "$TARGET/skills-personal"
  ok_or_skip install_file_safe "$PERSONAL_MANIFEST" "$TARGET/skills-personal/manifest.json" "skills-personal/manifest.json"
}

install_personal_claude() {
  local name src dest_dir extra
  install_personal_manifest
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    src="$PERSONAL_DIR/$name/SKILL.md"
    dest_dir="$TARGET/.claude/skills/$name"
    mkdir -p "$dest_dir"
    ok_or_skip install_file_safe "$src" "$dest_dir/SKILL.md" ".claude/skills/$name/SKILL.md"
    for extra in "$PERSONAL_DIR/$name"/*; do
      [[ -f "$extra" ]] || continue
      [[ "$(basename "$extra")" == "SKILL.md" ]] && continue
      ok_or_skip install_file_safe "$extra" "$dest_dir/$(basename "$extra")" ".claude/skills/$name/$(basename "$extra")"
    done
  done < <(each_local_personal_skill)
}

install_personal_cursor() {
  local name src
  install_personal_manifest
  mkdir -p "$TARGET/.cursor/rules"
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    src="$PERSONAL_DIR/$name/SKILL.md"
    ok_or_skip write_skill "$TARGET/.cursor/rules/${name}.mdc" ".cursor/rules/${name}.mdc" "$(skill_body "$src")" \
      "description: $(skill_field "$src" description)" "alwaysApply: false"
  done < <(each_local_personal_skill)
}

install_personal_opencode() {
  local name src
  install_personal_manifest
  mkdir -p "$TARGET/.opencode/skills"
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    src="$PERSONAL_DIR/$name/SKILL.md"
    ok_or_skip write_skill "$TARGET/.opencode/skills/${name}.md" ".opencode/skills/${name}.md" "$(skill_body "$src")" \
      "name: $(skill_field "$src" name)" "description: $(skill_field "$src" description)"
  done < <(each_local_personal_skill)
}

install_claude() {
  echo
  echo "Installing Claude Code adapter..."
  mkdir -p "$TARGET/.claude/skills"

  # Render each SKILL.md: full frontmatter (name, description, allowed-tools)
  for src in "$REPO_DIR/skills/"*.md; do
    name="$(basename "$src" .md)"
    lines=("name: $(skill_field "$src" name)" "description: $(skill_field "$src" description)")
    allowed="$(skill_field "$src" allowed-tools)"
    [[ -n "$allowed" ]] && lines+=("allowed-tools: $allowed")
    ok_or_skip write_skill "$TARGET/.claude/skills/$name/SKILL.md" ".claude/skills/$name/SKILL.md" "$(skill_body "$src")" "${lines[@]}"
  done

  # Copy agents, commands, rules
  for sub in agents commands rules; do
    if [[ -d "$REPO_DIR/adapters/claude/$sub" ]]; then
      install_dir_safe "$REPO_DIR/adapters/claude/$sub" "$TARGET/.claude/$sub" ".claude/$sub"
    fi
  done

  # Copy settings files
  ok_or_skip install_file_safe "$REPO_DIR/adapters/claude/settings.json" "$TARGET/.claude/settings.json" ".claude/settings.json"

  if [[ -f "$REPO_DIR/adapters/claude/settings.local.json.example" ]]; then
    ok_or_skip install_file_safe "$REPO_DIR/adapters/claude/settings.local.json.example" "$TARGET/.claude/settings.local.json.example" ".claude/settings.local.json.example"
  fi

  install_personal_claude
}

install_cursor() {
  echo
  echo "Installing Cursor adapter..."
  ok_or_skip install_file_safe "$REPO_DIR/adapters/cursor/.cursorrules" "$TARGET/.cursorrules" ".cursorrules"

  mkdir -p "$TARGET/.cursor/rules"
  install_dir_safe "$REPO_DIR/adapters/cursor/agents" "$TARGET/.cursor/agents" ".cursor/agents"
  ok_or_skip install_file_safe "$REPO_DIR/adapters/claude/rules/30-artifact-dir.md" "$TARGET/.cursor/rules/30-artifact-dir.mdc" ".cursor/rules/30-artifact-dir.mdc"

  # Render each skill as a Cursor rule: description + alwaysApply
  for src in "$REPO_DIR/skills/"*.md; do
    name="$(basename "$src" .md)"
    lines=("description: $(skill_field "$src" description)" "alwaysApply: false")
    ok_or_skip write_skill "$TARGET/.cursor/rules/$name.mdc" ".cursor/rules/$name.mdc" "$(skill_body "$src")" "${lines[@]}"
  done

  install_personal_cursor
}

install_opencode() {
  echo
  echo "Installing opencode adapter..."
  ok_or_skip install_file_safe "$REPO_DIR/adapters/opencode/AGENTS.md" "$TARGET/AGENTS.md" "AGENTS.md"

  mkdir -p "$TARGET/.opencode/skills"
  install_dir_safe "$REPO_DIR/adapters/opencode/agents" "$TARGET/.opencode/agents" ".opencode/agents"
  ok_or_skip install_file_safe "$REPO_DIR/adapters/opencode/instructions.md" "$TARGET/.opencode/instructions.md" ".opencode/instructions.md"

  # Render each skill as an opencode skill: name + description
  for src in "$REPO_DIR/skills/"*.md; do
    name="$(basename "$src" .md)"
    lines=("name: $(skill_field "$src" name)" "description: $(skill_field "$src" description)")
    ok_or_skip write_skill "$TARGET/.opencode/skills/$name.md" ".opencode/skills/$name.md" "$(skill_body "$src")" "${lines[@]}"
  done

  install_personal_opencode
}

case "$TOOL" in
  1) install_claude ;;
  2) install_cursor ;;
  3) install_opencode ;;
  4) install_claude; install_cursor; install_opencode ;;
  *) echo "Invalid choice"; exit 1 ;;
esac

echo
echo "Done. agent-workbench installed at $TARGET."
echo "Set \$ARTIFACT_DIR via .claude/settings.local.json, project .env, or your shell."

if [[ -d "$TARGET/.git" && -f "$REPO_DIR/hooks/pre-push" ]]; then
  mkdir -p "$TARGET/.git/hooks"
  ok_or_skip install_file_safe "$REPO_DIR/hooks/pre-push" "$TARGET/.git/hooks/pre-push" ".git/hooks/pre-push"
  if [[ -f "$TARGET/.git/hooks/pre-push" ]]; then
    chmod +x "$TARGET/.git/hooks/pre-push" || true
  fi
fi
