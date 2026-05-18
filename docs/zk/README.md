# Trinity ZK Proof-of-Compute: Groth16 Specification

**Version:** 1.0.0-draft  
**Status:** Specification — not yet implemented  
**Scope:** `docs/zk/` only — does not modify v1.0.0 AI format modules  
**Author:** Dmitrii Vasilev (gHashTag)  
**DePIN improvement:** #10 of 10

---

## Table of Contents

1. [Motivation](#1-motivation)
2. [Circuit Design — What We Prove](#2-circuit-design--what-we-prove)
3. [Field Arithmetic Mapping](#3-field-arithmetic-mapping)
4. [Groth16 Instantiation](#4-groth16-instantiation)
5. [Verifier Outline](#5-verifier-outline)
6. [Performance Targets](#6-performance-targets)
7. [Implementation Roadmap](#7-implementation-roadmap)
8. [Security Analysis](#8-security-analysis)
9. [Comparison: Groth16 vs PLONK vs STARK](#9-comparison-groth16-vs-plonk-vs-stark)
10. [References](#10-references)

---

## 1. Motivation

### 1.1 The Gap in Hardware-Only Attestation

The Trinity TRI-NET DePIN system deploys compute clusters of three TT SKY26b chips (a **Trinity Triad**). Each chip carries:

- An on-chip hardware `$TRI` token accumulator (`tri_token_accumulator.v`)
- R-SI-1 zero-multiply constraint enforcement
- The sacred 0x47C0 anchor (`sacred_constants_rom.v`, addresses 16–17)
- Sacred opcode set (`sacred_opcodes_rom.v`, crown47 ROM)

The existing M-of-N attestation scheme works as follows: at least M chips in a Triad of N=3 must independently sign a claim before the bridge accepts it. This is sound for a **trusted hardware environment**, but introduces the following limitations:

1. **Hardware trust assumption.** The verifier must trust that the chip is genuine and unmodified. A cloned ASIC can produce valid signatures while never performing real compute.
2. **Opacity of computation.** The attestation signature proves the chip was present but does not cryptographically bind the claim to specific opcodes executed, intermediate states, or output values.
3. **Oracle centralization.** M-of-N flows rely on oracle nodes relaying attestations. These oracles are a trust surface — a compromised oracle can relay fabricated claims.
4. **Single-chip gap.** A lone chip (e.g. a development board, a degraded Triad with one chip offline) cannot produce M-of-N attestations, leaving legitimate single-chip compute unrewarded.

### 1.2 What ZK Proof-of-Compute Adds

A **ZK-SNARK proof-of-compute** built on top of the Trinity ISA (TRI-27) closes these gaps:

| Property | Hardware M-of-N Attestation | ZK Proof-of-Compute |
|---|---|---|
| Trust in hardware | Required | Not required for core claim |
| Reveals computation inputs/outputs | Yes (full transparency) | No (hidden in witness) |
| Works for single chip | No (needs M≥2) | Yes |
| Forgeable by cloned chip | Yes (if key extracted) | No — requires circuit witness |
| Verifiable by anyone on-chain | Yes (signature check) | Yes (proof verification) |
| Gas cost on EVM | ~80K (2-of-3 sig) | ~250K (BN254 pairing) |

The key insight: **a Groth16 proof is computationally infeasible to forge without knowledge of the witness** — the actual private opcode sequence, intermediate register states, and VRF seed. Even a perfect hardware clone cannot produce a valid proof for a computation it did not perform.

### 1.3 Privacy Preservation

In addition to soundness, ZK proofs provide **zero-knowledge** — the verifier learns only:

- That exactly `opcodeCount` TRI-27 ISA opcodes were executed
- That the sacred 0x47C0 anchor was maintained throughout
- That the final token balance equals `finalBalance`
- That the claim is tied to a specific `chipSerial` and `epochNonce`

The specific opcode sequence, intermediate accumulator states, and VRF seed remain private. This is valuable for:

- Proprietary inference workloads that should not be disclosed
- Privacy-preserving proof of AI compute (ZKML direction)
- Competitive neutrality — no operator can observe another's exact workload

### 1.4 Defense Against Emulation Attacks

Software emulators of the Trinity ISA (e.g. running on x86) can produce correct final state outputs but **cannot produce valid Groth16 proofs** without:

1. A valid circuit witness including the chip's private VRF seed
2. Access to the proving key for the specific circuit
3. Approximately 5–30 seconds of proof generation time per epoch

An attacker emulating the hardware must also emulate the entire proof generation pipeline, which offers no economic advantage over running genuine hardware at that point.

---

## 2. Circuit Design — What We Prove

### 2.1 High-Level Statement

> "I (the prover) executed exactly `N` TRI-27 ISA opcodes on a chip with serial `S`. The sacred 0x47C0 anchor was held throughout all `N` steps. The final `$TRI` token balance is `B`. This claim is bound to epoch nonce `E`."

This statement is encoded as an R1CS (Rank-1 Constraint System) circuit and proven using the Groth16 protocol over the BN254 elliptic curve.

### 2.2 Public Inputs (Instance)

These values are revealed to the verifier and included in the proof:

```
chipSerial    : bytes32   — unique chip identifier (hash of ASIC key)
opcodeCount   : uint32    — number of TRI-27 opcodes executed this epoch
finalBalance  : uint16    — $TRI balance after epoch (saturated at 0xFFFF)
epochNonce    : uint64    — monotonic epoch counter preventing replay
anchorHash    : bytes32   — blake3("0x47C0" || epochNonce)
```

The `anchorHash` binds the proof to a specific epoch and confirms the anchor value was used. Computing it as `blake3("0x47C0" || epochNonce)` means the verifier can recompute it from the epoch nonce and check consistency without access to private state.

### 2.3 Private Witness (Statement-Specific Secrets)

These values are known only to the prover:

```
opcodeSeq[]   : uint5[N]  — TRI-27 opcode sequence (5-bit each, 32 opcodes max)
regStates[]   : uint16[N+1] — accumulator state at each step (initial + N outputs)
mantPartials  : uint8[]   — partial products from tri_mant_mul operations
vrfSeed       : bytes32   — chip-private VRF seed (used to derive anchorHash)
rewardAmounts : uint2[N]  — reward per attest pulse (1-4 tokens, from config)
```

The **opcode sequence compression**: because TRI-27 has a 27-opcode ISA, each opcode fits in 5 bits. A 64-opcode batch requires 320 bits = 40 bytes of witness space, well within practical limits.

### 2.4 Constraint System Structure

The circuit is organized in layers:

```
[AnchorCheck] × N     — verify anchor register = 0x47C0 at each step
[OpcodeValid] × N     — verify opcode is in the TRI-27 sacred set
[StateTransition] × N — verify regState[i+1] = execute(regState[i], opcode[i])
[MantMulConstraint]   — verify partial products for mant_mul opcodes
[BalanceAccumulate]   — verify finalBalance = sum of reward pulses
[NonceBinding]        — verify anchorHash = blake3(0x47C0 || epochNonce)
```

#### Constraint Count Estimate

| Constraint Group | Per-Opcode | For 64-Opcode Batch |
|---|---|---|
| AnchorCheck (16-bit equality) | ~16 | ~1,024 |
| OpcodeValid (5-bit range) | ~32 | ~2,048 |
| StateTransition (arithmetic) | ~200 | ~12,800 |
| MantMulConstraint (see §3.3) | ~80 | ~5,120 |
| BalanceAccumulate (running sum) | ~20 | ~1,280 |
| NonceBinding (blake3 circuit) | — | ~30,000 |
| **Total** | — | **~52,272** |

For a 256-opcode batch: ~200K R1CS constraints. Both are feasible with current tooling (Circom + snarkjs). The 64-opcode batch is the recommended starting point.

### 2.5 ISA Opcode Coverage

The TRI-27 ISA defines 27 sacred opcodes. The `opcodeValid` constraint in the circuit encodes a range check: `opcode ∈ {0, 1, ..., 26}`. Opcodes outside this range are rejected at the circuit level, independent of the hardware.

The `stateTransition` constraint must model each opcode's semantic. This is the most labor-intensive part of circuit construction. The initial implementation models a representative subset (ADD, MUL via TriMantMul, LOAD, STORE, ANCHOR_CHECK) and extends in subsequent phases.

---

## 3. Field Arithmetic Mapping

### 3.1 BN254 Scalar Field

Groth16 circuits operate over the scalar field `F_r` where:

```
r = 21888242871839275222246405745257275088548364400416034343698204186575808495617
```

This is a ~254-bit prime. All circuit values must be encoded as elements of `F_r`.

### 3.2 Trinity Custom Format Encodings

The Trinity hardware uses several non-standard number formats that must be mapped to field elements:

| Trinity Format | Bit Width | Encoding in F_r |
|---|---|---|
| NF4 (4-bit float) | 4 bits | uint4 → F_r element directly |
| Posit16 (16-bit posit) | 16 bits | uint16 → F_r element; range check ensures < 65536 |
| GF4 (Galois field 2^2) | 4 bits | uint4 with GF polynomial constraint |
| GF16 (Galois field 2^4) | 4 bits | uint4 with GF16 reduction constraint |
| GF256 (Galois field 2^8) | 8 bits | uint8 with GF256 multiplication constraint |
| TRI balance | 16 bits | uint16 → F_r (same as Posit16 encoding) |
| Anchor (0x47C0) | 16 bits | constant 0x47C0 = 18368 in F_r |

**Key observation:** All Trinity formats fit within 16 bits. A 16-bit field element is trivially encodable in BN254's ~254-bit field with zero information loss. The mapping is injective.

### 3.3 TriMantMul Constraint Set

The `tri_mant_mul` operation is the most complex arithmetic primitive in the Trinity ISA. It computes a 4-bit × 4-bit mantissa multiplication with sacred opcode preservation flag.

From the hardware perspective (`common/tri_mant_mul.v` reference):
- Input: `a[3:0]`, `b[3:0]` (4-bit NF4 mantissas)
- Output: `out[7:0]` (8-bit product), `sacred_flag` (1-bit)
- Method: shift-and-add (R-SI-1 compliant, no multiply operators)

The Circom circuit emulation (see `circuits/trinity_compute.circom.draft`) uses:

```
// 4-bit × 4-bit = 8-bit via shift-and-add decomposition
// Each bit of 'b' selects a conditional add of shifted 'a'
// Total: 4 conditional adds × ~8 constraints each = ~32 constraints
// Plus: range checks on a, b (4 constraints each) = ~8 constraints
// Plus: sacred_flag check (opcode preservation) = ~4 constraints
// TOTAL: ~44 constraints per TriMantMul invocation
```

The `sacred_flag` constraint checks that if the opcode producing this multiplication is in the sacred opcode set (0x47C0 domain), the flag output equals 1. This is a simple lookup constraint.

### 3.4 GF256 Multiplication Constraints

GF256 (used by `tt_um_ghtag_trinity_gf16` module, Euler chip) multiplications in circuit require:
- Bit decomposition of both operands: 8 bits each → 16 boolean constraints
- Carry-less multiplication: 8 partial products → 8 conditional adds
- Polynomial reduction mod `x^8 + x^4 + x^3 + x + 1` (AES irreducible polynomial): ~16 constraints
- **Total: ~64 constraints per GF256 multiplication**

For GF16 (4-bit field): ~16 constraints per multiplication.

Alternatively, lookup table arguments (Plookup / cq) can reduce GF256 multiplication to ~4 constraints, but these require PLONK-family systems, not Groth16. This is noted as a future upgrade path (see §7, Phase 4).

---

## 4. Groth16 Instantiation

### 4.1 Protocol Overview

Groth16 (Jens Groth, 2016) is a pairing-based zk-SNARK with the following properties:
- **Constant proof size:** 192 bytes (2 G1 points + 1 G2 point on BN254)
- **Fast verification:** single multi-scalar multiplication + 3 pairing checks
- **Trusted setup required:** circuit-specific, single-use toxic waste

The protocol operates over the BN254 (alt_bn128) elliptic curve pair:
- G1: y² = x³ + 3 (over F_p, p = 21888242871839275222246405745257275088314845440248939540949405108438)
- G2: defined over F_p² extension

### 4.2 Trusted Setup

Groth16 requires a **circuit-specific structured reference string (SRS)** generated in a trusted setup ceremony. The ceremony produces:

```
proving_key   (pk)  : ~10–50 MB for 100K constraints
verification_key (vk): ~3 KB (independent of constraint count)
toxic_waste         : MUST be destroyed; knowledge allows proof forgery
```

**Recommended approach for Trinity:**

1. **Phase 1 (Universal):** Participate in the [Perpetual Powers of Tau](https://github.com/privacy-scaling-explorations/perpetualpowersoftau) ceremony (Ethereum PSE). Use a contribution ≥ `2^17` constraints to accommodate the Trinity circuit.
2. **Phase 2 (Circuit-specific):** Run a small internal ceremony with 3–5 participants (e.g., core team members + external audit partner). Each participant contributes randomness and destroys their toxic waste.
3. **Ceremony software:** [snarkjs phase2](https://github.com/iden3/snarkjs#7-prepare-phase-2) or [p0tion](https://github.com/privacy-scaling-explorations/p0tion) for a production ceremony.

**Security assumption:** At least one ceremony participant honestly destroyed their toxic waste. With 5 participants, this assumption is extremely conservative. Future migration to PLONK (universal setup, see §9) eliminates this assumption entirely.

### 4.3 Proving Key and Verification Key

For the 64-opcode batch circuit (~52K R1CS constraints):

| Parameter | Estimate |
|---|---|
| R1CS constraints | ~52,272 |
| Proving key size (BN254) | ~15 MB |
| Verification key size | ~3.0 KB |
| Proof size | **192 bytes** (constant) |
| Phase 1 powers needed | `2^16` = 65,536 (sufficient) |

For the 256-opcode batch circuit (~200K R1CS constraints):

| Parameter | Estimate |
|---|---|
| R1CS constraints | ~200,000 |
| Proving key size (BN254) | ~60 MB |
| Verification key size | ~3.0 KB |
| Proof size | **192 bytes** (constant) |
| Phase 1 powers needed | `2^18` = 262,144 |

### 4.4 Proof Structure

A Groth16 proof over BN254 is a tuple `(A, B, C)` where:
- `A` : G1 point = (uint256, uint256) = 64 bytes
- `B` : G2 point = (uint256, uint256, uint256, uint256) = 128 bytes  
- `C` : G1 point = (uint256, uint256) = 64 bytes
- **Total: 192 bytes**

The Solidity representation:

```solidity
struct Proof {
    uint256[2]    a;   // G1 point
    uint256[2][2] b;   // G2 point
    uint256[2]    c;   // G1 point
}
```

### 4.5 On-Chain Verification Cost

The EVM provides BN254 pairing as a precompile at address `0x08` ([EIP-197](https://eips.ethereum.org/EIPS/eip-197)) and elliptic curve operations at `0x06` and `0x07` ([EIP-196](https://eips.ethereum.org/EIPS/eip-196)).

Groth16 verification requires:
- 3 pairing operations (via `ecPairing` precompile at `0x08`)
- Cost: `45,000 + 34,000 × 3 = 147,000` base gas + ~100K overhead for scalar mul and memory

**Total: ~250,000 gas per proof verification**

Comparison: a standard 2-of-3 `ecrecover` signature check costs ~80,000 gas. ZK verification is ~3× more expensive but provides stronger guarantees and single-chip support.

At 30 gwei gas price and $3,000 ETH price:  
`250,000 × 30e-9 ETH × $3,000 = $0.0225 per verification`

For hourly epochs aggregating 3,600 work cycles, this is economically viable.

---

## 5. Verifier Outline

### 5.1 Solidity Verifier Generation

The recommended toolchain for generating a Solidity verifier:

1. **Circom 2.x** — circuit language (see `circuits/trinity_compute.circom.draft`)
2. **snarkjs** — compiles Circom → R1CS → witness generation → Groth16 prove/verify
3. **snarkjs exportSolidityVerifier** — auto-generates a Solidity verifier contract

The generated verifier is a self-contained contract (~300 lines) that:
- Hardcodes the verification key as Solidity constants
- Implements the Groth16 verification equation using BN254 precompiles
- Exposes `function verifyProof(uint[2], uint[2][2], uint[2], uint[]) public view returns (bool)`

The `verifier_outline.sol` in this directory provides the integration wrapper around the auto-generated verifier.

### 5.2 Verification Key Structure

The verification key for a Groth16 circuit consists of:

```
vk.alpha : G1 point
vk.beta  : G2 point
vk.gamma : G2 point
vk.delta : G2 point
vk.IC[]  : array of G1 points, one per public input + 1
```

For 5 public inputs (chipSerial, opcodeCount, finalBalance, epochNonce, anchorHash), `vk.IC` has 6 entries.

The full verification key is hardcoded in the Solidity contract after the trusted setup ceremony produces final values.

### 5.3 Integration with TRIBridge

The `TrinityComputeVerifier` contract (see `verifier_outline.sol`) integrates with the TRIBridge via the `verifyAndClaim` function:

```
TRIBridge.submitProofClaim(proof, publicInputs)
  → TrinityComputeVerifier.verifyProof(proof, publicInputs) → bool
  → if true: TRIToken.mint(msg.sender, publicInputs.finalBalance)
  → if false: revert("Invalid ZK proof")
```

### 5.4 Hybrid Mode Design

Trinity supports two trust modes:

**Mode A — ZK-primary (single-chip claims):**
- Chip generates opcode log + ZK proof off-chain
- Submits `(proof, publicInputs)` to bridge
- Bridge verifies proof via `TrinityComputeVerifier`
- No oracle signatures required
- Appropriate for: solo chip rewards, privacy-preserving claims, claims < 100 $TRI

**Mode B — M-of-N primary (high-value claims):**
- All 3 chips in Triad attest independently
- 2-of-3 oracle signatures required on bridge
- Optional: also submit ZK proof for additional security
- Appropriate for: claims ≥ 100 $TRI, institutional operators, audit scenarios

**Fallback rule:** If a ZK proof fails verification but the operator holds valid M-of-N attestations, the bridge falls back to Mode B automatically. This ensures backward compatibility during the ZK rollout phase.

---

## 6. Performance Targets

### 6.1 Proof Generation (Off-Chain)

Proof generation runs entirely off-chain on the operator's device (laptop, server, or dedicated prover). It requires access to:
- The chip's opcode log for the epoch (emitted via serial/USB)
- The proving key (downloaded once, ~15–60 MB)
- The epoch nonce (from chain)

| Metric | Target | Notes |
|---|---|---|
| Proof generation time | 5–30 seconds | On a modern laptop (2022+, 8-core) |
| RAM requirement | < 2 GB | snarkjs WASM prover peak |
| Proving key download | One-time, ~15–60 MB | Cached locally |
| Opcode log size (64 ops) | 40 bytes | 5 bits × 64 = 320 bits |
| Opcode log size (256 ops) | 160 bytes | 5 bits × 256 = 1280 bits |

For production deployments, a dedicated **prover service** (see §7, Phase 3) can batch multiple epoch proofs and use GPU acceleration to reduce generation time to < 2 seconds.

### 6.2 Epoch Structure

The recommended epoch configuration:
- **Epoch duration:** 1 hour (3,600 seconds)
- **Work cycles per epoch:** ~3,600 (one per second average)
- **Proof frequency:** 1 proof per epoch (aggregates all epoch work)
- **Opcode batch size:** 64 opcodes per proof (multiple proofs per epoch if needed)

For 3,600 work cycles per epoch with 64 opcodes each: the operator generates `3600/64 ≈ 56` proofs per epoch, or uses a recursive aggregation scheme (Phase 4) to reduce to 1 aggregated proof.

### 6.3 Memory and Storage

| Resource | Requirement |
|---|---|
| RAM (proving) | < 2 GB |
| RAM (verification, on-chain) | N/A (EVM precompile) |
| Proving key storage | 15–60 MB (one-time) |
| Proof storage | 192 bytes per proof |
| Opcode log buffer (chip-side) | 40–160 bytes per epoch |

The Trinity chip's minimal onboard memory is sufficient to buffer a 64-opcode log for later proof generation by the host system.

---

## 7. Implementation Roadmap

### Phase 1 — Circuit Prototype (Weeks 1–6)

**Goal:** Working Circom circuit that compiles and generates correct proofs for a simple test case.

**Deliverables:**
- `zk/circuits/trinity_compute.circom` — full Circom 2.x circuit
- `zk/circuits/trinity_compute.r1cs` — compiled constraint system
- `zk/circuits/trinity_compute.wasm` — witness generation module
- Test vectors: 3 positive cases, 1 negative case (invalid anchor)

**Key tasks:**
- Implement `TriMantMul` template (4-bit × 4-bit in-circuit)
- Implement `OpcodeStep` for ISA subset (ADD, MUL, ANCHOR_CHECK)
- Implement blake3 sub-circuit for `anchorHash` computation
- CI: snarkjs compile + proof generation in GitHub Actions

**File location:** `NeuronConstant/zk/circuits/trinity_compute.circom` (to be created in Phase 1; draft in `docs/zk/circuits/trinity_compute.circom.draft` now)

### Phase 2 — Trusted Setup Ceremony (Weeks 7–10)

**Goal:** Generate production proving and verification keys.

**Deliverables:**
- Phase 1 contribution to Perpetual Powers of Tau (≥ 2^17)
- Phase 2 ceremony transcript (3–5 participants minimum)
- Final `proving_key.zkey` and `verification_key.json`
- Ceremony audit report

**Key tasks:**
- Set up ceremony infrastructure (p0tion or manual snarkjs ceremony)
- Recruit external participants (ideally: PSE member, independent auditor)
- Publish all ceremony contributions for auditability

### Phase 3 — On-Chain Integration (Weeks 11–16)

**Goal:** Deploy `TrinityComputeVerifier` and integrate with TRIBridge.

**Deliverables:**
- `contracts/TrinityComputeVerifier.sol` — auto-generated + integration wrapper
- `contracts/TRIBridge.sol` integration (call `verifyAndClaim`)
- Gas benchmarks on testnet
- `trinity-prove` CLI tool specification (see §INTEGRATION.md)

**Key tasks:**
- Export Solidity verifier from snarkjs with production VK
- Update TRIBridge to accept ZK proof claims (Mode A, §5.4)
- End-to-end test: chip emulator → opcode log → proof → on-chain verify
- Security audit of verifier contract

### Phase 4 — ZK Aggregation (Weeks 17–26)

**Goal:** Aggregate multiple epoch proofs into one on-chain verification.

**Deliverables:**
- Recursive SNARK circuit (Groth16 in-circuit verification, or migrate to PLONK/Halo2)
- Aggregation reduces 56 proofs/epoch → 1 proof/epoch
- Gas cost reduction: 250K → 250K (same per epoch, but covers 56× more work)

**Options evaluated:**
- **Nova/HyperNova** (incremental verifiable computation) — best for sequential opcode chains
- **PLONK with universal setup** — eliminates circuit-specific trusted setup
- **Halo2 (IPA commitment)** — no pairing, no trusted setup, but larger proofs

### Phase 5 — Quantum Resistance Migration (Long-term, 2026+)

**Goal:** Migrate from Groth16 (broken by Shor's algorithm) to post-quantum proof systems.

**Candidates:**
- **STARKs** (e.g., RISC Zero, Polygon Miden) — quantum-resistant, no trusted setup, larger proofs (~50 KB)
- **Lattice-based SNARKs** (e.g., Lasso, Binius) — experimental, very small proofs, active research area
- **STARK-SNARK hybrids** (e.g., Plonky3 over Goldilocks field) — fast proving, recursive-friendly

Migration trigger: credible quantum computing roadmap approaching `2^128` qubit scale for Shor attacks on BN254.

---

## 8. Security Analysis

### 8.1 Groth16 Soundness

The Groth16 proof system is **computationally sound** under the **q-DLOG** (q-discrete logarithm) assumption on BN254. Concretely:

- An adversary cannot produce a valid proof for a false statement without solving a discrete logarithm problem in a group of order ~2^254
- Current classical cryptanalysis: no known attack better than generic DLP in this group
- Security level: ~128 bits

**Soundness gap:** Groth16 achieves *computational* soundness, not *unconditional* (statistical) soundness. This is standard for SNARKs.

### 8.2 Trusted Setup Assumptions

**Critical weakness of Groth16:** If *all* ceremony participants collude or are compromised, the toxic waste can be used to forge proofs for any statement. This is the `"toxic waste"` problem.

**Mitigation:**
- Multi-party ceremony with diverse, geographically distributed participants
- At least one participant from an independent security firm
- Public ceremony transcript for post-hoc verification
- Future: migrate to PLONK (universal setup) or STARK (no setup) — see §7 Phase 4/5

### 8.3 Cloned/Emulated Chip Attacks

**Attack:** Adversary clones TT SKY26b hardware (or emulates it in software) to falsely claim compute rewards.

**ZK mitigation:** The circuit's private witness includes the chip's VRF seed (`vrfSeed : bytes32`). This seed is hardware-generated during chip manufacturing and is not recoverable from the chip's external interface (assuming secure key storage). Without the VRF seed, the adversary cannot generate a circuit witness that satisfies the `anchorHash` constraint, and therefore cannot produce a valid proof.

**Residual risk:** Physical extraction of the VRF seed from a chip sample via invasive techniques (focused ion beam, etc.). This is an out-of-scope hardware security concern; see `THREAT_MODEL.md`.

### 8.4 Replay Attacks

**Attack:** Adversary submits a valid proof from epoch `E` again in epoch `E+1`.

**Mitigation:** The `epochNonce` public input is a monotonic counter. The bridge contract maintains a `usedNonces` mapping. A proof with an already-used `(chipSerial, epochNonce)` pair is rejected at the contract level, independent of proof validity.

### 8.5 Side-Channel Attacks on the Prover

**Attack:** Adversary observes timing or power consumption during proof generation to extract the private witness (opcode sequence or VRF seed).

**Mitigation:** Proof generation is an off-chain software process. It should be run in a trusted environment (the chip operator's machine). Side-channel resistance of the snarkjs prover is not guaranteed; this is out of scope for the ZK spec but should be addressed in operational security guidelines.

### 8.6 Witness Extraction and Knowledge Soundness

Groth16 is a **proof of knowledge** (more precisely, an argument of knowledge). The *knowledge extractor* theorem guarantees that a computationally bounded prover who produces a valid proof must "know" a valid witness. This is exactly the property needed to ensure operators cannot claim rewards for compute they did not perform.

The knowledge soundness rests on the **q-DLOG** assumption (and implicitly on the generic group model for the specific algebraic structure of Groth16 verification equations).

### 8.7 Quantum Resistance

**Groth16 is NOT quantum-resistant.** Shor's algorithm (run on a sufficiently large quantum computer) can solve the elliptic curve discrete logarithm problem on BN254 in polynomial time, breaking both soundness and zero-knowledge.

**Current timeline (2025 assessment):** No quantum computer threatens BN254 in the foreseeable near term. The largest known quantum computers have a few thousand noisy qubits; breaking BN254 requires millions of fault-tolerant logical qubits.

**Migration path:**
1. **Phase 5 (see §7):** Migrate to STARKs (e.g., RISC Zero, StarkWare Stwo) — quantum-resistant, no trusted setup
2. **Monitoring trigger:** When IBM/Google/IonQ announce credible path to 10,000+ fault-tolerant logical qubits, begin Phase 5 immediately
3. **Hybrid transition:** During migration, run both Groth16 and STARK proofs simultaneously; require both for high-value claims

---

## 9. Comparison: Groth16 vs PLONK vs STARK

| Property | Groth16 | PLONK (KZG) | PLONK (IPA/Halo2) | STARK |
|---|---|---|---|---|
| Proof size | **192 bytes** | ~640 bytes | ~10–40 KB | ~50–200 KB |
| Verification gas (EVM) | **~250K** | ~400K | High (no precompile) | ~500K–2M |
| Proving time (100K constraints) | ~5–15 sec | ~10–30 sec | ~15–40 sec | ~5–20 sec |
| Trusted setup | Circuit-specific | Universal (one per domain size) | **None** | **None** |
| Quantum resistance | **No** | **No** | **No** | **Yes** |
| EVM precompile support | Yes (BN254, EIP-196/197) | Partial (KZG EIP-4844) | No | Limited |
| Recursive proofs | Complex | Native (PLONK folding) | Native (Halo2 IPA) | Native |
| Circom/tooling maturity | **Excellent** | Good | Moderate | Moderate |
| Circuit language | Circom, Bellman | Halo2, Noir | Halo2, Noir | Cairo, Miden |

**Recommendation for Trinity DePIN:**

- **Phase 1–3:** Use Groth16. Smallest proofs (192 bytes), cheapest EVM verification (~250K gas), best tooling (Circom + snarkjs), works with existing BN254 precompiles.
- **Phase 4:** Evaluate PLONK (KZG) for universal setup (eliminates circuit-specific ceremony burden). EIP-4844 brings KZG commitments to EVM with better support.
- **Phase 5:** Migrate to STARK (e.g., Polygon Miden or RISC Zero) for quantum resistance.

The primary reason to delay PLONK adoption is tooling maturity: Circom + snarkjs has the largest ecosystem, most documentation, and most audited circuits for the types of arithmetic used in Trinity's ISA emulation.

---

## 10. References

1. **Groth16 paper:** Groth, J. (2016). "On the Size of Pairing-Based Non-interactive Arguments." EUROCRYPT 2016. https://eprint.iacr.org/2016/260.pdf

2. **Circom documentation:** iden3. "Circom 2.0 Documentation." https://docs.circom.io/

3. **snarkjs:** iden3. "snarkjs — zkSNARK implementation in JavaScript." https://github.com/iden3/snarkjs

4. **EIP-196 (BN254 elliptic curve operations):** Buterin et al. https://eips.ethereum.org/EIPS/eip-196

5. **EIP-197 (BN254 optimal ate pairing):** Buterin et al. https://eips.ethereum.org/EIPS/eip-197

6. **Perpetual Powers of Tau:** Ethereum PSE. https://github.com/privacy-scaling-explorations/perpetualpowersoftau

7. **p0tion ceremony tool:** Ethereum PSE. https://github.com/privacy-scaling-explorations/p0tion

8. **BN254 curve parameters:** https://neuromancer.sk/std/bn/bn254

9. **Plonky3 (future migration candidate):** https://github.com/Plonky3/Plonky3

10. **RISC Zero (STARK prover):** https://github.com/risc0/risc0

11. **NeuronConstant v1.0.0 hardware modules:** gHashTag/Dmitrii Vasilev. DOI: 10.5281/zenodo.19227877. https://github.com/gHashTag/NeuronConstant

12. **tri_token_accumulator.v:** On-chip $TRI hardware accumulator. `NeuronConstant/common/depin/tri_token_accumulator.v`

13. **sacred_constants_rom.v:** 0x47C0 anchor ROM. `NeuronConstant/common/constants/sacred_constants_rom.v`

---

*This specification is part of DePIN improvement #10 of 10. Existing v1.0.0 modules (NF4, Posit16, GF4/16/256, sacred opcodes, tri_mant_mul) are referenced for field arithmetic mapping but are not modified.*
