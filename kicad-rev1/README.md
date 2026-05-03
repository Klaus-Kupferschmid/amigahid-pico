# Amiga-HID rev1.0 — KiCad 8 Project

> Stand-alone PCB design for the Amiga 2000 HID keyboard adapter.  
> Independent project — does **not** modify the legacy `kicad/` folder (Pico-module-adapter design).

## Design Status

| Sheet | Status | Notes |
|-------|--------|-------|
| **power** | 📋 Spec'd, awaiting review | This document |
| mcu | ⏳ Pending | RP2350A core + crystal + QSPI flash + BOOTSEL |
| usb | ⏳ Pending | USB-A + USBLC6 ESD |
| level_shifter | ⏳ Pending | TXS0102 for KB_DATA / KB_CLOCK |
| connectors_debug | ⏳ Pending | JST-XH-5A + Debug-Pads + LEDs + SJ1 |

## Iteration Workflow

1. **Spec phase** (this README): Components, nets, connections in tabular form → user reviews electrically
2. **Generate phase**: After approval, `.kicad_sch` files are written with proper symbols & footprints
3. **Footprint phase**: Footprint refs added (LCSC numbers, JLCPCB-friendly packages)
4. **Layout phase**: PCB outline 17×55 mm, component placement, routing

---

## Sheet 1: `power.kicad_sch` — Power Section (DRAFT, AWAITING REVIEW)

### Purpose
Provide regulated 3.3 V to the RP2350A and routed 5 V to the USB-A keyboard host port.  
Fully passive dual-source switching between Amiga (JST) and PC (USB-A↔USB-A flash cable).  
**No firmware logic involved** — power routing is self-correcting in all 4 use cases.

### Components

| Ref  | Value         | LCSC#    | Footprint           | Description                           |
|------|---------------|----------|---------------------|---------------------------------------|
| J_AMIGA | JST-XH-5A  | C157932  | JST_XH_B5B-XH-A     | Amiga / Front Panel connector (J2)    |
| D1   | PMEG2010AEH   | C181276  | SOD-323             | Schottky: Amiga +5V → Board-5V        |
| D2   | PMEG2010AEH   | C181276  | SOD-323             | Schottky: USB-A VBUS → Board-5V       |
| D3   | PMEG2010AEH   | C181276  | SOD-323             | Schottky: Board-5V → USB-A VBUS       |
| F1   | 0.5A PolyFuse | tbd      | 1206                | Tastatur-VBUS overcurrent protection  |
| U1   | AMS1117-3.3   | C6186    | SOT-223             | LDO 5 V → 3.3 V, ≥ 800 mA             |
| C1   | 10 µF / 16 V  | C19702   | 0805                | LDO input bulk cap                    |
| C2   | 100 nF        | C14663   | 0402                | LDO input bypass                      |
| C3   | 22 µF / 6.3 V | tbd      | 0805                | LDO output bulk cap (≥ 22 µF for AMS1117 stability) |
| C4   | 100 nF        | C14663   | 0402                | LDO output bypass                     |

> Note: `J_USB_A_VBUS` is **not** placed on this sheet — it lives on `usb.kicad_sch`.  
> `power.kicad_sch` references it via the hierarchical net **`VBUS`**.

### Nets (Pico 2 Reference Design convention)

| Net          | Purpose                                                        |
|--------------|----------------------------------------------------------------|
| `+5V_AMIGA`  | Pin 2 of JST connector (raw +5 V from Amiga) — additional source, not present on Pico 2 |
| `VBUS`       | USB-A connector VBUS pin — **bidirectional** in this design (input from PC OR output to keyboard). Same name as on the Pico 2 reference, but here it can flow both ways. |
| `VSYS`       | LDO input rail after diode-OR (≈ 4.8 V worst-case). Same role as on Pico 2: "system voltage" feeding the regulator. |
| `+3V3`       | AMS1117-3.3 output → supplies RP2350 (`IOVDD`, `USB_VDD`, `ADC_AVDD`) + all logic |
| `GND`        | Common ground plane                                            |

> The RP2350's internal supply pins (`IOVDD`, `DVDD`, `USB_VDD`, `ADC_AVDD`, `VREG_VIN`, `VREG_VOUT`) are wired on the **mcu** sheet — they all derive from `+3V3` (DVDD via internal LDO).

### Schematic (ASCII)

```
                                ┌──┐
   J_AMIGA (Pin 1, GND) ────────┤  │── GND plane
                                │  │
   J_AMIGA (Pin 2, +5V_AMIGA)─►─D1──►─────┬──── VSYS
                              (PMEG2010)  │
                                          │
   VBUS (USB-A pin) ──────────►──D2──►────┤
                              (PMEG2010)  │
                                          │
                                          │   VSYS
                                          ├──►──D3──►──F1───► VBUS (USB-A pin)
                                          │ (PMEG2010) (0.5A)
                                          │
                                          │      AMS1117-3.3
                                          ├──── VIN          VOUT ───┬──── +3V3
                                          │      │           │       │
                                         C1+C2  GND         GND     C3+C4
                                          ║                          ║
                                         GND                         GND

                  Notes:
                  • D2 + D3 share the same physical USB-A VBUS pin
                    but are oriented opposite → never both conducting
                  • D1, D2 anodes face inputs; D3 anode faces VSYS
                  • F1 in series with D3 (PolyFuse on the keyboard-out path)
                  • VSYS naming follows Pico 2 reference: LDO input rail
```

### Verification — All 4 Use-Cases

| Scenario | D1 | D2 | D3+F1 | VSYS | VBUS (USB-A pin) |
|----------|----|----|-------|------|-------------------|
| Amiga only (normal) | ON | OFF | ON | 4.8 V | 4.55 V → keyboard |
| PC only (flash cable) | OFF | ON | OFF | 4.8 V | 5.0 V from PC |
| Both connected (accident) | weak | weak | OFF | 4.8 V (higher wins) | 5.0 V from PC |
| Keyboard short-circuit | ON | OFF | F1 trips | unchanged | disconnected |

✅ No FW logic. ✅ Brick-resistant. ✅ Crash-safe.

### Voltage Drop Budget (Amiga → Keyboard)

| Element        | V_drop @ 100 mA |
|----------------|-----------------|
| D1 (PMEG2010)  | 0.20 V          |
| D3 (PMEG2010)  | 0.20 V          |
| F1 (PolyFuse)  | 0.05 V          |
| **Total**      | **0.45 V**      |
| **Keyboard sees** | **4.55 V** ✓ within USB spec (min 4.4 V) |

---

## Review Checklist (für User)

Bitte prüfen, dann gebe ich die Freigabe für die `.kicad_sch`-Generierung:

- [ ] Bauteilauswahl korrekt (PMEG2010AEH, AMS1117-3.3, Cap-Werte)
- [ ] Nets-Naming OK (`+5V_AMIGA`, `VBUS`, `VSYS`, `+3V3`) — Pico 2 reference convention
- [ ] Diode-OR Topologie verstanden und akzeptiert
- [ ] LDO-Output-Cap **22 µF** OK (AMS1117 Datenblatt verlangt ≥ 22 µF tantalum oder ≥ 22 µF X7R für Stabilität — manchmal reicht auch 10 µF, ist aber riskant)
- [ ] PolyFuse-Wert 500 mA OK (Reicht für die meisten USB-Tastaturen; Wireless-Dongles brauchen i.d.R. < 100 mA)
- [ ] LCSC-Nummern sind aktuell (Stand 2025)

Sobald alles OK → ich generiere `power.kicad_sch` als echte KiCad-8-Datei.
