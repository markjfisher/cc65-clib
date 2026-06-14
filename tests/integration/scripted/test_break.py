"""Integration test: BBC BRK handler (set_brk_ret / disarm_brk_ret).

Runs discs/test_break.c (built as TBREAK). set_brk_ret() has setjmp/longjmp
semantics: it returns 0 once (armed), and a subsequent non-ESC BRK long-jumps
back so it "returns" a second time with 1. The program prints ARMED, triggers a
BRK, and on the second return prints CAUGHT then DONE. The "NOTRAP" marker must
never appear (it would mean the BRK was not caught).
"""

from __future__ import annotations

import pytest

import clib_harness as h


def test_brk_handler_catches_break(bbc_for_mode, mode):
    h.reset_and_boot(bbc_for_mode, "TBREAK", mode)
    h.run_disc_program(bbc_for_mode, "TBREAK")

    h.assert_screen(bbc_for_mode, "ARMED")
    h.assert_screen(bbc_for_mode, "CAUGHT")
    h.assert_screen(bbc_for_mode, "DONE")
    # If the handler had not trapped the BRK, the program would have fallen
    # through to NOTRAP (or the language would have aborted it).
    h.assert_not_screen(bbc_for_mode, "NOTRAP")
