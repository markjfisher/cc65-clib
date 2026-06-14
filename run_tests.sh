#!/bin/bash
# One-command validation for cc65-clib.
#
# Builds the cc65 libraries (and, by default, the CLIB ROM), then runs the
# soft65c02 unit tests and the dual-mode (bbc + bbc-clib) beebium integration
# tests.
#
# Usage:
#   ./run_tests.sh                # ROM + both cc65 libs, unit + integration
#   ./run_tests.sh --quick        # cc65 libs only (no ROM regen), faster
#   ./run_tests.sh --no-beebium   # build + unit tests only
#
# Path overrides honoured by build-rom/Makefile: CC65_ROOT, CLIB_ROOT,
# TARGET_ROM_COPY (see build-rom/Makefile).

set -euo pipefail
cd "$(dirname "$0")"

RUN_BEEBIUM=1
QUICK=0
for arg in "$@"; do
  case "$arg" in
    --no-beebium) RUN_BEEBIUM=0 ;;
    --quick) QUICK=1 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

echo "############################################################"
if [ "$QUICK" = "1" ]; then
  echo "# 1/3  Build cc65 bbc + bbc-clib libraries (quick: no ROM regen)"
  echo "############################################################"
  make -C build-rom rebuild-cc65-lib
else
  echo "# 1/3  Build CLIB ROM + cc65 bbc/bbc-clib libraries"
  echo "############################################################"
  make -C build-rom all
fi

echo
echo "############################################################"
echo "# 2/3  Unit tests (soft65c02)"
echo "############################################################"
./run_unit_tests.sh

if [ "$RUN_BEEBIUM" = "1" ]; then
  echo
  echo "############################################################"
  echo "# 3/3  Beebium integration tests (bbc + bbc-clib)"
  echo "############################################################"
  ./run_integration_tests.sh
else
  echo
  echo "(skipping beebium: --no-beebium)"
fi

echo
echo "==> test matrix complete"
