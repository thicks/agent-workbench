#!/usr/bin/env bash
# Linear scan: which test creates POLLUTION_PATH.
# Usage: ./find-polluter.sh <pollution_path> <name-glob>
# Example: ./find-polluter.sh .git '*.test.ts'
#
# The second argument is a find -name glob (not a globstar path).
# Override the per-file command with FIND_POLLUTER_RUNNER (default: npm test).

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <pollution_path> <test-name-glob>" >&2
  echo "Example: $0 .git '*.test.ts'" >&2
  echo "Finds files with find . -name <glob>, then runs each through npm test" >&2
  echo "(or \$FIND_POLLUTER_RUNNER)." >&2
  exit 1
fi

POLLUTION_CHECK="$1"
TEST_PATTERN="$2"

echo "Searching for a test that creates: $POLLUTION_CHECK"
echo "find . -name $TEST_PATTERN"
echo

if [[ -e "$POLLUTION_CHECK" ]]; then
  echo "Pollution already exists before any test ran: $POLLUTION_CHECK" >&2
  echo "Remove it, then re-run so the scan is not a false negative." >&2
  exit 1
fi

TEST_FILES=()
while IFS= read -r f; do
  [[ -n "$f" ]] && TEST_FILES+=("$f")
done < <(find . -name "$TEST_PATTERN" | LC_ALL=C sort)

if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
  echo "No test files matched: find . -name $TEST_PATTERN" >&2
  echo "Use a -name glob such as '*.test.ts', not a path glob like 'src/**/*.test.ts'." >&2
  exit 1
fi

echo "Found ${#TEST_FILES[@]} test files"
echo

run_one() {
  local test_file="$1"
  if [[ -n "${FIND_POLLUTER_RUNNER:-}" ]]; then
    "$FIND_POLLUTER_RUNNER" "$test_file" >/dev/null 2>&1 || true
  else
    npm test "$test_file" >/dev/null 2>&1 || true
  fi
}

COUNT=0
FOUND=()
for TEST_FILE in "${TEST_FILES[@]}"; do
  COUNT=$((COUNT + 1))
  echo "[$COUNT/${#TEST_FILES[@]}] Testing: $TEST_FILE"
  run_one "$TEST_FILE"
  if [[ -e "$POLLUTION_CHECK" ]]; then
    FOUND+=("$TEST_FILE")
    echo "  polluter: $TEST_FILE"
    rm -rf "$POLLUTION_CHECK"
  fi
done

if [[ ${#FOUND[@]} -gt 0 ]]; then
  echo
  echo "FOUND ${#FOUND[@]} polluter(s):"
  printf '  %s\n' "${FOUND[@]}"
  exit 1
fi

echo
echo "No polluter found — all matched tests left $POLLUTION_CHECK absent."
exit 0
