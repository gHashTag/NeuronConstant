# Trinity ZK Integration Guide

**Version:** 1.0.0-draft  
**Scope:** `docs/zk/` only — integration specification with existing DePIN stack  
**DePIN improvement:** #10 of 10

---

## Overview

This document describes how the ZK Proof-of-Compute layer integrates with the Trinity TRI-NET DePIN stack. It covers data flow, trust model comparison, fallback behavior, gas economics, and the off-chain prover CLI specification.

---

## 1. End-to-End Data Flow

```
  ┌─────────────────────────────────────────────────────────┐
  │                   TRINITY TRI-NET EPOCH                  │
  │                                                          │
  │  TT SKY26b Chip (phi / euler / gamma)                    │
  │  ┌──────────────────────────────────────┐               │
  │  │  TRI-27 ISA execution                │               │
  │  │  ├── HW accumulator (tri_token_acc)  │               │
  │  │  ├── Sacred 0x47C0 anchor held       │               │
  │  │  └── Opcode log buffered in RAM      │               │
  │  └──────────────┬───────────────────────┘               │
  │                 │ USB/serial opcode log export            │
  │                 ▼                                        │
  │  Operator Machine (off-chain)                            │
  │  ┌──────────────────────────────────────┐               │
  │  │  trinity-prove CLI (future tool)     │               │
  │  │  ├── Load proving_key.zkey (~15 MB)  │               │
  │  │  ├── Build witness from opcode log   │               │
  │  │  ├── Run snarkjs groth16 prover      │               │
  │  │  └── Output: proof.json + public.json│               │
  │  └──────────────┬───────────────────────┘               │
  │                 │ proof (192 bytes) + public inputs      │
  │                 ▼                                        │
  │  Ethereum / L2 Network (on-chain)                        │
  │  ┌──────────────────────────────────────┐               │
  │  │  TRIBridge.submitProofClaim(         │               │
  │  │    proof, publicInputs               │               │
  │  │  )                                   │               │
  │  │    └──▶ TrinityComputeVerifier       │               │
  │  │         .verifyProof() → bool        │               │
  │  │           └── BN254 pairing (0x08)   │               │
  │  │         if true:                     │               │
  │  │           TRIToken.mint(claimer, B)  │               │
  │  └──────────────────────────────────────┘               │
  └─────────────────────────────────────────────────────────┘
```

**Step-by-step:**

1. **Chip execution:** The TT SKY26b chip executes `opcodeCount` TRI-27 ISA opcodes during an epoch. The hardware accumulator (`tri_token_accumulator.v`) tallies reward pulses. The 0x47C0 anchor is maintained throughout.

2. **Opcode log export:** After the epoch ends, the chip emits an opcode log (40–160 bytes for 64–256 opcodes) over USB/serial to the operator's machine.

3. **Off-chain proving:** The operator runs `trinity-prove` (see §5) which builds a circuit witness from the opcode log and generates a Groth16 proof using snarkjs. Duration: 5–30 seconds.

4. **On-chain submission:** The operator calls `TRIBridge.submitProofClaim(proof, publicInputs)`. The bridge calls `TrinityComputeVerifier.verifyProof()`.

5. **EVM pairing check:** The verifier executes a BN254 pairing check via the `ecPairing` precompile (EIP-197, address `0x08`). Gas cost: ~250K.

6. **Token mint:** If valid, the bridge calls `TRIToken.mint(claimer, finalBalance)` to credit the epoch reward.

---

## 2. Trust Model Comparison

### 2.1 Three Modes

Trinity supports three trust modes, selectable per claim:

#### Mode A — Pure ZK (single-chip, low/medium value)

```
Chip → opcode log → off-chain prover → proof → TRIBridge → Verifier → mint
```

- **Who must be trusted:** Nobody beyond the cryptographic proof system
- **Oracle dependency:** None
- **Single-chip support:** Yes
- **Privacy:** High (opcode sequence hidden)
- **Gas cost:** ~250K
- **Suitable for:** Solo chips, claims < 100 $TRI, privacy-sensitive workloads

#### Mode B — Hybrid (ZK + oracle, high value)

```
Chip → opcode log → off-chain prover → proof + M-of-N sigs → TRIBridge → Verifier + Oracle → mint
```

- **Who must be trusted:** At least 2 of 3 oracle nodes, AND ZK proof system
- **Oracle dependency:** Required for high-value claims
- **Single-chip support:** No (oracle needs M-of-N)
- **Privacy:** Medium (oracle sees claim hash)
- **Gas cost:** ~250K (ZK) + ~80K (sig verify) = ~330K
- **Suitable for:** Claims ≥ 100 $TRI, institutional operators, audit requirements

#### Mode C — Pure Oracle fallback (no ZK)

```
Chip → HW attestation → M-of-N oracle sigs → TRIBridge → Oracle → mint
```

- **Who must be trusted:** At least 2 of 3 oracle nodes
- **Oracle dependency:** Full
- **Single-chip support:** No
- **Privacy:** Low (full claim visible)
- **Gas cost:** ~80K
- **Suitable for:** Backward compatibility, degraded hardware, rollout phase

### 2.2 Trust Properties Summary

| Property | Mode A (Pure ZK) | Mode B (Hybrid) | Mode C (Pure Oracle) |
|---|---|---|---|
| Forgeable by cloned chip | No | No (ZK + oracle) | Possible if key extracted |
| Forgeable by oracle compromise | No | Only if also forge ZK | Yes (2-of-3 compromise) |
| Works for single chip | Yes | No | No |
| Hides computation | Yes | Partial | No |
| Requires trusted setup | Yes (Groth16) | Yes | No |
| EVM gas cost | ~250K | ~330K | ~80K |

---

## 3. Fallback Behavior

The `TRIBridge` contract implements automatic fallback logic:

```solidity
// Pseudocode — actual implementation in contracts/TRIBridge.sol
function submitClaim(proof, publicInputs, oracleSigs) external {
    if (proof is non-empty) {
        bool zkValid = verifier.verifyProof(proof, publicInputs);
        if (zkValid) {
            if (publicInputs.finalBalance >= HIGH_VALUE_THRESHOLD) {
                // Hybrid: also check oracle
                require(oracle.verifyMultisig(..., oracleSigs));
            }
            token.mint(msg.sender, publicInputs.finalBalance);
            return;
        }
        // ZK proof failed: emit event and try oracle fallback
        emit ZKProofFailed(publicInputs.chipSerial, publicInputs.epochNonce);
    }
    // Fallback: pure oracle mode
    require(oracleSigs.length >= 2, "Need 2+ oracle sigs if no valid ZK proof");
    require(oracle.verifyMultisig(..., oracleSigs));
    token.mint(msg.sender, publicInputs.finalBalance);
}
```

**Fallback triggers:**
- ZK proof submission omitted (empty proof bytes)
- ZK proof fails pairing check (malformed or wrong witness)
- Trusted setup keys not yet deployed (pre-Phase 3)

**Safety invariant:** A ZK proof failure never causes fund loss — it always falls back to oracle mode if valid oracle signatures are provided. This ensures backward compatibility during the rollout phase.

---

## 4. Gas Economics

### 4.1 Cost Comparison

| Operation | Gas | ETH at 30 gwei | USD at $3,000 ETH |
|---|---|---|---|
| ZK proof verification (ecPairing) | ~250,000 | 0.0075 ETH | $22.50 |
| 2-of-3 ecrecover sig verify | ~80,000 | 0.0024 ETH | $7.20 |
| Hybrid (ZK + oracle) | ~330,000 | 0.0099 ETH | $29.70 |
| ERC-20 mint | ~50,000 | 0.0015 ETH | $4.50 |

### 4.2 When ZK Makes Economic Sense

ZK verification costs ~3× more gas than oracle signatures alone, but provides stronger guarantees. The decision framework:

- **Use ZK (Mode A)** when: claim value > verification cost (> ~$25), or privacy is required, or no Triad available
- **Use Oracle (Mode C)** when: small claims (< $25 value), rollout phase, degraded hardware
- **Use Hybrid (Mode B)** when: large claims (> 100 $TRI), institutional operators requiring audit trail

### 4.3 L2 Deployment

On L2 networks (Arbitrum, Base, Polygon zkEVM), gas costs are 10–100× lower:
- ZK verification: ~2,500–25,000 L2 gas → ~$0.025–$0.25
- Oracle verification: ~800–8,000 L2 gas → ~$0.008–$0.08

L2 deployment makes ZK mode economically viable for all claim sizes. **Recommended: deploy Trinity DePIN primarily on an L2 network.**

---

## 5. Off-Chain Prover CLI Specification

The `trinity-prove` CLI tool (to be implemented in Phase 3) enables operators to generate ZK proofs without writing code.

### 5.1 Interface

```bash
# Basic usage
trinity-prove \
  --chip-serial 0xDEADBEEF... \
  --epoch 42 \
  --opcode-log opcode_log_epoch42.bin \
  --proving-key proving_key.zkey \
  --output proof_epoch42.json

# With verbose output
trinity-prove \
  --chip-serial 0xDEADBEEF... \
  --epoch 42 \
  --opcode-log opcode_log_epoch42.bin \
  --proving-key proving_key.zkey \
  --output proof_epoch42.json \
  --verbose

# Output format (proof.json)
{
  "proof": {
    "pi_a": ["0x...", "0x...", "1"],
    "pi_b": [["0x...", "0x..."], ["0x...", "0x..."], ["1", "0"]],
    "pi_c": ["0x...", "0x...", "1"],
    "protocol": "groth16",
    "curve": "bn128"
  },
  "publicInputs": {
    "chipSerial": "0x...",
    "opcodeCount": 64,
    "finalBalance": 1024,
    "epochNonce": 42,
    "anchorHash": "0x..."
  }
}
```

### 5.2 Opcode Log Format

The opcode log file (`*.bin`) is a binary file emitted by the chip over serial:

```
Offset  Size  Field
0       4     Magic: 0x54524900 ("TRI\0")
4       4     Epoch nonce (uint32)
8       2     Chip serial hash low 16 bits
10      2     Opcode count (uint16)
12      N*1   Opcode sequence (5 bits per opcode, packed into bytes)
...     2     CRC-16 checksum
```

### 5.3 Implementation Stack

```
trinity-prove (CLI, Rust or Node.js)
  ├── parse opcode log binary
  ├── compute anchorHash = blake3("0x47C0" || epochNonce)
  ├── build circuit witness (JSON)
  ├── snarkjs groth16 fullprove() (WASM, embedded)
  └── output proof.json + submit to TRIBridge (optional --submit flag)
```

---

## 6. Deployment Checklist

Before Phase 3 deployment, complete:

- [ ] Trusted setup ceremony completed (Phase 2)
- [ ] Verification key hardcoded in `TrinityComputeVerifier.sol`
- [ ] `snarkjs exportSolidityVerifier` run with production VK
- [ ] Gas benchmarks on testnet (Sepolia or OP Sepolia)
- [ ] Security audit of `TrinityComputeVerifier.sol`
- [ ] TRIBridge integration tested end-to-end
- [ ] `trinity-prove` CLI published as open-source
- [ ] Ceremony transcript published for auditability
- [ ] Documentation updated with production VK fingerprint

---

*DePIN improvement #10 of 10. v1.0.0 AI format modules (NF4, Posit16, GF4/16/256) referenced but not modified. Co-author: Claude Opus 4.6.*
