# Copilot Instructions für amigahid-pico

## Projekt-Übersicht
USB-HID Keyboard Adapter für Amiga 2000 basierend auf RP2350A (Pico 2).
Konvertiert moderne USB-Tastaturen zu Amiga-kompatiblem Keyboard-Protokoll.

## Hardware-Kontext

### Ziel-Hardware
- **Test-Board**: Raspberry Pi Pico 2 (RP2350)
- **Produktiv-MCU**: RP2350A (QFN-60, 7×7mm)
- **Board-Abmessungen**: 52×15mm (passt in bestehendes Gehäuse)

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

## GPIO-Mapping (config.h REV4)

| GPIO | Funktion | Verbindung |
|------|----------|------------|
| GP4 | KBD_AMIGA_RST | (nicht verwendet für Amiga 2000) |
| GP5 | KBD_AMIGA_DAT | → TXS0102 → J2 KBDATA |
| GP6 | KBD_AMIGA_CLK | → TXS0102 → J2 KBCLK |
| GP2 | I2C1_SDA | SSD1309 Display |
| GP3 | I2C1_SCL | SSD1309 Display |
| GP0 | UART TX | Debug via YP-01A |
| GP1 | UART RX | Debug via YP-01A |
| GP25 | LED | Onboard LED (Pico 2) |

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

## JLCPCB BOM (Produktiv-Board)

### Kritische Teile
| Bauteil | LCSC# | Package |
|---------|-------|---------|
| RP2350A | C42411118 | QFN-60 |
| AMS1117-3.3 | C6186 | SOT-223 |
| W25Q16JVSSIQ (Flash) | C131024 | SOIC-8 |
| JST-XH-5A | C157932 | - |

## Bekannte Einschränkungen
- Kein `reset_usb_boot()` im Code - BOOTSEL-Button nötig für Firmware-Updates
- Amiga 2000 hat keinen KBRST-Pin - nur KBDATA und KBCLK werden benötigt
