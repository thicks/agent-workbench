#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/skills-personal/systematic-debugging/find-polluter.sh"
WORKDIR=""

cleanup() {
  [[ -n "${WORKDIR:-}" ]] && rm -rf "$WORKDIR"
}
trap cleanup EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

WORKDIR="$(mktemp -d)"
mkdir -p "$WORKDIR/src"
printf 'ok\n' > "$WORKDIR/src/clean.test.ts"
printf 'pollute\n' > "$WORKDIR/src/pollute.test.ts"

runner="$WORKDIR/run.sh"
cat > "$runner" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# Create .git only when the test file name contains "pollute".
if [[ "$1" == *pollute* ]]; then
  mkdir -p .git
fi
EOF
chmod +x "$runner"

# N1: empty match is an error, not success.
cd "$WORKDIR"
set +e
"$SCRIPT" .git 'nomatch.test.ts' >"$WORKDIR/empty.out" 2>&1
empty_rc=$?
set -e
[[ "$empty_rc" -ne 0 ]] || fail "empty match should fail"
grep -Fqe 'No test files matched' "$WORKDIR/empty.out" || fail "empty match message"

# N1: documented path glob is not used; -name glob finds both files.
export FIND_POLLUTER_RUNNER="$runner"
set +e
"$SCRIPT" .git '*.test.ts' >"$WORKDIR/hit.out" 2>&1
hit_rc=$?
set -e
[[ "$hit_rc" -ne 0 ]] || fail "polluter scan should fail when a test creates pollution"
grep -Fqe 'pollute.test.ts' "$WORKDIR/hit.out" || fail "should report pollute.test.ts"
[[ ! -e "$WORKDIR/.git" ]] || fail "pollution should be removed between tests"

echo "PASS: find-polluter"
