#!/usr/bin/env python3
"""
Synchronize LCSC part numbers from _bom.csv into KiCad schematic.
Reads BOM, finds each component in schematic, updates LCSC property.
"""
import csv
import re
from pathlib import Path

BOM_FILE = Path(__file__).parent / "_bom.csv"
SCH_FILE = Path(__file__).parent / "Amiga-HID_rev1.0.kicad_sch"

def load_bom():
    """Load BOM and return dict: Designator -> JLCPCB Part #"""
    parts = {}
    with open(BOM_FILE, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            designator = row["Designator"].strip()
            lcsc = row.get("JLCPCB Part #", "").strip()
            if designator and lcsc:
                parts[designator] = lcsc
    return parts

def update_schematic(parts):
    """Update LCSC properties in schematic file."""
    with open(SCH_FILE, "r", encoding="utf-8") as f:
        content = f.read()
    
    changes = []
    
    for designator, lcsc in parts.items():
        # Find the symbol block with this Reference
        # Pattern: (property "Reference" "C1" followed by ... then (property "LCSC" "...")
        
        # First, find all symbol blocks
        # We need to find the Reference property and then update the LCSC property in the same symbol block
        
        # Escape designator for regex
        des_escaped = re.escape(designator)
        
        # Pattern to find the symbol block containing this Reference
        # Look for (property "Reference" "XX" and then find the next (property "LCSC" "..."
        
        # Strategy: Find the Reference line, then find the LCSC property within ~100 lines
        ref_pattern = rf'\(property "Reference" "{des_escaped}"\s*\n'
        ref_matches = list(re.finditer(ref_pattern, content))
        
        if not ref_matches:
            print(f"Warning: {designator} not found in schematic")
            continue
            
        for ref_match in ref_matches:
            ref_pos = ref_match.start()
            
            # Find the start of the enclosing (symbol block
            # Search backwards for (symbol\n
            symbol_start = content.rfind("\t(symbol\n", 0, ref_pos)
            if symbol_start == -1:
                symbol_start = content.rfind("(symbol\n", 0, ref_pos)
            if symbol_start == -1:
                print(f"Warning: Could not find symbol block for {designator}")
                continue
            
            # Find the end of this symbol block (matching closing paren)
            # We need to count parens
            depth = 0
            in_string = False
            i = symbol_start
            symbol_end = -1
            
            while i < len(content):
                c = content[i]
                if c == '"' and (i == 0 or content[i-1] != '\\'):
                    in_string = not in_string
                elif not in_string:
                    if c == '(':
                        depth += 1
                    elif c == ')':
                        depth -= 1
                        if depth == 0:
                            symbol_end = i + 1
                            break
                i += 1
            
            if symbol_end == -1:
                print(f"Warning: Could not find end of symbol block for {designator}")
                continue
            
            symbol_block = content[symbol_start:symbol_end]
            
            # Check if this is the instance block (skip those)
            if '(lib_id' not in symbol_block[:200]:
                continue
            
            # Find and update LCSC property in this block
            lcsc_pattern = r'\(property "LCSC" "[^"]*"'
            lcsc_match = re.search(lcsc_pattern, symbol_block)
            
            if lcsc_match:
                old_lcsc = re.search(r'"LCSC" "([^"]*)"', symbol_block).group(1)
                if old_lcsc != lcsc:
                    # Update the LCSC value
                    new_block = re.sub(
                        r'\(property "LCSC" "[^"]*"',
                        f'(property "LCSC" "{lcsc}"',
                        symbol_block,
                        count=1
                    )
                    content = content[:symbol_start] + new_block + content[symbol_end:]
                    changes.append(f"{designator}: {old_lcsc} -> {lcsc}")
                    # Adjust end position for next iteration
                    diff = len(new_block) - len(symbol_block)
                    # Since we're iterating through ref_matches, we need to be careful
                    # For simplicity, we'll just continue and not worry about position shifts
                    # (this works because we're processing one match at a time and re-reading isn't needed)
            else:
                # No LCSC property exists, we need to add one
                # Add after the Description property
                desc_pattern = r'(\(property "Description"[^)]*\)\s*\))'
                desc_match = re.search(desc_pattern, symbol_block)
                if desc_match:
                    insert_pos_rel = desc_match.end()
                    # Create new LCSC property (copy formatting from Description)
                    # Get indentation
                    indent = "\t\t"
                    new_lcsc_prop = f'\n{indent}(property "LCSC" "{lcsc}"\n{indent}\t(at 0 0 0)\n{indent}\t(hide yes)\n{indent}\t(show_name no)\n{indent}\t(do_not_autoplace no)\n{indent}\t(effects\n{indent}\t\t(font\n{indent}\t\t\t(size 1.27 1.27)\n{indent}\t\t)\n{indent}\t)\n{indent})'
                    new_block = symbol_block[:insert_pos_rel] + new_lcsc_prop + symbol_block[insert_pos_rel:]
                    content = content[:symbol_start] + new_block + content[symbol_end:]
                    changes.append(f"{designator}: ADDED {lcsc}")
                else:
                    print(f"Warning: Could not find Description property for {designator}")
    
    if changes:
        # Write back - use UTF-8 without BOM
        with open(SCH_FILE, "w", encoding="utf-8", newline="\n") as f:
            f.write(content)
        print(f"\nUpdated {len(changes)} components:")
        for change in changes:
            print(f"  {change}")
    else:
        print("No changes needed - all LCSC values are up to date.")

def main():
    print(f"Loading BOM from: {BOM_FILE}")
    parts = load_bom()
    print(f"Found {len(parts)} parts with LCSC numbers")
    
    print(f"\nUpdating schematic: {SCH_FILE}")
    update_schematic(parts)

if __name__ == "__main__":
    main()
