#!/bin/bash
# Run the beebium integration tests.
#
# Usage: bash scripts/run_integration_tests.sh [pytest_args...]
#
# Required environment variables:
#   BEEBIUM_HOME      beebium repo root (server + ROM paths derived automatically)
#   CC65_SRC          path to cc65 checkout (tests skip if missing or invalid)
#
# Preflight: tests/integration/check_test_env.sh
#
# Required tools: dfstool, basictool, cc65 (cl65), uv

set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

CC65_SRC="${CC65_SRC:-}"
BUILD_DIR="build/integration-testing/discs"

if [[ -z "${BEEBIUM_HOME:-}" ]]; then
  echo "    BEEBIUM_HOME must be set."
  echo "    See tests/integration/check_test_env.sh and docs/DEVELOPMENT.md"
  echo "    Skipping integration tests."
  exit 0
fi

if ! bash tests/integration/check_test_env.sh 2>/dev/null; then
  echo "    Beebium test environment is incomplete."
  echo "    Skipping integration tests."
  exit 0
fi

CC65_SRC=$(cd "$CC65_SRC" && pwd)
CC65_CLI="${CC65_SRC}/bin/cl65"
if [[ -z "$CC65_SRC" || ! -x "$CC65_CLI" ]]; then
  echo "    CC65_SRC must point at a cc65 checkout with bin/cl65."
  echo "    Skipping integration tests."
  exit 0
fi

if ! command -v dfstool >/dev/null 2>&1; then
  echo "    dfstool not found."
  echo "    Skipping integration tests."
  exit 0
fi
if ! command -v basictool >/dev/null 2>&1; then
  echo "    basictool not found."
  echo "    Skipping integration tests."
  exit 0
fi

if [[ -f tests/integration/.venv/bin/activate ]]; then
  # shellcheck source=/dev/null
  . tests/integration/.venv/bin/activate
elif [[ -f .venv/bin/activate ]]; then
  # shellcheck source=/dev/null
  . .venv/bin/activate
elif ! command -v uv >/dev/null 2>&1; then
  echo "    no virtualenv and uv not found"
  echo "    Skipping integration tests."
  exit 0
fi

if [[ "${REBUILD_ROM:-0}" = "1" ]] \
   || [[ ! -f roms/clib.rom ]] \
   || [[ ! -f "$CC65_SRC/lib/bbc.lib" ]] \
   || [[ ! -f "$CC65_SRC/lib/bbc-clib.lib" ]]; then
  echo "  Building cc65 libraries and CLIB ROM (make -C build-rom all)..."
  make -C build-rom all
fi

echo "  Building test disc images (bbc + bbc-clib)..."
bash tests/integration/scripts/build_test_discs.sh

cd tests/integration
exec ./run_pytest.sh scripted/ -q "$@"
