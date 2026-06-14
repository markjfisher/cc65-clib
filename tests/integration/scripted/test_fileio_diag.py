from __future__ import annotations

import clib_harness as h


def test_file_roundtrip_diag(bbc_for_mode, mode):
    h.reset_and_boot(bbc_for_mode, "TFDIAG", mode)
    h.run_disc_program(bbc_for_mode, "TFDIAG", settle=6.0)

    h.assert_screen(bbc_for_mode, "S0")
    h.assert_screen(bbc_for_mode, "S1")
    h.assert_screen(bbc_for_mode, "S2")
    h.assert_screen(bbc_for_mode, "S3")
    h.assert_screen(bbc_for_mode, "S4")
    h.assert_screen(bbc_for_mode, "S5")
    h.assert_screen(bbc_for_mode, "S6")
    h.assert_screen(bbc_for_mode, "FILEOK")
