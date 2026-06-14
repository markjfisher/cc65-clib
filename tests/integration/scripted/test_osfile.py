"""Integration test: OSFILE wrappers (osfile_save / osfile_read / osfile_delete).

Runs discs/test_osfile.c (built as TOSFIL): saves a file, reads its catalogue
info back (type=file, size=5), deletes it, and confirms a subsequent read
reports "not found". Exercises OS_File against real DFS.
"""

from __future__ import annotations

import pytest

import clib_harness as h


def test_osfile_save_read_delete(bbc_for_mode, mode):
    h.reset_and_boot(bbc_for_mode, "TOSFIL", mode)
    h.run_disc_program(bbc_for_mode, "TOSFIL", settle=4.0)

    h.assert_screen(bbc_for_mode, "SAVEOK")
    h.assert_screen(bbc_for_mode, "READOK")
    h.assert_screen(bbc_for_mode, "DELOK")
    h.assert_not_screen(bbc_for_mode, "READBAD")
    h.assert_not_screen(bbc_for_mode, "DELBAD")
