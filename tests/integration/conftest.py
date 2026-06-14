"""
pytest configuration for cc65-clib beebium integration tests.

Provides the ``bbc``, ``stopped_bbc``, and ``bbc_shared`` fixtures from
beebium's auto-registered pytest plugin, with sensible defaults for the
cc65 bbc target test environment.

Usage:
    pytest scripted/           # run all tests
    pytest -k test_hello       # run a specific test
    pytest --beebium-port 50071  # connect to existing server
"""

from __future__ import annotations

import logging
import os
from pathlib import Path

logger = logging.getLogger(__name__)


def pytest_configure(config):
    """Register custom markers."""
    config.addinivalue_line(
        "markers",
        "needs_dfs: requires DFS (disc image loaded)",
    )
    config.addinivalue_line(
        "markers",
        "needs_clib: requires cc65 clib ROM loaded",
    )


def pytest_report_header(config):
    """Report beebium server and ROM paths in test header."""
    server = os.environ.get("BEEBIUM_SERVER", "beebium-model-b")
    rom_dir = os.environ.get("BEEBIUM_ROM_DIR", "~/.local/share/beebium/roms")
    return [
        f"beebium-server: {server}",
        f"beebium rom dir: {rom_dir}",
    ]


# --fixture---------------------------------------------------------------
# Default mos_filepath lookup (used by beebium pytest plugin)
# ------------------------------------------------------------------------

def _find_default_mos() -> str | None:
    """Locate a MOS ROM by trying common paths."""
    candidates = [
        Path(os.environ.get("BEEBIUM_ROM_DIR", "")) if "BEEBIUM_ROM_DIR" in os.environ else None,
        Path.home() / ".local/share/beebium/roms",
        Path.home() / "dev/bbc/roms",
        Path("/usr/share/beebium/roms"),
    ]
    for base in candidates:
        if base is None:
            continue
        for name in ("MOS", "mos", "MOS.rom", "os.rom",
                      "acorn-mos_1_20.rom", "BBC_MOS.rom",
                      "BBC Micro Computer MOS 1.20.rom"):
            path = base / name
            if path.exists():
                return str(path.resolve())
        # Also check for any .rom file that looks like a MOS
        if base.exists():
            for p in sorted(base.glob("*MOS*")):
                return str(p.resolve())
            for p in sorted(base.glob("*os*")):
                return str(p.resolve())
    return None


def _find_default_basic() -> str | None:
    """Locate a BASIC ROM."""
    candidates = [
        Path(os.environ.get("BEEBIUM_ROM_DIR", "")) if "BEEBIUM_ROM_DIR" in os.environ else None,
        Path.home() / ".local/share/beebium/roms",
        Path.home() / "dev/bbc/roms",
        Path("/usr/share/beebium/roms"),
    ]
    for base in candidates:
        if base is None:
            continue
        if base.exists():
            for p in sorted(base.glob("*BASIC*")):
                return str(p.resolve())
            for p in sorted(base.glob("*basic*")):
                return str(p.resolve())
    return None


def _find_default_clib() -> str | None:
    """Locate a cc65 clib ROM (for clib-based tests)."""
    path = Path.home() / "dev/bbc/roms/clib.rom"
    return str(path.resolve()) if path.exists() else None


def pytest_addoption(parser):
    """Add custom CLI options."""
    parser.addoption(
        "--clib-rom",
        action="store",
        default=_find_default_clib(),
        help="Path to cc65 clib ROM (for clib integration tests)",
    )


def pytest_collection_modifyitems(config, items):
    """Skip tests needing clib ROM if it's not available."""
    clib_rom = config.getoption("--clib-rom")
    if not clib_rom:
        skip_clib = pytest.mark.skip(reason="no clib ROM available (use --clib-rom)")
        for item in items:
            if item.get_closest_marker("needs_clib"):
                item.add_marker(skip_clib)


# Fixtures for re-use across integration tests

import pytest
from beebium import Beebium


@pytest.fixture(scope="function")
def bbc(request):
    """Fresh BBC Micro for each test, automatically stopped."""
    mos = os.environ.get("BEEBIUM_MOS") or _find_default_mos()
    basic = os.environ.get("BEEBIUM_BASIC") or _find_default_basic()
    server_exe = os.environ.get("BEEBIUM_SERVER")
    port = int(os.environ.get("BEEBIUM_PORT", "0")) or None

    if not mos:
        pytest.skip("No MOS ROM found — set BEEBIUM_MOS or BEEBIUM_ROM_DIR")

    kwargs = dict(mos_filepath=mos)
    if basic:
        kwargs["basic_filepath"] = basic
    if server_exe:
        kwargs["server_filepath"] = server_exe
    if port:
        kwargs["port"] = port

    with Beebium.launch(**kwargs) as bbc_instance:
        bbc_instance.debugger.stop()
        yield bbc_instance


@pytest.fixture(scope="function")
def stopped_bbc(bbc):
    """Alias for bbc fixture (already stopped)."""
    return bbc


@pytest.fixture(scope="module")
def bbc_shared(request):
    """Shared BBC Micro across tests in one module."""
    mos = os.environ.get("BEEBIUM_MOS") or _find_default_mos()
    basic = os.environ.get("BEEBIUM_BASIC") or _find_default_basic()
    server_exe = os.environ.get("BEEBIUM_SERVER")
    port = int(os.environ.get("BEEBIUM_PORT", "0")) or None

    if not mos:
        pytest.skip("No MOS ROM found")

    kwargs = dict(mos_filepath=mos)
    if basic:
        kwargs["basic_filepath"] = basic
    if server_exe:
        kwargs["server_filepath"] = server_exe
    if port:
        kwargs["port"] = port

    with Beebium.launch(**kwargs) as bbc_instance:
        bbc_instance.debugger.stop()
        yield bbc_instance