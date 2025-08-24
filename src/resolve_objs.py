#!/usr/bin/env python3
import sys
import os
import re
import argparse

IDENT_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')

SECTION_NAMES = {
    "Header:", "Options:", "Files:", "Segments:", "Imports:", "Exports:",
    "Debug symbols:", "Line infos:", "String pool:", "Assertions:",
    "Scopes:", "Segment sizes:",
}

def parse_manifest(path):
    funcs = []
    with open(path, "r", errors="ignore") as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            funcs.append(s)
    return funcs

def pick_best_source(candidates, info_stem):
    if not candidates:
        return None

    def stem(p): return os.path.splitext(os.path.basename(p))[0].lower()

    # 1) exact stem match first
    for p in candidates:
        if stem(p) == info_stem.lower():
            chosen = p
            break
    else:
        # 2) prefer .c over .s
        cands_c = [p for p in candidates if p.lower().endswith(".c")]
        chosen = cands_c[0] if cands_c else candidates[0]

    rel = chosen[len("libsrc/"):] if chosen.startswith("libsrc/") else chosen
    base, _ = os.path.splitext(rel)
    return f"{base}.o"

def parse_info_file(path):
    with open(path, "r", errors="ignore") as f:
        lines = f.readlines()

    info_stem = os.path.splitext(os.path.basename(path))[0]
    current_section = None
    files = []
    exports = set()

    for raw in lines:
        line = raw.rstrip("\n")
        stripped = line.strip()

        # Section header? (Headers in od65 .info are often indented)
        if stripped in SECTION_NAMES:
            # Switch section explicitly
            if stripped == "Files:":
                current_section = "Files"
            elif stripped == "Exports:":
                current_section = "Exports"
            else:
                current_section = stripped[:-1]  # e.g. "Imports", "Debug symbols", etc.
            continue

        if current_section == "Files":
            # Match both `Name:  "..."` and `Name:"..."`
            m = re.search(r'Name:\s*"([^"]+)"', line)
            if m:
                name = m.group(1)
                lower = name.lower()
                # Only keep original lib sources, not generated build paths
                if lower.startswith("libsrc/") and (lower.endswith(".c") or lower.endswith(".s")):
                    files.append(name)

        elif current_section == "Exports":
            m = re.search(r'Name:\s*"([^"]+)"', line)
            if m:
                sym = m.group(1)
                if IDENT_RE.match(sym):
                    exports.add(sym)

        # All other sections are ignored for symbol collection

    # Prefer a real libsrc source; if none, fall back to stem.o to avoid dropping symbols silently
    obj_rel = pick_best_source(files, info_stem) or f"{info_stem}.o"
    return obj_rel, exports

def build_symbol_map(build_libwrk_dir):
    sym2obj = {}
    for root, _, files in os.walk(build_libwrk_dir):
        for fname in files:
            if not fname.endswith(".info"):
                continue
            info_path = os.path.join(root, fname)
            obj_rel, exports = parse_info_file(info_path)
            for sym in exports:
                sym2obj[sym] = obj_rel
    return sym2obj

def main():
    ap = argparse.ArgumentParser(
        description="Resolve cc65 excluded functions manifest to object files using od65 .info files"
    )
    ap.add_argument("build_libwrk_dir", nargs="?", default="./build/libwrk",
                    help="Path to build/libwrk directory (default: ./build/libwrk)")
    ap.add_argument("exclude_file", help="Path to excluded_functions.manifest")
    ap.add_argument("--dump-symbols", action="store_true",
                    help="Dump full symbol → object map (from .info files)")
    args = ap.parse_args()

    symmap = build_symbol_map(args.build_libwrk_dir)

    if args.dump_symbols:
        for sym in sorted(symmap):
            print(f"{sym:24} -> {symmap[sym]}")
        return

    wanted = parse_manifest(args.exclude_file)
    needed_objs = set()
    unresolved = []

    for sym in wanted:
        obj = symmap.get(sym)
        if obj:
            needed_objs.add(obj)
        else:
            unresolved.append(sym)

    print(f"EXCLUDED_OBJS := {' '.join(sorted(needed_objs))}")

    sys.stderr.write(f"Resolved {len(wanted) - len(unresolved)} / {len(wanted)} functions "
                     f"into {len(needed_objs)} unique object files\n")
    if unresolved:
        sys.stderr.write("Unresolved functions:\n")
        for u in unresolved:
            sys.stderr.write(f"  {u}\n")

if __name__ == "__main__":
    main()
