from __future__ import annotations

import clib_harness as h


def test_osfind_diag(bbc_for_mode, mode):
    h.reset_and_boot(bbc_for_mode, "TFFIND", mode)
    h.run_disc_program(bbc_for_mode, "TFFIND", settle=6.0)

    h.assert_screen(bbc_for_mode, "F0")
