# Task: make the beebium integration tests run reliably

Self-contained brief for a fresh session. Goal: the dual-mode (bbc + bbc-clib)
beebium integration suite must pass **consistently**, run after run. Today it is
flaky for `bbc-clib` when the larger (jump-table) CLIB ROM is in use.

## Repo layout / how tests run

- Project: `/home/markf/dev/bbc/cc65-clib` (this repo, formerly test-cc65-clib).
- Two test tiers:
  - **Unit** (`tests/unit/`, soft65c02): fast, reliable, NOT affected by this
    task. Run: `./run_unit_tests.sh`.
  - **Integration** (`tests/integration/scripted/`, beebium + pytest): the flaky
    ones. Run: `./run_integration_tests.sh` (auto-detects server/ROMs, builds
    discs, runs pytest).
- Integration harness: `tests/integration/scripted/clib_harness.py`
  (launch/boot/screen helpers) and `tests/integration/scripted/conftest.py`
  (the `mode` fixture, parametrising tests over `bbc` and `bbc-clib`).
- Each test does `with clib_harness.launch(disc, mode) as bbc:` which calls
  `beebium`'s `Beebium.launch(...)` — i.e. **starts a fresh beebium server
  subprocess per test**, boots it, types `*RUN <prog>`, scrapes the MODE 7
  screen, then tears the server down. The suite is ~25 tests over ~4.5 min, so
  ~25 server launch/teardown cycles in one pytest process.
- beebium Python client lives at
  `/home/markf/dev/bbc/beebium/clients/python/src/beebium` (`client.py`,
  `server.py`, `sideways.py`, `screen.py`, `system.py`). `Beebium.launch` is a
  context manager; check `server.py` for how the server subprocess is started
  and (importantly) **how/whether it is killed on `__exit__`**.
- Env for running: `BEEBIUM_ROM_DIR=/home/markf/dev/bbc/beebium/roms`,
  `BEEBIUM_SERVER=/home/markf/dev/bbc/beebium/build-release/src/server/beebium-model-b`,
  venv at `.venv`. `soft65c02_unit` is in `~/.cargo/bin`.

## The problem (precise)

- `bbc` (all-in-RAM) tests pass reliably.
- `bbc-clib` tests (which load the CLIB ROM in sideways slot 13 and whose `crt0`
  runs `detect_clib_rom` to find the ROM) **flake** in the full suite: typically
  ~9 of the ~10 bbc-clib cases fail in a given run, and *which* ones fail varies
  between runs.
- The failure mode: a program is `*RUN` but produces no/garbled output, or its
  `crt0` ROM detection returns "not found" (`clib_rom_available = 0`) even though
  the ROM is loaded. The CLIB ROM is sometimes not CPU-visible at the instant
  `detect_clib_rom` scans `$8000`.

## What is already known (don't re-derive)

1. **It is NOT a code/vectoring bug.** The same `bbc-clib` programs run correctly
   when launched **individually**: `debug/jumptable/run_repro.py <NAME>` and
   `debug/jumptable/multi_launch.py` both pass 6/6 in a plain (non-pytest)
   Python process. b2 (BeebEm-family emulator) runs the programs fine in normal
   use. So the ROM, the jump table, and the programs are good.
2. **It scales with the number of sequential launches inside one pytest
   process.** Running only the bbc-clib subset still flakes (~9/10); running one
   test in its own process is reliable. This points at server launch/teardown
   churn / resource accumulation, made worse by the **larger (16 KB) CLIB ROM**
   taking longer to load — Phase-2's smaller 9 KB ROM did NOT flake.
3. **A control-API sync before `*RUN` fixes a single run but not the suite.**
   Polling `bbc.sideways.read_slot_data(13, 9, 9) == b"cc65 CLIB"` after boot
   reliably fixes one launch, but the full suite still degrades over many
   launches. (A previous attempt added this to `boot()` and it did not fix the
   suite; it was reverted. `git log` on `clib_harness.py` shows the history.)
4. Booting at normal speed and only then setting
   `bbc.system.set_speed_multiplier(0.0)` (unlimited) is correct and already in
   place; setting unlimited speed *during* boot starves the larger ROM's
   detection.

## First step: diagnose the actual resource

Before changing anything, confirm what accumulates across launches. During a
full `./run_integration_tests.sh` (or a loop of bbc-clib tests), watch:

- `ps -ef | grep beebium-model-b` — are server processes orphaned (not reaped)?
- open file descriptors of the pytest process (`ls /proc/<pid>/fd | wc -l`).
- gRPC/TCP ports in TIME_WAIT (`ss -tan | grep -c TIME-WAIT`) — beebium uses a
  local socket/port per server.

Whichever grows is the lever. (Hypothesis: orphaned/zombie servers or port
exhaustion from per-test launches.)

## Candidate fixes (in rough order of leverage)

1. **Reuse one beebium instance across tests** (biggest lever, closest to normal
   use). Make a session- or module-scoped fixture that launches beebium once,
   and between tests `reset` the machine + re-mount the disc instead of
   relaunching. Far fewer launches = no accumulation. Watch for state bleed; the
   CLIB ROM stays loaded for the whole session. This likely needs reworking
   `clib_harness.launch`/`boot` and `conftest.py` so the `mode` fixture owns a
   reused instance per mode.
2. **Isolate each test in its own process** with `pytest-forked` (run
   **serially**, NOT `pytest-xdist` parallel) so the OS reclaims the server/fds/
   ports between tests. Lower-effort than (1); keeps current per-test launch.
3. **Harden teardown** in the beebium client (or the harness): ensure the
   server subprocess and any children are actually killed/waited on `__exit__`
   (see `beebium/clients/python/src/beebium/server.py`). If servers leak, fixing
   this may be enough on its own.
4. **Readiness waits** instead of fixed `sleep`s: after boot, poll
   `read_slot_data(13)` for the CLIB ROM (and optionally the BASIC prompt) before
   `*RUN`; add a small inter-test settle and generous timeouts. Helps single
   runs; combine with 1/2/3 for the suite.
5. **Split the run**: bbc vs bbc-clib in separate pytest invocations to cap
   launches per process.

Hard constraint from the maintainer: **do not** chase reliability with
parallelism / "fast and hard" load — normal, serial usage must be solid.

## How to verify success

The suite must be **repeatably** green:

```
export BEEBIUM_ROM_DIR=/home/markf/dev/bbc/beebium/roms
export BEEBIUM_SERVER=/home/markf/dev/bbc/beebium/build-release/src/server/beebium-model-b
for i in 1 2 3; do .venv/bin/python -m pytest tests/integration/scripted/ -q -p no:cacheprovider; done
```

Expect `24 passed, 1 skipped` (the 1 skip is the intentional MODE-0 graphics
reader) on **every** run, including the `[bbc-clib]` parametrisations. Also run
the bbc-clib subset a few times: `-k "bbc-clib or rom_swap"` should be all-green
repeatedly.

## Prerequisite: ensure the (jump-table) CLIB ROM is built

The jump-table ("vectoring") work lives on the **`jumptable-prototype` branch**
of `/home/markf/dev/bbc/cc65-clib` (master uses stable direct-address stubs).
The flakiness is most pronounced with that branch's larger 16 KB ROM, so test
against it:

```
( cd ../cc65-clib && git checkout jumptable-prototype )
make -C build-rom all          # builds CLIB ROM + cc65 bbc/bbc-clib libs, copies to roms/ and cc65
./run_integration_tests.sh     # builds dual-mode discs + runs pytest
```

`roms/clib.rom` should be 16384 bytes. Background on the ROM / vectoring is in
`docs/BBC_CLIB_JUMPTABLE_DESIGN.md`; overall test architecture in
`docs/BBC_CLIB_TEST_PLAN.md` and `AGENTS.md`.

## Useful existing tools

- `debug/jumptable/run_repro.py <NAME>` — launch one program, print PC/ROMSEL +
  screen (reliable; good baseline that proves a single run works).
- `debug/jumptable/multi_launch.py` — repeated launches in one plain process
  (passes; contrast with the flaky pytest suite to localise the cause).
- `tests/integration/scripts/build_test_discs.sh` — builds the disc images for
  both targets (uses `scripts/create_ssd.py`).

## Definition of done

- `./run_integration_tests.sh` passes (24 passed, 1 skipped) on at least 3
  consecutive runs with the `jumptable-prototype` 16 KB ROM, with no flaky
  `[bbc-clib]` failures.
- The fix is in the harness/runner only (no emulator-timing hacks that mask a
  leak); document what the accumulating resource was and how the fix addresses
  it.
- `./run_unit_tests.sh` still green; `bbc`-mode integration still green.
