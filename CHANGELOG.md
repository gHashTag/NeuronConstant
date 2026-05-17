# Changelog — NeuronConstant

All notable changes to this project will be documented in this file.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.1.0] — 2026-05-18

### Added

- Initial NeuronConstant catalog — Trinity tile line (φ-anchor / e-engine / γ-surface)
- `tiles/phi-anchor/` — RTL mirror from tt-trinity-phi (13 modules), testbench, TT metadata
- `tiles/e-engine/` — RTL mirror from tt-trinity-euler, testbench, TT metadata
- `tiles/gamma-surface/` — RTL mirror from tt-trinity-gamma, testbench, TT metadata
- `common/constants/sacred_constants_rom.v` — single source of truth for 75 PhD constants
- `common/constants/crown47_rom.v` — 47 Crown constants
- `common/bus/trinity_d2d_bus.v` — cross-tile D2D bus spec stub
- `common/verification/r_si_1_check.sh` — R-SI-1 zero `*` operator audit script
- `docs/architecture.md` — tile-line architecture overview
- `docs/interconnect.md` — cross-tile 3-wire handshake protocol (from tt-trinity-phi)
- `docs/pinout/phi-anchor.md` — Phi pinout
- `docs/pinout/e-engine.md` — Euler pinout
- `docs/pinout/gamma-surface.md` — Gamma pinout
- `docs/tapeout/tiny-tapeout-sky26b.md` — TTSKY26b submission status
- `docs/tapeout/packaging.md` — DIP-32 DevKit board notes
- `scripts/export_tt_project.sh` — export tile to TT-compatible flat structure
- `scripts/sync_from_trinity.sh` — pull RTL from upstream tt-trinity-* repos

### Notes

- Cross-die anchor: `dot4(1,2,3,4) = 0x47C0` (TG-TRIAD-X Theorem 36.1)
- R-SI-1: zero standalone `*` operators in synthesisable RTL
- TTSKY26b shuttle close: 2026-05-18; chip delivery: ~2026-12-16
- DOI: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)
