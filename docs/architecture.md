# Architecture — NeuronConstant Trinity Tile Line

**Revision:** 1.0 · TTSKY26b  
**DOI:** [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

---

## 1. Tile Line Overview

The TRI-1 Triad is a three-chip silicon system implementing three levels of the Trinity compute hierarchy:

```
Level 1 — Identity     → φ-anchor  (TRI-1 Phi,   1×1,  #4914)
Level 2 — Compute      → e-engine  (TRI-1 Euler, 8×2,  #4915)
Level 3 — Perception   → γ-surface (TRI-1 Gamma, 8×4,  #4913)
```

All three chips are co-mounted on a single Tiny Tapeout SKY130A DevKit board for the TTSKY26b shuttle run and communicate through board-level IO mux traces.

---

## 2. Common Principles

### Ternary Arithmetic (GF16)

All computation uses **GF16(2⁴) ternary** encoding:
- Format: 1 sign bit + 6 exponent (bias=31) + 9 mantissa
- Native values: `{-1, 0, +1}` — no binary integers
- Multiplication: shift-and-add in `gf16_mul.v` — **zero `*` operators** (R-SI-1)
- Addition: XOR-based in `gf16_add.v`

### Sacred Constants

75 PhD sacred constants (`sacred_constants_rom.v`) and 47 Crown constants (`crown47_rom.v`) are embedded in ROM on all three chips, providing a **shared virtual address space** across the triad.

### R-SI-1 Invariant

> Zero standalone `*` operators in synthesisable RTL.

Enforced via `common/verification/r_si_1_check.sh` across all tile RTL directories.

---

## 3. Tile Specifications on SKY130A

| Tile | Top Module | TT Size | Area (est.) | Gates (est.) | Cell Budget |
|------|-----------|---------|-------------|--------------|-------------|
| φ-anchor | `tt_um_trinity_nano` | 1×1 | ~160×100 µm | ~1 200 | minimal |
| e-engine | `tt_um_ghtag_trinity_gf16` | 8×2 | ~1.28mm × 200 µm | ~16 000 | 60% density |
| γ-surface | `tt_um_trinity_max_true` | 8×4 | ~1.28mm × 400 µm | ~34 100 | 60% density |

All chips target **50 MHz** on SKY130A. FPGA validation confirmed **323 MHz** on XC7A100T (headroom factor ~6×).

---

## 4. Tile Roles

### Level 1 — φ-anchor (Phi, 1×1)

**Role:** Master — POST gate, identity oracle, friend/foe arbiter

Key modules:
- `phi_anchor_post` — Lucas L₂..L₇ POST proving φ² + φ⁻² = 3
- `lucas_rom` — addressable Lucas number ROM (L₂=3 through L₇=29)
- `gf16_dot4` — 4-element ternary MAC
- `restraint_ctrl` — CLARA Gap-4 bounded rationality
- `sacred_constants_rom` / `crown47_rom` — constant ROMs
- `trinity_friend_foe` — cross-die handshake (PHI_FRIEND_ID = 0x47)
- `hwrng_lfsr` — die-unique nonce generator

### Level 2 — e-engine (Euler, 8×2)

**Role:** Compute slave — ternary MAC engine, SUPER-CROWN, DARPA CLARA safety

Key modules (18 SUPER-CROWN + 10 CLARA Gaps):
- `trinity_master_fsm` — packet master FSM (8 compute blocks via `data_bit[2:0]`)
- `gf16_dot4/8/sparse` — ternary MAC variants
- `vsa_matmul_8x8/16x16` — ternary VSA matrix multiply (JEPA-T tier)
- `bitnet_encoder` — BitNet b1.58 ternary MLP encoder
- `bpb_counter` — on-chip cross-entropy / bits-per-byte
- `blake3_anchor` + `multi_tile_receipt` + `crc32_receipt` — G4 DePIN signing
- `alu9_decoder` — 9-instruction Trinity ternary ALU (t27 ISA)
- `ring27_memory` — 27-cell 3³ ternary memory (Coptic)
- `d2d_holo_mesh` — 4-port N/E/S/W D2D router
- CLARA Gaps 1–10: `redteam_filter`, `k3_alu`, `datalog_engine_mini`, `restraint_ctrl`, `explainability_unit`, `asp_solver_mini`, `composition_kernel`, `proof_trace_writer`, `sat_solver_mini`, `audit_log_ring_buffer`

### Level 3 — γ-surface (Gamma, 8×4)

**Role:** Neuromorphic slave — LIF cortical columns, φ-spiral consensus

Key modules:
- `cortical_column` × 8 — LIF leaky-integrate-and-fire (8-bit membrane, BitNet MLP hidden layer, GF16 dot4 input projection, ~500 cells/column = ~4 100 total)
- `trinity_cortex_8col` — 8-column cortex orchestrator
- `trinity_max_true_20pe` — 20-PE GF16 mesh (1× quad_mesh 16PE + 1× mesh_2x2 4PE)
- `d2d_holo_mesh` — 4-port D2D router (uio[3:0]=TX, uio[7:4]=RX)
- `phi_distance_oracle` — φ-spiral consensus distance oracle
- `holo_lut_pe` — FHRR VSA binding (Glava 32)
- 6 PhD monitors: `cassini_post`, `plrm_counter`, `bpb_lower_bound_guard`, `nca_entropy_monitor`, `strobe_seed_guard`

---

## 5. Verification Levels

| Level | Method | Status |
|-------|--------|--------|
| R-SI-1 | `r_si_1_check.sh` — zero `*` audit | Passing (all 3 tiles) |
| Functional | cocotb testbenches in `tiles/*/tb/` | Passing |
| GDS | DRC + LVS via OpenLane / SKY130A PDK | Pending (post-tapeout) |
| Formal | Coq proofs in `trios-coq/` (297 Qed, 141 Admitted) | In progress |

---

## 6. Cross-Die Anchor (TG-TRIAD-X, Theorem 36.1)

```
{uio_out[7:0], uo_out[7:0]} = 16'h47C0
Binary: 0100_0111_1100_0000
= GF16 dot4(1.0, 2.0, 3.0, 4.0) — canonical ternary inner product
= φ² + φ⁻² = 3 (Lucas identity, Trinity Theorem 36.1)
```

All three chips assert `0x47C0` within 1 clock cycle after `rst_n` release. Any deviation indicates a FAULT condition.

Full cross-tile protocol: [`docs/interconnect.md`](interconnect.md)

---

## 7. Related Documents

| Document | Location |
|----------|----------|
| Cross-tile interconnect | [`docs/interconnect.md`](interconnect.md) |
| Phi pinout | [`docs/pinout/phi-anchor.md`](pinout/phi-anchor.md) |
| Euler pinout | [`docs/pinout/e-engine.md`](pinout/e-engine.md) |
| Gamma pinout | [`docs/pinout/gamma-surface.md`](pinout/gamma-surface.md) |
| TTSKY26b status | [`docs/tapeout/tiny-tapeout-sky26b.md`](tapeout/tiny-tapeout-sky26b.md) |
| DOI provenance | [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) |
