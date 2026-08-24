#!/usr/bin/env bash
# Run install smoke tests in a clean GNU bash environment (Ubuntu).
# macOS /bin/bash 3.2 does not abort on C1; this container does.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${SANDBOX_IMAGE:-ubuntu:24.04}"

exec docker run --rm \
  -v "$ROOT:/work:ro" \
  -w /work \
  "$IMAGE" \
  bash -lc 'echo "sandbox bash: $(bash --version | head -1)"; apt-get update -qq && apt-get install -y -qq python3 >/dev/null; python3 tests/check-docs.py && python3 tests/check-duplicates.py && ./tests/find-polluter.sh && ./tests/install-smoke.sh && ./tests/install-personal-manifest.sh'
