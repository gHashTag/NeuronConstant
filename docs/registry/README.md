# Trinity DePIN On-Chain Registry Specification

This document specifies the on-chain chip registry for the Trinity TRI-NET
DePIN (Decentralized Physical Infrastructure Network).  The registry provides
a canonical source of truth for hardware identity, geographic distribution,
and operational status of Trinity Triad chips.

---

## 1. Purpose

The registry serves three audiences:

| Consumer | Use case |
|----------|----------|
| **TRIBridge** | Validate that `chipSerial` exists, is not slashed, and matches the expected `chipType` before minting |
| **Indexer daemon** | Discover active chips by region or type |
| **Governance / users** | Audit geographic distribution, detect Sybil clusters |

---

## 2. Chip Record Structure

```solidity
struct ChipRecord {
    bytes32  serial;          // Unique chip ROM identifier (matches TRIBridge.ClaimReceipt.chipSerial)
    bytes33  pubkey;          // Compressed ECDSA public key (secp256k1)
    uint8    chipType;        // 0=phi, 1=euler, 2=gamma
    bytes12  geoLocation;     // Geohash (right-padded with null bytes to 12 chars)
    uint64   commissionTime;  // Unix timestamp of first registration
    uint64   lastClaim;       // Unix timestamp of last successful bridge claim
    uint256  totalEarned;     // Cumulative TRI minted for this chip (in wei)
    bool     slashed;         // True if the chip has been penalised by the bridge
}
```

### Geohash precision

| Characters | Precision | Use case |
|------------|-----------|----------|
| 4 | ~40 km | City-level bucketing |
| 6 | ~1.2 km | Neighbourhood-level |
| 7 | ~150 m | Building-level |
| 9 | ~5 m | Precise GPS |

The registry stores up to 12 characters; callers can truncate for coarser
queries.  Precision is tunable per deployment.

---

## 3. Operations

### 3.1 `register(bytes32 serial, bytes33 pubkey, uint8 chipType, bytes8 geoHash)`

**Open registration** — any party may register a chip.

- **Anti-Sybil deposit**: caller must attach **0.01 ETH** (refundable on `decommission`).
- Reverts if `chips[serial].commissionTime != 0` (already registered).
- Reverts if `chipType > 2` (unknown type).
- Stores `ChipRecord` with `commissionTime = block.timestamp`.
- Emits `ChipRegistered(serial, pubkey, chipType, geoHash, msg.sender)`.

### 3.2 `updateLocation(bytes32 serial, bytes8 newGeoHash)`

- Caller must be the original registrant (stored as `owner` in record).
- Emits `LocationUpdated(serial, oldGeoHash, newGeoHash)`.

### 3.3 `decommission(bytes32 serial)`

- Caller must be the original registrant.
- Sets `ChipRecord.commissionTime = 0` (marks inactive).
- Refunds the 0.01 ETH anti-Sybil deposit.
- Emits `ChipDecommissioned(serial, msg.sender)`.

### 3.4 `slash(bytes32 serial)` — `onlyBridge`

- Sets `chips[serial].slashed = true`.
- **Does not refund** the deposit (forfeited as penalty).
- Bridge calls this after `slashReceipt()` is confirmed.
- Emits `ChipSlashed(serial)`.

### 3.5 `recordClaim(bytes32 serial, uint256 amount)` — `onlyBridge`

- Updates `lastClaim = block.timestamp`.
- Adds `amount` to `totalEarned`.
- Emits `ClaimRecorded(serial, amount, totalEarned)`.

---

## 4. Discovery Functions

```solidity
// Returns all serials whose geoLocation starts with `geoPrefix` (4-byte prefix).
function getChipsByGeo(bytes4 geoPrefix) external view returns (bytes32[] memory);

// Returns all serials of a given chipType.
function getChipsByType(uint8 chipType) external view returns (bytes32[] memory);

// Returns count of chips with commissionTime > 0 and slashed = false.
function totalActive() external view returns (uint256);

// Returns the full ChipRecord for a serial.
function getChip(bytes32 serial) external view returns (ChipRecord memory);
```

> **Gas note:** `getChipsByGeo` and `getChipsByType` iterate over an internal
> array.  For networks with >10 000 chips, prefer an off-chain indexer
> (e.g., The Graph) and use the on-chain functions only for critical path
> validation.

---

## 5. Integration with TRIBridge

The bridge calls two registry methods during `claim()`:

1. `registry.getChip(receipt.chipSerial)` — verifies the chip is registered
   and `!slashed`.
2. `registry.recordClaim(receipt.chipSerial, receipt.amount)` — updates stats
   after a successful mint.

The bridge address is set in the registry constructor and is immutable.

---

## 6. Threat Model

### 6.1 Sybil Attack

**Threat:** Attacker registers thousands of fake chip serials to inflate
claim capacity.

**Mitigation:**
- 0.01 ETH deposit per chip serial raises the cost of mass registration.
- Bridge validates that the `chipSerial` provided in the claim matches a
  registered record with a known `pubkey`.  The hardware VRF receipt is
  signed by the chip's private key corresponding to `pubkey`.
- Optional KYC / vouching by the oracle set (governance extension).

### 6.2 Geo-Spoofing

**Threat:** Operator reports a false geolocation to appear in a high-value
geographic zone or to game distribution incentives.

**Mitigation:**
- Geohash is informational; reward amounts are not geo-weighted in v1.
- Future versions may add a geo-oracle that cross-checks GPS attestation from
  the indexer daemon.
- Community reporting: any party can submit a slash challenge with evidence.

### 6.3 Key Compromise

**Threat:** Attacker obtains a chip's private key and submits forged receipts.

**Mitigation:**
- HW key is locked in chip ROM; exfiltration requires physical access.
- VRF receipts use a one-time-use nonce; old nonces are rejected by the bridge.
- On compromise, the original registrant can call `decommission()` and
  re-register the chip with a new keypair.

### 6.4 Registry DOS

**Threat:** Attacker spams `register()` to bloat storage and degrade discovery
functions.

**Mitigation:**
- Anti-Sybil deposit (0.01 ETH) makes mass registration economically
  unfeasible at current ETH prices.
- Discovery functions can be replaced by an off-chain indexer for production
  use without affecting security.

---

## 7. Events Summary

| Event | Emitted by | Key fields |
|-------|-----------|------------|
| `ChipRegistered` | `register` | serial, pubkey, chipType, geoHash, owner |
| `LocationUpdated` | `updateLocation` | serial, oldGeoHash, newGeoHash |
| `ChipDecommissioned` | `decommission` | serial, owner |
| `ChipSlashed` | `slash` | serial |
| `ClaimRecorded` | `recordClaim` | serial, amount, totalEarned |

---

## 8. Draft Contract

See [`Registry.sol.draft`](./Registry.sol.draft) for the Solidity skeleton.
Full deployment follows the same Foundry workflow as the bridge contracts
(see [`contracts/README.md`](../../contracts/README.md)).
