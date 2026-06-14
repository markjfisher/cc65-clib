# Manual / hardware-dependent tests

These are **not** part of the automated suites (`bash scripts/run_unit_tests.sh`,
`bash scripts/run_integration_tests.sh`). They require human interaction and/or real
hardware and are kept for reference and occasional manual use.

## serial-fujinet/

A FujiNet RS423 serial application (cc65 `bbc` target). It exercises OSBYTE
serial wrappers (FX 2/3/7/8/21/128/129/145), builds FujiNet protocol packets
(reset, get SSID/hosts/device-slots, HTTP fetch) and hex-dumps responses.

It needs a real FujiNet device (or a serial peer) and is driven by an
interactive menu, so it cannot be asserted by the beebium screen-scraping
harness. Run it by hand on hardware/emulator with a FujiNet attached.

## Retired legacy tests (history)

The following interactive/visual `bbc-clib` test programs were removed once the
automated unit (`tests/unit/`) and beebium integration (`tests/integration/`)
suites covered their behaviour deterministically:

| Removed test | Replaced by |
|---|---|
| `test-maths` | unit `abs`, `atoi`, `itoa` |
| `test-strings` | unit `strlen`, `strcpy`, `strcat`, `strcmp`, `strchr` |
| `test-files` | unit `file_open/read/write/seek`, `lseek`, `fdtable`, `errors`; integration `test_fileio`, `test_dir`, `test_osfile` (both targets) |
| `test-c-comprehensive` | the above plus unit `ctype`, `memcpy/memset/memcmp`, and the new unit `strncpy` (its only previously-unique case) |
| `test-break-handler` | unit `break_handler`, `break_handler_debug`, `break_global_install`; integration `test_break` |

### Known automation gaps (previously only manual)

These paths from the retired tests are intentionally **not** automated, because
they end in the language/OS error handler or deliberately hang, which the
screen-scraping harness cannot assert reliably:

- BRK handler **ESC pass-through** (armed handler + ESC BRK must NOT be caught).
- BRK handler **debug-mode "bomb" banner + hang** path.

The covered BRK behaviour (arm, catch/recover a non-ESC BRK, disarm, install/
uninstall of BRKV) is asserted by the unit and integration tests above.
