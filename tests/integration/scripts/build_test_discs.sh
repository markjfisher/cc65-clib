#!/bin/bash
# Build DFS disc images for all integration test programs, for BOTH cc65 targets:
#   bbc       - conventional, all library code linked into the program (RAM)
#   bbc-clib  - ROM-split, stateless library functions resolved to the clib ROM
#
# Output: build/integration-testing/discs/<mode>/<NAME>.ssd
# (same DFS filename per program; the mode lives in the directory.)
#
# Each program is compiled with cc65, staged into a per-disc directory with a
# DFS .inf sidecar (DFS name + load/exec), then turned into an SSD by
# scripts/create_ssd.py (wraps dfstool).
#
# Environment:
#   CC65_SRC   path to cc65 checkout (default: ../cc65)
#   MODES      space-separated subset of "bbc bbc-clib" (default: both)
#
# Run from project root: bash tests/integration/scripts/build_test_discs.sh

set -euo pipefail

SRC_DIR="tests/integration/discs"
OUT_BASE="build/integration-testing/discs"
STAGE_ROOT="$OUT_BASE/stage"
CC65="${CC65_SRC:-${CC65_ROOT:-../cc65}}/bin/cl65"
CREATE_SSD="scripts/create_ssd.py"
MODES="${MODES:-bbc bbc-clib}"

# Link at $1900 (PAGE when DFS is present). Both bbc and bbc-clib default to
# STARTADDRESS $0E00, which collides with Acorn DFS private workspace
# ($0E00-$18FF). A program loaded+run there from a DFS disc corrupts (and is
# corrupted by) DFS, so its OSWRCH output never reaches the screen. Linking at
# $1900 (the DFS PAGE) avoids the conflict; the disc catalogue load/exec
# addresses must match.
LOAD_EXEC="001900 001900"

# program list: "NAME c_source [extra_src...]"
# (NAME is both the DFS filename and the .ssd basename.)
PROGRAMS=(
  "TBREAK  test_break.c   $SRC_DIR/brk_helper.s"
  "TCLOCK  test_clock.c"
  "TCONSL  test_console.c"
  "TFDISK  test_fileio.c"
  "TFDIAG  test_fileio_diag.c"
  "TFEXST  test_fileio_existing.c"
  "TFFIND  test_osfind_diag.c"
  "TFSYS   test_fileio_sys.c"
  "TKBHIT  test_kbhit.c"
  "TSCREN  test_screen.c"
  "TOSFIL  test_osfile.c"
)

# stage_inf <stage_dir> <dfs_name> <load_exec>
stage_inf() {
  printf '$.%s %s\n' "$2" "$3" > "$1/$2.inf"
}

# build_one <mode> <out_dir> <name> <c_file> [extra_src...]
build_one() {
  local mode="$1" out_dir="$2" name="$3" c_file="$4"
  shift 4
  local stage="$STAGE_ROOT/$mode/$name"
  rm -rf "$stage"; mkdir -p "$stage"
  "$CC65" -t "$mode" --start-addr 0x1900 -o "$stage/$name" "$SRC_DIR/$(basename "$c_file")" "$@" 2>/dev/null
  stage_inf "$stage" "$name" "$LOAD_EXEC"
  python3 "$CREATE_SSD" -i "$stage" -o "$out_dir/$name.ssd" -t "$name" >/dev/null
}

for mode in $MODES; do
  out_dir="$OUT_BASE/$mode"
  mkdir -p "$out_dir"
  echo "=== target: $mode -> $out_dir ==="
  for entry in "${PROGRAMS[@]}"; do
    # shellcheck disable=SC2086
    set -- $entry
    name="$1"; c_file="$2"; shift 2
    echo "  $c_file -> $name"
    build_one "$mode" "$out_dir" "$name" "$c_file" "$@"
  done

  # Directory-listing test (TDIR): needs extra catalogue entries to list.
  echo "  test_dir.c -> TDIR"
  stage="$STAGE_ROOT/$mode/TDIR"
  rm -rf "$stage"; mkdir -p "$stage"
  "$CC65" -t "$mode" --start-addr 0x1900 -o "$stage/TDIR" "$SRC_DIR/test_dir.c" 2>/dev/null
  stage_inf "$stage" "TDIR" "$LOAD_EXEC"
  printf 'alpha-data' > "$stage/ALPHA"
  printf 'beta-data'  > "$stage/BETA"
  stage_inf "$stage" "ALPHA" "000000 000000"
  stage_inf "$stage" "BETA"  "000000 000000"
  python3 "$CREATE_SSD" -i "$stage" -o "$out_dir/TDIR.ssd" -t TDIR >/dev/null

  # Existing-file write test (TFEXST): stage a file that already exists.
  echo "  test_fileio_existing.c -> TFEXST"
  stage="$STAGE_ROOT/$mode/TFEXST"
  rm -rf "$stage"; mkdir -p "$stage"
  "$CC65" -t "$mode" --start-addr 0x1900 -o "$stage/TFEXST" "$SRC_DIR/test_fileio_existing.c" 2>/dev/null
  stage_inf "$stage" "TFEXST" "$LOAD_EXEC"
  printf 'seed-data' > "$stage/EXIST"
  stage_inf "$stage" "EXIST" "000000 000000"
  python3 "$CREATE_SSD" -i "$stage" -o "$out_dir/TFEXST.ssd" -t TFEXST >/dev/null

  # OSFIND diagnostic (TFFIND): stage a file that definitely exists.
  echo "  test_osfind_diag.c -> TFFIND"
  stage="$STAGE_ROOT/$mode/TFFIND"
  rm -rf "$stage"; mkdir -p "$stage"
  "$CC65" -t "$mode" --start-addr 0x1900 -o "$stage/TFFIND" "$SRC_DIR/test_osfind_diag.c" 2>/dev/null
  stage_inf "$stage" "TFFIND" "$LOAD_EXEC"
  printf 'seed-data' > "$stage/EXIST"
  stage_inf "$stage" "EXIST" "000000 000000"
  python3 "$CREATE_SSD" -i "$stage" -o "$out_dir/TFFIND.ssd" -t TFFIND >/dev/null
done

echo "Done. Output in $OUT_BASE/{$(echo $MODES | tr ' ' ',')}"
