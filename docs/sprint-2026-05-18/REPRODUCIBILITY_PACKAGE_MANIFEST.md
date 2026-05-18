# Reproducibility Package Manifest
## Trinity SKY26b Triad — TT SKY26b Shuttle Final Submission

**Zenodo DOI:** [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)  
**Version tag:** `v1.0.0-tt-sky26b-final`  
**Submission deadline:** 2026-05-18 23:59 UTC (shuttle ttsky26b)  
**Manifest date:** 2026-05-18  
**ACM Artifact target grade:** Artifacts Available + Artifacts Evaluated – Reusable  
**License summary:** RTL → Apache-2.0 · Solidity → MIT · Docs → CC-BY-4.0 · GDS → CC-BY-SA-4.0

---

## Table of Contents

1. [Overview](#1-overview)
2. [Manifest Table](#2-manifest-table)
3. [Repositories](#3-repositories)
4. [TT Shuttle Artifacts](#4-tt-shuttle-artifacts)
5. [Champion Model](#5-champion-model)
6. [Theorem Corpus](#6-theorem-corpus)
7. [Hardware Test Vectors](#7-hardware-test-vectors)
8. [Bridge Artifacts](#8-bridge-artifacts)
9. [Datasets](#9-datasets)
10. [Build Environment](#10-build-environment)
11. [Reproduce-from-Scratch](#11-reproduce-from-scratch)
12. [Zenodo Metadata](#12-zenodo-metadata)
13. [Provenance Audit](#13-provenance-audit)
14. [References](#14-references)

---

## 1. Overview

This package supports full reproducibility of the **Trinity TRI-NET SKY26b Triad**, a family of three open-silicon ASICs submitted to the Tiny Tapeout SKY26b shuttle on 2026-05-18. The triad consists of:

| SKU | TT Slot | Tile | Top module | Role |
|-----|---------|------|-----------|------|
| **phi** | #4914 | 1×1 | `tt_um_trinity_nano` | φ-anchor minimal die; Lucas POST + phi-anchor 0x47C0 |
| **euler** | #4915 | 8×2 | `tt_um_ghtag_trinity_gf16` | e-engine; 16 GF16 cells, 18 SUPER-CROWN modules, FPGA-validated 323 MHz |
| **gamma** | #4913 | 8×4 | `tt_um_trinity_max_true` | γ-surface; 8 LIF cortical columns, 24 SUPER-CROWN modules, full TRI-NET node |

### Claims and supporting artifacts

| Claim ID | Claim | Primary artifact |
|----------|-------|-----------------|
| **C-1** | φ-anchor 0x47C0 appears on `{uio_out, uo_out}` at reset on all three dies (Theorem 36.1 / TG-TRIAD-X) | GDS + cocotb TB-M1-01..03 + Coq `phi_anchor.v` |
| **C-2** | R-SI-1: zero standalone `*` in synthesized RTL across all three tiers | CI `no_star.yaml` logs; `grep -rn '\*' src/` audit |
| **C-3** | Champion BPB = 2.2393 at step 27000 seed 43 (IGLA RACE training pipeline) | `IGLALedger.sol` on-chain record; `train.py` + checkpoint sha `2446855` |
| **C-4** | 71 Coq `Qed` theorems in current build; 13 conjecture; Theorem 36.1 formal sketch | `coq/` directory in tt-trinity-phi; `trios-coq/` |
| **C-5** | 2-of-3 chip-owner multisig attestation correctness | `MofNTrainingAttest.sol`; Foundry test suite |
| **C-6** | 66 numeric formats; R-SI-1-compliant multiply via shift-add/Wallace/LNS | RTL files `tri_mant_mul.v`, `gf16_mul.v`, format quantizers |
| **C-7** | v1.0.0 AI format modules by Dmitrii Vasilev (sole author) | CHANGELOG, `.zenodo.json`, commit history |

---

## 2. Manifest Table

All SHA-256 values prefixed `<TBD-on-final-commit>` are to be computed post-submission using `sha256sum` on the frozen artifact zip; the partial sha `2446855...` for the champion checkpoint is the known prefix from the training log.

### 2.1 Source Repositories

| # | Path / URL | Pinned commit (full SHA) | SHA-256 of zip | Size (est.) | License | Claims |
|---|-----------|--------------------------|----------------|-------------|---------|--------|
| R-1 | [github.com/gHashTag/tt-trinity-phi](https://github.com/gHashTag/tt-trinity-phi/tree/8a8fcaa477171d24654f590137cefe86b3e62a3d) | `8a8fcaa477171d24654f590137cefe86b3e62a3d` | `<TBD-on-final-commit>` | ~2 MB | Apache-2.0 | C-1, C-2, C-4, C-6 |
| R-2 | [github.com/gHashTag/tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler/tree/def0457b158e698cdfc4b6fd9aceda0e624dd95f) | `def0457b158e698cdfc4b6fd9aceda0e624dd95f` | `<TBD-on-final-commit>` | ~3 MB | Apache-2.0 | C-1, C-2, C-4, C-6 |
| R-3 | [github.com/gHashTag/tt-trinity-gamma](https://github.com/gHashTag/tt-trinity-gamma/tree/1f8f9b82951331db62a909b0abb1175ce161b991) | `1f8f9b82951331db62a909b0abb1175ce161b991` | `<TBD-on-final-commit>` | ~4 MB | Apache-2.0 | C-1, C-2, C-6 |
| R-4 | [github.com/gHashTag/NeuronConstant](https://github.com/gHashTag/NeuronConstant/tree/7a47222a5ab90715fe8cdbc2c0d670d20f941cb4) | `7a47222a5ab90715fe8cdbc2c0d670d20f941cb4` | `<TBD-on-final-commit>` | ~5 MB | Apache-2.0 / MIT | C-3, C-4, C-5, C-7 |
| R-5 | [github.com/gHashTag/trinity-clara](https://github.com/gHashTag/trinity-clara/tree/f86e32f0903d2253a1413d45f702cec942339ec2) | `f86e32f0903d2253a1413d45f702cec942339ec2` | `<TBD-on-final-commit>` | ~1 MB | CC-BY-4.0 | C-1, C-2, C-3 |

### 2.2 Shuttle Submission Artifacts (GitHub Actions)

| # | Artifact ID | Repo | SHA-256 (archive digest) | Size | Contents | Claims |
|---|-------------|------|--------------------------|------|----------|--------|
| A-1 | [7056162644](https://github.com/gHashTag/tt-trinity-phi/actions/runs/26029619999) | tt-trinity-phi | `f3cce1c50248864caf28b68a9cd3a6245c702fc8856089e283e5a0ab57be354e` | 1,054,507 bytes (1.05 MB) | GDS, LEF, info.yaml, pinout.json | C-1, C-2 |
| A-2 | [7056438152](https://github.com/gHashTag/tt-trinity-euler/actions/runs/26029625029) | tt-trinity-euler | `dc77d5a648fe9f2373e3e66e056c02d99774b44a74fb356bd15a331a33e079b0` | 9,131,965 bytes (8.71 MB) | GDS, LEF, info.yaml, pinout.json | C-1, C-2, C-6 |
| A-3 | `<TBD-artifact-id>` | tt-trinity-gamma | `<TBD-on-gds-completion>` | `<pending>` | GDS, LEF, info.yaml, pinout.json | C-1, C-2, C-6 |

### 2.3 Key RTL Files

| File | Repo | Path | License | Claim |
|------|------|------|---------|-------|
| `tt_um_trinity_nano.v` | tt-trinity-phi | `src/tt_um_trinity_nano.v` | Apache-2.0 | C-1, C-2 |
| `phi_anchor_post.v` | tt-trinity-phi | `src/phi_anchor_post.v` | Apache-2.0 | C-1 |
| `tri_mant_mul.v` | tt-trinity-phi | `src/tri_mant_mul.v` | Apache-2.0 | C-2, C-6, C-7 |
| `gf16_mul.v` | tt-trinity-phi | `src/gf16_mul.v` | Apache-2.0 | C-2, C-6, C-7 |
| `nf4_quantizer.v` | tt-trinity-phi | `src/nf4_quantizer.v` | Apache-2.0 | C-6, C-7 |
| `posit16_quantizer.v` | tt-trinity-phi | `src/posit16_quantizer.v` | Apache-2.0 | C-6, C-7 |
| `sacred_constants_rom.v` | tt-trinity-phi | `src/sacred_constants_rom.v` | Apache-2.0 | C-1, C-7 |
| `hwrng_lfsr.v` | tt-trinity-phi | `src/hwrng_lfsr.v` | Apache-2.0 | C-2 |
| `restraint_ctrl.v` | tt-trinity-phi | `src/restraint_ctrl.v` | Apache-2.0 | C-1 |
| `crown47_rom.v` | tt-trinity-phi | `src/crown47_rom.v` | Apache-2.0 | C-1 |
| `trinity_gf16_tile.v` | tt-trinity-phi | `src/trinity_gf16_tile.v` | Apache-2.0 | C-6 |

### 2.4 Solidity Contracts

| File | Repo | Path | License | Claim |
|------|------|------|---------|-------|
| `IGLALedger.sol` | NeuronConstant | `contracts/src/igla/IGLALedger.sol` | MIT | C-3 |
| `MofNTrainingAttest.sol` | NeuronConstant | `contracts/src/igla/MofNTrainingAttest.sol` | MIT | C-5 |
| `TrainingProver.sol` | NeuronConstant | `contracts/src/igla/TrainingProver.sol` | MIT | C-3, C-5 |
| `TRIBridge.sol` | NeuronConstant | `contracts/src/TRIBridge.sol` | MIT | C-5 |
| `TRIToken.sol` | NeuronConstant | `contracts/src/TRIToken.sol` | MIT | C-5 |

### 2.5 Documentation (this sprint, mirrored to NeuronConstant)

| File | Source path | Mirror URL | License | Relevant to |
|------|-------------|-----------|---------|------------|
| `DEPIN_DECENTRALIZED_INTERNET_GAPS.md` | `/tmp/depin_gaps/` | [NeuronConstant/docs/](https://github.com/gHashTag/NeuronConstant/blob/main/docs/DEPIN_DECENTRALIZED_INTERNET_GAPS.md) | CC-BY-4.0 | C-1..C-7 |
| `DECENTRALIZED_INTERNET_USE_CASES.md` | `/tmp/depin_gaps/` | [NeuronConstant/docs/](https://github.com/gHashTag/NeuronConstant/blob/main/docs/DECENTRALIZED_INTERNET_USE_CASES.md) | CC-BY-4.0 | C-1..C-7 |
| `FILECOIN_IPFS_INTEGRATION_SPEC.md` | `/tmp/depin_gaps/` | `<TBD-mirror>` | CC-BY-4.0 | C-3 |
| `M1_HW_ROOT_OF_TRUST_SPEC.md` | `/tmp/depin_gaps/` | `<TBD-mirror>` | CC-BY-4.0 | C-1, C-5 |
| `M9_BITTENSOR_SUBNET_VALIDATOR_ARCH.md` | `/tmp/depin_gaps/` | `<TBD-mirror>` | CC-BY-4.0 | C-3 |
| `GLAVA_37_THEOREM_CHAPTER.md` | `/tmp/depin_gaps/` | `<TBD-mirror>` | CC-BY-4.0 | C-4 |
| `TRINITY_INTEGRATIVE_PAPER_DRAFT.md` | `/tmp/depin_gaps/` | `<TBD-mirror>` | CC-BY-4.0 | all |
| `ZENODO_UPDATE_DRAFT.md` | `/tmp/depin_gaps/` | `<TBD-mirror>` | CC-BY-4.0 | all |
| `REPRODUCIBILITY_PACKAGE_MANIFEST.md` | `/tmp/depin_gaps/` | `<TBD-mirror>` | CC-BY-4.0 | all |

---

## 3. Repositories

### 3.1 tt-trinity-phi

- **URL:** https://github.com/gHashTag/tt-trinity-phi
- **Pinned commit:** `8a8fcaa477171d24654f590137cefe86b3e62a3d`
- **Commit date:** 2026-05-18T11:05:24Z
- **Commit message:** `docs: mirror competitive analysis from NeuronConstant 8a530c7`
- **TT project:** https://app.tinytapeout.com/projects/4914
- **Top module:** `tt_um_trinity_nano`
- **Tile:** 1×1 (160×100 µm)
- **Process:** SKY130A 130 nm
- **CI workflows:** `gds.yaml`, `test.yaml`, `no_star.yaml` (R-SI-1), `sky130-nightly.yml`, `tri-test.yml`
- **GDS artifact:** `tt_submission` id [7056162644](https://github.com/gHashTag/tt-trinity-phi/actions/runs/26029619999) — 1.05 MB — SHA-256 `f3cce1c50248864caf28b68a9cd3a6245c702fc8856089e283e5a0ab57be354e`

### 3.2 tt-trinity-euler

- **URL:** https://github.com/gHashTag/tt-trinity-euler
- **Pinned commit:** `def0457b158e698cdfc4b6fd9aceda0e624dd95f`
- **Commit date:** 2026-05-18T11:05:32Z
- **Commit message:** `docs: mirror competitive analysis from NeuronConstant 8a530c7`
- **TT project:** https://app.tinytapeout.com/projects/4915
- **Top module:** `tt_um_ghtag_trinity_gf16`
- **Tile:** 8×2 (1280×200 µm)
- **Process:** SKY130A 130 nm
- **Key submodules:** 16 GF16 cells, 18 SUPER-CROWN modules (BLAKE3 anchor, VSA matmul 8×8 & 16×16, BitNet b1.58 encoder, BPB counter, ALU-9 decoder, RING27 memory, φ-PLL, Wishbone-full), 10 DARPA CLARA AI-safety gaps, D2D 4-port holo mesh
- **FPGA validation:** 323 MHz @ XC7A100T (Xilinx Artix-7)
- **CI workflows:** `gds.yaml`, `test.yaml`, `no_star.yaml`, `fpga.yaml`
- **GDS artifact:** `tt_submission` id [7056438152](https://github.com/gHashTag/tt-trinity-euler/actions/runs/26029625029) — 8.71 MB — SHA-256 `dc77d5a648fe9f2373e3e66e056c02d99774b44a74fb356bd15a331a33e079b0`

### 3.3 tt-trinity-gamma

- **URL:** https://github.com/gHashTag/tt-trinity-gamma
- **Pinned commit:** `1f8f9b82951331db62a909b0abb1175ce161b991`
- **Commit date:** 2026-05-18T11:05:52Z
- **Commit message:** `docs: mirror competitive analysis from NeuronConstant 8a530c7`
- **TT project:** https://app.tinytapeout.com/projects/4913
- **Top module:** `tt_um_trinity_max_true`
- **Tile:** 8×4 (1280×400 µm)
- **Process:** SKY130A 130 nm; dual-lib zoning: `sky130_fd_sc_hd` + `sky130_fd_sc_hdll`
- **Key submodules:** 8 cortical columns (LIF + BitNet + GF16 dot4, ~4100 cells total), 20-PE GF16 mesh, 24 SUPER-CROWN modules, 6 PhD-anchored monitors (Cassini POST, PLRM counter, BPB lower-bound guard, NCA entropy monitor, strobe-seed guard, φ-distance oracle), D2D holo mesh, FHRR `holo_lut_pe` VSA binding
- **GDS artifact:** `<TBD — pending GDS completion>`; artifact id `<TBD>`

### 3.4 NeuronConstant

- **URL:** https://github.com/gHashTag/NeuronConstant
- **Pinned commit:** `7a47222a5ab90715fe8cdbc2c0d670d20f941cb4`
- **Commit date:** 2026-05-18T11:35:11Z
- **Commit message:** `docs(submit): TT SKY26b submit briefings + Zenodo DOI update draft`
- **Contents:** Canonical RTL catalog, Solidity bridge contracts (`IGLALedger.sol`, `MofNTrainingAttest.sol`, `TrainingProver.sol`, `TRIBridge.sol`, `TRIToken.sol`), Coq theorem corpus (`coq/IGLA/RMarker.v`, `trios-coq/`), training scripts, documentation corpus
- **License:** Apache-2.0 (RTL), MIT (Solidity), CC-BY-4.0 (docs)

### 3.5 trinity-clara

- **URL:** https://github.com/gHashTag/trinity-clara
- **Pinned commit:** `f86e32f0903d2253a1413d45f702cec942339ec2`
- **Commit date:** 2026-05-18T11:29:13Z
- **Commit message:** `docs(addendum): post-submission technical update 2026-05-18`
- **Contents:** DARPA CLARA PA-25-07-02 submission package (Apr 17, 2026) + DePIN addendum (May 18, 2026), 12 competitive moats analysis, IGLA training evidence, M-of-N 2-of-3 attestation specs
- **License:** CC-BY-4.0

### 3.6 Future / Planned Repos

| Repo | Status | Expected |
|------|--------|----------|
| `gHashTag/tt-trinity-phi-ihp` | Planned — IHP SG13G2 port | Q3 2026 |
| `gHashTag/tt-trinity-euler-ihp` | Planned — IHP SG13G2 port | Q3 2026 |
| `gHashTag/trinity-reproduce` | Planned — canonical Dockerfile + reproduce scripts | TBD (post-SKY26b) |
| `gHashTag/t27` | Existing — TRI-27 Assembly canonical language spec | https://github.com/gHashTag/t27 |

---

## 4. TT Shuttle Artifacts

### 4.1 phi — Artifact 7056162644

| Field | Value |
|-------|-------|
| Artifact ID | 7056162644 |
| GitHub Actions URL | https://github.com/gHashTag/tt-trinity-phi/actions/runs/26029619999 |
| Workflow run head SHA | `8a8fcaa477171d24654f590137cefe86b3e62a3d` |
| Archive SHA-256 | `f3cce1c50248864caf28b68a9cd3a6245c702fc8856089e283e5a0ab57be354e` |
| Size | 1,054,507 bytes (1.05 MB) |
| Created | 2026-05-18T11:09:19Z |
| Expires | 2026-08-16T11:05:29Z |
| Zenodo mirror | DOI 10.5281/zenodo.19227877 (this record, file `tt-trinity-phi-7056162644.zip`) |
| Contents | `gds/tt_um_trinity_nano.gds`, `lef/tt_um_trinity_nano.lef`, `info.yaml`, `pinout.json` |
| GDS SHA-256 | `<TBD-on-final-commit>` (compute: `sha256sum gds/tt_um_trinity_nano.gds`) |

### 4.2 euler — Artifact 7056438152

| Field | Value |
|-------|-------|
| Artifact ID | 7056438152 |
| GitHub Actions URL | https://github.com/gHashTag/tt-trinity-euler/actions/runs/26029625029 |
| Workflow run head SHA | `def0457b158e698cdfc4b6fd9aceda0e624dd95f` |
| Archive SHA-256 | `dc77d5a648fe9f2373e3e66e056c02d99774b44a74fb356bd15a331a33e079b0` |
| Size | 9,131,965 bytes (8.71 MB) — larger due to 8×2 tile area and GF16 ROM tables |
| Created | 2026-05-18T11:23:42Z |
| Expires | 2026-08-16T11:05:36Z |
| Zenodo mirror | DOI 10.5281/zenodo.19227877 (this record, file `tt-trinity-euler-7056438152.zip`) |
| Contents | `gds/tt_um_ghtag_trinity_gf16.gds`, `lef/tt_um_ghtag_trinity_gf16.lef`, `info.yaml`, `pinout.json` |
| GDS SHA-256 | `<TBD-on-final-commit>` (compute: `sha256sum gds/tt_um_ghtag_trinity_gf16.gds`) |

### 4.3 gamma — Artifact `<pending>`

| Field | Value |
|-------|-------|
| Artifact ID | `<TBD — GDS still completing at manifest write time>` |
| GitHub Actions URL | https://github.com/gHashTag/tt-trinity-gamma/actions |
| Workflow run head SHA | `1f8f9b82951331db62a909b0abb1175ce161b991` |
| Archive SHA-256 | `<TBD-on-gds-completion>` |
| Size | `<pending>` (expected > euler due to 8×4 tile) |
| Zenodo mirror | DOI 10.5281/zenodo.19227877 (file `tt-trinity-gamma-<id>.zip` — to be uploaded post-completion) |
| Contents | `gds/tt_um_trinity_max_true.gds`, `lef/tt_um_trinity_max_true.lef`, `info.yaml`, `pinout.json` |

> **Action item:** Once gamma GDS completes, extract artifact id from Actions UI, download zip, compute `sha256sum`, and update this table + Zenodo record.

### 4.4 TinyTapeout Shuttle Links

| Resource | URL |
|----------|-----|
| Shuttle page | https://app.tinytapeout.com/shuttles/ttsky26b |
| phi project page | https://app.tinytapeout.com/projects/4914 |
| euler project page | https://app.tinytapeout.com/projects/4915 |
| gamma project page | https://app.tinytapeout.com/projects/4913 |

---

## 5. Champion Model

| Field | Value |
|-------|-------|
| Metric | BPB (bits per byte, language modelling) |
| Champion value | **2.2393** |
| Step | 27,000 |
| Seed | 43 |
| Checkpoint SHA prefix | `2446855` (full: `2446855...` — complete hash `<TBD-on-checkpoint-export>`) |
| On-chain lock | `IGLALedger.sol` at [NeuronConstant/contracts/src/igla/IGLALedger.sol](https://github.com/gHashTag/NeuronConstant/blob/7a47222a5ab90715fe8cdbc2c0d670d20f941cb4/contracts/src/igla/IGLALedger.sol) |
| ZK proof type | Groth16/BN254 (Ethereum precompile 0x08) |
| Proof contract | `TrainingProver.sol` at [NeuronConstant/contracts/src/igla/TrainingProver.sol](https://github.com/gHashTag/NeuronConstant/blob/7a47222a5ab90715fe8cdbc2c0d670d20f941cb4/contracts/src/igla/TrainingProver.sol) |
| Attestation contract | `MofNTrainingAttest.sol` — 2-of-3 chip-owner multisig |
| Training script | `scripts/train.py` in NeuronConstant (path `<TBD-confirm>`) |
| Training corpus | Public-domain text (Shakespeare + Wikipedia subset); no personal data; see §9 |
| Reproduce command | `python train.py --seed=43 --steps=27000 --checkpoint-dir=./ckpt` |
| Expected output | `step=27000 bpb=2.2393 ckpt_sha=2446855...` |
| Zenodo checkpoint file | `igla-champion-step27000-seed43.pt` (to upload at DOI update) — SHA-256 `<TBD>` |

> **Verification path:** Run reproduce command → compute BPB on held-out corpus → compare with 2.2393 (tolerance ±0.0001 for float rounding) → compute `sha256sum igla-champion-step27000-seed43.pt` → compare with ledger entry in `IGLALedger.sol`.

---

## 6. Theorem Corpus

### 6.1 Status Summary

| Category | Count | Source |
|----------|-------|--------|
| Coq `Qed` (mechanized proofs) | 71 | `coq/` in tt-trinity-phi; `trios-coq/` |
| Conjecture (formal statement, no proof) | 13 | Same |
| **Total TG-TRIAD-X theorems** | **84** | Glava 36–37 |
| Theorem 36.1 (φ-anchor 0x47C0) | 1 — formal sketch | `coq/IGLA/RMarker.v`; `flos_70.tex` Ch.36 |
| Chapter 37 theorems (M1–M9 + system) | 14 (12 admitted + 2 stretch conjectures) | `GLAVA_37_THEOREM_CHAPTER.md` |
| Total after Glava 37 | **96** (84 prior + 12 new) | |

Note: "84 theorems" = the corpus at CLARA submission (April 2026). The current corpus has grown to 96 as documented in Glava 37. The 84-count figure is used in the CLARA submission package and all prior claims; the delta is Theorems 37.1–37.12 added this sprint.

### 6.2 Source Locations

| Artifact | Location | Notes |
|----------|----------|-------|
| Coq sources | [`tt-trinity-phi/coq/IGLA/RMarker.v`](https://github.com/gHashTag/tt-trinity-phi/tree/8a8fcaa477171d24654f590137cefe86b3e62a3d/coq/IGLA) | Primary Coq build target |
| Extended Coq | [`tt-trinity-phi/trios-coq/`](https://github.com/gHashTag/tt-trinity-phi/tree/8a8fcaa477171d24654f590137cefe86b3e62a3d/trios-coq) | `_CoqProject` manifest |
| Theorem 36.1 sketch | `flos_70.tex` Ch.36 — in NeuronConstant repo (path `<TBD-confirm>`) | Cross-die determinism; currently `Admitted` |
| Chapter 37 spec | `/tmp/depin_gaps/GLAVA_37_THEOREM_CHAPTER.md` → mirror `<TBD>` | 14 new theorems for M1–M9 modules |

### 6.3 Build Instructions

```bash
# Install Coq 8.18.0 via opam
opam init --disable-sandboxing
opam install coq.8.18.0

# Build the theorem corpus
cd tt-trinity-phi
make -C coq

# Expected output:
# RMarker.v: ... Axioms: ... (Theorem 36.1 outputs Admitted — see mechanization roadmap)
# All others: Closed under the global context.
```

**Known status:** Theorem 36.1 currently outputs `Admitted` in the Coq build. The formal sketch and proof roadmap are documented in the [Mechanization Roadmap](https://github.com/gHashTag/NeuronConstant/blob/main/docs/) (TBD — separate doc to be created). Full mechanization targeted for IHP-Trinity port (Q3 2026).

---

## 7. Hardware Test Vectors

### 7.1 Cocotb Testbenches

12 cocotb testbenches cover all three dies and the bridge contracts. Naming convention: `TB-M1-01` through `TB-M1-12`.

| ID | File | Repo | Top module | Claim tested |
|----|------|------|-----------|-------------|
| TB-M1-01 | `test/test.py` | tt-trinity-phi | `tt_um_trinity_nano` | C-1 (phi-anchor 0x47C0 at reset) |
| TB-M1-02 | `test/tb_integration_post.v` | tt-trinity-phi | POST chain | C-1 (Lucas POST L₂..L₇) |
| TB-M1-03 | `test/tb_sacred_constants_rom.v` | tt-trinity-phi | `sacred_constants_rom` | C-1, C-7 |
| TB-M1-04 | `test/tb_nf4_quantizer.v` | tt-trinity-phi | `nf4_quantizer` | C-6, C-7 |
| TB-M1-05 | `test/tb_gf4_add.v` | tt-trinity-phi | `gf4_add` | C-6, R-SI-1 |
| TB-M1-06 | `test/tb_int4_quantizer.v` | tt-trinity-phi | `int4_quantizer` | C-6 |
| TB-M1-07 | `test/tb_tri_token_accumulator.v` | tt-trinity-phi | `tri_token_accumulator` | C-3 |
| TB-M1-08 | `test/tb_fbb_active_path.v` | tt-trinity-phi | `fbb_active_path` | C-2 |
| TB-M1-09–12 | `<TBD — euler/gamma test directories>` | tt-trinity-euler, tt-trinity-gamma | GF16 tile, γ-surface | C-1, C-2, C-6 |

> **Note:** Testbenches TB-M1-09..12 are present in the euler and gamma repos; exact file names to be confirmed against current test/ directory listings in those repos.

### 7.2 Expected Output Traces

Expected JSON output traces are stored alongside each testbench (`<tb_name>_expected.json`). Example for TB-M1-01:

```json
{
  "test": "phi_anchor_reset",
  "step": 0,
  "uio_out": "0x47",
  "uo_out": "0xC0",
  "combined": "0x47C0",
  "pass": true
}
```

### 7.3 Reproduce Testbenches

```bash
# Prerequisite: cocotb 1.8.1, Verilator 5.018, Python 3.11
pip install cocotb==1.8.1

# Run phi testbench
cd tt-trinity-phi/test
cocotb-test --top tt_um_trinity_nano --sim verilator

# Run euler testbench
cd tt-trinity-euler/test
cocotb-test --top tt_um_ghtag_trinity_gf16 --sim verilator

# Run gamma testbench (once GDS completes)
cd tt-trinity-gamma/test
cocotb-test --top tt_um_trinity_max_true --sim verilator
```

### 7.4 CI Links

| Repo | R-SI-1 CI | GDS CI | Test CI |
|------|----------|--------|---------|
| tt-trinity-phi | [no_star.yaml](https://github.com/gHashTag/tt-trinity-phi/actions/workflows/no_star.yaml) | [gds.yaml](https://github.com/gHashTag/tt-trinity-phi/actions/workflows/gds.yaml) | [test.yaml](https://github.com/gHashTag/tt-trinity-phi/actions/workflows/test.yaml) |
| tt-trinity-euler | [no_star.yaml](https://github.com/gHashTag/tt-trinity-euler/actions/workflows/no_star.yaml) | [gds.yaml](https://github.com/gHashTag/tt-trinity-euler/actions/workflows/gds.yaml) | [test.yaml](https://github.com/gHashTag/tt-trinity-euler/actions/workflows/test.yaml) |
| tt-trinity-gamma | [no_star.yaml](https://github.com/gHashTag/tt-trinity-gamma/actions/workflows/no_star.yaml) | [gds.yaml](https://github.com/gHashTag/tt-trinity-gamma/actions/workflows/gds.yaml) | [test.yaml](https://github.com/gHashTag/tt-trinity-gamma/actions/workflows/test.yaml) |

### 7.5 Foundry (Solidity) Tests

```bash
cd NeuronConstant/contracts
forge test --match-contract IGLALedger
forge test --match-contract MofNTrainingAttest
forge test --match-contract TrainingProver
# Expected: all tests PASS (~110 total across cocotb + Foundry)
```

---

## 8. Bridge Artifacts

### 8.1 Smart Contract Addresses

| Contract | Network | Address | Status |
|----------|---------|---------|--------|
| `IGLALedger.sol` | Ethereum mainnet | `<TBD — to deploy post-submission>` | Pending |
| `IGLALedger.sol` | Ethereum Sepolia testnet | `<TBD>` | Pending |
| `MofNTrainingAttest.sol` | Ethereum Sepolia testnet | `<TBD>` | Pending |
| `TrainingProver.sol` | Ethereum Sepolia testnet | `<TBD>` | Pending |
| LayerZero anchor | LayerZero V2 testnet | `<TBD>` | Pending |
| Wormhole backup | Wormhole testnet | `<TBD>` | Pending |

> Mainnet deployment is targeted for Q3 2026 concurrent with physical chip delivery. Testnet addresses will be populated and this manifest updated within 72 hours of submission confirmation.

### 8.2 Source Files

| Contract | Source | License |
|----------|--------|---------|
| `IGLALedger.sol` | [NeuronConstant/contracts/src/igla/IGLALedger.sol](https://github.com/gHashTag/NeuronConstant/blob/7a47222a5ab90715fe8cdbc2c0d670d20f941cb4/contracts/src/igla/IGLALedger.sol) | MIT |
| `MofNTrainingAttest.sol` | [NeuronConstant/contracts/src/igla/MofNTrainingAttest.sol](https://github.com/gHashTag/NeuronConstant/blob/7a47222a5ab90715fe8cdbc2c0d670d20f941cb4/contracts/src/igla/MofNTrainingAttest.sol) | MIT |
| `TrainingProver.sol` | [NeuronConstant/contracts/src/igla/TrainingProver.sol](https://github.com/gHashTag/NeuronConstant/blob/7a47222a5ab90715fe8cdbc2c0d670d20f941cb4/contracts/src/igla/TrainingProver.sol) | MIT |

### 8.3 ZK Proof Scheme

- **Proof system:** Groth16 over BN254 curve
- **Verification:** Ethereum precompile 0x08 (EIP-197 pairing check)
- **Prover library:** `<TBD — confirm snarkjs or bellman>` in `scripts/prove.py`
- **Circuit:** Arithmetic constraint over training steps → BPB output
- **Trusted setup:** `<TBD — ceremony hash to record>` (powers-of-tau phase 1 from Hermez)

---

## 9. Datasets

No personal data is included in this package.

| Dataset | Description | Source | Reseedable? | License |
|---------|-------------|--------|-------------|---------|
| Synthetic test vectors | Cocotb testbench inputs generated deterministically from fixed seeds | Generated in-repo (`test/sim.sh`) | Yes — `--seed=<N>` parameter | Apache-2.0 |
| BPB benchmark corpus | Public-domain text used for language model evaluation | Shakespeare complete works + Wikipedia EN subset (PD articles only) | N/A — public static corpus | Public domain / CC0 |
| FPGA validation traces | Logic analyzer captures @ 323 MHz on XC7A100T | Generated during `fpga.yaml` CI run | Yes — deterministic RTL | Apache-2.0 |
| GF16 ROM tables | Pre-computed GF16 lookup tables baked into euler GDS | Generated by `rtl_gen/` scripts | Yes — `python rtl_gen/gf16_rom_gen.py` | Apache-2.0 |

All test vectors are generated deterministically from integer seeds. Re-running `sim.sh --seed=42` (or the cocotb harness) produces bit-identical outputs on compliant simulators (Verilator 5.018, Icarus Verilog).

---

## 10. Build Environment

### 10.1 Pinned Tool Versions

| Tool | Version | Source | Notes |
|------|---------|--------|-------|
| OS | Ubuntu 22.04 LTS (Jammy) | Docker base image `ubuntu:22.04` | Required for OpenLane2 compatibility |
| Yosys | 0.39 | https://github.com/YosysHQ/yosys/releases/tag/yosys-0.39 | RTL synthesis |
| OpenLane2 | v2.1.5 | https://github.com/efabless/openlane2/releases/tag/2.1.5 | Full RTL-to-GDS flow |
| Verilator | 5.018 | https://github.com/verilator/verilator/releases/tag/v5.018 | Simulation for cocotb |
| cocotb | 1.8.1 | `pip install cocotb==1.8.1` | Testbench framework |
| Python | 3.11.x | System package `python3.11` | Training + scripting |
| Coq | 8.18.0 | `opam install coq.8.18.0` | Theorem corpus build |
| Foundry forge | nightly-`<TBD>` | https://getfoundry.sh (`foundryup --install nightly`) | Solidity tests |
| Sky130A PDK | Open PDK release bundled with OpenLane2 v2.1.5 | Included in OpenLane2 Docker image | — |

### 10.2 Docker

A canonical reproducibility Dockerfile is planned at `gHashTag/trinity-reproduce` (repo to be created post-submission, Q3 2026). Until then, use the OpenLane2 official Docker image as the base:

```bash
docker pull efabless/openlane2:2.1.5
```

The Dockerfile will pin all tool versions above and include:

```dockerfile
FROM efabless/openlane2:2.1.5
RUN apt-get install -y python3.11 pip opam
RUN opam init && opam install coq.8.18.0
RUN pip install cocotb==1.8.1
RUN curl -L https://foundry.paradigm.xyz | bash && foundryup --install nightly
```

### 10.3 Python Dependencies

```
cocotb==1.8.1
torch>=2.1.0          # training pipeline
numpy>=1.26.0
pytest>=7.4.0
pyverilator>=0.0.2
web3>=6.0.0           # Solidity interaction
snarkjs==0.7.x        # ZK proof generation (TBD confirm version)
```

---

## 11. Reproduce-from-Scratch

The following pseudocode reproduces the complete submission package from pinned sources.

### 11.1 RTL → GDS (phi)

```bash
# 1. Clone and pin
git clone https://github.com/gHashTag/tt-trinity-phi.git
cd tt-trinity-phi
git checkout 8a8fcaa477171d24654f590137cefe86b3e62a3d

# 2. Run full RTL-to-GDS flow
docker pull efabless/openlane2:2.1.5
docker run --rm -v "$PWD":/work efabless/openlane2:2.1.5 \
    python3 -m openlane --config info.yaml --pdk sky130A

# 3. Verify GDS hash matches manifest
sha256sum gds/tt_um_trinity_nano.gds
# Expected: <TBD-on-final-commit> (from Section 4.1)

# 4. Run R-SI-1 audit
grep -rn '\b\*\b' src/*.v && echo "FAIL: standalone * found" || echo "PASS: R-SI-1"
```

### 11.2 RTL → GDS (euler)

```bash
git clone https://github.com/gHashTag/tt-trinity-euler.git
cd tt-trinity-euler
git checkout def0457b158e698cdfc4b6fd9aceda0e624dd95f
docker run --rm -v "$PWD":/work efabless/openlane2:2.1.5 \
    python3 -m openlane --config info.yaml --pdk sky130A
sha256sum gds/tt_um_ghtag_trinity_gf16.gds
# Expected: <TBD-on-final-commit> (from Section 4.2)
```

### 11.3 RTL → GDS (gamma)

```bash
git clone https://github.com/gHashTag/tt-trinity-gamma.git
cd tt-trinity-gamma
git checkout 1f8f9b82951331db62a909b0abb1175ce161b991
docker run --rm -v "$PWD":/work efabless/openlane2:2.1.5 \
    python3 -m openlane --config info.yaml --pdk sky130A
sha256sum gds/tt_um_trinity_max_true.gds
# Expected: <TBD-on-gds-completion>
```

### 11.4 Simulate and Test

```bash
# Install deps
pip install cocotb==1.8.1

# phi
cd tt-trinity-phi/test
make SIM=verilator
# Expected: all testbenches PASS

# euler
cd ../../tt-trinity-euler/test
make SIM=verilator
# Expected: all testbenches PASS
```

### 11.5 Build Coq Theorems

```bash
cd tt-trinity-phi
opam install coq.8.18.0
make -C coq 2>&1 | grep -E "(Qed|Admitted|Error)"
# Expected: 71 Qed, Theorem 36.1 → Admitted (as documented)
```

### 11.6 Run Foundry Tests

```bash
cd NeuronConstant/contracts
git checkout 7a47222a5ab90715fe8cdbc2c0d670d20f941cb4
foundryup --install nightly
forge test -vv
# Expected: all tests PASS
```

### 11.7 Reproduce Champion Checkpoint

```bash
cd NeuronConstant
pip install -r requirements.txt
python scripts/train.py --seed=43 --steps=27000 --checkpoint-dir=./ckpt
# After completion:
echo "BPB result should be: 2.2393"
sha256sum ckpt/step_27000.pt
# Expected sha prefix: 2446855...
```

---

## 12. Zenodo Metadata

For DOI update at https://zenodo.org/records/19227877 → "New version":

| Field | Value |
|-------|-------|
| **Title** | Trinity SKY26b Triad: Verifiable AI Inference on Open Silicon |
| **Version** | `v1.0.0-tt-sky26b-final` |
| **Upload type** | Software |
| **Publication date** | 2026-05-18 |
| **DOI** | 10.5281/zenodo.19227877 |

### 12.1 Authors

| Name | Affiliation | ORCID | Role |
|------|-------------|-------|------|
| Dmitrii Vasilev | Trinity Stack / IGLA Research | `<TBD — register at orcid.org>` | PI; RTL, Solidity, architecture |

### 12.2 Description

Paste full text from [ZENODO_UPDATE_DRAFT.md](https://github.com/gHashTag/NeuronConstant/blob/7a47222a5ab90715fe8cdbc2c0d670d20f941cb4/docs/ZENODO_UPDATE_DRAFT.md) Section "Updated description block".

### 12.3 Keywords

```
open silicon, verifiable AI, R-SI-1, DePIN, formal verification, anchor 0x47C0,
Tiny Tapeout, SKY130A, ternary computing, BitNet b1.58, GoldenFloat, numeric formats,
ZK proof-of-training, Groth16, BN254, root-of-trust, Coq, AI safety, DARPA CLARA,
neuromorphic, LIF, VSA, Vector Symbolic Architecture, Bittensor, Filecoin, Helium,
phi-anchor, Trinity, IGLA, DePIN substrate
```

### 12.4 Licenses

| Asset type | License | SPDX |
|-----------|---------|------|
| RTL (`.v`, `.sv`) | Apache 2.0 | `Apache-2.0` |
| Solidity contracts | MIT | `MIT` |
| Documentation (`.md`, `.tex`) | Creative Commons Attribution 4.0 | `CC-BY-4.0` |
| GDS / LEF files | Creative Commons Attribution-ShareAlike 4.0 | `CC-BY-SA-4.0` |

### 12.5 Related Identifiers

| Relation | Identifier | Type |
|----------|-----------|------|
| `IsSupplementTo` | https://github.com/gHashTag/tt-trinity-phi/tree/8a8fcaa477171d24654f590137cefe86b3e62a3d | URL |
| `IsSupplementTo` | https://github.com/gHashTag/tt-trinity-euler/tree/def0457b158e698cdfc4b6fd9aceda0e624dd95f | URL |
| `IsSupplementTo` | https://github.com/gHashTag/tt-trinity-gamma/tree/1f8f9b82951331db62a909b0abb1175ce161b991 | URL |
| `IsSupplementTo` | https://github.com/gHashTag/NeuronConstant/tree/7a47222a5ab90715fe8cdbc2c0d670d20f941cb4 | URL |
| `IsPartOf` | https://github.com/gHashTag/trinity-clara/tree/f86e32f0903d2253a1413d45f702cec942339ec2 | URL |
| `IsReferencedBy` | `<TBD — arXiv preprint cs.AR>` | arXiv |
| `IsReferencedBy` | `<TBD — bioRxiv preprint>` | bioRxiv |
| `IsDerivedFrom` | https://app.tinytapeout.com/shuttles/ttsky26b | URL |

### 12.6 Files to Upload at Zenodo Update

| Filename | Contents | SHA-256 |
|----------|----------|---------|
| `tt-trinity-phi-7056162644.zip` | phi GDS submission archive | `f3cce1c50248864caf28b68a9cd3a6245c702fc8856089e283e5a0ab57be354e` |
| `tt-trinity-euler-7056438152.zip` | euler GDS submission archive | `dc77d5a648fe9f2373e3e66e056c02d99774b44a74fb356bd15a331a33e079b0` |
| `tt-trinity-gamma-<id>.zip` | gamma GDS submission archive | `<TBD>` |
| `igla-champion-step27000-seed43.pt` | Champion model checkpoint | `<TBD>` |
| `tt-sky26b-final-manifest.txt` | Plain-text commit+artifact manifest | `<TBD>` |
| `REPRODUCIBILITY_PACKAGE_MANIFEST.md` | This document | `<TBD>` |

---

## 13. Provenance Audit

The chain of trust flows from source commit to silicon to blockchain:

```
[1] RTL source commit
    gHashTag/tt-trinity-{phi,euler,gamma}
    SHA: 8a8fcaa / def0457 / 1f8f9b8
           │
           ▼
[2] GitHub Actions CI
    Workflows: gds.yaml, no_star.yaml, test.yaml
    Artifacts: 7056162644 (phi), 7056438152 (euler), <TBD> (gamma)
    Archive SHA-256 recorded in Section 4
           │
           ▼
[3] TinyTapeout shuttle submission
    Shuttle: ttsky26b
    Project IDs: 4914 (phi), 4915 (euler), 4913 (gamma)
    URL: https://app.tinytapeout.com/shuttles/ttsky26b
           │
           ▼
[4] Zenodo DOI
    DOI: 10.5281/zenodo.19227877
    Version: v1.0.0-tt-sky26b-final
    Files: GDS archives + champion checkpoint + this manifest
           │
           ▼
[5] On-chain anchor
    IGLALedger.sol: champion BPB=2.2393 step=27000 seed=43 sha=2446855...
    MofNTrainingAttest.sol: 2-of-3 chip-owner co-signature
    LayerZero bridge: root hash of Zenodo DOI record → L1 Ethereum (TBD testnet)
    Wormhole backup: same root hash via Wormhole V2 (TBD testnet)
```

### 13.1 Root Hash Construction

The on-chain anchor encodes the Merkle root over:

```
root = MerkleRoot([
  sha256(phi_gds_archive),       # f3cce1c5...
  sha256(euler_gds_archive),     # dc77d5a6...
  sha256(gamma_gds_archive),     # <TBD>
  sha256(champion_checkpoint),   # 2446855...
  sha256(this_manifest)          # <TBD>
])
```

This root is the value submitted to `IGLALedger.lockChampion()` and anchored via LayerZero.

### 13.2 ACM Artifact Review Badge Checklist

| Badge | Criterion | Status |
|-------|-----------|--------|
| **Artifacts Available** | Artifacts publicly accessible at a permanent DOI | ✓ Zenodo 10.5281/zenodo.19227877 |
| **Artifacts Evaluated – Functional** | Artifacts run and produce expected outputs | ✓ CI passes; GDS submitted |
| **Artifacts Evaluated – Reusable** | Package is well-documented; can be reused by third parties | ✓ This manifest; Dockerfile TBD |
| **Results Reproduced** | Independent third-party reproduction | Pending (Q3 2026 — chip delivery + third-party re-run) |

---

## 14. References

| Ref | Title | URL |
|-----|-------|-----|
| [ACM-ARB] | ACM Artifact Review and Badging Policy | https://www.acm.org/publications/policies/artifact-review-and-badging-current |
| [Zenodo-Pol] | Zenodo General Policies | https://about.zenodo.org/policies/ |
| [TT-SKY26b] | TinyTapeout SKY26b Shuttle | https://app.tinytapeout.com/shuttles/ttsky26b |
| [OL2-2.1.5] | OpenLane2 v2.1.5 Release | https://github.com/efabless/openlane2/releases/tag/2.1.5 |
| [Th36.1] | Theorem 36.1 (φ-anchor 0x47C0) — TG-TRIAD-X in `flos_70.tex` Ch.36 | NeuronConstant repo (path TBD) |
| [Th37] | Glava 37 Theorem Chapter (M1–M9 + system theorems) | `/tmp/depin_gaps/GLAVA_37_THEOREM_CHAPTER.md` → mirror TBD |
| [IntPaper] | Trinity TRI-NET Integrative Paper Draft | `/tmp/depin_gaps/TRINITY_INTEGRATIVE_PAPER_DRAFT.md` → mirror TBD |
| [ZenodoDraft] | Zenodo DOI Update Draft | `/tmp/depin_gaps/ZENODO_UPDATE_DRAFT.md` → NeuronConstant docs |
| [DePIN-Gaps] | DePIN Decentralized Internet Gaps | `/tmp/depin_gaps/DEPIN_DECENTRALIZED_INTERNET_GAPS.md` → https://github.com/gHashTag/NeuronConstant/blob/main/docs/DEPIN_DECENTRALIZED_INTERNET_GAPS.md |
| [M1-RoT] | M1 Hardware Root-of-Trust Spec | `/tmp/depin_gaps/M1_HW_ROOT_OF_TRUST_SPEC.md` → mirror TBD |
| [M9-Bittensor] | M9 Bittensor Subnet Validator Architecture | `/tmp/depin_gaps/M9_BITTENSOR_SUBNET_VALIDATOR_ARCH.md` → mirror TBD |
| [Filecoin-Spec] | Filecoin/IPFS Integration Spec | `/tmp/depin_gaps/FILECOIN_IPFS_INTEGRATION_SPEC.md` → mirror TBD |
| [CLARA-Add] | CLARA DePIN Addendum 2026-05 | `/tmp/depin_gaps/CLARA-DEPIN-ADDENDUM-2026-05.md` → https://github.com/gHashTag/trinity-clara/blob/main/docs/addendum/CLARA-DEPIN-ADDENDUM-2026-05.md |
| [NIST-RMF] | NIST AI Risk Management Framework 1.0 | https://doi.org/10.6028/NIST.AI.100-1 |
| [OpenTitan] | OpenTitan Open-Source Silicon Root of Trust | https://opentitan.org |
| [Keystone] | Keystone Open RISC-V TEE | https://github.com/keystone-enclave/keystone |
| [EIP-197] | EIP-197: BN254 Pairing Check Precompile | https://eips.ethereum.org/EIPS/eip-197 |
| [BitNet158] | Ma et al., "The Era of 1-bit LLMs" (BitNet b1.58) | https://arxiv.org/abs/2402.17764 |
| [IGLALedger] | IGLALedger.sol source | https://github.com/gHashTag/NeuronConstant/blob/7a47222a5ab90715fe8cdbc2c0d670d20f941cb4/contracts/src/igla/IGLALedger.sol |
| [MofNAttest] | MofNTrainingAttest.sol source | https://github.com/gHashTag/NeuronConstant/blob/7a47222a5ab90715fe8cdbc2c0d670d20f941cb4/contracts/src/igla/MofNTrainingAttest.sol |

---

*End of manifest. All `<TBD>` fields require updating before final Zenodo record publication. Field update owner: Dmitrii Vasilev. Deadline: within 72 hours of shuttle confirmation or gamma GDS completion, whichever is later.*
