"""Integration test: blocking keyboard input via cgetc().

Runs discs/test_kbhit.c (built as TKBHIT): it prints PRESS, blocks in cgetc(),
and echoes the key it read. The test injects 'A' and checks "GOT A" appears.
"""

from __future__ import annotations

import time

import pytest

import clib_harness as h


def test_cgetc_reads_key(bbc_for_mode, mode):
    h.reset_and_boot(bbc_for_mode, "TKBHIT", mode)

    h.type_line(bbc_for_mode, "*RUN TKBHIT")
    # Wait for the program to reach its cgetc() prompt.
    assert h.wait_for_text(bbc_for_mode, "PRESS", timeout=6.0), h.screen_text(bbc_for_mode)

    # Resume and inject the keypress cgetc() is waiting for.
    bbc_for_mode.debugger.run()
    time.sleep(0.5)
    bbc_for_mode.keyboard.type("A")
    time.sleep(1.5)
    bbc_for_mode.debugger.stop()

    h.assert_screen(bbc_for_mode, "GOT A")
