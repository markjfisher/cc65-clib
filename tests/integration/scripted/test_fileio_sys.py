from __future__ import annotations

import clib_harness as h


def test_file_roundtrip_sys(bbc_for_mode, mode):
    h.reset_and_boot(bbc_for_mode, "TFSYS", mode)
    h.run_disc_program(bbc_for_mode, "TFSYS", settle=6.0)

    h.assert_screen(bbc_for_mode, "W0")
    h.assert_screen(bbc_for_mode, "W1")
    h.assert_screen(bbc_for_mode, "W2")
    h.assert_screen(bbc_for_mode, "W3")
    h.assert_screen(bbc_for_mode, "R1")
    h.assert_screen(bbc_for_mode, "R2")
    h.assert_screen(bbc_for_mode, "R3")
    h.assert_screen(bbc_for_mode, "SYSOK")
