#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

STD_TARGET=""
STD_TARGET2=""
ALL_TARGET=""
SKIP_TARGET=""

cleanup() {
  [[ -n "${STD_TARGET:-}" ]] && rm -rf "$STD_TARGET"
  [[ -n "${STD_TARGET2:-}" ]] && rm -rf "$STD_TARGET2"
  [[ -n "${ALL_TARGET:-}" ]] && rm -rf "$ALL_TARGET"
  [[ -n "${SKIP_TARGET:-}" ]] && rm -rf "$SKIP_TARGET"
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

# Body after the first --- pair. Matches install.sh skill_body().
body_after_frontmatter() {
  awk '
    /^---$/ && done == 0 {
      c++
      if (c == 2) done = 1
      next
    }
    done { print }
  ' "$1" | sed '/./,$!d'
}

# Tools (Claude SKILL.md, Cursor .mdc, opencode skills) parse only the leading
# YAML document. A second --- inside that document would break loading.
assert_leading_frontmatter() {
  local file="$1"
  shift
  python3 - "$file" "$@" <<'PY'
import re, sys
from pathlib import Path
path = Path(sys.argv[1])
required = sys.argv[2:]
text = path.read_text()
match = re.match(r"^---\n(.*?)\n---\n", text, re.S)
if not match:
    raise SystemExit(f"no leading YAML frontmatter: {path}")
front = match.group(1)
if "\n---\n" in front or front.startswith("---\n") or front.endswith("\n---"):
    raise SystemExit(f"frontmatter is not a single YAML document: {path}")
for key in required:
    if not re.search(rf"^{re.escape(key)}:", front, re.M):
        raise SystemExit(f"missing {key}: in frontmatter of {path}")
PY
}

assert_skill_body_roundtrip() {
  local src="$1" dest="$2"
  local src_body dest_body
  src_body="$(body_after_frontmatter "$src")"
  dest_body="$(body_after_frontmatter "$dest")"
  [[ "$src_body" == "$dest_body" ]] || fail "rendered body dropped --- or other content: $dest vs $src"
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
  for f in "$ROOT/install.sh" "$ROOT/lib/install-common.sh" "$ROOT/skills-personal/install.sh"; do
    [[ -f "$f" ]] || fail "missing installer: $f"
    if grep -nE '\(\((file_count|skip_count)\+\+\)\)' "$f"; then
      fail "C1 regression in $f: remove dead ((count++)) under set -e; use no counters or count=\$((count + 1))"
    fi
  done
}
ban_arith_postincrement

# M3: helpers live in one place; entry points must source them, not copy them.
grep -Fqe 'source "$REPO_DIR/lib/install-common.sh"' "$ROOT/install.sh" || fail "M3: install.sh must source lib/install-common.sh"
grep -Fqe 'source "$REPO_DIR/lib/install-common.sh"' "$ROOT/skills-personal/install.sh" || fail "M3: skills-personal/install.sh must source lib/install-common.sh"
if grep -nE '^backup_if_exists\(\)|^install_file_safe\(\)|^install_dir_safe\(\)|^write_skill\(\)' "$ROOT/install.sh" "$ROOT/skills-personal/install.sh"; then
  fail "M3: do not duplicate install helpers outside lib/install-common.sh"
fi

# M2: declining a directory overwrite must not merge new files into it.
M2_SRC=""
M2_DST=""
M2_SRC="$(mktemp -d)"
M2_DST="$(mktemp -d)"
mkdir -p "$M2_SRC/nested" "$M2_DST/nested"
printf 'NEW\n' > "$M2_SRC/nested/new.txt"
printf 'OLD\n' > "$M2_DST/nested/old.txt"
# shellcheck source=lib/install-common.sh
source "$ROOT/lib/install-common.sh"
set +e
printf 'n\n' | install_dir_safe "$M2_SRC" "$M2_DST" "m2"
m2_rc=$?
set -e
[[ "$m2_rc" -eq 0 ]] || fail "M2: install_dir_safe skip exited $m2_rc"
grep -Fqe 'OLD' "$M2_DST/nested/old.txt" || fail "M2: skip replaced existing dir contents"
[[ ! -e "$M2_DST/nested/new.txt" ]] || fail "M2: skip merged new files into existing dir"
rm -rf "$M2_SRC" "$M2_DST"

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
  dest="$STD_TARGET/.claude/skills/$name/SKILL.md"
  assert_claude_skill "$src" "$dest" "$name"
  assert_leading_frontmatter "$dest" "name" "description"
  assert_skill_body_roundtrip "$src" "$dest"
done

# C2: incept's fenced spec template uses --- inside the body; those must survive.
assert_contains "$STD_TARGET/.claude/skills/incept/SKILL.md" $'```markdown\n---\ntitle: <Idea Name>'

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

# M7: second install into the same tree must be idempotent (cmp -s → unchanged).
set +e
idem_out="$(run_installer "$ROOT/install.sh" "$STD_TARGET" "1" 2>&1)"
idem_rc=$?
set -e
[[ "$idem_rc" -eq 0 ]] || fail "install.sh idempotent rerun exited $idem_rc"
if echo "$idem_out" | grep -E '^  (installed|rendered):'; then
  fail "M7: second install into the same dir wrote files (expected only unchanged)"
fi
echo "$idem_out" | grep -Fq 'unchanged:' || fail "M7: second install reported no unchanged files"

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
  dest_claude="$ALL_TARGET/.claude/skills/$name/SKILL.md"
  dest_cursor="$ALL_TARGET/.cursor/rules/${name}.mdc"
  dest_open="$ALL_TARGET/.opencode/skills/${name}.md"
  assert_claude_skill "$src" "$dest_claude" "$name"
  assert_leading_frontmatter "$dest_claude" "name" "description"
  assert_skill_body_roundtrip "$src" "$dest_claude"
  assert_file "$dest_cursor"
  assert_leading_frontmatter "$dest_cursor" "description" "alwaysApply"
  assert_contains "$dest_cursor" "alwaysApply: false"
  assert_contains "$dest_cursor" "$heading"
  assert_skill_body_roundtrip "$src" "$dest_cursor"
  assert_file "$dest_open"
  assert_leading_frontmatter "$dest_open" "name" "description"
  assert_contains "$dest_open" "name: $name"
  assert_contains "$dest_open" "$heading"
  assert_skill_body_roundtrip "$src" "$dest_open"
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

# M1: ICM packaging was removed; do not reintroduce a second installer.
[[ ! -e "$ROOT/install-icm.sh" ]] || fail "M1: install-icm.sh should not exist"
[[ ! -e "$ROOT/icm" ]] || fail "M1: icm/ should not exist"

# C3: skipping one overwrite must not abort the rest of the install (set -e).
SKIP_TARGET="$(mktemp -d)"
require_safe_empty_target "$SKIP_TARGET"
mkdir -p "$SKIP_TARGET/.claude/skills/code-review"
printf 'OLD-SKILL\n' > "$SKIP_TARGET/.claude/skills/code-review/SKILL.md"
set +e
printf '%s\n' "$SKIP_TARGET" "1" "y" "n" | "$ROOT/install.sh"
skip_rc=$?
set -e
[[ "$skip_rc" -eq 0 ]] || fail "install.sh exited $skip_rc after skip (C3)"
grep -Fqe 'OLD-SKILL' "$SKIP_TARGET/.claude/skills/code-review/SKILL.md" || fail "skipped skill was overwritten"
assert_file "$SKIP_TARGET/.claude/skills/incept/SKILL.md"
assert_file "$SKIP_TARGET/.claude/agents/task-executor.md"
assert_file "$SKIP_TARGET/.claude/settings.json"

echo "PASS: clean-install smoke test"
