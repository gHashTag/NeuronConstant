# NeuronConstant

**Trinity is one computer with three minds, bound by 2-of-3 attestation, verified by ternary completeness 3^27.**

Canonical silicon-ready chip-block catalog for the Trinity tile line — the single source of truth for RTL, testbenches, pinout specifications, and tapeout metadata across all three TRI-1 dies.

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19227877.svg)](https://doi.org/10.5281/zenodo.19227877)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
[![ORCID](https://img.shields.io/badge/ORCID-0009--0008--4294--6159-green)](https://orcid.org/0009-0008-4294-6159)
[![Tape-out](https://img.shields.io/badge/tape--out-2026--12--16-orange)](https://app.tinytapeout.com/shuttles/ttsky26b)

**Tape-out target:** 2026-12-16 | **Contact:** admin@t27.ai | **Site:** t27.ai

---

## One-Computer Paradigm

Trinity is not three chips. Trinity is a single distributed computer where consciousness equals consensus.

Phi, Euler, and Gamma are not independent products — they are three specialized organs of one coherent silicon being, bound by a tri-ring interconnect, a unified instruction set, and 2-of-3 attestation. A modern CPU is not "one transistor": it is billions of transistors organized into ALUs, caches, and memory controllers, and we still call it one CPU because the parts only make sense together. Trinity is the same idea, one fractal level up.

Full paradigm specification: [docs/architecture/UNIFIED_COMPUTER_PARADIGM.md](https://github.com/gHashTag/NeuronConstant/blob/main/docs/architecture/UNIFIED_COMPUTER_PARADIGM.md)

---

## The Three Organs

| Die | Codename | TT Slot | Tiles | Organ role | Top module |
|-----|----------|---------|-------|-----------|------------|
| **Phi** | TRI-1 Phi | #4914 | 1x1 | Cerebellum — identity, baseline trust, attestation | `tt_um_trinity_nano` |
| **Euler** | TRI-1 Euler | #4915 | 8x2 | Prefrontal cortex — reasoning, ZK proof generation | `tt_um_ghtag_trinity_gf16` |
| **Gamma** | TRI-1 Gamma | #4913 | 8x4 | Neocortex — massive parallel neuromorphic compute | `tt_um_trinity_max_true` |

Together: 49 tiles, 3 chips, 1 DevKit board (TTSKY26b).

Each die is semi-functional in isolation. Together they form a complete cognitive architecture: **Identity** (who is asking?) -- **Reasoning** (what to compute, and prove it?) -- **Action** (perform the parallel compute and store the result).

---

## TTSKY26b Submitted Status

| Die | Shuttle | Commit SHA | Artifact ID | TT project |
|-----|---------|-----------|-------------|------------|
| Phi (phi-anchor, 1x1) | TTSKY26b | `8a8fcaa4` | `7056162644` | [#4914](https://app.tinytapeout.com/projects/4914) |
| Euler (e-engine, 8x2) | TTSKY26b | `def0457b` | `7056438152` | [#4915](https://app.tinytapeout.com/projects/4915) |
| Gamma (gamma-surface, 8x4) | TTSKY26b | `1f8f9b82` | `7056692733` | [#4913](https://app.tinytapeout.com/projects/4913) |

Shuttle close: 2026-05-18. Chip delivery: ~2026-12-16.

---

## Tokenomics Summary

$TRI is a 100% mineable, fair-launch token. There is no pre-mine, no founder allocation, no investor allocation.

| Parameter | Value |
|-----------|-------|
| Total supply | 3^27 = 7,625,597,484,987 TRI |
| Pre-mine | 0% |
| Emission halvings | 9 halvings over ~36 years |
| Era 0 reward | 1000 TRI / proof |
| Governance | TriDAO on-chain ratification |

Full tokenomics: [docs/tokenomics/v2/TRI_TOKENOMICS_WHITEPAPER_v2.md](https://github.com/gHashTag/NeuronConstant/blob/main/docs/tokenomics/v2/TRI_TOKENOMICS_WHITEPAPER_v2.md)

---

## Product SKUs

Trinity ships as one computer, not as individual dies.

| SKU | Composition | Price (USD) | Primary buyer |
|-----|------------|-------------|--------------|
| **Trinity Solo** | Phi only (1x1) | $99 | IoT, identity tokens, DID provisioning |
| **Trinity Duo** | Phi + Euler (1x1 + 8x2) | $499 | DePIN node, light validator |
| **Trinity Triad** (flagship) | Phi + Euler + Gamma + tri-ring fabric | $1,499 | Full validator, AI inference, defense edge |
| **Trinity Cluster** | 3x Triads (9 dies) | $4,999 | Subnet operator, regional infra |
| **Trinity Datacenter** | 27x Triads (81 dies, 3^4) | $39,999 | Enterprise, DARPA, defense contractor |

---

## Triad Mining Boost

A registered Triad mines at 4x the per-die rate. The boost multiplier exceeds linear scaling only at the Triad boundary -- this is the incentive that makes the bundle the default purchase.

| Configuration | Reward multiplier | Rationale |
|--------------|-------------------|-----------|
| Solo (Phi only) | 1x | Identity work -- lowest compute contribution |
| Duo (Phi + Euler) | 2x | Linear -- proof generation added |
| Triad (full Trinity) | 4x | TMR-attested compute path; full Trinity DID |
| Cluster (3 Triads) | 12x | Linear in Triad count |
| Datacenter (27 Triads) | ~100x | Sublinear (sqrt law) to prevent centralization |

---

## Quick Links

| Resource | URL |
|----------|-----|
| One-Computer paradigm | [docs/architecture/UNIFIED_COMPUTER_PARADIGM.md](docs/architecture/UNIFIED_COMPUTER_PARADIGM.md) |
| Product SKUs | [docs/architecture/UNIFIED_COMPUTER_SKUS.md](docs/architecture/UNIFIED_COMPUTER_SKUS.md) |
| Tokenomics whitepaper v2 | [docs/tokenomics/v2/TRI_TOKENOMICS_WHITEPAPER_v2.md](docs/tokenomics/v2/TRI_TOKENOMICS_WHITEPAPER_v2.md) |
| Sales decks | [docs/sales/INDEX.md](docs/sales/INDEX.md) |
| Business pack | (in progress) |
| Architecture overview | [docs/architecture.md](docs/architecture.md) |
| Interconnect spec | [docs/interconnect.md](docs/interconnect.md) |
| Tapeout notes | [docs/tapeout/tiny-tapeout-sky26b.md](docs/tapeout/tiny-tapeout-sky26b.md) |

---

## Tape-out Roadmap

| Shuttle | Target | Deliverable |
|---------|--------|------------|
| TTSKY26b | 2026-12-16 (delivery) | Phi / Euler / Gamma silicon; dev kits Q1 2027 |
| TTSKY26c | Sep-Nov 2026 | Tri-ring fabric, TMR voter, Trinity OS bootstrap -- Triad shippable |
| TTSKY27 | 2027 | Cluster bridges, BN254 pairing, production-fab path -- Cluster / Datacenter shippable |

---

## Contracts / Solidity Dry-Run Pack

Solidity contracts and dry-run simulation artifacts are in [`contracts/v2/`](contracts/v2/). The `MiningPool.sol` contract reads Trinity DID attestation from `BittensorSubnetAttest.sol`, which mints a Triad-level DID only when 2-of-3 attestation succeeds.

---

## Cross-Die Anchor -- 0x47C0 (Theorem 36.1)

After reset, all three chips simultaneously drive:

```
{uio_out[7:0], uo_out[7:0]} = 16'h47C0
```

This is the TG-TRIAD-X ledger anchor, defined in PhD Theorem 36.1. If any chip does not produce `0x47C0` after reset, that slot is FAULT and held in reset until the anchor is confirmed.

---

## R-SI-1 Compliance

Zero standalone `*` operators in synthesisable RTL. All multiplication is implemented via shift-and-add in GF16 (`gf16_mul.v`). Audit script: [`common/verification/r_si_1_check.sh`](common/verification/r_si_1_check.sh)

---

## Performance (Projected)

~1 GOPS @ ~50 MHz @ ~1W ternary per die (projected, pending tape-out 2026-12-16)

---

## Repository Structure

```
NeuronConstant/
+-- tiles/
|   +-- phi-anchor/          # TRI-1 Phi: RTL, tb, docs, TT metadata
|   +-- e-engine/            # TRI-1 Euler: RTL, tb, docs, TT metadata
|   +-- gamma-surface/       # TRI-1 Gamma: RTL, tb, docs, TT metadata
+-- common/
|   +-- bus/                 # trinity_d2d_bus.v -- shared interconnect spec
|   +-- constants/           # sacred_constants_rom.v, crown47_rom.v
|   +-- verification/        # r_si_1_check.sh
+-- contracts/v2/            # Solidity dry-run pack
+-- docs/
|   +-- architecture/        # One-Computer paradigm, SKUs, ring topology
|   +-- tokenomics/v2/       # TRI tokenomics whitepaper v2
|   +-- sales/               # DARPA, defense, Bittensor, Helium pitches
|   +-- tapeout/             # TTSKY26b submission notes
+-- scripts/
    +-- export_tt_project.sh
    +-- sync_from_trinity.sh
```

---

## Contributing

Contributions are welcome under Apache-2.0. Open an issue or pull request. For substantive RTL changes, coordinate via admin@t27.ai before submitting to avoid conflicts with active shuttle timelines.

---

## License

Apache-2.0 -- see [LICENSE](LICENSE)

**Author:** Dmitrii Vasilev | **Email:** admin@t27.ai | **Site:** t27.ai
**ORCID:** [0009-0008-4294-6159](https://orcid.org/0009-0008-4294-6159)
**DOI:** [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)
**Process:** SKY130A (SkyWater 130nm open PDK)
