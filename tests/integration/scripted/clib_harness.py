"""
Shared harness for the cc65 bbc clib beebium integration tests.

These tests drive cc65-compiled C programs inside a fully emulated BBC Micro
(beebium) loaded from a DFS disc image, and verify their behaviour by reading
the MODE 7 screen.

Key facts that make this work (and that the earlier attempt got wrong):

* The cc65 bbc target defaults to a load/run address of $0E00, which collides
  with Acorn DFS private workspace ($0E00-$18FF). A program *RUN from a DFS disc
  there silently corrupts DFS and produces no output. build_test_discs.sh
  therefore links the test programs at $1900 (PAGE when DFS is present), and the
  disc catalogue load/exec addresses match.

* beebium's beebium.screen helpers already correct for 6845 hardware scrolling
  (they anchor reads at the CRTC screen-start), so read_mode7_screen /
  screen_contains return what is actually displayed.

* Disc operations are slow at the default 2 MHz; we set the speed multiplier to
  0.0 (run as fast as the host allows) so tests complete quickly.

* A cc65 program's _exit returns cleanly to BASIC (RTS to the language), so the
  emulator keeps running and the screen can be read after the program finishes.
"""

from __future__ import annotations

import contextlib
import os
import time
from pathlib import Path

import pytest

from beebium import Beebium
from beebium.screen import dump_screen, read_mode7_screen, screen_contains


def _getenv_path(name, default=None):
    v = os.environ.get(name) or default
    return Path(v).resolve() if v else None


def _rom(name):
    d = _getenv_path("BEEBIUM_ROM_DIR")
    if d:
        p = d / name
        if p.exists():
            return p
    return None


BEEBIUM_SERVER = _getenv_path(
    "BEEBIUM_SERVER",
    "../beebium/build-release/src/server/beebium-model-b",
)
DFS_ROM = _rom("acorn-dfs_2_26.rom")
MOS_ROM = _rom("acorn-mos_1_20.rom")
BASIC_ROM = _rom("bbc-basic_2.rom")
_REPO_ROOT = Path(__file__).resolve().parents[3]
DISCS_DIR = _REPO_ROOT / "build" / "integration-testing" / "discs"
# The cc65 CLIB ROM (built by `make -C build-rom`), loaded for bbc-clib runs.
CLIB_ROM = _REPO_ROOT / "roms" / "clib.rom"

# The two cc65 targets we exercise. bbc links everything into RAM; bbc-clib
# resolves stateless library functions to the CLIB sideways ROM.
MODES = ("bbc", "bbc-clib")

_REQUIRED = {
    "beebium-server": BEEBIUM_SERVER,
    "DFS ROM": DFS_ROM,
    "MOS ROM": MOS_ROM,
    "BASIC ROM": BASIC_ROM,
}
_MISSING = [n for n, p in _REQUIRED.items() if not p or not p.exists()]
SKIP_NEEDED = bool(_MISSING)
SKIP_REASON = "missing: " + ", ".join(_MISSING) if _MISSING else ""

# Sideways slots. beebium Model B aliases 4 physical sockets across 16 logical
# slots (socket = slot mod 4): DFS sits in socket 0 (slot 12) and BASIC in
# socket 3 (slot 15), so the CLIB ROM uses socket 1 (slot 13).
DFS_SLOT = 12
CLIB_SLOT = 13


def disc_path(short_name: str, mode: str = "bbc") -> Path:
    """Path to a built test disc image, e.g. mode="bbc" -> .../bbc/TCONSL.ssd."""
    return DISCS_DIR / mode / f"{short_name}.ssd"


def ensure_ready(short_name: str, mode: str = "bbc"):
    """pytest.skip if prerequisites for running ``short_name`` in ``mode`` are
    missing (beebium/ROM deps, the built disc, or the CLIB ROM for bbc-clib)."""
    if SKIP_NEEDED:
        pytest.skip(SKIP_REASON)
    if not disc_path(short_name, mode).exists():
        pytest.skip(
            f"disc {mode}/{short_name}.ssd not built "
            f"(run tests/integration/scripts/build_test_discs.sh)"
        )
    if mode == "bbc-clib" and not CLIB_ROM.exists():
        pytest.skip("roms/clib.rom not built (run make -C build-rom)")


@contextlib.contextmanager
def launch(disc_short_name=None, mode: str = "bbc", with_clib_rom=None):
    """Launch beebium as a Model B with DFS + a 1770 controller.

    ``mode`` selects which target's disc subdirectory to mount and (for
    bbc-clib) whether to page in the CLIB ROM. ``with_clib_rom`` overrides that
    (e.g. False to prove a bbc-clib program fails without the ROM). If a disc is
    requested its prerequisites are checked and the test is skipped if missing.
    """
    if disc_short_name is not None:
        ensure_ready(disc_short_name, mode)
    if with_clib_rom is None:
        with_clib_rom = mode == "bbc-clib"

    extra = [
        "--sideways", f"{DFS_SLOT}:rom:{DFS_ROM}",
        "--fdc", "acorn-1770",
    ]
    if with_clib_rom:
        extra += ["--sideways", f"{CLIB_SLOT}:rom:{CLIB_ROM}"]
    if disc_short_name is not None:
        extra += ["--floppy", f"0:{disc_path(disc_short_name, mode)}"]

    with Beebium.launch(
        server_filepath=str(BEEBIUM_SERVER),
        mos_filepath=str(MOS_ROM),
        basic_filepath=str(BASIC_ROM),
        extra_args=extra,
    ) as bbc:
        with contextlib.suppress(Exception):
            bbc.system.set_speed_multiplier(0.0)
        yield bbc


def boot(bbc, wait: float = 1.5):
    """Reset and let the machine reach the BASIC prompt."""
    bbc.debugger.reset()
    bbc.debugger.run()
    time.sleep(wait)


def type_line(bbc, text: str, wait: float = 0.0):
    """Type ``text`` followed by Return (the emulator must be running)."""
    bbc.keyboard.type(text + "\r")
    if wait:
        time.sleep(wait)


def pause(bbc):
    """Stop the CPU so screen/CRTC reads describe a single, settled frame."""
    bbc.debugger.stop()


def run_disc_program(bbc, short_name: str, settle: float = 3.0):
    """*RUN a program from the mounted disc, wait, then pause for reading."""
    type_line(bbc, f"*RUN {short_name}")
    time.sleep(settle)
    pause(bbc)


# ----- Shared-instance (session-scoped) helpers ------------------------------

def reset_and_boot(bbc, short_name: str, mode: str = "bbc", wait: float = 1.5):
    """Reset the machine, switch to a new disc, and boot to BASIC.

    Ejects any mounted disc, inserts the one for ``short_name``/``mode``,
    hardware-resets the CPU, and waits for the BASIC prompt.  Leaves the CPU
    **running** so the caller can type commands.
    """
    bbc.keyboard.clear_typing()
    drive = bbc.disc.drive0
    if not drive.is_empty:
        drive.eject(immediate=True)
    drive.insert(str(disc_path(short_name, mode)))
    bbc.disc.set_spin_up_delay(False)
    bbc.debugger.reset()
    bbc.debugger.run()
    time.sleep(wait)


@contextlib.contextmanager
def launch_shared(mode: str = "bbc"):
    """Launch one beebium instance with ROMs loaded, **no disc mounted**.

    The caller uses ``reset_and_boot()`` (which switches discs via
    drive-0 insert) to run each test.  Yields a paused Beebium so
    callers can inspect it immediately.
    """
    extra = [
        "--sideways", f"{DFS_SLOT}:rom:{DFS_ROM}",
        "--fdc", "acorn-1770",
    ]
    if mode == "bbc-clib":
        extra += ["--sideways", f"{CLIB_SLOT}:rom:{CLIB_ROM}"]

    with Beebium.launch(
        server_filepath=str(BEEBIUM_SERVER),
        mos_filepath=str(MOS_ROM),
        basic_filepath=str(BASIC_ROM),
        extra_args=extra,
    ) as bbc:
        bbc.disc.set_spin_up_delay(False)
        with contextlib.suppress(Exception):
            bbc.system.set_speed_multiplier(0.0)
        bbc.debugger.stop()
        yield bbc


def screen_text(bbc) -> str:
    """Full MODE 7 screen as a diagnostic string."""
    return dump_screen(bbc)


def wait_for_text(bbc, text: str, timeout: float = 8.0, poll: float = 0.1) -> bool:
    """Poll until ``text`` appears or ``timeout`` elapses.

    Reads are taken with the CPU paused (so they are self-consistent) and the
    CPU is resumed between polls. Leaves the CPU paused on success.
    """
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        bbc.debugger.stop()
        if screen_contains(bbc, text):
            return True
        bbc.debugger.run()
        time.sleep(poll)
    bbc.debugger.stop()
    return False


def assert_screen(bbc, text: str):
    """Assert ``text`` is present on screen, dumping the screen on failure."""
    if not screen_contains(bbc, text):
        raise AssertionError(f"expected {text!r} on screen\n{dump_screen(bbc)}")


def assert_not_screen(bbc, text: str):
    """Assert ``text`` is NOT present on screen."""
    if screen_contains(bbc, text):
        raise AssertionError(f"did not expect {text!r} on screen\n{dump_screen(bbc)}")


def row_text(bbc, row: int) -> str:
    """The text of a single (scroll-corrected) MODE 7 row, right-stripped."""
    rows = read_mode7_screen(bbc)
    return rows[row].rstrip() if 0 <= row < len(rows) else ""

