#!/usr/bin/env python3
"""
gen_jumptable.py - manage src/jumptable.def, the append-only ledger of ROM
CODE functions that get a fixed jump-table slot (the vectoring layer).

The set of "functions" is taken authoritatively from the linker map: every
symbol whose address lies in the CODE segment (and is not an internal "__"
symbol) is a function. Data lives in RODATA and is never vectored.

Modes:
  --check   (default) report drift between the ledger and the ROM's CODE
            functions (new functions to append; ledger entries no longer in
            CODE that should be marked RESERVED). Warn only; exit 0.
  --update  append any new CODE functions to the END of the ledger (preserving
            existing slot order), and warn about entries to RESERVE. Use this
            when updating the library/ROM.
  --init    (re)write the ledger from scratch with all current CODE functions
            in alphabetical order. Establishes the baseline; only safe before
            any application binaries depend on the slot layout.

Usage: gen_jumptable.py <clib.map> <jumptable.def> [--check|--update|--init]
"""

import os
import re
import sys

HEADER = """\
# CLIB ROM jump-table definition (vectoring layer) - the append-only ledger of
# ROM-resident CODE functions exposed to applications via fixed JMP slots
# (segment JUMPTABLE, base $8100, 3 bytes/slot). An application calls the slot,
# which JMPs to the real (relocatable) function body, so the ROM code can be
# rebuilt/reflashed without breaking already-linked application binaries.
#
# This file is normally maintained by gen_jumptable.py against the linker map:
#   --init   regenerate from scratch (baseline; pre-release only)
#   --update append newly-added CODE functions at the end
#   --check  report drift (build step)
#
# RULES (critical for binary compatibility):
#   * Order = slot index and is PERMANENT. Append new functions at the END only.
#   * NEVER reorder or delete a line. To retire a function, replace its symbol
#     with the keyword RESERVED (keeps every later slot at its fixed address).
#   * Only CODE functions belong here; data (RODATA) symbols are never vectored.
#
# Slot 0 is the first entry below.
"""


def parse_map(map_path):
    """Return (code_lo, code_hi, {symbol: addr}) from an ld65 map file."""
    with open(map_path) as f:
        lines = f.read().splitlines()

    code_lo = code_hi = None
    in_seg = in_exp = False
    syms = {}
    for line in lines:
        s = line.strip()
        if s.startswith("Segment list:"):
            in_seg, in_exp = True, False
            continue
        if s.startswith("Exports list by value:"):
            in_seg, in_exp = False, True
            continue
        if s.startswith("Exports list by name:") or s.startswith("Imports list:"):
            in_exp = False
            continue

        if in_seg:
            m = re.match(r"^CODE\s+([0-9A-Fa-f]{6})\s+([0-9A-Fa-f]{6})\s", line)
            if m:
                code_lo = int(m.group(1), 16)
                code_hi = int(m.group(2), 16)  # inclusive end address
        elif in_exp:
            # "name  ADDR TYPE [name2 ADDR2 TYPE2]"
            for name, addr, _typ in re.findall(
                r"(\w+)\s+([0-9A-Fa-f]{6})\s+([A-Z]+)", line
            ):
                syms[name] = int(addr, 16)

    if code_lo is None:
        sys.exit(f"{map_path}: could not find CODE segment in map")
    return code_lo, code_hi, syms


def code_functions(map_path):
    """Sorted list of CODE-segment function symbols (excludes __internal)."""
    lo, hi, syms = parse_map(map_path)
    funcs = [
        n for n, a in syms.items()
        if lo <= a <= hi and not n.startswith("__")
    ]
    return sorted(funcs)


def read_ledger(path):
    """Return ordered slot entries (symbol or 'RESERVED'); [] if missing."""
    if not os.path.exists(path):
        return []
    out = []
    with open(path) as f:
        for line in f:
            t = line.split("#", 1)[0].strip()
            if t:
                out.append(t)
    return out


def write_ledger(path, entries):
    with open(path, "w") as f:
        f.write(HEADER + "\n")
        for e in entries:
            f.write(e + "\n")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    mode = next((a for a in sys.argv[1:] if a.startswith("--")), "--check")
    if len(args) != 2:
        sys.exit(__doc__)
    map_path, ledger_path = args

    funcs = code_functions(map_path)
    func_set = set(funcs)
    ledger = read_ledger(ledger_path)
    listed = {e for e in ledger if e != "RESERVED"}

    new = [f for f in funcs if f not in listed]              # in CODE, not listed
    dropped = sorted(listed - func_set)                       # listed, not in CODE

    if mode == "--init":
        write_ledger(ledger_path, funcs)
        print(f"gen_jumptable: wrote {len(funcs)} CODE functions to {ledger_path}")
        return

    if mode == "--update":
        if new:
            write_ledger(ledger_path, ledger + new)
            print(f"gen_jumptable: appended {len(new)} new function(s): "
                  + ", ".join(new))
        else:
            print("gen_jumptable: no new functions to append")
        for d in dropped:
            print(f"gen_jumptable: WARNING '{d}' is no longer a ROM CODE function "
                  f"- mark its slot RESERVED in {ledger_path}", file=sys.stderr)
        return

    # --check (default): warn only
    if new:
        print(f"gen_jumptable: WARNING {len(new)} ROM CODE function(s) NOT in the "
              f"jump table (run gen_jumptable.py --update): " + ", ".join(new),
              file=sys.stderr)
    for d in dropped:
        print(f"gen_jumptable: WARNING ledger entry '{d}' is no longer a ROM CODE "
              f"function - mark its slot RESERVED", file=sys.stderr)
    if not new and not dropped:
        print(f"gen_jumptable: jump table in sync ({len(funcs)} CODE functions)")


if __name__ == "__main__":
    main()
