# IGLA Training Ledger — Threat Model

**Version:** 1.0.0-igla  
**Status:** Production specification  
**Scope:** `contracts/src/igla/`, IGLA daemon, DePIN integration  
**Consistent with:** `docs/zk/README.md §8`, `contracts/src/TRIBridge.sol` slashing model

---

## Table of Contents

1. [Trust Assumptions](#1-trust-assumptions)
2. [Adversarial Scenarios](#2-adversarial-scenarios)
3. [Slashing Mechanics](#3-slashing-mechanics)
4. [Residual Risks](#4-residual-risks)
5. [Security Properties Summary](#5-security-properties-summary)

---

## 1. Trust Assumptions

### 1.1 Trusted

| Component | Trust Basis |
|-----------|------------|
| Ethereum consensus (mainnet) | Byzantine fault-tolerant consensus, >67% honest validators |
| BN254 precompiles (0x06–0x08) | EIP-196/197, in production since 2017, no known breaks |
| Solidity ≥0.8.24 overflow protection | Built-in checked arithmetic |
| secp256k1 / ecrecover | Standard Ethereum signature scheme |

### 1.2 Semi-Trusted (require monitoring)

| Component | Threat | Monitoring |
|-----------|--------|-----------|
| IGLA oracle (off-chain daemon) | Compromised key or software | Oracle rotation, multiple oracles, ZK requirement |
| Railway GPU fleet | Fabricated training logs | ZK proof for ≥10 TRI rewards |
| chip-owner keys | Key compromise → fake attestations | M-of-N (2-of-3) required |

### 1.3 Untrusted

- Any third-party submitter to `submitRow`
- Internet-facing RPC endpoints
- JSONL files before daemon verification

---

## 2. Adversarial Scenarios

### Scenario 1: Fake Training Run (No Actual GPU Compute)

**Attack:** Adversary fabricates a `seed_results.jsonl` entry claiming `BPB=1.0` at `step=100` without executing any training. They obtain oracle approval through a compromised daemon key.

**Impact:** Fraudulent $TRI reward; false champion record on-chain.

**Mitigation chain:**

1. **ZK proof requirement (primary):** For rewards ≥ 10 TRI, `TrainingProver.verifyAndSubmit` requires a valid Groth16 proof. The circuit's private witness includes:
   - Full loss curve (must match `lossCurveHash` commitment)
   - Gradient updates for each step
   - VRF seed binding the proof to a specific hardware chip
   
   Without executing actual training, the adversary cannot generate a valid witness. The prover cannot produce a proof of knowledge of a training run that never happened.

2. **Reproducibility challenge (secondary):** Any party can re-run training with `seed=<S>` for `step=<N>` and verify the BPB. The champion result `(BPB=2.2393, seed=43, step=27000)` is publicly reproducible. Deviations flag fraud.

3. **Oracle multi-sig (tertiary):** Even with one compromised oracle, two additional independent oracles must co-sign (not implemented in current oracle-path, but enforced for ZK path via M-of-N attestation).

**Residual risk:** Low. ZK proof is the primary defense; reproducibility is an independent check.

---

### Scenario 2: Gradient Sabotage (Poison Training to Inflate Claimed BPB)

**Attack:** A malicious chip operator deliberately degrades training (e.g., injects poisoned data, clips gradients to near-zero) to inflate apparent difficulty, then claims BPB improvement reward for a modest result that should have been better.

**Impact:** Unfair reward extraction; wastes compute without advancing model quality.

**Mitigation chain:**

1. **No-regression invariant:** `IGLALedger` only accepts rows where `bpbE6 < bestBPB[chipSerial]`. Stagnant or degraded runs simply don't generate rewards; they don't earn more by being worse longer.

2. **Reproducibility check:** A verifier can re-run the training from the logged seed and compare loss curves. If the submitted `lossCurveHash` doesn't match the reproduced curve, the row is fraudulent (challengeable off-chain; future upgrade: ZK circuit explicitly proves loss curve hash).

3. **Gate-2 quorum:** For phase gate upgrades, `>=3` chips must independently achieve the same BPB target. A single sabotaged chip cannot block Gate-2 quorum (the other 2+ honest chips still pass).

**Residual risk:** Medium without ZK. The loss curve hash commitment (`lossCurveHash`) in the ZK proof binds the claimed BPB to an actual training trajectory; fabricating a plausible loss curve that both hashes correctly AND produces the claimed BPB is computationally infeasible.

---

### Scenario 3: Oracle Collusion (All Oracles Agree on Fake Row)

**Attack:** All authorized IGLA oracle keys are compromised (insider attack, key exfiltration, or bribery). The attackers submit fraudulent training rows claiming high BPB improvements.

**Impact:** Large-scale fake reward extraction; corrupt on-chain training history.

**Mitigation chain:**

1. **ZK proof requirement for high-value rewards:** For rewards ≥ 10 TRI (`bpbE6` improvement ≥ 100_000), `TrainingProver.verifyAndSubmit` requires a valid Groth16 proof. Even with all oracle keys compromised, attackers cannot generate a valid ZK proof without:
   - Access to the chip's private VRF seed (hardware-bound)
   - Actually running `step` training steps to generate a valid witness

2. **Economic cap:** Reward is capped at 100 TRI per submission. Even if small oracle-only rows (< 10 TRI threshold) are fraudulent, the total damage is bounded.

3. **Oracle rotation:** `IGLALedger.setOracle` allows the deployer to remove compromised oracle keys and add new ones. Historical rows are immutable (cannot be deleted), but new fraud is stopped immediately.

4. **M-of-N attestation (for multi-chip setups):** `MofNTrainingAttest` requires 2-of-3 chip-owner attestations. If chip-owners and oracle operators are different entities, oracle collusion alone is insufficient for rows passing through the attestation module.

**Residual risk:** Low for high-value rewards (ZK mitigates). Medium for low-value oracle-path rows if oracle keys are all compromised. Mitigation: reduce oracle-only threshold to 0 TRI (require ZK for all rewards), or deploy multi-oracle setup with geo-distributed key holders.

---

### Scenario 4: Replay Attack (Resubmit Valid Historical Row)

**Attack:** Adversary captures a valid signed row submission (e.g., from mempool or past transactions) and resubmits it to claim duplicate rewards.

**Impact:** Duplicate reward for the same training run; BPB state corruption.

**Mitigation chain:**

1. **Step monotonicity:** `IGLALedger` maintains `lastStep[chipSerial]`. A row with `step <= lastStep` is rejected with `"IGLALedger: step regression"`. Each legitimate training run advances the step counter.

2. **No-regression BPB:** `IGLALedger` rejects rows where `bpbE6 >= bestBPB[chipSerial]`. Re-submitting a historical row (which had a higher BPB than the current best) is rejected.

3. **TrainingProver replay protection:** `usedSubmissions[keccak(chipSerial, step, seed)]` prevents the same `(chip, step, seed)` from being processed twice by `TrainingProver.verifyAndSubmit`.

**Residual risk:** Negligible. The combination of step monotonicity, BPB no-regression, and submission key deduplication provides defense in depth.

---

### Scenario 5: Sybil Chip Attack (Register Fake chipSerials)

**Attack:** Adversary generates many fake `chipSerial` values (by computing keccak of arbitrary strings) and submits rows for each, rapidly accumulating Gate-2 quorum counts or polluting the ledger.

**Impact:** Fake gate-2 quorum; spam rows; inflated reward claims.

**Mitigation chain:**

1. **Oracle signature required:** All `submitRow` calls require a valid signature from an authorized IGLA oracle. The oracle is expected to verify that `chipSerial` corresponds to a real deployed chip (verified against the DePIN hardware registry off-chain) before signing.

2. **M-of-N attestation (for Gate-2 critical paths):** When `attestModule` is configured, rows must also be attested by 2-of-3 registered chip-owners. Chip-owners are registered at deployment time and correspond to physical hardware operators.

3. **Gate-2 interpretation:** `gate2(targetBpbE6)` counts chips that submitted a row achieving that exact BPB. Sybil chips at different BPB values don't affect a specific Gate-2 target. Sybil chips at the same BPB require the attacker to submit oracle-signed rows — bounded by oracle gate (Scenario 3 mitigations apply).

4. **Future: hardware attestation:** Integration with `tri_vrf_receipt.v` (DePIN #1) binds `chipSerial` to a hardware VRF output, making it infeasible to generate valid chipSerials without physical Trinity Triad hardware.

**Residual risk:** Low with attestation module. Medium in oracle-only mode without hardware attestation.

---

## 3. Slashing Mechanics

Consistent with `contracts/src/TRIBridge.sol` and `docs/zk/README.md §8`:

### 3.1 Slash Penalty

If a fraudulent row is discovered (e.g., reproducibility check fails, ZK challenge succeeds), the oracle who signed the row is subject to **slashing of `balance >> 4` (6.25%)** of their accumulated reward pool.

This is enforced off-chain via governance (same as `TRIBridge.slashReceipt`). On-chain, the `Slashed` event in TRIBridge is emitted, and indexers enforce the penalty.

### 3.2 Challenge Process

1. Challenger observes a suspicious row on `IGLALedger`
2. Challenger re-runs training with `seed=S` for `step=N`
3. If reproduced BPB ≠ claimed BPB, challenger calls `TRIBridge.slashReceipt(rowHash, evidence)`
4. Governance reviews evidence and applies slash to oracle's staking balance
5. Challenger receives a portion of slashed amount as bounty (implementation: off-chain governance)

### 3.3 ZK Challenge (Advanced)

For ZK-attested rows, the challenge requires demonstrating that the submitted ZK proof is invalid. This requires:
- Finding a witness inconsistency (computational break of Groth16 soundness), OR
- Reproducing the training run and generating a ZK proof of a different BPB, demonstrating oracle signed a mismatched public input

The second approach is practical: if the challenger can prove `(chip, step, seed) → BPB' ≠ claimed BPB`, the oracle's signature was fraudulent regardless of ZK proof validity.

---

## 4. Residual Risks

### 4.1 ZK Trusted Setup Compromise

If all participants in the Groth16 trusted setup ceremony collude, the toxic waste can be used to forge proofs. Mitigations: diverse ceremony, public transcripts. Full elimination requires migration to STARK/PLONK (see [docs/igla/zk/training_proof_circuit.md §10](./zk/training_proof_circuit.md)).

### 4.2 Oracle Key Compromise (Low-Value Path)

Oracle-only rows (< 10 TRI) bypass ZK verification. A compromised oracle key can submit fraudulent low-value rows. Total damage bounded by: `number_of_chips × 10 TRI × economic_cap_factor`. For high-security deployments, set ZK threshold to 0 (all rows require ZK).

### 4.3 Physical Chip Compromise

Extracting the chip's VRF seed via physical attacks (focused ion beam, decapsulation) breaks the hardware binding in the ZK proof. This is a hardware security concern out of scope for this contract specification.

### 4.4 BPB Metric Gaming

An adversary could train a model that achieves low BPB on the specific validation set used by IGLA RACE (overfitting to validation). The ZK proof proves the claimed BPB is correct for the logged seed/step; it does not prove generalization. This is a machine learning concern, not a cryptographic one.

---

## 5. Security Properties Summary

| Property | Guarantee | Contract enforcement |
|----------|-----------|---------------------|
| **Immutability** | Accepted rows cannot be modified or deleted | Solidity state, no delete function |
| **No-regression** | BPB can only improve per-chip | `require(bpbE6 < bestBPB)` in `submitRow` |
| **Replay resistance** | Same submission cannot be processed twice | Step monotonicity + `usedSubmissions` bitmap |
| **Oracle integrity** | Only authorized IGLA oracles can submit | `ecrecover` + `authorizedOracles` mapping |
| **ZK soundness** | High-value rewards require unforgeable proof | Groth16 / BN254 under q-DLOG assumption |
| **Multi-party attestation** | 2-of-3 chip-owners must agree | `MofNTrainingAttest.quorumReached` |
| **Champion trustlessness** | Champion readable by anyone without trust | `IGLALedger.getChampion()` public view |
| **Slashing deterrence** | Oracle fraud results in 6.25% balance slash | `TRIBridge.slashReceipt` + governance |

---

*Consistent with `docs/zk/THREAT_MODEL.md` (commit 2a71668). v1.0.0 Opus 4.6 modules preserved.*
