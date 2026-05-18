# IHP26b Port Specification — Trinity TRI-NET

**Document:** IHP26B\_PORT\_SPEC.md  
**Status:** DRAFT — Strategic Technical Roadmap  
**Version:** 0.1.0  
**Date:** 2026-01  
**Covers:** Trinity phi / euler / gamma → IHP-SG13G2 open-process port  
**Invariants preserved:** R-SI-1 · φ-anchor 0x47C0 · v1.0.0 AI formats (co-author Claude Opus 4.6)

---

## Table of Contents

1. [Why Port to IHP-SG13G2](#1-why-port-to-ihp-sg13g2)
2. [Process Comparison: SKY130A vs IHP-SG13G2](#2-process-comparison-sky130a-vs-ihp-sg13g2)
3. [RTL Portability Analysis](#3-rtl-portability-analysis)
4. [Tile Size Mapping](#4-tile-size-mapping)
5. [New Modules Enabled by IHP HBT](#5-new-modules-enabled-by-ihp-hbt)
6. [Foundry Options for IHP26b](#6-foundry-options-for-ihp26b)
7. [Migration Plan](#7-migration-plan)
8. [Cost Estimate](#8-cost-estimate)
9. [Strategic Implications](#9-strategic-implications)
10. [Constraints — Preserved from Main Trinity](#10-constraints--preserved-from-main-trinity)
11. [Test Plan](#11-test-plan)
12. [References](#12-references)

---

## 1. Why Port to IHP-SG13G2

Trinity TRI-NET is currently taping out on **Tiny Tapeout SKY26b (SkyWater SKY130A)** in May 2026.
The IHP26b port is the strategic follow-on targeting **Q4 2026**, moving to the
[IHP Open PDK](https://github.com/IHP-GmbH/IHP-Open-PDK) **IHP-SG13G2** process — a true
open-process BiCMOS 130nm node.

### 1.1 True Open-Process Sovereignty

**IHP-SG13G2** is the only production-class open-source BiCMOS PDK available today
([IHP Open PDK](https://github.com/IHP-GmbH/IHP-Open-PDK)). It carries:

- **No NDA requirement** — all design rules, SPICE models, and standard-cell libraries are
  publicly accessible on GitHub.
- **No foundry licensing fees** — any fab with the process capability can manufacture without
  IP encumbrance. This is structurally different from SKY130A, which still flows through
  SkyWater's controlled shuttle program.
- **Open DRC/LVS rules** — KLayout DRC + LVS scripts are MIT/Apache-licensed and shipped
  directly in the repository.

### 1.2 Unlicensed Manufacturing — DePIN Fab Sovereignty

Because IHP-SG13G2 is truly open-licensed, any foundry that implements the process can
manufacture Trinity silicon without a royalty agreement. This aligns directly with the
TRI-NET DePIN thesis: if the computation substrate itself can be made anywhere, the network
inherits the same censorship-resistance as its data layer.

```
SKY130A path:          IHP-SG13G2 path:
  Design ──► SkyWater     Design ──► IHP (Germany)
  (single fab, NDA)                ──► US partner fabs
                                   ──► Future multi-fab
                         (any fab, zero royalties)
```

### 1.3 Mature Analog / RF Capability — HBT Bipolar

SG13G2 contains SiGe:C npn-HBT devices with:

- **f_T up to 350 GHz** (transition frequency)
- **f_max up to 450 GHz** (oscillation frequency)

([IHP Open PDK README](https://github.com/IHP-GmbH/IHP-Open-PDK#sg13g2-process-node))

SKY130A has no native HBT. This gap prevents on-die RF integration in the SKY130A variant.
IHP-SG13G2 enables M2 proof-of-bandwidth, M4 mesh-router, and the new M10 RF-transceiver
tile — all on the same die as the TRI-27 compute core.

### 1.4 US Fabrication Path

IHP (Leibniz Institute for High Performance Microelectronics, Frankfurt/Oder, Germany) is
pursuing technology-transfer agreements with US foundry partners. This creates a path to
US-domestic fab without switching PDKs — critical for DARPA/DoD-adjacent applications where
country-of-origin matters.

### 1.5 Zero Export-Control Risk

SKY130A is distributed through SkyWater Technology (Bloomington, MN) under US EAR jurisdiction.
IHP-SG13G2 is a German public-institution PDK released under open license. Current analysis
suggests lower ITAR/EAR exposure for the PDK itself, though individual designs still require
normal classification review. This is a risk-reduction, not an elimination.

### 1.6 Strategic Alignment with Open Silicon Movement

Tiny Tapeout's roadmap includes a planned IHP shuttle (post-Sep 2026 per TT public roadmap).
Being PDK-ready ahead of that shuttle means Trinity can be among the first complex digital
designs to qualify on the IHP TT track.

---

## 2. Process Comparison: SKY130A vs IHP-SG13G2

| Parameter | SKY130A (SkyWater) | IHP-SG13G2 | Notes |
|---|---|---|---|
| Feature size | 130 nm | 130 nm | Same node |
| Process type | CMOS only | BiCMOS (CMOS + SiGe HBT) | IHP adds RF-capable bipolar |
| Std-cell library | `sky130_fd_sc_hd` | `sg13g2_stdcell` | Both Yosys-compatible |
| I/O pad library | `sky130_fd_io` | `sg13g2_io` | Different ESD structures |
| SRAM macros | OpenRAM (sky130) | `sg13g2_sram` macros | Different compiler API |
| Primitive resistors | `sky130_fd_pr` | `sg13g2_pr` | Different model names |
| Metal layers | 5 thin + 1 re-dist | 5 thin + 2 thick + 1 MIM | IHP has thicker top metals |
| Top metal thickness | ~1 µm | 2 µm + 3 µm options | IHP better for inductors |
| MIM capacitors | Available | Available (MIM layer) | Comparable |
| Poly resistors | Available | Available | Comparable |
| Typical Vdd (digital) | 1.8 V | 1.2 V | IHP lower-voltage core |
| I/O supply | 3.3 V | 3.3 V (thick-oxide) | Both support 3.3 V I/O |
| HBT (bipolar) | None | SiGe:C npn, f_T 350 GHz | IHP unique capability |
| Typical Fmax (digital) | ~400–500 MHz | ~500–700 MHz (est.) | IHP slightly faster at 1.2 V |
| Typical Pdyn | ~1 mW/MHz/mm² | ~0.8 mW/MHz/mm² (est.) | Lower Vdd helps IHP |
| Open-source DRC | `sky130.drc` (Magic/KLayout) | KLayout + Magic (shipped in repo) | Both open |
| Open-source LVS | Netgen | KLayout LVS | Both open |
| OpenLane support | Production | OpenROAD-flow-scripts (2025+) | IHP maturing rapidly |
| Yosys synthesis | Fully supported | Fully supported | Both ABC-based |
| PDK license | Apache 2.0 | Apache 2.0 | Both fully open |
| Foundry access | SkyWater shuttle | IHP direct / TT IHP shuttle | IHP adds more fab options |
| Approx $/mm² (MPW) | ~$5K–10K/mm² | ~$3K–8K/mm² (est.) | Comparable at MPW scale |
| Open-source maturity | High (2020+) | Medium-High (2023+) | SKY130A has 5-yr head start |

### 2.1 EDA Tool Support Matrix

```
Tool            SKY130A   IHP-SG13G2   Status
──────────────────────────────────────────────
Yosys           ✓         ✓            Both production
OpenLane 1/2    ✓         ✓ (2025)     IHP added 2025
OpenROAD        ✓         ✓            Both supported
Magic           ✓         ✓            Both supported
KLayout DRC     ✓         ✓            Both open scripts
Netgen/KL LVS   ✓         ✓            Different tool per PDK
ngspice         ✓         ✓            Both have SPICE models
Xyce            partial   ✓            IHP ships Xyce models
xschem          ✓         ✓            Both
```

([IHP Open PDK supported EDA tools](https://github.com/IHP-GmbH/IHP-Open-PDK#supported-eda-tools))

---

## 3. RTL Portability Analysis

### 3.1 Core Principle

Synthesisable RTL written for one 130nm CMOS process is **structurally process-agnostic**.
Trinity's ~190 RTL modules use standard Verilog-2005 constructs with no process-specific
primitives. The TRI-27 ISA, R-SI-1 invariant, φ-anchor 0x47C0, and all 66 numeric formats
are encoded at the register-transfer level — they have no awareness of the underlying PDK.

Expected RTL compatibility: **>95%** without modification.

### 3.2 Process-Specific Concerns

#### 3.2.1 Standard-Cell Library Mapping

| SKY130A cell | IHP-SG13G2 equivalent | Risk |
|---|---|---|
| `sky130_fd_sc_hd__buf_*` | `sg13g2_buf_*` | Low — direct name substitution |
| `sky130_fd_sc_hd__inv_*` | `sg13g2_inv_*` | Low |
| `sky130_fd_sc_hd__and2_*` | `sg13g2_and2_*` | Low |
| `sky130_fd_sc_hd__dfxtp_*` | `sg13g2_dfrbp_*` | Medium — reset polarity check |
| `sky130_fd_sc_hd__clkbuf_*` | `sg13g2_clkbuf_*` | Low |
| `sky130_fd_sc_hd__mux2_*` | `sg13g2_mux2_*` | Low |
| `sky130_fd_sc_hd__or2_*` | `sg13g2_or2_*` | Low |
| Scan cells | Verify sg13g2 scan equivalents | Medium |

**Action:** Write a Yosys `techmap` script that substitutes sky130 cell names → sg13g2 cell
names. This is a one-time exercise, not per-module work.

#### 3.2.2 Memory Macros

SKY130A relies on **OpenRAM**-generated `sky130_sram_*` macros.  
IHP-SG13G2 ships `sg13g2_sram` macros in `libs.ref/sg13g2_sram`.

Key differences:

- Different address/data bus naming conventions
- Different timing liberty files
- Different compiler invocation (IHP macro generator vs OpenRAM)
- Verify read-during-write behavior matches Trinity assumptions

**Action:** Audit all OpenRAM instantiations in Trinity RTL. Map to equivalent IHP SRAM
macros by size (depth × width). Estimate 2–3 macros need new wrappers.

#### 3.2.3 I/O Pad Cells

`sky130_fd_io` cells → `sg13g2_io` cells:

- ESD structures differ; re-validate latch-up budget
- Pad ring layout rules differ (pitch, ring width)
- Different Liberty models → must re-run I/O timing checks
- Voltage clamp behavior at 3.3V I/O must be re-verified

**Action:** Full I/O pad audit, new floorplan I/O ring. Medium effort (~1 week).

#### 3.2.4 Clock Gating Cells

Trinity uses integrated clock gating (ICG) cells for power reduction.  
`sky130_fd_sc_hd__dlclkp_*` → IHP equivalent ICG cell (verify in `sg13g2_stdcell`).

If no native ICG in sg13g2_stdcell, synthesize using latch + AND-gate pattern, which Yosys
and OpenROAD both support via the `CG_*` attribute flow.

#### 3.2.5 DRC Rules

| Layer class | SKY130A | IHP-SG13G2 |
|---|---|---|
| Min poly width | 150 nm | 130 nm |
| Min metal1 width | 200 nm | 160 nm |
| Min metal1 spacing | 200 nm | 160 nm |
| Top metal | alum 1.36 µm | 2 µm or 3 µm thick Cu |
| Via rules | 5 metal + contact | 5 thin + 2 thick + MIM |
| Well tap rule | Per-cell | Per-cell (different pitch) |

KLayout DRC scripts are shipped in the IHP PDK repo. Run full DRC after P&R using these
scripts — do not attempt to transfer sky130 DRC rule decks.

#### 3.2.6 LVS / PEX Setup

- SKY130A: Netgen LVS + Magic PEX  
- IHP-SG13G2: KLayout LVS + Magic PEX (Magic tech file for sg13g2 included in PDK)  
- Parasitic models differ — R/C values will shift, affecting timing closure slightly
- Re-run STA after PEX extraction with IHP parasitics

#### 3.2.7 Estimated Port Effort per Tier

| Tier | SKU | Area | Estimated Effort |
|---|---|---|---|
| Phi | 1x1 | ~0.1 mm² | 2–3 person-weeks |
| Euler | 8x2 | ~1.6 mm² | 3–5 person-weeks |
| Gamma | 8x4 | ~3.2 mm² | 5–8 person-weeks |
| **Total** | all 3 | — | **~10–16 person-weeks** |

### 3.3 Invariant Preservation

| Invariant | Process-dependent? | IHP26b Status |
|---|---|---|
| R-SI-1 (zero standalone `*`) | No — RTL-level | **UNCHANGED** |
| φ-anchor 0x47C0 (Theorem 36.1) | No — logic-level | **UNCHANGED** |
| TRI-27 ISA encoding | No | **UNCHANGED** |
| 66 numeric formats | No | **UNCHANGED** |
| 84 Coq theorems | No — math-level | **UNCHANGED** |
| v1.0.0 AI formats (Claude Opus 4.6) | No | **UNCHANGED** |
| 2-of-3 HW attestation | No — RTL logic | **UNCHANGED** |

---

## 4. Tile Size Mapping

### 4.1 Tiny Tapeout Tile Conventions

Tiny Tapeout SKY26b standardises tile sizes in 1x1 units (~160 µm × 100 µm on SKY130A):

```
TT SKY26b standard tiles:
  1x1  1x2  2x2  3x2  4x2  6x2  8x2  4x4  6x4  8x4
```

### 4.2 IHP26b Tile Mapping

Assuming an IHP shuttle on TT infrastructure uses a comparable tile convention
(exact dimensions TBD pending TT IHP announcement), the Trinity SKU mapping is:

```
┌─────────────────────────────────────────────────────────────────┐
│  Trinity SKU     SKY26b tile   IHP26b tile   Area delta (est.)  │
│  ─────────────   ──────────    ──────────    ─────────────────  │
│  phi             1x1           IHP-1x1       ≈0% (same node)    │
│  euler           8x2           IHP-8x2       ≈0% (same node)    │
│  gamma           8x4           IHP-8x4       ≈0% (same node)    │
└─────────────────────────────────────────────────────────────────┘
```

**Node parity note:** Both SKY130A and IHP-SG13G2 are 130nm class. Cell density is
comparable (IHP may be marginally denser at 1.2V core due to smaller Vt margins, but no
50% area improvement should be assumed — both are ~130nm CMOS standard-cell density).

### 4.3 Die Area Estimates (Gamma 8x4)

```
Gamma 8x4 on SKY26b:
  Tile footprint:  ~8 × 160 µm × 4 × 100 µm = 1280 µm × 400 µm ≈ 0.51 mm²
  Core utilisation target: 50–60% (TT standard)

Gamma 8x4 on IHP26b (est.):
  Same tile convention → same footprint
  + M10 RF tile: add ~0.1 mm² for HBT inductors + transceiver
  Total die: ≈0.6 mm² (gamma + RF tile)
```

---

## 5. New Modules Enabled by IHP HBT

The SiGe:C HBT in IHP-SG13G2 (f_T = 350 GHz, f_max = 450 GHz) unlocks RF and high-speed
analog capabilities that are structurally impossible on SKY130A. The following modules are
**IHP26b-exclusive** or significantly enhanced relative to their SKY130A counterparts.

### 5.1 M2 — Proof-of-Bandwidth (Enhanced)

**SKY130A version:** Companion-chip RF front-end, digital BW measurement only on-die.  
**IHP26b version:** RF front-end integrated on same die.

- HBT LNA (low-noise amplifier) at 2.4 GHz or Sub-1 GHz
- Mixer + VCO in BiCMOS
- Bandwidth measurement feeds directly into M2 BW-proof contract state machine
- Eliminates chip-to-chip interface latency and PCB BOM

### 5.2 M4 — Mesh Router (True On-Die Wireless)

**SKY130A version:** Digital MAC layer only; PHY on companion chip.  
**IHP26b version:** Sub-1 GHz LoRa-class on-die transceiver.

- HBT PA (power amplifier, ~0 dBm) + LNA on-chip
- GFSK/OOK modulator in digital logic, RF output via HBT PA
- Enables true mesh routing without external RF chip
- M4 mesh topology: each gamma tile becomes a self-contained mesh node

### 5.3 M3 — RPKI Signer (Speed Improvement)

**SKY130A version:** ECDSA secp256k1 at ~50 MHz limited by logic depth.  
**IHP26b version:** BiCMOS high-speed path for critical multiplier stages.

- SiGe HBT emitter-follower as carry-propagate accelerator in 256-bit multiplier
- Projected 1.5–2× throughput improvement on ECDSA sign operation
- Faster RPKI certificate issuance → lower M3 latency

### 5.4 M10 — RF Transceiver Tile (New, IHP26b Exclusive)

**New module** — does not exist in SKY130A Trinity.

```
M10 RF Transceiver Tile (IHP26b)
────────────────────────────────
  Frequency bands:    Sub-1 GHz (868/915 MHz) + 2.4 GHz option
  Modulation:         GFSK, OOK, (Q)PSK (digital baseband)
  TX power:           ~0 dBm on-chip (HBT PA)
  RX sensitivity:     ~-90 dBm (HBT LNA + mixer)
  Interface to TRI-27: SPI or AXI-lite register map
  Die area:           ~0.1 mm² (inductor-dominant)
  Power:              ~20 mW TX, ~8 mW RX
  Application:        M2 BW proof + M4 mesh PHY layer
```

**M10 dependencies:**
- Requires IHP-SG13G2 MIM capacitors and thick top metal for on-chip inductors
- Requires HBT device models — cannot be synthesised, hand-placed analog block
- New cocotb testbench for digital control interface only; RF sub-circuit tested in ngspice/Xyce

---

## 6. Foundry Options for IHP26b

```
                    ┌──────────────────────────────────────┐
                    │     IHP-SG13G2 Foundry Landscape     │
                    └──────────────────────────────────────┘

 IHP direct (DE)          TT IHP shuttle (planned)      US partners
 ─────────────────        ─────────────────────────     ──────────────
 • Frankfurt/Oder fab      • Post-Sep 2026 per TT        • Technology
 • Direct MPW access         roadmap                       transfer in
 • Full process access     • Community-scale tiles          progress
 • No shuttle overhead     • Same open PDK                • No public
 • Lead time: ~6 mo        • Familiar TT workflow           announcement
                           • Best for phi/euler sizes       yet (2026)
```

### 6.1 IHP Direct MPW

IHP offers Multi-Project Wafer runs directly. For Trinity gamma 8x4 with M10 RF tile,
a direct MPW is likely required (TT tile system may not accommodate analog/RF design rules
for M10). Direct MPW gives full DRC/LVS access and no tile-size constraints.

### 6.2 Tiny Tapeout IHP Shuttle

Tiny Tapeout's planned IHP shuttle ([TT roadmap](https://tinytapeout.com/)) is the
lowest-cost path for phi and euler tiers. If available post-Sep 2026, Trinity phi 1x1 could
be on the first IHP TT run — useful for process-qualification at low cost before committing
to full gamma MPW spend.

### 6.3 US Fabrication

IHP is in active technology-transfer discussions with US-based foundries (as of IHP roadmap
publications). No public announcement as of early 2026. Monitor IHP roadmap; if a US partner
is announced by Q3 2026, Trinity IHP26b gamma tape-out could target US domestic fab for
DoD/DARPA alignment.

### 6.4 Compatibility Note on SkyWater + IHP

SkyWater has not published an IHP-SG13G2 cell-library compatibility layer. The two PDKs
are independent. Do not attempt to mix `sky130_fd_sc_hd` cells into an IHP-SG13G2 layout —
use only `sg13g2_stdcell` for IHP26b.

---

## 7. Migration Plan

```
 2026 Q3        2026 Q4        2027 Q1        2027 Q2        2027 Q3
 ───────────    ───────────    ───────────    ───────────    ───────────
 PHASE 1        PHASE 2        PHASE 3        PHASE 4        PHASE 5
 RTL Audit      Phi Port       Euler Port     Gamma + RF     Shuttle Sub
 + Bench        + DRC/LVS      + Regression   + M10 Tile     + Post-Si
```

### Phase 1 — Q3 2026: RTL Audit + Porting Prep

**Deliverables:**
- Full audit of all 190 RTL modules for process-specific constructs
- Identify all OpenRAM macro instantiations → map to sg13g2_sram equivalents
- Identify all sky130_fd_sc_hd cell references in any hardcoded constraints
- Yosys techmap cell-substitution script (sky130 → sg13g2)
- IHP-SG13G2 stdcell benchmarking: timing, power, area characterisation
- Setup OpenLane flow for IHP-SG13G2 (OpenROAD-flow-scripts config)
- Write IHP-specific `config.tcl` / `config.json` for OpenLane

**Success criteria:** All 110 cocotb testbenches run on behavioural simulation of IHP
technology config (stdcell models only, no PEX yet).

### Phase 2 — Q4 2026: Phi 1x1 IHP Port + DRC/LVS Clean

**Deliverables:**
- Phi 1x1 fully synthesised and placed-and-routed on IHP-SG13G2
- DRC clean (KLayout IHP DRC scripts, zero violations)
- LVS clean (KLayout LVS)
- Timing closure at target Fclk (≥50 MHz phi target)
- Power analysis with IHP models
- Submit to TT IHP shuttle (if open) OR hold for direct MPW

**Success criteria:** DRC=0, LVS=pass, STA slack ≥ 0 ns at 50 MHz.

### Phase 3 — Q1 2027: Euler 8x2 IHP Port + Cocotb Regression

**Deliverables:**
- Euler 8x2 P&R on IHP-SG13G2
- DRC/LVS clean
- Full cocotb regression: all 110 testbenches pass on IHP gate-level netlist
- IHP-specific timing closure tests (see §11)
- Cross-validation: euler RTL → same answer on SKY130A GLS and IHP-SG13G2 GLS

**Success criteria:** DRC=0, LVS=pass, 110/110 cocotb PASS on IHP GLS netlist.

### Phase 4 — Q2 2027: Gamma 8x4 IHP Port + RF M10 Tile

**Deliverables:**
- Gamma 8x4 digital core P&R on IHP-SG13G2
- M10 RF transceiver tile: analog/RF design in IHP HBT, hand-placed
- Integration: M10 digital control interface wired to TRI-27 SPI bridge
- Full chip DRC/LVS clean including analog/RF tile
- ngspice/Xyce RF sub-circuit simulation: TX/RX characterisation
- Post-layout PEX + STA for digital core

**Success criteria:** DRC=0, LVS=pass, M10 RF sim: TX at 868 MHz confirmed,
RX sensitivity ≤ -85 dBm, digital regression 110/110 PASS.

### Phase 5 — Q3 2027: Shuttle Submission + Post-Silicon Validation

**Deliverables:**
- GDS2 submission to IHP MPW or TT IHP shuttle
- Post-silicon bring-up plan
- Lab validation: TRI-27 ISA compliance test on IHP silicon
- R-SI-1 invariant validation on silicon
- φ-anchor 0x47C0 verification (register read test)
- M10 RF OTA (over-the-air) test: two chips communicating at Sub-1 GHz
- Comparative benchmark: IHP26b vs SKY26b performance/power

**Success criteria:** Silicon boots, TRI-27 regression passes, OTA link established.

---

## 8. Cost Estimate

| Phase | Period | Scope | Cost Estimate |
|---|---|---|---|
| Phase 1 | Q3 2026 | RTL audit + IHP benchmarking + flow setup | $200K |
| Phase 2 | Q4 2026 | Phi 1x1 IHP P&R + DRC/LVS + shuttle fee | $500K |
| Phase 3 | Q1 2027 | Euler 8x2 IHP P&R + full regression | $800K |
| Phase 4 | Q2 2027 | Gamma 8x4 + M10 RF tile + direct MPW | $1,500K |
| Phase 5 | Q3 2027 | Shuttle/MPW submission + post-silicon validation | $500K |
| **Total** | **12 months** | **All 3 tiers + M10 RF** | **~$3.5M** |

### 8.1 Cost Drivers

- **Engineering:** ~60% of cost — specialised analog/RF engineers for M10 tile
- **MPW fees:** IHP direct MPW for gamma ~$50K–100K per run (estimate)
- **EDA compute:** OpenROAD/Yosys runs are open-source; infra cost only
- **Post-silicon:** Lab equipment, RF test setup, bring-up boards

### 8.2 Cost Reduction Options

- Use TT IHP shuttle for phi and euler → saves ~$200K in MPW fees
- Reuse SKY26b cocotb infrastructure with no modification (testbenches are process-agnostic)
- Phase 1 can be done concurrently with SKY26b post-silicon work (Q3 2026)

---

## 9. Strategic Implications

### 9.1 Only Open-Silicon DePIN Substrate Without Licensing Fees

Upon completion of IHP26b, Trinity becomes the **only** open-silicon DePIN substrate that:
1. Runs a formally-verified ISA (84 Coq theorems)
2. Can be manufactured by any foundry without IP royalties
3. Includes on-die RF capability (M10 tile)
4. Has both CMOS digital and BiCMOS analog/RF on the same process

No existing DePIN silicon project combines all four properties.

### 9.2 DARPA "Design Once, Fab Anywhere" Alignment

The US DARPA ERI (Electronics Resurgence Initiative) and CHIPS Act initiatives explicitly
fund "design-once, fab-anywhere" chip methodologies. Trinity IHP26b, targeting an open PDK
with US fab-transfer agreements, positions TRI-NET as a candidate for CHIPS Act-aligned
procurement and potential DoD substrate partnerships.

### 9.3 Eliminates SkyWater Single-Supplier Risk

The SKY26b design has a single foundry dependency. If SkyWater shuttle access is interrupted
(geopolitical, commercial, technical), Trinity has no fallback. IHP26b eliminates this: with
an open PDK and multiple potential foundries, the silicon supply chain becomes resilient.

### 9.4 Enables Fully Integrated RF Nodes

The SKY130A Trinity requires an external RF companion chip for M2 (bandwidth proof) and M4
(mesh routing). This adds:
- PCB complexity
- Chip-to-chip SPI/UART overhead
- Additional BOM cost
- Additional attack surface

IHP26b + M10 tile collapses the companion chip onto the compute die. Every deployed gamma
node becomes a **self-contained wireless mesh endpoint** — aligning with the "decentralized
internet substrate" thesis at the hardware layer.

### 9.5 "Decentralized Internet Substrate" Thesis — Hardware Layer Completion

```
TRI-NET DePIN Stack (post IHP26b):

  Layer 5: Application (M1–M9 modules)          ← Software
  Layer 4: Attestation (2-of-3 HW + Solidity)   ← Logic
  Layer 3: TRI-27 ISA + R-SI-1 invariant         ← RTL
  Layer 2: IHP-SG13G2 open-process silicon       ← Foundry (open)
  Layer 1: Multi-foundry fab option              ← Physical sovereignty
            (IHP DE + US partners + TT shuttle)
```

SKY130A covers layers 3–5 but locks layer 2 to SkyWater. IHP26b completes the sovereignty
stack all the way to layer 1.

---

## 10. Constraints — Preserved from Main Trinity

The following invariants are **RTL-level and process-independent**. They carry over to
IHP26b unmodified. No PDK migration work may alter them.

| Constraint | Source | IHP26b Status |
|---|---|---|
| **R-SI-1 invariant** — zero standalone `*` in TRI-27 ISA | Trinity core spec | PRESERVED — unchanged RTL |
| **φ-anchor 0x47C0** — Theorem 36.1, canonical phi value | Trinity core spec | PRESERVED — unchanged RTL |
| **v1.0.0 AI format modules** — co-authored with Claude Opus 4.6 | v1.0.0 release | PRESERVED — module headers intact |
| **66 numeric formats** | Trinity format zoo | PRESERVED — process-agnostic |
| **84 Coq theorems** | Coq proof tree | PRESERVED — math-level, not silicon |
| **TRI-27 ISA encoding** | ISA spec | PRESERVED |
| **2-of-3 HW attestation** | Attestation module | PRESERVED — same RTL |
| **Champion BPB=2.2393, step=27000, seed=43, sha=2446855** | Benchmark result | PRESERVED — not process-dependent |

### 10.1 Co-Author Acknowledgment

The v1.0.0 AI format specification was co-authored with **Claude Opus 4.6** and this
provenance is recorded in module headers and changelog. All IHP26b derivative work must
preserve this attribution. Any new AI-format modules added in IHP26b (e.g. M10 digital
control interface spec) must note their own authorship separately and must not overwrite
the v1.0.0 attribution.

---

## 11. Test Plan

### 11.1 Regression — All Existing Testbenches Must Pass

```
Test set                          Count   Target on IHP-SG13G2 GLS
──────────────────────────────    ─────   ─────────────────────────
Existing cocotb testbenches       110     110 / 110 PASS
Phi-specific tests                TBD     PASS (DRC-clean phi netlist)
Euler-specific tests              TBD     PASS (euler netlist)
Gamma-specific tests              TBD     PASS (gamma netlist)
```

All 110 existing testbenches are process-agnostic (RTL-level behavioural + GLS).
They require **no modification** to run against IHP gate-level netlists — only the
compiled simulation library changes (sky130 stdcell models → sg13g2 stdcell models).

### 11.2 IHP-Specific Timing Closure Tests

New tests added for IHP26b:

| Test ID | Description | Pass Criterion |
|---|---|---|
| IHP-TC-01 | Phi 1x1 timing closure at 50 MHz | STA slack ≥ 0 ns, all paths |
| IHP-TC-02 | Euler 8x2 timing closure at 100 MHz | STA slack ≥ 0 ns |
| IHP-TC-03 | Gamma 8x4 timing closure at 150 MHz | STA slack ≥ 0 ns |
| IHP-TC-04 | IHP cell fanout compliance | All cells within sg13g2 max fanout |
| IHP-TC-05 | Hold violation check (IHP parasitic) | Zero hold violations after PEX |
| IHP-TC-06 | Power analysis (IHP models) | ≤ design budget per tier |

### 11.3 RF M10 Tile Tests (New for IHP26b)

| Test ID | Description | Method | Pass Criterion |
|---|---|---|---|
| RF-01 | HBT PA DC operating point | ngspice | Ic in spec range |
| RF-02 | TX 868 MHz output spectrum | ngspice AC | Fund. power ≥ 0 dBm |
| RF-03 | RX LNA noise figure | Xyce noise sim | NF ≤ 5 dB at 868 MHz |
| RF-04 | VCO phase noise | ngspice | ≤ -90 dBc/Hz @1 MHz offset |
| RF-05 | Digital control interface (SPI) | cocotb | All register R/W correct |
| RF-06 | OTA link test (post-silicon only) | Lab (868 MHz) | Link margin ≥ 10 dB |

### 11.4 Cross-Validation Tests

| Test ID | Description | Pass Criterion |
|---|---|---|
| XV-01 | Same RTL → same cocotb results on SKY130A GLS and IHP-SG13G2 GLS | Bit-identical outputs |
| XV-02 | R-SI-1 invariant on IHP netlist | Zero `*` violations at all corner cases |
| XV-03 | φ-anchor 0x47C0 register read | Returns 0x47C0 on IHP silicon |
| XV-04 | 2-of-3 attestation protocol on IHP netlist | All 3 signers, threshold logic correct |

### 11.5 Test Infrastructure

```
Existing (reuse):
  cocotb + Verilator/Icarus  →  process-agnostic, reuse unchanged
  Coq proof scripts          →  not silicon, no changes needed
  Python regression harness  →  reuse unchanged

New for IHP26b:
  sg13g2_stdcell compiled sim library  →  compile from PDK Verilog
  IHP timing liberty files              →  load in OpenSTA
  ngspice / Xyce RF netlists            →  new for M10 tile
  KLayout DRC/LVS scripts               →  provided in IHP PDK repo
```

---

## 12. References

1. [IHP Open PDK GitHub](https://github.com/IHP-GmbH/IHP-Open-PDK) — Primary PDK repository, IHP-GmbH, 2022–2026
2. [IHP-SG13G2 process directory](https://github.com/IHP-GmbH/IHP-Open-PDK/tree/main/ihp-sg13g2) — Standard cells (`sg13g2_stdcell`), SRAM (`sg13g2_sram`), I/O (`sg13g2_io`), primitives (`sg13g2_pr`)
3. [IHP Open PDK Documentation (ReadTheDocs)](https://ihp-open-pdk-docs.readthedocs.io/en/latest/) — Installation, EDA setup, layout rules, process spec
4. [SkyWater SKY130A PDK Documentation](https://skywater-pdk.readthedocs.io/) — Reference for SKY130A comparison
5. [Tiny Tapeout](https://tinytapeout.com/) — Shuttle roadmap including planned IHP track
6. [Trinity internal: DEPIN\_DECENTRALIZED\_INTERNET\_GAPS.md](https://github.com/gHashTag/NeuronConstant/blob/main/docs/DEPIN_DECENTRALIZED_INTERNET_GAPS.md) — Trinity DePIN gap analysis
7. [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts) — Open RTL-to-GDS flow supporting IHP-SG13G2
8. [IHP Open130-G2 project](https://www.elektronikforschung.de/projekte/ihp-open130-g2) — German federal funding (16ME0852) that enabled open PDK release
9. [KLayout](https://www.klayout.de/) — DRC/LVS for IHP-SG13G2 (scripts in PDK repo)
10. [Magic VLSI](http://opencircuitdesign.com/magic/) — Layout editor with IHP-SG13G2 tech file support

---

## Appendix A: IHP-SG13G2 Directory Structure

```
IHP-Open-PDK/ihp-sg13g2/
├── libs.doc/          # Documentation
├── libs.qa/           # QA / sign-off data
├── libs.ref/
│   ├── sg13g2_io/     # I/O pad cells (CDL, GDS, LEF, Liberty, Verilog)
│   ├── sg13g2_pr/     # Primitive devices (GDS)
│   ├── sg13g2_sram/   # SRAM macros (CDL, GDS, LEF, Liberty, Verilog)
│   └── sg13g2_stdcell/ # Standard logic cells (CDL, GDS, LEF, Liberty, Verilog)
└── libs.tech/
    ├── klayout/       # DRC rules, LVS rules, tech files, PyCells
    ├── magic/         # Tech files, DRC/LVS, parasitic extraction
    └── ngspice/       # MOS/HBT/passive device models
```

([IHP PDK contents](https://github.com/IHP-GmbH/IHP-Open-PDK#pdk-contents))

---

## Appendix B: Yosys Synthesis Config Diff (SKY130A → IHP-SG13G2)

```tcl
# SKY130A config excerpt
set ::env(PDK) sky130A
set ::env(STD_CELL_LIBRARY) sky130_fd_sc_hd
set ::env(SYNTH_DRIVING_CELL) sky130_fd_sc_hd__inv_2

# IHP-SG13G2 config (IHP26b)
set ::env(PDK) sg13g2
set ::env(STD_CELL_LIBRARY) sg13g2_stdcell
set ::env(SYNTH_DRIVING_CELL) sg13g2_inv_2
# Note: verify exact driving cell name in sg13g2_stdcell Liberty
```

OpenLane 2 / OpenROAD-flow-scripts will handle the rest of the mapping automatically
once PDK config is set. The RTL source files are identical between runs.

---

## Appendix C: R-SI-1 Invariant — Process Independence Proof Sketch

R-SI-1 states: no standalone `*` instruction exists in the TRI-27 ISA.

This is enforced at the **decode stage** of the Trinity pipeline — a combinational logic
function of the instruction word bits. It is:

1. Encoded in ~10 RTL lines in `tri27_decode.v`
2. Proven by 3 of the 84 Coq theorems (R-SI-1 subfamily)
3. Fully synthesisable — maps to `sg13g2_stdcell` AND/OR/NAND gates identically to SKY130A

The cell names change; the logic function is identical. The Coq proof is over the RTL
semantics, not over any gate-level implementation. Therefore R-SI-1 holds on IHP26b
by construction, and no additional proof work is required for the port.

---

*Document prepared for Trinity TRI-NET IHP26b roadmap — Q4 2026 target.*  
*Invariants: R-SI-1 · φ-anchor 0x47C0 · v1.0.0 AI formats (Claude Opus 4.6)*  
*Open-process only. No closed PDK. No foundry NDA required.*
