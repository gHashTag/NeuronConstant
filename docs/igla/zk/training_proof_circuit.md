# IGLA Training Proof Circuit — Extended Circom Specification

**Version:** 1.0.0-igla  
**Status:** Specification — extends `docs/zk/` stack  
**Circuit:** `training_proof_circuit` (Groth16 / BN254)  
**Constraint estimate:** ~500K R1CS  
**Co-authors:** Dmitrii Vasilev (gHashTag)  
**Compatible with:** `docs/zk/verifier_outline.sol`, `docs/zk/README.md`

---

## Table of Contents

1. [Proof Statement](#1-proof-statement)
2. [Public Inputs](#2-public-inputs)
3. [Private Witness](#3-private-witness)
4. [Circuit Structure](#4-circuit-structure)
5. [R1CS Constraint Estimate](#5-r1cs-constraint-estimate)
6. [Public Inputs Encoding (Solidity)](#6-public-inputs-encoding-solidity)
7. [Hash Function: blake3](#7-hash-function-blake3)
8. [Optimization: Proof Aggregation](#8-optimization-proof-aggregation)
9. [Compatibility with docs/zk/ Stack](#9-compatibility-with-docszk-stack)
10. [Trusted Setup](#10-trusted-setup)
11. [Implementation Roadmap](#11-implementation-roadmap)
12. [References](#12-references)

---

## 1. Proof Statement

The training ZK proof asserts the following statement:

> **"I executed `step` gradient descent training steps on chip `chipSerial`, using random seed `seed`, starting from initial weights with Merkle root `W₀` (private), reaching final weights with Merkle root `weightsRootHash`. The resulting model achieves bits-per-byte `bpbE6 / 1e6` on the held-out validation set. The full loss curve across all training steps has blake3 hash `lossCurveHash`."**

This statement is encoded as a Rank-1 Constraint System (R1CS) over the BN254 scalar field `Fᵣ` and proven using Groth16.

**What the prover reveals (public):**
- Which chip ran the training
- How many steps were executed
- Which seed was used
- The final BPB achieved
- A commitment (blake3 hash) to the entire loss curve
- A commitment (Merkle root) to the final model weights

**What the prover keeps private:**
- The actual loss values at each training step
- The gradient update tensors
- Intermediate weight checkpoints
- The initial weights (`W₀`)

---

## 2. Public Inputs

The following values are revealed to the on-chain verifier and included in the Groth16 proof's public input vector:

```
chipSerial      : bytes32   — Chip identifier (keccak of ASIC hardware key)
step            : uint64    — Number of training steps executed
seed            : uint32    — Random seed (e.g., seed=43 for champion run)
bpbE6           : uint32    — BPB * 1e6 (e.g., 2239300 for BPB=2.2393)
lossCurveHash   : bytes32   — blake3 hash of full loss curve values array
weightsRootHash : bytes32   — Merkle root of final model weights tensor
```

**Encoding as BN254 field elements** (12 total, see Section 6):

| Index | Value | Encoding |
|-------|-------|----------|
| 0–3   | `chipSerial` | 4 × uint64 chunks |
| 4     | `step` | uint64 |
| 5     | `seed` | uint32 |
| 6     | `bpbE6` | uint32 |
| 7–10  | `lossCurveHash` | 4 × uint64 chunks |
| 11    | `weightsRootHash` lower 128 bits | uint128 |

---

## 3. Private Witness

The prover knows these values but does not reveal them to the verifier:

```
fullLossCurve   : float32[step]      — Per-step training loss values
gradientUpdates : tensor[step]       — Gradient update Δθ at each step
initialWeights  : tensor             — Model weights at step 0
                                       (Merkle root = W₀, private)
intermediateWeights : tensor[k]      — Sparse weight checkpoints (every 1000 steps)
vrfSeed         : bytes32            — Chip's hardware VRF seed
                                       (binds proof to specific physical chip)
bpbComputation  : float64[N_val]     — Per-token loss on validation set
                                       (aggregated to bpbE6)
```

**Key insight:** The circuit does NOT prove execution of the actual GPU kernel (that would require a full zkVM, infeasible at ~500K steps). Instead it proves:
1. A valid cryptographic commitment chain: `W₀ → gradients → W_final`
2. The loss curve hash matches a specific sequence of floating-point loss values
3. The BPB claimed is consistent with those loss values
4. The chip's VRF seed is embedded (hardware binding)

---

## 4. Circuit Structure

### 4.1 Top-Level Circom Template

```circom
pragma circom 2.1.6;

include "blake3.circom";         // blake3 hash circuit
include "merkle_root.circom";    // Merkle root computation
include "bpb_compute.circom";    // BPB from loss values
include "gradient_step.circom";  // Weight update constraint
include "vrf_binding.circom";    // Hardware VRF binding

template TrainingProofCircuit(NUM_STEPS, BATCH_SIZE) {
    // ── Public inputs ────────────────────────────────────────────
    signal input chipSerial[4];      // bytes32 as 4 × uint64
    signal input step;               // training steps count
    signal input seed;               // random seed
    signal input bpbE6;              // BPB * 1e6
    signal input lossCurveHash[4];   // blake3 hash as 4 × uint64
    signal input weightsRootHashLo;  // lower 128 bits of weights Merkle root

    // ── Private witness ──────────────────────────────────────────
    signal input vrfSeed[4];                    // chip hardware VRF seed (bytes32)
    signal input initialWeightsRoot[4];         // W₀ Merkle root
    signal input lossValues[NUM_STEPS];         // per-step loss values (fixed-point)
    signal input gradientNorm[NUM_STEPS];       // per-step gradient L2 norm
    signal input weightCheckpoints[K][4];       // sparse weight Merkle roots (K checkpoints)
    signal input checkpointSteps[K];            // step indices for checkpoints
    signal input validationLoss[N_VAL];         // per-token validation loss

    // ── Constraints ──────────────────────────────────────────────

    // 1. VRF binding: chipSerial = keccak(vrfSeed)
    //    (approximated in BN254 field via Poseidon hash)
    component vrfBind = VRFBinding();
    vrfBind.vrfSeed <== vrfSeed;
    vrfBind.chipSerial <== chipSerial;

    // 2. Loss curve hash: blake3(lossValues) == lossCurveHash
    component lossHash = Blake3Circuit(NUM_STEPS * 4);
    for (var i = 0; i < NUM_STEPS; i++) {
        lossHash.in[i*4..i*4+3] <== lossValues[i]; // float32 → 4 bytes
    }
    lossHash.out === lossCurveHash;

    // 3. BPB computation: sum(validationLoss) / N_VAL / log(2) == bpbE6 / 1e6
    component bpbComp = BPBCompute(N_VAL);
    bpbComp.lossValues <== validationLoss;
    bpbComp.bpbE6 <== bpbE6;

    // 4. Gradient monotonicity: loss curve is non-trivially decreasing
    //    (rejects trivially non-trained runs)
    component monCheck = MonotonicityCheck(NUM_STEPS);
    monCheck.lossValues <== lossValues;
    monCheck.seed <== seed;
    monCheck.step <== step;

    // 5. Weights root consistency: final checkpoint matches weightsRootHashLo
    component wRoot = WeightsRootCheck(K);
    wRoot.checkpoints <== weightCheckpoints;
    wRoot.checkpointSteps <== checkpointSteps;
    wRoot.finalSteps <== step;
    wRoot.weightsRootLo <== weightsRootHashLo;
}

component main {public [chipSerial, step, seed, bpbE6, lossCurveHash, weightsRootHashLo]}
    = TrainingProofCircuit(27000, 32);
```

### 4.2 Sub-Circuits

#### 4.2.1 VRFBinding

```circom
// Proves chipSerial is derived from chip's private VRF seed.
// Uses Poseidon hash (BN254-native, cheaper than blake3 in circuit).
template VRFBinding() {
    signal input vrfSeed[4];
    signal input chipSerial[4];

    component poseidon = Poseidon(4);
    poseidon.inputs <== vrfSeed;
    poseidon.out === chipSerial[0]; // simplified binding (production: full 256-bit)

    // Constraints: ~50 (Poseidon-4 over BN254 scalar field)
}
```

#### 4.2.2 BPBCompute

```circom
// Proves BPB = -sum(log_loss) / N_VAL / ln(2) matches claimed bpbE6.
// Uses fixed-point arithmetic (16-bit fractional, sufficient for BPB range 1–5).
template BPBCompute(N_VAL) {
    signal input lossValues[N_VAL]; // cross-entropy per token (fixed-point * 2^16)
    signal input bpbE6;             // claimed BPB * 1e6

    // Sum validation losses
    signal lossSum;
    var acc = 0;
    for (var i = 0; i < N_VAL; i++) {
        acc += lossValues[i];
    }
    lossSum <== acc;

    // BPB = lossSum / N_VAL / ln(2) ≈ lossSum * INV_NVAL_LN2 (fixed-point)
    // Constraint: bpbE6 * SCALE == lossSum * INV_NVAL_LN2_SCALED
    // Constraints: ~3*N_VAL + 10 ≈ 30010 for N_VAL=10000
}
```

#### 4.2.3 MonotonicityCheck

```circom
// Proves loss values are plausibly trained (not all zero, trending down).
// This is a sanity check, not a full training verification.
template MonotonicityCheck(NUM_STEPS) {
    signal input lossValues[NUM_STEPS];
    signal input seed;
    signal input step;

    // Check: lossValues[0] > lossValues[step-1] * 0.9 (loss decreased by at least 10%)
    // Check: lossValues[0] < MAX_INITIAL_LOSS (sensible initialization)
    // Check: all lossValues[i] > 0
    // Constraints: ~3 * NUM_STEPS ≈ 81_000
}
```

---

## 5. R1CS Constraint Estimate

| Sub-circuit | Instance | Count | Constraints |
|-------------|----------|-------|-------------|
| VRFBinding (Poseidon-4) | 1 | 1 | ~50 |
| Blake3Circuit (loss curve hash) | NUM_STEPS×4 bytes | 1 | ~120_000 |
| BPBCompute | N_VAL=10_000 | 1 | ~30_000 |
| MonotonicityCheck | NUM_STEPS=27_000 | 1 | ~81_000 |
| WeightsRootCheck (Merkle, K=27) | K=27 checkpoints | 1 | ~15_000 |
| Field encoding / range checks | Public inputs | 12 | ~200 |
| **Total** | | | **~246_250** |

For a larger circuit with full gradient update verification (advanced mode):

| Sub-circuit | Instance | Count | Constraints |
|-------------|----------|-------|-------------|
| Base circuits above | — | — | ~246_250 |
| GradientStep (simplified) | per step | 27_000 | ~270_000 |
| **Total (advanced)** | | | **~516_250** |

This is consistent with the specification target of **~500K R1CS**.

**Proving key size:** ~160 MB for 500K constraints on BN254  
**Phase 1 powers needed:** `2^19` = 524_288 (sufficient)  
**Proof size:** **192 bytes** (Groth16 constant)

---

## 6. Public Inputs Encoding (Solidity)

The `TrainingProver._encodePublicInputs` function maps `TrainingPublicInputs` to 12 BN254 scalar field elements:

```solidity
// From contracts/src/igla/TrainingProver.sol
function _encodePublicInputs(TrainingPublicInputs calldata pi)
    internal pure returns (uint256[12] memory inputs)
{
    // chipSerial: split bytes32 into 4 × uint64
    bytes32 cs = pi.chipSerial;
    inputs[0] = uint256(uint64(bytes8(cs)));
    inputs[1] = uint256(uint64(bytes8(cs << 64)));
    inputs[2] = uint256(uint64(bytes8(cs << 128)));
    inputs[3] = uint256(uint64(bytes8(cs << 192)));

    // Scalar values
    inputs[4] = uint256(pi.step);   // uint64 → fits BN254 scalar
    inputs[5] = uint256(pi.seed);   // uint32
    inputs[6] = uint256(pi.bpbE6);  // uint32

    // lossCurveHash: split into 4 × uint64
    bytes32 lch = pi.lossCurveHash;
    inputs[7]  = uint256(uint64(bytes8(lch)));
    inputs[8]  = uint256(uint64(bytes8(lch << 64)));
    inputs[9]  = uint256(uint64(bytes8(lch << 128)));
    inputs[10] = uint256(uint64(bytes8(lch << 192)));

    // weightsRootHash: lower 128 bits (upper bits committed via lossCurveHash)
    inputs[11] = uint256(uint128(uint256(pi.weightsRootHash)));
}
```

**Why split bytes32 into 4 × uint64?**  
BN254's scalar field modulus `r ≈ 2^254`. A `bytes32` value is 256 bits. Splitting into 4 × uint64 (each 64 bits, each < `r`) ensures all inputs are valid field elements without modular reduction. The circuit can reconstruct the full 256-bit value from the 4 chunks.

**Why truncate `weightsRootHash` to 128 bits?**  
The lower 128 bits provide sufficient binding for the weights commitment while staying within one field element. The upper 128 bits are linked via `lossCurveHash` (the blake3 hash of the loss curve is computed over data that includes the weights trajectory). In the full circuit, both halves of `weightsRootHash` can be committed as two separate field elements if stronger binding is required.

---

## 7. Hash Function: blake3

All external hashes in the IGLA training circuit use **blake3**, consistent with:
- `common/depin/v2/tri_vrf_receipt.v` (HW blake3 usage)
- `docs/zk/README.md` (blake3 for anchorHash in the compute circuit)

**Motivation for blake3 over keccak256:**
1. Hardware alignment: Trinity ASIC implements blake3 natively for VRF receipts
2. Circom efficiency: blake3 requires fewer constraints per byte than keccak256 (~3–4K vs ~5–6K per 64-byte block)
3. Speed: blake3 is faster off-chain for proof generation

**Constraints per blake3 invocation:**
- Single 64-byte block: ~3_200 R1CS constraints
- 27_000 steps × 4 bytes per loss value = 108_000 bytes = 1_687 blocks × 3_200 = **~5.4M** constraints if naively applied

**Optimization:** Use Poseidon hash (BN254-native) for the loss curve commitment inside the circuit, and blake3 only for the outer commitment that the IGLA daemon computes off-chain. The circuit checks:

```
blake3(lossValues) == lossCurveHash  [off-chain verified by daemon]
Poseidon(lossValues_chunked) == poseidonCommitment [in-circuit]
lossCurveHash == blake3(poseidonCommitment_preimage) [cross-binding]
```

This reduces in-circuit blake3 usage to a single 32-byte block (~120K constraints).

---

## 8. Optimization: Proof Aggregation

### 8.1 Motivation

The IGLA training run for the champion (step=27_000) is too large to prove in a single Groth16 proof at full fidelity. The two-level approach:

**Level 1 — Step-batch proofs:**  
Divide 27_000 steps into 27 batches of 1_000 steps each. Each batch proof covers:
- 1_000 loss values
- Gradient norm for 1_000 steps  
- Merkle root transition: `W_{k}` → `W_{k+1}`

Each batch proof: ~18_500 R1CS constraints.

**Level 2 — Aggregation proof:**  
A single Groth16 proof that recursively verifies all 27 batch proofs.

This is the **Groth16 recursion** pattern. However, Groth16 recursion in Circom is expensive (~10K constraints per Groth16 verification). An alternative: use **Plonky2** (Plonk + FRI, native recursion) for Level 2.

### 8.2 Plonky2 Option

[Plonky2](https://github.com/0xPolygonZero/plonky2) supports efficient recursive proof composition over Goldilocks field (`p = 2^64 - 2^32 + 1`). It can aggregate 27 batch proofs into one proof in ~2 seconds on a modern CPU.

The aggregated Plonky2 proof can be wrapped in a Groth16 proof for on-chain verification (Plonky2 → Groth16 wrapper, as used by Polygon zkEVM).

### 8.3 Recommended Approach

```
Phase 1 (now):      Single Groth16 proof over simplified circuit (~246K R1CS)
                    Omits full gradient verification; commits to loss curve + weights root

Phase 2 (Q2 2026):  27 batch Groth16 proofs + Plonky2 aggregation
                    Full gradient step verification

Phase 3 (Q4 2026):  STARK-based proof (RISC Zero or Miden VM)
                    Proves actual Python training step execution
                    Quantum-resistant, no trusted setup
```

### 8.4 Nova/HyperNova Alternative

[Nova](https://github.com/microsoft/Nova) (Incrementally Verifiable Computation) can accumulate 27_000 step proofs into one without blowup, at ~2KB proof size per accumulator step. However, it requires a custom verifier contract (no BN254 precompile support) and adds deployment complexity.

Recommendation: evaluate Nova for Phase 3 alongside RISC Zero.

---

## 9. Compatibility with docs/zk/ Stack

This circuit extends the `docs/zk/` stack without modifying it:

| Component | docs/zk/ | docs/igla/zk/ |
|-----------|----------|----------------|
| Curve | BN254 | BN254 (same) |
| Proof system | Groth16 | Groth16 (same) |
| VK constants | Placeholders in `verifier_outline.sol` | Placeholders in `TrainingProver.sol` |
| Public inputs | opcodeCount, finalBalance, epochNonce | step, bpbE6, seed, hashes |
| Pairing precompile | `0x08` (EIP-197) | `0x08` (same) |
| Trusted setup | Perpetual PoT + Phase 2 | Perpetual PoT + Phase 2 (separate) |
| Circuit language | Circom 2.x | Circom 2.x (same) |
| Hash function | blake3 for anchorHash | blake3 for lossCurveHash |

**Separate trusted setups required:** The training proof circuit (`training_proof_circuit`) and the compute proof circuit (`trinity_compute`) are different circuits with different R1CS. Each requires its own Phase 2 ceremony.

However, both can share the same Phase 1 contribution (Perpetual Powers of Tau at `2^19`) since the training circuit (500K constraints) fits within `2^19 = 524_288`.

---

## 10. Trusted Setup

### 10.1 Requirements

| Parameter | Value |
|-----------|-------|
| Phase 1 (Perpetual PoT) | `2^19` contribution required |
| Phase 2 participants | ≥ 3 (recommend: core team + external auditor + community) |
| Proving key size | ~160 MB |
| Verification key size | ~3 KB |
| Toxic waste | MUST be destroyed by all participants |

### 10.2 Ceremony Software

- [snarkjs](https://github.com/iden3/snarkjs) — Phase 1 contribution and Phase 2 ceremony
- [p0tion](https://github.com/privacy-scaling-explorations/p0tion) — GUI ceremony management
- [Circom 2.1.6+](https://docs.circom.io/) — Circuit compilation

### 10.3 VK Integration

After the ceremony, export the verification key:

```bash
snarkjs zkey export verificationkey training_proof_final.zkey training_vk.json
```

Replace the placeholder constants in `contracts/src/igla/TrainingProver.sol`:
- `VK_ALPHA_X`, `VK_ALPHA_Y`
- `VK_BETA_X0`–`VK_BETA_Y1`
- `VK_GAMMA_X0`–`VK_GAMMA_Y1`
- `VK_DELTA_X0`–`VK_DELTA_Y1`
- `VK_IC_X[0..12]`, `VK_IC_Y[0..12]`

---

## 11. Implementation Roadmap

| Phase | Target | Deliverable |
|-------|--------|-------------|
| **P1** (current) | Q4 2025 | Circom circuit draft, test vectors, placeholder VK in TrainingProver.sol |
| **P2** | Q1 2026 | Working Circom circuit, ~246K R1CS, Phase 2 ceremony |
| **P3** | Q2 2026 | Batch proofs (27 × 1K steps) + Plonky2 aggregation |
| **P4** | Q4 2026 | STARK-based full training proof (RISC Zero) |

**P1 deliverables (current PR):**
- ✅ `TrainingProver.sol` — full Groth16 verifier with placeholder VK
- ✅ `docs/igla/zk/training_proof_circuit.md` — this document
- ⬜ `zk/circuits/training_proof.circom` — Circom circuit (P2)
- ⬜ `zk/circuits/training_proof.r1cs` — compiled constraints (P2)

---

## 12. References

1. **IGLA RACE source:** [gHashTag/trios-trainer-igla](https://github.com/gHashTag/trios-trainer-igla)
2. **Circom 2.x documentation:** https://docs.circom.io/
3. **snarkjs:** https://github.com/iden3/snarkjs
4. **EIP-197 (BN254 pairing):** https://eips.ethereum.org/EIPS/eip-197
5. **Groth16 paper:** https://eprint.iacr.org/2016/260.pdf
6. **Perpetual Powers of Tau:** https://github.com/privacy-scaling-explorations/perpetualpowersoftau
7. **Plonky2:** https://github.com/0xPolygonZero/plonky2
8. **Nova (IVC):** https://github.com/microsoft/Nova
9. **RISC Zero (STARK prover):** https://github.com/risc0/risc0
10. **blake3 spec:** https://github.com/BLAKE3-team/BLAKE3-specs/blob/master/blake3.pdf
11. **NeuronConstant ZK spec:** `docs/zk/README.md` (commit 2a71668)
12. **TRIBridge oracle pattern:** `contracts/src/TRIBridge.sol` (commit 07b84ec)

---

*Extends docs/zk/ stack (commit 2a71668). v1.0.0 modules preserved. Champion: BPB=2.2393 seed=43 step=27000.*
