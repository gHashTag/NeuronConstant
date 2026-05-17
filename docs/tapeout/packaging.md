# Packaging & DevKit Board — TRI-1 Triad

**Shuttle:** TTSKY26b · **Process:** SKY130A

---

## DIP-32 Socket

Each Tiny Tapeout TTSKY26b chip is packaged in a **DIP-32** (Dual In-line Package, 32 pins) ceramic package.

| Parameter | Value |
|-----------|-------|
| Package | DIP-32 |
| Pin pitch | 2.54mm (100 mil) |
| Body width | 15.24mm (600 mil) |
| Supply | 1.8V core / 3.3V IO (SKY130A) |

Three DIP-32 sockets are mounted on the TRI-1 Triad DevKit board:
- Socket 1: TRI-1 Phi (φ-anchor, #4914)
- Socket 2: TRI-1 Euler (e-engine, #4915)
- Socket 3: TRI-1 Gamma (γ-surface, #4913)

---

## DevKit Board

The Tiny Tapeout SKY130A DevKit board provides:

| Feature | Specification |
|---------|--------------|
| Controller | RP2040 (dual-core ARM Cortex-M0+) |
| IO mux | SPI-controlled hardware multiplexer |
| Clock | 50 MHz oscillator → all chip CLK pins |
| Reset | RP2040 GPIO → all three `rst_n` pins simultaneously |
| USB | USB-C for host communication |
| Headers | 2× 20-pin female headers (IO access) |

### IO Mux Channels

| Channel | Chip | TT Slot |
|---------|------|---------|
| 0 | TRI-1 Phi (φ-anchor) | #4914 |
| 1 | TRI-1 Euler (e-engine) | #4915 |
| 2 | TRI-1 Gamma (γ-surface) | #4913 |

### Cross-Die Wiring

Board traces implement the 3-wire handshake:
- **Wire A (LOAD_MODE):** Phi `ui[0]` driver → Euler `ui[0]` AND Gamma `ui[0]`
- **Wire B (SYNC_STROBE):** Phi `ui[6]` driver → Euler pulse path (muxed)
- **Wire C (ACK):** Euler `uo[0]` + Gamma `uio[3]` → Phi dedicated GPIO

D2D forwarding trace:
- Euler `uo[7:0]` → Gamma `uio[4]` (D2D n_rx) via trace J1
- Gamma `uio[1]` (D2D e_tx) → Phi mux input via trace J3

---

## Bring-Up Checklist

```
[ ] Insert all 3 DIP-32 chips into correct sockets
[ ] Connect USB-C to host
[ ] Flash RP2040 firmware (see docs/interconnect.md §7)
[ ] Run anchor verification: expect 0x47C0 on all 3 chips
[ ] Run Lucas POST on Phi: L₂=3, L₃=4, L₄=7, L₅=11, L₆=18, L₇=29
[ ] Run cross-tile friend/foe handshake
[ ] Test token forwarding: Phi → Euler → Gamma
```

---

## Notes

- DevKit boards purchased: **3** (one per project, for bring-up and comparative testing)
- Chip delivery estimate: **~2026-12-16**
- For cross-die protocol details see [`docs/interconnect.md`](../interconnect.md)
