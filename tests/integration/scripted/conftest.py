"""pytest fixtures for the dual-mode (bbc / bbc-clib) integration tests.

Any test that takes a ``mode`` parameter is automatically run once per cc65
target. bbc-clib runs are skipped if the CLIB ROM has not been built.

Reliability strategy
--------------------
Each ``bbc`` / ``bbc-clib`` mode gets **one** session-scoped beebium instance
that stays alive for the whole test run.  Between tests ``reset_and_boot()``
switches the floppy disc and hardware-resets the CPU.  This avoids the flakiness
of creating and tearing down ~25 server subprocesses in one pytest process.

Usage
-----
Tests that need a single mode write::

    def test_foo(bbc_for_mode, mode):
        h.reset_and_boot(bbc_for_mode, "DISC", mode)
        ...

``bbc_for_mode`` yields whichever shared instance matches the current ``mode``
parametrisation.  Tests that explicitly need the bbc-clib instance (e.g. the
ROM-swap tests) can request the session-scoped ``bbc_clib`` fixture directly.
"""

from __future__ import annotations

import pytest

import clib_harness as h


# ---------------------------------------------------------------------------
# Shared per-mode beebium instances (session-scoped)
# ---------------------------------------------------------------------------

@pytest.fixture(scope="session")
def bbc():
    """One shared Model B (bbc / all-in-RAM target) for the entire session."""
    if h.SKIP_NEEDED:
        pytest.skip(h.SKIP_REASON)
    with h.launch_shared("bbc") as instance:
        yield instance


@pytest.fixture(scope="session")
def bbc_clib():
    """One shared Model B (bbc-clib target) for the entire session.

    The CLIB ROM is paged in at slot 13 at launch and stays there.
    """
    if h.SKIP_NEEDED:
        pytest.skip(h.SKIP_REASON)
    if not h.CLIB_ROM.exists():
        pytest.skip("roms/clib.rom not built (run make -C build-rom)")
    with h.launch_shared("bbc-clib") as instance:
        yield instance


# ---------------------------------------------------------------------------
# Per-mode mapping to shared instances
# ---------------------------------------------------------------------------

@pytest.fixture
def bbc_for_mode(mode, bbc, bbc_clib):
    """The shared beebium instance matching the current ``mode`` parametrisation."""
    if mode == "bbc-clib":
        return bbc_clib
    return bbc


# ---------------------------------------------------------------------------
# Mode parametrisation
# ---------------------------------------------------------------------------

@pytest.fixture(params=h.MODES)
def mode(request):
    """The cc65 target under test: 'bbc' (RAM) or 'bbc-clib' (ROM-split)."""
    m = request.param
    if h.SKIP_NEEDED:
        pytest.skip(h.SKIP_REASON)
    if m == "bbc-clib" and not h.CLIB_ROM.exists():
        pytest.skip("roms/clib.rom not built (run make -C build-rom)")
    return m