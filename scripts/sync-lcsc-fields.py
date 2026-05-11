"""
Synchronisiert das `LCSC`-Property auf jeder Bauteil-Instanz im
KiCad-Schaltplan und PCB anhand der kanonischen BOM (`_bom.csv`).

Regeln:
- Quelle der Wahrheit: kicad/Amiga-HID_rev1.0/_bom.csv
- Pro Reference (z.B. "C1", "U4"): wenn LCSC-Code in BOM gesetzt ist und
  nicht "tbd" / leer / "DNF" -> Property "LCSC" muss in Schaltplan UND
  PCB existieren und exakt diesen Wert haben.
- Wenn Property bereits vorhanden -> Wert wird angepasst.
- Wenn nicht vorhanden -> direkt nach dem "Description"-Property eingefuegt.
- Property-Variante "LCSC Part" wird zu "LCSC" umbenannt (JLCPCB-konform).
- Bei BOM-Eintraegen ohne gueltigen LCSC (tbd / leer / DNF) wird ein evtl.
  vorhandenes LCSC-Property NICHT geloescht (defensiv), nur ein Hinweis
  ausgegeben.

Aufruf:
    python scripts/sync-lcsc-fields.py            # dry-run
    python scripts/sync-lcsc-fields.py --apply    # schreibt mit Backup
"""
from __future__ import annotations

import argparse
import csv
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent / "kicad" / "Amiga-HID_rev1.0"
BOM_PATH = PROJECT_DIR / "_bom.csv"
SCH_PATH = PROJECT_DIR / "Amiga-HID_rev1.0.kicad_sch"
PCB_PATH = PROJECT_DIR / "Amiga-HID_rev1.0.kicad_pcb"


def load_bom() -> dict[str, str]:
    mapping: dict[str, str] = {}
    skipped: list[tuple[str, str]] = []
    with BOM_PATH.open(encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            refs = [r.strip() for r in (row.get("Reference") or "").split(",") if r.strip()]
            lcsc = (row.get("LCSC") or "").strip()
            if not lcsc or lcsc.lower() in {"tbd", "dnf", "n/a", "-"}:
                for r in refs:
                    skipped.append((r, lcsc or "<empty>"))
                continue
            if not re.fullmatch(r"C\d{3,}", lcsc):
                for r in refs:
                    skipped.append((r, lcsc))
                continue
            for r in refs:
                mapping[r] = lcsc
    if skipped:
        print("[BOM] kein gueltiger LCSC -> uebersprungen:")
        for ref, val in skipped:
            print(f"   - {ref:<6} (BOM-LCSC='{val}')")
    return mapping


# ----- sexpr helpers ---------------------------------------------------------

def find_block_end(text: str, open_paren_pos: int) -> int:
    """Return index AFTER the matching ')' for the '(' at open_paren_pos."""
    assert text[open_paren_pos] == "("
    depth = 0
    i = open_paren_pos
    in_string = False
    while i < len(text):
        ch = text[i]
        if ch == '"' and text[i - 1] != "\\":
            in_string = not in_string
        elif not in_string:
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    return i + 1
        i += 1
    raise ValueError("unbalanced parens")


def iter_top_blocks(text: str, head: str):
    """Yield (start, end) for every top-level block beginning with `(<head>`.

    `head` example: "symbol" (for schematic instance) or "footprint".
    Top-level here means: the '(' is preceded by a newline + tab (single
    indent), to skip the lib_symbols/embedded definitions.
    """
    pattern = re.compile(r"\n(\t)\((" + re.escape(head) + r")\b")
    for m in pattern.finditer(text):
        open_pos = m.start(0) + 2  # skip '\n' + '\t' to land on '('
        assert text[open_pos] == "("
        end = find_block_end(text, open_pos)
        yield open_pos, end


REF_RE = re.compile(r'\(property\s+"Reference"\s+"([^"]+)"')
LCSC_RE = re.compile(r'\(property\s+"(LCSC(?:\s+Part)?)"\s+"([^"]*)"')
DESC_RE = re.compile(r'\(property\s+"Description"\s+"')


def process_block(block: str, ref_to_lcsc: dict[str, str], indent: str,
                  changes: list[str]) -> str:
    ref_m = REF_RE.search(block)
    if not ref_m:
        return block
    ref = ref_m.group(1)
    target_lcsc = ref_to_lcsc.get(ref)

    lcsc_m = LCSC_RE.search(block)
    if lcsc_m:
        existing_name = lcsc_m.group(1)
        existing_value = lcsc_m.group(2)
        if target_lcsc is None:
            # BOM hat keinen Wert; defensiv lassen, aber Variante normalisieren
            if existing_name != "LCSC":
                new_block = (
                    block[: lcsc_m.start()]
                    + f'(property "LCSC" "{existing_value}"'
                    + block[lcsc_m.start() + len(f'(property "{existing_name}" "{existing_value}"'):]
                )
                changes.append(
                    f"{ref}: rename '{existing_name}' -> 'LCSC' (Wert '{existing_value}')"
                )
                return new_block
            return block
        # Update Wert / Name falls noetig
        if existing_name != "LCSC" or existing_value != target_lcsc:
            old_head = f'(property "{existing_name}" "{existing_value}"'
            new_head = f'(property "LCSC" "{target_lcsc}"'
            new_block = block[: lcsc_m.start()] + new_head + block[lcsc_m.start() + len(old_head):]
            changes.append(
                f"{ref}: '{existing_name}'='{existing_value}' -> 'LCSC'='{target_lcsc}'"
            )
            return new_block
        return block

    # kein LCSC vorhanden -> einfuegen, falls BOM-Wert vorhanden
    if target_lcsc is None:
        return block

    # Description-Block finden und dahinter einfuegen, sonst vor letztem ')'
    desc_m = DESC_RE.search(block)
    if desc_m:
        desc_open = block.rfind("(", 0, desc_m.end())
        # desc_open ist nicht zwingend richtig (rfind), suche stattdessen ab desc_m.start()
        desc_open = desc_m.start()
        desc_end = find_block_end(block, desc_open)
        insert_pos = desc_end
    else:
        # vor schliessendem ')' der Instanz einfuegen
        insert_pos = len(block.rstrip()) - 1

    snippet = (
        f'\n{indent}(property "LCSC" "{target_lcsc}"\n'
        f'{indent}\t(at 0 0 0)\n'
        f'{indent}\t(unlocked yes)\n'
        f'{indent}\t(layer "F.Fab")\n'
        f'{indent}\t(hide yes)\n'
        f'{indent}\t(uuid "00000000-0000-0000-0000-000000000000")\n'
        f'{indent}\t(effects\n'
        f'{indent}\t\t(font\n'
        f'{indent}\t\t\t(size 1 1)\n'
        f'{indent}\t\t\t(thickness 0.15)\n'
        f'{indent}\t\t)\n'
        f'{indent}\t)\n'
        f'{indent})'
    )
    changes.append(f"{ref}: LCSC='{target_lcsc}' eingefuegt")
    return block[:insert_pos] + snippet + block[insert_pos:]


def schematic_snippet(indent: str, value: str) -> str:
    return (
        f'\n{indent}(property "LCSC" "{value}"\n'
        f'{indent}\t(at 0 0 0)\n'
        f'{indent}\t(show_name no)\n'
        f'{indent}\t(do_not_autoplace no)\n'
        f'{indent}\t(hide yes)\n'
        f'{indent}\t(effects\n'
        f'{indent}\t\t(font\n'
        f'{indent}\t\t\t(size 1.27 1.27)\n'
        f'{indent}\t\t)\n'
        f'{indent}\t)\n'
        f'{indent})'
    )


def process_block_sch(block: str, ref_to_lcsc: dict[str, str],
                      changes: list[str]) -> str:
    ref_m = REF_RE.search(block)
    if not ref_m:
        return block
    ref = ref_m.group(1)
    target_lcsc = ref_to_lcsc.get(ref)

    lcsc_m = LCSC_RE.search(block)
    if lcsc_m:
        existing_name = lcsc_m.group(1)
        existing_value = lcsc_m.group(2)
        if target_lcsc is None:
            if existing_name != "LCSC":
                old_head = f'(property "{existing_name}" "{existing_value}"'
                new_head = f'(property "LCSC" "{existing_value}"'
                changes.append(f"{ref}: rename '{existing_name}' -> 'LCSC'")
                return block[: lcsc_m.start()] + new_head + block[lcsc_m.start() + len(old_head):]
            return block
        if existing_name != "LCSC" or existing_value != target_lcsc:
            old_head = f'(property "{existing_name}" "{existing_value}"'
            new_head = f'(property "LCSC" "{target_lcsc}"'
            changes.append(
                f"{ref}: '{existing_name}'='{existing_value}' -> 'LCSC'='{target_lcsc}'"
            )
            return block[: lcsc_m.start()] + new_head + block[lcsc_m.start() + len(old_head):]
        return block

    if target_lcsc is None:
        return block

    desc_m = DESC_RE.search(block)
    if desc_m:
        desc_open = desc_m.start()
        desc_end = find_block_end(block, desc_open)
        insert_pos = desc_end
        # Indent von Description uebernehmen: davor stehen tabs vom Zeilenanfang
        line_start = block.rfind("\n", 0, desc_open) + 1
        indent = block[line_start:desc_open]
    else:
        insert_pos = len(block.rstrip()) - 1
        indent = "\t\t"

    changes.append(f"{ref}: LCSC='{target_lcsc}' eingefuegt")
    return block[:insert_pos] + schematic_snippet(indent, target_lcsc) + block[insert_pos:]


def process_block_pcb(block: str, ref_to_lcsc: dict[str, str],
                      changes: list[str]) -> str:
    # Reference im PCB ist `(property "Reference" "REF" ...)` ebenso
    return process_block_sch_or_pcb(block, ref_to_lcsc, changes, kind="pcb")


def pcb_snippet(indent: str, value: str) -> str:
    return (
        f'\n{indent}(property "LCSC" "{value}"\n'
        f'{indent}\t(at 0 0 0)\n'
        f'{indent}\t(unlocked yes)\n'
        f'{indent}\t(layer "F.Fab")\n'
        f'{indent}\t(hide yes)\n'
        f'{indent}\t(effects\n'
        f'{indent}\t\t(font\n'
        f'{indent}\t\t\t(size 1 1)\n'
        f'{indent}\t\t\t(thickness 0.15)\n'
        f'{indent}\t\t)\n'
        f'{indent}\t)\n'
        f'{indent})'
    )


def process_block_sch_or_pcb(block: str, ref_to_lcsc: dict[str, str],
                              changes: list[str], kind: str) -> str:
    ref_m = REF_RE.search(block)
    if not ref_m:
        return block
    ref = ref_m.group(1)
    target_lcsc = ref_to_lcsc.get(ref)

    lcsc_m = LCSC_RE.search(block)
    if lcsc_m:
        existing_name = lcsc_m.group(1)
        existing_value = lcsc_m.group(2)
        if target_lcsc is None:
            if existing_name != "LCSC":
                old_head = f'(property "{existing_name}" "{existing_value}"'
                new_head = f'(property "LCSC" "{existing_value}"'
                changes.append(f"{ref}: rename '{existing_name}' -> 'LCSC'")
                return block[: lcsc_m.start()] + new_head + block[lcsc_m.start() + len(old_head):]
            return block
        if existing_name != "LCSC" or existing_value != target_lcsc:
            old_head = f'(property "{existing_name}" "{existing_value}"'
            new_head = f'(property "LCSC" "{target_lcsc}"'
            changes.append(
                f"{ref}: '{existing_name}'='{existing_value}' -> 'LCSC'='{target_lcsc}'"
            )
            return block[: lcsc_m.start()] + new_head + block[lcsc_m.start() + len(old_head):]
        return block

    if target_lcsc is None:
        return block

    desc_m = DESC_RE.search(block)
    if desc_m:
        desc_open = desc_m.start()
        desc_end = find_block_end(block, desc_open)
        insert_pos = desc_end
        line_start = block.rfind("\n", 0, desc_open) + 1
        indent = block[line_start:desc_open]
    else:
        insert_pos = len(block.rstrip()) - 1
        indent = "\t\t"

    snippet = schematic_snippet(indent, target_lcsc) if kind == "sch" else pcb_snippet(indent, target_lcsc)
    changes.append(f"{ref}: LCSC='{target_lcsc}' eingefuegt")
    return block[:insert_pos] + snippet + block[insert_pos:]


def update_text(text: str, head: str, ref_to_lcsc: dict[str, str], kind: str,
                 changes: list[str]) -> str:
    out = []
    last = 0
    for start, end in iter_top_blocks(text, head):
        out.append(text[last:start])
        block = text[start:end]
        new_block = process_block_sch_or_pcb(block, ref_to_lcsc, changes, kind=kind)
        out.append(new_block)
        last = end
    out.append(text[last:])
    return "".join(out)


def write_with_backup(path: Path, new_text: str) -> None:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = path.with_suffix(path.suffix + f".bak_lcsc_{ts}")
    shutil.copy2(path, backup)
    # KiCad-konform: UTF-8 ohne BOM, LF
    path.write_text(new_text, encoding="utf-8", newline="\n")
    print(f"   Backup -> {backup.name}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="Aenderungen schreiben (sonst dry-run)")
    args = ap.parse_args()

    if not BOM_PATH.exists():
        print(f"BOM nicht gefunden: {BOM_PATH}", file=sys.stderr)
        return 1
    ref_to_lcsc = load_bom()
    print(f"\n[BOM] {len(ref_to_lcsc)} Referenzen mit gueltigem LCSC")

    # Schematic
    sch_text = SCH_PATH.read_text(encoding="utf-8")
    sch_changes: list[str] = []
    new_sch = update_text(sch_text, head="symbol", ref_to_lcsc=ref_to_lcsc,
                           kind="sch", changes=sch_changes)
    print(f"\n[SCH] {len(sch_changes)} Aenderungen")
    for c in sch_changes:
        print(f"   - {c}")

    # PCB
    pcb_text = PCB_PATH.read_text(encoding="utf-8")
    pcb_changes: list[str] = []
    new_pcb = update_text(pcb_text, head="footprint", ref_to_lcsc=ref_to_lcsc,
                           kind="pcb", changes=pcb_changes)
    print(f"\n[PCB] {len(pcb_changes)} Aenderungen")
    for c in pcb_changes:
        print(f"   - {c}")

    if not args.apply:
        print("\n(dry-run; mit --apply ausfuehren um zu schreiben)")
        return 0

    if sch_changes:
        write_with_backup(SCH_PATH, new_sch)
        print(f"[SCH] geschrieben: {SCH_PATH.name}")
    else:
        print("[SCH] keine Aenderungen")

    if pcb_changes:
        write_with_backup(PCB_PATH, new_pcb)
        print(f"[PCB] geschrieben: {PCB_PATH.name}")
    else:
        print("[PCB] keine Aenderungen")
    return 0


if __name__ == "__main__":
    sys.exit(main())
