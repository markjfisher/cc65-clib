# Developer setup (cc65-clib)

## Run tests

Build the ROM, set one path, run the test gate:

```bash
make -C build-rom all

export BEEBIUM_HOME=/path/to/beebium
export CC65_ROOT=/path/to/cc65    # if not ../cc65 relative to this repo

bash scripts/run_tests.sh
```

Beebium integration tests need only `BEEBIUM_HOME`. The server binary and ROM
files under `beebium/roms/` are derived automatically. No separate venv sync
step — `tests/integration/run_pytest.sh` attaches the Beebium client via
`uv run --with-editable`.

### Unit tests (soft65c02)

`scripts/run_unit_tests.sh` sources [scripts/test_env.sh](../scripts/test_env.sh).
Set **`CC65_ROOT`** to your cc65 checkout if it is not `../cc65` relative to
this repo:

```bash
export CC65_ROOT=/path/to/cc65
export CLIB_ROOT=/path/to/cc65-clib
bash scripts/run_unit_tests.sh
```

## Prerequisites

- **cc65 toolchain** — `ca65`, `cc65`, `ld65`, `ar65`, `od65` on `PATH`
- **beebium** built (`beebium-model-b` under your `BEEBIUM_HOME` checkout)
- **Python 3.12+** and **[uv](https://docs.astral.sh/uv/)**
- **soft65c02** — unit test harness
- **basictool**, **dfstool** — test disc and SSD generation

Beebium ROM bundle must include under `$BEEBIUM_HOME/roms/` (or override
`BEEBIUM_ROM_DIR`):

- `acorn-mos_1_20.rom`
- `bbc-basic_2.rom`
- `acorn-dfs_2_26.rom`

## Verify environment

```bash
cd tests/integration
./check_test_env.sh          # preflight + pytest collect smoke
./run_pytest.sh scripted/ -q
```

Set `CHECK_TEST_ENV_SMOKE=0` to skip the collect-only smoke in `check_test_env.sh`.

## Common commands

```bash
bash scripts/run_tests.sh              # full matrix
bash scripts/run_tests.sh --no-beebium # unit tests only
bash scripts/run_integration_tests.sh  # Beebium integration only
bash scripts/run_unit_tests.sh         # soft65c02 unit tests only
```

## Further reading

- [README.md](../README.md) — build pipeline and jump table
- [docs/BBC_CLIB_TEST_PLAN.md](BBC_CLIB_TEST_PLAN.md) — test architecture
- [PYTHON_SCRIPTS.md](../PYTHON_SCRIPTS.md) — ROM build scripts
