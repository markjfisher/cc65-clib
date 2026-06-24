"""Environment resolution for cc65-clib Beebium integration tests.

Required (only this one):

  BEEBIUM_HOME       beebium repository root

Everything else is derived automatically. Override BEEBIUM_SERVER or
BEEBIUM_ROM_DIR only when autodetection is wrong for your machine.

Run tests via tests/integration/run_pytest.sh (not bare ``uv run pytest``).
There is no setup_tests.sh or other venv sync step.
"""

from __future__ import annotations

import os
from pathlib import Path

import pytest

_CONFIGURED = False

_RUNNER = "tests/integration/run_pytest.sh"

ROM_FILES = (
    "acorn-mos_1_20.rom",
    "bbc-basic_2.rom",
    "acorn-dfs_2_26.rom",
)


def _exit(message: str) -> None:
    pytest.exit(
        f"{message}\n"
        f"Required: BEEBIUM_HOME. Run tests via {_RUNNER}. "
        "See docs/DEVELOPMENT.md."
    )


def _env_path(name: str) -> Path | None:
    value = os.environ.get(name)
    if value is None or not value.strip():
        return None
    return Path(value.strip()).expanduser().resolve()


def _first_executable(*paths: Path) -> Path | None:
    for path in paths:
        if path.is_file() and os.access(path, os.X_OK):
            return path
    return None


def resolve_beebium_home() -> Path:
    home = _env_path("BEEBIUM_HOME")
    if home is None:
        _exit("BEEBIUM_HOME must be set")
    if not home.is_dir():
        _exit(f"BEEBIUM_HOME is not a directory: {home}")
    return home


def resolve_beebium_rom_dir(home: Path) -> Path:
    rom_dir = _env_path("BEEBIUM_ROM_DIR")
    if rom_dir is not None:
        if not rom_dir.is_dir():
            _exit(f"BEEBIUM_ROM_DIR is not a directory: {rom_dir}")
        return rom_dir
    default = home / "roms"
    if default.is_dir():
        return default
    _exit(f"No ROM directory found (tried {default}); set BEEBIUM_ROM_DIR")


def resolve_beebium_server(home: Path) -> Path:
    explicit = _env_path("BEEBIUM_SERVER")
    if explicit is not None:
        if not explicit.is_file() or not os.access(explicit, os.X_OK):
            _exit(f"BEEBIUM_SERVER is not an executable file: {explicit}")
        return explicit
    found = _first_executable(
        home / "build-release" / "src" / "server" / "beebium-model-b",
        home / "build" / "src" / "server" / "beebium-model-b",
    )
    if found is not None:
        return found
    _exit(
        "BEEBIUM_SERVER not set and beebium-model-b not found under "
        f"{home}/build-release or {home}/build — build beebium or set BEEBIUM_SERVER"
    )


def missing_prerequisites() -> list[str]:
    """Return names of missing prerequisites (empty when the environment is usable)."""
    missing: list[str] = []
    home = _env_path("BEEBIUM_HOME")
    if home is None:
        missing.append("BEEBIUM_HOME")
        return missing
    if not home.is_dir():
        missing.append(f"BEEBIUM_HOME (not a directory: {home})")
        return missing

    server = _env_path("BEEBIUM_SERVER")
    if server is not None:
        if not server.is_file() or not os.access(server, os.X_OK):
            missing.append(f"BEEBIUM_SERVER ({server})")
    else:
        found = _first_executable(
            home / "build-release" / "src" / "server" / "beebium-model-b",
            home / "build" / "src" / "server" / "beebium-model-b",
        )
        if found is None:
            missing.append("beebium-model-b (build beebium or set BEEBIUM_SERVER)")

    rom_dir = _env_path("BEEBIUM_ROM_DIR") or home / "roms"
    if not rom_dir.is_dir():
        missing.append(f"BEEBIUM_ROM_DIR ({rom_dir})")
        return missing

    for name in ROM_FILES:
        if not (rom_dir / name).is_file():
            missing.append(f"{name} under {rom_dir}")

    return missing


def ensure_environment() -> None:
    global _CONFIGURED
    if _CONFIGURED:
        return

    home = resolve_beebium_home()
    rom_dir = resolve_beebium_rom_dir(home)
    os.environ.setdefault("BEEBIUM_HOME", str(home))
    os.environ.setdefault("BEEBIUM_SERVER", str(resolve_beebium_server(home)))
    os.environ.setdefault("BEEBIUM_ROM_DIR", str(rom_dir))

    for name in ROM_FILES:
        path = rom_dir / name
        if not path.is_file():
            _exit(f"BEEBIUM_ROM_DIR missing {name}: expected {path}")

    _CONFIGURED = True


def rom_paths():
    """Return (server, mos, basic, dfs) Paths from resolved environment."""
    ensure_environment()
    rom_dir = Path(os.environ["BEEBIUM_ROM_DIR"])
    return (
        Path(os.environ["BEEBIUM_SERVER"]),
        rom_dir / "acorn-mos_1_20.rom",
        rom_dir / "bbc-basic_2.rom",
        rom_dir / "acorn-dfs_2_26.rom",
    )
