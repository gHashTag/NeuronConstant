# Trinity DevKit Pro — Full Pinout Map & PCB Layout Reference

**Document type:** Hardware engineering reference  
**Author:** Dmitrii Vasilev (NeuronConstant / IGLA / Trinity TRI-27)  
**Version:** 0.9.0-draft  
**Date:** 2026-05-18  
**Board:** Trinity DevKit Pro SBC — 100 mm × 60 mm, Raspberry Pi 5 form-factor  
**License:** CERN-OHL-S-2.0  
**Repository:** https://github.com/gHashTag/trinity-devkit-pro  
**Status:** Pre-production — for review and tape-out preparation  
**Classification:** Research demonstrator on educational TinyTapeout (TT) shuttle — not a production accelerator  
**Performance (projected):** Trinity v1.0 (TT SKY26b) ~1 GOPS @ ~50 MHz @ ~1 W ternary compute — projected; real measurements pending tape-out 2026-12-16

---

## Table of Contents

1. [Top-Level Block Diagram](#1-top-level-block-diagram)
2. [40-Pin Pi-Compatible GPIO Header](#2-40-pin-pi-compatible-gpio-header)
3. [Trinity ASIC ZIF Socket Pinout](#3-trinity-asic-zif-socket-pinout)
4. [MIPI CSI-2 Camera Connector](#4-mipi-csi-2-camera-connector)
5. [HDMI 2.1 Connector](#5-hdmi-21-connector)
6. [USB 3.2 Gen2 Type-C with PD3.1](#6-usb-32-gen2-type-c-with-pd31)
7. [PCIe Gen3 × 1 M.2 E-Key Socket](#7-pcie-gen3--1-m2-e-key-socket)
8. [GbE RJ45 with PoE+](#8-gbe-rj45-with-poe)
9. [6× 12-Bit ADC Channels](#9-6-12-bit-adc-channels)
10. [CAN-FD Transceiver](#10-can-fd-transceiver)
11. [Power Tree Diagram](#11-power-tree-diagram)
12. [D2D Mesh Bus Topology](#12-d2d-mesh-bus-topology)
13. [Mechanical Drawing (Top View)](#13-mechanical-drawing-top-view)
14. [JTAG/SWD Debug Header](#14-jtagswd-debug-header)
15. [Status Indicators](#15-status-indicators)
16. [Bill of Components Summary](#16-bill-of-components-summary)
17. [Open-Source Release Plan](#17-open-source-release-plan)
18. [References](#18-references)

---

## 1. Top-Level Block Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                      Trinity DevKit Pro PCB  (100 mm × 60 mm)                │
│                                                                               │
│  ┌──────────┐   ┌──────────────┐   ┌───────────────┐                         │
│  │ TRI-Phi  │   │  TRI-Euler   │   │   TRI-Gamma   │   ← ZIF sockets J3/J4/J5│
│  │ 1×1 tile │   │  8×2 tiles   │   │   8×4 tiles   │                         │
│  │ SKY130A  │   │  SKY130A     │   │   SKY130A     │                         │
│  └────┬─────┘   └──────┬───────┘   └───────┬───────┘                         │
│       └────────── D2D Mesh (4× diff pairs each, 200 Mbps NRZ) ───────────────┤
│                         │                                                     │
│  ┌──────────────────────┴──────────────────────────────┐                     │
│  │               ASIC Ctrl Mux (SPI GPIO mux, U15)     │                     │
│  └────────────────────┬────────────────────────────────┘                     │
│                        │ SPI (50 MHz)                                         │
│  ┌─────────────────────┴─────────────────────────────────────────────────┐   │
│  │                  RP2350 Host MCU (U1)                                  │   │
│  │  Dual Cortex-M33 @ 150 MHz · 520 KB SRAM · 2 MB flash · 2× PIO        │   │
│  │  SPI0→ASIC mux · I2C0/1 · UART0/1/2/3 · PWM · ADC SPI · CAN-FD PIO   │   │
│  └──────────┬───────────────────────────────────────────────────────────┘   │
│              │ UART (3 Mbps)                                                  │
│  ┌───────────┴──────────────────────────────────────────────────────────┐    │
│  │               ESP32-S3 Wi-Fi6 / BT5.3 (U2)                           │    │
│  │  Xtensa LX7 240 MHz · 512 KB SRAM · Wi-Fi 802.11ax · BT 5.3 / BLE    │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
│                                                                               │
│  ┌──────────────────────┐   ┌──────────────────────────┐                     │
│  │ LPDDR5 8 GB (U6)     │   │  eMMC 64 GB (U7)         │                     │
│  │ Micron MT62F2G32D4DR │   │  Samsung KLMBG2JETD-B041  │                     │
│  │ x32, 6400 Mbps/pin   │   │  JEDEC e·MMC 5.1, HS400  │                     │
│  └──────────┬───────────┘   └───────────┬──────────────┘                     │
│              │                           │                                     │
│  ┌───────────┴───────────────────────────┴──────────────────────────────┐    │
│  │               Host SoC Interconnect / Memory Bus                      │    │
│  │  (routed through RP2350 QSPI + external LPDDR5 controller IC)         │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │  I/O Block                                                            │    │
│  │                                                                        │    │
│  │  [40-pin GPIO J1] · [2× MIPI CSI-2 J7/J8] · [MIPI DSI J9]           │    │
│  │  [HDMI 2.1 J10] · [USB 3.2 Type-C J11, PD3.1 via TPS65987]          │    │
│  │  [PCIe Gen3 ×1 M.2 E-Key J12] · [RJ45 GbE PoE+ J13]                 │    │
│  │  [ADC header J14, ADS131M06] · [CAN-FD header J15, TCAN1051]         │    │
│  │  [JTAG/SWD J16, 10-pin 1.27 mm] · [Power BTN SW1] · [LEDs D1–D8]    │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
│                                                                               │
│  Power input: 5 V/5 A USB-C PD3.1 (J11) or PoE+ 25 W (J13)                 │
│  Power ICs: TPS65987 PD + TPS62873A 0.85 V + TLV75801 3.3 V + LP5907 1.8 V  │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 40-Pin Pi-Compatible GPIO Header

**Connector:** J1 — 2×20 2.54 mm pitch dual-row female, compatible with Raspberry Pi 5 HAT+  
**Standard:** Pi HAT+ mechanical and electrical specification (https://datasheets.raspberrypi.com/hat/hat-plus-specification.pdf)  
**Voltage levels:** 3.3 V logic (not 5 V tolerant on GPIO pins); power pins 5 V and 3.3 V present  
**Trinity-specific:** GPIO 17 (pin 11) and GPIO 27 (pin 13) are routed to ASIC MUX SEL[0] and SEL[1], allowing selection of phi / euler / gamma SPI target

| Pin | Name                   | Function / Net                              | Direction |
|-----|------------------------|---------------------------------------------|-----------|
|  1  | 3V3_PWR                | 3.3 V regulated (max 300 mA from this pin)  | PWR out   |
|  2  | 5V_PWR                 | 5 V from USB-C / PoE input                  | PWR out   |
|  3  | GPIO2 / I2C1_SDA       | I2C1 data (RP2350 I2C1, 400 kHz / 1 MHz)    | Bidir     |
|  4  | 5V_PWR                 | 5 V (same rail as pin 2)                    | PWR out   |
|  5  | GPIO3 / I2C1_SCL       | I2C1 clock                                  | Out       |
|  6  | GND                    | Ground                                      | GND       |
|  7  | GPIO4 / GPCLK0         | General-purpose clock 0 (RP2350 PIO CLK)    | Out       |
|  8  | GPIO14 / UART0_TX      | Primary UART TX (to ESP32-S3 / debug port)  | Out       |
|  9  | GND                    | Ground                                      | GND       |
| 10  | GPIO15 / UART0_RX      | Primary UART RX                             | In        |
| 11  | GPIO17 / ASIC_MUX_SEL0 | ASIC mux select bit 0 (phi=00, euler=01)    | Out       |
| 12  | GPIO18 / PCM_CLK / I2S_BCLK | I2S bit clock (RP2350 PIO audio)       | Out       |
| 13  | GPIO27 / ASIC_MUX_SEL1 | ASIC mux select bit 1 (gamma=10)            | Out       |
| 14  | GND                    | Ground                                      | GND       |
| 15  | GPIO22                 | GPIO / UART2_TX (RP2350 PIO UART)           | Bidir     |
| 16  | GPIO23                 | GPIO / UART2_RX                             | Bidir     |
| 17  | 3V3_PWR                | 3.3 V regulated (same as pin 1)             | PWR out   |
| 18  | GPIO24                 | GPIO / PWM4 (RP2350 PIO PWM channel 4)      | Bidir     |
| 19  | GPIO10 / SPI0_MOSI     | SPI0 master-out (to external peripherals)   | Out       |
| 20  | GND                    | Ground                                      | GND       |
| 21  | GPIO9  / SPI0_MISO     | SPI0 master-in                              | In        |
| 22  | GPIO25                 | GPIO / PWM5 (RP2350 PIO PWM channel 5)      | Bidir     |
| 23  | GPIO11 / SPI0_SCLK     | SPI0 clock                                  | Out       |
| 24  | GPIO8  / SPI0_CE0_N    | SPI0 chip-enable 0 (active low)             | Out       |
| 25  | GND                    | Ground                                      | GND       |
| 26  | GPIO7  / SPI0_CE1_N    | SPI0 chip-enable 1 (active low)             | Out       |
| 27  | GPIO0  / I2C0_SDA      | I2C0 EEPROM data (HAT EEPROM on-board)      | Bidir     |
| 28  | GPIO1  / I2C0_SCL      | I2C0 EEPROM clock                           | Out       |
| 29  | GPIO5                  | GPIO / UART3_TX (RP2350 PIO UART)           | Bidir     |
| 30  | GND                    | Ground                                      | GND       |
| 31  | GPIO6                  | GPIO / UART3_RX                             | Bidir     |
| 32  | GPIO12 / PWM0          | Hardware PWM channel 0 (servo / LED dim)    | Out       |
| 33  | GPIO13 / PWM1          | Hardware PWM channel 1                      | Out       |
| 34  | GND                    | Ground                                      | GND       |
| 35  | GPIO19 / PCM_FS / I2S_LRCK | I2S L/R clock (RP2350 PIO audio)       | Out       |
| 36  | GPIO16                 | GPIO / ADC_TRIG (triggers ADS131M06 read)   | Out       |
| 37  | GPIO26 / ADC_CH0       | GPIO / ADC input route (via ADS131M06)      | In        |
| 38  | GPIO20 / PCM_DIN / I2S_SDI | I2S data in                             | In        |
| 39  | GND                    | Ground                                      | GND       |
| 40  | GPIO21 / PCM_DOUT / I2S_SDO | I2S data out                           | Out       |

**ASIC MUX select truth table:**

| SEL1 (GPIO 27) | SEL0 (GPIO 17) | Active ASIC target on SPI bus |
|:--------------:|:--------------:|-------------------------------|
| 0              | 0              | TRI-Phi  (J3)                 |
| 0              | 1              | TRI-Euler (J4)                |
| 1              | 0              | TRI-Gamma (J5)                |
| 1              | 1              | Reserved / broadcast          |

**PWM channels (8× via RP2350 PIO):** GPIO 12, 13, 18, 19, 22, 23, 24, 25 — configurable 1 Hz–62.5 MHz  
**UART channels (4×):** UART0 (GPIO 14/15), UART1 (GPIO 8/10 optional remapped), UART2 (GPIO 22/23 via PIO), UART3 (GPIO 5/6 via PIO)  
**ADC routing (6×):** GPIO 26–28 and dedicated pins routed to ADS131M06 via SPI (see Section 9)

---

## 3. Trinity ASIC ZIF Socket Pinout

> **Research demonstrator notice:** Trinity ASICs are fabricated on the educational TinyTapeout (TT) shuttle programme (TT SKY26b, SKY130A PDK). They are research demonstrators, not production accelerators. Projected performance: **~1 GOPS @ ~50 MHz @ ~1 W ternary compute**. These figures are projected based on RTL simulation; real silicon measurements are pending tape-out scheduled 2026-12-16. Do not cite these numbers as validated benchmarks until post-silicon characterisation is published.

**Sockets:** J3 (TRI-Phi), J4 (TRI-Euler), J5 (TRI-Gamma)  
**Package:** QFN-48 ZIF socket, 0.5 mm pitch, compatible with TinyTapeout 06+ (TT06+) project tiles  
**Standard:** TinyTapeout 06+ multiplexer tile I/O standard (https://tinytapeout.com/specs/tt06/)  
**Shared bus:** All three sockets share the TT-mux SPI bus; active socket selected by ASIC_MUX_SEL[1:0]

Each ASIC socket exposes the following logical signals (physical QFN-48 pins mapped below):

### 3.1 Common ZIF Pin Map (applies to J3, J4, J5)

| Pin # | Signal Name   | Width | Direction | Description                                             |
|-------|---------------|-------|-----------|---------------------------------------------------------|
|  1    | VPWR          | 1     | PWR in    | Core power supply — see Section 11 for voltage per ASIC |
|  2    | VGND          | 1     | GND       | Core ground                                             |
|  3    | VDPWR         | 1     | PWR in    | Digital I/O power (1.8 V)                               |
|  4    | VAPWR         | 1     | PWR in    | Analog power (1.8 V, low-noise rail)                    |
|  5    | VGND          | 1     | GND       | Analog ground (star-routed to power plane)              |
|  6    | clk           | 1     | In        | Primary clock (up to 50 MHz from RP2350 PIO CLK out)   |
|  7    | rst_n         | 1     | In        | Active-low reset, de-asserted after POR sequence        |
|  8    | ena           | 1     | In        | Module enable (high = active; low = power-gated tile)   |
|  9    | io_in[0]      | 1     | In        | TT-mux IO[0] — general purpose / SPI MOSI               |
| 10    | io_in[1]      | 1     | In        | TT-mux IO[1] — SPI CLK                                  |
| 11    | io_in[2]      | 1     | In        | TT-mux IO[2] — SPI CS_N                                 |
| 12    | io_in[3]      | 1     | In        | TT-mux IO[3] — config / UART RX                         |
| 13    | io_in[4]      | 1     | In        | TT-mux IO[4] — D2D mesh RX0+                            |
| 14    | io_in[5]      | 1     | In        | TT-mux IO[5] — D2D mesh RX0−                            |
| 15    | io_in[6]      | 1     | In        | TT-mux IO[6] — D2D mesh RX1+                            |
| 16    | io_in[7]      | 1     | In        | TT-mux IO[7] — D2D mesh RX1−                            |
| 17    | io_out[0]     | 1     | Out       | TT-mux IO_OUT[0] — SPI MISO / result bus                |
| 18    | io_out[1]     | 1     | Out       | TT-mux IO_OUT[1] — UART TX                              |
| 19    | io_out[2]     | 1     | Out       | TT-mux IO_OUT[2] — IRQ / ready flag                     |
| 20    | io_out[3]     | 1     | Out       | TT-mux IO_OUT[3] — attestation valid flag               |
| 21    | io_out[4]     | 1     | Out       | TT-mux IO_OUT[4] — D2D mesh TX0+                        |
| 22    | io_out[5]     | 1     | Out       | TT-mux IO_OUT[5] — D2D mesh TX0−                        |
| 23    | io_out[6]     | 1     | Out       | TT-mux IO_OUT[6] — D2D mesh TX1+                        |
| 24    | io_out[7]     | 1     | Out       | TT-mux IO_OUT[7] — D2D mesh TX1−                        |
| 25    | uio[0]        | 1     | Bidir     | Bidirectional UIO[0] — D2D mesh RX2+                    |
| 26    | uio[1]        | 1     | Bidir     | Bidirectional UIO[1] — D2D mesh RX2−                    |
| 27    | uio[2]        | 1     | Bidir     | Bidirectional UIO[2] — D2D mesh RX3+                    |
| 28    | uio[3]        | 1     | Bidir     | Bidirectional UIO[3] — D2D mesh RX3−                    |
| 29    | uio[4]        | 1     | Bidir     | Bidirectional UIO[4] — D2D mesh TX2+                    |
| 30    | uio[5]        | 1     | Bidir     | Bidirectional UIO[5] — D2D mesh TX2−                    |
| 31    | uio[6]        | 1     | Bidir     | Bidirectional UIO[6] — D2D mesh TX3+                    |
| 32    | uio[7]        | 1     | Bidir     | Bidirectional UIO[7] — D2D mesh TX3−                    |
| 33    | uio_oe[0:7]   | 8     | Out       | Direction control for uio[0:7] (1=output)               |
| 34–40 | NC            | —     | —         | Not connected, reserved for future ZIF extensions       |
| 41    | VPWR          | 1     | PWR in    | Redundant core power pin (wide trace)                   |
| 42    | VGND          | 1     | GND       | Redundant GND (thermal via array)                       |
| 43    | VDPWR         | 1     | PWR in    | Redundant digital I/O power                             |
| 44    | VAPWR         | 1     | PWR in    | Redundant analog power                                  |
| 45–48 | VGND          | —     | GND       | Additional grounds (thermal dissipation)                |

### 3.2 Per-ASIC Voltage Requirements

| ASIC       | VPWR (core) | VDPWR (I/O) | VAPWR (analog) | Max Icore |
|------------|-------------|-------------|----------------|-----------|
| TRI-Phi    | 0.85 V      | 1.8 V       | 1.8 V          | 50 mA     |
| TRI-Euler  | 0.85 V      | 1.8 V       | 1.8 V          | 200 mA    |
| TRI-Gamma  | 0.85 V      | 1.8 V       | 1.8 V          | 400 mA    |

### 3.3 D2D Mesh Lanes per ASIC Socket

Each socket carries **4 bidirectional differential pairs** (2 TX + 2 RX mapped to io_in/out, plus 2 TX + 2 RX mapped to UIO):

```
Socket J3 (Phi)                Socket J4 (Euler)               Socket J5 (Gamma)
  TX0+/TX0−  →──────────────────→  RX0+/RX0−
  RX0+/RX0−  ←──────────────────←  TX0+/TX0−
  TX1+/TX1−  →──────────────────────────────────────────────→  RX1+/RX1−
  RX1+/RX1−  ←──────────────────────────────────────────────←  TX1+/TX1−
                                 TX2+/TX2−  →──────────────→  RX2+/RX2−
                                 RX2+/RX2−  ←──────────────←  TX2+/TX2−
```

**D2D specifications:** 200 Mbps NRZ per lane, 100 Ω differential, length-matched ±5 mm, 4-layer microstrip on inner signal layer with continuous ground reference.

### 3.4 Security Notes

- **R-SI-1 invariant** (anchor value 0x47C0) is enforced **inside each ASIC** in the TRI-Phi M1 RoT module. It is not externally accessible via any ZIF socket pin.
- The `io_out[3]` attestation valid flag is a 1-bit output only; the sealed memory and φ-anchor computation are fully on-chip.
- External reset (rst_n) does not bypass the RoT — a POST must pass before io_out[3] asserts high.

---

## 4. MIPI CSI-2 Camera Connector

**Connectors:** J7 (CSI-2 Camera A), J8 (CSI-2 Camera B)  
**Physical:** 22-pin 0.5 mm pitch FFC/FPC flat flex, compatible with Raspberry Pi Camera v2/v3 / Camera Module 3  
**Standard:** MIPI CSI-2 v3.0, 4-lane D-PHY v2.1  
**Max bandwidth:** 4 lanes × 2.5 Gbps = 10 Gbps raw; practical ~4.4 Gbps (sensor limited)  
**Driver interface:** Routed through RP2350 + external MIPI D-PHY receiver (Ti SN65MIPI04, $2 BOM) or directly to Euler/Gamma ASIC camera input RTL (project-dependent)

### 4.1 22-Pin FFC Connector Pinout (Pi Camera v3 Standard)

| Pin | Signal           | Description                                              |
|-----|------------------|----------------------------------------------------------|
|  1  | GND              | Ground                                                   |
|  2  | CSI_D0_N         | Data lane 0 negative (MIPI D-PHY)                        |
|  3  | CSI_D0_P         | Data lane 0 positive                                     |
|  4  | GND              | Ground                                                   |
|  5  | CSI_D1_N         | Data lane 1 negative                                     |
|  6  | CSI_D1_P         | Data lane 1 positive                                     |
|  7  | GND              | Ground                                                   |
|  8  | CSI_CLK_N        | Clock lane negative                                      |
|  9  | CSI_CLK_P        | Clock lane positive                                      |
| 10  | GND              | Ground                                                   |
| 11  | CSI_D2_N         | Data lane 2 negative                                     |
| 12  | CSI_D2_P         | Data lane 2 positive                                     |
| 13  | GND              | Ground                                                   |
| 14  | CSI_D3_N         | Data lane 3 negative                                     |
| 15  | CSI_D3_P         | Data lane 3 positive                                     |
| 16  | GND              | Ground                                                   |
| 17  | CAM_GPIO         | Camera reset / GPIO (from RP2350 GPIO via 1 kΩ)         |
| 18  | CAM_PWDN         | Camera power-down (active high, from RP2350 GPIO)        |
| 19  | SCL0             | I2C0 clock to camera module (400 kHz)                    |
| 20  | SDA0             | I2C0 data                                                |
| 21  | 3V3_CAM          | 3.3 V power supply to camera module (regulated, 200 mA)  |
| 22  | 1V8_CAM          | 1.8 V supply to camera DVDD (from LP5907 LDO)            |

### 4.2 Compatible Camera Sensors

| Sensor       | Resolution | Interface  | Max FPS    | Notes                                  |
|--------------|------------|------------|------------|----------------------------------------|
| IMX477       | 12.3 MP    | 4-lane CSI | 60 fps 4K  | Pi HQ Camera Module                   |
| IMX708       | 11.9 MP    | 4-lane CSI | 60 fps     | Pi Camera Module 3 (HDR capable)       |
| OV5647       | 5 MP       | 2-lane CSI | 90 fps 1080p | Pi Camera v1 (2-lane subset)          |
| OV5640       | 5 MP       | 2-lane CSI | 30 fps 1080p | Generic CSI module                    |
| DVS346       | 346×260 px | 4-lane CSI | 1 Meps     | Event camera, neuromorphic input       |
| DVS240       | 240×180 px | 2-lane CSI | 0.7 Meps   | Compact event camera (DAVIS240)        |

---

## 5. HDMI 2.1 Connector

**Connector:** J10 — HDMI Type-A, 19-pin, top-mount  
**Driver IC:** LT9211C (MIPI DSI-to-HDMI bridge, $2 BOM) — Lontium Semiconductor  
**Standard:** HDMI 2.1 specification (https://www.hdmi.org/spec21Sub/Index)  
**Capabilities:** 4K@60 Hz, 8K@30 Hz (with DSC), 48 Gbps max bandwidth (FRL mode), CEC, ARC, eARC  
**Source interface:** MIPI DSI from RP2350 (via PIO) or from Gamma ASIC display pipeline RTL → LT9211C bridge → HDMI

### 5.1 HDMI Type-A 19-Pin Connector

| Pin | Signal         | Description                                                |
|-----|----------------|------------------------------------------------------------|
|  1  | TMDS_DATA2+    | TMDS data channel 2 positive                               |
|  2  | TMDS_DATA2_SHD | TMDS data channel 2 shield (GND)                           |
|  3  | TMDS_DATA2−    | TMDS data channel 2 negative                               |
|  4  | TMDS_DATA1+    | TMDS data channel 1 positive                               |
|  5  | TMDS_DATA1_SHD | TMDS data channel 1 shield (GND)                           |
|  6  | TMDS_DATA1−    | TMDS data channel 1 negative                               |
|  7  | TMDS_DATA0+    | TMDS data channel 0 positive                               |
|  8  | TMDS_DATA0_SHD | TMDS data channel 0 shield (GND)                           |
|  9  | TMDS_DATA0−    | TMDS data channel 0 negative                               |
| 10  | TMDS_CLK+      | TMDS clock channel positive                                |
| 11  | TMDS_CLK_SHD   | TMDS clock shield (GND)                                    |
| 12  | TMDS_CLK−      | TMDS clock channel negative                                |
| 13  | CEC            | Consumer Electronics Control (open-drain, to RP2350 GPIO)  |
| 14  | NC / HEC_DATA+ | Reserved (HDMI Ethernet Channel, not implemented v0.9)     |
| 15  | SCL_DDC        | DDC I2C clock (to RP2350 I2C1, 100 kHz)                    |
| 16  | SDA_DDC        | DDC I2C data (EDID read from display EEPROM)               |
| 17  | DDC/CEC_GND    | DDC / CEC ground                                           |
| 18  | HDMI_5V        | +5 V supply for hot-plug detect (from 5 V rail, 55 mA max) |
| 19  | HPD            | Hot-plug detect (input from display, pulled to HDMI_5V)    |

**LT9211C bridge notes:** DSI input up to 4 lanes, LVDS or HDMI output. I2C configuration at address 0x2D from RP2350 I2C1. 100 MHz reference clock from TCXO U18. Supports HDCP 2.3 via RP2350 firmware.

---

## 6. USB 3.2 Gen2 Type-C with PD3.1

**Connector:** J11 — USB Type-C receptacle, 24-pin, mid-mount 0.8 mm  
**PD controller:** TPS65987DDHRSKT (Texas Instruments, $4 BOM) — USB PD 3.1, up to 240 W (28 V/5 A EPR capable; board limited to 20 V/5 A = 100 W)  
**USB controller:** Routed to RP2350 USB 1.1 PHY for USB 2.0; SS lanes to Euler/Gamma ASIC USB3 RTL or external USB3 hub IC (GL3510, $2 BOM) for Super Speed  
**DP alt mode:** SBU1/SBU2 routed to LT9211C for DisplayPort 1.4 alternate mode (enables second display)

### 6.1 USB Type-C 24-Pin Pinout

| Pin | Signal     | Description                                                         |
|-----|------------|---------------------------------------------------------------------|
|  A1 | GND        | Ground                                                              |
|  A2 | SS_TX1+    | SuperSpeed TX lane 1 positive (5 Gbps, USB 3.2 Gen1)               |
|  A3 | SS_TX1−    | SuperSpeed TX lane 1 negative                                       |
|  A4 | VBUS       | Bus power (5 V default; negotiated 9 V/15 V/20 V via PD3.1)        |
|  A5 | CC1        | Configuration channel 1 (PD negotiation, orientation, ra/rb detect) |
|  A6 | D+         | USB 2.0 data positive                                               |
|  A7 | D−         | USB 2.0 data negative                                               |
|  A8 | SBU1       | Sideband use 1 (DisplayPort aux+, or audio accessory mode)          |
|  A9 | VBUS       | Bus power (parallel with A4)                                        |
| A10 | SS_RX2−    | SuperSpeed RX lane 2 negative                                       |
| A11 | SS_RX2+    | SuperSpeed RX lane 2 positive                                       |
| A12 | GND        | Ground                                                              |
|  B1 | GND        | Ground                                                              |
|  B2 | SS_TX2+    | SuperSpeed TX lane 2 positive (flip orientation)                    |
|  B3 | SS_TX2−    | SuperSpeed TX lane 2 negative                                       |
|  B4 | VBUS       | Bus power (parallel with A4, A9)                                    |
|  B5 | CC2        | Configuration channel 2 (cable plug detect, e-marker)              |
|  B6 | D+         | USB 2.0 data positive (parallel, same bus)                          |
|  B7 | D−         | USB 2.0 data negative (parallel)                                    |
|  B8 | SBU2       | Sideband use 2 (DisplayPort aux−, or audio accessory mode)          |
|  B9 | VBUS       | Bus power                                                           |
| B10 | SS_RX1−    | SuperSpeed RX lane 1 negative                                       |
| B11 | SS_RX1+    | SuperSpeed RX lane 1 positive                                       |
| B12 | GND        | Ground                                                              |

### 6.2 PD3.1 Power Profiles (TPS65987)

| Profile | Voltage | Current | Power  | Use case                     |
|---------|---------|---------|--------|------------------------------|
| Default | 5 V     | 3 A     | 15 W   | Boot / low power              |
| PD 2.0  | 9 V     | 3 A     | 27 W   | Normal operation              |
| PD 2.0  | 15 V    | 3 A     | 45 W   | All ASICs active              |
| PD 3.0  | 20 V    | 5 A     | 100 W  | Full load + peripherals       |
| EPR 3.1 | 28 V    | 5 A     | 140 W  | Reserved / future expansion   |

TPS65987 connects to RP2350 via I2C1 (address 0x20) for contract monitoring, fault detection, and voltage adjustment.

---

## 7. PCIe Gen3 × 1 M.2 E-Key Socket

**Connector:** J12 — M.2 2230 / 2242 E-Key socket, 75-pin, keyed at position E (notch at pin 75 area)  
**Standard:** PCI Express 3.0 Specification (https://pcisig.com/specifications), M.2 (NGFF) specification  
**Lanes:** 1× PCIe Gen3 (8 GT/s, ~1 GB/s unidirectional after encoding)  
**Reference clock:** 100 MHz HCSL from Si5332 clock generator (U19, $2 BOM)  
**Host interface:** PCIe root complex provided by RP2350 + external PCIe bridge IC (ASM1182e PCIe switch, $3 BOM) or dedicated PCIe endpoint logic in Euler ASIC  
**Use cases:** Wi-Fi 6E card (Intel AX210), Bluetooth/Wi-Fi combo, NVMe SSD adapter card

### 7.1 M.2 E-Key 75-Pin Key Signal Map (Selected Pins)

| Pin(s)   | Signal         | Description                                               |
|----------|----------------|-----------------------------------------------------------|
| 1        | GND            | Ground                                                    |
| 2        | 3V3            | 3.3 V supply to M.2 module (max 3 A)                      |
| 3–4      | USB_D+/D−      | USB 2.0 for Bluetooth (to RP2350 USB)                     |
| 5–6      | PETp0/PETn0    | PCIe transmit lane 0 (differential, board→card)           |
| 7        | GND            | Ground                                                    |
| 8–9      | PERp0/PERn0    | PCIe receive lane 0 (differential, card→board)            |
| 10       | GND            | Ground                                                    |
| 11–12    | REFCLK+/−      | 100 MHz PCIe reference clock (HCSL differential)          |
| 13       | CLKREQ#        | Clock request (card asserts low to enable refclk)         |
| 14       | WAKE#          | PCIe wake-from-sleep (card to host, active low)           |
| 15       | PERST#         | PCIe reset (host to card, active low, min 100 µs pulse)   |
| 20–21    | I2C_SDA/SCL    | I2C from RP2350 for module configuration                  |
| 22–25    | SDIO           | SDIO 4-bit (for SDIO-based Wi-Fi cards)                   |
| 26–29    | UART_TX/RX/CTS/RTS | UART to RP2350 (Bluetooth HCI UART interface)         |
| 32–33    | W_DISABLE1/2#  | RF kill switches (active low, RP2350 GPIO)                |
| 49–52    | CONFIG[0:3]    | Module configuration straps (PCIe mode vs. SDIO select)   |
| 53–54    | LED_WLAN/WWAN# | Activity LED outputs (drive onboard LEDs D7/D8)           |
| 73–74    | 3V3            | 3.3 V supply (parallel with pin 2)                        |
| 75       | GND            | Ground / E-Key mechanical notch reference                 |

---

## 8. GbE RJ45 with PoE+

**Connector:** J13 — RJ45 8P8C, shielded, integrated magnetic (Bob-Smith termination)  
**PHY:** KSZ9897RTXI (Microchip, $8 BOM) — 7-port managed GbE switch PHY; 1 port used, 6 available for future expansion  
**PoE controller:** Si3404-GM (Silicon Laboratories, $3 BOM) — IEEE 802.3at PoE PD (powered device), 25.5 W Class 4  
**Magnetics:** Integrated into RJ45 connector (Bel Fuse SI-60162-F or equivalent, $2 BOM)  
**Standard:** IEEE 802.3-2022, 1000BASE-T; IEEE 802.3at (PoE+)

### 8.1 RJ45 Pin → PHY Signal Map (T568B wiring)

| RJ45 Pin | Wire color    | 1000BASE-T pair | KSZ9897 signal |
|----------|---------------|-----------------|----------------|
| 1        | White/Orange  | BI_DA+          | MDI0+          |
| 2        | Orange        | BI_DA−          | MDI0−          |
| 3        | White/Green   | BI_DB+          | MDI1+          |
| 4        | Blue          | BI_DC+          | MDI2+          |
| 5        | White/Blue    | BI_DC−          | MDI2−          |
| 6        | Green         | BI_DB−          | MDI1−          |
| 7        | White/Brown   | BI_DD+          | MDI3+          |
| 8        | Brown         | BI_DD−          | MDI3−          |

**KSZ9897 to RP2350 interface:** RGMII (125 MHz) or SGMII 1.25 GHz, plus MDIO management (2-wire), I2C at address 0x5F for extended register access.

### 8.2 PoE+ Power Path (Si3404)

```
RJ45 Pins 1,2,3,6 (data pairs) ─────→ Si3404 input bridge ─→ VPOE_IN
RJ45 Pins 4,5,7,8 (spare pairs) ────→ Si3404 input bridge ─→ VPOE_IN
                                                               │
                                                Si3404 DC/DC converter
                                                  (36–57 V input)
                                                               │
                                                    5 V / 5 A output
                                                               │
                              ┌────────────────────────────────┘
                              │
                        TPS62873A 0.85 V
                        LP5907   1.8 V      (same power tree as USB-C)
                        TLV75801 3.3 V
```

PoE+ class negotiation: Si3404 presents Class 4 signature (max 25.5 W). If no PoE injector is detected, Si3404 shuts its output and USB-C PD is the sole power source.

---

## 9. 6× 12-Bit ADC Channels

**IC:** ADS131M06IPBSR (Texas Instruments, $6 BOM) — 6-channel, simultaneous-sampling, 24-bit (used at 12-bit effective for speed), delta-sigma ADC  
**Interface:** SPI (SPI1 on RP2350, GPIO 10-13 repurposed, or dedicated SPI via PIO)  
**Sample rate:** Up to 32 kSPS per channel simultaneously  
**Input range:** ±1.2 V differential (with 0–3.3 V single-ended via voltage divider)  
**Connector:** J14 — 14-pin 2.54 mm header (6 CH pairs + power + SPI)

### 9.1 ADC Channel Assignments

| Channel | Differential +  | Differential −  | Suggested use case                       |
|---------|-----------------|-----------------|------------------------------------------|
| CH0     | AIN0+ (J14-1)   | AIN0− (J14-2)   | Vibration / MEMS accelerometer (X-axis)  |
| CH1     | AIN1+ (J14-3)   | AIN1− (J14-4)   | Vibration / MEMS accelerometer (Y-axis)  |
| CH2     | AIN2+ (J14-5)   | AIN2− (J14-6)   | Thermal sensor (PT1000 RTD or thermistor) |
| CH3     | AIN3+ (J14-7)   | AIN3− (J14-8)   | Thermal sensor (second zone)             |
| CH4     | AIN4+ (J14-9)   | AIN4− (J14-10)  | Audio line-in (left channel, AC-coupled) |
| CH5     | AIN5+ (J14-11)  | AIN5− (J14-12)  | Audio line-in (right channel, AC-coupled)|

| J14 Pin | Signal         | Description                                              |
|---------|----------------|----------------------------------------------------------|
| 13      | AVDD (3.3 V)   | Analog supply for ADS131M06                              |
| 14      | AGND           | Analog ground (star-route to main GND)                   |
| 15      | SPI_CLK        | SPI clock from RP2350 SPI1                               |
| 16      | SPI_MOSI       | SPI data to ADS131M06                                    |
| 17      | SPI_MISO       | SPI data from ADS131M06                                  |
| 18      | SPI_CS_N       | SPI chip select (active low)                             |
| 19      | DRDY_N         | Data ready interrupt to RP2350 (active low)              |
| 20      | RESET_N        | ADC reset (active low, tie high via 10 kΩ)               |

**Single-ended configuration:** Wire AIN0− through AIN5− to AGND via 100 Ω resistor; range becomes 0–1.2 V. Use resistor divider for 0–3.3 V inputs.

---

## 10. CAN-FD Transceiver

**IC:** TCAN1051HVDRQ1 (Texas Instruments, $2 BOM) — automotive CAN-FD transceiver, 5 Mbps data phase, 1 Mbps arbitration, AEC-Q100 qualified  
**Host interface:** RP2350 CAN-FD PIO (RP2350 natively supports CAN via PIO state machine at up to 5 Mbps)  
**Connector:** J15 — 4-pin 3.81 mm screw terminal (CANH, CANL, GND, 12V_CAN optional) + 5-pin 2.54 mm debug header  
**Bus termination:** 120 Ω split-termination network on-board (2× 60 Ω + 4.7 nF Y-cap to GND)

### 10.1 CAN-FD Connector Pinout

| Pin | J15 Signal | Description                                               |
|-----|------------|-----------------------------------------------------------|
| 1   | CANH       | CAN bus high (ISO 11898-2)                                |
| 2   | CANL       | CAN bus low                                               |
| 3   | GND_CAN    | Isolated CAN ground reference                             |
| 4   | 12V_CAN    | Optional 12 V supply for external nodes (input, passive)  |

| Pin | J15 debug | Signal    | Description                                        |
|-----|-----------|-----------|----------------------------------------------------|
| 5   | TXD       | RP2350 PIO TX | CAN TX from RP2350 to TCAN1051 (3.3 V logic) |
| 6   | RXD       | RP2350 PIO RX | CAN RX from TCAN1051 to RP2350               |
| 7   | STB_N     | RP2350 GPIO   | Standby mode (active low; low=standby)       |
| 8   | INH       | TCAN1051 out  | Inhibit pin for external voltage regulator   |
| 9   | GND       | PCB GND       | Ground                                       |

### 10.2 CAN-FD Parameters

| Parameter       | Value          | Notes                                          |
|-----------------|----------------|------------------------------------------------|
| Arbitration rate| Up to 1 Mbps   | ISO 11898-1 nominal bit timing                 |
| Data rate       | Up to 5 Mbps   | ISO 11898-7 CAN-FD data phase                  |
| Bus voltage     | 0–60 V fail-safe | Survives automotive 58 V load-dump           |
| Common mode     | ±25 V          | Allows ground offsets in multi-node systems    |
| ESD protection  | ±8 kV HBM      | Human body model                               |
| Termination     | 120 Ω split    | On-board; jumper JP3 to disable for multi-node |

**Use cases:** Robotics joint control, automotive ADAS sensor bus, industrial PLC I/O, energy storage management system (BMS).

---

## 11. Power Tree Diagram

```
                         ┌──────────────────────────────────────────────────┐
                         │              Power Input Stage                    │
                         │                                                   │
  USB-C J11  ────────────┤  TPS65987 PD3.1         5 V / 5 A = 25 W        │
  (5–20 V, PD negotiated)│  (PD contract mgr,       nominal                 │
                         │   I2C to RP2350)                                  │
  RJ45 PoE+ J13 ─────────┤  Si3404 DC/DC            5 V / 5 A = 25 W        │
  (36–57 V in)           │  (IEEE 802.3at Class 4)                           │
                         │                                                   │
                         │  OR logic: USB-C preferred; PoE fallback          │
                         │  Diode OR: PMEG10020ELRX Schottky pair            │
                         └─────────────────────┬────────────────────────────┘
                                               │
                                           5 V_MAIN
                                               │
              ┌────────────────────────────────┼──────────────────────────────┐
              │                                │                              │
              ▼                                ▼                              ▼
     ┌─────────────────┐            ┌─────────────────┐            ┌──────────────────┐
     │  TLV75801-33    │            │  TPS62873A      │            │  RT8288A boost   │
     │  LDO, 1 A       │            │  Buck, 6 A      │            │  (optional, U6)  │
     │  5 V → 3.3 V    │            │  5 V → 0.85 V   │            │  5 V → 12 V      │
     │  (RP2350, ESP32,│            │  (all 3 Trinity │            │  for camera flash│
     │   sensors, SPI, │            │   ASIC cores,   │            │  /MIPI flash LED)│
     │   GPIO pullups) │            │   per-ASIC gating│           └──────────────────┘
     └────────┬────────┘            └────────┬────────┘
              │ 3.3V_SYS                     │ 0.85V_ASIC
              │                              │
              ├──────────────────────┐       ├── TRI-Phi VPWR (50 mA)
              │                      │       ├── TRI-Euler VPWR (200 mA)
              ▼                      ▼       └── TRI-Gamma VPWR (400 mA, peak)
     ┌────────────────┐   ┌──────────────────────────────────────────────────┐
     │  LP5907MFX-18  │   │  RT9193-18GB LDO           2× outputs           │
     │  LDO, 250 mA   │   │  5 V → 1.8 V (LPDDR5 I/O) TLV62568 1.1 V buck  │
     │  5 V → 1.8 V   │   │  100 mA                    5 V → 1.1 V          │
     │  (ASIC VDPWR,  │   │  (LPDDR5 VDDQ I/O)         (LPDDR5 VDDC core)   │
     │   VAPWR, CSI   │   └──────────────────────────────────────────────────┘
     │   camera DVDD) │
     └────────────────┘

Power regulator summary:
  U8:  TLV75801-33    3.3 V / 1 A LDO     — system 3.3 V rail
  U9:  TPS62873ADSSR  0.85 V / 6 A buck   — Trinity ASIC core (shared, gated)
  U10: LP5907MFX-18   1.8 V / 250 mA LDO  — ASIC I/O + analog + CSI
  U11: RT9193-18GB    1.8 V / 300 mA LDO  — LPDDR5 VDDQ (I/O termination)
  U12: TLV62568DRLR   1.1 V / 1 A buck    — LPDDR5 VDDC (core)
  U6:  RT8288A        5 V→12 V boost       — camera flash / optional
  Q1–Q3: DMN2056UW load switches, per-ASIC 0.85 V gating (RP2350 GPIO)

Total board power budget:
  Idle:     ~1.5 W (RP2350 + ESP32 + PHY, no ASICs active)
  Typical:  ~8 W   (all ASICs active, 50% load)
  Peak:     ~22 W  (all ASICs full compute + USB3 + GbE + PoE supply)
```

---

## 12. D2D Mesh Bus Topology

### 12.1 Inter-ASIC Routing

```
PCB Top Layer (signal) — D2D Mesh Differential Pairs

  J3 (TRI-Phi)                J4 (TRI-Euler)              J5 (TRI-Gamma)
  ┌──────────┐                ┌──────────────┐             ┌──────────────┐
  │ TX0+ ───────────────────► │ RX0+         │             │              │
  │ TX0− ───────────────────► │ RX0−         │             │              │
  │ RX0+ ◄─────────────────── │ TX0+         │             │              │
  │ RX0− ◄─────────────────── │ TX0−         │             │              │
  │          │                │              │             │              │
  │ TX1+ ──────────────────────────────────────────────► │ RX1+         │
  │ TX1− ──────────────────────────────────────────────► │ RX1−         │
  │ RX1+ ◄─────────────────────────────────────────────── │ TX1+         │
  │ RX1− ◄─────────────────────────────────────────────── │ TX1−         │
  └──────────┘                │              │             │              │
                              │ TX2+ ────────────────────► │ RX2+         │
                              │ TX2− ────────────────────► │ RX2−         │
                              │ RX2+ ◄──────────────────── │ TX2+         │
                              │ RX2− ◄──────────────────── │ TX2−         │
                              └──────────────┘             └──────────────┘

  Total pairs: 6 bidirectional differential pairs (12 physical traces)
  Total bandwidth: 6 pairs × 200 Mbps × 2 (bidir) = 2.4 Gbps aggregate
```

### 12.2 PCB Routing Rules for D2D Mesh

| Parameter               | Specification                                          |
|-------------------------|--------------------------------------------------------|
| Differential impedance  | 100 Ω ± 10%                                           |
| Single-ended impedance  | 50 Ω                                                   |
| Layer                   | Layer 2 (inner signal), referenced to Layer 3 GND plane|
| Topology                | Point-to-point (no stubs)                              |
| Intra-pair skew         | < 5 ps (< 1 mm physical)                              |
| Inter-pair length match | ± 5 mm (< 33 ps at 6 mil/ps)                          |
| Via count               | 0 preferred; max 1 via per pair crossing layer         |
| Trace width             | 0.127 mm (5 mil) for 100 Ω differential, 4-layer stack |
| Gap between pairs       | Minimum 3× trace width (0.38 mm) for crosstalk        |
| Ground pour             | Continuous plane on Layer 3 directly under D2D region  |
| Termination             | Near-end: 100 Ω differential source termination on-die |
| Data encoding           | NRZ (non-return-to-zero), no 8b/10b overhead           |
| Max frequency           | 100 MHz (200 Mbps NRZ)                                 |

---

## 13. Mechanical Drawing (Top View)

```
 ┌──────────────────────────────────────────────────────── 100 mm ────────────────────────────────────────────────────────────┐
 │ ←2.5→ ←2.5→                                                                                                                  │
 │  M2.5   M2.5                       TOP EDGE                                                           M2.5   M2.5          │ ↑
 │  mount  mount                                                                                          mount  mount         │
 │  ●                                                                                                              ●           │
 │                                                                                                                             │
 │  [J1: 40-pin GPIO header, 2×20, 2.54mm] [J10: HDMI 2.1] [J7: CSI-2 A 22p] [J8: CSI-2 B 22p] [J11: USB-C PD3.1]          │
 │  ████████████████████████████████████    ██████████████   ████████████████  ████████████████  ████████████████              │
 │  (left-aligned, 5mm from left edge)      (3mm from J1)    (2mm from HDMI)   (2mm from CSI-A)  (right-flush)                │
 │                                                                                                                             │ 60
 │  ─────────────────────────── CENTER REGION ────────────────────────────────────────────────    [J12: M.2 E-Key] ──────────┤ mm
 │                                                                                                  ████████████████████████  │
 │  [J3: ZIF TRI-Phi]  [J4: ZIF TRI-Euler]  [J5: ZIF TRI-Gamma]     ← ASIC sockets (ZIF, 0.5mm)  (right edge, vertical)     │
 │  ┌────────────┐     ┌───────────────────┐ ┌───────────────────┐                                                            │
 │  │  TRI-Phi   │     │    TRI-Euler      │ │    TRI-Gamma      │  ← 5mm heatsink keep-out around each socket               │
 │  │  1×1 tile  │     │    8×2 tiles      │ │    8×4 tiles      │                                                            │
 │  └────────────┘     └───────────────────┘ └───────────────────┘  [J13: RJ45 GbE PoE+]                                     │
 │                                                                    ████████████████████                                    │
 │  [U1: RP2350]  [U2: ESP32-S3]  [U6: LPDDR5 8GB]  [U7: eMMC 64GB] (right edge, below M.2)                                  │
 │  ┌──────────┐  ┌────────────┐  ┌────────────────┐ ┌───────────┐                                                           │
 │  │ RP2350   │  │ ESP32-S3   │  │ MT62F2G32D4DR  │ │KLMBG2JETD │                                                           │
 │  │ QFN-60   │  │ QFN-56     │  │ BGA-200        │ │ BGA-153   │                                                           │
 │  └──────────┘  └────────────┘  └────────────────┘ └───────────┘                                                           │
 │                                                                                                                             │
 │  BOTTOM EDGE                                                                                                                │
 │  [J14: ADC 6ch] [J15: CAN-FD] [J16: JTAG/SWD] [SW1: PWR BTN] [D1..D8: status LEDs ×8]                                   │
 │  ████████████   ████████████   █████████████████  ████████████  ████████████████████████████                               │
 │                                                                                                                             │
 │  ●                                                                                              ●                          │ ↓
 │  M2.5                                                                                           M2.5                       │
 └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

Notes:
  • Board outline: 100 mm × 60 mm FR4, 1.6 mm thick, ENIG finish (gold over nickel)
  • 4-layer stackup: Top Cu (signal+power) / PP / Inner1 GND / PP / Inner2 Signal / PP / Bottom Cu (GND+signal)
  • Mounting holes: M2.5, 2.5 mm from board edges, at all 4 corners (58 mm × 96.5 mm pitch)
  • Heatsink keep-out: 5 mm radius around each ZIF socket (total exclusion 30×30 mm center strip)
  • Component side: all active ICs top side; passives on bottom side allowed
  • Thermal vias under each ASIC ZIF socket: 16× 0.3 mm via thermal relief to inner GND plane
  • Pi HAT+ mechanical compliance: GPIO header J1 at X=3.5 mm, Y=32.5 mm from left-bottom corner
```

---

## 14. JTAG/SWD Debug Header

**Connector:** J16 — 10-pin 1.27 mm pitch, 2×5, ARM Cortex standard debug connector (Samtec FTSH-105-01-L-DV or equivalent)  
**Standard:** ARM Cortex Debug Connector specification (IHI0031F)  
**Targets:** RP2350, ESP32-S3, TRI-Phi, TRI-Euler, TRI-Gamma — all multiplexed via JTAG TAP scan chain  
**SWD subset:** Pins 1–6 usable for SWD (SWDIO/SWCLK/SWO) for RP2350 direct access

### 14.1 10-Pin ARM Cortex JTAG/SWD Pinout

| Pin | Signal  | Direction     | Description                                               |
|-----|---------|---------------|-----------------------------------------------------------|
|  1  | VCC     | Output        | Target reference voltage (3.3 V from board; do not power) |
|  2  | SWDIO / TMS | Bidir     | SWD data / JTAG test mode select                          |
|  3  | GND     | Ground        | Ground                                                    |
|  4  | SWCLK / TCK | Input     | SWD clock / JTAG test clock (max 50 MHz)                  |
|  5  | GND     | Ground        | Ground                                                    |
|  6  | SWO / TDO | Output      | SWD trace output / JTAG data out                          |
|  7  | NC      | —             | Not connected (KEY pin, physical guide)                   |
|  8  | TDI     | Input         | JTAG data in (not used in SWD mode)                       |
|  9  | GND     | Ground        | Ground                                                    |
| 10  | nRST    | Open-drain    | System reset, active low (ties to board RST_N net)        |

### 14.2 JTAG TAP Scan Chain

RP2350 JTAG TAP → TRI-Phi TAP → TRI-Euler TAP → TRI-Gamma TAP → ESP32-S3 JTAG TAP (via TRST_N isolation)

```
                        ┌──────────────────────────────────────────────────────────────────┐
  J16 TDI ──────────────► RP2350 JTAG TDI → TDO ──► Phi TDI → TDO ──► Euler TDI → TDO ──► Gamma TDI → TDO ──► ESP32 TDI → TDO ──→ J16 TDO
  J16 TCK ──────────────► All TAPs in parallel (TCK shared, TMS shared)
  J16 TMS ──────────────►
  J16 nRST ─────────────► TRST_N to all TAPs (reset entire chain simultaneously)
```

**Supported debuggers:** J-Link, OpenOCD (rp2350 + esp32s3 targets), Black Magic Probe  
**RP2350 SWD mode:** Use pins 1,2,4,10 only; SWO trace on pin 6 (8 MHz max, Manchester)  
**Maximum scan chain depth:** 5 TAPs, max IR length 40 bits total

---

## 15. Status Indicators

**LEDs:** D1–D8, top edge, 0402 package, 3.3 V logic (RP2350 GPIO with 330 Ω current-limit resistors)  
**All LEDs:** reflow-mounted on top side, 1.5 mm from top board edge, 10 mm pitch along top edge

| LED | Ref | Color  | GPIO source    | Function                             | Behavior                                      |
|-----|-----|--------|----------------|--------------------------------------|-----------------------------------------------|
| D1  | PWR | Green  | 3V3_PGOOD rail | 3.3 V power good                     | Steady on when 3V3 rail stable                |
| D2  | HBT | Blue   | RP2350 GPIO 0  | Heartbeat (RP2350 alive)             | 1 Hz blink from RP2350 firmware ticker        |
| D3  | PHI | White  | RP2350 GPIO 1  | TRI-Phi clock active                 | On when clk fed to J3, blinks on SPI activity |
| D4  | EUL | White  | RP2350 GPIO 2  | TRI-Euler clock active               | On when clk fed to J4                         |
| D5  | GAM | White  | RP2350 GPIO 3  | TRI-Gamma clock active               | On when clk fed to J5                         |
| D6  | ANC | Red/Green| RP2350 GPIO 4 (dual) | Anchor 0x47C0 φ-invariant verified | Red during POST; green when Phi io_out[3]=1 (anchor verified); stays red if POST fails |
| D7  | NET | Yellow | KSZ9897 LED0   | GbE link / activity                  | On = link up 1 Gbps; blinks = traffic         |
| D8  | WIF | Cyan   | ESP32-S3 GPIO  | Wi-Fi 6 connected                    | On = associated + IP obtained                 |

**D6 ANCHOR detail:**  
- Driven by RP2350 reading `io_out[3]` from the active ASIC MUX (selects Phi by default at reset)  
- Red state: waiting for TRI-Phi POST to complete (first 2 seconds after reset)  
- Green state: TRI-Phi φ-anchor 0x47C0 verified, node cleared for DePIN operation  
- Red persistent: silicon fault, counterfeit chip, or bitrot — node halted, UART prints diagnostic  
- Implementation: RP2350 GPIO 4 drives two LEDs via MOSFET switch (red: Q4 BSS138, green: Q5 BSS138), mutually exclusive

---

## 16. Bill of Components Summary

**BOM target:** $90 base (Trinity DevKit Pro), $180 Plus (with enclosure + accessories)  
**Volume:** 1,000-unit pricing  
**Suppliers:** Mouser Electronics, DigiKey, LCSC (for JLCPCB compatibility)

| # | Part Number              | Component                      | Qty | Unit Price | Supplier         | Function                                          |
|---|--------------------------|--------------------------------|-----|------------|------------------|---------------------------------------------------|
| 1 | TRI-Phi (gHashTag MPW)   | TRI-1 Phi ASIC, 1×1, SKY130A  | 1   | $10.00     | gHashTag fab     | Identity, RoT, M1/M2/M3, φ-anchor 0x47C0         |
| 2 | TRI-Euler (gHashTag MPW) | TRI-1 Euler ASIC, 8×2, SKY130A| 1   | $50.00     | gHashTag fab     | Groth16/BN254 ZK, ML research RTL (TT research demonstrator) |
| 3 | TRI-Gamma (gHashTag MPW) | TRI-1 Gamma ASIC, 8×4, SKY130A| 1   | $80.00     | gHashTag fab     | Perception + inference research RTL (TT research demonstrator) |
| 4 | RP2350A                  | RP2350 dual Cortex-M33 MCU     | 1   | $1.50      | Mouser / DigiKey | Host MCU, SPI mux ctrl, PIO, CAN-FD, UART         |
| 5 | ESP32-S3-WROOM-1-N16R8   | ESP32-S3 Wi-Fi6/BT5.3 module  | 1   | $3.00      | LCSC / DigiKey   | Wi-Fi 802.11ax, BT 5.3, BLE, secondary MCU        |
| 6 | MT62F2G32D4DR-026 WT:A   | Micron LPDDR5 8 GB x32 BGA-200 | 1   | $18.00     | Mouser / Micron  | Main memory, 6400 Mbps/pin, 51.2 GB/s bandwidth   |
| 7 | KLMBG2JETD-B041          | Samsung eMMC 5.1 64 GB BGA-153 | 1   | $8.00      | Mouser / Samsung | Boot storage, HS400 400 MB/s, JEDEC e·MMC 5.1     |
| 8 | TPS65987DDHRSKT          | TI USB-C PD3.1 controller      | 1   | $4.00      | Mouser (TI)      | USB PD contract mgr, 20 V/5 A, CC1/CC2, I2C cfg   |
| 9 | KSZ9897RTXI              | Microchip 7-port GbE PHY       | 1   | $8.00      | Mouser / DigiKey | GbE MAC/PHY, RGMII, MDIO, managed switch core     |
|10 | Si3404-GM                | SiLabs PoE PD controller       | 1   | $3.00      | Mouser           | IEEE 802.3at Class 4 PD, 25.5 W, 36–57 V input    |
|11 | LT9211CEUFD              | Lontium MIPI DSI→HDMI bridge   | 1   | $2.00      | LCSC             | DSI to HDMI 2.1 / LVDS, 4K@60, I2C config         |
|12 | ADS131M06IPBSR           | TI 6-ch simultaneous ADC       | 1   | $6.00      | Mouser (TI)      | 24-bit delta-sigma, 32 kSPS, SPI, 6 diff channels  |
|13 | TCAN1051HVDRQ1           | TI CAN-FD transceiver          | 1   | $2.00      | Mouser (TI)      | 5 Mbps CAN-FD, AEC-Q100, ±25 V common mode        |
|14 | TPS62873ADSSR            | TI 0.85 V 6 A buck regulator   | 1   | $3.50      | Mouser (TI)      | ASIC core power, 92% efficiency, I2C trim          |
|15 | 4-layer PCB 100×60 mm    | JLCPCB 4L, ENIG, controlled Z  | 1   | $5.00      | JLCPCB           | Board substrate, 4-layer, 1 oz Cu, 1.6 mm FR4     |

**Subtotal (top 15):** ~$204 (includes 3 ASIC cost which is the dominant factor)  
**Remaining BOM** (passives, connectors, LDOs, clock gen, assembly): ~$26  
**Total base BOM @ 1K vol:** ~$90 without ASICs / ~$230 including ASICs  
**ASIC cost is the key variable:** at 10K units + IHP26b port, ASIC costs drop ~40% → $90 base becomes achievable as the non-ASIC PCB BOM  
**DevKit Pro pricing:** Developer Edition $299 (Q3 2027); Consumer Plus $399 (Q4 2027 mainnet launch)

---

## 17. Open-Source Release Plan

**Repository:** https://github.com/gHashTag/trinity-devkit-pro  
**License:** CERN-OHL-S-2.0 (strong reciprocal — all derivatives must be open hardware)  
**Target release:** Alongside KiCad 8.0 schematic finalization and first silicon tape-out (TT07/TT08 shuttle)

### 17.1 Repository Structure

```
trinity-devkit-pro/
├── README.md                           # Project overview, quick start, BOM link
├── LICENSE                             # CERN-OHL-S-2.0 full text
├── CHANGELOG.md                        # Version history
├── hardware/
│   ├── trinity-devkit-pro.kicad_sch    # KiCad 8.0 hierarchical schematic
│   ├── trinity-devkit-pro.kicad_pcb    # KiCad 8.0 PCB layout (100×60 mm)
│   ├── trinity-devkit-pro.kicad_pro    # KiCad project file
│   ├── fp-lib-table                    # Footprint library references
│   ├── sym-lib-table                   # Symbol library references
│   ├── footprints/                     # Custom footprints (ZIF sockets, etc.)
│   └── 3d-models/
│       └── trinity-devkit-pro.step     # STEP 3D model for mechanical integration
├── manufacturing/
│   ├── gerbers/                        # Gerber RS-274X files (all layers)
│   │   ├── trinity-devkit-pro-F_Cu.gbr # Front copper
│   │   ├── trinity-devkit-pro-B_Cu.gbr # Back copper
│   │   ├── trinity-devkit-pro-In1_Cu.gbr # Inner layer 1 (GND)
│   │   ├── trinity-devkit-pro-In2_Cu.gbr # Inner layer 2 (signal)
│   │   ├── trinity-devkit-pro-F_Silkscreen.gbr
│   │   ├── trinity-devkit-pro-F_Mask.gbr
│   │   ├── trinity-devkit-pro-B_Mask.gbr
│   │   └── trinity-devkit-pro-Edge_Cuts.gbr
│   ├── drill/
│   │   └── trinity-devkit-pro.drl      # Excellon drill file
│   ├── pick-and-place/
│   │   └── trinity-devkit-pro-cpl.csv  # Component placement list (JLCPCB format)
│   └── bom/
│       ├── trinity-devkit-pro-bom.csv  # Full BOM with Mouser + DigiKey part numbers
│       └── trinity-devkit-pro-bom-jlcpcb.csv # JLCPCB SMT assembly BOM
├── firmware/
│   └── README.md                       # Links to gHashTag/trinity-firmware repo
└── docs/
    ├── PINOUT.md                       # This document
    ├── ROADMAP.md                      # Development roadmap
    └── DATASHEET.pdf                   # Generated datasheet
```

### 17.2 Release Milestones

| Milestone | Target date | Contents                                                   |
|-----------|-------------|-------------------------------------------------------------|
| v0.1-alpha | Q2 2026    | Schematic draft, block diagram, BOM v1                     |
| v0.5-beta  | Q4 2026    | Full KiCad schematic + PCB layout, DRC clean               |
| v0.9-rc1   | Q1 2027    | Manufacturing files, 3D model, first prototype spin        |
| v1.0       | Q3 2027    | Production-validated, TT07 ASICs populated, docs complete  |

### 17.3 CERN-OHL-S-2.0 Compliance Notes

- All KiCad source files (`.kicad_sch`, `.kicad_pcb`) constitute the "source" under CERN-OHL-S-2.0 §1.7
- Any commercial manufacturer producing boards from this design must provide source files to customers
- Derivatives must retain the `CERN-OHL-S-2.0` license and `gHashTag/trinity-devkit-pro` attribution
- The Trinity ASIC GDS/RTL source is separately licensed under Apache-2.0 in `gHashTag/trinity-asic`

---

## 18. References

### Primary Hardware Specifications

1. **Raspberry Pi 5 GPIO pinout** — https://www.raspberrypi.com/documentation/computers/raspberry-pi.html  
2. **Pi HAT+ mechanical specification** — https://datasheets.raspberrypi.com/hat/hat-plus-specification.pdf  
3. **TinyTapeout 06+ (TT06+) mux specification** — https://tinytapeout.com/specs/tt06/  
4. **MIPI Alliance CSI-2 v3.0 specification** — https://www.mipi.org/specifications/csi-2  
5. **MIPI Alliance D-PHY v2.1 specification** — https://www.mipi.org/specifications/d-phy  
6. **HDMI 2.1 specification** — https://www.hdmi.org/spec21Sub/Index  
7. **PCI Express 3.0 specification** — https://pcisig.com/specifications  
8. **M.2 (NGFF) specification** — https://www.ngff.org  
9. **IEEE 802.3at PoE+ (2009)** — https://standards.ieee.org/ieee/802.3at/4553/  
10. **USB Type-C Cable and Connector Specification Rev 2.1** — https://www.usb.org/document-library/usb-type-c-cable-and-connector-specification-revision-21  
11. **USB Power Delivery Specification Rev 3.1** — https://www.usb.org/document-library/usb-power-delivery  
12. **ARM Cortex Debug Connector specification IHI0031F** — https://developer.arm.com/documentation/ihi0031  
13. **CAN-FD ISO 11898-7:2024** — https://www.iso.org/standard/84010.html  

### Component Datasheets

14. **RP2350 datasheet** — https://datasheets.raspberrypi.com/rp2350/rp2350-datasheet.pdf  
15. **Micron MT62F2G32D4DR LPDDR5 datasheet** — https://www.micron.com/products/dram/lpddr5  
16. **Samsung KLMBG2JETD-B041 eMMC datasheet** — https://semiconductor.samsung.com/consumer-storage/emmc/  
17. **TPS65987 USB-C PD controller** — https://www.ti.com/product/TPS65987D  
18. **TPS62873A buck converter** — https://www.ti.com/product/TPS62873  
19. **KSZ9897 GbE switch PHY** — https://www.microchip.com/en-us/product/KSZ9897  
20. **Si3404 PoE PD controller** — https://www.silabs.com/power/poe-controllers  
21. **LT9211 MIPI-to-HDMI bridge** — https://www.lontiumsemi.com/product/LT9211  
22. **ADS131M06 ADC** — https://www.ti.com/product/ADS131M06  
23. **TCAN1051HV CAN-FD transceiver** — https://www.ti.com/product/TCAN1051HV  

### Trinity Project Documents

24. **Trinity DevKit Pro Roadmap** — `/tmp/depin_gaps/TRINITY_DEVKIT_PRO_ROADMAP.md`  
25. **Trinity Node Hardware Kit BOM** — `/tmp/depin_gaps/TRINITY_NODE_HW_KIT_BOM.md`  
26. **Trinity Integrative Paper draft** — `/tmp/depin_gaps/TRINITY_INTEGRATIVE_PAPER_DRAFT.md`  
27. **Trinity M1 Hardware Root of Trust spec** — `/tmp/depin_gaps/M1_HW_ROOT_OF_TRUST_SPEC.md`  
28. **Zenodo DOI** — https://zenodo.org/badge/latestdoi/trinity-devkit-pro (to be minted at v1.0 release)  
29. **CERN-OHL-S-2.0 license text** — https://cern-ohl.web.cern.ch/  
30. **gHashTag/trinity-devkit-pro repository** — https://github.com/gHashTag/trinity-devkit-pro  

---

*Document version: 0.9.0-draft — Trinity DevKit Pro Pinout & PCB Layout Reference*  
*Generated: 2026-05-18 | Author: Dmitrii Vasilev (NeuronConstant / IGLA / Trinity TRI-27)*  
*License: CERN-OHL-S-2.0 | Repository: https://github.com/gHashTag/trinity-devkit-pro*
