# Common Constants — NeuronConstant

This directory contains the **single source of truth** for all Trinity sacred and Crown constants embedded in the TRI-1 tile line.

---

## Files

| File | Entries | Description |
|------|---------|-------------|
| `sacred_constants_rom.v` | 75 | PhD sacred constants — GF16 ternary encoded values derived from the Trinity mathematical framework (φ, Lucas numbers, GF16 arithmetic identities) |
| `crown47_rom.v` | 47 | Crown47 constants — Trinity Crown constants for cross-die handshake and protocol verification |

---

## sacred_constants_rom.v — 75 PhD Constants

Address range: `0x00`–`0x4A` (75 entries × 8-bit)

Key entries:
- **Address 0x00** — Canonical anchor high byte: `0x47` (from `0x47C0 = dot4(1,2,3,4)`)
- **Address 0x01** — Canonical anchor low byte: `0xC0`
- **Address 0x02** — Lucas L₂ = 3 (φ² + φ⁻² = 3, Trinity identity)
- **Address 0x03** — Lucas L₃ = 4
- **Address 0x04** — Lucas L₄ = 7
- **Address 0x05** — Lucas L₅ = 11
- **Address 0x06** — Lucas L₆ = 18
- **Address 0x07** — Lucas L₇ = 29
- ...additional GF16 constants, φ-PLL ratios, VSA binding constants

All three chips (φ-anchor, e-engine, γ-surface) carry identical copies of this ROM.

---

## crown47_rom.v — 47 Crown Constants

Address range: `0x00`–`0x2E` (47 entries × 8-bit)

Used by:
- `trinity_friend_foe.v` — friend/foe handshake pattern matching
- `trinity_master_fsm.v` — SUPER-CROWN module routing
- `phi_anchor_post.v` — POST verification chain

Key entries:
- `PHI_FRIEND_ID = 0x47` — φ-anchor identification byte
- `EULER_FRIEND_ID = 0xE2` — e-engine signature
- `GAMMA_FRIEND_ID = 0x93` — γ-surface anchor

---

## Usage

These ROMs are the **canonical single source of truth**. They are mirrored into each tile's `rtl/` directory:
- `tiles/phi-anchor/rtl/sacred_constants_rom.v`
- `tiles/e-engine/rtl/sacred_constants_rom.v` (+ `crown47_rom.v`)
- `tiles/gamma-surface/rtl/sacred_constants_rom.v` (+ `crown47_rom.v`)

To update constants: modify the files in `common/constants/` first, then run `scripts/sync_from_trinity.sh` to propagate to tile RTL directories.

---

## Cross-Chip Address Space

All three chips implement the same ROM address space, creating a **shared virtual address space** accessible from the host:

```
Access Phi sacred_constants_rom:
  Set load_mode=0, lucas_idx = desired index → uo+uio = L_n value

Access Gamma crown47_rom:
  Set load_mode=0, uio[7]=1 (crown_mode), ui[6]=addr[6] → Crown ROM value

Access Euler SUPER-CROWN modules:
  Euler trinity_master_fsm addresses ROM internally via load_mode=1 packet path
```

The canonical anchor `0x47C0` at address 0 is the single point of synchrony across all three chips.

---

## DOI

[10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) — Trinity Stack provenance (includes complete constant derivation)
