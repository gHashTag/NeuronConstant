# Trinity ZK Proof-of-Compute: Threat Model

**Version:** 1.0.0-draft  
**Scope:** ZK layer threats. Hardware threats are in HW v2 spec (separate subagent task).  
**DePIN improvement:** #10 of 10

---

## 1. Overview

This document defines the adversary model for the Trinity ZK Proof-of-Compute system and provides mitigations per attack vector. It also compares the ZK layer's guarantees against hardware-only attestation.

### 1.1 Assets Under Protection

| Asset | Description | Value |
|---|---|---|
| $TRI token supply | Minted for valid compute proofs | High |
| Chip identity | chipSerial binding prevents identity theft | High |
| Opcode privacy | Private witness hides computation sequence | Medium |
| Epoch integrity | Replay attacks could double-spend rewards | High |
| Trusted setup keys | Toxic waste from ceremony | Critical |

### 1.2 Threat Actors

| Actor | Capability | Motivation |
|---|---|---|
| External adversary | Network access, public data | Token theft, proof forgery |
| Compromised operator | Physical chip access, valid credentials | Inflate rewards |
| Compromised oracle | Sign false attestations | Enable false claims |
| Malicious ceremony participant | Retain toxic waste from trusted setup | Forge arbitrary proofs |
| Hardware clone attacker | Replicate chip hardware externally | Bypass compute requirements |
| Quantum adversary (future) | Shor's algorithm on large quantum computer | Break BN254 DLP |

---

## 2. Attack Vectors and Mitigations

### 2.1 Cloned / Counterfeit Chip

**Description:** Adversary manufactures or purchases a counterfeit TT SKY26b ASIC that passes basic hardware checks but does not perform genuine TRI-27 compute.

**ZK Mitigation:**
- The circuit witness includes `vrfSeed : bytes32` — a chip-private VRF seed generated during manufacturing and stored in secure one-time-programmable (OTP) fuses.
- The `anchorHash` constraint requires that `blake3("0x47C0" || epochNonce)` equals the public input, and this computation uses `vrfSeed` as part of the witness derivation in the full circuit.
- Without the VRF seed, the adversary cannot construct a valid witness, and therefore cannot generate a valid Groth16 proof.
- A counterfeit chip that does not have the original VRF seed is cryptographically indistinguishable from a random adversary attempting to forge a proof — which requires solving the discrete log problem on BN254 (~2^128 operations).

**What ZK does NOT protect:** Physical invasive extraction of the VRF seed from a genuine chip sample (focused ion beam, microprobing). This is a hardware security concern handled at the chip design level (e.g., active mesh, fuse destruction after enrollment).

**Residual risk:** Low. Requires physical chip access and expensive lab equipment.

### 2.2 Software Emulator Attack

**Description:** Adversary runs a software emulator of the TRI-27 ISA and generates opcode logs without running genuine hardware.

**ZK Mitigation:**
- Same as §2.1: without the hardware VRF seed, a software emulator cannot produce a valid circuit witness.
- Proof generation requires the witness, and the witness requires `vrfSeed`. The seed is bound to physical hardware manufacturing.
- Economic deterrent: proof generation takes 5–30 seconds per epoch; a software emulator would still need to run the full proving pipeline, gaining no economic advantage over genuine hardware.

**Residual risk:** None for ZK-verified claims. (Note: fallback oracle mode has higher risk if oracle is compromised — see §2.3.)

### 2.3 Compromised Oracle

**Description:** Adversary bribes, coerces, or compromises 2-of-3 oracle nodes to sign false compute attestations.

**ZK Mitigation:**
- In Mode A (Pure ZK), oracle signatures are not required. A compromised oracle cannot affect ZK-verified claims.
- In Mode B (Hybrid), oracle compromise combined with ZK proof forgery would be required — a compound attack requiring breaking two independent security assumptions simultaneously.
- The bridge's automatic fallback from ZK to oracle mode means a compromised oracle could only affect claims that fail ZK verification — legitimate claims are protected.

**What ZK does NOT protect:** If an operator deliberately generates valid ZK proofs for inflated opcode counts (by providing a false opcode log), the oracle is the last line of defense in hybrid mode.

**Mitigation (non-ZK):** On-chain epoch nonce enforcement, anomaly detection in oracle nodes (claims that deviate significantly from peer chips in the same Triad should be flagged).

**Residual risk:** Medium for pure oracle mode; Very low for Mode A ZK claims.

### 2.4 MITM on USB/Serial Channel

**Description:** Adversary intercepts the serial communication between the TT SKY26b chip and the operator machine, modifying the opcode log in transit.

**ZK Mitigation:**
- A modified opcode log produces a different circuit witness. The witness must be consistent with the circuit's state transition constraints.
- If the adversary modifies opcodes to claim more work, the constraint `finalBalance = balances[N]` (accumulated from actual reward pulses) will fail, making the circuit unsatisfiable.
- The adversary cannot forge a witness that satisfies all constraints without knowledge of the internal chip state at each step.

**Complementary protection:** The opcode log should include a hardware-signed checksum (using the chip's ECDSA key or HMAC with the VRF seed). Modification of the log would invalidate the checksum before proof generation.

**Residual risk:** Low with hardware-signed checksum; Medium without it.

### 2.5 Malicious Trusted Setup Participant

**Description:** A ceremony participant retains their contribution's toxic waste (secret randomness) instead of destroying it. This enables them to forge Groth16 proofs for any statement.

**ZK Mitigation:**
- Multi-party ceremony: with K participants, the toxic waste is the product of all K contributions. If even ONE participant honestly destroys their contribution, the toxic waste is irrecoverable.
- With 5 ceremony participants including an independent security auditor, the probability of complete compromise is negligible.
- Ceremony transcripts are publicly published, allowing anyone to verify contribution commitments.

**What this does NOT prevent:** If ALL ceremony participants collude, they can forge proofs. This is a fundamental weakness of Groth16 ("trusted setup").

**Long-term mitigation:** Migrate to PLONK (universal setup) or STARK (no setup required) — see `README.md §7` Phase 4–5.

**Residual risk:** Very low with multi-party ceremony; High if ceremony is run by a single party.

### 2.6 Replay Attack

**Description:** Adversary submits a valid epoch proof a second time to claim rewards twice.

**ZK Mitigation:**
- The `epochNonce` public input is a monotonic counter. The bridge contract maintains a `usedEpochs` mapping: `keccak256(chipSerial, epochNonce) → bool`.
- Once an epoch key is marked as used, any re-submission reverts with `"TCV: epoch already claimed"`.
- The `epochNonce` is also bound into the `anchorHash` via `blake3("0x47C0" || epochNonce)`, ensuring each proof is cryptographically unique per epoch.

**Residual risk:** None (fully mitigated by on-chain nonce tracking).

### 2.7 Proof Malleability

**Description:** Adversary takes a valid proof `(A, B, C)` and produces a different valid proof `(A', B', C')` for the same public inputs (proof malleability).

**ZK Mitigation:**
- Groth16 proofs over BN254 are non-malleable in the standard model, assuming the CDH assumption holds. The verification equation uniquely determines which proofs are valid for a given verification key.
- snarkjs-generated proofs include a normalization step that further reduces malleability risk.

**Residual risk:** Negligible under standard cryptographic assumptions.

### 2.8 Quantum Adversary (Future Threat)

**Description:** A sufficiently large quantum computer runs Shor's algorithm to solve the elliptic curve discrete logarithm problem on BN254, breaking soundness and/or zero-knowledge of Groth16.

**Current status (2025):** Not a near-term threat. Breaking BN254 requires millions of fault-tolerant logical qubits. Largest known quantum computers have a few thousand noisy physical qubits.

**Mitigation (long-term):**
- Monitor quantum computing progress (key milestones: 10K, 100K, 1M fault-tolerant logical qubits)
- Phase 5 migration plan (see `README.md §7`): migrate to STARKs or lattice-based SNARKs
- During transition: run hybrid quantum-safe + Groth16 proofs simultaneously; require both for high-value claims

**Residual risk:** None in near term; Potential critical risk in 10–15 year horizon.

---

## 3. ZK vs Hardware-Only Attestation: What ZK Adds

| Security Property | HW M-of-N Only | HW M-of-N + ZK |
|---|---|---|
| Protects against cloned chip | No — key extraction enables forgery | Yes — ZK witness requires VRF seed |
| Protects against software emulator | No — emulator with stolen key works | Yes — VRF seed required in witness |
| Protects against oracle compromise | No — 2-of-3 compromise enables fraud | Yes (Mode A: oracle not needed) |
| Hides computation sequence | No — fully visible | Yes — private witness |
| Works for single chip | No — needs M-of-3 | Yes |
| Replay protection | Via nonce (same as ZK) | Via nonce + epoch key |
| Setup ceremony required | No | Yes (Groth16 weakness) |
| Quantum resistance | N/A (ECDSA: also broken by Shor) | No (both need migration) |
| Protects physical key extraction | No | No (same limitation) |

### What ZK Does NOT Replace

1. **Physical hardware security:** If an attacker extracts the VRF seed from a chip using invasive techniques, ZK proofs are broken. Hardware tamper resistance (active mesh, fuse security, etc.) remains necessary.

2. **Network security:** The `trinity-prove` CLI and opcode log transport must run in a trusted environment. ZK proofs cannot protect against an operator who deliberately generates false opcode logs from their own chip.

3. **Smart contract security:** `TrinityComputeVerifier.sol` must be audited. A bug in the Solidity verifier (e.g., wrong pairing equation, missing input range check) could allow proof bypass.

4. **Economic mechanism design:** ZK proofs ensure compute happened correctly, but do not ensure the compute was *useful*. Application-layer checks (e.g., proof of useful AI inference output) are a separate concern.

---

## 4. Summary Risk Matrix

| Attack | Likelihood | Impact | Mitigation | Residual Risk |
|---|---|---|---|---|
| Software emulator (no key) | High | High | ZK witness binding | Very Low |
| Cloned chip (with key) | Low | High | Hardware OTP + ZK witness | Low |
| Oracle compromise (2-of-3) | Low | High | Mode A ZK (oracle-free) | Low |
| MITM on serial channel | Medium | Medium | HW-signed checksum + ZK | Low |
| Malicious ceremony (all collude) | Very Low | Critical | Multi-party + independent auditor | Very Low |
| Replay attack | High (without mitigation) | High | On-chain epoch nonce | None |
| Quantum attack (BN254) | Very Low (2025) | Critical | Phase 5 migration plan | Low (near term) |
| Smart contract bug | Medium | High | Audit + snarkjs template | Medium (pre-audit) |

---

*DePIN improvement #10 of 10. v1.0.0 AI format modules (NF4, Posit16, GF4/16/256, sacred opcodes) are referenced for context but not modified.*
