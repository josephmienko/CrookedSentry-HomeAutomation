#!/bin/bash
# Docker-based test runner for CrookedSentry Core Logic

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🧪 Running Swift tests in Docker..."
docker run --rm -t \
  -v "$REPO_ROOT:/code" \
  -w /code/ci/spm-tests \
  swift:6.0-jammy \
  swift test "$@"
