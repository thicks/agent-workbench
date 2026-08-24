#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "agent-workbench — standard install"
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
echo "Will install standard variant into $TARGET."
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
    [Bb]) backup_if_exists "$target"; return 2 ;;
    *) echo "  skipped"; return 2 ;;
  esac
}

# 0 = installed/unchanged, 2 = user skipped, 1 = real failure.
# Skip must not trip set -e at bare call sites.
ok_or_skip() {
  local st=0
  "$@" || st=$?
  [[ "$st" -eq 0 || "$st" -eq 2 ]]
}

install_file_safe() {
  local src="$1"
  local dest="$2"
  local desc="${3:-$(basename "$dest")}"
  local st=0

  if [[ ! -f "$src" ]]; then
    echo "  missing source: $src" >&2
    return 1
  fi

  if [[ -e "$dest" ]]; then
    if cmp -s "$src" "$dest"; then
      echo "  unchanged: $desc"
      return 0
    fi
    prompt_overwrite "$dest" "$desc" || {
      st=$?
      [[ "$st" -eq 2 ]] && return 2
      return "$st"
    }
  fi

  mkdir -p "$(dirname "$dest")" || return 1
  cp "$src" "$dest" || return 1
  echo "  installed: $desc"
}

# Skill bodies (skills/<name>.md) carry their own tool-neutral frontmatter
# (name, description, allowed-tools). Each tool renders only the fields it
# needs into its native frontmatter shape via write_skill below.

skill_field() {
  local file="$1" field="$2"
  awk -v f="$field" '
    /^---$/ { c++; next }
    c==1 && $0 ~ "^" f ":" {
      sub("^" f ": *", "", $0)
      print $0
      exit
    }
  ' "$file"
}

skill_body() {
  # Drop only the opening YAML frontmatter (first two --- lines). Later ---
  # lines are section rules or fenced examples and must be kept so tools still
  # see a single leading frontmatter pair plus the original body.
  awk '
    /^---$/ && done == 0 {
      c++
      if (c == 2) done = 1
      next
    }
    done { print }
  ' "$1" | sed '/./,$!d'
}

# write_skill <dest> <label> <body> <frontmatter-line>...
write_skill() {
  local dest="$1" label="$2" body="$3"; shift 3
  local st=0

  mkdir -p "$(dirname "$dest")" || return 1
  local tmp_file
  tmp_file=$(mktemp)
  {
    echo "---"
    printf '%s\n' "$@"
    echo "---"
    echo
    printf '%s\n' "$body"
  } > "$tmp_file"

  if [[ -e "$dest" ]]; then
    if cmp -s "$tmp_file" "$dest"; then
      echo "  unchanged: $label"
      rm "$tmp_file"
      return 0
    fi
    prompt_overwrite "$dest" "$label" || {
      st=$?
      rm -f "$tmp_file"
      [[ "$st" -eq 2 ]] && return 2
      return "$st"
    }
  fi

  mv "$tmp_file" "$dest" || return 1
  echo "  rendered: $label"
}

install_dir_safe() {
  local src_dir="$1"
  local dest_dir="$2"
  local desc="$3"

  if [[ ! -d "$src_dir" ]]; then
    return 0
  fi

  mkdir -p "$dest_dir"

  for src_file in "$src_dir"/*; do
    local filename="$(basename "$src_file")"
    local dest_file="$dest_dir/$filename"

    if [[ -d "$src_file" ]]; then
      # Recursive for subdirectories
      if [[ -d "$dest_file" ]]; then
        prompt_overwrite "$dest_file" "$desc/$filename" || continue
        rm -rf "$dest_file"
      fi
      cp -R "$src_file" "$dest_file" || return 1
      echo "  installed: $desc/$filename/"
    else
      ok_or_skip install_file_safe "$src_file" "$dest_file" "$desc/$filename"
    fi
  done
}

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
echo "Done. Standard agent-workbench installed at $TARGET."
echo "Set \$ARTIFACT_DIR via .claude/settings.local.json, project .env, or your shell."
