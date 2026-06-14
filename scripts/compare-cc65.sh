#!/bin/bash
#
# compare-cc65.sh - compare / sync the bbc library sources between the canonical
# cc65 fork (libsrc/bbc) and this project's copy (src/libsrc/bbc), which is what
# the CLIB ROM is built from.
#
# The two trees should be functionally identical; cosmetic whitespace (tabs vs
# spaces) is ignored. The one structural difference is the break handler: cc65
# keeps brk/{bbc,bbc-clib}/break_handler_common.s while this project keeps a flat
# break_handler_common.s, which must track cc65's ROM-aware brk/bbc-clib variant.
#
# Usage:
#   ./compare-cc65.sh             # report functional differences (default)
#   ./compare-cc65.sh --diff      # also show unified diffs of differing files
#   ./compare-cc65.sh --sync      # copy cc65 -> here for functionally-diff files
#   ./compare-cc65.sh -h
#
# Paths (overridable):
#   CC65_SRC   cc65 fork checkout (default: ../cc65 relative to this script)

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
CC65_SRC="${CC65_SRC:-$PROJECT_ROOT/../cc65}"
SRC_DIR="$CC65_SRC/libsrc/bbc"                 # canonical
DST_DIR="$PROJECT_ROOT/src/libsrc/bbc"           # this project's copy
# The flat break handler here tracks cc65's ROM-aware variant:
BRK_SRC="$SRC_DIR/brk/bbc-clib/break_handler_common.s"
BRK_DST="$DST_DIR/break_handler_common.s"

MODE="check"
case "${1:-}" in
  -h|--help)
    sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  --diff) MODE="diff" ;;
  --sync) MODE="sync" ;;
  "") MODE="check" ;;
  *) echo "unknown option: $1 (use -h)"; exit 2 ;;
esac

[ -d "$SRC_DIR" ] || { echo "cc65 source not found: $SRC_DIR (set CC65_SRC)"; exit 1; }
[ -d "$DST_DIR" ] || { echo "project source not found: $DST_DIR"; exit 1; }

# List of overlapping source files (paths relative to the bbc dir), excluding
# the brk/ subdirs that only exist on the cc65 side.
mapfile -t FILES < <(cd "$SRC_DIR" && find . -type f \
  \( -name '*.s' -o -name '*.c' -o -name '*.inc' -o -name '*.h' \) \
  -not -path './brk/*' | sort)

diff_count=0
synced=0

check_one() {  # <relpath> <src> <dst> <label>
  local rel="$1" src="$2" dst="$3" label="$4"
  if [ ! -f "$dst" ]; then
    echo "  MISSING here: $label"; diff_count=$((diff_count+1)); return
  fi
  if ! diff -wq "$src" "$dst" >/dev/null 2>&1; then
    diff_count=$((diff_count+1))
    echo "  DIFFERS (functional): $label"
    if [ "$MODE" = "diff" ]; then diff -u "$dst" "$src" || true; fi
    if [ "$MODE" = "sync" ]; then cp "$src" "$dst"; synced=$((synced+1)); echo "    -> synced"; fi
  fi
}

echo "cc65 (canonical): $SRC_DIR"
echo "project copy:     $DST_DIR"
echo "Functional differences (whitespace ignored):"

for rel in "${FILES[@]}"; do
  check_one "$rel" "$SRC_DIR/$rel" "$DST_DIR/${rel#./}" "${rel#./}"
done

# Break handler (structural path difference) -> track cc65 brk/bbc-clib variant.
if [ -f "$BRK_SRC" ]; then
  check_one "break_handler_common.s" "$BRK_SRC" "$BRK_DST" "break_handler_common.s (<- brk/bbc-clib)"
fi

echo
if [ "$MODE" = "sync" ]; then
  echo "Synced $synced file(s). Re-run 'make -C src clean copy-cc65-artifacts' to"
  echo "regenerate the ROM + metadata from the updated sources."
elif [ "$diff_count" -eq 0 ]; then
  echo "In sync (no functional differences)."
else
  echo "$diff_count functional difference(s). Run with --sync to copy cc65 -> here."
fi
