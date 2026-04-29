# amigahid-pico - Projekt-Dokumentation

> USB-HID Keyboard Adapter für Amiga 2000 mit RP2350A

## Projekt-Status (Stand: 28.04.2026)

### ✅ Erledigt
- [x] Fork synchronisiert mit upstream (borb/amigahid-pico)
- [x] Repository geklont mit allen Submodules (pico-sdk 2.2.0)
- [x] VSCode Entwicklungsumgebung konfiguriert
- [x] Firmware erfolgreich gebaut für Pico 2 (RP2350)
- [x] Build-Output: `build_pico2/src/amigahid-pico.uf2` (140 KB)

### ⏳ Nächste Schritte
- [ ] TXS0108E Modul verdrahten (heute/morgen)
- [ ] Firmware auf Pico 2 flashen
- [ ] Test mit Dell KB900 Tastatur
- [ ] UART-Debug mit YP-01A einrichten
- [ ] PCB-Design für Produktiv-Board (52×15mm)

---

## Hardware-Architektur

### System-Übersicht
```
┌──────────────────┐     USB      ┌─────────────────┐
│ Dell KB900       │────────────▶│ Pico 2 (RP2350) │
│ + 2.4GHz Dongle  │              │ USB Host        │
└──────────────────┘              └────────┬────────┘
                                           │ 3.3V
                                           ▼
                                  ┌─────────────────┐
                                  │ TXS0102/TXS0108E│
                                  │ Level Shifter   │
                                  └────────┬────────┘
                                           │ 5V
                           J2 Connector    ▼
┌──────────────────┐      (5-Pin)  ┌─────────────────┐
│ Amiga 2000       │◀─────────────│ Ultimate Front  │
│ CIA Keyboard     │              │ Panel (STM32)   │
└──────────────────┘              └─────────────────┘
```

### J2 Connector Pinout
| Pin | Signal | Richtung | Beschreibung |
|-----|--------|----------|--------------|
| 1 | GND | - | Masse |
| 2 | +5V | → | Spannungsversorgung vom Amiga |
| 3 | _KBDATA_USB | ↔ | Keyboard Data (bidirektional) |
| 4 | NC | - | Nicht verbunden |
| 5 | _KBCLK_USB | ↔ | Keyboard Clock (bidirektional) |

### Warum Level-Shifter?
- **RP2350 ist NICHT 5V-tolerant!** (max. 3.63V auf GPIO)
- Amiga verwendet 5V TTL-Pegel
- TXS0102 ist bidirektional - wichtig für Amiga Keyboard-Protokoll

---

## Verkabelung Test-Setup

### Pico 2 → TXS0108E → J2
```
Pico 2                TXS0108E               J2
──────                ────────               ──
3V3 ────────────────▶ VA (3.3V side)
                      VB ◀──────────────── +5V (Pin 2)
GND ────────────────▶ GND ◀──────────────── GND (Pin 1)
GP5 (KBDATA) ───────▶ A1 ──▶ B1 ──────────▶ KBDATA (Pin 3)
GP6 (KBCLK) ────────▶ A2 ──▶ B2 ──────────▶ KBCLK (Pin 5)
                      OE ◀──────────────── VA (immer enabled)
```

### UART Debug (YP-01A)
```
Pico 2          YP-01A
──────          ──────
GP0 (TX) ─────▶ RX
GP1 (RX) ◀───── TX
GND ───────────▶ GND
3V3 ───────────▶ 3V3 (WICHTIG: nicht 5V!)
```

### I²C Display (SSD1309)
```
Pico 2          SSD1309
──────          ───────
GP2 (SDA) ────▶ SDA
GP3 (SCL) ────▶ SCL
3V3 ──────────▶ VCC
GND ──────────▶ GND
```

---

## Build-Anleitung

### Voraussetzungen (Windows 11)
- Visual Studio 2022/2024 mit C++ Build Tools
- ARM GCC Toolchain (`C:\Program Files (x86)\Arm GNU Toolchain arm-none-eabi\14.3 rel1`)
- CMake (`C:\Program Files\CMake\bin`)
- Ninja (`winget install Ninja-build.Ninja`)
- Python 3.12 (`winget install Python.Python.3.12`)

### Build
```powershell
# Option 1: Build-Script (empfohlen - setzt MSVC Environment)
cmd /c build-pico2.cmd

# Option 2: VSCode Task
# Ctrl+Shift+B → "Build (Pico 2)"

# Option 3: Manuell
cmake -S . -B build_pico2 -G Ninja `
    -DPICO_PLATFORM=rp2350 `
    -DPICO_BOARD=pico2 `
    -DBOARD_TYPE=BOARD_HIDPICO_REV4
cmake --build build_pico2
```

### Flash
```powershell
# 1. Pico 2 in BOOTSEL-Modus bringen:
#    - BOOTSEL-Taste halten
#    - USB-Kabel anschließen
#    - BOOTSEL loslassen
#    → Laufwerk "RP2350" erscheint

# 2. Flashen:
.\flash-uf2.ps1

# Oder manuell:
# Kopiere build_pico2\src\amigahid-pico.uf2 auf das RP2350-Laufwerk
```

---

## JLCPCB BOM (Produktiv-Board)

### Spannungsversorgung
| Bauteil | Wert | LCSC# | Package | Typ |
|---------|------|-------|---------|-----|
| U1 | AMS1117-3.3 | **C6186** | SOT-223 | ✅ Basic |
| C1, C2 | 10µF/16V | C19702 | 0805 | ✅ Basic |
| C3 | 100nF | C14663 | 0402 | ✅ Basic |

### MCU & Peripherie
| Bauteil | Wert | LCSC# | Package | Preis |
|---------|------|-------|---------|-------|
| U2 | RP2350A | **C42411118** | QFN-60 | $1.06 |
| U3 | W25Q16JVSSIQ | C131024 | SOIC-8 | $0.30 |
| Y1 | 12MHz | C9002 | 3215 | $0.05 |
| C4, C5 | 15pF | C1644 | 0402 | $0.001 |

### Level-Shifter
| Bauteil | Wert | LCSC# | Package |
|---------|------|-------|---------|
| U4 | TXS0102 | (TBD) | TSSOP-8 |

### Connectors
| Bauteil | Typ | LCSC# | Position |
|---------|-----|-------|----------|
| J1 | USB-A Buchse | C46407 | Stirnseite |
| J2 | JST-XH-5A | C157932 | Rückseite |

### Optional
| Bauteil | Wert | LCSC# | Funktion |
|---------|------|-------|----------|
| SW1 | Reset | C318884 | Notfall-Reset |
| D1 | LED grün 0603 | C72043 | Status |
| R1 | 150Ω 0402 | C25082 | LED-Vorwiderstand |

---

## Board-Layout

```
                    52mm
        ┌─────────────────────────┐
        │  ┌─────────────────┐    │
        │  │    USB-A        │    │  ← Stirnseite (zum USB-Dongle)
        │  │    Buchse       │    │
        │  └─────────────────┘    │
        │                         │
        │   [U2]      [U3]        │
        │  RP2350A   Flash        │  15mm
        │                         │
        │   [U1]      [U4]        │
        │   LDO     TXS0102       │
        │                         │
        │  ┌─────────────────┐    │
        │  │   JST-XH-5A    │    │  ← Rückseite (zu J2/Amiga)
        │  └─────────────────┘    │
        └─────────────────────────┘
```

---

## Debugging

### UART-Ausgabe aktivieren
Bereits konfiguriert in `src/CMakeLists.txt`:
```cmake
pico_enable_stdio_uart(amigahid-pico 1)
```

### Debug-Funktionen im Code
- `ahprintf()` - Debug-Ausgabe (src/util/output.h)
- `disp_write()` - Display-Ausgabe
- `dbgcons_init()` - Debug-Console initialisieren

### Terminal-Verbindung
```powershell
# PuTTY oder:
# 1. COM-Port finden (Gerätemanager)
# 2. Verbinden mit 115200 baud
```

---

## Referenzen

- **Upstream**: https://github.com/borb/amigahid-pico
- **Fork**: https://github.com/Klaus-Kupferschmid/amigahid-pico
- **pico-sdk**: Version 2.2.0 (mit RP2350-Support)
- **Amiga Keyboard Protocol**: http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0172.html
