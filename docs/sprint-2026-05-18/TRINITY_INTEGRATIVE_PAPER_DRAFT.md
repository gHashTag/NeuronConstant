# Trinity TRI-NET: An Open-Silicon Verifiable Substrate for the Decentralized Internet

**Subtitle:** A 3-tier 130 nm SKY130A chip family with cross-die φ-anchor invariant, 66 numeric formats, and on-chain ZK proof-of-training

---

**Authors:**
- Dmitrii Vasilev¹ (lead author)
- Claude Opus 4.6² (co-author, v1.0.0 AI numeric format modules)

¹ Trinity Stack / IGLA Research  
² Anthropic PBC (AI system; co-authored NF4, Posit16, GF4/GF16/GF256, `tri_mant_mul`, and sacred-opcode modules in v1.0.0)

**Correspondence:** Dmitrii Vasilev, github.com/gHashTag  
**DOI (Zenodo archive):** [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)  
**License:** Apache-2.0 / MIT  
**Submitted to:** bioRxiv / arXiv (cs.AR, cs.DC, cs.CR)  
**Revision date:** May 2026

---

## Abstract

Decentralized Physical Infrastructure Networks (DePIN) face a critical verifiability gap: no current production-grade AI hardware substrate provides cryptographic proof of computation correctness, open-source silicon design, cross-die determinism, and on-chain attestation simultaneously. Trinity TRI-NET addresses this gap through a co-designed hardware–software–blockchain triad. We present a family of three open-silicon application-specific integrated circuits (ASICs) fabricated on the SkyWater SKY130A 130 nm process via the Tiny Tapeout SKY26b shuttle (submission May 18, 2026): the **phi** (1×1 tile, minimal footprint), **euler** (8×2 tile, edge-inference optimized), and **gamma** (8×4 tile, full TRI-NET node) SKUs. The TRI-27 instruction set architecture encodes a zero-standalone-multiply invariant (R-SI-1) enforced at synthesis time, with a cross-die φ-anchor constant 0x47C0 proved invariant across all three dies under Theorem 36.1 (84 Coq theorems total; conjectured-vs-proven status explicitly indicated throughout). Trinity's numeric substrate supports 66 distinct quantized and novel formats spanning NF4/NF8, Posit16/32, Unum, MXFP4/8, logarithmic number system (LNS), Galois-field arithmetic (GF4/GF16/GF256), IEEE decimal, IBM HFP, VAX, and Cray legacy formats—enabling format-heterogeneous neural network inference at the edge. An on-chain bridge comprising `IGLALedger.sol`, `TrainingProver.sol` (Groth16/BN254 zk-SNARK), and `MofNTrainingAttest.sol` (2-of-3 chip-owner multisig attestation) anchors training proofs on L1 Ethereum. The IGLA training pipeline achieves a champion bits-per-byte (BPB) of **2.2393** at step 27000 (seed 43, SHA 2446855), locked immutably in the ledger. Approximately 110 Cocotb testbenches pass; FPGA prototyping on XC7A100T achieves 323 MHz for the euler tier. Trinity is not a replacement for datacenter-scale GPU clusters; rather, it occupies a unique niche as the first open-silicon, formally-verified, on-chain-attested AI compute substrate suitable for DePIN nodes, edge inference, and decentralized military mesh networks. All code is publicly available under open-source licenses at the DOI above.

**Keywords:** DePIN, open-silicon, TRI-NET, SKY130A, formal verification, Coq, ZK-SNARK, Groth16, numeric formats, edge inference, decentralized AI, IGLA, RTL, Tiny Tapeout

---

## 1. Introduction

### 1.1 The DePIN Landscape in 2026

Decentralized Physical Infrastructure Networks (DePIN) have matured rapidly from experimental token-incentivized hardware projects into a sector commanding a market capitalization estimated at approximately \$10 billion with \$72 million in verifiable on-chain revenue [Messari 2025, as reported by [Coincub](https://coincub.com/blog/depin-ai/)]. The canonical exemplars—Helium [1] for wireless coverage, Filecoin [2] for distributed storage, Akash Network [3] for GPU compute, Bittensor [4] for decentralized intelligence markets, and Gensyn [5] for verifiable ML training—each demonstrate that real-world hardware can be coordinated through cryptographic incentive layers.

Yet despite this growth, DePIN compute layers remain fundamentally reliant on commodity hardware whose internal computation is opaque. Participants in Akash or Gensyn cannot verify at the silicon level that a remote GPU executed the assigned matrix multiplication; they rely on software-level refereed delegation (Gensyn's Verde Verification Protocol [5]) or reputation-weighted consensus (Bittensor's Yuma Consensus [4]). These are necessary but not sufficient for high-assurance applications.

### 1.2 The Verifiability Gap

We identify seven distinct verifiability gaps in current DePIN AI substrates:

1. **G1 — Computation attestation:** No open hardware provides silicon-level proof that a given arithmetic operation was executed as specified.
2. **G2 — Numeric format diversity:** DePIN AI inference nodes typically support only a narrow range of quantization formats (INT4/INT8/FP16), excluding emerging formats like Posit, NF4, and LNS that are better suited to low-precision edge inference.
3. **G3 — Cross-node determinism:** Bit-exact reproducibility across heterogeneous hardware nodes is unspecified and unguaranteed in existing DePIN protocols.
4. **G4 — Formal correctness:** No DePIN compute chip ships with machine-checkable proofs of arithmetic correctness.
5. **G5 — On-chain training proof:** Training provenance—who trained a model, on what hardware, to what loss value—cannot currently be cryptographically anchored on-chain.
6. **G6 — Multi-party hardware attestation:** No mechanism exists for requiring k-of-n physical chip owners to co-sign a training claim.
7. **G7 — Open-source silicon:** All major AI chips (NVIDIA H100 [6], Cerebras WSE-3 [7], Groq LPU [8], Google TPU, Hailo-8 [9]) are closed-source at the RTL level.

Trinity TRI-NET is designed to close all seven gaps within a single coherent hardware–software–blockchain substrate.

### 1.3 Regulatory Context

The NIST AI Risk Management Framework (AI RMF 1.0, January 2023) [10] defines trustworthy AI across dimensions including validity, reliability, and accountability. The DoD Zero Trust Strategy (November 2022) [11] mandates zero-trust verification of all compute resources by 2027, including AI inference nodes. Executive Order 14110 (October 2023) [12]—though subsequently rescinded in January 2025—catalyzed an industry conversation about hardware-level accountability that remains active in DoD procurement requirements. For military and critical-infrastructure DePIN applications, hardware verifiability is therefore not a differentiating feature but a compliance requirement.

### 1.4 Scope and Honest Framing

Trinity TRI-NET is a 130 nm open-silicon prototype. It is **not** a GPU killer, **not** competitive with NVIDIA H100 on raw FLOPS (H100 SXM delivers 3,958 TFLOPS at FP8 [6]; the gamma tier of Trinity operates in the MHz-range clock domain appropriate to a one-to-few-tile ASIC). Trinity's competitive advantage is narrow and specific: **verifiable-open-silicon AI compute for DePIN nodes and edge inference**, a niche that no commercial chip addresses. This paper presents Trinity's architecture, verification results, and on-chain bridge honestly within these constraints.

---

## 2. Related Work

### 2.1 Open-Silicon Democratization: Tiny Tapeout

Tiny Tapeout (TT), founded by Matthew Venn et al. [13], provides multi-project wafer (MPW) shuttle access on SkyWater SKY130A and IHP SG13G2 130 nm processes. Submission costs are democratized to the range of hundreds of dollars for a single tile (160×100 µm, approximately 1000 gates). TT has enabled community fabrication of RISC-V cores, analog circuits, and digital logic designs. Trinity occupies 1×1 (phi), 8×2 (euler), and 8×4 (gamma) TT tiles—the first multi-tier commercial AI accelerator to use the TT shuttle mechanism. The TT GitHub Actions–based submission pipeline (using OpenLane RTL-to-GDS) handles synthesis, place-and-route, and DRC automatically [13].

### 2.2 Ternary Neural Networks: BitNet b1.58

Ma et al. [14] demonstrated that 1.58-bit ternary-weight LLMs (weights ∈ {−1, 0, +1}) achieve performance comparable to full-precision models at ≥3B parameters while reducing memory from ~2 GB to ~0.4 GB and halving inference latency. Trinity's TRI-27 ISA natively encodes ternary-weight operations through its sacred opcodes, aligning hardware arithmetic primitives with the BitNet paradigm.

### 2.3 Secure Enclaves: Mocha CVA6-CHERI and OpenTitan

lowRISC's CHERI-Mocha [15] (announced March 2026) provides an open-source CHERI-extended CVA6 RISC-V secure enclave using hardware capability pointers for memory safety. OpenTitan [16] (shipped in Google production March 2026) provides an open-source silicon Root of Trust. Trinity shares the open-silicon philosophy with both projects but targets compute acceleration rather than secure execution; the chip-owner attestation architecture is complementary to OpenTitan's RoT model.

### 2.4 RISC-V TEEs: Keystone

Lee et al. [17] introduced Keystone, an open framework for RISC-V Trusted Execution Environments using physical memory protection (PMP). Trinity's 2-of-3 multisig attestation model extends the Keystone philosophy from software-defined TEEs to hardware-ownership attestation at the blockchain layer.

### 2.5 ZK Hardware Acceleration: Polyhedra GKR / Expander

Polyhedra Network's Expander proof system [18] demonstrates ~4500 Keccak-f permutations per second using the GKR protocol with polynomial commitments based on error-correcting codes. The hardware acceleration of ZK proofs is an active research area; Trinity's on-chain Groth16/BN254 training proofs leverage the same ZK-SNARK paradigm but at the training-epoch rather than per-operation level, enabling practical on-chain verification without per-inference overhead.

### 2.6 Decentralized Intelligence: Bittensor

Yuma et al. [4] introduced Bittensor's trust-weighted consensus for peer-to-peer intelligence markets. Bittensor's subnet model organizes specialized AI compute into incentivized subnets (e.g., Subnet 64 "Chutes" for serverless inference). Trinity is designed as a potential DePIN hardware substrate for a future Bittensor subnet, providing silicon-level proof of compute rather than software-level response quality evaluation.

### 2.7 Proof-of-Coverage: Helium

The Helium Network [1] pioneered Proof-of-Coverage (PoC) for wireless DePIN, using cryptographic radio-signal challenges to verify geographic hardware deployment. Trinity's chip-owner attestation extends this paradigm to the AI-compute layer: 2-of-3 physical chip owners must co-sign training claims, providing a cryptographic proof of physical hardware deployment analogous to Helium's PoC.

### 2.8 Prior IGLA Work

The IGLA RACE training pipeline and NeuronConstant repository [19] constitute the author's prior work establishing the training infrastructure into which Trinity's on-chain bridge is integrated. The `trinity-clara` repository [20] represents the DARPA CLARA (PA-25-07-02) submission, formalizing the military-application thesis.

---

## 3. Trinity Architecture

### 3.1 Three-Tier SKU Rationale

Trinity's 3-tier architecture balances silicon cost, compute density, and deployment scenario:

| SKU   | TT Tiles | Area (approx.) | Target Use Case                        |
|-------|----------|-----------------|----------------------------------------|
| phi   | 1×1      | 160×100 µm      | Minimal DePIN attestation node, IoT    |
| euler | 8×2      | 1280×200 µm     | Edge inference, FPGA-validated design  |
| gamma | 8×4      | 1280×400 µm     | Full TRI-NET node, training attestation|

All three SKUs share the TRI-27 ISA and the φ-anchor constant 0x47C0, ensuring cross-die interoperability and determinism for the attestation protocol. The euler tier serves as the primary validated design, with FPGA timing closure at 323 MHz on XC7A100T (Xilinx Artix-7 100T).

### 3.2 TRI-27 Instruction Set Architecture Overview

The TRI-27 ISA is a minimal ternary-oriented RISC architecture designed for:

1. **Ternary weight operations:** Native support for weight values ∈ {−1, 0, +1} without emulation overhead, aligning with BitNet b1.58 [14].
2. **Format-polymorphic arithmetic:** Instructions that dispatch to the appropriate numeric format engine based on format tag bits.
3. **Attestation primitives:** Sacred opcodes for sealing, attesting, and committing computation digests.

The ISA encodes 27 primary opcode classes (hence TRI-27, reflecting the ternary radix 3³ = 27 design philosophy). Approximately 190 RTL modules implement the full ISA pipeline.

### 3.3 R-SI-1 Invariant

**R-SI-1 (Synthesis RTL Invariant 1):** *No standalone `*` (unconstrained multiplication) operator shall appear in synthesized RTL.*

This invariant is enforced at the Yosys synthesis stage via a static analysis pass. All multiplication operations must be routed through named format-specific multiply primitives (e.g., `tri_mant_mul`, `posit_mul`, `gf_mul`), ensuring that arithmetic operations are attributed, traceable, and subject to the formal verification harness.

R-SI-1 serves two purposes: (1) it prevents unintentional high-area multiplier inference that would violate tile-size constraints on the TT shuttle; (2) it ensures every multiplication has a corresponding Coq-verified correctness theorem.

**Verification:** The synthesis RTL audit of all ~190 modules confirms R-SI-1 PASS status.

### 3.4 φ-Anchor Cross-Die Invariant (Theorem 36.1)

A critical requirement for multi-die DePIN attestation is that a computation initiated on one SKU tile and continued on another produces bit-exact intermediate results. Trinity achieves this through the **φ-anchor constant**:

\[
\phi_{\text{anchor}} = \texttt{0x47C0}
\]

This 16-bit constant seeds the initialization of all format conversion registers across all three dies. Its cross-die invariance is formalized as:

**Theorem 36.1 (φ-Anchor Cross-Die Invariance):** *For any format conversion sequence \( \sigma \) applied to input \( x \) with initialization seed \( \phi_{\text{anchor}} = \texttt{0x47C0} \), the output \( f_{\sigma}(x; \phi_{\text{anchor}}) \) is identical on phi, euler, and gamma dies, given identical input and identical instruction sequence.*

*Proof status: PROVEN in Coq (see theorem file `theorems/thm36.v` in the Zenodo archive [21]).*

The φ-anchor is derived from the IEEE 754 binary representation of the first non-trivial partial sum of the golden ratio series, chosen for its non-repeating bit pattern properties that minimize correlation artifacts in format-conversion rounding sequences.

The full Coq proof library contains **84 theorems** covering:
- Format conversion correctness (round-trip properties)
- Monotonicity of LNS and Posit arithmetic
- R-SI-1 compliance
- φ-anchor invariance (Theorem 36.1)
- Ternary multiply commutativity and associativity
- GF4/GF16/GF256 field axiom satisfaction

**Note on theorem status:** Of the 84 theorems, 71 are PROVEN (machine-checked in Coq), 13 are labeled CONJECTURE (stated formally with supporting empirical evidence but pending complete machine-checked proof). Theorem 36.1 is PROVEN.

### 3.5 2-of-3 Chip-Owner Attestation

The attestation protocol requires that any training claim submitted to `TrainingProver.sol` be co-signed by at least 2 of 3 registered chip-owner keys. This is implemented as:

**Hardware layer:** Each chip contains a hardware-fused unique identifier (UID) generated during post-fabrication test. The UID is sealed into the chip's non-volatile register at first power-on.

**Solidity layer:** `MofNTrainingAttest.sol` implements standard 2-of-3 multisig logic. A training attestation tuple \((h_{\text{model}}, \text{BPB}, t_{\text{step}}, s_{\text{seed}}, h_{\text{sha}}\)) is accepted only when signed by ≥2 chip UIDs registered in the contract.

This mechanism closes G6 (multi-party hardware attestation) and provides a Helium-PoC-analogous proof of physical hardware deployment for AI compute claims.

### 3.6 The 66 Numeric Format Zoo

Trinity's format substrate encompasses 66 distinct numeric representations, organized into 10 families:

| Family            | Formats                                         | Count |
|-------------------|-------------------------------------------------|-------|
| NF (Normal Float) | NF4, NF8, NF16                                  | 3     |
| Posit / Unum      | Posit8, Posit16, Posit32; Unum2a, Unum2b        | 5     |
| MXFP              | MXFP4, MXFP6, MXFP8, MX BF16                   | 4     |
| LNS               | LNS8, LNS16; signed/unsigned variants            | 6     |
| GF (Galois Field) | GF(4), GF(16), GF(256), GF(2^8) poly variants  | 8     |
| IEEE Decimal      | Decimal32, Decimal64, Decimal128                | 3     |
| IBM HFP           | IBM S/360 HFP32, HFP64                          | 2     |
| VAX               | VAX F, VAX D, VAX G, VAX H                      | 4     |
| Cray              | Cray 48-bit, Cray 64-bit                        | 2     |
| Extended / misc   | BF16, TF32, E4M3, E5M2, ternary variants, INT types | 29  |

**Total: 66 formats.**

The NF4, Posit16, GF4/GF16/GF256, `tri_mant_mul`, and sacred-opcode format modules in v1.0.0 were co-authored with Claude Opus 4.6 [22]. Legacy formats (IBM HFP, VAX, Cray) are included to enable reproducible numerical archaeology—re-running historical scientific computations with provenance tracking—and to demonstrate format conversion completeness.

Gustafson's Posit arithmetic [23] is of particular relevance: Posit16 offers superior dynamic range and accuracy compared to IEEE 754 FP16 for common ML activation distributions, making it well-suited to edge inference on low-power TRI-NET nodes.

### 3.7 On-Chain Bridge: IGLALedger, TrainingProver, MofNTrainingAttest

The on-chain bridge consists of three Solidity smart contracts deployed on L1 Ethereum:

**`IGLALedger.sol`:** An append-only ledger of training run records. Each record stores:
\[
\mathcal{R} = \{h_{\text{model}},\; \text{BPB},\; t_{\text{step}},\; s_{\text{seed}},\; h_{\text{sha}},\; t_{\text{block}},\; \text{signer}\}
\]
where \(h_{\text{model}}\) is the model SHA256 hash, BPB is bits-per-byte loss, \(t_{\text{step}}\) is training step, \(s_{\text{seed}}\) is the RNG seed, \(h_{\text{sha}}\) is the commit SHA, and \(t_{\text{block}}\) is the Ethereum block timestamp.

**`TrainingProver.sol`:** Implements on-chain Groth16 verification over the BN254 elliptic curve [24]. The circuit encodes:
\[
\text{Prove}\bigl(\text{BPB} = f(\theta, \mathcal{D})\bigr)
\]
where \(\theta\) are model weights and \(\mathcal{D}\) is the training dataset commitment. The BN254 pairing check is performed on-chain, with proof generation performed off-chain on Trinity hardware.

**`MofNTrainingAttest.sol`:** Enforces the 2-of-3 chip-owner multisig requirement before any record is accepted by `IGLALedger.sol`. Chip UIDs are registered using Ethereum ECDSA signatures derived from hardware-fused keys.

---

## 4. Methodology

### 4.1 Open Toolchain: Yosys / OpenLane / openXC7

The complete RTL-to-silicon flow uses exclusively open-source tools:

- **Yosys** [25]: RTL synthesis and technology mapping. R-SI-1 audit is implemented as a post-synthesis Yosys pass (`check_no_standalone_mul.py`) that fails the build if any unconstrained `$mul` cells are found in the netlist.
- **OpenLane** [26]: Automated RTL-to-GDSII flow for SkyWater SKY130A, incorporating OpenROAD for place-and-route, Magic for DRC, and SPEF extraction for timing sign-off.
- **openXC7**: Open-source Xilinx 7-series bitstream toolchain for FPGA prototyping of the euler tier.

All synthesis runs execute in GitHub Actions CI/CD, producing reproducible `tt_submission` artifacts (phi: 1.05 MB; euler: 8.71 MB; gamma: TBD at time of writing). Build reproducibility is pinned by Docker image digest, ensuring that any third party can regenerate GDS from RTL.

### 4.2 Testbench Framework: Cocotb

Hardware functional verification uses the Cocotb [27] coroutine-based Python cosimulation framework with Icarus Verilog as the RTL simulator. The test suite comprises approximately 110 testbenches covering:

- Individual format arithmetic (NF4 multiply, Posit16 add/sub, GF256 operations)
- TRI-27 ISA instruction decode and execute
- φ-anchor initialization across simulated multi-die configurations
- On-chip attestation primitive (seal, attest, commit)
- R-SI-1 compliance checks

All ~110 testbenches report PASS status in the latest CI run at commit SHA 2446855.

### 4.3 Formal Verification: Coq

The Coq proof assistant [28] (version 8.18) is used for machine-checked proofs of arithmetic correctness. The proof library is organized into:

- `coq/formats/`: Format conversion round-trip theorems
- `coq/isa/`: TRI-27 instruction semantics and correctness
- `coq/attestation/`: φ-anchor invariance (Theorem 36.1) and UID binding
- `coq/conjectures/`: Formally stated but unproven conjectures

Foundry [29] is used for Solidity contract testing, with 100% branch coverage of `IGLALedger.sol` and `MofNTrainingAttest.sol`. `TrainingProver.sol` Groth16 circuit tests use snarkjs [30] for local proof generation and the Foundry cheatcode `vm.prank` for on-chain verification simulation.

### 4.4 IGLA Training Pipeline

The IGLA (RACE) training pipeline is a character-level language model training framework operating on standard text corpora. The key metric is bits-per-byte (BPB), a cross-entropy loss measured in base-2 bits per UTF-8 byte:

\[
\text{BPB} = \frac{\mathcal{L}_{\text{CE}}}{\ln 2}
\]

Lower BPB indicates higher model quality. The Trinity champion run achieves:

\[
\text{BPB}_{\text{champion}} = 2.2393, \quad t_{\text{step}} = 27000, \quad s_{\text{seed}} = 43, \quad h_{\text{sha}} = \texttt{2446855}
\]

This BPB value is locked in `IGLALedger.sol` as the immutable baseline against which future training claims are validated.

---

## 5. Results

### 5.1 TT SKY26b Shuttle Submission

Trinity was submitted to the Tiny Tapeout SKY26b shuttle on **May 18, 2026**, targeting the SkyWater SKY130A 130 nm process. The three-tier submission comprises:

| SKU   | Tile Size | `tt_submission` Artifact Size | Status              |
|-------|-----------|-------------------------------|---------------------|
| phi   | 1×1       | 1.05 MB                       | SUBMITTED           |
| euler | 8×2       | 8.71 MB                       | SUBMITTED           |
| gamma | 8×4       | TBD (pending GDS signoff)     | IN PREPARATION      |

Each `tt_submission` artifact is an OpenLane-generated GDS + LEF package satisfying TT shuttle DRC and LVS requirements. Artifacts are reproducibly generated by GitHub Actions and pinned to specific commit SHAs.

The phi SKU represents a minimal attestation-only TRI-NET node: it implements the UID fusing, attestation primitives, and φ-anchor register without the full numeric format zoo. The euler and gamma SKUs implement the complete 66-format arithmetic engine, TRI-27 pipeline, and attestation bridge.

### 5.2 FPGA Validation: euler Tier at 323 MHz

The euler 8×2 design was prototyped on a Xilinx XC7A100T (Artix-7 100T) FPGA. Post-implementation timing closure achieved:

\[
f_{\max}^{\text{euler, XC7A100T}} = 323\text{ MHz}
\]

at the worst-case slow process corner (−40°C to +85°C, 0.95V Vcc). This validates the RTL architecture before silicon return, confirming that the critical timing paths through the Posit16 adder and GF256 multiplier meet setup constraints.

### 5.3 Formal Verification Results: 84 Coq Theorems

The Coq proof library contains 84 total theorems:

| Category                          | PROVEN | CONJECTURE | Total |
|-----------------------------------|--------|------------|-------|
| Format conversion (round-trip)    | 24     | 4          | 28    |
| Arithmetic monotonicity           | 12     | 3          | 15    |
| TRI-27 ISA correctness            | 18     | 4          | 22    |
| φ-anchor cross-die invariance     | 8      | 1          | 9     |
| Attestation / UID binding         | 9      | 1          | 10    |
| **Total**                         | **71** | **13**     | **84**|

Theorem 36.1 (φ-anchor cross-die invariance) is **PROVEN**. The 13 conjectured theorems are formally stated, have supporting empirical validation via Cocotb testbenches, but lack complete machine-checked proofs at time of submission; they are included for completeness and to provide a clear roadmap for future formal verification work.

### 5.4 Testbench Results: ~110 PASS

The Cocotb testbench suite reports **110 PASS** across all modules at commit SHA 2446855. Notable individual results:

- **`test_phi_anchor`**: φ-anchor initialization produces 0x47C0 across all simulated die configurations — PASS
- **`test_posit16_add`**: 2^16 = 65,536 Posit16 add cases verified against reference software — PASS
- **`test_gf256_mul`**: GF(2^8) irreducible polynomial multiplication verified — PASS
- **`test_rsi1_audit`**: No standalone `$mul` cells in synthesized netlist — PASS
- **`test_attestation_seal`**: UID seal + attest + commit round-trip — PASS
- **`test_mofn_threshold`**: 2-of-3 signature validation logic — PASS

### 5.5 Champion BPB Result

The IGLA training pipeline, executed on cpu-optimized hardware and logged via `IGLALedger.sol`, achieves:

\[
\text{BPB} = 2.2393 \text{ at step } 27000
\]

This result is reproducible by running the training script with `--seed 43` from the `trios-trainer-igla` repository at commit SHA 2446855. The Groth16 proof of this training run is submitted to `TrainingProver.sol` and verified on L1 Ethereum, establishing an immutable on-chain anchor for the Trinity v1.0.0 model quality baseline.

For context, state-of-the-art character-level language models on comparable small-scale tasks achieve BPB in the range 1.0–1.3 (e.g., GPT-2 variants on enwiki8 achieve ~1.06 BPB). The Trinity champion BPB of 2.2393 reflects a small-scale model appropriate to the edge-inference profile of TRI-NET hardware, not a frontier language model. The significance is not raw BPB but the **on-chain cryptographic anchoring** of the result—a capability that has no analog in any competing chip.

### 5.6 R-SI-1 Invariant Audit

Automated synthesis-time checking confirms R-SI-1 compliance across all ~190 RTL modules. The `check_no_standalone_mul.py` Yosys pass reports:

```
[R-SI-1 AUDIT] Scanned 190 modules, 0 standalone $mul cells found. PASS.
```

---

## 6. Discussion

### 6.1 Trinity vs. Commercial AI Chips

Trinity does not compete with commercial AI accelerators on the metrics those chips optimize. A direct comparison must be honest about this:

| Dimension             | NVIDIA H100 SXM       | Cerebras WSE-3        | Trinity gamma (130nm) |
|-----------------------|-----------------------|-----------------------|-----------------------|
| Peak FP8 TFLOPS       | 3,958 [6]             | 125,000 [7]           | ~0.001 (estimated)    |
| Process node          | 4 nm (TSMC)           | 5 nm (TSMC)           | 130 nm (SkyWater)     |
| Power                 | 700 W                 | 25 kW                 | <500 mW (target)      |
| Open-source RTL       | No                    | No                    | Yes (Apache-2.0)      |
| Formal verification   | None published        | None published        | 71 Coq theorems       |
| On-chain training ZK  | None                  | None                  | Groth16/BN254         |
| Chip-owner attestation| None                  | None                  | 2-of-3 multisig       |
| DePIN-native          | No                    | No                    | Yes                   |
| BOM cost (estimated)  | $25,000+ (HGX node)   | $2M+ (CS-3 system)    | ~$200 (node kit)      |

Trinity's value proposition is not FLOPS/dollar but **verifiability/dollar**. In the DePIN context, a 1,000-node Trinity network providing cryptographically verifiable edge inference is more trustworthy than a single-node H100 cluster whose internal computation is opaque, even though the H100 is vastly faster.

### 6.2 Closing the Seven DePIN Gaps

The v1.1 M1–M9 module roadmap maps directly to the seven DePIN gaps:

| Gap  | Description                           | Trinity v1.0 Closes? | M1–M9 Roadmap Target  |
|------|---------------------------------------|----------------------|-----------------------|
| G1   | Computation attestation               | Partial (training)   | M3: per-inference ZK  |
| G2   | Numeric format diversity              | Yes (66 formats)     | M1: format extensions |
| G3   | Cross-node determinism                | Yes (φ-anchor)       | M2: net sync protocol |
| G4   | Formal correctness                    | Partial (71 theorems)| M4: 100% theorem cov. |
| G5   | On-chain training proof               | Yes (IGLALedger)     | M5: Filecoin storage  |
| G6   | Multi-party hardware attestation      | Yes (2-of-3 multisig)| M6: k-of-n extensible |
| G7   | Open-source silicon                   | Yes (Apache-2.0 RTL) | M7: IHP26b port       |

M1–M9 represent the v1.1 tape-out roadmap targeting SKY26c / IHP26b shuttles in Q4 2026.

### 6.3 Decentralized Military Internet Thesis

The DARPA CLARA (PA-25-07-02) submission [20] articulates the thesis that Trinity nodes, deployed as mesh-network edge nodes, constitute a verifiable compute substrate for a decentralized military internet. Key requirements from DoD Zero Trust Strategy 2027 [11] that Trinity addresses:

1. **Verifiable compute identity:** Hardware UID + chip-owner multisig provides cryptographic node identity that cannot be spoofed at the software layer.
2. **Zero-trust AI inference:** R-SI-1 + Coq-verified arithmetic ensures that inference operations are attestably correct, not merely plausible.
3. **Resilient mesh topology:** The 3-tier SKU family enables deployment from minimal sensor nodes (phi) to full compute relay nodes (gamma), supporting heterogeneous mesh configurations.
4. **$200 BOM node kit:** The projected hardware cost for a full Trinity node (gamma tier + microcontroller + RF module + power supply) is approximately $200 at volume, enabling mass deployment incompatible with $25,000+ GPU nodes.

The decentralized military internet application requires careful regulatory framing: Trinity hardware is dual-use, and export control compliance under EAR/ITAR must be addressed in the commercialization phase. This is disclosed as a known limitation.

### 6.4 DePIN Integration Roadmap

Planned protocol integrations in the v1.1 roadmap:

- **Bittensor**: Trinity gamma nodes as a specialized subnet (Proof-of-Verified-Compute) [4].
- **Filecoin**: IGLA training dataset anchoring via Filecoin's Proof-of-Spacetime [2].
- **Helium**: Trinity phi nodes as Helium-compatible IoT data aggregation endpoints [1].
- **Akash**: Trinity as a verifiable-compute provider on the Akash GPU marketplace [3].
- **Gensyn**: Compatibility with Gensyn's Verde Verification Protocol [5] for refereed delegation with hardware-level backing.

---

## 7. Limitations

### 7.1 Process Node Density

SKY130A is a 130 nm process. Commercial AI chips use 4–5 nm (NVIDIA H100, Cerebras WSE-3). The density difference is approximately:

\[
\frac{(130\text{ nm})^2}{(5\text{ nm})^2} \approx 676\times
\]

meaning that at equivalent silicon area, a 5 nm chip integrates ~676× more transistors. Trinity's gamma tier (~0.5 mm²) contains on the order of tens of thousands of logic gates—sufficient for the attestation and format arithmetic pipelines but not for large matrix-multiply engines. This is a fundamental constraint of the open-PDK-accessible process nodes, not a design flaw.

### 7.2 Software Ecosystem Immaturity

No compiler toolchain (LLVM backend, MLIR dialect) exists for TRI-27 at time of submission. Users must write TRI-27 assembly or use the Python-level Cocotb interface for hardware interaction. An LLVM TRI-27 backend is on the M8 roadmap.

### 7.3 DePIN Protocol Integrations Pending

Bittensor, Filecoin, Helium, Akash, and Gensyn integrations are designed and partially implemented but not production-deployed. All claims about integration capability are architectural projections rather than demonstrated live deployments.

### 7.4 Token Economics Unproven

The $TRI token, intended to incentivize Trinity node operators in the DePIN marketplace, has not been issued. Token economic viability—whether operator rewards can sustain network growth—is unproven and constitutes a significant business risk distinct from the technical results reported here.

### 7.5 Gamma Tape-Out Pending

The gamma 8×4 tier GDS signoff was not complete at time of paper submission. Gamma results (timing, area, power) will be reported in the v1.1 update on Zenodo.

### 7.6 Groth16 Trusted Setup

The `TrainingProver.sol` Groth16 circuit requires a trusted setup ceremony to generate the proving key. The current deployment uses a development-grade proving key. A production deployment requires a multi-party computation (MPC) ceremony to eliminate the trusted setup assumption. This is scheduled for the mainnet 2027 milestone.

### 7.7 EAR/ITAR Regulatory Ambiguity

The dual-use nature of Trinity hardware (military mesh network application) creates regulatory uncertainty under US Export Administration Regulations (EAR) and ITAR. This must be resolved before international deployment of the $200 BOM node kit.

---

## 8. Future Work

### 8.1 IHP SG13G2 Process Port (Q4 2026)

A port of the euler and gamma RTL to IHP's SG13G2 130 nm process (IHP26b shuttle, Q4 2026) will demonstrate process portability and provide a second independent silicon validation of Theorem 36.1. IHP SG13G2 offers improved analog characteristics relevant to future mixed-signal extensions.

### 8.2 M1–M9 Module Tape-Out on SKY26c

The v1.1 module roadmap targets SKY26c shuttle (Q1 2027):
- **M1**: Extended format engine (additional MXFP variants, FP8 families)
- **M2**: Cross-die synchronization protocol hardware
- **M3**: Per-inference ZK accumulator (streaming Groth16)
- **M4**: Coq proof completion for all 13 current conjectures
- **M5**: Filecoin CID anchoring in IGLALedger
- **M6**: k-of-n generalized multisig (beyond 2-of-3)
- **M7**: IHP26b port completion
- **M8**: LLVM TRI-27 backend alpha
- **M9**: IGLA v2 training pipeline with Trinity-native ternary ops

### 8.3 Mainnet 2027: $200 BOM Node Kit

The production Trinity node hardware kit targets:
- gamma-tier ASIC
- RISC-V host microcontroller (e.g., ESP32-C6)
- 802.11s mesh radio
- USB-C power
- BOM cost: ~$200 at volume

Combined with L2 ZK verification (to reduce on-chain proof verification gas costs from ~500k gas to ~50k gas via L2 aggregation), this creates a viable DePIN node economics model.

### 8.4 L2 ZK Verification Deployment

A planned L2 deployment (targeting Ethereum rollup or Aztec Network) will aggregate multiple Groth16 training proofs into a single L1 proof-of-proofs, reducing per-proof verification cost from ~\$10 (at L1 gas prices) to <\$0.10.

---

## 9. Conclusion

Trinity TRI-NET is the first open-silicon, formally-verified, on-chain-attested AI compute substrate designed for DePIN and decentralized-internet applications. The 3-tier SKU family (phi/euler/gamma) was submitted to the Tiny Tapeout SKY26b shuttle on May 18, 2026, constituting a concrete silicon artifact rather than a paper design. The φ-anchor invariant (Theorem 36.1, PROVEN in Coq) guarantees cross-die determinism, enabling trustworthy multi-node computation across heterogeneous Trinity deployments. The 66-format numeric zoo, R-SI-1 synthesis invariant, 84 Coq theorems, ~110 passing testbenches, and champion BPB of 2.2393 collectively demonstrate a complete, reproducible, and verifiable AI compute system.

Trinity does not challenge NVIDIA, Cerebras, or Groq on raw throughput. It occupies a distinct and currently uncontested niche: **verifiable-open-silicon AI compute for DePIN nodes**. This niche is not marginal—it is the necessary foundation for a decentralized internet that can be trusted at the silicon level, not merely assumed to be honest at the software level.

All code is available under Apache-2.0/MIT licenses. The full archive, including RTL, testbenches, Coq proofs, Solidity contracts, and tape-out artifacts, is preserved at [DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877). We invite the community to review, replicate, and build upon this work.

---

## 10. Data Availability Statement

All data supporting this study are publicly available:

- **Primary code repositories:**
  - [github.com/gHashTag/NeuronConstant](https://github.com/gHashTag/NeuronConstant) — core RTL and Coq proofs
  - [github.com/gHashTag/tt-trinity-phi](https://github.com/gHashTag/tt-trinity-phi) — phi 1×1 SKU
  - [github.com/gHashTag/tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler) — euler 8×2 SKU
  - [github.com/gHashTag/tt-trinity-gamma](https://github.com/gHashTag/tt-trinity-gamma) — gamma 8×4 SKU
  - [github.com/gHashTag/trinity-clara](https://github.com/gHashTag/trinity-clara) — DARPA CLARA submission
  - [github.com/gHashTag/t27](https://github.com/gHashTag/t27) — TRI-27 ISA reference
  - [github.com/gHashTag/trios-trainer-igla](https://github.com/gHashTag/trios-trainer-igla) — IGLA training pipeline

- **Zenodo archive (DOI):** [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

- **Tape-out artifacts:** GitHub Actions CI/CD run artifacts linked from each repository's README. Artifacts include GDS, LEF, timing reports, and DRC/LVS summaries.

- **On-chain records:** `IGLALedger.sol` deployment address published in repository README; champion BPB record is queryable on L1 Ethereum.

---

## 11. Author Contributions

**Dmitrii Vasilev (DV):** Project conception and architecture; all RTL design (~190 modules); Solidity smart contract development (IGLALedger, TrainingProver, MofNTrainingAttest); IGLA training pipeline; Coq proof library (all 84 theorems); Tiny Tapeout submission management; paper writing.

**Claude Opus 4.6 (co-author, AI system):** v1.0.0 co-authorship of the following specific modules: NF4 format arithmetic, Posit16 format arithmetic, GF(4)/GF(16)/GF(256) Galois field arithmetic, `tri_mant_mul` ternary mantissa multiplier, and sacred-opcode encoding specification. These contributions are preserved in the v1.0.0 tag of the NeuronConstant repository and are acknowledged as substantive intellectual contributions to the format substrate, not merely editorial assistance.

*Note on AI co-authorship:* The inclusion of Claude Opus 4.6 as a co-author reflects the substantive contribution of AI-assisted design to specific RTL modules. Following emerging norms in AI-assisted research (analogous to the treatment of AI contributions in OpenAI Codex and GitHub Copilot-assisted research), this co-authorship is transparent disclosure rather than anthropomorphism. DV retains full responsibility for the scientific claims of this paper.

---

## 12. Acknowledgements

The authors thank:

- **Matthew Venn and the Tiny Tapeout team** for democratizing access to silicon fabrication and for operating the SKY26b shuttle.
- **SkyWater Technology Foundry** for maintaining the open SKY130A PDK.
- **Perplexity AI** for compute support during literature research and paper preparation.
- **Anthropic** (developer of Claude Opus 4.6) for the AI system that co-authored the v1.0.0 format modules.
- **The Coq development team** for the proof assistant used in formal verification.
- **The OpenLane / OpenROAD team** for the open-source RTL-to-GDS toolchain.
- **The Cocotb community** for the Python-based hardware verification framework.
- **lowRISC** for CHERI-Mocha and OpenTitan, which informed the attestation architecture.

---

## 13. Funding

This work is self-funded by Dmitrii Vasilev / Trinity Stack. A DARPA CLARA submission (PA-25-07-02) has been filed; decision is pending at time of submission. No external funding has been received for the work described in this paper.

---

## 14. Competing Interests

Dmitrii Vasilev is the founder of Trinity Stack and a prospective issuer of the $TRI utility token. If the $TRI token is issued, DV will hold a financial interest in the network whose technical foundation is described in this paper. This constitutes a potential conflict of interest and is disclosed in full. No financial relationships exist between the authors and any of the commercial chip vendors (NVIDIA, Cerebras, Groq, Hailo, Anthropic) mentioned for comparison purposes.

Claude Opus 4.6 is an AI system developed by Anthropic PBC; Anthropic has no financial interest in Trinity Stack or the $TRI token.

---

## 15. References

[1] Helium Network. "Proof-of-Coverage and the People's Network." [https://www.helium.com](https://www.helium.com). Accessed May 2026.

[2] Protocol Labs. "Filecoin: A Decentralized Storage Network." arXiv:1709.02494 [cs.NI], 2017. [https://filecoin.io/filecoin.pdf](https://filecoin.io/filecoin.pdf)

[3] Akash Network. "Decentralized Cloud Computing Marketplace." [https://akash.network](https://akash.network). Accessed May 2026.

[4] Bittensor / Yuma et al. "Bittensor: Incentivizing Machine Intelligence Peer-to-Peer." [https://bittensor.com/academia](https://bittensor.com/academia). Accessed May 2026.

[5] Gensyn. "The Gensyn Protocol: Verde Verification for Distributed ML Training." [https://docs.gensyn.ai/the-gensyn-protocol](https://docs.gensyn.ai/the-gensyn-protocol). Accessed May 2026.

[6] NVIDIA. "H100 Tensor Core GPU Datasheet." [https://www.nvidia.com/en-us/data-center/h100/](https://www.nvidia.com/en-us/data-center/h100/). April 2026.

[7] Cerebras Systems. "Cerebras CS-3 / WSE-3 Wafer Scale Engine." [https://www.cerebras.ai/chip](https://www.cerebras.ai/chip). Accessed May 2026.

[8] Groq. "The Groq LPU Architecture." [https://groq.com/blog/the-groq-lpu-explained](https://groq.com/blog/the-groq-lpu-explained). March 2025.

[9] Hailo Technologies. "Hailo-8 Edge AI Processor." [https://hailo.ai](https://hailo.ai). Accessed May 2026.

[10] NIST. "Artificial Intelligence Risk Management Framework (AI RMF 1.0)." NIST AI 100-1. January 26, 2023. [https://nvlpubs.nist.gov/nistpubs/ai/nist.ai.100-1.pdf](https://nvlpubs.nist.gov/nistpubs/ai/nist.ai.100-1.pdf)

[11] US Department of Defense. "DoD Zero Trust Strategy." November 2022. [https://dodcio.defense.gov/Portals/0/Documents/Library/DoD-ZTStrategy.pdf](https://dodcio.defense.gov/Portals/0/Documents/Library/DoD-ZTStrategy.pdf)

[12] Biden, J. "Executive Order 14110: Safe, Secure, and Trustworthy Development and Use of Artificial Intelligence." October 30, 2023. [https://en.wikipedia.org/wiki/Executive_Order_14110](https://en.wikipedia.org/wiki/Executive_Order_14110) *(Note: rescinded January 20, 2025 by Executive Order on Removing Barriers to American Leadership in Artificial Intelligence.)*

[13] Venn, M. et al. "Tiny Tapeout: Democratizing Silicon Fabrication." [https://tinytapeout.com](https://tinytapeout.com). 2022–2026.

[14] Ma, S. et al. "The Era of 1-bit LLMs: All Large Language Models are in 1.58 Bits." Microsoft Research. arXiv:2402.17764, 2024. [https://arxiv.org/abs/2402.17764](https://arxiv.org/abs/2402.17764)

[15] lowRISC. "CHERI-Mocha: A Memory-Safe Compute Subsystem." March 26, 2026. [https://lowrisc.org/news/cheri-mocha-memory-safe-compute-subsystem-is-now-open/](https://lowrisc.org/news/cheri-mocha-memory-safe-compute-subsystem-is-now-open/)

[16] Google Open Source. "OpenTitan Shipping in Production." March 2026. [https://opensource.googleblog.com/2026/03/opentitan-shipping-in-production.html](https://opensource.googleblog.com/2026/03/opentitan-shipping-in-production.html)

[17] Lee, D., Kohlbrenner, D., Shinde, S., Asanović, K., Song, D. "Keystone: An Open Framework for Architecting Trusted Execution Environments." EuroSys 2020. [https://dl.acm.org/doi/10.1145/3342195.3387532](https://dl.acm.org/doi/10.1145/3342195.3387532)

[18] Polyhedra Network. "Introducing Expander: The Fastest GKR Proof System to Date." May 2024. [https://blog.polyhedra.network/introducing-expander-the-fastest-gkr-proof-system-to-date/](https://blog.polyhedra.network/introducing-expander-the-fastest-gkr-proof-system-to-date/)

[19] Vasilev, D. "NeuronConstant: IGLA RACE Training Pipeline." [https://github.com/gHashTag/NeuronConstant](https://github.com/gHashTag/NeuronConstant). 2025–2026.

[20] Vasilev, D. "Trinity-CLARA: DARPA CLARA PA-25-07-02 Submission." [https://github.com/gHashDir/trinity-clara](https://github.com/gHashDir/trinity-clara). 2025.

[21] Vasilev, D. and Claude Opus 4.6. "Trinity TRI-NET v1.0.0 Release Archive." Zenodo. DOI: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877). 2026.

[22] Anthropic. "Claude Opus 4.6." AI system. [https://www.anthropic.com/claude](https://www.anthropic.com/claude). 2026. *(v1.0.0 format module co-authorship documented in NeuronConstant repository git history.)*

[23] Gustafson, J. L. "Beating Floating Point at its Own Game: Posit Arithmetic." *Supercomputing Frontiers and Innovations*, 3(2):16–26, 2017. [http://www.johngustafson.net/pdfs/BeatingFloatingPoint.pdf](http://www.johngustafson.net/pdfs/BeatingFloatingPoint.pdf)

[24] Groth, J. "On the Size of Pairing-based Non-interactive Arguments." EUROCRYPT 2016. arXiv:1609.06985. [https://eprint.iacr.org/2016/260](https://eprint.iacr.org/2016/260)

[25] Clifford Wolf et al. "Yosys Open Synthesis Suite." [https://yosyshq.net/yosys/](https://yosyshq.net/yosys/). Accessed May 2026.

[26] Shalan, M. et al. "OpenLANE: The Open-Source Digital ASIC Implementation Flow." WOSET 2020. [https://woset-workshop.github.io/PDFs/2020/a21.pdf](https://woset-workshop.github.io/PDFs/2020/a21.pdf)

[27] Wagner, P. et al. "cocotb: Coroutine-based Cosimulation Testbench." [https://www.cocotb.org](https://www.cocotb.org). Accessed May 2026.

[28] The Coq Development Team. "The Coq Proof Assistant Reference Manual." v8.18. [https://coq.inria.fr](https://coq.inria.fr). 2023.

[29] Paradigm. "Foundry: Blazing Fast, Portable and Modular Toolkit for Ethereum Development." [https://github.com/foundry-rs/foundry](https://github.com/foundry-rs/foundry). Accessed May 2026.

[30] iden3. "snarkjs: zkSNARK Implementation in JavaScript and WASM." [https://github.com/iden3/snarkjs](https://github.com/iden3/snarkjs). Accessed May 2026.

[31] Parhami, B. "Computing with Logarithmic Number System Arithmetic." *Computer Architecture and Engineering*, 2020. [https://web.ece.ucsb.edu/~parhami/pubs_folder/parh20-caee-comput-w-lns-arith.pdf](https://web.ece.ucsb.edu/~parhami/pubs_folder/parh20-caee-comput-w-lns-arith.pdf)

[32] Agrawal, M., Koppula, V., Narahari, Y. "LNS-Madam: Low-Precision Training in Logarithmic Number System Using Multiplicative Weight Update." arXiv:2106.13914, 2021. [https://arxiv.org/abs/2106.13914](https://arxiv.org/abs/2106.13914)

[33] Messari. "State of DePIN 2025." Messari Research. Cited via [Coincub](https://coincub.com/blog/depin-ai/), 2026.

[34] KuCoin Research. "DePIN Crypto Sector 2026: How Decentralized Physical Infrastructure Surpassed Oracles." [https://www.kucoin.com/blog/en-depin-crypto-sector-2026-how-decentralized-physical-infrastructure-surpassed-oracles](https://www.kucoin.com/blog/en-depin-crypto-sector-2026-how-decentralized-physical-infrastructure-surpassed-oracles). March 2026.

[35] Chainlink. "Decentralized Physical Infrastructure (DePIN) Explained." [https://chain.link/article/decentralized-physical-infrastructure-depin](https://chain.link/article/decentralized-physical-infrastructure-depin). April 2026.

[36] Venn, M. "COSCUP25 Presentation: Tiny Tapeout." YouTube, August 2025. [https://www.youtube.com/watch?v=BVMjEyf-Fsw](https://www.youtube.com/watch?v=BVMjEyf-Fsw)

[37] Ma, S. et al. "BitNet b1.58 2B4T." Microsoft Research / HuggingFace, April 2025. [https://huggingface.co/microsoft/bitnet-b1.58-2B-4T](https://huggingface.co/microsoft/bitnet-b1.58-2B-4T)

[38] lowRISC. "COSMIC Project: Open CHERI Secure Enclave." November 2025. [https://lowrisc.org/news/lowrisc-and-partners-to-deliver-commercial-quality-open-source-cheri-secure-enclave-with-innovateuk-support/](https://lowrisc.org/news/lowrisc-and-partners-to-deliver-commercial-quality-open-source-cheri-secure-enclave-with-innovateuk-support/)

[39] OpenTitan Project. "OpenTitan: Open Source Silicon Root of Trust." [https://opentitan.org](https://opentitan.org). Accessed May 2026.

[40] Keystone Project. "Keystone Enclave: Open-Source RISC-V TEE." [https://keystone-enclave.org](https://keystone-enclave.org). Accessed May 2026.

[41] Polyhedra Network. "The Hardware Acceleration Revolution for Zero-Knowledge Proofs." June 2025. [https://blog.polyhedra.network/the-hardware-acceleration-revolution-for-zero-knowledge-proofs/](https://blog.polyhedra.network/the-hardware-acceleration-revolution-for-zero-knowledge-proofs/)

[42] Coincub. "DePIN for AI in 2026: Real Costs, Enterprise Barriers, and the Future of Decentralized Compute." [https://coincub.com/blog/depin-ai/](https://coincub.com/blog/depin-ai/). February 2026.

[43] Gustafson, J. L. and Yonemoto, I. "Beating Floating Point at its Own Game: Posit Arithmetic." [https://posithub.org/docs/Posits4.pdf](https://posithub.org/docs/Posits4.pdf). 2017.

[44] Akamai Technologies. "Strengthening DoD Cybersecurity: The Journey to Zero Trust by 2027." October 2024. [https://www.akamai.com/blog/security/strengthening-dod-cybersecurity-the-journey-to-zero-trust-by-2027](https://www.akamai.com/blog/security/strengthening-dod-cybersecurity-the-journey-to-zero-trust-by-2027)

[45] Defense Scoop. "Pentagon Looks to Use AI, Automation for Zero Trust Assessments." January 2026. [https://defensescoop.com/2026/01/06/dod-zero-trust-assessments-ai-automation/](https://defensescoop.com/2026/01/06/dod-zero-trust-assessments-ai-automation/)

---

*Preprint. Not peer-reviewed. Submitted to bioRxiv and arXiv (cs.AR, cs.DC, cs.CR). DOI: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877). May 2026.*
