"""Integration test: directory listing via opendir()/readdir()/closedir().

Runs discs/test_dir.c (built as TDIR) on a disc that also holds data files
ALPHA and BETA. The listing (driven by OSGBPB against the real DFS catalogue)
must include the program and both data files.
"""

from __future__ import annotations

import pytest

import clib_harness as h


def test_directory_listing(bbc_for_mode, mode):
    h.reset_and_boot(bbc_for_mode, "TDIR", mode)
    h.run_disc_program(bbc_for_mode, "TDIR")

    h.assert_screen(bbc_for_mode, "TDIR")
    h.assert_screen(bbc_for_mode, "ALPHA")
    h.assert_screen(bbc_for_mode, "BETA")
    h.assert_screen(bbc_for_mode, "END")
    h.assert_not_screen(bbc_for_mode, "NODIR")
