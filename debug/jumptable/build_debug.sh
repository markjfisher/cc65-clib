#!/bin/bash
# Build the jump-table debug bundle: the vectored CLIB ROM + a set of small
# bbc-clib programs (sources alongside) + SSDs + symbol files, so the vectoring
# can be loaded and step-debugged in an emulator.
#
# Run from the cc65-clib repo root:
#     bash debug/jumptable/build_debug.sh
#
# Produces, in this directory:
#   clib.rom  clib.lbl  clib.map   - the vectored ROM and its symbols
#   VECOK/VECGOTO/VECFAIL/TSCREN    - bbc-clib programs (+ .lbl app symbols)
#   *.ssd                           - DFS discs (load/exec &1900) for each
#
# Then in an emulator: load clib.rom into a sideways slot (e.g. 13), mount a
# disc, and *RUN <NAME>.  See README.md for what each program does and what to
# watch.

set -euo pipefail
cd "$(dirname "$0")"
ROOT=$(cd ../.. && pwd)
HERE=$(pwd)
CL65="${CC65_SRC:-${CC65_ROOT:-$ROOT/../cc65}}/bin/cl65"

echo "1) Building the vectored CLIB ROM + cc65 bbc-clib lib..."
make -C "$ROOT/build-rom" all >/dev/null

echo "2) Copying ROM + symbols into the bundle..."
cp "$ROOT/roms/clib.rom" clib.rom
cp "$ROOT/build/clib.lbl" clib.lbl 2>/dev/null || true
cp "$ROOT/build/clib.map" clib.map 2>/dev/null || true

echo "3) Building the test programs (-t bbc-clib, link \$1900)..."
for prog in vec_ok:VECOK vec_gotoxy:VECGOTO vec_fail:VECFAIL tscren:TSCREN; do
  src="${prog%%:*}.c"; name="${prog##*:}"
  "$CL65" -t bbc-clib --start-addr 0x1900 -Ln "$name.lbl" -o "$name" "$src"
  printf '{"version":1,"discTitle":"%s","discSize":800,"bootOption":"none","cycleNumber":0,"files":[{"fileName":"%s","directory":"$","locked":false,"loadAddress":"&001900","executionAddress":"&001900","contentPath":"%s/%s","type":"other"}]}' \
    "$name" "$name" "$HERE" "$name" > "$name.json"
  dfstool make -o "$name.ssd" -f "$name.json" >/dev/null
  echo "   built $name ($(stat -c%s "$name") bytes) + $name.ssd"
done

echo
echo "Done. Vectored _strlen stub: $(grep -E '^_strlen[[:space:]]' "${CC65_SRC:-${CC65_ROOT:-$ROOT/../cc65}}/libsrc/bbc-clib/clib_stubs.s")"
echo "Jump table base \$8100; see README.md."
