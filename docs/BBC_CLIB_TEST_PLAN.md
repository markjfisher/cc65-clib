# Plan: bbc-clib ROM build + dual-mode (bbc / bbc-clib) test harness

Status: Approved. Phase 1 (Stage A) implemented — see Progress log (§5a).
Decisions: Q1 Stage A before B; Q2 replace legacy tests; Q3 add ROM-missing test.

This plan covers the second purpose of this project: building and validating
the cc65 **bbc-clib** ROM, proving ROM-swapping works, and proving that the
`bbc` and `bbc-clib` targets behave identically — reusing the test suite we just
built for the `bbc` target.

---

## 1. Background & goals

The cc65 fork has two BBC targets:

- **`bbc`** — conventional: every library function is statically linked into the
  application in RAM.
- **`bbc-clib`** — the bulk of *stateless* library functions (CODE/RODATA only,
  no BSS/DATA state) live in a sideways **ROM** (`"cc65 CLIB"`, type `$82`).
  The application links a small local `bbc-clib.lib` for stateful code (heap,
  stdio, fd table, errno, BSS-backed state) and resolves ROM functions to fixed
  absolute addresses. Result: identical source, less application RAM.

The ROM is produced by the sibling **cc65-clib** project, which:
1. compiles its copy of the library, dumps each object (`od65`), and splits
   functions into ROM-eligible vs local (`clib_imports.py`);
2. links the ROM-eligible objects into `clib.rom` and emits `clib_stubs.s`
   (symbol → absolute ROM address) + manifests + `inc_objs.mk`;
3. copies `clib_stubs.s` and `inc_objs.mk` into `cc65/libsrc/bbc-clib/` so the
   cc65 build of the `bbc-clib` target knows which objects to build locally and
   where the ROM functions live.

**End goal of this work:** a harness that (a) builds + validates the clib ROM,
(b) runs applications proving the ROM swap works, and (c) proves our `bbc` /
`bbc-clib` cc65 changes are correct and testable in *both* modes.

---

## 2. Key findings (current state)

### 2.1 CRITICAL: the ROM is stale and does not contain our recent fixes
- cc65-clib builds the ROM from its **own copy** of the sources at
  `cc65-clib/src/libsrc/{bbc,common,runtime}` (Makefile `BBCDIR/COMDIR/RTDIR`,
  lines 20-26), **not** from the canonical `cc65/libsrc/bbc`.
- That copy still contains the bugs we fixed on the `bbc` target:
  - `cc65-clib/src/libsrc/bbc/osfind.s:43` — buggy `tya` (A-vs-Y handle bug).
  - `cc65-clib/src/libsrc/bbc/oslib/osfile_alloc_block.s` — old block/buffer
    overlap layout (+ the read/delete/load early-free + offset bugs).
- The generated `cc65/libsrc/bbc-clib/clib_stubs.s` + manifests are from
  **Nov 2025**, while the `bbc` source fixes are **Jun 2026**.
- Because `bbc-clib` resolves `_osfind` / `_osfile_*` to **ROM addresses**, a
  `bbc-clib` application calls the *stale buggy* ROM copy and ignores the fixed
  local source. **Our osfind/osfile fixes are therefore NOT yet effective for
  `bbc-clib`.** A `bbc-clib` file-I/O program will fail exactly as the `bbc` one
  did before the fix. This is the first thing the new dual-mode tests must
  catch, and the first thing to fix.

### 2.2 The two source trees are ~99% identical (mostly formatting)
- File lists differ by exactly one item: cc65 reorganised the break handler into
  `brk/bbc/` and `brk/bbc-clib/`; cc65-clib still has a single flat
  `bbc/break_handler_common.s`.
- Almost every overlapping file shows a content diff, but inspection shows the
  drift is overwhelmingly **tabs (cc65-clib) vs spaces (cc65)** — e.g. `cclear.s`
  and `clock.s` are functionally identical. The genuine *functional* divergences
  are few: `crt0.s`, the recently-fixed `osfind.s` / `oslib/osfile_*.s`, and the
  break-handler reorganisation.
- The "missing" files the maintainer recalled (`cclear.s`, `cgetc.s`,
  `chline.s`, …) are in fact present in both trees. What's missing is their
  *local object* in `bbc-clib.lib`: they are stateless → ROM-resident → excluded
  from `inc_objs.mk`, so they are not built into the local lib. That is correct
  behaviour, not a gap.

### 2.3 Build wiring
- `build-rom/Makefile`:
  - `rebuild-cc65-lib` builds the cc65 `bbc` and `bbc-clib` libs.
  - `rebuild-clib-rom` runs `cd cc65-clib/src && make clean copy-cc65-artifacts`
    (regenerates ROM + metadata, copies into cc65), then copies
    `clib.{rom,lbl,lib}` to `roms/` and to hardcoded `$HOME/dev/bbc/roms`.
  - Hardcoded paths: `../../cc65`, `../../cc65-clib`, `$HOME/dev/bbc/roms`.
- `build.sh`: hardcoded `test_dirs`, hand-rolls `test.json` per directory
  (the dfstool-manifest pattern we just removed from the integration builder),
  interactive/visual, no assertions.
- `cc65-clib/compare-cc65.sh`: absolute hardcoded paths; `--sync`/`--verbose`
  are unimplemented stubs.

### 2.4 cc65-clib design notes (for context)
- Call mechanism = **fixed absolute addresses, no jump table / no service-call
  indirection** (`clib_imports_jmp.inc` empty, `clib_svc` is bare `rts`).
  Consequence: the `.lib` and `.rom` must come from the *same build*; any address
  shift breaks previously-built binaries. README acknowledges this.
- `crt0.s` (cc65 side, `libsrc/bbc-clib/`) detects the ROM (scans slots 15→0,
  validates header/title), pages it in for the whole run, restores on exit.
  ROM-aware BRK handler re-selects the ROM (`brk/bbc-clib/break_handler_common.s`).
- Cruft to be aware of: dead `cc65-clib/src/libsrc/bbc/Makefile` (`$(error)`),
  unused `resolve_objs.py`/`excluded_objs.mk`, incomplete `clean`,
  half-finished `compare-cc65.sh`, `osfile.h` TODOs.

### 2.5 Legacy `tests/test-*` disposition (vs the new suite)
| Legacy test | Target | Verdict |
|---|---|---|
| test-maths | bbc-clib | Redundant (unit abs/atoi/itoa) — retire |
| test-strings | bbc-clib | Redundant (unit strlen/strcpy/strcat/strcmp/strchr) — retire |
| test-files | bbc-clib | Redundant (unit + integration fileio/dir/osfile) — retire |
| test-c-comprehensive | bbc-clib | Mostly redundant; **unique gap: `strncpy`** |
| test-break-handler | bbc-clib | Partly redundant; unique: ESC pass-through / debug-bomb paths |
| test-serial | **bbc** | Unique (FujiNet/RS423/OSBYTE), hardware-dependent, not a libc test |

All are visual/interactive with no PASS tokens, so none are reusable as-is; their
*coverage* is almost entirely already in the new unit/integration suite.

---

## 3. Source-of-truth decision (recommendation)

The duplication in 2.2 is the root cause of the staleness in 2.1. Given the drift
is mostly formatting, **single source of truth is both feasible and the right
long-term fix**, but it must be staged carefully.

**Recommended target state:** cc65-clib builds the ROM directly from
`cc65/libsrc/{bbc,common,runtime}` (the canonical tree), eliminating the
duplicate `cc65-clib/src/libsrc/*`. ROM-only artefacts stay in cc65-clib
(`clib_rom.s`, `clib_rom.cfg`, the Python generators); application-side
ROM-target files stay in cc65 (`libsrc/bbc-clib/crt0.s`, `rom_detect.s`,
`rom_error.s`, and the generated `clib_stubs.s`/`inc_objs.mk`/manifests).

This requires resolving three concrete divergences first:
1. **Break-handler layout**: point cc65-clib at cc65's `brk/bbc-clib/`
   variant (the ROM should use the ROM-aware handler).
2. **`crt0.s`**: confirm whether the ROM build even needs/uses a `crt0`
   (a ROM has no program entry; `crt0` is almost certainly compiled-but-excluded
   as it's stateful). If unused for the ROM, this divergence is moot. **VERIFY.**
3. **common/runtime**: confirm cc65-clib's `common`/`runtime` copies have no
   functional divergence from cc65's beyond formatting. **VERIFY** (diff -w).

**Migration approach (low-risk, staged):**
- Stage A (immediate, unblocks correctness): treat cc65/libsrc/bbc as canonical
  and **sync** the functional fixes into cc65-clib's copy (osfind, all osfile_*),
  then regenerate the ROM. This is the "just sync once now" path and immediately
  makes bbc-clib correct so testing can proceed.
- Stage B (later, structural): repoint cc65-clib `BBCDIR/COMDIR/RTDIR` at
  `$(CC65_SRC)/libsrc/*`, delete the duplicate trees, and handle the brk-reorg.
  Validate the regenerated ROM/stubs are byte-identical (modulo formatting) to
  Stage A's, then commit the dedup.

A finished `compare-cc65.sh` (or a tiny `sync_sources.sh`) using `diff -w` to
detect *functional* (non-whitespace) drift is the safety net for Stage A and a
verification tool for Stage B.

---

## 4. Phased implementation plan

### Phase 1 — Make bbc-clib correct & rebuildable (highest priority)
1. Sync the functional fixes (`osfind.s`, all `oslib/osfile_*.s`,
   `osfile_alloc_block.s`, ret/offsets) from `cc65/libsrc/bbc` into
   `cc65-clib/src/libsrc/bbc` (Stage A). Use `diff -w` to confirm only the
   intended functional lines change.
2. Rebuild the ROM + regenerate metadata: `make -C build-rom all` (which runs
   `cc65-clib` clean + copy-cc65-artifacts, then rebuilds cc65 `bbc`/`bbc-clib`
   libs). Confirm `clib_stubs.s` / manifests / `inc_objs.mk` are refreshed in
   `cc65/libsrc/bbc-clib/`.
   - Note ordering bug to check: `rebuild-clib` runs `rebuild-cc65-lib` *before*
     `rebuild-clib-rom`, but the cc65 `bbc-clib` lib depends on the freshly
     generated `clib_stubs.s`/`inc_objs.mk`. The Makefile may need reordering so
     the ROM/metadata are generated *first*, then the cc65 libs built. **VERIFY
     and fix if needed.**
3. Smoke-prove correctness: compile a file-I/O program with `-t bbc-clib`, load
   `clib.rom` in beebium, and confirm it now passes (the fix reached the ROM).
   Resolve the `_osfind` double-listing (appears in both manifests) if it
   persists after regeneration.

### Phase 2 — Dual-mode integration harness
Goal: run the existing `discs/*.c` integration programs in **both** `bbc` and
`bbc-clib` modes and assert identical screen output.

1. Extend `build_test_discs.sh` to build each program twice:
   - `-t bbc` (as today) → e.g. `TCONSL.ssd`.
   - `-t bbc-clib` → e.g. `TCONSL` on a disc, with the program linked against
     `bbc-clib.lib`. Continue using `create_ssd.py` for both.
2. Extend `clib_harness.launch()` to optionally load `clib.rom` into a sideways
   slot (alongside DFS) for bbc-clib runs.
3. Parametrize the pytest integration tests over `mode ∈ {bbc, bbc-clib}` (e.g.
   a `mode` fixture). Same assertions for both. A `bbc-clib` run that fails where
   `bbc` passes immediately flags a ROM/stub mismatch.
4. Add a dedicated **ROM-swap proof** test: assert the program runs correctly
   *only when* the ROM is present, and fails with the ROM-missing error
   (`detect_clib_rom` → `print_error_and_exit`) when it is absent — proving the
   app genuinely uses the ROM, not a locally-linked copy.
5. Decide the ROM slot/precedence and how beebium loads it (mirror the
   `--sideways N:rom:clib.rom` pattern already used for DFS).

**Open question:** the unit tests (soft65c02) are target-agnostic at the
function level and need no ROM; keep them `bbc`-only (mocking the ROM swap at
unit level adds cost for little value). Dual-mode lives in integration only.

### Phase 3 — Retire / realign legacy tests
1. Add a `strncpy` **unit** test (the one genuine coverage gap).
2. Retire `tests/test-maths`, `tests/test-strings`, `tests/test-files` (fully
   redundant). Optionally retire `test-c-comprehensive` once `strncpy` is
   covered, and `test-break-handler` once ESC/pass-through paths are covered.
3. Consider a small integration test for the break ESC / pass-through / debug
   paths if we want that coverage (currently only armed/recover is asserted).
4. Move `tests/test-serial` to a clearly-labelled `manual/` or `hardware/`
   area (it's a FujiNet application needing real hardware, not a libc/ROM test),
   or document it as non-automated.

### Phase 4 — De-hardcode the build
1. `build-rom/Makefile`: make `CC65_ROOT`, `CLIB_ROOT`, `TARGET_ROM_COPY`
   overridable env vars with current defaults; make `TARGET_ROM_COPY` optional.
2. Replace the interactive `build.sh` flow with the harness flow (or repurpose it
   to drive Phase 1-2). Remove the hand-rolled `test.json`; use `create_ssd.py`.
3. `cc65-clib/compare-cc65.sh`: finish (or replace with a small sync/verify
   script) and de-hardcode its paths.
4. Wire a top-level `run_tests.sh` mode that builds the ROM, builds both targets,
   and runs unit + dual-mode integration — the single "validate everything"
   entry point.

### Phase 5 — Enhancement (plan-only for now)
Address the absolute-address fragility (the `.lib`/`.rom` same-build coupling):
- Introduce a **jump table / vectoring** layer (the empty `clib_imports_jmp.inc`
  + `clib_svc` were scaffolded for this) so ROM addresses can change without
  rebuilding applications, and/or
- Adopt **private workspace** like fn-rom (this ROM is also a DFS-coexisting
  sideways ROM) to give ROM functions guaranteed RAM, widening what can move to
  ROM. Requires designing claim/release of a workspace page and is a larger,
  separate effort.

---

## 5. Risks & open questions
- **R1 (ordering):** does `build-rom` build the cc65 `bbc-clib` lib before the
  metadata it depends on is generated? Verify/fix in Phase 1.2.
- **R2 (same-build coupling):** every ROM rebuild shifts addresses; all
  `bbc-clib` test binaries must be rebuilt against the matching `clib.lib`/ROM in
  the same run. The harness must always rebuild both together. (Phase 5 removes
  this.)
- **R3 (crt0/common/runtime divergence):** confirm these have no functional
  divergence before Stage B dedup (Section 3).
- **R4 (ROM not padded):** `clib.rom` is ~9 KB, not a padded 16 KB image —
  confirm beebium/real-BBC flashing accepts it.
- **Q1:** keep cc65-clib's duplicate tree (Stage A only) or fully dedup
  (Stage B)? Recommend Stage A now, Stage B after dual-mode tests are green.
- **Q2:** keep `test-c-comprehensive`/`test-break-handler` legacy programs at all,
  or fully replace with purpose-built integration programs? Recommend replace.
- **Q3:** do we want the ROM-missing failure path asserted (Phase 2.4)? Recommend
  yes — it's the strongest proof the app uses the ROM.

---

## 5a. Progress log

### Phase 1 (Stage A) — DONE
- Synced all 33 functionally-diverged `bbc` source files cc65 → cc65-clib
  (`cc65-clib/src/libsrc/bbc`), verified zero functional diffs remain (`diff -w`).
  The drift was mostly tabs-vs-spaces plus our recent osfind/osfile fixes and
  other accumulated changes.
- Synced the ROM-aware break handler: cc65-clib's flat `break_handler_common.s`
  was the old non-ROM-aware variant; replaced with cc65's
  `brk/bbc-clib/break_handler_common.s` (has `select_clib` ROM re-paging).
- **Fixed build ordering** (`build-rom/Makefile`): `rebuild-clib` now generates
  the ROM + metadata (`clib_stubs.s`/`inc_objs.mk`) *before* building the cc65
  libs that link against them.
- Regenerated ROM + metadata + cc65 `bbc`/`bbc-clib` libs end-to-end via
  `make -C build-rom all`.
- **Found & fixed a second real bug** — `cc65/libsrc/bbc-clib/rom_detect.s`
  `check_current_rom`: the title-match loop had a `cpy #9 / bcc` guard that
  exited one iteration early, so after matching all 9 chars of "cc65 CLIB" it
  fell through to "not found". The NUL terminator `beq` could never fire →
  **the CLIB ROM was never detected** (every bbc-clib program errored with
  "cc65 CLIB ROM not found"). Replaced the guard with `iny / bne` so the NUL
  terminator ends the match. App-side fix (rom_detect.o is local).
- **Proven on beebium (Model B):**
  - bbc-clib `test_fileio.c` (linked `-t bbc-clib`, clib ROM in a sideways slot)
    prints **FILEOK** — i.e. it calls `osfind`/`osfile` *from the ROM* and they
    work, confirming our fixes reached the ROM.
  - Without the ROM it prints "cc65 CLIB ROM not found" — confirming the app
    genuinely depends on the ROM (not a locally-linked copy).
  - The unpadded 8999-byte `roms/clib.rom` works directly (no 16K padding
    needed) — resolves R4.

Notes for later:
- beebium Model B aliases 4 physical sockets across 16 logical slots
  (socket = slot mod 4). DFS=socket0, clib loaded at slot 13=socket1, BASIC=
  socket3. The harness must pick a clib slot that doesn't collide with DFS(12)
  or BASIC(15); slot 13 works.
- The `_osfind` double-manifest listing is reduced to a cosmetic quirk: the
  linkable `clib_stubs.s` (`_osfind := $9429`) and `inc_objs.mk` (osfind.o
  absent) agree it is ROM-resident. Worth a generator tidy-up later, not
  functionally blocking.

### Phase 2 (dual-mode integration harness) — DONE
- `build_test_discs.sh` now builds every program for BOTH targets into
  `build/integration-testing/discs/{bbc,bbc-clib}/` (same DFS filenames; mode in
  the directory). `MODES` env can restrict to one target.
- `clib_harness.py` is mode-aware: `disc_path(short, mode)`, per-mode skip via
  `ensure_ready`, and `launch(short, mode, with_clib_rom=None)` which pages the
  CLIB ROM into slot 13 for bbc-clib (overridable for the ROM-missing proof).
- `scripted/conftest.py` adds a `mode` fixture parametrized over
  `("bbc", "bbc-clib")`; bbc-clib auto-skips if `roms/clib.rom` is absent.
- All 8 disc tests (console, screen, clock, keyboard, break, fileio, dir,
  osfile) now run in BOTH modes with identical assertions.
- New `test_rom_swap.py`: proves a bbc-clib program errors with
  "cc65 CLIB ROM not found" WITHOUT the ROM and runs to completion WITH it
  (Q3) — i.e. it genuinely uses the ROM, not a local copy.
- `run_integration_tests.sh` now ensures the cc65 libs + CLIB ROM exist (builds
  via `make -C build-rom all` if missing, or `REBUILD_ROM=1` to force) before
  building discs.
- **Result: 24 passed, 1 skipped** (the intentional MODE-0 graphics reader);
  every functional test green in both `bbc` and `bbc-clib`. fileio/osfile pass
  in bbc-clib too, confirming the fixed osfind/osfile run correctly from the ROM.

### Phase 3 (retire/realign legacy tests) — DONE
- Added a `strncpy` unit test (NUL-padding + truncation-without-NUL), the only
  case the legacy `test-c-comprehensive` covered that the unit suite did not.
- Retired the redundant interactive programs: `test-maths`, `test-strings`,
  `test-files`, `test-c-comprehensive`, `test-break-handler`.
- Moved the FujiNet serial app to `tests/manual/serial-fujinet/` with a
  `tests/manual/README.md` recording the coverage mapping and the two
  intentionally-unautomated BRK paths (ESC pass-through, debug-bomb-banner/hang).
- Updated `AGENTS.md` structure/legacy sections.
- Unit suite: 362 assertions, 0 fail, 53 tests.

### Phase 4 (de-hardcode the build) — DONE
- `build-rom/Makefile`: `CC65_ROOT`, `CLIB_ROOT`, `CC65_TARGET`,
  `CC65_CLIB_TARGET`, `ROM_PATH`, `BUILD_DIR` now `?=` overridable;
  `TARGET_ROM_COPY` defaults empty and the emulator copy (and clean) are guarded
  so it is optional (no more hardcoded `$HOME/dev/bbc/roms`, no `rm /clib*`).
- `build.sh`: stripped of the retired per-test/JSON logic; now a thin wrapper
  over `build-rom` (`build.sh` / `build.sh -r`).
- `run_tests.sh`: the single validate-everything entry point — full ROM + both
  cc65 libs by default, `--quick` (libs only), `--no-beebium`.
- `run_unit_tests.sh`: adds `~/.cargo/bin` / `~/.local/bin` to PATH so
  `soft65c02_unit` is found from a bare environment.
- `cc65-clib/compare-cc65.sh`: rewritten into a working, de-hardcoded
  check/sync tool (`--check` default, `--diff`, `--sync`); ignores whitespace,
  handles the flat-vs-brk/bbc-clib break-handler mapping. Currently reports
  "in sync".
- Verified: `./build.sh` rebuilds the ROM and skips the (unset) emulator copy;
  ROM regeneration is deterministic (cc65 tree unchanged); `run_tests.sh
  --quick` runs all 362 unit assertions green.

### Phase 5 (jump-table / vectoring) — DESIGNED + PROTOTYPED, NOT ADOPTED
- Per instruction, only the jump-table/vectoring was attempted; the sideways-ROM
  private-workspace idea was left out of scope.
- A full prototype was implemented (fixed `$8100` JUMPTABLE segment, append-only
  `jumptable.def`, generator + stub changes) and verified correct in isolation:
  the table lands at `$8100`, stubs vector to the right slots, each slot JMPs to
  the real function, and a bbc-clib program printed a vectored `strlen` result.
- It also surfaced and fixed a real ROM-image issue: gapped memory regions need
  `fill = yes` so file offsets match load addresses (otherwise the fixed table
  loads at the wrong address).
- BUT it destabilised the bbc-clib integration tests (programs abend/hang at a
  vectored call, deterministic for some, flaky for others, pointing at a
  ROM-paging/boot-timing interaction). As this needs focused interactive
  debugging (not safe to resolve unattended), the prototype was **reverted** to
  keep the proven, stable direct-address bbc-clib, and the work is captured as a
  design + open-issue writeup in `docs/BBC_CLIB_JUMPTABLE_DESIGN.md` (the
  implementation remains in git history). Suite restored to 24 passed, 1 skipped.

### Remaining in Phase 1 (Stage B — deferred per decision)
- Repoint cc65-clib `BBCDIR/COMDIR/RTDIR` at `$(CC65_SRC)/libsrc/*` and delete
  the duplicate trees, after dual-mode tests are green (verify common/runtime
  have no functional divergence first).

## 6. Suggested execution order
1. Phase 1 (correctness) — unblocks everything; proves the pipeline.
2. Phase 2 (dual-mode integration) — the core deliverable.
3. Phase 3 (legacy cleanup) — low-risk, reduces confusion.
4. Phase 4 (de-hardcode) — quality-of-life + portability.
5. Phase 5 (vectoring/workspace) — separate, larger initiative.
