# AmigaHID-Pico Test Setup - Breadboard Aufbau

## Hardware-Komponenten
- 1x Raspberry Pi Pico 2 (Target)
- 1x Waveshare RP2350-USB-A (Debug Probe)
- 1x SSD1309 OLED Display 128x64 (I2C, Adresse 0x3C)
- 1x TXS0108E Level Shifter Modul (AZDelivery)
- 1x Breadboard (Full-Size, 63 Spalten)
- Jumperwires in verschiedenen Farben

---

## 1. PICO 2 (TARGET) - Pinout mit Pinnummern

```
                                    ┌───USB-C───┐
                                    │  BOOTSEL  │
                        ┌───────────┴───────────┴───────────┐
                        │                                   │
   UART0_TX   I2C0_SDA  │                                   │
   SPI0_RX    ────────► │ GP0    [1]           [40]   VBUS  │ ◄── 5V vom USB
   UART0_RX   I2C0_SCL  │ GP1    [2]           [39]   VSYS  │
   SPI0_CSn   ────────► │                                   │
                        │ GND    [3]           [38]   GND   │ ◄── ACTIVE GND
              I2C1_SDA  │                                   │
   SPI0_SCK   ────────► │ GP2    [4] ◄─────────────────────────── I2C Display SDA
              I2C1_SCL  │                                   │
   SPI0_TX    ────────► │ GP3    [5] ◄─────────────────────────── I2C Display SCL
                        │ GP4    [6]           [37]  3V3_EN │
  ►►KBD_DAT◄◄           │ GP5    [7] ◄─────────────────────────── TXS0108E A1
                        │ GND    [8]           [36]   3V3   │ ◄── 3.3V OUT
  ►►KBD_CLK◄◄           │ GP6    [9] ◄─────────────────────────── TXS0108E A2
                        │ GP7   [10]           [35] ADC_REF │
                        │ GP8   [11]           [34]   GP28  │
                        │ GP9   [12]           [33]   GND   │
                        │ GND   [13]           [32]   GP27  │
                        │ GP10  [14]           [31]   GP26  │
                        │ GP11  [15]           [30]   RUN   │ ◄── ACTIVE SWCLK
                        │ GP12  [16]           [29]   GP22  │
                        │ GP13  [17]           [28]   GND   │
                        │ GND   [18]           [27]   GP21  │
                        │ GP14  [19]           [26]   GP20  │
                        │ GP15  [20]           [25]   GP19  │
                        │ GP16  [21] ◄───────────────────────── ACTIVE SWDIO
                        │ GP17  [22]           [24]   GP18  │
                        │ GND   [23]                        │
                        └───────────────────────────────────┘
                                     │  │  │
                                  ┌──┴──┴──┴──┐
                                  │Debug Pads │
                                  │SWCLK GND SWDIO
                                  └───────────┘
```

**Aktive Pins für dieses Projekt:**
| Pin# | GPIO | Funktion |
|------|------|----------|
| 4 | GP2 | I2C1_SDA → Display |
| 5 | GP3 | I2C1_SCL → Display |
| 7 | GP5 | KBD_DAT → TXS A1 |
| 9 | GP6 | KBD_CLK → TXS A2 |
| 30 | RUN | SWCLK ← Debug Probe |
| 21 | GP16 | SWDIO ← Debug Probe |
| 36 | 3V3 | Stromversorgung |
| 38 | GND | Masse |

---

## 2. WAVESHARE RP2350-USB-A (DEBUG PROBE) - Pinout

```
         ┌──────────────────────────────────────────────────────────────┐
         │                                                              │
         │  ╔════════╗                                    ┌─────────┐   │
         │  ║ USB-A  ║                                    │WS2812   │   │
         │  ║Stecker ║                                    │RGB LED  │   │
         │  ╚════════╝                                    │(GP16)   │   │
         │                                                └─────────┘   │
         │                      ┌────────────────┐                      │
         │                      │    RP2350A     │                      │
         │                      │                │                      │
         │                      └────────────────┘                      │
         │                                                              │
         │   LINKE SEITE                              RECHTE SEITE      │
         │   ════════════                             ═════════════     │
         │                                                              │
         │      5V ○────────────────────────────────────○ GP0           │
         │     GND ○────────────────────────────────────○ GP1           │
         │     3V3 ○────────────────────────────────────○ GP2  ◄◄ SWCLK OUT
         │    GP29 ○────────────────────────────────────○ GP3  ◄◄ SWDIO OUT
         │    GP28 ○────────────────────────────────────○ GP4  ◄◄ UART TX
         │    GP27 ○────────────────────────────────────○ GP5  ◄◄ UART RX
         │    GP26 ○────────────────────────────────────○ GP6           │
         │    GP10 ○────────────────────────────────────○ GP7           │
         │     GP9 ○────────────────────────────────────○ GP8           │
         │                                                              │
         └──────────────────────────────────────────────────────────────┘
```

**Debug Probe Pins (mit debugprobe Firmware):**
| Position | GPIO | Funktion |
|----------|------|----------|
| Rechts, 3. von oben | GP2 | SWCLK Output → Pico Pin 30 |
| Rechts, 4. von oben | GP3 | SWDIO Output → Pico Pin 21 |
| Links, 2. von oben | GND | Masse |
| Rechts, 5. von oben | GP4 | UART TX (optional) |
| Rechts, 6. von oben | GP5 | UART RX (optional) |

---

## 3. TXS0108E LEVEL SHIFTER MODUL - Pinout

```
    ┌─────────────────────────────────────────────────────────────────────┐
    │                                                                     │
    │   5V SEITE (Amiga/J2)                      3.3V SEITE (Pico)        │
    │   ═══════════════════                      ════════════════         │
    │                                                                     │
    │    VB   B1   B2   B3   B4   B5   B6   B7   B8   GND                 │
    │    ○    ○    ○    ○    ○    ○    ○    ○    ○    ○                   │
    │    │    │    │                                                      │
    │    │    │    │         ┌─────────────────────────┐                  │
    │    │    │    │         │       TXS0108E          │                  │
    │    │    │    │         │        YF08E            │                  │
    │    │    │    │         └─────────────────────────┘                  │
    │    │    │    │                                                      │
    │    ○    ○    ○    ○    ○    ○    ○    ○    ○    ○                   │
    │    VA   A1   A2   A3   A4   A5   A6   A7   A8   OE                  │
    │    │    │    │                                   │                  │
    │    │    │    │                                   │                  │
    └────┼────┼────┼───────────────────────────────────┼──────────────────┘
         │    │    │                                   │
         │    │    │                                   └──► 3V3 (Enable)
         │    │    │
         │    │    └── A2 ◄── GP6 (Pin 9)  ════► B2 ──► J2 Pin 5 (KBCLK)
         │    │
         │    └─────── A1 ◄── GP5 (Pin 7)  ════► B1 ──► J2 Pin 3 (KBDATA)
         │
         └──────────── VA ◄── 3V3 (Pin 36)     VB ◄── J2 Pin 2 (+5V)
```

**Verwendete Pins:**
| A-Seite (3.3V) | B-Seite (5V) | Funktion |
|----------------|--------------|----------|
| VA | VB | Spannungsreferenz 3.3V / 5V |
| A1 | B1 | KBD_DAT (GP5 ↔ J2 Pin 3) |
| A2 | B2 | KBD_CLK (GP6 ↔ J2 Pin 5) |
| GND | GND | Gemeinsame Masse |
| OE | - | An 3V3 (aktiviert Shifter) |

---

## 4. BREADBOARD AUFBAU

```
═══════════════════════════════════════════════════════════════════════════════
                              BREADBOARD LAYOUT (63 Spalten)
═══════════════════════════════════════════════════════════════════════════════

+5V Rail  ════●═══════════════════════════════════════════════════════════●════
GND Rail  ════●═══════════════════════════════════════════════════════════●════

Spalte:   1         10        20        30        40        50        60  63
          │         │         │         │         │         │         │   │
    a     ○─────────○─────────○─────────○─────────○─────────○─────────○───○
    b     ○─────────○─────────○─────────○─────────○─────────○─────────○───○
    c     ○─────────○─────────○─────────○─────────○─────────○─────────○───○
    d     ○─────────○─────────○─────────○─────────○─────────○─────────○───○
    e     ○─────────○─────────○─────────○─────────○─────────○─────────○───○
          ├─────────────────────── MITTELSTEG ─────────────────────────────┤
    f     ○─────────○─────────○─────────○─────────○─────────○─────────○───○
    g     ○─────────○─────────○─────────○─────────○─────────○─────────○───○
    h     ○─────────○─────────○─────────○─────────○─────────○─────────○───○
    i     ○─────────○─────────○─────────○─────────○─────────○─────────○───○
    j     ○─────────○─────────○─────────○─────────○─────────○─────────○───○

+3V3 Rail ════●═══════════════════════════════════════════════════════════●════
GND Rail  ════●═══════════════════════════════════════════════════════════●════


═══════════════════════════════════════════════════════════════════════════════
                           KOMPONENTEN-PLATZIERUNG
═══════════════════════════════════════════════════════════════════════════════

    WAVESHARE DEBUG PROBE            PICO 2 TARGET                PERIPHERIE
    Spalte 1-9 (USB links)           Spalte 25-44 (USB rechts)    Spalte 50-63
    ══════════════════════           ═════════════════════════    ════════════

          [USB-A]◄──┐                      ┌──►[USB-C]
                    │                      │
    Linke │ Rechte  │        Linke │ Rechte
    Seite │ Seite   │        Seite │ Seite
    ──────┼────────────      ──────┼───────                       ┌──────────┐
     5V  a1  GP0 e1          GP0  a25  VBUS j25                   │ SSD1309  │
    GND  a2  GP1 e2          GP1  a26  VSYS j26                   │  OLED    │
    3V3  a3  GP2 e3 ════     GND  a27  GND  j27                   │ DISPLAY  │
   GP29  a4  GP3 e4 ════     GP2  a28  3V3_EN j28                 │          │
   GP28  a5  GP4 e5          GP3  a29  3V3  j29 ════►3V3 Rail     │  SDA ○ a55
   GP27  a6  GP5 e6          GP4  a30  ADC  j30                   │  SCL ○ a56
   GP26  a7  GP6 e7          GP5  a31  GP28 j31                   │  VCC ○ a57
   GP10  a8  GP7 e8          GND  a32  GND  j32                   │  GND ○ a58
    GP9  a9  GP8 e9          GP6  a33  GP27 j33                   └──────────┘
                             GP7  a34  GP26 j34
         │                   GP8  a35  RUN  j35 ◄═══ SWCLK
         │                   GP9  a36  GP22 j36      (grün)
         │                   GND  a37  GND  j37                   ┌──────────┐
         │                   GP10 a38  GP21 j38                   │ TXS0108E │
         │                   GP11 a39  GP20 j39                   │          │
         │                   GP12 a40  GP19 j40                   │ VA ○ a50 │
         │                   GP13 a41  GP18 j41                   │ A1 ○ a51 │
         │                   GND  a42  GND  j42                   │ A2 ○ a52 │
         │                   GP14 a43  GP17 j43                   │... ...   │
         │                   GP15 a44  GP16 j44 ◄═══ SWDIO        │ OE ○ a59 │
         │                                          (blau)        │ VB ○ e50 │
         │                                                        │ B1 ○ e51 │
         │                          │                             │ B2 ○ e52 │
         └══════════════════════════┘                             │... ...   │
                  SWD Debug                                       │GND○ e59  │
                (grün + blau + schwarz)                           └──────────┘

                                                                  ┌──────────┐
                                                                  │   J2     │
                                                                  │CONNECTOR │
                                                                  │ 1○ GND   │f60
                                                                  │ 2○ +5V   │f61
                                                                  │ 3○ KBDAT │f62
                                                                  │ 4○ NC    │f63
                                                                  │ 5○ KBCLK │g60
                                                                  └──────────┘
```

---

## 5. VERKABELUNGSLISTE MIT PINNUMMERN

### SWD Debug (Waveshare → Pico 2)
| Von | Pin | Breadboard | → | Breadboard | Pin | Nach | Farbe |
|-----|-----|------------|---|------------|-----|------|-------|
| Waveshare GP2 | e3 | Spalte 3 | ═══► | Spalte 35 | j35 | Pico RUN (Pin 30) | **GRÜN** |
| Waveshare GP3 | e4 | Spalte 4 | ═══► | Spalte 44 | j44 | Pico GP16 (Pin 21) | **BLAU** |
| Waveshare GND | a2 | Spalte 2 | ═══► | GND Rail | | Pico GND (Pin 38) | **SCHWARZ** |

### I2C Display (Pico 2 → SSD1309)
| Von | Pin | Breadboard | → | Breadboard | Nach | Farbe |
|-----|-----|------------|---|------------|------|-------|
| Pico GP2 | Pin 4 | a28 | ═══► | a55 | Display SDA | **ORANGE** |
| Pico GP3 | Pin 5 | a29 | ═══► | a56 | Display SCL | **GELB** |
| Pico 3V3 | Pin 36 | j29 | ═══► | a57 | Display VCC | **ROT** |
| Pico GND | Pin 38 | j27 | ═══► | a58 | Display GND | **SCHWARZ** |

### Amiga Keyboard (Pico 2 → TXS0108E → J2)
| Von | Pin | Breadboard | → | Breadboard | TXS Pin | → | J2 Pin | Farbe |
|-----|-----|------------|---|------------|---------|---|--------|-------|
| Pico GP5 | Pin 7 | a31 | ═══► | a51 | A1 | B1 → | Pin 3 (KBDAT) | **LILA** |
| Pico GP6 | Pin 9 | a33 | ═══► | a52 | A2 | B2 → | Pin 5 (KBCLK) | **CYAN** |
| Pico 3V3 | Pin 36 | j29 | ═══► | a50 + a59 | VA + OE | | | **ROT** |
| GND Rail | | | ═══► | e59 | GND | | Pin 1 | **SCHWARZ** |
| +5V Rail | | | ═══► | e50 | VB | ◄── | Pin 2 | **ROT** |

---

## 6. J2 CONNECTOR PINOUT (zum Amiga 2000)

```
    Ansicht von vorne (Kabelseite, JST-XH 5-Pin):

         ┌───────────────────────────────────┐
         │                                   │
         │    1      2      3      4      5  │
         │    ○      ○      ○      ○      ○  │
         │   GND    +5V   KBDAT   NC   KBCLK │
         │    │      │      │            │   │
         └────┼──────┼──────┼────────────┼───┘
              │      │      │            │
              │      │      │            └────► TXS0108E B2 (CYAN)
              │      │      │
              │      │      └─────────────────► TXS0108E B1 (LILA)
              │      │
              │      └────────────────────────► TXS0108E VB (ROT, +5V)
              │
              └───────────────────────────────► Common GND (SCHWARZ)
```

---

## 7. WICHTIGE HINWEISE

⚠️ **RP2350 ist NICHT 5V-tolerant!** 
   TXS0108E Level Shifter ist PFLICHT für die Amiga-Verbindung!

⚠️ **OE-Pin des TXS0108E**
   Muss an 3V3 angeschlossen werden um den Shifter zu aktivieren!

⚠️ **Debug-Pins am Pico 2**
   - Pin 30 (RUN) = SWCLK
   - Pin 21 (GP16) = SWDIO
   - Alternative: Die 3 Debug-Pads an der Unterseite des Pico 2

⚠️ **Waveshare Debug Probe Firmware**
   Muss mit `debugprobe_on_pico2.uf2` geflasht sein!
   - GP2 = SWCLK Output
   - GP3 = SWDIO Output

⚠️ **Display I2C-Adresse**
   SSD1309: 0x3C (Standard)

⚠️ **J2 Pin 4 (NC)**
   Nicht verbinden - ist reserviert/unbenutzt beim Amiga 2000
