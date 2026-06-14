"""Integration test: prove the bbc-clib target genuinely depends on the CLIB ROM.

A bbc-clib program resolves stateless library functions to absolute addresses in
the CLIB sideways ROM, and its crt0 refuses to run if the ROM is absent. These
tests run the SAME bbc-clib program with and without the ROM paged in:

* without the ROM -> crt0's detect_clib_rom fails and prints
  "cc65 CLIB ROM not found"; the program body never runs.
* with the ROM -> the program runs normally (proving it called into the ROM).

Together these prove ROM-swapping works and that the program is not silently
falling back to a locally-linked copy of the library.
"""

from __future__ import annotations

import pytest

import clib_harness as h

ROM_MISSING_MSG = "cc65 CLIB ROM not found"


def test_bbc_clib_requires_rom():
    """Without the CLIB ROM, a bbc-clib program must report the missing ROM
    and must NOT produce its normal output."""
    with h.launch("TCONSL", "bbc-clib", with_clib_rom=False) as bbc:
        h.boot(bbc)
        h.run_disc_program(bbc, "TCONSL")
        h.assert_screen(bbc, ROM_MISSING_MSG)
        h.assert_not_screen(bbc, "COLOUROK")


def test_bbc_clib_runs_with_rom():
    """With the CLIB ROM present the same program runs to completion."""
    with h.launch("TCONSL", "bbc-clib", with_clib_rom=True) as bbc:
        h.boot(bbc)
        h.run_disc_program(bbc, "TCONSL")
        h.assert_screen(bbc, "COLOUROK")
        h.assert_not_screen(bbc, ROM_MISSING_MSG)
