"""Integration test: stdio file I/O (fopen/fwrite/fclose/fread) on real DFS.

Runs discs/test_fileio.c (built as TFDISK): writes "Hello World" to a DFS file
and reads it back, expecting FILEOK.

This used to fail because cc65 osfind.s read the OSFIND handle from Y instead of
A, so fopen()/open() returned a bogus non-zero handle and every OSBGET/OSBPUT
raised DFS "Channel". Fixed in libsrc/bbc/osfind.s.
"""

from __future__ import annotations

import pytest

import clib_harness as h


def test_file_roundtrip(bbc_for_mode, mode):
    h.reset_and_boot(bbc_for_mode, "TFDISK", mode)
    h.run_disc_program(bbc_for_mode, "TFDISK", settle=6.0)

    h.assert_screen(bbc_for_mode, "FILEOK")
    h.assert_not_screen(bbc_for_mode, "FILEBAD")
