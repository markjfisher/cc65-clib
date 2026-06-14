#!/bin/bash
#
# compare-cc65.sh - verify the cc65-clib overlay files are in sync with cc65.
#
# The project no longer holds a full copy of libsrc/{bbc,common,runtime};
# it compiles directly from the canonical cc65 fork at ../cc65.  The only
# local sources are the bbc-clib overlay (src/libsrc/bbc-clib/), which
# provides:
#
#   break_handler_common.s  — flat ROM-aware break handler (from
#                              cc65 libsrc/bbc/brk/bbc-clib/)
#   excluded_objs.list      — object basenames excluded from the build
#
# Usage:
#   bash scripts/compare-cc65.sh             # check (default)
#   bash scripts/compare-cc65.sh --sync      # copy cc65 -> overlay
#   bash scripts/compare-cc65.sh -h
#
# Paths (overridable):
#   CC65_SRC   cc65 fork checkout (default: ../cc65 relative to project root)

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
CC65_SRC="${CC65_SRC:-$PROJECT_ROOT/../cc65}"
OVERLAY="$PROJECT_ROOT/src/libsrc/bbc-clib"

OVERLAY_FILES=(
  "break_handler_common.s:brk/bbc-clib/break_handler_common.s"
)

MODE="${1:-check}"
case "$MODE" in
  -h|--help)
    sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  check|--sync) ;;
  *) echo "unknown option: $1 (use -h)"; exit 2 ;;
esac

[ -d "$CC65_SRC/libsrc/bbc" ] || { echo "cc65 source not found: $CC65_SRC (set CC65_SRC)"; exit 1; }
[ -d "$OVERLAY" ] || { echo "overlay not found: $OVERLAY"; exit 1; }

diff_count=0
synced=0

echo "cc65 (canonical): $CC65_SRC/libsrc/bbc"
echo "overlay:           $OVERLAY"

for entry in "${OVERLAY_FILES[@]}"; do
  local_name="${entry%%:*}"
  cc65_rel="${entry##*:}"
  src="$CC65_SRC/libsrc/bbc/$cc65_rel"
  dst="$OVERLAY/$local_name"
  echo
  echo "--- $local_name ---"
  if [ ! -f "$src" ]; then
    echo "  MISSING in cc65: $cc65_rel"; diff_count=$((diff_count+1))
    continue
  fi
  if diff -q "$src" "$dst" >/dev/null 2>&1; then
    echo "  identical"
  else
    diff_count=$((diff_count+1))
    echo "  DIFFERS:"
    diff -u "$dst" "$src" || true
    if [ "$MODE" = "--sync" ]; then
      cp "$src" "$dst"; synced=$((synced+1)); echo "  -> synced"
    fi
  fi
done

echo
if [ "$MODE" = "--sync" ]; then
  echo "Synced $synced file(s). Run 'make -C src clean' to rebuild the ROM."
elif [ "$diff_count" -eq 0 ]; then
  echo "Overlay in sync with cc65."
else
  echo "$diff_count file(s) differ. Run with --sync to update the overlay."
fi