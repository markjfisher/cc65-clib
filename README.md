# cc65-clib

BBC Micro cc65 C library as a sideways ROM.

This project determines which cc65 bbc library functions can reside in a 16 KB
sideways ROM, builds that ROM image, and generates the stubs and metadata that
the `bbc-clib` cc65 target uses to call into it.

Originally forked from https://github.com/dominicbeesley/cc65-clib, this
repository has since undergone an extensive rewrite and is now detached.

## Repository structure

```
├── src/                          # ROM build system (Python + cc65 toolchain)
│   ├── Makefile
│   ├── clib_rom.s / clib_rom.cfg
│   ├── clib_imports.py / clib_stubs.py / gen_jumptable.py / resolve_objs.py
│   ├── jumptable.def
│   └── libsrc/{runtime,common,bbc}/
├── build-rom/                    # Orchestrates ROM + cc65 lib rebuild
├── tests/                        # Test suites (unit + integration)
│   ├── unit/                     # soft65c02 unit tests (54 test dirs)
│   ├── integration/              # Beebium dual-mode integration tests
│   │   ├── discs/                # C sources for disc-based test programs
│   │   ├── scripted/             # pytest test files + harness
│   │   └── scripts/              # build_test_discs.sh
│   ├── harness/                  # soft65c02 test harness (crt0, stubs)
│   ├── soft65c02-docs/
│   └── manual/                   # Hardware-dependent manual tests
├── debug/jumptable/              # Jump-table debug bundle
├── docs/                         # Design & planning documents
├── scripts/                      # Shell scripts + create_ssd.py
│   ├── run_tests.sh
│   ├── run_unit_tests.sh
│   ├── run_integration_tests.sh
│   ├── test_env.sh
│   ├── compare-cc65.sh
│   └── create_ssd.py
├── build/                        # Output: ROM, libs, test discs
├── roms/                         # Built ROM images (copied from build/)
├── .venv/                        # Python venv (beebium, pytest, grpcio)
├── Makefile                      # Root: delegates to src/ and scripts/
└── README.md
```

## Prerequisites

- **cc65 toolchain** (`ca65`, `cc65`, `ld65`, `ar65`, `od65`) — must be on
  `PATH`. Built from the cc65 fork at
  [github.com/markf256/cc65](https://github.com/markf256/cc65).
- **Python 3.6+** (stdlib only; no pip packages required).

## Building

```bash
cd src && make
```

This runs the full pipeline:

1. **Compile** — assembles all `.s` sources and compiles `.c` sources via cc65
2. **Analyse** — `od65 --dump-all` on each object, then `clib_imports.py`
   determines which functions go in ROM vs. local (only `CODE`/`RODATA`
   segments are ROM-eligible)
3. **Link ROM** — `ld65` links the ROM image (`clib.rom`) with a fixed
   jump-table at `$8100` (1024 slots × 3 bytes) and relocatable code at `$8D00`
4. **Generate stubs** — `clib_stubs.py` creates `clib_stubs.s` mapping each
   ROM function to its fixed jump-table slot address, plus VICE label files
5. **Build library** — `ar65` creates `clib.lib` containing non-ROM objects
   and the stubs object

### Outputs

| File | Description |
|------|-------------|
| `build/clib.rom` | **16 KB sideways ROM image** — the primary deliverable |
| `build/clib.lib` | Companion static library for application linking |
| `build/clib.map` | Linker map |
| `build/clib.lbl` | VICE labels for ROM addresses (`$8000-$BFFF`) |
| `build/clib-mos.lbl` | VICE labels for MOS symbols outside the ROM window |

### Partial builds

```bash
# ROM only (skip stub/label generation)
make -C src rom

# Library only (requires ROM to have been linked already)
make -C src lib
```

### Clean

```bash
make -C src clean
```

Removes the entire `build/` directory.

## Jump table stability

The ROM's jump table is defined by `src/jumptable.def` — an append-only ledger
of `CODE` functions assigned to fixed 3-byte slots at `$8100`. A function
obtains a slot the first time it appears in a ROM build; thereafter it keeps
that slot even if the function body moves within the ROM. This means
application binaries linked against an old ROM continue to work with a newer
one, as long as no slots were retired.

The `gen_jumptable.py --check` target (part of the default build) verifies that
every `CODE` function in the current ROM map has a corresponding entry in
`jumptable.def`, and warns if any are missing.

## Integration with the cc65 fork

This project is loosely coupled with the cc65 fork at
`/home/markf/dev/bbc/cc65/` (or wherever `CC65_SRC` points). After building,
`make copy-cc65-artifacts` copies two files into the cc65 project:

| File | Destination in cc65 | Purpose |
|------|---------------------|---------|
| `build/out/clib_stubs.s` | `libsrc/bbc-clib/clib_stubs.s` | Stubs mapping ROM functions to their jump-table slot addresses |
| `build/out/inc_objs.mk` | `libsrc/bbc-clib/inc_objs.mk` | Makefile fragment listing objects cc65 must build locally (everything not in ROM) |

The copy is non-fatal — if the cc65 checkout is missing the build still
completes, but the artifacts won't be picked up by the cc65 `bbc-clib` target.

## Testing

Tests are bundled in this project. The `build-rom/Makefile` orchestrates the
end-to-end rebuild: cleans and rebuilds the ROM in `src/`, copies it to
`roms/clib.rom`, then rebuilds the cc65 `bbc` and `bbc-clib` libraries.

```bash
# Full matrix: build + unit tests + integration tests
bash scripts/run_tests.sh
bash scripts/run_tests.sh --no-beebium   # skip the slower emulator-based tests
bash scripts/run_tests.sh --quick        # skip ROM rebuild (cc65 libs only)

# Individual suites
bash scripts/run_unit_tests.sh           # 54 soft65c02 unit tests (fast, no emulator)
bash scripts/run_integration_tests.sh    # 24 dual-mode beebium tests (~3 min)

# Or just the bbc-clib subset
pytest tests/integration/scripted/ -k "bbc-clib or rom_swap"
```

### Unit tests (soft65c02)

54 test directories under `tests/unit/`, each exercising a single cc65 bbc
library function in a pure 6502 emulator with a MOS stub harness. Fast and
deterministic.

### Integration tests (beebium)

Dual-mode (bbc + bbc-clib) tests that run cc65-compiled C programs inside a
full BBC Micro emulation. These exercise real OS calls (OSWRCH, OSBYTE, OSFILE,
OSFIND, OSGBPB) against the emulated Acorn DFS filing system and MODE 7 screen.

Prerequisites (auto-detected, skipped with a clear message if missing):
- `beebium-model-b` server binary (from `../beebium`)
- MOS, BASIC, and DFS ROMs
- `dfstool` and `basictool` for building disc images

## Keeping sources in sync with cc65

The `src/libsrc/bbc/` directory is a copy of the bbc library sources from the
cc65 fork. The `scripts/compare-cc65.sh` script checks for functional differences
(ignoring whitespace) and can sync changes from cc65:

```bash
# Check for differences
bash scripts/compare-cc65.sh

# Show unified diffs
bash scripts/compare-cc65.sh --diff

# Copy cc65 sources here (overwrites)
bash scripts/compare-cc65.sh --sync
```

After syncing, re-run the build: `make -C src clean copy-cc65-artifacts`.

## Further reading

- `PYTHON_SCRIPTS.md` — detailed documentation of the Python build scripts
- `architecture-diagram.puml` — PlantUML diagram showing the build pipeline
- `docs/BBC_CLIB_JUMPTABLE_DESIGN.md` — design of the jump
  table / vectoring mechanism
- `docs/BBC_CLIB_TEST_PLAN.md` — overall test architecture