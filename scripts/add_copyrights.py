#!/usr/bin/env python3

from pathlib import Path
import argparse
import sys


ASM_HEADER = """; Dominic Beesley, 2005
; Mark Fisher, 2026
;

"""

C_HEADER = """// Dominic Beesley, 2005
// Mark Fisher, 2026
//

"""


def has_header(text: str, header: str) -> bool:
    return text.startswith(header) or text.startswith(header.rstrip() + "\n")


def process_file(path: Path, dry_run: bool = False) -> bool:
    suffix = path.suffix.lower()

    if suffix in {".s", ".inc"}:
        header = ASM_HEADER
    elif suffix == ".h":
        header = C_HEADER
    else:
        return False

    try:
        original = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        original = path.read_text(encoding="latin-1")

    if has_header(original, header):
        print(f"skip:    {path}")
        return False

    updated = header + original

    if dry_run:
        print(f"would update: {path}")
    else:
        path.write_text(updated, encoding="utf-8")
        print(f"updated: {path}")

    return True


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Add copyright headers to .s, .inc, and .h files."
    )
    parser.add_argument(
        "folder",
        type=Path,
        help="Folder to process recursively",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without writing files",
    )

    args = parser.parse_args()

    root = args.folder.expanduser().resolve()

    if not root.exists():
        print(f"error: folder does not exist: {root}", file=sys.stderr)
        return 1

    if not root.is_dir():
        print(f"error: not a folder: {root}", file=sys.stderr)
        return 1

    changed = 0

    for path in sorted(root.rglob("*")):
        if path.is_file() and path.suffix.lower() in {".s", ".inc", ".h"}:
            if process_file(path, dry_run=args.dry_run):
                changed += 1

    if args.dry_run:
        print(f"\n{changed} file(s) would be updated")
    else:
        print(f"\n{changed} file(s) updated")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())