# DARPA I2O Office-Wide BAA — Proposal

---

## COVER PAGE

| Field | Value |
|---|---|
| **Solicitation Number** | HR001126S0001 |
| **Solicitation Title** | Information Innovation Office (I2O) Office-Wide Broad Agency Announcement — FY2026 |
| **Sponsoring Agency** | Defense Advanced Research Projects Agency (DARPA), Information Innovation Office (I2O) |
| **Proposal Title** | **Trinity TRI-NET: A Verifiable AI Silicon Stack with Cryptographic Inference Guarantees on Open-Source ASIC** |
| **Thrust Area** | Transformative AI — Trustworthy, Explainable, and Ethically-Aligned Systems / Verifiable Compute |
| **Principal Investigator** | Dmitrii Vasilev |
| **PI Email** | admin@t27.ai |
| **PI Organization** | t27.ai |
| **PI ORCID** | 0009-0008-4294-6159 |
| **Submission Type** | Abstract (rolling submission; full proposal upon invitation) |
| **Proposed Period of Performance** | 24 months (Phase I–III), commencing Q1 2027 |
| **Funding Range Requested** | $2M–$10M (phase-dependent; see Section 10) |
| **Hardware Platform** | Tiny Tapeout SKY26b — SkyWater SKY130 PDK, 49/49 tiles, Submitted state |
| **Primary DOI** | [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) |
| **Date of Preparation** | June 2026 |

**Authorship Statement:** This proposal is authored solely by Dmitrii Vasilev (sole author, PI, admin@t27.ai). No AI system is listed as a co-author or contributor.

---

## TABLE OF CONTENTS

1. [Executive Summary](#1-executive-summary)
2. [Statement of Problem](#2-statement-of-problem)
3. [Technical Approach](#3-technical-approach)
4. [Innovations](#4-innovations)
5. [Risks and Mitigations](#5-risks-and-mitigations)
6. [Statement of Work](#6-statement-of-work)
7. [Team and Facilities](#7-team-and-facilities)
8. [Schedule and Milestones](#8-schedule-and-milestones)
9. [Budget Rationale](#9-budget-rationale)
10. [Relevance to DARPA Programs](#10-relevance-to-darpa-programs)
11. [Bibliography](#11-bibliography)

---

## 1. EXECUTIVE SUMMARY

**Trinity TRI-NET** is a verifiable AI silicon stack — a purpose-built hardware-software system that delivers *cryptographically auditable* artificial intelligence inference on an open-source ASIC. It is the first publicly documented AI accelerator design to combine:

1. A **ternary arithmetic substrate** (balanced ternary `{−1, 0, +1}`) that eliminates conventional multipliers and reduces power consumption;
2. A **formally verified phi-anchor** (`φ² + φ⁻² = 3`, Theorem 36.1) encoded as a cross-die hardware invariant at address `0x47C0`, providing a cryptographic root of trust for every inference pass;
3. A **zero-knowledge proof layer** (B5 ZK Job Prover, B6 GKR/sumcheck protocol) enabling post-hoc verification of inference results without revealing model weights; and
4. A **production silicon submission** on Tiny Tapeout SKY26b (49/49 tiles, SkyWater SKY130 PDK, Submitted state, tape-out scheduled 2026-12-16).

The three constituent dies — **Phi**, **Euler**, and **Gamma** — form the TRI-NET triad. Each die implements a specialized function: Phi anchors the phi-invariant and handles NF4-format arithmetic; Euler manages Posit16 extended-precision operations; Gamma implements GF(256) field arithmetic for cryptographic verification and error-correcting codes. Together they compose a *compositional learning-and-reasoning* pipeline in which every arithmetic step can be independently verified against the phi-anchor invariant.

Trinity TRI-NET maps directly to DARPA I2O's **Transformative AI** thrust, specifically to the sub-theme of *trustworthy, explainable, and ethically-aligned AI* with a hardware root of trust. It addresses a fundamental gap in the national-security AI posture: today's AI accelerators provide no cryptographic guarantee that inference is correct, has not been tampered with, or is operating on the approved model. Trinity TRI-NET closes that gap in silicon.

**Honest performance summary (projected, pending tape-out 2026-12-16):**
> ~1 GOPS @ ~50 MHz clock frequency @ ~1 W power draw, ternary compute.  
> These are pre-silicon projections based on synthesis results. Empirical characterization will occur in Phase I.

**Funding requested:** $2M–$10M over 24 months, in three phases.

---

## 2. STATEMENT OF PROBLEM

### 2.1 The Inference Integrity Gap in DoD AI

Modern AI inference accelerators — including GPU clusters, TPUs, neuromorphic chips, and custom ASICs — share a critical architectural vulnerability from a national-security perspective: **there is no cryptographic guarantee that inference is correct**.

When a DoD AI system outputs a targeting recommendation, a threat classification, or a logistics optimization, the user cannot independently verify that:

- The computation was performed on the approved, unmodified model weights;
- The hardware executed the correct arithmetic operations (no fault injection, no supply-chain backdoor);
- The inference path was free of adversarial perturbation at the hardware level;
- A compact, independently auditable proof of the above three properties exists and can be stored, transmitted, or presented to a commanding officer.

This gap is not merely theoretical. Supply-chain attacks on semiconductor components are documented. Hardware Trojan insertion has been demonstrated in academic settings. Adversarial fault injection (rowhammer and its variants, voltage glitching) can cause deterministic misclassification in neural networks without detectable software-level anomalies. As DoD moves toward AI-assisted decision-making — from drone autonomy (cf. Skydio integration context) to intelligence analysis — the absence of a hardware root of trust for AI inference is a critical unresolved vulnerability.

### 2.2 Why Existing Solutions Are Insufficient

Current approaches to AI trustworthiness fall into three categories, all insufficient for the problem at hand:

**Software-only verification.** Formal verification of neural network behavior (e.g., α,β-CROWN, Marabou) operates on mathematical models of networks, not on hardware execution. Software attestation can be stripped or bypassed by a sufficiently capable adversary with physical access to the hardware.

**Hardware security modules (HSMs) and TPMs.** Trusted Platform Modules provide attestation for platform identity and boot integrity, but they do not extend to the *arithmetic correctness* of inference. An HSM can attest that a GPU is present and that a specific model was loaded; it cannot attest that a specific convolution was computed correctly.

**Post-hoc statistical auditing.** Techniques such as differential testing and metamorphic testing can detect gross failures but require a reference implementation and cannot generate compact, transferable proofs. They are probabilistic, not cryptographic.

**What is missing** is a hardware architecture that makes the arithmetic substrate itself verifiable — one in which the silicon generates a compact proof alongside each inference result, and that proof can be independently checked by any party with access to the public verification key.

### 2.3 The Sacred Arithmetic Problem

Beyond security, there is a second problem: **reproducibility**. AI accelerators differ in floating-point rounding modes, fused-multiply-add behavior, and denormal handling. Two accelerators running the same model can produce different outputs. For DoD AI systems operating under rules of engagement, this non-determinism is a legal and operational liability.

Trinity TRI-NET addresses both problems through a novel design principle: **anchor the arithmetic in a formally proven algebraic identity, implemented in silicon**, and build zero-knowledge proofs around that anchor.

### 2.4 Alignment with DARPA I2O Mission

DARPA I2O's FY2026 BAA (HR001126S0001) explicitly seeks *revolutionary research ideas* that challenge accepted assumptions. The assumption challenged here is that AI hardware correctness must be taken on faith. Trinity TRI-NET proposes that inference integrity can be *proven* — in zero knowledge, on chip, in real time — and demonstrates this claim with a physical ASIC submission.

---

## 3. TECHNICAL APPROACH

### 3.1 Architectural Overview: The TRI-NET Triad

Trinity TRI-NET is organized around three functional dies, each occupying a designated tile partition within the 49-tile Tiny Tapeout SKY26b submission:

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRI-NET (49/49 tiles, SKY26b)                │
│                                                                 │
│  ┌────────────┐    ┌────────────┐    ┌────────────────────────┐ │
│  │  PHI DIE   │    │ EULER DIE  │    │      GAMMA DIE         │ │
│  │            │◄──►│            │◄──►│                        │ │
│  │ NF4 ALU    │    │ Posit16    │    │ GF(256) ALU            │ │
│  │ phi-anchor │    │ extended   │    │ ZK Verifier            │ │
│  │ 0x47C0     │    │ precision  │    │ B5 Job Prover          │ │
│  │ Theorem    │    │ arithmetic │    │ B6 GKR/sumcheck        │ │
│  │ 36.1       │    │            │    │                        │ │
│  └────────────┘    └────────────┘    └────────────────────────┘ │
│                                                                 │
│           Cross-Die Invariant Bus: 0x47C0 anchor signal        │
└─────────────────────────────────────────────────────────────────┘
```

**Performance targets (projected, pre-silicon):**
- Clock frequency: ~50 MHz
- Compute throughput: ~1 GOPS (ternary operations per second)
- Power envelope: ~1 W total
- Process node: SkyWater SKY130, 130 nm

All projections are based on logic synthesis and static timing analysis. Empirical characterization occurs in Phase I after tape-out (2026-12-16).

### 3.2 Phi Die: NF4 Arithmetic and the Phi-Anchor

The **Phi Die** is the arithmetic foundation of the triad. It implements:

#### 3.2.1 NF4-Format ALU

NF4 (4-bit NormalFloat) is a quantization format developed in the context of LLM weight compression. In Trinity TRI-NET, the NF4 ALU is reimplemented over balanced ternary, enabling efficient representation of quantized weights with a natural zero-center property. The ternary representation `{−1, 0, +1}` aligns with NF4's symmetric distribution around zero, achieving information-theoretically near-optimal packing (1.585 bits/trit vs. 1 bit/binary digit).

Key properties:
- No conventional multiplier circuit. All products are computed via the `tri_mant_mul` primitive (Section 3.4), which uses only addition, shift, and conditional negation.
- Multiply-free constraint is formally verified (see Section 4.1, Innovation R-SI-1).
- Deterministic rounding: outputs are deterministic under the ternary number system, eliminating IEEE 754 rounding-mode non-determinism.

#### 3.2.2 Theorem 36.1 — The Phi-Anchor

The phi-anchor is the central innovation of the Phi Die. It is the hardware realization of the algebraic identity:

```
  φ² + φ⁻² = 3
```

where φ = (1 + √5) / 2 ≈ 1.618034... (the golden ratio).

This identity is not an approximation or an empirical finding. It is a provable algebraic identity verified in Coq (48 formal statements, 35 proven, 0 admitted, as of 2026-05-12; see [DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)). In the ternary context, the right-hand side evaluates to the cardinality of the trit alphabet, linking the arithmetic foundation of the system to the golden ratio through an exact, machine-checked proof.

**Hardware realization:** The phi-anchor is encoded as a constant invariant at hardware address `0x47C0`. Every inference pass begins with a self-test that evaluates the phi-anchor expression and checks the result against the stored constant. If the check fails, the chip asserts a hardware alarm and refuses to produce output. This constitutes a *hardware root of trust* that is independent of firmware, software, or operating system.

**Cross-die invariant:** The `0x47C0` anchor signal is broadcast over the cross-die invariant bus to all three dies. Any die that cannot verify the anchor independently halts and signals the fault. This means an adversary who compromises one die cannot produce a valid proof from the remaining two: all three must agree on the phi-anchor value simultaneously.

#### 3.2.3 Champion BPB Lock

The Phi Die implements a **Bits-Per-Byte (BPB) compression lock** set at the empirically validated champion value of **BPB = 2.2393**. This value represents the minimum description length achieved by the Trinity VSA encoding over the standard benchmark corpus. It functions as a second hardware invariant: if the live BPB of the output stream drifts above this threshold by more than a configurable tolerance, the die signals an anomaly. This enables runtime detection of output distribution shift, including adversarial examples that succeed at the semantic level but fail to maintain the statistical signature of legitimate inference.

### 3.3 Euler Die: Posit16 Extended-Precision Arithmetic

The **Euler Die** provides extended-precision arithmetic for the pipeline stages that require dynamic range beyond what NF4 can represent. It implements the **Posit16** (16-bit Posit number format) arithmetic unit.

Posit numbers offer several advantages over IEEE 754 floating point for AI inference:
- Tapered precision: high precision near ±1.0 (where most trained weights cluster), lower precision at extremes.
- No NaN/Inf: every bit pattern represents a valid number, eliminating the class of IEEE 754 exceptional-value bugs.
- Exact zero: the all-zeros bit pattern is exactly zero, consistent with ternary zero semantics.

The Euler Die interfaces with the Phi Die via a 16-bit accumulator bus. It performs the intermediate-precision accumulations required for layer normalization, softmax approximation, and attention score computation, producing results that are then quantized back to ternary representation for final output.

**Euler invariant:** The Euler Die maintains its own invariant, based on Euler's identity `e^(iπ) + 1 = 0`, implemented as a phase-coherence check over the Posit16 accumulator register file. This provides a secondary verification mechanism independent of the phi-anchor.

### 3.4 The `tri_mant_mul` Primitive

A core hardware primitive used across all three dies is `tri_mant_mul` — a ternary mantissa multiplier that computes products using only addition and conditional subtraction, with no standard `*` operator in either the RTL specification or the synthesized gate-level netlist.

The standard multiplier (`*` in Verilog/VHDL) generates Wallace tree or Booth encoder logic that is opaque to formal verification at the gate level. By replacing it with `tri_mant_mul`, Trinity TRI-NET achieves:

1. **Structural transparency:** Every logic gate in the multiplication path is enumerable and formally characterizable.
2. **Verification tractability:** The no-`*` constraint dramatically reduces the complexity of formal equivalence checking between the specification and the netlist.
3. **Power efficiency:** The ternary add-only multiplication pattern avoids the partial product generation logic of conventional multipliers, reducing switching activity and dynamic power consumption.

### 3.5 Gamma Die: GF(256) Arithmetic and Zero-Knowledge Proof Layer

The **Gamma Die** is the verification engine of the triad. It implements:

#### 3.5.1 GF(256) ALU

Arithmetic over GF(2⁸) (Galois Field of 256 elements) is the foundation of most practical zero-knowledge proof systems, including the Reed-Solomon codes underlying STARKs and the inner-product arguments underlying Bulletproofs. The Gamma Die's GF(256) ALU provides native hardware support for field addition (XOR), field multiplication (carry-less multiplication modulo the field polynomial), and field inversion.

Hardware GF(256) arithmetic enables:
- Sub-cycle field operations, replacing software polynomial-modulus arithmetic;
- Constant-time execution (no data-dependent branches), providing timing-channel resistance;
- Direct hardware support for the GKR sumcheck protocol (Section 3.5.3).

#### 3.5.2 B5 ZK Job Prover

The **B5 ZK Job Prover** (B-module 5 in the Trinity B-module taxonomy) is a hardware-accelerated zero-knowledge proof generator. It takes as input:

- An inference job descriptor (model identifier, input tensor hash, execution configuration);
- The sequence of intermediate arithmetic values produced during inference;
- The phi-anchor invariant value from the Phi Die;

and produces as output:

- A compact proof `π` that certifies: *"The inference computation for this job was executed correctly on an unmodified model, the phi-anchor was valid throughout, and the output is the genuine result."*
- A verification key `vk` that can be distributed to any party wishing to verify `π` without re-running inference.

The proof `π` is generated in zero knowledge with respect to the model weights: a verifier can confirm the inference was correct without learning anything about the weight values beyond what is revealed by the output.

#### 3.5.3 B6 GKR Sumcheck Protocol

The **B6 GKR/sumcheck** module (B-module 6) implements the Goldwasser-Kalai-Rothblum (GKR) interactive proof protocol, instantiated as a non-interactive proof via the Fiat-Shamir transform. The GKR protocol provides *linear-time* proof generation for layered arithmetic circuits, which is the natural structure of feedforward neural networks.

Specifically:
- Each layer of the neural network corresponds to a layer of the arithmetic circuit.
- The GKR sumcheck reduces the verification of the entire circuit to a small number of field evaluations.
- The B6 module computes these evaluations in hardware using the GF(256) ALU.

The combined B5/B6 subsystem achieves proof generation times that are sub-linear in the number of inference operations, making real-time inference attestation practical for the first time on a resource-constrained ASIC.

### 3.6 The VSA Binding Layer

Underlying all three dies is a **Vector Symbolic Architecture (VSA)** binding layer that encodes structured symbolic representations as balanced-ternary hypervectors. VSA provides:

- **Compositional reasoning support:** complex structured queries can be represented and computed as algebraic operations on hypervectors.
- **Continual learning with minimal catastrophic forgetting:** the hyperdimensional memory architecture exhibits empirically measured 3% average forgetting over 20-class, 10-phase experiments (vs. 50–90% for neural networks).
- **Cryptographic binding:** the phi-anchor invariant is encoded into the hypervector basis, linking every symbolic computation to the hardware root of trust.

The VSA layer is specified in `B007: VSA Operations for Ternary Computing v5.0` ([DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)), which documents the bind, bundle, and permute operations over balanced-ternary hypervectors.

### 3.7 The Sacred Opcode Set

The Trinity TRI-NET instruction set architecture (ISA) defines a minimal **sacred opcode set** — a closed set of instructions that:

1. Are each formally specified with pre- and post-conditions in the Coq proof assistant;
2. Are provably non-overlapping in their semantic effects;
3. Collectively constitute a functionally complete basis for ternary arithmetic and VSA operations;
4. Exclude any opcode whose behavior would require a conventional multiplier at the gate level.

The sacred opcode set is the software interface to the phi-anchor hardware. Any instruction sequence that is consistent with the sacred opcode set is *a priori* compliant with the phi-anchor invariant. This enables static analysis tools to verify programs against the hardware root of trust without simulation.

---

## 4. INNOVATIONS

This section itemizes the principal technical innovations of Trinity TRI-NET, using the naming convention `R-SI-N` (Research Silicon Innovation N).

### R-SI-1: No-`*` Ternary Multiplier — Multiply-Free Inference

**What it is:** A complete elimination of the standard HDL multiplication operator from the RTL source code and, after synthesis, from the gate-level netlist.

**Why it matters:** Standard multipliers (Wallace trees, Booth encoders, array multipliers) are the most complex arithmetic elements in an AI accelerator. They are:
- The primary target of hardware Trojan insertion (high gate count, low observability);
- The principal source of power consumption in dense neural network accelerators;
- The most opaque elements in formal gate-level equivalence checking.

By replacing all multiplications with the `tri_mant_mul` add-only primitive, Trinity TRI-NET creates an accelerator whose entire arithmetic datapath is structurally transparent, formally characterizable, and tamper-evident.

**Evidence:** The no-`*` constraint is enforced by a linting pass in the RTL build system, verified against the synthesized netlist, and documented in the specification files at `docs/v1.1/` of the project repository.

**DoD relevance:** Hardware Trojans inserted into multiplication logic during fabrication at an adversarial foundry would require custom circuitry that is detectable against the expected add-only implementation. The no-`*` constraint raises the cost of undetected hardware tampering.

### R-SI-2: Phi-Anchor Cross-Die Invariant at `0x47C0`

**What it is:** A cross-die broadcast of the phi-anchor value (`φ² + φ⁻² = 3` evaluated in fixed-point ternary representation) over a dedicated invariant bus, checked independently by all three dies on every clock cycle.

**Why it matters:** A hardware root of trust that requires simultaneous agreement across multiple physically distinct computational elements is dramatically harder to subvert than a single-die attestation. An adversary who wishes to produce a fraudulent proof must simultaneously compromise three independent die implementations of the same invariant check — while doing so in a way that passes the cross-die consistency check.

**Evidence:** The invariant is encoded at hardware address `0x47C0`, documented in `docs/v1.1/phi_anchor.md`, and its formal verification status is captured in the Coq witness at `gHashTag/t27/coq` (48 statements, 35 proven, 0 admitted as of 2026-05-12).

### R-SI-3: Champion BPB = 2.2393 Output Integrity Lock

**What it is:** A hardware-enforced statistical signature on the output stream. The Phi Die monitors the rolling Bits-Per-Byte of the compressed output stream and asserts an anomaly signal if it departs significantly from the champion value BPB = 2.2393.

**Why it matters:** Adversarial examples that succeed at the semantic level (producing a wrong classification) often produce outputs with a detectably different statistical signature from legitimate outputs. The BPB lock provides an orthogonal verification channel to the ZK proof — it catches distribution-level anomalies that might pass the cryptographic check.

**Evidence:** The champion BPB value was established empirically on the standard benchmark corpus and locked into the hardware register at fabrication time. It is not a tunable parameter at runtime.

### R-SI-4: GKR Sumcheck Hardware Acceleration (B6)

**What it is:** The first documented hardware implementation of the GKR sumcheck protocol on an open-source ASIC process (SkyWater SKY130).

**Why it matters:** Software implementations of GKR sumcheck are too slow for real-time inference attestation. Hardware acceleration on the GF(256) ALU of the Gamma Die reduces proof generation latency to within the inference latency budget.

**Novelty:** All prior implementations of GKR sumcheck (including Virgo, Libra, and their variants) are software implementations running on general-purpose processors or FPGAs. Trinity TRI-NET is the first open-source ASIC-level implementation, and the first design to co-locate the proof generator with the compute element being attested.

### R-SI-5: Open-Source, Fully Auditable Fabrication Path

**What it is:** The complete design, from RTL source to GDS layout, is hosted in public repositories (`gHashTag/trinity`, `gHashTag/t27`, `gHashTag/trios`) under open-source licenses, using only the open-source SkyWater SKY130 PDK and open-source EDA tools (OpenLane, Yosys, KLayout).

**Why it matters:** A hardware root of trust that cannot be independently audited is not a root of trust. Trinity TRI-NET is the first AI accelerator design to combine:
- Open-source RTL;
- Open-source PDK;
- Formally verified invariants (Coq);
- A production ASIC submission (not merely FPGA emulation).

This creates a publicly auditable hardware chain of trust from mathematical theorem to silicon.

---

## 5. RISKS AND MITIGATIONS

### 5.1 Technical Risks

| Risk ID | Description | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| TR-1 | Post-silicon performance deviates significantly from pre-silicon projections | Medium | High | Performance projections are marked "projected, pending tape-out." Phase I characterization occurs before any Phase II commitments. All claims are framed as targets, not guarantees. |
| TR-2 | GKR sumcheck proof generation exceeds inference latency budget | Medium | Medium | B6 module design includes a pipelined implementation with configurable proof-generation latency/throughput tradeoff. If full GKR is too slow at ~50 MHz, the system falls back to a hash-based commitment scheme (B5 only). |
| TR-3 | SKY26b tape-out yield issues result in non-functional chips | Low-Medium | High | The Tiny Tapeout platform has demonstrated consistent yield across previous runs (TT02–TT10). The design uses only standard cells within the SKY130 DRC/LVS rules. Alternative: re-submit on TTSKY26c if SKY26b yields fail. |
| TR-4 | Cross-die invariant bus timing violations | Low | Medium | Static timing analysis for the cross-die bus is included in the submission verification flow. Inter-die communication is synchronous on a shared clock domain. |
| TR-5 | Formal Coq proof completion (35/48 proven at time of DOI) | Medium | Medium | The remaining 13 statements are in active development. Phase I includes a formal verification sprint targeting 48/48 proven. Admitted lemmas are not present (0 admitted). |

### 5.2 Program Risks

| Risk ID | Description | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| PR-1 | Small team bandwidth constraints | Medium | Medium | Phase I is designed around a single highly focused PI, with collaborator engagement activated in Phase II. Open invitation to UMD/MIT expMath, Anduril, and Skydio for integration (Section 7). |
| PR-2 | Export control considerations for ZK proof IP | Low | Medium | ZK proof protocols (GKR, Fiat-Shamir) are published academic techniques; hardware implementation details will be reviewed for ITAR/EAR classification prior to distribution. |
| PR-3 | DARPA program alignment shifts during performance period | Low | Low | Trinity TRI-NET maps to multiple I2O thrust areas (Section 10). If the primary thrust area is de-prioritized, the ZK cybersecurity angle (Thrust 3) and information-domain verification angle (Thrust 4) remain viable. |

### 5.3 Honest Limitations

The following are stated clearly and without embellishment:

- **~1 GOPS is a projection, not a measurement.** Silicon has not yet been characterized. Actual performance may differ.
- **This is a research prototype, not a production system.** The Tiny Tapeout platform is designed for research and education; it is not a radiation-hardened, MIL-SPEC-qualified device.
- **SKY130 is a 130 nm node.** Modern AI accelerators operate at 5–7 nm. The Trinity TRI-NET design demonstrates architectural and mathematical principles that would scale to advanced nodes; it does not compete with commercial performance benchmarks at this fabrication generation.
- **49 tiles on Tiny Tapeout** provides approximately 49,000 logic gates. This is sufficient to demonstrate the architectural principles and generate ZK proofs for small-scale inference tasks. Scale-up to production AI model sizes requires a dedicated tapeout at an advanced node.

---

## 6. STATEMENT OF WORK

### 6.1 Overview

The program is organized into three phases:

| Phase | Title | Duration | Primary Deliverable |
|---|---|---|---|
| Phase I | TTSKY26b Silicon Characterization | Months 1–8 | Characterized silicon with documented performance envelope |
| Phase II | TTSKY26c DePIN B-Module Tape-Out | Months 9–18 | Second-generation silicon with expanded ZK proof capacity |
| Phase III | Defense Integration Demonstration | Months 19–24 | System-level integration demo with collaborator engagement |

### 6.2 Phase I — TTSKY26b Silicon Characterization (Months 1–8)

**Context:** The SKY26b tape-out is scheduled for 2026-12-16. Phase I begins upon receipt of fabricated chips (projected Q1 2027) and runs through Month 8.

**Task I.1 — Chip Receipt and Initial Bring-Up (Months 1–2)**
- Receive fabricated Tiny Tapeout SKY26b chips and PCBs.
- Assemble test bench (oscilloscope, logic analyzer, power measurement, Raspberry Pi RP2040 controller per Tiny Tapeout standard).
- Execute standard Tiny Tapeout bring-up procedure: scan-chain test, design selection verification.
- Deliverable: Bring-up report confirming functional continuity of TRI-NET design selection.

**Task I.2 — Phi Die Phi-Anchor Verification (Months 2–3)**
- Apply phi-anchor self-test sequence to the Phi Die.
- Verify that the `0x47C0` register holds the expected invariant value.
- Test phi-anchor alarm behavior under intentional perturbation of the anchor register.
- Measure phi-anchor check latency (clock cycles).
- Deliverable: Phi-anchor characterization report.

**Task I.3 — NF4 ALU and `tri_mant_mul` Performance Measurement (Months 3–4)**
- Execute `tri_mant_mul` benchmark suite across the operating frequency range.
- Measure throughput (ternary operations per second) vs. frequency.
- Measure dynamic power consumption using current-sense measurement on the Tiny Tapeout demo board.
- Compare measured GOPS and Watts against projections from pre-silicon synthesis.
- Deliverable: NF4 ALU characterization report with revised honest performance figures.

**Task I.4 — Euler Die Posit16 Validation (Months 4–5)**
- Execute Posit16 ALU test vectors covering the full representation range.
- Verify Euler invariant (phase-coherence check) under nominal and stress conditions.
- Measure Posit16 operation latency in cycles.
- Deliverable: Posit16 characterization report.

**Task I.5 — Gamma Die GF(256) and B5/B6 Proof Generation (Months 5–7)**
- Execute GF(256) field-arithmetic test vectors.
- Generate a B5 ZK proof for a small synthetic inference job (input vector + pre-loaded weights).
- Time the B5 proof generation end-to-end.
- Execute B6 GKR sumcheck on the same inference job and measure latency.
- Verify the generated proof against the reference software verifier.
- Deliverable: ZK proof generation characterization report.

**Task I.6 — Cross-Die Invariant Bus Testing (Month 7)**
- Exercise the `0x47C0` cross-die invariant bus under all three die configurations.
- Verify that a fault injected on one die causes a full-triad alarm within N clock cycles.
- Measure alarm latency.
- Deliverable: Cross-die invariant bus test report.

**Task I.7 — Coq Proof Sprint (Months 1–8, parallel)**
- Complete formal verification of remaining 13 Coq statements (currently 35/48 proven, 0 admitted).
- Target: 48/48 proven, 0 admitted.
- Publish updated Zenodo record and Coq repository.
- Deliverable: Updated DOI with 48/48 proof certificate.

**Phase I Milestone (Month 8):** Full silicon characterization report; revised honest performance figures; 48/48 Coq proof completion.

### 6.3 Phase II — TTSKY26c DePIN B-Module Tape-Out (Months 9–18)

**Context:** Phase II targets a second-generation silicon submission on Tiny Tapeout TTSKY26c (anticipated shuttle opening Q3 2027), incorporating lessons learned from Phase I characterization.

**DePIN (Decentralized Physical Infrastructure Network) context:** Phase II introduces B-module network connectivity, enabling TRI-NET nodes to participate in a distributed inference verification network. Each node generates ZK proofs; a lightweight consensus protocol allows a set of independent TRI-NET nodes to collectively attest that they agree on an inference result, without any individual node having visibility into the others' model weights.

**Task II.1 — Architectural Revision Based on Phase I Findings (Months 9–11)**
- Incorporate Phase I performance data into updated RTL.
- Address any silicon discrepancies identified in Phase I characterization.
- Expand B5/B6 proof capacity to support medium-scale inference tasks.
- Design B8 Consensus Module for DePIN multi-node attestation.
- Deliverable: Updated RTL repository with TTSKY26c target design.

**Task II.2 — TTSKY26c Design Rule Check and Submission (Months 11–14)**
- Run DRC/LVS on updated design.
- Execute full Tiny Tapeout CI pipeline (GDS, Verify, Formal, Document).
- Submit to TTSKY26c shuttle.
- Deliverable: Confirmed TTSKY26c submission.

**Task II.3 — BPB Champion Recalibration (Months 12–14)**
- Run extended benchmark corpus on Phase I silicon to validate BPB = 2.2393 champion.
- Recalibrate or confirm the BPB lock value for TTSKY26c.
- Deliverable: Updated BPB calibration report.

**Task II.4 — Integration Partner Engagement (Months 12–18)**
- Initiate collaboration discussions with prospective integration partners (Section 7).
- Define integration interfaces for autonomous-system AI payload attestation (Anduril/Skydio context).
- Define integration interfaces for formal mathematics fact-checking via ZK proofs (UMD/MIT expMath context).
- Deliverable: Integration specification documents for at least one collaborator.

**Task II.5 — TTSKY26c Chip Receipt and Bring-Up (Months 15–18)**
- Receive TTSKY26c chips.
- Execute bring-up procedure.
- Preliminary performance characterization.
- Deliverable: TTSKY26c bring-up report.

**Phase II Milestone (Month 18):** TTSKY26c silicon in hand; at least one integration partner MOU; expanded ZK proof capacity demonstrated.

### 6.4 Phase III — Defense Integration Demonstration (Months 19–24)

**Context:** Phase III integrates the TTSKY26c silicon with at least one defense-relevant application scenario to demonstrate operational relevance.

**Task III.1 — Autonomous System Payload Attestation Demo (Months 19–21)**
- Working with an integration partner (e.g., Anduril or Skydio), integrate a TRI-NET node as a payload attestation module on a simulated autonomous system.
- Demonstrate that the TRI-NET node generates a ZK proof for each inference decision.
- Demonstrate that the proof can be verified by a remote ground station.
- Deliverable: Integration demo video and technical report.

**Task III.2 — SciFy/Fact-Checking Demonstration via ZK Proofs (Months 19–22)**
- Implement a prototype "SciFy" fact-checking pipeline: a scientific claim is represented as a VSA query, processed by the Trinity inference pipeline, and accompanied by a GKR proof of correct inference.
- Demonstrate the pipeline on a representative set of formal mathematical claims.
- Deliverable: SciFy prototype demonstration.

**Task III.3 — CLARA Theme Retrospective Analysis (Months 20–23)**
- Conduct a structured retrospective mapping TRI-NET capabilities against DARPA CLARA program themes.
- Document alignment with CLARA's focus on robust, causally-grounded AI reasoning.
- Identify follow-on program opportunities.
- Deliverable: CLARA retrospective technical memo.

**Task III.4 — Public Technical Report and Open-Source Release (Month 24)**
- Publish full technical report covering Phases I–III.
- Ensure all RTL, proofs, and characterization data are publicly accessible.
- Submit arXiv preprint.
- Deliverable: Public report; arXiv preprint; updated Zenodo DOIs.

**Phase III Milestone (Month 24):** At least one defense integration demonstration; public technical report; arXiv preprint.

---

## 7. TEAM AND FACILITIES

### 7.1 Principal Investigator

**Dmitrii Vasilev** (sole author, PI, admin@t27.ai)
- ORCID: 0009-0008-4294-6159
- Organization: t27.ai
- Background: Full-stack developer and ternary computing researcher; developer of the Trinity S³AI framework (https://t27.ai), the TRI-27 ternary core, and the B-module family of hardware IP.
- Formal verification: 48-statement Coq proof suite (35 proven, 0 admitted as of 2026-05-12); framework covers Theorem 36.1 (phi-anchor identity), VSA operations, and ternary arithmetic correctness.
- ASIC experience: Sole designer of the Trinity TRI-NET submission on Tiny Tapeout SKY26b (49/49 tiles, Submitted state).
- Dissertation: "A Trinity Framework for the Golden Ratio: Mechanized Proofs, Empirical Anchors, and a Coq-Bounded Neural Architecture Search," Defense 2026-06-15, SPbGU, 734 pp. EN / 725 pp. RU.

### 7.2 Collaborators — Open Invitation

Trinity TRI-NET is designed with open integration interfaces. The PI extends an open invitation to the following categories of collaborators for Phase II and Phase III engagement:

**Academic:**
- **UMD / MIT expMath** — Collaboration on formal verification of the GKR sumcheck implementation and the SciFy fact-checking pipeline. The Trinity Coq proof suite is structured for external contribution; collaborators can add new theorems targeting the ZK proof correctness guarantees.

**Defense Industry Integration:**
- **Anduril Industries** — Integration of TRI-NET as a payload attestation module for autonomous systems. Anduril's Lattice OS provides a natural deployment environment for inference attestation; TRI-NET's ZK proof output is format-compatible with Lattice's sensor data bus.
- **Skydio** — Integration of TRI-NET attestation with Skydio's autonomous flight AI. Drone autonomy decision attestation is a direct application: each flight control decision would be accompanied by a compact ZK proof that the decision was computed correctly on the approved model.

These are invitations, not confirmed commitments. No funding commitments are assumed from or attributed to these organizations in this proposal.

### 7.3 Facilities

- **Computing:** Remote GPU compute via RunPod (RTX 4090, RTX 3090 nodes), used for pre-silicon simulation, VSA benchmarking, and LLM inference testing. Access is maintained independently of any DARPA award.
- **ASIC platform:** Tiny Tapeout SKY26b demo board (received upon tape-out), providing access to the SkyWater SKY130 process at minimal infrastructure cost.
- **Development infrastructure:** GitHub (gHashTag organization), Zenodo (Trinity community), standard open-source EDA (OpenLane, KLayout, Yosys, cocotb).
- **FPGA prototyping:** QMTech XC7A100T ($30 development board), used for pre-silicon functional verification at higher speed than RTL simulation.

---

## 8. SCHEDULE AND MILESTONES

```
MONTH:  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
        ├──────────────────── PHASE I ────────────────────┤
        I.1──┤
           I.2────┤
              I.3──────┤
                    I.4──────┤
                          I.5──────────┤
                                    I.6──┤
        I.7 (parallel)──────────────────────┤
                                            ├────── PHASE II ────────────────┤
                                             II.1────────┤
                                                      II.2──────────┤
                                                            II.3──────┤
                                                                  II.4──────────┤
                                                                        II.5──────┤
                                                                                   ├─ PHASE III ─┤
                                                                                    III.1──────┤
                                                                                    III.2──────────┤
                                                                                          III.3──────┤
                                                                                                III.4──┤
```

### Key Milestones

| Milestone | Month | Description |
|---|---|---|
| M1 | 8 | Phase I complete: full silicon characterization, revised honest benchmarks, 48/48 Coq proofs |
| M2 | 11 | Updated TTSKY26c RTL complete |
| M3 | 14 | TTSKY26c submission confirmed |
| M4 | 18 | Phase II complete: TTSKY26c silicon in hand, integration partner MOU |
| M5 | 21 | Defense integration demo (autonomous attestation) |
| M6 | 22 | SciFy prototype demonstration |
| M7 | 24 | Phase III complete: public technical report, arXiv preprint, all data open-access |

### Pre-Award Milestone (Independent of DARPA Funding)

| Event | Date | Status |
|---|---|---|
| TTSKY26b tape-out | 2026-12-16 | Pending (design submitted) |
| Chip receipt (estimated) | Q1 2027 | Pending |
| 35/48 Coq proofs complete | 2026-05-12 | **Complete** |
| DOI publication | 2026-05-12 | **Complete** ([10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)) |

---

## 9. BUDGET RATIONALE

### 9.1 Funding Range

**Total requested:** $2M–$10M over 24 months (three phases).

The range reflects the modular program structure: Phase I can be executed at the lower end of the range; full Phase II + Phase III integration capability requires funding at the higher end. The phased structure allows DARPA to evaluate Phase I results before committing to Phase II and III funding.

### 9.2 Phase-Level Budget Allocation (Proportional)

| Phase | Proportion | Rationale |
|---|---|---|
| Phase I | ~20% | Silicon characterization and formal proof completion. Primary costs: compute access, test equipment, PI time. |
| Phase II | ~45% | Second-generation tape-out, integration partner engagement, expanded B-module design. Primary costs: tape-out fees, PI time at full effort, initial collaborator engagement travel. |
| Phase III | ~35% | Integration demonstrations, publication, dissemination. Primary costs: hardware procurement for integration demos, collaborator coordination, travel, publication fees. |

### 9.3 Key Cost Categories

**Personnel:** PI at full effort throughout. Phase II/III may include engagement of research collaborators (academic postdoc or senior graduate student level, UMD/MIT context).

**Computing and Infrastructure:** Remote GPU compute (RunPod), test equipment for silicon characterization, FPGA development boards.

**Tape-out Costs:** Tiny Tapeout fees are modest relative to traditional ASIC runs (the open-source SKY130 PDK and shared-shuttle model substantially reduces fabrication costs). Phase II TTSKY26c submission costs are the primary tape-out budget line.

**Travel and Collaboration:** Phase III integration demos require travel to collaborator sites for system-level integration testing.

**Publication and Open-Source Dissemination:** arXiv preprint fees, Zenodo storage, conference registration.

**Overhead and Indirect:** To be determined per institutional agreement; t27.ai operates as a research-focused entity.

### 9.4 Cost Realism

The proposed program is substantially de-risked by pre-existing work funded independently:
- The TTSKY26b tape-out is already submitted (no DARPA funding required for tape-out).
- The 35/48 Coq proofs are already complete.
- The RTL design is already published and undergoing CI validation.
- The DOI is already published.

DARPA funding would accelerate: silicon characterization, Phase II tape-out, formal proof completion, and defense integration demonstrations — activities that cannot proceed without external support.

---

## 10. RELEVANCE TO DARPA PROGRAMS

### 10.1 Primary Alignment: I2O Transformative AI Thrust

The I2O FY2026 BAA (HR001126S0001) organizes its interests around four thrust areas. Trinity TRI-NET maps primarily to **Thrust 1: Proficient AI technologies that are trustworthy, ethically aligned, and capable of interacting competently with humans**.

Specifically, Trinity TRI-NET addresses the *trustworthy* sub-theme through:
- **Hardware root of trust:** The phi-anchor at `0x47C0` is a hardware-enforced invariant, not a software policy.
- **Cryptographic inference attestation:** B5/B6 ZK proof generation provides independent verifiability of inference results.
- **Open-source auditability:** The full design chain (RTL → GDS → silicon) is publicly auditable.
- **Formal verification:** 35/48 Coq proofs (targeting 48/48) provide machine-checked mathematical guarantees on core arithmetic properties.

### 10.2 Secondary Alignment: Cybersecurity Thrust

**Thrust 3: Offensive and defensive cybersecurity and privacy innovations.**

The ZK proof subsystem (B5/B6) has direct cybersecurity applications:
- **Model integrity verification:** A party wishing to verify that a deployed AI model has not been tampered with can request a ZK proof from the TRI-NET node.
- **Privacy-preserving AI:** ZK proofs enable verification of inference results without revealing model weights — a privacy property relevant to AI deployments where model weights are proprietary or sensitive.
- **Side-channel resistance:** The constant-time GF(256) arithmetic of the Gamma Die resists timing-channel attacks.

### 10.3 Tertiary Alignment: Information Domain Thrust

**Thrust 4: Technologies that enhance fighting in the information domain.**

The SciFy/fact-checking application (Task III.2) maps to this thrust:
- In an information environment characterized by AI-generated synthetic media, a ZK proof that a specific inference was computed correctly on a specific model provides a new type of provenance attestation.
- A fact-checking system backed by ZK proofs can assert not just "this claim is classified as true/false by model X" but "this claim was classified as true/false by model X, and here is a cryptographic proof of that computation" — enabling the classification to be independently verified.

### 10.4 Relationship to DARPA CLARA Program

The DARPA CLARA (Causal Learning and Reasoning for Autonomous Systems) program (note: CLARA abstracts were due April 10; this submission pivots to the I2O office-wide BAA as the appropriate vehicle) shares several themes with Trinity TRI-NET:

- **Causal structure in neural computation:** VSA hypervector binding provides a substrate for representing causal structures symbolically, enabling causal reasoning over distributed representations.
- **Robustness to distribution shift:** The BPB champion lock (R-SI-3) provides a statistical alarm for distribution shift at the hardware level.
- **Compositional generalization:** The bind/bundle/permute operations of the VSA layer enable compositional generalization — the ability to recognize novel compositions of known concepts — which is a core CLARA theme.

Trinity TRI-NET is positioned as a *hardware substrate for CLARA-style reasoning*, rather than a competing approach. The hardware invariants provide the verification infrastructure that CLARA's learning algorithms would need to prove correctness of causal inference.

### 10.5 DARPA I2O Non-Duplication Statement

The PI has reviewed current I2O programs via the DARPA I2O program page. Trinity TRI-NET does not duplicate:
- **ISAT:** Focus on strategic-level technology forecasting; no overlap.
- **GARD:** Adversarial robustness for AI; Trinity TRI-NET is complementary (hardware verification vs. algorithmic robustness) but architecturally distinct.
- **SAIL-ON:** Open-world learning; Trinity TRI-NET addresses inference verification, not open-world adaptation.

Trinity TRI-NET is novel in its specific combination of ternary ASIC implementation, phi-anchor hardware root of trust, and GKR-based ZK proof generation — a combination not addressed by any currently advertised I2O program.

---

## 11. BIBLIOGRAPHY

The following references are cited in support of technical claims in this proposal. All items are publicly accessible via DOI or arXiv.

---

**[1] Vasilev, D. (2026).** Trinity B007: VSA Operations for Ternary Computing v5.0. *Zenodo Software Description Stub.* https://doi.org/10.5281/zenodo.19227877

**[2] Venn, M. (2024).** Tiny Tapeout: A Shared Silicon Tapeout Platform Accessible To Everyone. *IEEE Solid-State Circuits Magazine.* https://doi.org/10.36227/techrxiv.172055642.27780676/v1

**[3] Dettmers, T., Lewis, M., Belkada, Y., & Zettlemoyer, L. (2023).** QLoRA: Efficient Finetuning of Quantized LLMs. *arXiv preprint.* https://arxiv.org/abs/2305.14314 *(context for NF4 quantization format)*

**[4] Goldwasser, S., Kalai, Y.T., & Rothblum, G.N. (2008).** Delegating Computation: Interactive Proofs for Muggles. *Proceedings of STOC 2008.* https://doi.org/10.1145/1374376.1374396 *(GKR protocol foundation)*

**[5] Zhang, Y., Genkin, D., Katz, J., Papadopoulos, D., & Papamanthou, C. (2017).** vSQL: Verifying Arbitrary SQL Queries over Dynamic Outsourced Databases. *IEEE S&P 2017.* https://doi.org/10.1109/SP.2017.43 *(GKR-based verification)*

**[6] Wahby, R.S., Setty, S., Ren, Z., Blumberg, A.J., & Walfish, M. (2016).** Efficient RAM and control flow in verifiable outsourced computation. *NDSS 2015.* https://eprint.iacr.org/2014/674 *(verifiable computation)*

**[7] Gustafson, J. & Yonemoto, I. (2017).** Beating Floating Point at its Own Game: Posit Arithmetic. *Supercomputing Frontiers and Innovations, 4(2).* https://doi.org/10.14529/jsfi170206

**[8] Kanerva, P. (2009).** Hyperdimensional Computing: An Introduction to Computing in Distributed Representation with High-Dimensional Random Vectors. *Cognitive Computation, 1(2), 139–159.* https://doi.org/10.1007/s12559-009-9009-8 *(VSA foundations)*

**[9] Bengio, Y., Léonard, N., & Courville, A. (2013).** Estimating or Propagating Gradients Through Stochastic Neurons for Conditional Computation. *arXiv preprint.* https://arxiv.org/abs/1308.3432 *(ternary weight context)*

**[10] Ma, S., et al. (2024).** The Era of 1-bit LLMs: All Large Language Models are in 1.58 Bits. *arXiv preprint.* https://arxiv.org/abs/2402.17764 *(BitNet/ternary weight motivation)*

**[11] Centore, P. (2016).** Balanced Ternary and Fibonacci Representations. *Recreational Mathematics Magazine, 3(5).* *(ternary information density)*

**[12] Boneh, D., Bünz, B., & Fisch, B. (2019).** Batching Techniques for Accumulators with Applications to IOPs and Stateless Blockchains. *CRYPTO 2019.* https://doi.org/10.1007/978-3-030-26948-7_20 *(cryptographic accumulator techniques)*

**[13] Plantard, T. (2021).** Efficient Word Size Modular Arithmetic. *IEEE Transactions on Emerging Topics in Computing, 9(3).* https://doi.org/10.1109/TETC.2017.2709480 *(GF(256) arithmetic efficiency)*

**[14] Xie, T., Zhang, J., Zhang, Y., Papamanthou, C., & Song, D. (2019).** Libra: Succinct Zero-Knowledge Proofs with Optimal Prover Computation. *CRYPTO 2019.* https://doi.org/10.1007/978-3-030-26948-7_24 *(GKR/sumcheck in ZK context)*

**[15] DARPA I2O. (2025).** Information Innovation Office (I2O) FY2026 Office-Wide Broad Agency Announcement. *SAM.gov Solicitation HR001126S0001, posted 2025-11-28.* https://www.darpa.mil/work-with-us/opportunities/hr001126s0001

**[16] Vasilev, D. (2026).** Trinity S³AI Framework Documentation. *t27.ai Technical Documentation.* https://t27.ai/docs/

---

### End of Proposal

*All technical specifications, performance projections, and formal verification claims in this document are the work of Dmitrii Vasilev (sole author, PI, admin@t27.ai), t27.ai. This document is submitted as a public-facing research proposal in response to DARPA I2O BAA HR001126S0001. Performance figures marked "projected, pending tape-out 2026-12-16" are pre-silicon estimates and subject to revision upon characterization of fabricated chips.*

*Contact: Dmitrii Vasilev | admin@t27.ai | https://t27.ai | ORCID 0009-0008-4294-6159*
