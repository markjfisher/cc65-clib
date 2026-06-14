"""Integration test: clock() against the real BBC MOS centisecond timer.

Runs discs/test_clock.c (built as TCLOCK), which reads clock() twice with a
busy-wait between and prints CLOCKOK only if both reads are valid and the timer
advanced monotonically.
"""

from __future__ import annotations

import pytest

import clib_harness as h


def test_clock_advances(bbc_for_mode, mode):
    h.reset_and_boot(bbc_for_mode, "TCLOCK", mode)
    h.run_disc_program(bbc_for_mode, "TCLOCK", settle=4.0)

    h.assert_screen(bbc_for_mode, "CLOCKOK")
    h.assert_not_screen(bbc_for_mode, "CLOCKBAD")
