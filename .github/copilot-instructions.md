# Copilot Instructions für amigahid-pico

## Projekt-Übersicht
USB-HID Keyboard Adapter für Amiga 2000 basierend auf RP2350A (Pico 2).
Konvertiert moderne USB-Tastaturen zu Amiga-kompatiblem Keyboard-Protokoll.

## Arbeitsregeln für KI-Assistenten (persistent über alle Rechner/Chats/Modelle)

### Synchron halten bei jeder HW-Änderung
Folgende Dateien spiegeln dieselbe Wahrheit wider und müssen bei jeder Bauteil-/Pinning-/Footprint-Änderung **gemeinsam** aktualisiert werden:
- [`kicad-rev1/_bom.csv`](../kicad-rev1/_bom.csv) — kanonische BOM, 4 Spalten: `Reference, Value, Footprint, LCSC`
- `.github/copilot-instructions.md` (diese Datei) — REV5 GPIO-Mapping, kritische BOM, Debug-Pads, 3D-Modelle
- `kicad-rev1/Amiga-HID_rev1.0.kicad_sch` — `Footprint`-Property pro Symbol muss zur BOM passen
- `kicad-rev1/Amiga-HID_rev1.0.kicad_pcb` — eingebettete Footprints + 3D-Modell-Refs

### Konventionen
- **Project-local 3D-Modelle**: `kicad-rev1/Amiga-HID_rev1.0.pretty/3d/<LCSC>_<descr>.{step,wrl}`
- **easyeda2kicad Quell-Cache**: `kicad-rev1/_easyeda_dl/<LCSC>.*` — nur tatsächlich eingebaute Teile aufbewahren, falsche Downloads sofort wegwerfen
- **Offizielle KiCad-3D-Lib hat KEIN JST_SH/PH/XH** (nur JST_EH) → solche Stecker grundsätzlich projektlokal über easyeda2kicad ziehen, in `pretty/3d/` ablegen, im PCB per `${KIPRJMOD}/...`-Pfad referenzieren

### PowerShell BOM-Falle (kritisch!)
- **NIE** `Set-Content -Encoding UTF8` (schreibt UTF-8-BOM → KiCad-Parser scheitert lautlos, Datei wirkt "leer")
- **Stattdessen** immer:
  ```powershell
  [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding($false)))
  ```

### Bestätigte LCSC-Mapping-Highlights (Stand REV5)
| Bauteil | LCSC | Footprint/Hinweis |
|---|---|---|
| RP2350A | C42411118 | QFN-60 |
| USB-A J1 | **C42614** | Jing JTJ THT recessed, JLCPCB Extended Part, Body überhängt N-Kante (kein Cutout) |
| JST-SH 3pin J5+J6 | **C160403** | SM03B-SRSS-TB, side-entry SMD, identische Teile |
| JST-XH-5A J2 | C157932 | B5B-XH-A vertical |
| Schottky D1/D2/D3 | C181276 | PMEG2010AEH SOD-323 |
| TXS0102 U5 | C53411 | VSSOP-8 Level-Shifter |
| W25Q16JVSSIQ U3 | **C82317** | SOIC-8 5.3×5.3 mm P1.27, 2 MB QSPI Flash (ersetzt W25Q128JVS 16 MB — 2 MB reichen locker, Pico-2-Reference); bei RP2354A-Variante DNP |
| USBLC6-2SC6 U1 | C7480 | SOT-23-6 ESD |
| AMS1117-3.3 U2 | C6186 | SOT-223 LDO |
| Crystal 12 MHz Y1 | C9002 | 3225-4P |
| Inductor 2.2µH L1 | **C1046** | L_pol_2016 (Sunlord 0805 chip inductor, JLCPCB Basic; ersetzt C408232 weil dort kein EasyEDA-3D verfügbar) |
| Tact-Switch SW1/SW2 | **C139797** | SW_SMD_Tact_4x3_4P_C139797 (4,2×3,2 mm SMD vertical, kompakt; ersetzt teures Würth 434133025816) |
| 100nF 0402 (×17) | C14663 | C2/C4/C7/C10/C13/C15-C23 |
| 10µF 0805 (×2) | C19702 | C1/C14 |

## Hardware-Kontext

### Ziel-Hardware
- **Test-Board**: Raspberry Pi Pico 2 (RP2350)
- **Produktiv-MCU**: RP2350A (QFN-60, 7×7mm)
- **Board-Abmessungen REV5 / Amiga-HID rev1.0**: **20 × 55 mm** (eigene PCB, passt in bestehendes Gehäuse)
  - Kurze Seite (20 mm) Nord: **USB-A Buchse** (Host-Port für Tastatur, recessed/edge-mount THT)
  - Kurze Seite (20 mm) Süd: **JST-XH-5A** (Verbindung zum Amiga / Front Panel)
  - Lange Seite (55 mm) links: **Lötpads / Connectors** für Debug & Display (siehe Debug-Pads)

### KiCad-Projekt
- **Aktuelles Quellprojekt**: `kicad-rev1/Amiga-HID_rev1.0.kicad_pro` (KiCad 8.0.6 → Migration auf KiCad 10.x in Vorbereitung)
- **Veraltet** (nicht mehr pflegen): das alte `kicad/`-Verzeichnis (war Pico-Modul-Adapter-Design)
- Projekt-lokale Footprints: `kicad-rev1/Amiga-HID_rev1.0.pretty/`
- 3D-Modelle: einige projekt-lokal unter `…pretty/3d/` (USB-A C42614, JST-SH C160403 — letzteres weil offizielle KiCad-3D-Library für `Connector_JST` **nur** JST_EH abdeckt, nicht JST_SH/PH/XH), Rest aus `${KICAD8_3DMODEL_DIR}` (KiCad-Standard 3D-Library, separat installieren)
- **Quell-Cache** projekt-lokaler Teile: `kicad-rev1/_easyeda_dl/` (via easyeda2kicad gezogen, nur eingebaute Teile aufbewahrt)
- **Kanonische BOM**: [`kicad-rev1/_bom.csv`](../kicad-rev1/_bom.csv) (4 Spalten: Reference, Value, Footprint, LCSC)

### Bestehendes System
- **Ultimate Front Panel**: Eigenes Board mit STM32F103CBT6 (BluePill)
- **J2 Connector**: 5-Pin Verbindung zum Amiga (GND, +5V, KBDATA, NC, KBCLK)
- Das neue RP2350-Board verbindet sich über J2 mit dem bestehenden System

### Level-Shifting (WICHTIG!)
- RP2350 ist NICHT 5V-tolerant!
- Amiga verwendet 5V TTL-Pegel
- **Lösung**: TXS0102 bidirektionaler Level-Shifter (3.3V ↔ 5V)
- Test-Hardware: TXS0108E Modul von AZDelivery

### Spannungsversorgung
- J2 liefert nur 5V vom Amiga
- **LDO erforderlich**: AMS1117-3.3 (SOT-223)

## GPIO-Mapping

### config.h REV4 (Test-Hardware: Pico 2 + Breadboard)

| GPIO | Funktion | Verbindung |
|------|----------|------------|
| GP4 | KBD_AMIGA_RST | (nicht verwendet für Amiga 2000) |
| GP5 | KBD_AMIGA_DAT | → TXS0108E → J2 KBDATA |
| GP6 | KBD_AMIGA_CLK | → TXS0108E → J2 KBCLK |
| GP2 | I2C1_SDA | SSD1309 Display |
| GP3 | I2C1_SCL | SSD1309 Display |
| GP0 | UART TX | Debug via YP-01A |
| GP1 | UART RX | Debug via YP-01A |
| GP25 | LED | Onboard LED (Pico 2) |

### REV5 / Amiga-HID rev1.0 (Produktiv-PCB)

| GPIO | Funktion        | Verbindung                                          |
|------|-----------------|-----------------------------------------------------|
| GP0  | UART_TX         | Debug-Bereich A (JST-SH UART Pin 1) → Pi Debug Probe RX |
| GP1  | UART_RX         | Debug-Bereich A (JST-SH UART Pin 3) ← Pi Debug Probe TX |
| GP2  | I2C1_SDA        | OLED SSD1309 (Debug-Bereich B Pad B4)               |
| GP3  | I2C1_SCL        | OLED SSD1309 (Debug-Bereich B Pad B3)               |
| GP4  | KBD_AMIGA_RST   | reserviert (am Amiga 2000 ungenutzt)                |
| GP5  | KBD_AMIGA_DAT   | → TXS0102 → J2 Pin 3 (KB_DATA, 5 V)                 |
| GP6  | KBD_AMIGA_CLK   | → TXS0102 → J2 Pin 5 (KB_CLOCK, 5 V)                |
| GP7  | GP_RES1         | Reserve, herausgeführt auf Debug-Bereich B Pad B8   |
| GP8  | GP_RES2         | Reserve, herausgeführt auf Debug-Bereich B Pad B9   |
| GP16 | LED2 (Activity) | LED2 (USB-Aktivität), Tiny-Board-Konvention         |
| GP25 | LED1 (Status)   | LED1 (Power/Status), Pico-Konvention                |
| –    | USB D+/D-       | direkt an USB-A J1 (über USBLC6-2SC6 ESD-Schutz)    |
| –    | SWCLK/SWDIO     | Debug-Bereich A (JST-SH SWD)                        |
| –    | QSPI            | W25Q128JVS Flash (16 MB) – siehe BOM                |

## Build-Konfiguration

### CMake-Parameter
```
-DPICO_PLATFORM=rp2350
-DPICO_BOARD=pico2
-DBOARD_TYPE=BOARD_HIDPICO_REV4
```

### Build-Befehle
```powershell
# Via MSVC Developer Command Prompt:
cmd /c build-pico2.cmd

# Oder manuell:
cmake -S . -B build_pico2 -G Ninja -DPICO_PLATFORM=rp2350 -DPICO_BOARD=pico2 -DBOARD_TYPE=BOARD_HIDPICO_REV4
cmake --build build_pico2
```

### Flash
```powershell
# BOOTSEL-Modus: Halte BOOTSEL, verbinde USB
.\flash-uf2.ps1
# Oder manuell: Kopiere build_pico2/src/amigahid-pico.uf2 auf RP2350-Laufwerk
```

## Debug-Setup

### UART Debug
- **Adapter**: YP-01A USB-TTL
- **Spannung**: 3.3V (NICHT 5V!)
- **Baudrate**: Standardmäßig 115200
- `pico_enable_stdio_uart(amigahid-pico 1)` ist in CMakeLists.txt aktiviert

### I²C Display
- **Display**: SSD1309 (M242-12864-4-V2.0), 128×64 Pixel
- **Adresse**: 0x3C (Standard)
- **Pins**: GP2 (SDA), GP3 (SCL)

## Test-Hardware
- **Tastatur**: Dell KB900 mit 2.4GHz USB-Dongle
- Business-Tastatur → sollte Boot Protocol unterstützen

## JLCPCB BOM (Produktiv-Board, Stand Amiga-HID rev1.0)

> Kanonische BOM-Quelle: [`kicad-rev1/_bom.csv`](../kicad-rev1/_bom.csv) (aus dem Schaltplan generiert).
> Tabelle hier ist die **Sicht auf die kritischen Teile mit JLCPCB-Bestellnummern**.

### Kritische Teile
| Bauteil                  | LCSC#       | Package                          | Hinweis                             |
|--------------------------|-------------|----------------------------------|-------------------------------------|
| RP2350A                  | C42411118   | QFN-60                           | MCU                                 |
| W25Q16JVSSIQ (Flash 2 MB)| C82317      | SOIC-8 (5.3×5.3 mm, P1.27)       | Pico-2-Ref-konform; bei Bestückung mit RP2354A → **DNP** |
| AMS1117-3.3              | C6186       | SOT-223                          | LDO 5 V → 3,3 V                     |
| JST-XH-5A (B5B-XH-A)     | C157932     | THT 2,5 mm                       | J2 → Amiga / Front Panel            |
| **USB-A Buchse J1**      | **C42614**  | **THT recessed/edge-mount**      | Jing Extension 905-261A1011D10100, JLCPCB Extended Part; Body überhängt Nordkante (kein Edge.Cuts-Cutout nötig) |

## Bekannte Einschränkungen
- Kein `reset_usb_boot()` im Code - BOOTSEL-Button nötig für Firmware-Updates
- Amiga 2000 hat keinen KBRST-Pin - nur KBDATA und KBCLK werden benötigt

## Schaltplan-Korrekturen REV5 (TODO im KiCad-Editor nachziehen!)

Folgende Änderungen sind in der BOM bereits umgesetzt, müssen aber im Schaltplan/PCB **manuell nachgezogen** werden:

### 1. R3 KOMPLETT ENTFERNEN (kritisch!)
- **Position**: derzeit als Bridge zwischen UART_TX und QSPI_SS (Bus-Knoten mit R4/R5)
- **Problem**: Bei Bestückung würde jeder UART-Print den Flash-CS togglen → Boot-/Flash-Crash
- **Aktion**: R3-Symbol im Schaltplan löschen, Wire UART_TX direkt an JST-SH J6 Pin 1 ziehen
- Footprint im PCB ebenfalls löschen oder unbenutzt lassen
- BOM-Eintrag R3 ist bereits entfernt

### 2. R5 = 10 kΩ bestücken (vorher DNF)
- **Funktion**: QSPI_SS Pullup gegen +3V3 (Pico-2-Reference Pflicht)
- Ohne Pullup: QSPI_SS floatet beim Boot → instabiler Boot-Modus, evtl. ungewolltes BOOTSEL
- BOM bereits auf 10 kΩ / C25804 geändert
- **Bei RP2354A-Variante (flashless)**: trotzdem bestückt lassen, schadet nicht

### 3. R4 bleibt 0 Ω (unverändert)
- Verbindet QSPI_SS-Label mit dem Mittel-Knoten (R4/R5)
- 0 Ω = direkte Durchverbindung, im Pico-2-Ref so vorgesehen

### 4. UART Serien-Widerstände NEU einfügen (Variante B, defensiv)
Nach Entfernung von R3 sollen **zwei separate** Serien-Widerstände in den UART-Pfad:

| Ref  | Wert | Position                              | Zweck                              |
|------|------|---------------------------------------|------------------------------------|
| R12  | 33 Ω | MCU GP0 → R12 → UART_TX → J6 Pin 1   | Serien-Termination/ESD-Schutz TX   |
| R13  | 33 Ω | J6 Pin 3 → UART_RX → R13 → MCU GP1   | Serien-Termination/ESD-Schutz RX   |

- Footprint: 0402, LCSC C25104 (33 Ω)
- BOM-Einträge bereits angelegt
- **NICHT** an den alten R3-Knoten (mit R4/R5) anschließen — R12 und R13 sind reine Inline-Serie zwischen MCU und JST-Header

### 5. I²C Pullup-Pads R14/R15 als DNF vorsehen
Das SSD1309-Modul M242-12864 hat bereits Onboard-Pullups, daher keine externen Pullups nötig. Trotzdem Pads für spätere Module vorsehen:

| Ref  | Wert | Position                | Zweck                              |
|------|------|-------------------------|------------------------------------|
| R14  | DNF  | I2C1_SDA → +3V3 (4,7 kΩ Bestückungs-Option) | Optionaler Pullup falls anderes Modul ohne eigene Pullups |
| R15  | DNF  | I2C1_SCL → +3V3 (4,7 kΩ Bestückungs-Option) | dito |

- Footprint: 0402
- Bestückungswert wenn nötig: 4,7 kΩ (Standard für 100–400 kHz I²C)
- BOM hat R14/R15 als DNF eingetragen

### Topologie-Skizze nach Korrektur

```
  +3V3
    │
    R5 (10kΩ)         ← NEU bestückt
    │
    ├─ R4 (0Ω) ── QSPI_SS ── U3 /CS
    │
    (R3 ENTFERNT)

  MCU GP0 ──── R12 (33Ω) ──── UART_TX ──── J6 Pin 1   ← NEU
  MCU GP1 ──── R13 (33Ω) ──── UART_RX ──── J6 Pin 3   ← NEU

  +3V3 ── R14 (DNF) ── I2C1_SDA ── GP2   ← Pad reserviert
  +3V3 ── R15 (DNF) ── I2C1_SCL ── GP3   ← Pad reserviert
```

## Bestückungsvarianten (eine PCB, zwei BOMs)
Das Layout unterstützt beide MCU-Varianten ohne Änderung am Board:

| Bauteil          | Variante A: RP2350A + ext. Flash | Variante B: RP2354A flashless |
|------------------|----------------------------------|-------------------------------|
| U4 (MCU)         | RP2350A (C42411118)              | **RP2354A** (pinkompatibel QFN-60) |
| U3 (QSPI Flash)  | W25Q16JVSSIQ (C82317), 2 MB      | **DNP**                       |
| C an U3 VCC      | 100 nF bestückt                  | **DNP**                       |
| QSPI_SS Pullup   | bestückt (10 kΩ)                 | bestückt (schadet nicht, definierter Pegel) |
| Rest             | identisch                        | identisch                     |

**Layout-Regeln** (für beide Varianten gültig, daher schon im Default-Design erfüllt):
- QSPI-Leitungen MCU↔U3 kurz halten (< 15 mm) — bei RP2354A einfach floatend, kein Problem
- QSPI_SS Pullup 10 kΩ gegen 3V3 immer bestücken (definierter Pegel)
- U3-Versorgung 100 nF nahe Pin 8 — wird in Variante B mit-DNP'd

**Wann welche Variante**:
- **Variante A (Default)**: RP2350A breit verfügbar, W25Q16 ~0,30 €. Wirtschaftlichster Standardfall.
- **Variante B**: nur sinnvoll wenn RP2354A bei JLCPCB als Basic Part verfügbar wird oder wenn man absolut minimale BOM will. Spart 2 SMD-Bauteile, verteuert aber den MCU.

---

## Eigene PCB REV5 (Produktiv-Design)

### Mechanik & Stecker
- **Größe**: 17 × 55 mm, **4-lagig** (sauberer GND-Plane + Power-Plane wegen USB + 12 MHz Quartz + EMV)
- **USB-A Buchse** (einzige USB-Buchse) an einer 17-mm-Schmalseite
  - Im **Normalbetrieb**: Host-Port → versorgt USB-Tastatur mit 5 V
  - Im **Flash-Betrieb**: Device-Port → wird über **USB-A-zu-USB-A-Kabel** vom PC versorgt und programmiert
  - **Keine zweite USB-Buchse**, kein USB-Mux nötig — RP2350 D+/D- gehen direkt an die USB-A-Buchse
- **JST-XH-5A** an gegenüberliegender 17-mm-Schmalseite (Verbindung zum Amiga / Ultimate Front Panel)
- **Debug-Pads** als durchgehende 2,54-mm-Pin-Reihe entlang der linken 55-mm-Langseite (siehe unten)
- **Mini BOOTSEL-Taster** (SMD Tact-Switch) auf der Platine – als Notfall-Fallback, falls Tastatur-Shortcut nicht funktioniert

### JST-XH-5A Pinout (J2 zum Amiga)
| Pin | Signal      | Verbindung im Board                          |
|-----|-------------|----------------------------------------------|
| 1   | GND         | Massefläche                                  |
| 2   | +5 V        | → Power-Mux/Dioden-OR → VSYS (RP2350A)       |
| 3   | KB_DATA     | → TXS0102 → GPIO5                            |
| 4   | NC          | nicht belegt                                 |
| 5   | KB_CLOCK    | → TXS0102 → GPIO6                            |

### Spannungsversorgung – rein passiv (3× Schottky + PolyFuse), KEINE FW-Logik
**Designprinzip**: Power-Routing **ausschließlich elektronisch**, kein Load-Switch, keine MCU-Steuerung. Damit ist das Board **immer korrekt versorgt**, egal ob FW läuft, abgestürzt ist oder gerade neu geflasht wird.

**Anwendungsfälle (alle automatisch korrekt behandelt):**
- **Normalbetrieb am Amiga**: 5 V vom **JST Pin 2** → Board → versorgt Tastatur am USB-A
- **Flashen am PC**: Tastatur ab, **USB-A↔USB-A-Kabel zum PC** in dieselbe Buchse → PC versorgt Board
- **Beide gleichzeitig (Unfall)**: höhere Quelle "gewinnt" via Diode-OR, kein Schaden
- **Tastatur-Kurzschluss**: PolyFuse trennt bei > 500 mA

**Schaltungstopologie:**

```
            ┌─[D1: PMEG2010AEH]◄── JST Pin 2 (+5 V vom Amiga)
            │
Board-5V ◄──┼─[D2: PMEG2010AEH]◄── USB-A VBUS pin (PC speist Board beim Flashen)
            │                              ▲
            │                              │
            └─[D3: PMEG2010AEH]──[F1: PolyFuse 500mA]──► USB-A VBUS pin (Board speist Tastatur)

Board-5V ──► AMS1117-3.3 ──► 3,3 V Rail (RP2350 + Logik)
```

**Funktionsweise im Detail:**

| Szenario               | D1 | D2 | D3+F1 | Board-5V         | USB-A VBUS pin   |
|------------------------|----|----|-------|------------------|------------------|
| Nur Amiga (Normalfall) | ON | OFF| ON    | 4,8 V (Amiga−D1) | 4,55 V → Tastatur|
| Nur PC (Flash-Kabel)   | OFF| ON | OFF   | 4,8 V (PC−D2)    | 5,0 V (vom PC)   |
| Beide gleichzeitig     | ~  | ~  | OFF   | 4,8 V (höhere)   | 5,0 V (vom PC)   |
| Tastatur-Kurzschluss   | ON | OFF| **F1 trippt** | unverändert  | abgetrennt       |

**Warum kein Konflikt zwischen D2 und D3** (hängen am selben physischen VBUS-Pin):
- D2 ist orientiert **Pin → Board** (Eingang PC→Board)
- D3 ist orientiert **Board → Pin** (Ausgang Board→Tastatur)
- Beide gleichzeitig leitend wäre nur möglich, wenn `Pin > Board` UND `Board > Pin` → physikalisch unmöglich.
- Folge: bei PC-Speisung ist D3 reverse-biased → kein Rückstrom durch F1.

**Bauteilauswahl – warum PMEG2010AEH statt SS14:**

USB-Spec verlangt min. **4,4 V** für die Tastatur. Verlustbudget Amiga→Tastatur:
- SS14 (Vf ≈ 0,3 V @ 100 mA) × 2 + PolyFuse (~0,05 V) = **0,65 V** → Tastatur sieht **4,35 V** ⚠️ unter Spec
- PMEG2010AEH (Vf ≈ 0,2 V @ 100 mA) × 2 + PolyFuse (~0,05 V) = **0,45 V** → Tastatur sieht **4,55 V** ✓
- → **PMEG2010AEH dringend empfohlen** (LCSC: C181276, ~0,06 €/Stück)

**Vorteile dieser passiven Lösung:**
- ✅ **MCU-Crash-sicher**: kein FW-Bug kann das Power-Routing beschädigen
- ✅ **Brick-resistant**: funktioniert auch mit "leerer" oder defekter FW (BOOTSEL möglich)
- ✅ **Keine GPIO belegt**: alle Pins frei für andere Funktionen
- ✅ **Keine Sequencing-Komplexität** in der Firmware
- ✅ **Günstiger** als Load-Switch IC (~0,30 € vs. ~0,40 €)

**WICHTIG – USB-Schutzbeschaltung:**
- **USBLC6-2SC6** ESD-Schutz auf D+/D- der USB-A-Buchse
- **PolyFuse 500 mA** (1206, z.B. mF-MSMF050) in Reihe mit D3 → schützt sowohl Tastatur (Kurzschluss) als auch Board (versehentlicher VBUS-Kurzschluss)

### Referenzdesign Pico 2 – übernommene Bauteile
| Bauteil                      | Wert/Typ           | Funktion                          |
|------------------------------|--------------------|-----------------------------------|
| RP2350A (oder RP2354A)       | QFN-60             | MCU – pinkompatible Alternative RP2354A hat 2 MB Stacked Flash intern → U3 dann DNP |
| W25Q16JVSSIQ                 | 16 Mbit QSPI Flash | Boot/Programm-Flash (entfällt bei RP2354A) |
| AMS1117-3.3                  | SOT-223            | LDO 5 V → 3,3 V (≥ 800 mA)        |
| Crystal 12 MHz               | XRCGB12M000F0Z00R0 | Systemtakt (lt. Pico 2 Schaltplan)|
| Lastkondensatoren XTAL       | 2× 15 pF C0G       | Quartz-Beschaltung                |
| Decoupling 100 nF / 10 µF    | je VDD-Pin         | nach Pico 2 Reference             |
| Reset-RC + Pullups (RUN, QSPI_SS) | 10 kΩ / 1 µF  | nach Pico 2 Reference             |
| TXS0102DCUR                  | VSSOP-8            | Bidir Level-Shifter 3,3 V ↔ 5 V   |

> Schaltplan-Vorlage: **Raspberry Pi Pico 2 Reference Design** (offizielles PDF von raspberrypi.com). Alle Pull-ups, Caps und der QSPI-Flash-Block 1:1 übernehmen.

### LEDs (User Indicators)
- Pico 1 und Pico 2 haben jeweils nur **eine** Onboard-LED an **GP25**.
- Tiny-Boards mit weniger GPIOs (Waveshare RP2040-Zero, Seeed XIAO RP2040) nutzen oft **GP16** für die User-LED (dort als WS2812 NeoPixel) → diese Konvention für REV5 übernehmen.
- **REV5 LED-Mapping**:
  - **LED1 (Power/Status)**: **GP25** – kompatibel mit Pico-Konvention, vom Code bereits genutzt
  - **LED2 (Activity / USB-Traffic)**: **GP16** – Tiny-Board-Konvention
- LED-Typ: SMD 0603, mit Vorwiderstand (≈ 1 kΩ, ggf. 2,2 kΩ für niedrigere Helligkeit) gegen GND, Anode an GPIO

### BOOTSEL-Taster (Hardware-Fallback)
- **Mini SMD Tact-Switch** (z.B. 3×4 mm) auf der Platine
- Verbindung wie auf Pico 2: zwischen **QSPI_SS** und GND, beim Booten gedrückt halten → BOOTSEL-Modus
- **Zweck**: Notfall-Fallback, falls Tastatur-Shortcut nicht funktioniert (z.B. Firmware-Crash, defekte Tastatur)
- Im Normalbetrieb soll der Bootloader **per Tastatur-Shortcut aus der laufenden Firmware** ausgelöst werden (siehe unten)
- Im eingebauten Zustand schwer zugänglich → **nicht** für Routine-Updates gedacht

### Debug-Pads (linke 55-mm-Langseite)
Zwei räumlich getrennte Pad-Bereiche entlang der Langseite, jeder im **eigenen Raster** passend zur jeweiligen Steckverbindung. In **jedem** Bereich sind alle Pads im konstanten Raster, sodass alternativ zu den Steckverbindungen auch eine **durchgehende Stiftleiste** im selben Raster eingelötet werden kann.

#### Bereich A: Pi-Debug-Probe (1,0 mm Pitch, 10 Pads)

Direkt kompatibel mit dem **Raspberry Pi Debug Probe** und dessen mitgelieferten **JST-SH 3-Pin Kabeln (1,0 mm Pitch)**. Beide Probe-Stecker (SWD + UART) als JST-SH-Buchsen direkt auf der Platine. Kabel mit JST-SH auf **beiden** Seiten verbinden Probe und Board ohne Adapter.

**Geometrie-Hinweis**: Eine JST-SH 3-Pin-Buchse hat bei 1,0 mm Pin-Pitch ein Gehäuse von ca. **4,5 mm Breite** (≈ 1,25 mm Überstand pro Seite über die äußeren Pins). Zwei Buchsen direkt nebeneinander auf 1,0-mm-Raster kollidieren mechanisch → **2 Füll-Pads (GND)** zwischen den Buchsen erforderlich. Vorteil: doppelte GND-Schirmung der SWD/UART-Signale.

> **Hinweis zu RUN/Reset**: Es gibt **keinen** RUN-Pad mehr im Debug-Bereich. Reset erfolgt ausschließlich über den **Mini BOOTSEL-Taster** auf der Platine (siehe oben) bzw. softwareseitig über den Tastatur-Shortcut. Pi Debug Probe braucht für SWD-Sessions kein eigenes RUN — `openocd` triggert Soft-Reset über SWD.

**Pad-Reihenfolge Bereich A (Nord → Süd, alle 1,0 mm Pitch):**

| #  | Signal     | GPIO  | Stecker          | Funktion                        |
|----|------------|-------|------------------|---------------------------------|
| A1 | GND        | –     | –                | Masse-Pad / Pre-Pad             |
| A2 | **SWCLK**  | SWCLK | **JST-SH 1 (SWD)** Pin 1 | SWD Clock              |
| A3 | **GND**    | –     | JST-SH 1 (SWD) Pin 2 | Probe-Masse                |
| A4 | **SWDIO**  | SWDIO | JST-SH 1 (SWD) Pin 3 | SWD Data                   |
| A5 | GND        | –     | (Füll-Pad 1)     | Abstand zwischen JST-Gehäusen   |
| A6 | GND        | –     | (Füll-Pad 2)     | Abstand zwischen JST-Gehäusen   |
| A7 | **UART_TX**| GP0   | **JST-SH 2 (UART)** Pin 1 | Konsole → Probe RX    |
| A8 | **GND**    | –     | JST-SH 2 (UART) Pin 2 | Probe-Masse               |
| A9 | **UART_RX**| GP1   | JST-SH 2 (UART) Pin 3 | Konsole ← Probe TX        |
| A10| GND        | –     | –                | Masse-Pad / Post-Pad            |

**Bestückungsoptionen Bereich A:**
- **Variante 1 (Default)**: 2× JST-SH 3-Pin-Buchse **SM03B-SRSS-TB** (LCSC C160403, side-entry/horizontal SMD) auf Pads A2-A4 und A7-A9. Pads A1, A5-A6, A10 bleiben unbestückt oder als kleine THT-Lötaugen.
- **Variante 2 (Alternative)**: durchgehende **1×10 Stiftleiste im 1,0-mm-Raster** (z.B. JST-SH-kompatible Pin-Header) — ersetzt beide JST-SH-Buchsen. Alle 10 Pads werden bestückt.
- **Niemals beide gleichzeitig** — JST-SH-Gehäuse blockieren mechanisch den Stiftleisten-Bereich.

**Pad-Layout Hinweise**:
- Beide JST-SH-Buchsen sind **identisch** (SM03B-SRSS-TB, side-entry SMD) → nur **eine** Bestellnummer, weniger Bestückungsfehler
- Füll-Pads (A1, A5, A6, A10) als **THT** mit ovalen Lötaugen für 1,0-mm-Stiftleiste
- 3D-Modell: projektlokal in `Amiga-HID_rev1.0.pretty/3d/C160403_JST_SH_SM03B-SRSS-TB.{step,wrl}` (offizielle KiCad-3D-Library hat **kein** JST_SH-Modell, nur JST_EH)
- Gesamtbreite Bereich A: 10 × 1,0 mm = **10 mm**

#### Bereich B: OLED-Display + Reserve (2,54 mm Pitch, 9 Pads)

Direkt kompatibel mit dem **SSD1309-Modul M242-12864** (4-Pin I²C-Header im 2,54-mm-Raster, Reihenfolge **GND – VCC – SCL – SDA**). Modul kann mit 4-Pin-Buchse direkt aufgesteckt werden.

**Pad-Reihenfolge Bereich B (Nord → Süd, alle 2,54 mm Pitch):**

| #  | Signal      | GPIO  | Block                | Zweck                                         |
|----|-------------|-------|----------------------|-----------------------------------------------|
| B1 | **GND**     | –     | **OLED SSD1309**     | OLED GND (Pin 1 am Modul)                     |
| B2 | **OLED_VCC**| –     | (OLED-Block)         | OLED VCC (Pin 2) – via Lötjumper SJ1 wählbar  |
| B3 | **I2C1_SCL**| GP3   | (OLED-Block)         | OLED SCL (Pin 3) – Logikpegel 3,3 V           |
| B4 | **I2C1_SDA**| GP2   | (OLED-Block)         | OLED SDA (Pin 4) – Logikpegel 3,3 V           |
| B5 | **VSYS**    | –     | **Reserve J7** Pin 1 | ≈ 4,8 V (Board-5V nach Schottky-OR)           |
| B6 | **GND**     | –     | Reserve J7 Pin 2     | Masse für Reserve-Lasten                      |
| B7 | **+3V3**    | –     | Reserve J7 Pin 3     | 3,3 V Out für externe Module                  |
| B8 | **GP_RES1** | GP7   | Reserve J7 Pin 4     | freier GPIO für Erweiterung                   |
| B9 | **GP_RES2** | GP8   | Reserve J7 Pin 5     | freier GPIO für Erweiterung                   |

**Bestückungsoptionen Bereich B:**
- **Variante 1**: 4-Pin Buchsenleiste auf B1-B4 (für OLED-Modul) + 5-Pin Stiftleiste auf B5-B9 (Reserve)
- **Variante 2**: durchgehende **1×9 Stiftleiste 2,54 mm** über alle 9 Pads
- Gesamtbreite Bereich B: 9 × 2,54 mm = **22,86 mm**

**Hinweis VSYS vs. +3V3**:
- **VSYS** (B5): ungeregeltes Board-5V-Netz nach den Schottky-Dioden (≈ 4,8 V im Amiga-Betrieb, ≈ 5,0 V wenn USB-Kabel zum PC steckt). Geeignet für 5-V-Module die internen Regler haben (Servos meiden — die ziehen Spitzen, die der Polyfuse stören könnten).
- **+3V3** (B7): direkt aus dem AMS1117-LDO, sauber für analoge/digitale 3,3-V-Lasten (max. ~200 mA empfohlen, damit der LDO nicht zu warm wird)
- **Beide GND-Pads** (B1 & B6) sind elektrisch identisch — der zweite GND erleichtert das Verdrahten von zwei unabhängigen Add-Ons

**OLED VCC – Lötjumper SJ1 (3-Pad Solder-Bridge)**:
- Mittelpad: B2 (OLED_VCC)
- Linkes Pad: **3V3** (= **DEFAULT**, ab Werk gebrückt)
- Rechtes Pad: **+5 V** (Board-5V-Rail)
- SSD1309-Modul M242-12864 läuft mit 3,3 V (mit On-Board-Booster) → 3V3 ausreichend
- Falls 5V-only-Variante des Moduls verwendet wird → SJ1 umlöten

#### Gesamt-Layout der Debug-Bereiche

```
55-mm-Langseite (links):

  Nord ─────────────────────────────────────────────────────► Süd
  ┌──────────────────────┬─────┬─────────────────────────┐
  │  Bereich A (1,0 mm)  │ Gap │  Bereich B (2,54 mm)    │
  │  RUN GND [JST-SWD]   │     │  GND VCC SCL SDA 3V3 R1 R2
  │  GG [JST-UART] GND   │     │                         │
  │  ~11 mm              │~5mm │  ~18 mm                 │
  └──────────────────────┴─────┴─────────────────────────┘
  
  Zusätzlich Platz auf den restlichen ~21 mm für: 
  Mini BOOTSEL-Taster, LEDs, freie Routing-Fläche
```

Insgesamt belegt von der 55-mm-Langseite: ~34 mm für Debug-Pads, ~21 mm bleiben für andere Bauteile/Beschriftung.

### USB-Datenpfad – nur EINE USB-A-Buchse, kein Mux nötig
RP2350 D+/D- gehen **direkt an die USB-A-Buchse** (keine Mux-IC). Die USB-Rolle wird **rein in Software** umgeschaltet:
- **Normalbetrieb**: TinyUSB als **Host** initialisiert → erkennt Tastatur, liest HID-Reports
- **Nach `reset_usb_boot()`**: RP2350-ROM nutzt denselben USB-Bus als **Device** → meldet sich am PC als RPI-RP2

Der USB-Stecker selbst (USB-A) ist **nur ein mechanischer Anschluss** – Host/Device-Rolle bestimmt die Firmware bzw. das ROM. Genau wie das offizielle Pico-2-Reference-Design das mit Micro-USB macht, funktioniert es hier mit USB-A. Der einzige Unterschied: VBUS muss bidirektional sicher gehandhabt werden (siehe Spannungsversorgung oben).

### USB-Bootloader via Tastatur-Shortcut (`LCtrl + LShift + F10` empfohlen)
**Ziel**: Firmware-Update ohne Gehäuseöffnung – kein Zugriff auf BOOTSEL-Taster nötig.

**Workflow Firmware-Update:**
1. User drückt `LCtrl + LShift + F10` an der Tastatur
2. FW ruft `reset_usb_boot(0, 0)` → RP2350 rebootet ins ROM-Bootrom (Device-Modus auf demselben USB-Bus)
3. User zieht Tastatur ab, steckt **USB-A↔USB-A-Kabel zum PC** in dieselbe Buchse
4. PC liefert 5 V über VBUS → D2 → Board-5V-Rail → Board läuft weiter
5. ROM meldet sich am PC als **RPI-RP2** Mass-Storage
6. User kopiert UF2 → Board startet neue FW automatisch
7. USB-Kabel ab, Tastatur wieder rein → Normalbetrieb

**Hinweis**: Da die Stromversorgung **rein passiv** ist, muss die FW **keinen Load-Switch** schalten — beim Anstecken des PC-Kabels übernimmt automatisch D2 die Versorgung, D3 sperrt von selbst.

**Software-Vorbereitung (Code aktuell NICHT anpassen, nur Voraussetzungen schaffen)**:
- HID-Keyboard-Decoder muss Modifier-Bitmasken (LSHIFT/LCTRL/RSHIFT/RCTRL) und F-Tasten unterscheiden können → bereits gegeben
- Vorgemerkter Hook-Punkt im Keyboard-Event-Pfad für künftigen Aufruf:
  ```c
  #include "pico/bootrom.h"
  reset_usb_boot(0, 0);   // ins BOOTSEL-ROM springen
  ```
- Empfohlener Shortcut: **`LCtrl + LShift + F10`** (kollidiert nicht mit Amiga-Standard-Kombos wie `Ctrl+Amiga+Amiga` Reset)
- **TODO** (zukünftig): in `usb_hid.c` einen Watchdog auf Modifier+F10 einbauen, der `reset_usb_boot()` triggert
- **Kein Load-Switch-GPIO nötig** dank passiver Power-Schaltung

**Hardware-Fallback**: Mini BOOTSEL-Taster auf der Platine (siehe oben), nur für den Notfall (defekte FW, Tastatur funktioniert nicht).

### REV5 BOM-Ergänzungen (zusätzlich zur bestehenden Tabelle)
| Bauteil                                     | LCSC#       | Package          | Funktion                                |
|---------------------------------------------|-------------|------------------|-----------------------------------------|
| TXS0102DCUR                                 | C53411      | VSSOP-8          | U5: Level-Shifter KB_DATA/CLK (3,3↔5 V) |
| USBLC6-2SC6                                 | C7480       | SOT-23-6         | U1: USB ESD-Schutz (D+/D-)              |
| **PMEG2010AEH (3×)** D1/D2/D3               | **C181276** | **SOD-323**      | Power-OR Schottky                       |
| PolyFuse 500 mA F1 (z.B. mF-MSMF050)        | tbd         | 1206             | Tastatur-VBUS Überstromschutz (mit D3)  |
| 12 MHz Crystal Y1                           | C9002       | 3225-4P          | Systemtakt                              |
| LED 0603 (2×) – LED1 grün, LED2 gelb        | tbd         | 0603             | LED1 GP25 (Status), LED2 GP16 (Activity)|
| R 1 kΩ (LED-Vorwiderstände, Pullups)        | –           | 0402/0603        | passiv                                  |
| Tact-Switch SW1/SW2 (BOOTSEL + Reset)       | **C139797** | SMD vertical 4,2×3,2 mm, Pad-Pitch 4,2×2,14 mm | Hardware-Fallback BOOTSEL + Reset; kompakte günstige Alternative zu Würth 434133025816 |
| **USB-A Buchse J1**                         | **C42614**  | THT recessed     | Jing Extension JTJ USB-AF-13            |
| JST-XH-5A J2 (B5B-XH-A)                     | C157932     | THT 2,5 mm       | Verbindung Amiga / Front Panel          |
| **JST-SH 3-Pin (2×)** J5/J6 (SM03B-SRSS-TB) | **C160403** | SMD, side-entry  | Pi Debug Probe SWD + UART (identische Teile) |
| PinHeader 1×4 (J3) / 1×5 (J4)               | –           | 2,54 mm THT      | OLED I²C / Reserve (3V3+GP+GND+VSYS)    |
| PinHeader 1×6 (J7)                          | –           | 1,27 mm THT      | zusätzlicher Reserve-Header (siehe Schema)|
| Lötjumper SJ1 (3-Pad)                       | –           | SMD              | OLED VCC: Default 3V3, optional auf 5V  |
| Induktivität L1 2,2 µH                      | **C1046**   | L_pol_2016 (0805) | Sunlord chip inductor, RP2350 SMPS (VREG_LX) |
| Testpoints TP1/TP2                          | –           | THT 1,0 mm       | Mess-Pads                               |
