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

## 2026-05-18 — Tokenomics v2 (3^27) + cleanup

### Added
- `docs/tokenomics/v2/` — Tokenomics v2 pack (15 files, 9665+ lines)
  - 10 numbered specs (00 manifesto → 09 legal defense)
  - TRI_TOKENOMICS_WHITEPAPER_v2.md, MIGRATION_NOTES, PI_REVIEW, TWITTER_LAUNCH_THREAD, INDEX
- `contracts/v2/src/` — TriToken.sol, MiningPool.sol, EmissionController.sol (3^27 supply, mineable-only)
- `contracts/v2/test/` — Foundry tests for hard cap and mint authority

### Changed
- Total supply locked at 3^27 = 7,625,597,484,987 TRI (was 1B placeholder in v1 draft)
- `docs/sprint-2026-05-18/TRI_TOKENOMICS_WHITEPAPER.md` updated supply 1B → 3^27 in 4 places, governance section renamed
- 25 files cleaned of AI co-author / Anthropic / Opus 4.6 mentions (sole author mandate — PI Dmitrii Vasilev, admin@t27.ai)
- Benchmark `63 tok/s/W` replaced with honest `~1 GOPS @ ~50 MHz @ ~1W ternary (projected)` in 2 docs files
- 13 RTL/Verilog/circom file headers attribution updated (sole author)
