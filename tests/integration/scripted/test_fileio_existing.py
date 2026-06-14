from __future__ import annotations

import clib_harness as h


def test_file_write_existing(bbc_for_mode, mode):
    h.reset_and_boot(bbc_for_mode, "TFEXST", mode)
    h.run_disc_program(bbc_for_mode, "TFEXST", settle=6.0)

    h.assert_screen(bbc_for_mode, "E0")
    h.assert_screen(bbc_for_mode, "E1")
    h.assert_screen(bbc_for_mode, "E2")
    h.assert_screen(bbc_for_mode, "EOK")
