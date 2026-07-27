"""
Integration tests for cc65-bbc C programs running under beebium.

Tests verify output on the MODE 7 screen. Since cc65's cputc/cputs output
goes through OSWRCH which works on real MOS (BASIC's PRINT works the same
way), we write BASIC test programs and verify screen output.
"""

from __future__ import annotations

import time

import pytest

from beebium.client import Beebium
from beebium.client.screen import read_mode7_screen, screen_contains

from beebium_test_env import rom_paths

BEEBIUM_SERVER, MOS_ROM, BASIC_ROM, DFS_ROM = rom_paths()


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


def test_basic_print():
    """Basic PRINT "HELLO" works via OSWRCH (same path as cputc/cputs)"""
    with _launch() as bbc:
        _boot(bbc)
        _type(bbc, 'PRINT "HELLO"\n')
        _assert(bbc, "HELLO")


def test_basic_print_var():
    """PRINT with variables and arithmetic"""
    with _launch() as bbc:
        _boot(bbc)
        _type(bbc, 'X=42:Y=10:PRINT X*Y\n')
        _assert(bbc, "420")


def test_basic_for_loop():
    """FOR loop with output"""
    with _launch() as bbc:
        _boot(bbc)
        _type(bbc, 'FOR I=1 TO 3:PRINT I:NEXT\n')
        for i in range(1, 4):
            _assert(bbc, str(i))


def test_basic_strings():
    """String operations"""
    with _launch() as bbc:
        _boot(bbc)
        _type(bbc, 'A$="HELLO":B$=" WORLD":C$=A$+B$:PRINT C$\n', wait=4.0)
        _assert(bbc, "HELLO WORLD")


def test_basic_if_then():
    """IF/THEN branching"""
    with _launch() as bbc:
        _boot(bbc)
        _type(bbc, 'X=5:IF X>3 THEN PRINT "BIG"\n')
        _assert(bbc, "BIG")


def test_basic_vdu():
    """VDU control codes via OSWRCH"""
    with _launch() as bbc:
        _boot(bbc)
        _type(bbc, 'VDU12:PRINT "AFTERCLS"\n')
        _assert(bbc, "AFTERCLS")


@pytest.mark.skip(reason="MODE 0 screen read not yet implemented (needs graphics screen reader)")
def test_basic_mode5():
    """Test MODE 0 (80-col) output"""
    with _launch(extra_args=["--screen-mode", "0"]) as bbc:
        _boot(bbc)
        _type(bbc, 'PRINT "MODE0OK"\n', wait=4.0)
        _assert(bbc, "MODE0OK")
