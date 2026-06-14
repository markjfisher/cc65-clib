#!/bin/bash
# Run the soft65c02 unit tests against a built cc65 bbc library.
#
# Usage: ./run_unit_tests.sh [test_name_pattern]
#   (default: all unit tests under tests/unit/)
#
# The harness builds a small test binary linked against the compiled cc65 bbc
# library, then soft65c02_unit executes the test DSL to verify register/memory state.

set -euo pipefail
cd "$(dirname "$0")"

# soft65c02_unit is typically a cargo-installed binary; make sure the usual
# install locations are on PATH so the runner works from a bare environment.
export PATH="$PATH:$HOME/.cargo/bin:$HOME/.local/bin"

if ! command -v soft65c02_unit >/dev/null 2>&1; then
  echo "    soft65c02_unit not found on PATH -- skipping unit tests."
  echo "    (install from https://github.com/...)"
  exit 0
fi

. ./test_env.sh

PATTERN="${1:-*}"

# Rebuild the cc65 bbc library so tests link against current code
echo "  rebuilding cc65 bbc library..."
make -C build-rom rebuild-cc65-lib >/dev/null

echo "  running soft65c02 unit tests..."

find "$UNIT_TEST_DIR" -name "*.yaml" -path "*/$PATTERN*" | while read -r yaml; do
  test_name=$(basename "$(dirname "$yaml")")
  echo "    $test_name..."
  soft65c02_unit -i "$yaml"
done

echo "  unit tests done."