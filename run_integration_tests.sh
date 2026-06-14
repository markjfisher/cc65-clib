#!/bin/bash
# Run the beebium integration tests.
#
# Usage: ./run_integration_tests.sh [pytest_args...]
#
# Environment variables:
#   BEEBIUM_SERVER     Path to beebium-model-b executable
#                      (default: auto-detect from project checkout)
#   BEEBIUM_ROM_DIR    Directory containing MOS, BASIC, and DFS ROMs
#                      (default: auto-detect from beebium checkout)
#   BEEBIUM_VENV       Path to Python venv with beebium installed
#                      (default: .venv in project root)
#
# Required dependencies:
#   - beebium-server (build from ../beebium)
#   - MOS and BASIC ROMs (bundled with beebium build)
#   - DFS ROM (acorn-dfs_2_26.rom, bundled with beebium build)
#   - dfstool (install from https://github.com/rcook/dfstool)
#   - basictool (used by scripts/create_ssd.py)
#   - cc65 (at ../cc65)
#
# Skips gracefully if dependencies not met, with a clear message.

set -euo pipefail
cd "$(dirname "$0")"

VENV_DIR="${BEEBIUM_VENV:-.venv}"
BEEBIUM_ROM_DIR="${BEEBIUM_ROM_DIR:-}"
BEEBIUM_SERVER="${BEEBIUM_SERVER:-}"
CC65_DIR="${CC65_DIR:-../cc65}"
BUILD_DIR="build/integration-testing/discs"

# --- Discover beebium-server --------------------------------------------
if [ -z "$BEEBIUM_SERVER" ] || [ ! -x "$BEEBIUM_SERVER" ]; then
  candidates=(
    "../beebium/build-release/src/server/beebium-model-b"
    "../beebium/build/src/server/beebium-model-b"
  )
  for c in "${candidates[@]}"; do
    resolved=$(realpath -q "$c" 2>/dev/null || true)
    if [ -n "$resolved" ] && [ -x "$resolved" ]; then
      BEEBIUM_SERVER="$resolved"
      break
    fi
  done
fi
if [ -z "$BEEBIUM_SERVER" ] || [ ! -x "$BEEBIUM_SERVER" ]; then
  echo "    beebium-server not found. Set BEEBIUM_SERVER or check ../beebium/build."
  echo "    Skipping integration tests."
  exit 0
fi
export BEEBIUM_SERVER

# --- Discover ROM directory ---------------------------------------------
if [ -z "$BEEBIUM_ROM_DIR" ]; then
  server_dir=$(dirname "$BEEBIUM_SERVER")
  rom_candidates=(
    "$server_dir/../../roms"      # relative to build/src/server/
    "$server_dir/../roms"         # build/src/ or similar
    "../beebium/build-release/roms"
    "../beebium/roms"
  )
  for c in "${rom_candidates[@]}"; do
    resolved=$(realpath -q "$c" 2>/dev/null || true)
    if [ -n "$resolved" ] && [ -d "$resolved" ] && [ -f "$resolved/acorn-mos_1_20.rom" ]; then
      BEEBIUM_ROM_DIR="$resolved"
      break
    fi
  done
fi
if [ -z "$BEEBIUM_ROM_DIR" ]; then
  echo "    ROM directory not found. Set BEEBIUM_ROM_DIR."
  echo "    Skipping integration tests."
  exit 0
fi
export BEEBIUM_ROM_DIR

# --- Check cc65 ---------------------------------------------------------
CC65_CLI="$CC65_DIR/bin/cl65"
CC65_DIR=$(cd "$CC65_DIR" && pwd)
if [ ! -x "$CC65_CLI" ]; then
  echo "    cc65 not found at $CC65_CLI. Set CC65_DIR."
  echo "    Skipping integration tests."
  exit 0
fi

# --- Check dfstool / basictool (both used by scripts/create_ssd.py) -----
if ! command -v dfstool >/dev/null 2>&1; then
  echo "    dfstool not found. Install from https://github.com/rcook/dfstool"
  echo "    Skipping integration tests."
  exit 0
fi
if ! command -v basictool >/dev/null 2>&1; then
  echo "    basictool not found (required by scripts/create_ssd.py)."
  echo "    Skipping integration tests."
  exit 0
fi

# --- Activate venv ------------------------------------------------------
if [ -f "$VENV_DIR/bin/activate" ]; then
  . "$VENV_DIR/bin/activate"
elif command -v uv >/dev/null 2>&1; then
  :
else
  echo "    no virtualenv found at $VENV_DIR"
  echo "    Skipping integration tests."
  exit 0
fi

# --- Ensure cc65 libs + CLIB ROM exist ----------------------------------
# The dual-mode (bbc + bbc-clib) discs need both cc65 libraries, and bbc-clib
# runs need roms/clib.rom. Build them if missing, or force with REBUILD_ROM=1.
# (A heavy step: rebuilds the cc65-clib ROM and the cc65 bbc/bbc-clib libs.)
if [ "${REBUILD_ROM:-0}" = "1" ] \
   || [ ! -f roms/clib.rom ] \
   || [ ! -f "$CC65_DIR/lib/bbc.lib" ] \
   || [ ! -f "$CC65_DIR/lib/bbc-clib.lib" ]; then
  echo "  Building cc65 libraries and CLIB ROM (make -C build-rom all)..."
  make -C build-rom all
fi

# --- Build test discs ---------------------------------------------------
echo "  Building test disc images (bbc + bbc-clib)..."
bash tests/integration/scripts/build_test_discs.sh

# --- Run tests ----------------------------------------------------------
exec python3 -m pytest tests/integration/scripted/ -q "$@"