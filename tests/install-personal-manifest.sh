#!/usr/bin/env bash
# Manifest-driven personal skills. Separate from tests/install-smoke.sh,
# which only covers canonical skills/*.md.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/skills-personal/manifest.json"
STD_TARGET=""
STANDALONE_TARGET=""

cleanup() {
  [[ -n "${STD_TARGET:-}" ]] && rm -rf "$STD_TARGET"
  [[ -n "${STANDALONE_TARGET:-}" ]] && rm -rf "$STANDALONE_TARGET"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "missing file: $1"
}

refuse_home_or_repo() {
  local resolved home_resolved
  resolved="$(cd "$1" && pwd)"
  home_resolved="$(cd "$HOME" && pwd)"
  [[ "$resolved" != "$home_resolved" && "$resolved" != "$ROOT" ]] || fail "refusing HOME or repo"
}

manifest_entries() {
  python3 - "$MANIFEST" <<'PY'
import json, sys
from pathlib import Path
manifest = json.loads(Path(sys.argv[1]).read_text())
for entry in manifest.get("skills", []):
    print("{}\t{}\t{}\t{}".format(
        entry.get("source", "remote"),
        entry["skill"],
        entry.get("path", entry["skill"]),
        entry.get("file", "SKILL.md"),
    ))
PY
}

assert_local_claude_from_manifest() {
  local target="$1"
  local name rel filename src dest extra
  local_count=0
  assert_file "$target/skills-personal/manifest.json"
  while IFS=$'\t' read -r source name rel filename; do
    [[ -n "$name" ]] || continue
    [[ "$source" == "local" ]] || continue
    src="$ROOT/skills-personal/$rel/$filename"
    dest="$target/.claude/skills/$name/$(basename "$filename")"
    [[ -f "$src" ]] || fail "manifest lists $name but source missing: $src"
    assert_file "$dest"
    grep -Fqe "name: $name" "$dest" || fail "expected name: $name in $dest"
    for extra in "$ROOT/skills-personal/$rel"/*; do
      [[ -f "$extra" ]] || continue
      assert_file "$target/.claude/skills/$name/$(basename "$extra")"
    done
    local_count=$((local_count + 1))
  done < <(manifest_entries)
  [[ "$local_count" -gt 0 ]] || fail "manifest contained no local skills"
}

[[ -f "$MANIFEST" ]] || fail "missing $MANIFEST"
command -v python3 >/dev/null 2>&1 || fail "python3 required to read the manifest"

# --- install.sh still installs local manifest skills ---
STD_TARGET="$(mktemp -d)"
refuse_home_or_repo "$STD_TARGET"
set +e
"$ROOT/install.sh" --yes --target "$STD_TARGET" --tool 1
std_rc=$?
set -e
[[ "$std_rc" -eq 0 ]] || fail "install.sh exited $std_rc"
assert_local_claude_from_manifest "$STD_TARGET"

# --- standalone skills-personal/install.sh ---
STANDALONE_TARGET="$(mktemp -d)"
refuse_home_or_repo "$STANDALONE_TARGET"
set +e
NONINTERACTIVE=1 TARGET="$STANDALONE_TARGET" "$ROOT/skills-personal/install.sh"
standalone_rc=$?
set -e
[[ "$standalone_rc" -eq 0 ]] || fail "skills-personal/install.sh exited $standalone_rc"
assert_local_claude_from_manifest "$STANDALONE_TARGET"

# C4: prompts must not share stdin with the manifest stream.
grep -Fqe '/dev/tty' "$ROOT/skills-personal/install.sh" || fail "C4: prompts must read from /dev/tty"
if grep -E 'jq .+\| while read' "$ROOT/skills-personal/install.sh"; then
  fail "C4: do not pipe jq into the prompt loop"
fi

# C4: unpinned remotes are refused in noninteractive mode (no silent clone of HEAD).
UNPINNED_TARGET="$(mktemp -d)"
refuse_home_or_repo "$UNPINNED_TARGET"
UNPINNED_MANIFEST="$UNPINNED_TARGET/manifest.json"
python3 - "$UNPINNED_MANIFEST" <<'PY'
from pathlib import Path
import json, sys
Path(sys.argv[1]).write_text(json.dumps({
    "skills": [{
        "skill": "unpinned-example",
        "source": "remote",
        "repo": "https://example.invalid/repo.git",
        "file": "SKILL.md",
    }]
}))
PY
set +e
INSTALL_REMOTE=1 NONINTERACTIVE=1 TARGET="$UNPINNED_TARGET" \
  MANIFEST_FILE="$UNPINNED_MANIFEST" "$ROOT/skills-personal/install.sh" >"$UNPINNED_TARGET/out.txt" 2>&1
unpinned_rc=$?
set -e
[[ "$unpinned_rc" -ne 0 ]] || fail "C4: INSTALL_REMOTE=1 without sha should fail"
grep -Fqe 'unpinned remote' "$UNPINNED_TARGET/out.txt" || fail "C4: expected unpinned remote error"
rm -rf "$UNPINNED_TARGET"

echo "PASS: personal-manifest install"
