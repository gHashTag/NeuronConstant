# Trinity DePIN Stack — Architecture

This document describes the five-layer architecture of the Trinity TRI-NET
Decentralized Physical Infrastructure Network.

---

## Layer Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Layer 4 — User Wallet                                                   │
│  Standard ERC-20 wallet (MetaMask, Rainbow, Rabby, …)                   │
│  TRI balance, swap via DEX (Uniswap v3, Aerodrome on Base)              │
└──────────────────────────────────────────────────────────────────────────┘
         ▲ TRI tokens (ERC-20 transfer)
         │
┌──────────────────────────────────────────────────────────────────────────┐
│  Layer 3 — On-Chain Settlement (L1 / L2)                                 │
│                                                                          │
│  ┌─────────────────┐    mint/burn    ┌────────────────┐                  │
│  │  TRIBridge.sol  │ ─────────────▶ │  TRIToken.sol  │                  │
│  │  2-of-3 oracle  │                │  ERC-20        │                  │
│  │  multisig       │ ◀─────────────  │  uncapped      │                  │
│  │  replay guard   │    withdraw     │  supply        │                  │
│  └────────┬────────┘                └────────────────┘                  │
│           │ slash / recordClaim                                          │
│  ┌────────▼────────┐                                                     │
│  │ TRIRegistry.sol │  serial, pubkey, geo, type, earned, slashed        │
│  │  anti-Sybil     │  discovery: getChipsByGeo / getChipsByType         │
│  └─────────────────┘                                                     │
│                                                                          │
│  Deployment target: Ethereum mainnet or L2 (Base / Optimism)            │
│  Contracts are network-agnostic (no chain-id guards).                   │
└──────────────────────────────────────────────────────────────────────────┘
         ▲ claim(ClaimReceipt) + 2-of-3 oracle sigs
         │
┌──────────────────────────────────────────────────────────────────────────┐
│  Layer 2 — Off-Chain Indexer (TypeScript daemon — spec only)             │
│                                                                          │
│  • Listens on chip USB / serial port for ClaimReceipt packets            │
│  • Validates VRF proof (v2 attestation, common/depin/v2/)               │
│  • Contacts 3 oracle nodes, collects ≥ 2 ECDSA signatures              │
│  • Submits TRIBridge.claim() transaction                                 │
│  • Monitors Slashed events → applies off-chain penalty (balance >> 4)   │
│  • Monitors Withdrawn events → triggers on-chip credit                  │
│                                                                          │
│  Expected stack: Node.js + ethers.js v6, serialport library             │
│  Deployment: Docker container co-located with the chip host machine     │
└──────────────────────────────────────────────────────────────────────────┘
         ▲ ClaimReceipt (USB / UART serial)
         │
┌──────────────────────────────────────────────────────────────────────────┐
│  Layer 1 — HW M-of-N Attestation (2-of-3 within Trinity Triad)          │
│                                                                          │
│  Trinity Triad = 3 chips on SKY130B Tiny Tapeout shuttle:               │
│                                                                          │
│  ┌────────────────┐  ┌──────────────────┐  ┌─────────────────────────┐  │
│  │ phi (1×1 tile) │  │ euler (2×2 tile) │  │ gamma (4×2 tile)        │  │
│  │ reward: 1 TRI  │  │ reward: 2 TRI    │  │ reward: 4 TRI            │  │
│  │ NF4 format     │  │ GF16 arithmetic  │  │ Posit16 / GF256          │  │
│  └────────────────┘  └──────────────────┘  └─────────────────────────┘  │
│                                                                          │
│  Each chip runs tri_token_accumulator.v (v1.0.0, common/depin/v1/)     │
│  After a completed work cycle the accumulator serialises a receipt:     │
│    { chipSerial, nonce, amount, vrfReceiptHash, chipType }              │
│                                                                          │
│  v2 improvements (common/depin/v2/ — in development, do not modify):   │
│    VRF receipts, hardware attestation proofs, advanced slashing         │
└──────────────────────────────────────────────────────────────────────────┘
         ▲ compute (work cycles)
         │
┌──────────────────────────────────────────────────────────────────────────┐
│  Layer 0 — Hardware (chip)                                               │
│                                                                          │
│  • Tiny Tapeout SKY130B ASIC                                             │
│  • Executes AI inference workloads using sacred opcodes                 │
│    (tri_mant_mul, NF4, Posit16, GF4 / GF16 / GF256 arithmetic)         │
│  • HW accumulator counts completed work cycles locally                  │
│  • Proof-of-compute: cryptographically bound to chip ROM serial         │
│  • Physical security: key locked in ROM; VRF uses on-chip PRNG seed    │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow (sequential)

```
chip (HW)
  │  1. completes work cycle
  │  2. tri_token_accumulator.v increments counter, serialises ClaimReceipt
  ▼
indexer daemon (off-chain)
  │  3. receives ClaimReceipt via USB/serial
  │  4. validates VRF proof (v2 attestation path)
  │  5. requests signatures from oracle_0, oracle_1, oracle_2
  │  6. collects ≥ 2 signatures (2-of-3 threshold)
  ▼
TRIBridge.claim() (on-chain, Layer 3)
  │  7. verifies oracle signatures
  │  8. checks nonce strictly increasing
  │  9. enforces chipType amount cap
  │  10. marks receipt hash as processed (replay protection)
  │  11. calls TRIToken.mint(claimant, amount)
  │  12. calls TRIRegistry.recordClaim(serial, amount)
  ▼
TRIToken (ERC-20)
  │  13. increases claimant balance
  ▼
User Wallet
     14. TRI available for transfer or DEX swap
```

---

## Token Economics

### Emission

| Chip | Reward per work cycle | Notes |
|------|-----------------------|-------|
| phi (1×1) | 1 TRI | Nano inference tile |
| euler (2×2) | 2 TRI | GF16 accelerator |
| gamma (4×2) | 4 TRI | Max compute tile |

Work cycles are hardware-defined; frequency is bounded by chip clock and
workload type.  The bridge enforces per-claim caps that match these values.

### Halving (future)

A supply-weighted halving schedule (similar to Bitcoin) is planned for
governance v2.  The bridge will add a `halvingEpoch` counter; when total
supply crosses each threshold, reward multipliers decrease by 50 %.

### Slashing Pool

Forfeited anti-Sybil deposits and slash penalties accumulate in a designated
address.  Governance (future) will determine their redistribution (e.g.,
burn, redistribute to honest miners, fund audits).

### Governance (future roadmap)

- On-chain voting for oracle rotation
- Halving schedule parameter changes
- Slashing pool allocation
- Cross-chain bridge expansion (Arbitrum, zkSync)

---

## Module Inventory

| Module | Location | Version | Status |
|--------|----------|---------|--------|
| `tri_token_accumulator.v` | `common/depin/v1/` | v1.0.0 | Stable, canonical |
| NF4 format | `common/constants/` | v1.0.0 | Stable |
| Posit16 | `common/constants/` | v1.0.0 | Stable |
| GF4 / GF16 / GF256 | `common/constants/` | v1.0.0 | Stable |
| Sacred opcodes | `common/constants/` | v1.0.0 | Stable |
| `tri_mant_mul` | `common/constants/` | v1.0.0 | Stable |
| v2 HW attestation | `common/depin/v2/` | in dev | Do not modify |
| `TRIToken.sol` | `contracts/src/` | v1.0.0 | New (this PR) |
| `TRIBridge.sol` | `contracts/src/` | v1.0.0 | New (this PR) |
| `Registry.sol.draft` | `docs/registry/` | draft | New (this PR) |

---

## Security Assumptions

1. **Hardware integrity** — The chip ROM serial and embedded seed are
   tamper-proof.  Physical chip cloning is considered out of scope.

2. **Oracle independence** — The three oracle nodes are operated by distinct,
   non-colluding parties.  A single oracle compromise does not break the
   2-of-3 threshold.

3. **Indexer honesty** — The indexer daemon is a semi-trusted relay.  It cannot
   forge receipts (hardware-signed) or bypass oracle signatures.

4. **Chain liveness** — The L1/L2 chain processes transactions within a
   reasonable time window.  Stuck transactions are retried by the indexer with
   increasing gas price.

---

## References

- `contracts/README.md` — bridge and token deployment guide
- `docs/registry/README.md` — on-chain chip registry specification
- `common/depin/v1/` — HW accumulator source (v1.0.0, canonical)
- `common/depin/v2/` — next-generation attestation (in development)
- Tiny Tapeout SKY130B: https://tinytapeout.com
