# 🔱 NeuronConstant

**Canonical silicon-ready chip-block catalog for the Trinity tile line**  
`φ-anchor · e-engine · γ-surface` — TTSKY26b · Apache-2.0 · ternary · SKY130A · Bazaar Green AI

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19227877.svg)](https://doi.org/10.5281/zenodo.19227877)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
[![ORCID](https://img.shields.io/badge/ORCID-0009--0008--4294--6159-green)](https://orcid.org/0009-0008-4294-6159)

---

## Vision

**NeuronConstant** is the *silicon-ready chip-block catalog* for the Trinity tile line — the single source of truth for RTL, testbenches, pinout specifications, and tapeout metadata across all three TRI-1 tiles.

This repo is **separate** from:

- **[gHashTag/trinity](https://github.com/gHashTag/trinity)** — umbrella research/runtime repo (PhD corpus, Coq proofs, host software, FPGA experiments)
- **[gHashTag/tt-trinity-phi](https://github.com/gHashTag/tt-trinity-phi)** — thin Tiny Tapeout submission mirror (φ-anchor, 1×1, #4914)
- **[gHashTag/tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler)** — thin Tiny Tapeout submission mirror (e-engine, 8×2, #4915)
- **[gHashTag/tt-trinity-gamma](https://github.com/gHashTag/tt-trinity-gamma)** — thin Tiny Tapeout submission mirror (γ-surface, 8×4, #4913)

The tt-trinity-\* repos are **submission mirrors** kept minimal for the Tiny Tapeout GitHub Actions flow. NeuronConstant is where the catalog lives.

---

## Tile Line — TRI-1 Triad

| Tile | Codename | TT Slot | Size | Tiles | Role | Source |
|------|----------|---------|------|-------|------|--------|
| **φ-anchor** | TRI-1 Phi | #4914 | 1×1 | 1 | Master — POST gate, Lucas chain, friend/foe handshake, CLARA Gap-4 | [tiles/phi-anchor/](tiles/phi-anchor/) |
| **e-engine** | TRI-1 Euler | #4915 | 8×2 | 16 | Compute slave — ternary MAC, SUPER-CROWN (18 modules), 10 DARPA CLARA Gaps, D2D holo mesh | [tiles/e-engine/](tiles/e-engine/) |
| **γ-surface** | TRI-1 Gamma | #4913 | 8×4 | 32 | Neuromorphic slave — 8 LIF cortical columns, 20-PE GF16 mesh, φ-distance oracle, D2D holo mesh | [tiles/gamma-surface/](tiles/gamma-surface/) |

**Total: 49 tiles, 3 chips, 1 DevKit board (TTSKY26b)**

---

## Cross-Die Anchor — `0x47C0` (Theorem 36.1)

After reset, **all three chips** simultaneously drive:

```
{uio_out[7:0], uo_out[7:0]} = 16'h47C0   (binary: 0100_0111_1100_0000)
```

This is the **TG-TRIAD-X ledger anchor**, defined in PhD Theorem 36.1:

```
Meaning : GF16 dot4(1.0, 2.0, 3.0, 4.0) — canonical ternary inner product
Identity: φ² + φ⁻² = 3  (Trinity algebraic identity, Lucas chain)
Anchor  : TG-TRIAD-X
Scope   : Cross-die deterministic reset verification
```

If any chip does not produce `0x47C0` after reset, that slot is considered **FAULT** and held in reset until the anchor is confirmed.

Full protocol: [`docs/interconnect.md`](docs/interconnect.md)

---

## R-SI-1 Invariant

> **Zero standalone `*` operators in synthesisable RTL.**

All multiplication is implemented via shift-and-add in GF16 (`gf16_mul.v`). The `*` operator is prohibited in synthesisable `.v` files to guarantee synthesis portability and audit compliance with the DARPA CLARA AI safety framework.

Verification script: [`common/verification/r_si_1_check.sh`](common/verification/r_si_1_check.sh)

```bash
bash common/verification/r_si_1_check.sh tiles/phi-anchor/rtl
bash common/verification/r_si_1_check.sh tiles/e-engine/rtl
bash common/verification/r_si_1_check.sh tiles/gamma-surface/rtl
```

---

## Tiny Tapeout SKY 26b Status

| Item | Value |
|------|-------|
| Shuttle | TTSKY26b (SKY130A) |
| Shuttle close | 2026-05-18 |
| Chip delivery | ~2026-12-16 |
| Projects Assigned | **3/3** |
| Tiles consumed | **49/49** (1 + 16 + 32) |
| DevKit boards purchased | 3 |

Project assignments:
- **#4914** — TRI-1 Phi (φ-anchor, 1×1) → [tiles/phi-anchor/](tiles/phi-anchor/)
- **#4915** — TRI-1 Euler (e-engine, 8×2) → [tiles/e-engine/](tiles/e-engine/)
- **#4913** — TRI-1 Gamma (γ-surface, 8×4) → [tiles/gamma-surface/](tiles/gamma-surface/)

Full tapeout notes: [`docs/tapeout/tiny-tapeout-sky26b.md`](docs/tapeout/tiny-tapeout-sky26b.md)

---

## Repository Structure

```
NeuronConstant/
├── tiles/
│   ├── phi-anchor/          # TRI-1 Phi: RTL, tb, docs, TT metadata
│   ├── e-engine/            # TRI-1 Euler: RTL, tb, docs, TT metadata
│   └── gamma-surface/       # TRI-1 Gamma: RTL, tb, docs, TT metadata
├── common/
│   ├── bus/                 # trinity_d2d_bus.v — shared interconnect spec
│   ├── constants/           # sacred_constants_rom.v, crown47_rom.v (single source)
│   └── verification/        # r_si_1_check.sh
├── docs/
│   ├── architecture.md      # Tile-line architecture overview
│   ├── interconnect.md      # Cross-tile 3-wire protocol
│   ├── pinout/              # Per-tile pinout specifications
│   └── tapeout/             # TTSKY26b submission notes
└── scripts/
    ├── export_tt_project.sh # Export tile to TT-compatible flat structure
    └── sync_from_trinity.sh # Sync RTL from upstream tt-trinity-* repos
```

---

## Quick Start — Export a Tile to Tiny Tapeout Flow

```bash
# Export phi-anchor to a TT-compatible flat structure
bash scripts/export_tt_project.sh phi-anchor /tmp/export/tt-phi-anchor

# Export e-engine
bash scripts/export_tt_project.sh e-engine /tmp/export/tt-e-engine

# Export gamma-surface
bash scripts/export_tt_project.sh gamma-surface /tmp/export/tt-gamma-surface
```

The exported directory follows the standard Tiny Tapeout layout (`src/`, `test/`, `docs/`, `info.yaml`) and can be used directly with the [tt-support-tools](https://github.com/TinyTapeout/tt-support-tools) flow or submitted via `app.tinytapeout.com`.

---

## Common Modules

| Module | Location | Description |
|--------|----------|-------------|
| `sacred_constants_rom.v` | `common/constants/` | 75 PhD sacred constants (single source of truth) |
| `crown47_rom.v` | `common/constants/` | 47 Crown constants |
| `trinity_d2d_bus.v` | `common/bus/` | Cross-tile D2D bus specification |
| `r_si_1_check.sh` | `common/verification/` | R-SI-1 zero-`*` RTL audit script |

---

## Architecture

Three levels of the Trinity compute hierarchy:

1. **Identity** — φ-anchor (Phi): Lucas POST, GF16 dot4 MAC, canonical anchor oracle
2. **Compute** — e-engine (Euler): ternary MAC, VSA, BitNet MLP, DARPA CLARA safety
3. **Perception** — γ-surface (Gamma): LIF cortical columns, neuromorphic spike aggregation

Full architecture: [`docs/architecture.md`](docs/architecture.md)

---

## Relation to Other Repos

```
gHashTag/trinity          ← umbrella research repo (PhD, Coq, host runtime)
       │
       ├── gHashTag/NeuronConstant   ← THIS REPO (canonical hardware catalog)
       │          ├── tiles/phi-anchor/rtl/   ← mirrored in ↓
       │          ├── tiles/e-engine/rtl/     ← mirrored in ↓
       │          └── tiles/gamma-surface/rtl/← mirrored in ↓
       │
       ├── gHashTag/tt-trinity-phi     ← thin TT submission mirror (#4914)
       ├── gHashTag/tt-trinity-euler   ← thin TT submission mirror (#4915)
       └── gHashTag/tt-trinity-gamma   ← thin TT submission mirror (#4913)
```

**NeuronConstant** is the upstream. The `tt-trinity-*` repos are downstream submission mirrors that must not be modified outside of the TT submission flow. Use `scripts/sync_from_trinity.sh` to pull the latest RTL back if upstream changes happen.

---

## License & Provenance

- **License:** Apache-2.0 — see [LICENSE](LICENSE)
- **ORCID:** [0009-0008-4294-6159](https://orcid.org/0009-0008-4294-6159)
- **DOI:** [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)
- **Process:** SKY130A (SkyWater 130nm open PDK)
- **Shuttle:** Tiny Tapeout TTSKY26b, close 2026-05-18
- **Author:** Dmitrii Vasilev (Bazaar Green AI)
