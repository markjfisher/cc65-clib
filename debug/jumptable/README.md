# Jump-table (vectoring) debug bundle

This bundle lets you load and step-debug the CLIB ROM **jump-table / vectoring**
prototype in an emulator. The generator code lives on the cc65-clib branch
`jumptable-prototype`; this directory holds small bbc-clib programs and a build
script to reproduce the artifacts.

## TL;DR of the investigation

The vectoring itself is **correct** (verified): a fixed jump table at `$8100`
(3 bytes/slot, order from `cc65-clib/src/jumptable.def`), and `clib_stubs.s`
resolves vectored functions to their slot (`_strlen := $812D`, etc.); each slot
is `jmp <real function>` and the targets match the ROM map.

The problem is **not** the table. The vectoring adds `fill = yes` padding so the
ROM grew (8999 -> ~9960 bytes), and the larger ROM trips a **ROM-load /
detection timing sensitivity**: a bbc-clib program's `crt0` runs
`detect_clib_rom`, which scans the sideways slots reading `$8000`; with the
bigger ROM the CLIB ROM is sometimes not yet CPU-visible at that instant, so
detection returns `clib_rom_available = 0` and the program aborts (or, depending
on timing, hangs). Reading the slot over the control API (`read_slot_data`)
before running a program reliably fixes a *single* run; but a long test run
(many sequential emulator launches) still flakes, which points at the
emulator-harness ROM-load timing rather than the 6502 code.

So: **direct-address bbc-clib (master) is the stable shipping config; the jump
table is a working prototype blocked on this ROM-load timing issue.**

## Build the bundle

```
bash build_debug.sh                                             # from the cc65-clib project root
```

Produces here: `clib.rom` (+ `clib.lbl`, `clib.map`), and for each program a
binary + `.lbl` (app symbols) + `.ssd` (DFS disc, load/exec `&1900`).

Restore the stable (direct-address) config afterwards:

```
git checkout main && make -C build-rom all
```

## The programs

| Program | Calls | Observed |
|---|---|---|
| `VECOK`    | cputc (ROM, direct) then `strlen` (vectored) | works |
| `VECGOTO`  | clrscr, `gotoxy` (ROM), cputs              | works |
| `VECFAIL`  | clrscr, cputs (local), `strlen` (vectored) | works standalone |
| `TSCREN`   | clrscr, loop cputc/cputs, `gotoxy`         | **reliably reproduces the failure** |

`strlen` is vectored (slot 15 -> `$812D`), `gotoxy`/`cputc` are ROM-direct,
`clrscr`/`cputs` are local (built into the app). `TSCREN` is the most reliable
repro of the failure.

## Reproduce in an emulator

Load `clib.rom` into a sideways slot (slot 13 was used in testing; beebium
Model B aliases socket = slot mod 4, so 13 = socket 1), mount a `.ssd`, and
`*RUN <NAME>`.

* Success looks like the program's output (`L5`, line listing + `MODE7OK`, ...).
* Failure: `>*RUN TSCREN` then the screen does not clear / no program output;
  the program has aborted because `detect_clib_rom` returned 0.

beebium control-API repro scripts (run from this dir, venv active):
* `run_repro.py <NAME>` — single launch, prints PC/ROMSEL and the screen.
* `multi_launch.py` — repeated launches in one process (passes), to contrast
  with the long pytest suite (flakes).

## What to watch when step-debugging

1. `detect_clib_rom` (source: `cc65/libsrc/bbc-clib/rom_detect.s`) — single-step
   the slot scan; when it pages slot 13 (`STX $F4` / `STX $FE30`), is `$8000`
   reading the CLIB header (`00 00 00 4C ... 82 ... "cc65 CLIB"`) or garbage?
   The hypothesis is the ROM is not CPU-visible yet at this instant.
2. `clib_rom_available` / `clib_rom_slot` (app BSS — see each program's `.lbl`;
   e.g. `grep clib_rom_available TSCREN.lbl`). 0 = detection failed.
3. The jump table at `$8100`: each slot should be `4C lo hi` (`jmp`). `_strlen`
   is slot 15 = `$812D` (see `clib.lbl` / `clib.map`).
4. `$F4` (ROMSEL RAM copy) and `$FE30` (ROMSEL) across `crt0` -> `main`.

If you can capture a trace of `detect_clib_rom` at a failing run (especially the
bytes read at `$8000` while slot 13 is paged), that should confirm whether the
ROM is simply not present in the CPU address space at scan time.

## Files

* `vec_ok.c`, `vec_gotoxy.c`, `vec_fail.c`, `tscren.c` — program sources.
* `build_debug.sh` — rebuild everything from the prototype branch.
* `run_repro.py`, `multi_launch.py` — beebium control-API drivers.
* Generator code: this project's `src/jumptable.def`, `src/clib_rom.cfg`,
  `src/clib_rom.s`, `src/clib_imports.py`, `src/clib_stubs.py`. Design notes:
  `docs/BBC_CLIB_JUMPTABLE_DESIGN.md`.
