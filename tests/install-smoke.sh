#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

STD_TARGET=""
STD_TARGET2=""
ALL_TARGET=""
ICM_TARGET=""
ICM_ALL_TARGET=""

cleanup() {
  [[ -n "${STD_TARGET:-}" ]] && rm -rf "$STD_TARGET"
  [[ -n "${STD_TARGET2:-}" ]] && rm -rf "$STD_TARGET2"
  [[ -n "${ALL_TARGET:-}" ]] && rm -rf "$ALL_TARGET"
  [[ -n "${ICM_TARGET:-}" ]] && rm -rf "$ICM_TARGET"
  [[ -n "${ICM_ALL_TARGET:-}" ]] && rm -rf "$ICM_ALL_TARGET"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "missing file: $1"
}

# Source skill bodies start with "# Title — ...". Rendering must keep that heading
# and emit the canonical skill name in Claude/opencode frontmatter.
assert_contains() {
  local file="$1" needle="$2"
  grep -Fqe "$needle" "$file" || fail "expected '$needle' in $file"
}

skill_heading() {
  awk '/^---$/{c++; next} c>=2 && /^# /{print; exit}' "$1"
}

assert_claude_skill() {
  local src="$1" dest="$2" name="$3"
  local heading
  assert_file "$dest"
  assert_contains "$dest" "name: $name"
  heading="$(skill_heading "$src")"
  [[ -n "$heading" ]] || fail "no H1 heading in $src"
  assert_contains "$dest" "$heading"
}

require_safe_empty_target() {
  local target="$1"
  local resolved home_resolved
  resolved="$(cd "$target" && pwd)"
  home_resolved="$(cd "$HOME" && pwd)"

  if [[ "$resolved" == "$home_resolved" || "$resolved" == "$ROOT" ]]; then
    fail "refusing to install into \$HOME or repo root: $resolved"
  fi

  if [[ -n "$(ls -A "$target")" ]]; then
    fail "target is not empty before install: $target"
  fi
}

run_installer() {
  local script="$1"
  local target="$2"
  local tool="$3"
  printf '%s\n' "$target" "$tool" "y" | "$script"
}

# Portable C1 guard: GNU bash aborts on ((x++)) when x is 0 under set -e.
# macOS bash 3.2 does not, so inventory-only tests can false-green locally.
ban_arith_postincrement() {
  local f
  for f in "$ROOT/install.sh" "$ROOT/install-icm.sh"; do
    if grep -nE '\(\((file_count|skip_count)\+\+\)\)' "$f"; then
      fail "C1 regression in $f: remove dead ((count++)) under set -e; use no counters or count=\$((count + 1))"
    fi
  done
}
ban_arith_postincrement

# --- standard install.sh (Claude only) ---

STD_TARGET="$(mktemp -d)"
require_safe_empty_target "$STD_TARGET"

set +e
run_installer "$ROOT/install.sh" "$STD_TARGET" "1"
std_rc=$?
set -e

[[ "$std_rc" -eq 0 ]] || fail "install.sh exited $std_rc"

for src in "$ROOT/skills/"*.md; do
  name="$(basename "$src" .md)"
  assert_claude_skill "$src" "$STD_TARGET/.claude/skills/$name/SKILL.md" "$name"
done

for sub in agents commands rules; do
  for src in "$ROOT/adapters/claude/$sub"/*; do
    [[ -f "$src" ]] || continue
    assert_file "$STD_TARGET/.claude/$sub/$(basename "$src")"
  done
done

assert_file "$STD_TARGET/.claude/settings.json"
assert_file "$STD_TARGET/.claude/settings.local.json.example"

assert_file "$STD_TARGET/.claude/agents/task-executor.md"
assert_file "$STD_TARGET/.claude/commands/incept.md"
assert_file "$STD_TARGET/.claude/rules/30-artifact-dir.md"

# Second clean install into a fresh empty dir (regression: C1 can false-green on macOS).
STD_TARGET2="$(mktemp -d)"
require_safe_empty_target "$STD_TARGET2"

set +e
run_installer "$ROOT/install.sh" "$STD_TARGET2" "1"
std_rc2=$?
set -e

[[ "$std_rc2" -eq 0 ]] || fail "install.sh second run exited $std_rc2"
assert_file "$STD_TARGET2/.claude/agents/task-executor.md"

# --- standard install.sh (all tools) ---

ALL_TARGET="$(mktemp -d)"
require_safe_empty_target "$ALL_TARGET"

set +e
run_installer "$ROOT/install.sh" "$ALL_TARGET" "4"
all_rc=$?
set -e

[[ "$all_rc" -eq 0 ]] || fail "install.sh (all tools) exited $all_rc"

for src in "$ROOT/skills/"*.md; do
  name="$(basename "$src" .md)"
  heading="$(skill_heading "$src")"
  assert_claude_skill "$src" "$ALL_TARGET/.claude/skills/$name/SKILL.md" "$name"
  assert_file "$ALL_TARGET/.cursor/rules/${name}.mdc"
  assert_contains "$ALL_TARGET/.cursor/rules/${name}.mdc" "alwaysApply: false"
  assert_contains "$ALL_TARGET/.cursor/rules/${name}.mdc" "$heading"
  assert_file "$ALL_TARGET/.opencode/skills/${name}.md"
  assert_contains "$ALL_TARGET/.opencode/skills/${name}.md" "name: $name"
  assert_contains "$ALL_TARGET/.opencode/skills/${name}.md" "$heading"
done

assert_file "$ALL_TARGET/.cursorrules"
assert_file "$ALL_TARGET/.cursor/rules/30-artifact-dir.mdc"
assert_file "$ALL_TARGET/AGENTS.md"
assert_file "$ALL_TARGET/.opencode/instructions.md"

for src in "$ROOT/adapters/cursor/agents/"*; do
  [[ -f "$src" ]] || continue
  assert_file "$ALL_TARGET/.cursor/agents/$(basename "$src")"
done

for src in "$ROOT/adapters/opencode/agents/"*; do
  [[ -f "$src" ]] || continue
  assert_file "$ALL_TARGET/.opencode/agents/$(basename "$src")"
done

# --- install-icm.sh (Claude only) ---

ICM_TARGET="$(mktemp -d)"
require_safe_empty_target "$ICM_TARGET"

set +e
run_installer "$ROOT/install-icm.sh" "$ICM_TARGET" "1"
icm_rc=$?
set -e

[[ "$icm_rc" -eq 0 ]] || fail "install-icm.sh exited $icm_rc"

assert_file "$ICM_TARGET/CLAUDE.md"
assert_file "$ICM_TARGET/workflows/dev-workflow/WORKFLOW.md"

for src in "$ROOT/skills/"*.md; do
  assert_file "$ICM_TARGET/workflows/dev-workflow/skills/$(basename "$src")"
done

for src in "$ROOT/references/"*.md; do
  assert_file "$ICM_TARGET/workflows/dev-workflow/references/$(basename "$src")"
done

for src in "$ROOT/icm/adapters/claude/agents/"*; do
  [[ -f "$src" ]] || continue
  assert_file "$ICM_TARGET/.claude/agents/$(basename "$src")"
done

# --- install-icm.sh (all tools) ---

ICM_ALL_TARGET="$(mktemp -d)"
require_safe_empty_target "$ICM_ALL_TARGET"

set +e
run_installer "$ROOT/install-icm.sh" "$ICM_ALL_TARGET" "4"
icm_all_rc=$?
set -e

[[ "$icm_all_rc" -eq 0 ]] || fail "install-icm.sh (all tools) exited $icm_all_rc"

assert_file "$ICM_ALL_TARGET/CLAUDE.md"
assert_file "$ICM_ALL_TARGET/.cursorrules"
assert_file "$ICM_ALL_TARGET/.opencode/instructions.md"
for src in "$ROOT/skills/"*.md; do
  assert_file "$ICM_ALL_TARGET/workflows/dev-workflow/skills/$(basename "$src")"
done

echo "PASS: clean-install smoke test"
