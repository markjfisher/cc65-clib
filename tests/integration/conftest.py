"""
pytest configuration for cc65-clib beebium integration tests.

Required environment variable:

  BEEBIUM_HOME     beebium repo root (server binary and ROM paths are derived)

Run tests via tests/integration/run_pytest.sh (not bare uv run pytest).
"""

from __future__ import annotations

import logging
import os
from pathlib import Path

import pytest

from beebium_test_env import ensure_environment

logger = logging.getLogger(__name__)

ensure_environment()

_REPO_ROOT = Path(__file__).resolve().parents[2]
_DEFAULT_CLIB_ROM = _REPO_ROOT / "roms" / "clib.rom"


def pytest_configure(config):
    ensure_environment()
    config.addinivalue_line(
        "markers",
        "needs_dfs: requires DFS (disc image loaded)",
    )
    config.addinivalue_line(
        "markers",
        "needs_clib: requires cc65 clib ROM loaded",
    )


def pytest_report_header(config):
    return [
        f"beebium-server: {os.environ['BEEBIUM_SERVER']}",
        f"beebium rom dir: {os.environ['BEEBIUM_ROM_DIR']}",
    ]


def pytest_addoption(parser):
    parser.addoption(
        "--clib-rom",
        action="store",
        default=os.environ.get("CLIB_ROM", str(_DEFAULT_CLIB_ROM)),
        help="Path to cc65 clib ROM (for clib integration tests)",
    )


def pytest_collection_modifyitems(config, items):
    clib_rom = config.getoption("--clib-rom")
    if not clib_rom or not Path(clib_rom).is_file():
        skip_clib = pytest.mark.skip(reason="no clib ROM available (use --clib-rom)")
        for item in items:
            if item.get_closest_marker("needs_clib"):
                item.add_marker(skip_clib)


from beebium import Beebium


def _rom_dir() -> Path:
    return Path(os.environ["BEEBIUM_ROM_DIR"])


def _launch_kwargs() -> dict:
    rom_dir = _rom_dir()
    kwargs = {
        "mos_filepath": str(rom_dir / "acorn-mos_1_20.rom"),
        "basic_filepath": str(rom_dir / "bbc-basic_2.rom"),
        "server_filepath": str(os.environ["BEEBIUM_SERVER"]),
    }
    port = os.environ.get("BEEBIUM_PORT", "").strip()
    if port:
        kwargs["port"] = int(port)
    return kwargs


@pytest.fixture(scope="function")
def bbc(request):
    with Beebium.launch(**_launch_kwargs()) as bbc_instance:
        bbc_instance.debugger.stop()
        yield bbc_instance


@pytest.fixture(scope="function")
def stopped_bbc(bbc):
    return bbc


@pytest.fixture(scope="module")
def bbc_shared(request):
    with Beebium.launch(**_launch_kwargs()) as bbc_instance:
        bbc_instance.debugger.stop()
        yield bbc_instance
