# Trinity TRI-NET Contracts

Solidity smart contracts for the **$TRI** proof-of-compute token and the
**TRIBridge** oracle gateway.  These contracts implement Layer 3 of the
Trinity DePIN stack (see [`docs/depin/architecture.md`](../docs/depin/architecture.md)).

## Overview

```
Trinity Triad HW (3 chips)
  ↓  USB/serial ClaimReceipt
Off-chain Indexer (TypeScript daemon)
  ↓  gathers 2-of-3 oracle signatures
TRIBridge.claim()  [on-chain]
  ↓  verified → TRIToken.mint()
User Wallet (ERC-20 TRI)
```

## Contracts

| File | Description |
|------|-------------|
| `src/TRIToken.sol` | Minimal ERC-20, mint/burn controlled exclusively by bridge |
| `src/TRIBridge.sol` | 2-of-3 oracle multi-sig gateway; receipt validation, replay protection, slashing |
| `test/TRIToken.t.sol` | Foundry tests: mint, burn, transfer, allowance |
| `test/TRIBridge.t.sol` | Foundry tests: sig threshold, nonce, caps, slash |
| `script/Deploy.s.sol` | Deployment script for Base Sepolia (and any EVM chain) |

---

## Architecture

### TRIToken

- Standard ERC-20 (`name="Trinity Compute Token"`, `symbol="TRI"`, `decimals=18`).
- Total supply is uncapped; inflation is bounded by hardware throughput.
- The `bridge` address is set in the constructor and **immutable**.
- Only the bridge can call `mint()` or `burn()`.

### TRIBridge

#### ClaimReceipt struct

```solidity
struct ClaimReceipt {
    bytes32 chipSerial;      // Unique chip ROM identifier
    uint256 nonce;           // Monotonically increasing sequence counter per chip
    uint256 amount;          // TRI to mint (wei)
    bytes32 vrfReceiptHash;  // VRF output from HW (v2 attestation, NeuronConstant/common/depin/v2/)
    uint8   chipType;        // 0=phi, 1=euler, 2=gamma
    address claimant;        // Destination wallet
    bytes   signatures;      // Packed 65-byte ECDSA sigs from oracles
}
```

#### Chip type reward caps

| chipType | Chip | Tile | Max per claim |
|----------|------|------|---------------|
| 0 | phi | 1×1 | 1 TRI |
| 1 | euler | 2×2 | 2 TRI |
| 2 | gamma | 4×2 | 4 TRI |

These caps mirror the hardware-assigned reward weights in
`common/depin/v1/tri_token_accumulator.v`.

#### Oracle multi-sig

- Three oracle addresses are set at deploy time.
- A claim requires **≥ 2 distinct oracle signatures** (2-of-3 threshold).
- Signatures are packed 65-byte ECDSA (`r ++ s ++ v`) over the EIP-191
  personal-sign hash of the receipt fields.
- This mirrors the hardware M-of-N attestation scheme in the Trinity Triad.

#### Replay protection

- `processedReceipts[receiptHash] → bool` — marks each receipt hash as consumed.
- `chipNonces[chipSerial] → uint256` — nonce must strictly increase per chip.

#### Slashing

- An oracle can call `slashReceipt(receiptHash, evidence)` to flag a fraudulent
  claim on-chain.
- Off-chain enforcement: the indexer daemon monitors `Slashed` events and applies
  a penalty of `balance >> 4` (6.25 %) to the claimant's accumulated rewards.

---

## How HW Receipts Become On-Chain Claims

1. **Hardware** — Each Trinity Triad chip runs `tri_token_accumulator.v`
   (v1.0.0, `common/depin/v1/`). After each work cycle the accumulator
   increments a local counter and serialises a `ClaimReceipt` over the
   USB/serial interface.

2. **Off-chain Indexer** — A TypeScript daemon listens for receipts, validates
   the VRF proof (from v2 attestation, `common/depin/v2/`), and requests
   signatures from the three oracle nodes.

3. **TRIBridge.claim()** — Once 2-of-3 oracle signatures are collected, the
   indexer submits the receipt on-chain.  The bridge verifies signatures,
   nonce, and amount cap, then calls `TRIToken.mint()`.

4. **User** — The minted TRI appears in the claimant's standard ERC-20 wallet
   and can be transferred or swapped on any DEX.

---

## Security Model

| Threat | Mitigation |
|--------|------------|
| Replay attack | `processedReceipts` mapping; each hash consumed once |
| Nonce regression / reorder | `chipNonces` enforces strict monotonic increase |
| Rogue oracle | 2-of-3 threshold — single oracle compromise insufficient |
| Over-minting | Per-chipType amount caps enforced on-chain |
| Fraudulent receipt | Slashing mechanism + off-chain indexer validation |
| Key compromise | Oracle rotation requires a new contract deploy (or add a timelock) |

---

## Deployment

See [`script/Deploy.s.sol`](script/Deploy.s.sol) for full instructions.

**Quick start (Base Sepolia):**

```bash
forge install foundry-rs/forge-std
forge build

export DEPLOYER_PK=0x...
export ORACLE_0=0x...
export ORACLE_1=0x...
export ORACLE_2=0x...

forge script contracts/script/Deploy.s.sol \
  --rpc-url https://sepolia.base.org \
  --private-key $DEPLOYER_PK \
  --broadcast --verify -vvvv
```

---

## On-chain Registry

For chip registration, geo-discovery, and anti-Sybil deposit logic, see the
[DePIN Registry Specification](../docs/registry/README.md).
