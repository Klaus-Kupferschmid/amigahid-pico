# Amiga-HID rev1.0 — KiCad Project

> Stand-alone PCB design for the Amiga 2000 HID keyboard adapter.  
> RP235(0/4)A based, 20×55 mm, 4-layer PCB.

## Design Status: ✅ Complete

| Aspect | Status |
|--------|--------|
| Schematic | ✅ Complete (flat design) |
| PCB Layout | ✅ Complete |
| BOM | ✅ JLCPCB-ready |

---

## Bill of Materials (Stand: Mai 2026)

Kanonische BOM-Quelle: [`_bom.csv`](_bom.csv)

### MCU & Flash

| Ref | Value | LCSC | Footprint | Usage |
|-----|-------|------|-----------|-------|
| U4 | RP2354_60QFN | C41378174 | QFN-60 7×7mm | MCU (RP2350A mit internem 2MB Flash, alternativ RP2350A pinkompatibel) |
| U3 | W25Q16JVSSIQ | C82317 | SOIC-8 5.3×5.3mm | QSPI Flash 2 MB (DNP bei RP2354A) |
| Y1 | 12MHz | C3003246 | Crystal_SMD_3225 | Systemtakt (18 pF Load) |
| L1 | 3.3µH | C42411119 | L_pol_2016 | RP2350 SMPS-Induktivität (VREG_LX) |

### Power

| Ref | Value | LCSC | Footprint | Usage |
|-----|-------|------|-----------|-------|
| U2 | AMS1117-3.3 | C2688239 | SOT-223 | LDO 5V → 3.3V |
| D1, D2, D3 | PMEG2005AEA | C53114226 | SOD-323 | Power-OR Schottky-Dioden |
| F1 | 500mA | C7202014 | Fuse_1206 | PolyFuse Tastatur-VBUS |
| C1 | 10µF | C15850 | 0805 | VBUS Bulk-Cap |
| C3 | 22µF | C45783 | 0805 | LDO Output Bulk |

### USB & ESD

| Ref | Value | LCSC | Footprint | Usage |
|-----|-------|------|-----------|-------|
| J1 | USB-A | C42614 | USB_A_Edge | USB-A Buchse (Host/Flash) |
| U1 | USBLC6-2SC6 | C19170930 | SOT-23-6 | USB ESD-Schutz |
| R8, R9 | 27Ω | C25100 | 0402 | USB D+/D- Series-Termination |

### Level-Shifter (Amiga Interface)

| Ref | Value | LCSC | Footprint | Usage |
|-----|-------|------|-----------|-------|
| U5 | TXS0102DCUR | C53434 | VSSOP-8 | Bidir 3.3V↔5V für KB_DATA/KB_CLOCK |
| C22 | 100nF | C161530 | 0402 | TXS0102 VccA Decoupling (3V3) |
| C23 | 100nF | C161530 | 0402 | TXS0102 VccB Decoupling (5V) |

### Connectors

| Ref | Value | LCSC | Footprint | Usage |
|-----|-------|------|-----------|-------|
| J2 | JST-XH-5A | C7551124 | JST_XH_B5B-XH-A | Amiga / Front Panel (GND, 5V, KBDATA, NC, KBCLK) |
| J3 | Pin Header 1×04 | C52016392 | PinHeader_1x04_P2.54mm | SSD1309 OLED I2C (GND/VCC/SCL/SDA) |
| J4 | Pin Header 1×05 | C225480 | PinHeader_1x05_P2.54mm | Reserve (VSYS/GND/3V3/GP7/GP8) |
| J5 | JST-SH-3 | C160403 | JST_SH_SM03B-SRSS-TB | Pi Debug Probe SWD |
| J6 | JST-SH-3 | C160403 | JST_SH_SM03B-SRSS-TB | Pi Debug Probe UART |
| J7 | Conn_01x06 | C5372829 | PinHeader_1x06_P1.27mm | Zusatz-Reserve-Header |

### LEDs & Switches

| Ref | Value | LCSC | Footprint | Usage |
|-----|-------|------|-----------|-------|
| LED1 | Status_Green | C965804 | LED_0603 | Status/Power LED (GP25) |
| LED2 | Activity_Yellow | C72038 | LED_0603 | Activity LED (GP16) |
| R1, R2 | 1kΩ | C21190 | 0603 | LED-Vorwiderstände |
| SW1 | SW_Push | C139797 | SMD_Tact_4x3 | BOOTSEL Taster |
| SW2 | SW_Push | C139797 | SMD_Tact_4x3 | Reset Taster |

### Capacitors (Decoupling)

| Ref | Value | LCSC | Footprint | Usage |
|-----|-------|------|-----------|-------|
| C2, C4, C5 | 100nF | C1525 | 0402 | LDO Decoupling |
| C6, C7 | 15pF | C18164617 | 0402 | XTAL Load-Caps |
| C8, C9, C10, C12 | 4.7µF | C368809 | 0402 | MCU VREG/1V1 Decoupling |
| C11, C13–C21 | 100nF | C161530 | 0402 | MCU VDD / Flash Decoupling |
| C14 | 100nF | C161530 | 0402 | USB-VBUS Decoupling |

### Resistors

| Ref | Value | LCSC | Footprint | Usage |
|-----|-------|------|-----------|-------|
| R3 | 10kΩ | C25744 | 0402 | QSPI_SS Pullup |
| R4, R6, R7 | 1kΩ | C11702 | 0402 | Pullups |
| R5 | 33Ω | C25105 | 0402 | 3V3 RC-Filter (ADC_AVDD) |
| R10, R11 | 33Ω | C25105 | 0402 | UART TX/RX Series-Termination |
| R12, R13 | DNF | C25900 | 0402 | I2C Pullup-Pads (optional) |

### Misc

| Ref | Value | LCSC | Footprint | Usage |
|-----|-------|------|-----------|-------|
| SJ1 | OLED_VCC_SEL | – | SolderJumper-3 | OLED VCC: Default 3V3, optional 5V |

---

## Power Architecture

Passive dual-source switching (Amiga + PC USB):

```
   Amiga 5V (J2 Pin 2) ──►─D1──►─┬── Board-5V ──► AMS1117-3.3 ──► +3V3
                                 │
   USB-A VBUS (PC) ─────►─D2──►──┤
                                 │
                                 └─D3──►─F1──► USB-A VBUS (Tastatur)
```

✅ No FW logic required · ✅ Brick-resistant · ✅ Crash-safe

---

## GPIO Mapping (REV5)

| GPIO | Function | Connection |
|------|----------|------------|
| GP0 | UART_TX | J6 → Pi Debug Probe RX |
| GP1 | UART_RX | J6 ← Pi Debug Probe TX |
| GP2 | I2C1_SDA | OLED (J3 Pin 4) |
| GP3 | I2C1_SCL | OLED (J3 Pin 3) |
| GP5 | KB_DATA | → TXS0102 → J2 Pin 3 |
| GP6 | KB_CLOCK | → TXS0102 → J2 Pin 5 |
| GP7, GP8 | Reserve | J4 |
| GP16 | LED2 | Activity LED |
| GP25 | LED1 | Status LED |

---

## Tools

- **sync_lcsc_to_sch.py**: Synchronisiert LCSC-Nummern aus `_bom.csv` in die Schematic
