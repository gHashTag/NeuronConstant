# IGLA RACE Training Ledger ↔ DePIN On-Chain Integration

**Version:** 1.0.0-igla  
**Status:** Implementation — production-ready contracts + ZK spec  
**Scope:** `contracts/src/igla/`, `docs/igla/` — extends but does NOT modify v1.0.0  
**Co-authors:** Dmitrii Vasilev (gHashTag)  
**Champion:** BPB=2.2393 @ step=27000 seed=43 sha=2446855  
**Source:** [trios-trainer-igla/assertions/champion_lock.txt](https://github.com/gHashTag/trios-trainer-igla/blob/main/assertions/champion_lock.txt)

---

## Table of Contents

1. [IGLA RACE Recap](#1-igla-race-recap)
2. [Why On-Chain Ledger](#2-why-on-chain-ledger)
3. [Architecture Overview](#3-architecture-overview)
4. [Contract Reference](#4-contract-reference)
5. [Token Economics](#5-token-economics)
6. [ZK Proof Integration](#6-zk-proof-integration)
7. [Threat Model Summary](#7-threat-model-summary)
8. [HW Integration: VRF Receipts and M-of-N](#8-hw-integration-vrf-receipts-and-m-of-n)
9. [Deployment Checklist](#9-deployment-checklist)
10. [References](#10-references)

---

## 1. IGLA RACE Recap

### 1.1 Training Pipeline

**IGLA RACE** is the competitive language model training pipeline hosted in [gHashTag/trios-trainer-igla](https://github.com/gHashTag/trios-trainer-igla). It runs on a Railway-hosted fleet of GPU nodes and implements a reproducible training harness for small transformer models targeting minimal bits-per-byte (BPB) on held-out text.

Key properties:
- **Reproducible runs**: every training run is identified by `(seed, step)` and produces a deterministic BPB
- **Triplet-validated ledger**: each result row is written to `assertions/seed_results.jsonl` and validated across a triplet of independent runs
- **Gate system**: `gate_status=1` = passed internal validation; `gate_status=2` = passed cross-chip quorum (Gate-2)
- **Champion lock**: the best result is pinned in `assertions/champion_lock.txt`

### 1.2 Champion

The current IGLA RACE champion, pinned at commit `2446855`:

```
BPB=2.2393  seed=43  step=27000
```

In on-chain bpbE6 notation: `2239300` (i.e., `2.2393 × 10⁶`).

This value is the ground truth for the no-regression invariant in `IGLALedger.sol`: any new row must achieve `bpbE6 < 2239300` to update the per-chip best.

### 1.3 Ledger Row Format

Each `assertions/seed_results.jsonl` row maps to an on-chain `TrainingRow`:

| JSONL field      | On-chain field    | Type     | Notes                                      |
|------------------|-------------------|----------|--------------------------------------------|
| `bpb`            | `bpbE6`           | uint32   | Multiplied by 1e6; 2.2393 → 2239300        |
| `step`           | `step`            | uint64   | Training step number                       |
| `seed`           | `seed`            | uint32   | Random seed                                |
| `sha` (7-char)   | `sha`             | bytes7   | First 7 bytes of commit/entry hash         |
| row index        | `jsonlRow`        | uint64   | Row number in seed_results.jsonl           |
| `gate_status`    | `gateStatus`      | uint8    | 0=pending, 1=gate1, 2=gate2               |
| (set on-chain)   | `timestamp`       | uint64   | block.timestamp at submission              |
| chip identifier  | `chipSerial`      | bytes32  | DePIN hardware serial (keccak of chip ID) |

---

## 2. Why On-Chain Ledger

### 2.1 Censorship Resistance

An off-chain training ledger (even with cryptographic signatures) is susceptible to:
- **Selective disclosure**: operator withholds runs that show poor performance
- **Retroactive tampering**: JSONL file modified after the fact
- **Availability attacks**: ledger server goes offline, erasing history

An on-chain `IGLALedger` makes training history **immutable and public**. Once a row is submitted, it cannot be deleted or modified. Any observer can verify that:
- The BPB sequence is monotonically improving (no-regression invariant enforced)
- The champion is the globally best result, not cherry-picked

### 2.2 Public Verifiable Training History

DePIN participants (chip operators, token holders, governance) need to trust that:
- Training rewards are based on real compute, not fabricated results
- The champion claim is independently reproducible (seed + step are public)
- No single party controls the ledger

`IGLALedger.getChampion()` provides a trustless, on-chain source of truth for the current best BPB. Any external contract or frontend can query it without trusting the IGLA daemon.

### 2.3 Slashing for Fake Results

If an oracle submits a fraudulent training row (fabricated BPB), the challenge mechanism (via `TRIBridge.slashReceipt`) allows any oracle to file evidence. The slashing penalty (`balance >> 4`, i.e., 6.25%) is consistent across the DePIN stack (see [THREAT_MODEL.md](./THREAT_MODEL.md)).

For high-value rewards (≥ 10 TRI), `TrainingProver.verifyAndSubmit` additionally requires a valid Groth16 ZK proof, making fabrication cryptographically infeasible.

### 2.4 Token Incentive Alignment

By linking BPB improvement to `$TRI` token rewards, the system creates a direct economic incentive to improve training quality. The reward formula (`1 TRI per 0.01 BPB improvement, cap 100 TRI`) penalizes marginal improvements and rewards breakthroughs, aligning operator incentives with model quality.

---

## 3. Architecture Overview

### 3.1 Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                 trios-trainer-igla (Railway fleet)           │
│  - GPU training nodes                                        │
│  - assertions/seed_results.jsonl  ←  training results       │
│  - assertions/champion_lock.txt   ←  best result pinned     │
└───────────────────────┬─────────────────────────────────────┘
                        │ JSONL row + BPB + sha
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                 IGLA daemon (off-chain indexer)               │
│  - Reads seed_results.jsonl                                  │
│  - Signs each row with oracle private key (EIP-191)          │
│  - (Optional) Generates ZK training proof                    │
│  - Submits to blockchain via RPC                             │
└───────────────────────┬─────────────────────────────────────┘
                        │ oracle_sig + (optional ZK proof)
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              MofNTrainingAttest.sol (2-of-3)                 │
│  - 3 chip-owners independently attest rowHash               │
│  - Quorum = 2 (mirrors HW tri_mofn_attest.v)                │
│  - isRowAttested(rowHash) → bool                            │
└───────────────────────┬─────────────────────────────────────┘
                        │ attestation cleared
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   IGLALedger.submitRow()                     │
│  - Verifies oracle signature                                 │
│  - Enforces no-regression BPB invariant                      │
│  - Enforces step monotonicity                                │
│  - Updates bestBPB[chipSerial]                               │
│  - Updates global champion                                   │
│  - Tracks Gate-2 quorum per BPB target                      │
└───────────────────────┬─────────────────────────────────────┘
                        │ ZK proof path
                        ▼
┌─────────────────────────────────────────────────────────────┐
│            TrainingProver.verifyAndSubmit()                  │
│  - Verifies Groth16 proof (BN254 precompile 0x08)           │
│  - Verifies oracle signature                                 │
│  - Calls IGLALedger.submitRowVerified()                      │
│  - Computes BPB improvement reward                           │
└───────────────────────┬─────────────────────────────────────┘
                        │ mintTrainingReward(to, amount)
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   TRIBridge.claim()                          │
│  - Authorized by TrainingProver                              │
│  - Calls TRIToken.mint(recipient, rewardWei)                 │
└───────────────────────┬─────────────────────────────────────┘
                        │ $TRI minted
                        ▼
              ┌────────────────────┐
              │  TRIToken (ERC-20) │  ← chip-owner wallet receives $TRI
              └────────────────────┘
```

### 3.2 Data Flow Summary

1. **Off-chain**: Training run completes → JSONL row written by `trios-trainer-igla`
2. **Off-chain**: IGLA daemon reads row → signs with oracle key → (optionally) generates ZK proof
3. **On-chain**: 2 of 3 chip-owners attest the rowHash via `MofNTrainingAttest`
4. **On-chain**: IGLA daemon calls `TrainingProver.verifyAndSubmit(proof, pi, sig, ...)`
5. **On-chain**: TrainingProver verifies ZK proof → calls `IGLALedger.submitRowVerified`
6. **On-chain**: IGLALedger records row, updates champion, tracks Gate-2
7. **On-chain**: TrainingProver computes reward → calls `TRIBridge.mintTrainingReward`
8. **On-chain**: TRIToken mints `$TRI` to chip-owner wallet

For the oracle-only path (no ZK proof), step 2–5 simplify to direct `IGLALedger.submitRow(row, oracle_sig)`.

---

## 4. Contract Reference

### 4.1 IGLALedger.sol

**File:** `contracts/src/igla/IGLALedger.sol`  
**Purpose:** On-chain mirror of `assertions/seed_results.jsonl`

Key interfaces:

```solidity
// Submit a training row (oracle signature path)
function submitRow(TrainingRow calldata row, bytes calldata oracle_sig) external;

// Submit a training row (ZK-verified path, called by TrainingProver only)
function submitRowVerified(TrainingRow calldata row) external;

// Returns the current global champion
function getChampion() external view returns (TrainingRow memory);

// Gate-2 quorum check: >= 3 chips achieved exactly targetBpbE6
function gate2(uint32 targetBpbE6) external view returns (bool);
```

**Key invariants:**
- `bestBPB[chipSerial]` is monotonically decreasing (lower = better)
- `lastStep[chipSerial]` is monotonically increasing
- `getChampion().bpbE6` = global minimum across all chips

### 4.2 TrainingProver.sol

**File:** `contracts/src/igla/TrainingProver.sol`  
**Purpose:** ZK proof verifier + reward minter for training runs

Key interfaces:

```solidity
// Pure ZK verification (no side effects)
function verifyTrainingProof(
    TrainingProof calldata proof,
    TrainingPublicInputs calldata pi
) external view returns (bool);

// ZK + oracle hybrid: verify → record → reward
function verifyAndSubmit(
    TrainingProof calldata proof,
    TrainingPublicInputs calldata pi,
    bytes calldata oracle_sig,
    bytes7 sha, uint64 jsonlRow, uint8 gateStatus,
    address rewardTo
) external;

// Reward formula: 1 TRI per 0.01 BPB improvement, cap 100 TRI
function bpbToReward(uint32 prevBest, uint32 newBest)
    public pure returns (uint256 rewardWei);
```

### 4.3 MofNTrainingAttest.sol

**File:** `contracts/src/igla/MofNTrainingAttest.sol`  
**Purpose:** 2-of-3 chip-owner attestation (mirrors `tri_mofn_attest.v`)

Key interfaces:

```solidity
// Attest via signature (chip-owner can delegate)
function attestRow(bytes32 rowHash, bytes calldata sig) external;

// Attest directly (chip-owner calls from their EOA)
function attestRowDirect(bytes32 rowHash) external;

// Query: has rowHash reached quorum?
function isRowAttested(bytes32 rowHash) external view returns (bool);

// Query: which owners have attested?
function getAttesters(bytes32 rowHash) external view returns (bool[3] memory);
```

---

## 5. Token Economics

### 5.1 Reward Formula

The `$TRI` reward for a training submission is:

```
improvement = prevBestBpbE6 - newBpbE6          (in bpbE6 units)
triUnits    = improvement / 10_000               (integer division)
rewardWei   = min(triUnits, 100) × 10^18
```

Where `10_000 bpbE6 units = 0.01 BPB = 1 TRI`.

**Example — Champion scenario (2.5 BPB → 2.2393 BPB):**
- Improvement: `2_500_000 - 2_239_300 = 260_700` bpbE6 units
- TRI reward: `260_700 / 10_000 = 26` TRI
- Reward wei: `26 × 10^18`

**Example — First submission (no prior best, baseline 3.0 BPB):**
- Improvement from baseline: `3_000_000 - 2_239_300 = 760_700` bpbE6 units
- TRI reward: `760_700 / 10_000 = 76` TRI

**Cap:** Maximum 100 TRI per submission (prevents reward explosion for unrealistically low BPB claims; ZK proof is required for large rewards to prevent forgery).

### 5.2 High-Value Threshold

Following the hybrid security model established in `docs/zk/verifier_outline.sol`, claims yielding ≥ 10 TRI **should** submit a ZK proof via `TrainingProver.verifyAndSubmit` rather than the oracle-only `IGLALedger.submitRow` path.

This threshold is enforced at the application layer (IGLA daemon configuration). Future governance upgrade may enforce it at the contract layer.

### 5.3 Supply Dynamics

Training rewards are minted via `TRIBridge.mintTrainingReward`. The total $TRI supply from training rewards depends on:
- Frequency of BPB improvements (diminishing returns as model converges)
- Number of participating chips
- BPB ceiling: once champion reaches ~1.5 BPB, improvements < 0.01 BPB yield 0 TRI

This creates a naturally deflationary issuance curve as the training frontier converges.

---

## 6. ZK Proof Integration

### 6.1 Proof Statement

The training ZK proof asserts:

> "I executed `step` training gradient updates starting from weights root `W0`, achieved bits-per-byte `BPB` on the validation set, using seed `seed`, on chip `chipSerial`. The loss curve commitment is `lossCurveHash` and the final weights Merkle root is `weightsRootHash`."

### 6.2 Public Inputs

```
chipSerial      : bytes32  — chip identifier (4 × uint64 field elements)
step            : uint64   — training step count
seed            : uint32   — random seed
bpbE6           : uint32   — BPB * 1e6
lossCurveHash   : bytes32  — blake3 hash of full loss curve (4 × uint64 field elements)
weightsRootHash : bytes32  — lower 128 bits of Merkle root (1 field element)
```

Total: 12 BN254 scalar field elements.

### 6.3 Private Witness

```
fullLossCurve[]   : float[]   — per-step training loss values
gradientUpdates[] : tensor[]  — gradient updates at each step
intermediateWeights[] : tensor[] — weight checkpoints
initialWeightsRoot   : bytes32  — Merkle root at step 0
```

The circuit proves that applying the gradient updates to `initialWeightsRoot` produces `weightsRootHash` and the loss curve has hash `lossCurveHash`.

### 6.4 Circom Circuit

Full circuit specification: [docs/igla/zk/training_proof_circuit.md](./zk/training_proof_circuit.md)

Estimated size: ~500K R1CS constraints (training step heavier than inference).

Compatible with the existing `docs/zk/` stack (Groth16/BN254).

---

## 7. Threat Model Summary

Full analysis: [docs/igla/THREAT_MODEL.md](./THREAT_MODEL.md)

| Threat | Mitigation |
|--------|-----------|
| Fake training run (no GPU) | ZK proof of compute required for ≥ 10 TRI rewards |
| Gradient sabotage (inflate BPB) | Reproducibility: re-run from logged seed proves result |
| Oracle collusion | ZK proof required for high-value; slash mechanism |
| Replay attack | Step monotonicity in IGLALedger + usedSubmissions in TrainingProver |
| Sybil chips | chipSerial bound to hardware DePIN serial (keccak of ASIC key) |

---

## 8. HW Integration: VRF Receipts and M-of-N

### 8.1 DePIN #1 — VRF Receipts

`common/depin/v2/tri_vrf_receipt.v` generates a hardware VRF receipt for each compute epoch. The IGLA training proof extends this by using the VRF seed as a private witness element that binds the proof to a specific chip's hardware identity.

Without knowledge of the chip's VRF seed (hardware-generated, not externally readable), an adversary cannot produce a valid training ZK proof even if they have access to the public VK.

### 8.2 DePIN #3 — M-of-N Attestation

`MofNTrainingAttest.sol` is the Solidity mirror of `common/depin/v2/tri_mofn_attest.v`. Both implement the same 2-of-3 threshold logic:

| HW module (`tri_mofn_attest.v`) | Solidity (`MofNTrainingAttest.sol`) |
|---------------------------------|--------------------------------------|
| `attest_in[2:0]` bitmap         | `attestBitmap[rowHash]`              |
| `count` register                | `attestCount[rowHash]`               |
| `quorum_reached` flag           | `quorumReached[rowHash]`             |
| `M` parameter (default 2)      | `quorumThreshold` (constructor arg)  |
| `N` parameter (default 3)      | `chipOwnerCount` (hardcoded 3)       |

### 8.3 DePIN #5 — Slashing

Slashing for fraudulent training rows follows the same `balance >> 4` (6.25%) penalty as `TRIBridge.slashReceipt`. Oracle addresses that sign fraudulent rows are subject to governance-enforced slashing via off-chain evidence submission.

---

## 9. Deployment Checklist

See full guide: [docs/igla/INTEGRATION.md](./INTEGRATION.md)

**Quick reference:**

1. Deploy `TRIToken` (if not already deployed)
2. Deploy `TRIBridge(_token, _oracles[3])`
3. Deploy `IGLALedger(_oracles[])`
4. Deploy `MofNTrainingAttest([chipOwner0, chipOwner1, chipOwner2], 2)`
5. Deploy `TrainingProver(_iglaLedger, _triBridge, _oracles[])`
6. `IGLALedger.setTrainingProver(address(prover))`
7. `IGLALedger.setAttestModule(address(attestModule))` (optional)
8. Configure IGLA daemon Railway env vars: `CONTRACT_ADDRESS`, `ORACLE_KEY`
9. Fund oracle address with ETH for gas
10. Verify champion row: `igla-onchain submit --row 1 --sha 2446855 --bpb 2.2393 --step 27000 --seed 43`

---

## 10. References

1. **IGLA RACE source:** [gHashTag/trios-trainer-igla](https://github.com/gHashTag/trios-trainer-igla)
2. **Champion lock:** [trios-trainer-igla/assertions/champion_lock.txt](https://github.com/gHashTag/trios-trainer-igla/blob/main/assertions/champion_lock.txt)
3. **NeuronConstant repo:** [gHashTag/NeuronConstant](https://github.com/gHashTag/NeuronConstant)
4. **TRIBridge.sol (oracle pattern):** `contracts/src/TRIBridge.sol` (commit 07b84ec)
5. **ZK verifier outline:** `docs/zk/verifier_outline.sol` (commit 2a71668)
6. **HW M-of-N attestation:** `common/depin/v2/tri_mofn_attest.v` (commit fb0e385)
7. **ZK Proof-of-Compute spec:** [docs/zk/README.md](../zk/README.md)
8. **Groth16 paper:** https://eprint.iacr.org/2016/260.pdf
9. **EIP-197 (BN254 pairing):** https://eips.ethereum.org/EIPS/eip-197
10. **NeuronConstant v1.0.0:** DOI 10.5281/zenodo.19227877

---

*v1.0.0 Opus 4.6 modules preserved. IGLA integration extends DePIN improvement set.*
