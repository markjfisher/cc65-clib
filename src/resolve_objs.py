#!/usr/bin/env python3
import sys
import os
import re
import argparse

SRCDIRS = [
    "bbc",
    "common",
    "conio",
    "dbg",
    "em",
    "joystick",
    "mouse",
    "runtime",
    "serial",
    "tgi",
    "zlib",
]

# C function definition heuristic (captures the identifier before '(')
FUNC_DEF_RE = re.compile(r'^\s*(?:[A-Za-z_][\w\s\*]*\s+)*([A-Za-z_][A-Za-z0-9_]*)\s*\(')

# Identifier (symbol) matcher: start with letter/underscore, then alnum/underscore
IDENT_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')

def parse_manifest(exclude_file):
    funcs = []
    with open(exclude_file) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            funcs.append(line)
    return funcs

def strip_comment(line: str) -> str:
    # ca65 comments start with ';' – drop it and anything after
    return line.split(";", 1)[0]

def parse_export_item(item: str):
    """
    Parse a single comma-separated .export item.
    Returns (primary_symbol, alias_target_symbol_or_None).
    Accepts forms like:
      name
      name:zp
      name = other
      name:abs = other
      name = other:attr
      name = $00  (alias to numeric -> target ignored)
    """
    s = item.strip()
    if not s:
        return (None, None)

    # primary is the identifier at the start
    m_primary = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)', s)
    primary = m_primary.group(1) if m_primary else None

    # look for "= target"
    m_target = re.search(r'=\s*([A-Za-z_][A-Za-z0-9_]*)', s)
    target = m_target.group(1) if m_target else None

    return (primary, target)

def build_export_map(libsrc_root):
    export_map = {}
    for subdir in SRCDIRS:
        full_dir = os.path.join(libsrc_root, subdir)
        if not os.path.isdir(full_dir):
            continue
        for fname in os.listdir(full_dir):
            path = os.path.join(full_dir, fname)

            if fname.endswith(".s"):
                rel_obj = os.path.join(subdir, fname.replace(".s", ".o"))
                with open(path) as f:
                    for raw in f:
                        line = strip_comment(raw)
                        if not line.strip():
                            continue

                        # 1) .export lines (multiple items, alias forms, attributes)
                        m = re.match(r'\s*\.export\s+(.+)', line)
                        if m:
                            items = [x.strip() for x in m.group(1).split(",")]
                            for it in items:
                                primary, target = parse_export_item(it)
                                if primary and IDENT_RE.match(primary):
                                    export_map[primary] = rel_obj
                                if target and IDENT_RE.match(target):
                                    export_map[target] = rel_obj
                            continue

                        # 2) .proc lines
                        m = re.match(r'\s*\.proc\s+([A-Za-z_][A-Za-z0-9_]*)', line)
                        if m:
                            sym = m.group(1)
                            if IDENT_RE.match(sym) and sym.startswith("_"):
                                export_map[sym] = rel_obj
                            continue

                        # 3) label lines at column 0
                        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:', line)
                        if m:
                            sym = m.group(1)
                            # Only treat global-like function entrypoints (start with underscore)
                            if sym.startswith("_"):
                                export_map[sym] = rel_obj
                            continue

            elif fname.endswith(".c"):
                rel_obj = os.path.join(subdir, fname.replace(".c", ".o"))
                with open(path, errors="ignore") as f:
                    for raw in f:
                        line = strip_comment(raw)
                        if not line.strip():
                            continue
                        m = FUNC_DEF_RE.match(line)
                        if m:
                            cname = m.group(1)  # e.g., "__afailed"
                            # Skip likely non-defs (e.g., 'if (...)', 'while (...)') by requiring identifier to be in IDENT_RE
                            if not IDENT_RE.match(cname):
                                continue
                            sym = "_" + cname  # cc65 adds a leading underscore
                            export_map[sym] = rel_obj
    return export_map

def main():
    parser = argparse.ArgumentParser(description="Resolve cc65 excluded functions manifest to object files")
    parser.add_argument("libsrc_root", help="Path to cc65/libsrc")
    parser.add_argument("exclude_file", help="Path to excluded_functions.manifest")
    parser.add_argument("--dump-symbols", action="store_true",
                        help="Dump full symbol → object map instead of Makefile output")
    args = parser.parse_args()

    funcs = parse_manifest(args.exclude_file)
    export_map = build_export_map(args.libsrc_root)

    if args.dump_symbols:
        for sym, obj in sorted(export_map.items()):
            print(f"{sym:24} -> {obj}")
        return

    needed_objs = set()
    unresolved = []

    for func in funcs:
        if func in export_map:
            needed_objs.add(export_map[func])
        else:
            unresolved.append(func)

    print(f"EXCLUDED_OBJS := {' '.join(sorted(needed_objs))}")

    sys.stderr.write(f"Resolved {len(funcs) - len(unresolved)} / {len(funcs)} functions "
                     f"into {len(needed_objs)} unique object files\n")
    if unresolved:
        sys.stderr.write("Unresolved functions:\n")
        for u in unresolved:
            sys.stderr.write(f"  {u}\n")

if __name__ == "__main__":
    main()
