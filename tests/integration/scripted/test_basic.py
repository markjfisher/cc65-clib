"""
Integration tests for cc65-bbc C programs running under beebium.

Tests verify output on the MODE 7 screen. Since cc65's cputc/cputs output
goes through OSWRCH which works on real MOS (BASIC's PRINT works the same
way), we write BASIC test programs and verify screen output.
"""

from __future__ import annotations

import os
import time
from pathlib import Path

import pytest

from beebium import Beebium
from beebium.screen import read_mode7_screen, screen_contains


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
DISCS_DIR = Path(__file__).resolve().parent.parent.parent.parent / "build" / "integration-testing" / "discs"

_REQUIRED = {
    "beebium-server": BEEBIUM_SERVER,
    "DFS ROM": DFS_ROM,
    "MOS ROM": MOS_ROM,
    "BASIC ROM": BASIC_ROM,
}
_MISSING = [n for n, p in _REQUIRED.items() if not p or not p.exists()]
_SKIP_NEEDED = bool(_MISSING)
_SKIP_REASON = ", ".join(_MISSING)


def _launch(extra_args=None):
    return Beebium.launch(
        server_filepath=str(BEEBIUM_SERVER),
        mos_filepath=str(MOS_ROM),
        basic_filepath=str(BASIC_ROM),
        extra_args=extra_args or [],
    )


def _boot(bbc):
    bbc.debugger.stop()
    bbc.debugger.reset()
    bbc.debugger.run()
    time.sleep(1.5)
    bbc.debugger.stop()


def _type(bbc, text, wait=3.0):
    bbc.keyboard.type(text)
    bbc.debugger.run()
    time.sleep(wait)
    bbc.debugger.stop()


def _text(bbc):
    return "\n".join(read_mode7_screen(bbc))


def _assert(bbc, text):
    assert screen_contains(bbc, text), (
        f"Expected {text!r} on screen\n{_text(bbc)}"
    )


# ---- Tests via BASIC ---------------------------------------------------


@pytest.mark.skipif(_SKIP_NEEDED, reason=_SKIP_REASON)
def test_basic_print():
    """Basic PRINT "HELLO" works via OSWRCH (same path as cputc/cputs)"""
    with _launch() as bbc:
        _boot(bbc)
        _type(bbc, 'PRINT "HELLO"\n')
        _assert(bbc, "HELLO")


@pytest.mark.skipif(_SKIP_NEEDED, reason=_SKIP_REASON)
def test_basic_print_var():
    """PRINT with variables and arithmetic"""
    with _launch() as bbc:
        _boot(bbc)
        _type(bbc, 'X=42:Y=10:PRINT X*Y\n')
        _assert(bbc, "420")


@pytest.mark.skipif(_SKIP_NEEDED, reason=_SKIP_REASON)
def test_basic_for_loop():
    """FOR loop with output"""
    with _launch() as bbc:
        _boot(bbc)
        _type(bbc, 'FOR I=1 TO 3:PRINT I:NEXT\n')
        for i in range(1, 4):
            _assert(bbc, str(i))


@pytest.mark.skipif(_SKIP_NEEDED, reason=_SKIP_REASON)
def test_basic_strings():
    """String operations"""
    with _launch() as bbc:
        _boot(bbc)
        _type(bbc, 'A$="HELLO":B$=" WORLD":C$=A$+B$:PRINT C$\n', wait=4.0)
        _assert(bbc, "HELLO WORLD")


@pytest.mark.skipif(_SKIP_NEEDED, reason=_SKIP_REASON)
def test_basic_if_then():
    """IF/THEN branching"""
    with _launch() as bbc:
        _boot(bbc)
        _type(bbc, 'X=5:IF X>3 THEN PRINT "BIG"\n')
        _assert(bbc, "BIG")


@pytest.mark.skipif(_SKIP_NEEDED, reason=_SKIP_REASON)
def test_basic_vdu():
    """VDU control codes via OSWRCH"""
    with _launch() as bbc:
        _boot(bbc)
        # VDU 12 = clear screen, VDU 31,x,y = cursor home, then PRINT
        _type(bbc, 'VDU12:PRINT "AFTERCLS"\n')
        _assert(bbc, "AFTERCLS")


@pytest.mark.skipif(_SKIP_NEEDED, reason=_SKIP_REASON)
@pytest.mark.skip(reason="MODE 0 screen read not yet implemented (needs graphics screen reader)")
def test_basic_mode5():
    """Test MODE 0 (80-col) output"""
    with _launch(extra_args=["--screen-mode", "0"]) as bbc:
        _boot(bbc)
        _type(bbc, 'PRINT "MODE0OK"\n', wait=4.0)
        _assert(bbc, "MODE0OK")