#!/usr/bin/env python3
"""
Python equivalent of clib_stubs.pl

Extracts map information for the ROM to a set of assembler defines to be
exported in the library module.

Usage: clib_stubs.py <rom_map.map> <output.s>
"""

import sys
import re
from typing import Dict, NamedTuple


def usage(msg: str):
    """Print usage message and exit."""
    print(f"{sys.argv[0]} <rom_map.map> <output.s>", file=sys.stderr)
    print(file=sys.stderr)
    sys.exit(msg)


class Symbol(NamedTuple):
    """Represents a symbol from the map file."""
    name: str
    address: str
    symbol_type: str


class MapParser:
    """Parse ld65 map files and extract symbol information."""
    
    def __init__(self):
        self.symbols: Dict[str, Symbol] = {}
    
    def parse_map_file(self, filename: str) -> None:
        """Parse a map file and extract symbol information."""
        try:
            with open(filename, 'r') as f:
                content = f.read()
        except IOError as e:
            usage(f"Cannot open {filename} for input: {e}")
        
        lines = content.split('\n')
        in_exports_section = False
        past_header = False
        
        for line in lines:
            line = line.strip()
            
            # Look for "Exports list by value:" section
            if "Exports list by value:" in line:
                in_exports_section = True
                continue
            
            # Skip until we see the separator line
            if in_exports_section and not past_header:
                if line.startswith('---'):
                    past_header = True
                continue
            
            # Stop at next major section or second separator
            if past_header and (line.startswith('---') or 
                               re.match(r'^[A-Z][a-z\s]+:', line)):
                break
            
            # Parse symbol lines in exports section
            if in_exports_section and past_header and line:
                self._parse_symbol_line(line)
    
    def _parse_symbol_line(self, line: str) -> None:
        """Parse a single symbol line from the exports section."""
        # Pattern matches: SYMBOL ADDR TYPE [SYMBOL2 ADDR2 TYPE2]
        # Example: "malloc   008456 RLA     free     008123 RLA"
        pattern = r'(\w+)\s+([0-9A-F]{6})\s+([A-Z]+)(?:\s+(\w+)\s+([0-9A-F]{6})\s+([A-Z]+))?'
        
        match = re.match(pattern, line)
        if match:
            # First symbol
            name1, addr1, type1 = match.group(1), match.group(2), match.group(3)
            self._add_symbol(name1, addr1, type1)
            
            # Second symbol (if present)
            if match.group(4):
                name2, addr2, type2 = match.group(4), match.group(5), match.group(6)
                self._add_symbol(name2, addr2, type2)
    
    def _add_symbol(self, name: str, address: str, symbol_type: str) -> None:
        """Add a symbol to the collection, processing the type."""
        # Extract the last character as the type (Z=zeropage, A=absolute, etc.)
        processed_type = symbol_type[-1] if symbol_type else 'A'
        
        symbol = Symbol(name, address, processed_type)
        self.symbols[name] = symbol
    
    def generate_stubs_file(self, output_file: str) -> None:
        """Generate the assembler stubs file."""
        try:
            with open(output_file, 'w') as f:
                for symbol_name in sorted(self.symbols.keys()):
                    symbol = self.symbols[symbol_name]
                    
                    # Skip symbols starting with '__' (internal symbols)
                    if symbol.name.startswith('__'):
                        f.write(f"\t\t; skipping symbol {symbol.name}\n")
                        continue
                    
                    if symbol.symbol_type == 'Z':
                        # Zeropage symbol
                        f.write(f"\t\t.exportZP\t{symbol.name}\n")
                        f.write(f"\t\t{symbol.name}\t\t:=\t${symbol.address}\n")
                    elif symbol.symbol_type == 'A':
                        # Absolute symbol
                        f.write(f"\t\t.export\t{symbol.name}\n") 
                        f.write(f"{symbol.name}\t\t:=\t${symbol.address}\n")
                    else:
                        # Unsupported symbol type
                        print(f"Warning: Unsupported symbol type \"{symbol.symbol_type}\" for symbol \"{symbol.name}\"", 
                              file=sys.stderr)
        
        except IOError as e:
            usage(f"Cannot open {output_file} for output: {e}")


def main():
    """Main entry point."""
    if len(sys.argv) != 3:
        usage("wrong number of arguments")
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    parser = MapParser()
    parser.parse_map_file(input_file)
    parser.generate_stubs_file(output_file)


if __name__ == "__main__":
    main()
