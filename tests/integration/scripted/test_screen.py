"""Integration test: cursor positioning and line output (gotoxy + scrolling).

Runs discs/test_screen.c (built as TSCREN): prints five numbered lines from
home, then jumps to row 10 with gotoxy() and prints a marker.
"""

from __future__ import annotations

import pytest

import clib_harness as h


def test_screen_lines_and_gotoxy(bbc_for_mode, mode):
    h.reset_and_boot(bbc_for_mode, "TSCREN", mode)
    h.run_disc_program(bbc_for_mode, "TSCREN")

    # The five numbered lines printed from the home position. (cc65 clrscr()
    # emits CLS *and* a trailing newline, so the home block starts at row 1.)
    for i in range(5):
        assert h.row_text(bbc_for_mode, i + 1) == f"{i}: LINE", h.screen_text(bbc_for_mode)

    # gotoxy(0, 10) positions absolutely, independent of the home block.
    assert h.row_text(bbc_for_mode, 10) == "MODE7OK", h.screen_text(bbc_for_mode)
