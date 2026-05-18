# Trinity DePIN — Cross-Chain Anchoring Specification

**Status:** Draft v0.1  
**Authors:** Trinity Protocol Engineering  
**Last Updated:** 2025  
**Companion Docs:** `TrinityStorageRegistry.sol` (Filecoin spec), `MofNTrainingAttest.sol` (M1 spec), `BittensorSubnetAttest.sol` (M9 spec)

---

## Table of Contents

1. [Why Multi-Bridge](#1-why-multi-bridge)
2. [LayerZero V2 Integration (Primary)](#2-layerzero-v2-integration-primary)
3. [Wormhole Integration (Backup)](#3-wormhole-integration-backup)
4. [Ethereum L2 Finality — Optimism + Base](#4-ethereum-l2-finality--optimism--base)
5. [Anchor Payload Format](#5-anchor-payload-format)
6. [Cross-Bridge Reconciliation — TrinityFinality.sol](#6-cross-bridge-reconciliation--trinityfinality-sol)
7. [Failure Modes & Mitigations](#7-failure-modes--mitigations)
8. [Gas Economics](#8-gas-economics)
9. [$TRI Token Bridging](#9-tri-token-bridging)
10. [Smart Contract Addresses](#10-smart-contract-addresses)
11. [Audit Plan](#11-audit-plan)
12. [Deployment Timeline](#12-deployment-timeline)
13. [References](#13-references)

---

## 1. Why Multi-Bridge

### 1.1 Historical Bridge Exploits

Single-bridge architectures represent a critical systemic risk in cross-chain protocols. The following incidents establish the threat model:

| Incident | Date | Loss | Root Cause |
|---|---|---|---|
| Wormhole exploit | Feb 2022 | $325 M | Signature verification bypass on Solana |
| Ronin Bridge (Axie) | Mar 2022 | $625 M | 5-of-9 validator key compromise |
| Multichain | Jul 2023 | $1.5 B | Suspected insider/key exfiltration |
| Nomad Bridge | Aug 2022 | $190 M | Initialization flaw; any address could prove any message |
| Harmony Horizon | Jun 2022 | $100 M | 2-of-5 multisig key theft |

**Lesson:** No single bridge should be a single point of finality for production DePIN state. Trinity anchors machine-generated proofs (inference receipts, training attestations, cross-die quorum proofs) that gate slashing and reward distribution. A compromised anchor = a compromised economic security model.

### 1.2 Bridge Comparison

| Property | LayerZero V2 | Wormhole | Optimism/Base Native |
|---|---|---|---|
| **Architecture** | Decentralized Verifier Network (DVN) mesh; each message verified by configurable set of independent DVNs | 19-guardian multisig (Wormhole guardian network) | Optimistic rollup; proofs posted to Ethereum mainnet |
| **Trust assumption** | Threshold of independent DVNs (configurable; Trinity uses 4-of-5) | 13-of-19 guardian supermajority | Ethereum validator set + 7-day fraud proof window |
| **Finality latency** | ~5–15 min (DVN confirmation + destination chain) | ~15–30 min (guardian observation + VAA generation) | ~1–4 h (L2 block → L1 state root) / 7 days optimistic |
| **Maturity** | V2 launched 2024; [docs](https://docs.layerzero.network/v2) | Live since 2021; [wormhole.com](https://wormhole.com/) | Optimism live since 2021; Base since 2023 |
| **FVM support** | Yes (EVM-compatible endpoint) | Yes (EVM gateway) | Indirect (FVM → Ethereum → L2) |
| **Notable risks** | DVN key compromise; new architecture surface area | Guardian set cartel; proven $325 M exploit (patched) | Sequencer downtime; 7-day withdrawal delay |
| **Gas overhead** | Low–medium (per-message) | Medium (VAA post + verify) | Low (L2 execution) |

### 1.3 Defense-in-Depth Policy

> **Finality rule:** An anchor is considered **final** iff ≥ 2 of 3 independent bridge paths report the same `network_state_root` (bytes32) within a **1-hour reconciliation window**.

This means:

- A single bridge compromise cannot forge a Trinity anchor.
- An attacker must simultaneously compromise LayerZero DVN threshold **and** either Wormhole guardian supermajority **or** Ethereum L2 fraud-proof system — a near-impossible attack surface.
- Each bridge path independently records the anchor in `TrinityFinality.sol`.

---

## 2. LayerZero V2 Integration (Primary)

**Reference:** [LayerZero V2 Documentation](https://docs.layerzero.network/v2)

### 2.1 Architecture Overview

LayerZero V2 replaces V1's relayer/oracle model with **Decentralized Verifier Networks (DVNs)**. Each DVN independently verifies the packet on the source chain and submits a confirmation to the destination chain. The `MessageLib` enforces the configured DVN threshold before delivery.

```
FVM (Source)
  └─ TrinityAnchorOApp.send()
       └─ LayerZero Endpoint (EID: FVM)
            └─ [DVN1, DVN2, DVN3, DVN4, DVN5] verify packet
                 └─ LayerZero Endpoint (EID: Destination)
                      └─ TrinityAnchorOApp.lzReceive()
```

### 2.2 DVN Configuration

Trinity uses **4-of-5** required DVNs. This tolerates one DVN failure or compromise without halting anchor delivery.

| Slot | DVN | Rationale |
|---|---|---|
| 1 | LayerZero Labs | Protocol-native; highest uptime SLA |
| 2 | Google Cloud DVN | Enterprise-grade infrastructure; independent key custody |
| 3 | Polyhedra (ZK-based) | ZK proof verification path; cryptographic independence |
| 4 | Trinity Self-DVN | Protocol self-custody; runs on Trinity validator nodes |
| 5 | Operator-Elected | Community governance; rotated quarterly via DAO vote |

**DVN configuration in `SetConfigParam`:**

```solidity
// Required DVNs (all must confirm)
address[] memory requiredDVNs = new address[](4);
requiredDVNs[0] = LAYERZERO_LABS_DVN;
requiredDVNs[1] = GOOGLE_CLOUD_DVN;
requiredDVNs[2] = POLYHEDRA_DVN;
requiredDVNs[3] = TRINITY_SELF_DVN;

// Optional DVNs (at least 0-of-1 must confirm, i.e., threshold = 0)
address[] memory optionalDVNs = new address[](1);
optionalDVNs[0] = OPERATOR_ELECTED_DVN;
uint8 optionalDVNThreshold = 0; // operator DVN is bonus verification

UlnConfig memory config = UlnConfig({
    confirmations: 15,            // FVM blocks before message eligible
    requiredDVNCount: 4,
    optionalDVNCount: 1,
    optionalDVNThreshold: optionalDVNThreshold,
    requiredDVNs: requiredDVNs,
    optionalDVNs: optionalDVNs
});
```

> **Note:** Trinity Self-DVN is slot 4 (required). In an emergency where Trinity validators are compromised, governance can rotate it to optional via DAO proposal with 48 h timelock.

### 2.3 Source and Destination Chains

| Chain | LayerZero EID | Direction | Role |
|---|---|---|---|
| Filecoin EVM (FVM) | 30332 (mainnet) | Source | Originates all anchor messages |
| Ethereum mainnet | 30101 | Destination | Primary settlement layer |
| Optimism | 30111 | Destination | L2 finality |
| Base | 30184 | Destination | L2 finality |
| Arbitrum One | 30110 | Destination | L2 finality |
| Solana | 30168 | Destination | Via Stargate adapter |

### 2.4 `TrinityAnchorOApp` — Contract Skeleton

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OAppOptionsType3.sol";

/// @title TrinityAnchorOApp
/// @notice Sends Trinity network-state anchor payloads via LayerZero V2
///         from FVM (source) to all destination chains.
///         Receives anchor payloads on destination chains.
contract TrinityAnchorOApp is OApp, OAppOptionsType3 {

    // ─── Events ────────────────────────────────────────────────────────────────
    event AnchorSent(uint32 indexed dstEid, uint64 trinityPeriod, bytes32 networkStateRoot);
    event AnchorReceived(uint32 indexed srcEid, uint64 trinityPeriod, bytes32 networkStateRoot, bytes anchorPayload);

    // ─── State ─────────────────────────────────────────────────────────────────
    /// @dev TrinityFinality contract on this chain (set post-deploy)
    address public trinityFinality;

    /// @dev Authorized caller on source chain (Trinity epoch manager)
    address public epochManager;

    modifier onlyEpochManager() {
        require(msg.sender == epochManager, "TrinityAnchorOApp: not epoch manager");
        _;
    }

    constructor(address _endpoint, address _owner)
        OApp(_endpoint, _owner) {}

    // ─── Send (FVM Source Only) ────────────────────────────────────────────────

    /// @notice Called by Trinity epoch manager at the end of each period.
    ///         Broadcasts anchor payload to all configured destination chains.
    /// @param dstEid   Destination LayerZero EID
    /// @param payload  ABI-encoded AnchorPayload struct (see Section 5)
    /// @param options  LayerZero messaging options (gas limit, value)
    function sendAnchor(
        uint32 dstEid,
        bytes calldata payload,
        bytes calldata options
    ) external payable onlyEpochManager {
        // Decode period and root for event
        (uint64 period, bytes32 root) = abi.decode(payload[:64], (uint64, bytes32));

        _lzSend(
            dstEid,
            payload,
            options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );

        emit AnchorSent(dstEid, period, root);
    }

    /// @notice Quote the fee for sending an anchor to dstEid.
    function quoteAnchor(
        uint32 dstEid,
        bytes calldata payload,
        bytes calldata options
    ) external view returns (MessagingFee memory fee) {
        return _quote(dstEid, payload, options, false);
    }

    // ─── Receive (Destination Chains) ─────────────────────────────────────────

    /// @dev Called by LayerZero endpoint after DVN threshold is met.
    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        (uint64 period, bytes32 root) = abi.decode(_message[:64], (uint64, bytes32));

        // Forward to TrinityFinality for cross-bridge reconciliation
        ITrinityFinality(trinityFinality).recordBridgeAnchor(
            ITrinityFinality.BridgeSource.LAYERZERO,
            period,
            root,
            _message
        );

        emit AnchorReceived(_origin.srcEid, period, root, _message);
    }

    // ─── Admin ─────────────────────────────────────────────────────────────────

    function setTrinityFinality(address _finality) external onlyOwner {
        trinityFinality = _finality;
    }

    function setEpochManager(address _manager) external onlyOwner {
        epochManager = _manager;
    }

    receive() external payable {}
}
```

### 2.5 Hourly Anchor Schedule

- One `sendAnchor` call per hour per destination chain.
- 24 anchors/day × 5 destination chains = 120 LayerZero messages/day.
- Batching: multiple destination EIDs triggered via `sendAnchorBatch` helper (not shown) to reduce epoch manager transaction count on FVM.

---

## 3. Wormhole Integration (Backup)

**Reference:** [Wormhole Documentation](https://wormhole.com/) | [Wormhole Queries](https://docs.wormhole.com/wormhole/queries/overview)

### 3.1 Architecture Overview

Wormhole uses a **guardian network** of 19 nodes operated by independent entities (Jump Crypto, Everstake, Chorus One, etc.). A **Verifiable Action Approval (VAA)** is issued when ≥ 13-of-19 guardians observe and sign a message on the source chain.

```
FVM (Source)
  └─ Wormhole Core Bridge — publishMessage(nonce, payload, consistencyLevel)
       └─ Guardian Network (19 nodes) observe Wormhole log
            └─ ≥13 of 19 sign VAA
                 └─ Relayer submits VAA to destination
                      └─ TrinityWormholeReceiver.receiveMessage(vaa)
```

### 3.2 Posting Frequency

| Path | Frequency | Rationale |
|---|---|---|
| LayerZero (primary) | Every 1 hour | High-frequency, low-latency anchor stream |
| Wormhole (backup) | Every 4 hours | Sufficient for backup; lower cost; guardian batch efficiency |

The 4-hour Wormhole anchor still falls within the 1-hour finality reconciliation window for **finality confirmation** purposes: a Wormhole VAA posted at T+4h confirms or challenges LayerZero anchors for periods T, T+1, T+2, T+3.

### 3.3 VAA Format

```
Wormhole VAA (Binary)
├── Header
│   ├── version           : uint8  (= 1)
│   ├── guardian_set_index: uint32
│   └── signatures        : [{guardian_index: uint8, r: bytes32, s: bytes32, v: uint8}] × ≥13
├── Body
│   ├── timestamp         : uint32 (seconds, Unix)
│   ├── nonce             : uint32 (Trinity period)
│   ├── emitter_chain     : uint16 (Filecoin = 35 per Wormhole chain registry)
│   ├── emitter_address   : bytes32 (Trinity Wormhole Emitter on FVM)
│   ├── sequence          : uint64 (monotonic)
│   ├── consistency_level : uint8  (= 15, ~15 FVM blocks)
│   └── payload           : bytes  (AnchorPayload, see Section 5)
```

**Consistency level 15** corresponds to ~15 FVM block confirmations (~150 s at 10 s/block). This ensures the emitter transaction is sufficiently deep before guardians sign.

### 3.4 Trinity Wormhole Receiver (Destination)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { IWormhole } from "@wormhole-foundation/wormhole-solidity-sdk/interfaces/IWormhole.sol";

contract TrinityWormholeReceiver {
    IWormhole public immutable wormhole;
    ITrinityFinality public immutable finality;

    // Wormhole chain ID for FVM (Filecoin)
    uint16 public constant FVM_WORMHOLE_CHAIN_ID = 35;
    bytes32 public trustedEmitter; // TrinityWormholeEmitter on FVM

    mapping(bytes32 => bool) public processedVAAs;

    event WormholeAnchorReceived(uint64 trinityPeriod, bytes32 networkStateRoot);

    constructor(address _wormhole, address _finality, bytes32 _emitter) {
        wormhole = IWormhole(_wormhole);
        finality = ITrinityFinality(_finality);
        trustedEmitter = _emitter;
    }

    function receiveAnchorVAA(bytes calldata encodedVAA) external {
        // 1. Parse + verify VAA signatures against current guardian set
        (IWormhole.VM memory vm, bool valid, string memory reason) =
            wormhole.parseAndVerifyVM(encodedVAA);
        require(valid, string.concat("TrinityWormholeReceiver: invalid VAA: ", reason));

        // 2. Verify emitter
        require(vm.emitterChainId == FVM_WORMHOLE_CHAIN_ID, "wrong emitter chain");
        require(vm.emitterAddress == trustedEmitter, "untrusted emitter");

        // 3. Replay protection
        require(!processedVAAs[vm.hash], "VAA already processed");
        processedVAAs[vm.hash] = true;

        // 4. Decode Trinity payload
        (uint64 period, bytes32 root) = abi.decode(vm.payload[:64], (uint64, bytes32));

        // 5. Record in TrinityFinality
        finality.recordBridgeAnchor(
            ITrinityFinality.BridgeSource.WORMHOLE,
            period,
            root,
            vm.payload
        );

        emit WormholeAnchorReceived(period, root);
    }
}
```

### 3.5 Wormhole Queries for Read-Only Cross-Certification

[Wormhole Queries](https://docs.wormhole.com/wormhole/queries/overview) allows off-chain components to query the state of any Wormhole-connected chain without posting a transaction. Trinity uses this for:

- **Off-chain monitoring:** Guardian-signed attestation that a given `network_state_root` exists at a specific FVM block height, without paying gas on destination chains.
- **Challenge verification:** During a cross-bridge dispute (Section 6), Trinity's dispute oracle uses Wormhole Queries to cross-certify the FVM source state before triggering slashing.

---

## 4. Ethereum L2 Finality — Optimism + Base

**References:** [Optimism Docs](https://docs.optimism.io/) | [Base](https://docs.base.org/)

### 4.1 Optimistic Rollup Finality Model

Optimism and Base are OP Stack optimistic rollups. State roots are posted to Ethereum mainnet via the `OptimismPortal` / `L2OutputOracle` contracts. A **7-day challenge window** allows fault proofs to be submitted before a state root is considered final on L1.

**Key alignment with Trinity:**

> Trinity's slashing dispute window is also **7 days**. This means an L2-anchored state root achieves L1 finality at exactly the same moment the slashing challenge window closes. No anchor can be considered "safely final" on L2 while a slash is still disputable — the windows are identical by design.

### 4.2 $TRI Bridge to L2 (Canonical)

$TRI is bridged to Optimism and Base exclusively via the **canonical OP Stack bridge**, not any third-party bridge:

```
FVM → [LayerZero OFT path] → Ethereum mainnet (ERC-20)
Ethereum mainnet → [OP Canonical Bridge] → Optimism (L2 ERC-20)
Ethereum mainnet → [Base Canonical Bridge] → Base (L2 ERC-20)
```

Using the canonical bridge means $TRI inherits L1 security for withdrawals (7-day window) and avoids third-party bridge risk for the token itself. Cross-chain liquidity is supplemented by LayerZero OFT (Section 9).

### 4.3 Fee Payments on L2

| Asset | Source | Use |
|---|---|---|
| ETH (native) | Bridged from mainnet or purchased on L2 | L2 execution gas |
| USDC (native) | Circle CCTP native issuance on Base/Optimism | Anchor fee denomination |
| $TRI | Canonical bridge + OFT | Protocol-internal payments |

Native USDC via Circle's [CCTP](https://www.circle.com/cross-chain-transfer-protocol) eliminates wrapped-USDC bridge risk on Base and Optimism.

### 4.4 `TrinityL2Anchor.sol`

This contract is deployed on **each L2** (Optimism, Base, Arbitrum). It:
1. Receives anchor messages from `TrinityAnchorOApp` (LayerZero).
2. Verifies Wormhole VAAs submitted by relayers.
3. Posts the reconciled anchor on-chain for the L2 ecosystem to consume.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title TrinityL2Anchor
/// @notice Receives cross-chain anchor messages on Ethereum L2s.
///         Aggregates LayerZero and Wormhole signals, posts final anchor.
contract TrinityL2Anchor {

    // ─── Types ─────────────────────────────────────────────────────────────────
    struct L2AnchorRecord {
        bytes32  networkStateRoot;
        uint64   trinityPeriod;
        uint64   blockHeightFvm;
        uint64   timestamp;
        bool     lzConfirmed;
        bool     wormholeConfirmed;
        bool     final_;          // true when ≥2 bridges confirmed
    }

    // ─── State ─────────────────────────────────────────────────────────────────
    mapping(uint64 => L2AnchorRecord) public anchors; // period → record
    address public lzOApp;       // TrinityAnchorOApp (LayerZero)
    address public wormholeRcvr; // TrinityWormholeReceiver

    event AnchorUpdated(uint64 indexed period, bytes32 root, bool final_);

    // ─── LayerZero path ────────────────────────────────────────────────────────
    function onLayerZeroAnchor(
        uint64 period,
        bytes32 root,
        uint64 blockHeightFvm,
        uint64 timestamp
    ) external {
        require(msg.sender == lzOApp, "unauthorized");
        L2AnchorRecord storage rec = anchors[period];
        rec.networkStateRoot = root;
        rec.trinityPeriod    = period;
        rec.blockHeightFvm   = blockHeightFvm;
        rec.timestamp        = timestamp;
        rec.lzConfirmed      = true;
        _checkFinality(period);
    }

    // ─── Wormhole path ────────────────────────────────────────────────────────
    function onWormholeAnchor(
        uint64 period,
        bytes32 root
    ) external {
        require(msg.sender == wormholeRcvr, "unauthorized");
        L2AnchorRecord storage rec = anchors[period];
        // Validate root consistency if LayerZero already confirmed
        if (rec.lzConfirmed) {
            require(rec.networkStateRoot == root, "TrinityL2Anchor: root mismatch — bridge divergence");
        } else {
            rec.networkStateRoot = root;
            rec.trinityPeriod    = period;
        }
        rec.wormholeConfirmed = true;
        _checkFinality(period);
    }

    // ─── Finality check ───────────────────────────────────────────────────────
    function _checkFinality(uint64 period) internal {
        L2AnchorRecord storage rec = anchors[period];
        uint8 confirmations = (rec.lzConfirmed ? 1 : 0) + (rec.wormholeConfirmed ? 1 : 0);
        if (confirmations >= 2 && !rec.final_) {
            rec.final_ = true;
            emit AnchorUpdated(period, rec.networkStateRoot, true);
        }
    }

    function isFinal(uint64 period) external view returns (bool) {
        return anchors[period].final_;
    }
}
```

---

## 5. Anchor Payload Format

### 5.1 JSON Schema (Human-Readable)

```json
{
  "version": 1,
  "trinity_period": "<uint64>",
  "network_state_root": "<bytes32>",
  "anchor_canonical": "0x47C0",
  "die_quorum_count": "<uint16>",
  "die_signatures": ["<bytes65>", "<bytes65>", "..."],
  "merkle_root_inference_batches": "<bytes32>",
  "merkle_root_training_attestations": "<bytes32>",
  "block_height_fvm": "<uint64>",
  "timestamp": "<uint64>"
}
```

### 5.2 ABI-Encoded Layout (On-Chain)

```
AnchorPayload (ABI-encoded tuple):
┌─────────────────────────────────────────┬──────────┬─────────────────────────────────────────────┐
│ Field                                   │ Type     │ Description                                 │
├─────────────────────────────────────────┼──────────┼─────────────────────────────────────────────┤
│ version                                 │ uint8    │ Schema version; current = 1                 │
│ trinity_period                          │ uint64   │ Monotonic epoch counter (hourly increments) │
│ network_state_root                      │ bytes32  │ Merkle root of full network state           │
│ anchor_canonical                        │ bytes2   │ Fixed: 0x47C0 (cross-die quorum identifier) │
│ die_quorum_count                        │ uint16   │ Number of 0x47C0 dies that signed           │
│ die_signatures                          │ bytes65[]│ ECDSA sigs; each sig = r(32) + s(32) + v(1) │
│ merkle_root_inference_batches           │ bytes32  │ Root of inference receipt Merkle tree       │
│ merkle_root_training_attestations       │ bytes32  │ Root of training attestation Merkle tree    │
│ block_height_fvm                        │ uint64   │ FVM block at which state root was computed  │
│ timestamp                               │ uint64   │ Unix timestamp (seconds)                    │
└─────────────────────────────────────────┴──────────┴─────────────────────────────────────────────┘
```

**Solidity struct:**

```solidity
struct AnchorPayload {
    uint8    version;
    uint64   trinityPeriod;
    bytes32  networkStateRoot;
    bytes2   anchorCanonical;          // 0x47C0
    uint16   dieQuorumCount;
    bytes[]  dieSignatures;            // each element = 65 bytes
    bytes32  merkleRootInferenceBatches;
    bytes32  merkleRootTrainingAttestations;
    uint64   blockHeightFvm;
    uint64   timestamp;
}
```

### 5.3 Size and Gas Estimates (Preliminary)

| Component | Size | Notes |
|---|---|---|
| Fixed fields | 128 bytes | version through timestamp excluding dieSignatures |
| dieSignatures (assume 32 dies) | 32 × 65 = 2,080 bytes | Typical quorum size |
| ABI encoding overhead | ~64 bytes | Dynamic array header + padding |
| **Total payload** | **~2,272 bytes** | Worst-case 32 dies |
| Typical (12-of-16 dies) | ~840 bytes | Smaller quorums |

> **Preliminary gas cost estimates** (subject to change; based on current Ethereum mainnet calldata pricing post-EIP-4844):
> - Ethereum mainnet `lzReceive` + `recordBridgeAnchor`: ~250,000 gas
> - Optimism/Base (L2 execution): ~80,000 gas (L2 execution) + L1 data fee ~$0.01–0.05
> - Arbitrum: ~60,000 gas (L2 execution)

---

## 6. Cross-Bridge Reconciliation — `TrinityFinality.sol`

### 6.1 Purpose

`TrinityFinality.sol` is the **single source of truth** on each destination chain for Trinity anchor finality. It:

- Accepts anchor reports from all three bridge sources.
- Applies the ≥2-of-3 finality rule within a 1-hour window.
- Triggers the dispute/challenge mechanism when bridges diverge.

### 6.2 Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title TrinityFinality
/// @notice Cross-bridge reconciliation for Trinity DePIN anchor proofs.
///         Finality = ≥2 of 3 bridges agree on same root within 1-hour window.
contract TrinityFinality {

    // ─── Enums ─────────────────────────────────────────────────────────────────
    enum BridgeSource { LAYERZERO, WORMHOLE, L2_NATIVE }

    // ─── Types ─────────────────────────────────────────────────────────────────
    struct BridgeReport {
        bytes32 root;
        uint256 reportedAt;    // block.timestamp
        bool    exists;
    }

    struct AnchorState {
        // Per-bridge reports
        BridgeReport[3] reports;  // indexed by BridgeSource
        // Finality
        bytes32  finalRoot;
        uint256  finalizedAt;
        bool     isFinal;
        // Dispute
        bool     disputed;
        uint256  disputeWindowEnd;
    }

    // ─── Constants ─────────────────────────────────────────────────────────────
    uint256 public constant RECONCILIATION_WINDOW = 1 hours;
    uint256 public constant DISPUTE_WINDOW        = 24 hours;

    // ─── State ─────────────────────────────────────────────────────────────────
    mapping(bytes32 => AnchorState) private _anchors;     // anchor_id = keccak256(period)
    mapping(bytes32 => bool)        public  paused;        // anchor_id → paused

    address public authorizedLayerZero;
    address public authorizedWormhole;
    address public authorizedL2Native;
    address public disputeResolver;      // Trinity governance multisig

    // ─── Events ────────────────────────────────────────────────────────────────
    event BridgeAnchorRecorded(bytes32 indexed anchorId, BridgeSource source, bytes32 root);
    event AnchorFinalized(bytes32 indexed anchorId, bytes32 finalRoot, uint256 confirmedBy);
    event AnchorDisputed(bytes32 indexed anchorId, BridgeSource conflictingSource, bytes32 conflictingRoot);
    event AnchorChallengeResolved(bytes32 indexed anchorId, bool slashTriggered);

    // ─── Core: Record Bridge Report ────────────────────────────────────────────

    /// @notice Called by authorized bridge receiver contracts.
    function recordBridgeAnchor(
        BridgeSource source,
        uint64       trinityPeriod,
        bytes32      root,
        bytes calldata /*fullPayload*/
    ) external {
        _requireAuthorized(source);

        bytes32 anchorId = keccak256(abi.encodePacked(trinityPeriod));
        AnchorState storage state = _anchors[anchorId];

        BridgeReport storage report = state.reports[uint8(source)];
        require(!report.exists, "TrinityFinality: bridge already reported for this period");

        report.root       = root;
        report.reportedAt = block.timestamp;
        report.exists     = true;

        emit BridgeAnchorRecorded(anchorId, source, root);

        // Attempt reconciliation
        _reconcile(anchorId, state);
    }

    // ─── Finality Query ────────────────────────────────────────────────────────

    /// @notice Returns true iff ≥2 of 3 bridges reported the same root
    ///         within RECONCILIATION_WINDOW of each other.
    function isFinal(bytes32 anchorId) external view returns (bool) {
        return _anchors[anchorId].isFinal;
    }

    function getFinalRoot(bytes32 anchorId) external view returns (bytes32) {
        require(_anchors[anchorId].isFinal, "TrinityFinality: not final");
        return _anchors[anchorId].finalRoot;
    }

    // ─── Internal: Reconciliation Logic ───────────────────────────────────────

    function _reconcile(bytes32 anchorId, AnchorState storage state) internal {
        if (state.isFinal) return;

        BridgeReport[3] storage rpts = state.reports;
        uint8 existCount = 0;
        for (uint8 i = 0; i < 3; i++) {
            if (rpts[i].exists) existCount++;
        }
        if (existCount < 2) return;

        // Find the candidate majority root (any 2 that agree within time window)
        for (uint8 i = 0; i < 3; i++) {
            if (!rpts[i].exists) continue;
            uint8 matches = 0;
            uint256 earliest = rpts[i].reportedAt;
            uint256 latest   = rpts[i].reportedAt;
            for (uint8 j = 0; j < 3; j++) {
                if (!rpts[j].exists) continue;
                if (rpts[j].root == rpts[i].root) {
                    matches++;
                    if (rpts[j].reportedAt < earliest) earliest = rpts[j].reportedAt;
                    if (rpts[j].reportedAt > latest)   latest   = rpts[j].reportedAt;
                }
            }
            if (matches >= 2 && (latest - earliest) <= RECONCILIATION_WINDOW) {
                // Finalize
                state.finalRoot    = rpts[i].root;
                state.finalizedAt  = block.timestamp;
                state.isFinal      = true;
                emit AnchorFinalized(anchorId, rpts[i].root, matches);
                return;
            }
        }

        // If we have ≥2 reports but no 2 agree → dispute
        if (existCount >= 2) {
            _triggerDispute(anchorId, state);
        }
    }

    function _triggerDispute(bytes32 anchorId, AnchorState storage state) internal {
        if (state.disputed) return;
        state.disputed          = true;
        state.disputeWindowEnd  = block.timestamp + DISPUTE_WINDOW;

        // Identify conflicting source for event
        BridgeSource conflict = BridgeSource.LAYERZERO;
        bytes32 ref = bytes32(0);
        for (uint8 i = 0; i < 3; i++) {
            if (!_anchors[anchorId].reports[i].exists) continue;
            if (ref == bytes32(0)) { ref = _anchors[anchorId].reports[i].root; continue; }
            if (_anchors[anchorId].reports[i].root != ref) conflict = BridgeSource(i);
        }
        emit AnchorDisputed(anchorId, conflict, _anchors[anchorId].reports[uint8(conflict)].root);
    }

    // ─── Dispute Resolution ───────────────────────────────────────────────────

    /// @notice Called by Trinity governance after manual investigation.
    ///         Accepts canonical root, triggers DVN slashing if compromise confirmed.
    function resolveDispute(
        bytes32 anchorId,
        bytes32 canonicalRoot,
        bool    slashCompromisedDVN
    ) external {
        require(msg.sender == disputeResolver, "TrinityFinality: not resolver");
        AnchorState storage state = _anchors[anchorId];
        require(state.disputed, "TrinityFinality: not disputed");
        require(!state.isFinal, "TrinityFinality: already final");

        state.finalRoot   = canonicalRoot;
        state.finalizedAt = block.timestamp;
        state.isFinal     = true;
        emit AnchorChallengeResolved(anchorId, slashCompromisedDVN);

        // Slashing hook: notify LayerZero DVN slashing contract (implementation TBD)
        if (slashCompromisedDVN) {
            _notifyDVNSlash(anchorId, canonicalRoot);
        }
    }

    function _notifyDVNSlash(bytes32 anchorId, bytes32 canonicalRoot) internal {
        // TODO: call LayerZero DVN slashing interface
        // Interface: IDVNSlasher(dvnSlasher).slash(anchorId, canonicalRoot)
    }

    // ─── Auth ─────────────────────────────────────────────────────────────────
    function _requireAuthorized(BridgeSource source) internal view {
        if (source == BridgeSource.LAYERZERO)  require(msg.sender == authorizedLayerZero, "unauthorized");
        if (source == BridgeSource.WORMHOLE)   require(msg.sender == authorizedWormhole,  "unauthorized");
        if (source == BridgeSource.L2_NATIVE)  require(msg.sender == authorizedL2Native,  "unauthorized");
    }
}
```

### 6.3 `anchor_id` Computation

```
anchor_id = keccak256(abi.encodePacked(trinity_period))
```

This gives a stable, chain-agnostic identifier for each hourly anchor period.

---

## 7. Failure Modes & Mitigations

| Failure Mode | Impact | Mitigation | Finality Path |
|---|---|---|---|
| **LayerZero DVN threshold not met** (≥2 of 5 DVNs offline/compromised) | LayerZero messages not delivered | Wormhole VAA + L2 native anchor sufficient for ≥2-of-3 | Wormhole + L2 |
| **LayerZero DVN signing wrong root** (Byzantine DVN) | Malicious anchor injected via LZ path | `TrinityFinality` dispute trigger; 24 h challenge window; DVN slashed | Wormhole + L2 provide canonical root; LZ root rejected |
| **Wormhole guardian rug** (≥7 of 19 guardians compromised) | Invalid VAA accepted | LayerZero + L2 still finalize; Wormhole VAA rejected in dispute | LayerZero + L2 |
| **Wormhole smart contract exploit** | VAA verification bypass | LayerZero + L2 override; Wormhole receiver paused via governance | LayerZero + L2 |
| **L2 sequencer downtime** (Optimism/Base sequencer offline) | L2 anchor not posted | LayerZero + Wormhole finalize on Ethereum mainnet; L2 anchor delayed | LayerZero + Wormhole on mainnet |
| **L2 sequencer censorship** | L2 anchor permanently withheld | Force-include via L1 (OP Stack supports L1 force-inclusion after 24 h) | LayerZero + Wormhole; force-include on L2 |
| **FVM source node compromise** | Wrong payload emitted | Requires compromising Trinity epoch manager key; 3-of-5 multisig on FVM; hardware HSM required | FVM multisig + HSM |
| **All 3 bridges simultaneously down** | No anchor can reach ≥2-of-3 threshold | **Emergency pause:** all reward distributions and slashing halted; manual unbridging permitted after 7-day timelock | Manual governance |
| **Gas price spike** | Anchor queue backlog | Anchor messages queued on FVM; max 4 h delay tolerable before Wormhole backup covers gap | Wormhole covers gap; LZ queue drains when gas normalizes |
| **Payload size exceeds bridge limit** | Message dropped | Current ~2 KB well within LayerZero (10 KB) and Wormhole (10 KB) limits; monitor via bridge dashboard | N/A (within limits) |

### 7.1 Emergency Pause Mechanism

```solidity
// In TrinityFinality.sol (addition)
bool public globalPause;
uint256 public pauseInitiatedAt;
uint256 public constant MANUAL_UNBRIDGE_DELAY = 7 days;

function initiateEmergencyPause() external onlyGovernance {
    globalPause = true;
    pauseInitiatedAt = block.timestamp;
}

function manualUnbridge(bytes32 anchorId, bytes32 root) external onlyGovernance {
    require(globalPause, "not paused");
    require(block.timestamp >= pauseInitiatedAt + MANUAL_UNBRIDGE_DELAY, "7-day delay not elapsed");
    // governance-enforced manual finality
    _anchors[anchorId].finalRoot  = root;
    _anchors[anchorId].isFinal    = true;
}
```

---

## 8. Gas Economics

> **Note:** All figures are **preliminary estimates** based on current network conditions (Q1 2025). Actual costs will vary with L1 gas prices, EIP-4844 blob fee market, and LayerZero/Wormhole relayer pricing. All USD figures assume ETH = $3,000.

### 8.1 Per-Anchor Cost Breakdown

| Bridge | Operation | Gas (units) | Gas Price Assumption | ETH Cost | USD Cost |
|---|---|---|---|---|---|
| **LayerZero** | FVM `sendAnchor` | ~200,000 (FVM gas) | 1 nanoFIL/gas | 0.0002 FIL | ~$0.003 |
| LayerZero | Ethereum mainnet `lzReceive` | ~250,000 | 15 Gwei | 0.00375 ETH | ~$11.25 |
| LayerZero | Optimism `lzReceive` | ~80,000 (L2) + L1 data | ~0.001 Gwei L2 | <0.0001 ETH | ~$0.30 |
| LayerZero | Base `lzReceive` | ~80,000 (L2) + L1 data | ~0.001 Gwei L2 | <0.0001 ETH | ~$0.30 |
| LayerZero | Arbitrum `lzReceive` | ~60,000 (L2) | ~0.01 Gwei L2 | <0.0001 ETH | ~$0.20 |
| **LayerZero subtotal (all 5 chains)** | | | | | **~$12.05** |
| **Wormhole** | FVM `publishMessage` | ~100,000 (FVM gas) | 1 nanoFIL/gas | 0.0001 FIL | ~$0.002 |
| Wormhole | Relayer fee (Ethereum) | — | Wormhole standard | — | ~$5.00 |
| Wormhole | VAA verification (Ethereum) | ~180,000 | 15 Gwei | 0.0027 ETH | ~$8.10 |
| **Wormhole subtotal** | | | | | **~$13.10** |
| **L2 Native Anchor** | `TrinityL2Anchor` update | ~50,000 × 3 L2s | L2 gas prices | <0.0003 ETH total | **~$1.00** |
| **Per-anchor total** | | | | | **~$26.15** |

> **Caveat:** LayerZero provides fee discounts for high-volume protocols. Trinity may negotiate a volume rate. Wormhole automatic relayer pricing varies. The $8 estimate for Wormhole is conservative.

### 8.2 Daily and Annual Costs

| Frequency | Anchors | LZ Cost | Wormhole Cost | L2 Cost | Daily Total |
|---|---|---|---|---|---|
| LayerZero | 24/day (hourly) | $12.05 × 24 = $289 | — | $1.00 × 24 = $24 | — |
| Wormhole | 6/day (4-hourly) | — | $13.10 × 6 = $79 | — | — |
| **Daily total** | 24 LZ + 6 WH | $289 | $79 | $24 | **~$392** |
| **Annual total** | | ~$105K | ~$29K | ~$9K | **~$143K** |

**Funding source:** Paid from Trinity network treasury. Treasury allocation: 10% of $TRI total supply dedicated to protocol operations, including bridge fees.

### 8.3 Cost Optimization Strategies

1. **Blob calldata (EIP-4844):** Post anchor payloads as blobs on L2 instead of calldata where possible. Reduces L1 data fee component by ~10×.
2. **LayerZero volume pricing:** Negotiate enterprise rate after mainnet launch.
3. **Wormhole NTT (Native Token Transfer):** Potentially bundle $TRI bridge ops with anchor posting to amortize guardian fees.
4. **Anchor batching:** Batch up to 4 periods per LayerZero message during low-activity windows (reduces message count, not total payload).

---

## 9. $TRI Token Bridging

### 9.1 Token Architecture

| Chain | Token Type | Standard | Notes |
|---|---|---|---|
| **FVM (Filecoin EVM)** | **Native** | ERC-20 (FERC-20 compatible) | Canonical issuance; total supply minted here |
| Ethereum mainnet | OFT representation | LayerZero OFT v2 | Locked on FVM, minted on Ethereum |
| Optimism | OFT representation | LayerZero OFT v2 | Locked on FVM, minted on Optimism |
| Base | OFT representation | LayerZero OFT v2 | Locked on FVM, minted on Base |
| Arbitrum One | OFT representation | LayerZero OFT v2 | Locked on FVM, minted on Arbitrum |
| Solana | OFT-Solana representation | LayerZero OFT (Solana) | Via Stargate adapter |

### 9.2 LayerZero OFT Standard

**Reference:** [LayerZero OFT documentation](https://docs.layerzero.network/v2/developers/evm/oft/quickstart)

The OFT standard implements lock-and-mint (or burn-and-mint) semantics across chains. For $TRI:

- **FVM (source):** `TRI_OFT_Adapter` — locks tokens held in escrow, sends cross-chain message.
- **Destination chains:** `TRI_OFT` — mints/burns representation tokens.

```solidity
// On FVM: TRI_OFT_Adapter
// Locks native $TRI and sends LZ message to mint on destination
contract TRI_OFT_Adapter is OFTAdapter {
    constructor(address _token, address _lzEndpoint, address _owner)
        OFTAdapter(_token, _lzEndpoint, _owner) {}
}

// On Ethereum/Optimism/Base/Arbitrum: TRI_OFT
// Receives LZ message, mints/burns representation $TRI
contract TRI_OFT is OFT {
    constructor(address _lzEndpoint, address _owner)
        OFT("Trinity DePIN", "TRI", _lzEndpoint, _owner) {}
}
```

### 9.3 Initial Liquidity Seeding

| Pair | DEX | Chain | Initial LP Source |
|---|---|---|---|
| $TRI / FIL | Uniswap V3 (FVM deploy) | FVM | Trinity treasury |
| $TRI / ETH | Uniswap V3 | Ethereum mainnet | Trinity treasury |
| $TRI / ETH | Uniswap V3 (OP) | Optimism | Trinity treasury |
| $TRI / ETH | Uniswap V3 (Base) | Base | Trinity treasury |
| $TRI / SOL | Orca / Raydium | Solana | Community bootstrap |

**Community LP incentives:** Modeled after Bittensor's emission curve — liquidity providers earn $TRI emissions proportional to depth × duration. Emission rate decays over 4-year schedule. Smart contract: `TRI_LPIncentives.sol` (spec TBD).

### 9.4 Canonical vs. OFT Bridge Policy

| Scenario | Bridge Used | Rationale |
|---|---|---|
| $TRI FVM → Ethereum mainnet | OFT (LayerZero) | Primary route; fast, low-friction |
| $TRI Ethereum → Optimism | OP Canonical Bridge | Inherits L1 security; required for "canonical" L2 representation |
| $TRI Ethereum → Base | Base Canonical Bridge | Inherits L1 security |
| $TRI FVM → Solana | OFT via Stargate | No canonical path; OFT is best available |
| Emergency $TRI withdrawal | OP Canonical (7-day) | Security backstop; not OFT |

> **Policy:** Users and protocols that require L1-guaranteed settlement (e.g., exchanges, custody) MUST use the canonical bridge with 7-day window. OFT is for DeFi / fast-settlement use cases with LayerZero trust assumptions.

---

## 10. Smart Contract Addresses

> All addresses are **TBD** — populated at deployment. This table will be updated by the Trinity DevOps team.

| Contract | Chain | Network | Address |
|---|---|---|---|
| `TrinityAnchorOApp` (source) | FVM | Calibration testnet | TBD |
| `TrinityAnchorOApp` (source) | FVM | Mainnet | TBD |
| `TrinityAnchorOApp` (dest) | Ethereum | Sepolia testnet | TBD |
| `TrinityAnchorOApp` (dest) | Ethereum | Mainnet | TBD |
| `TrinityAnchorOApp` (dest) | Optimism | Sepolia testnet | TBD |
| `TrinityAnchorOApp` (dest) | Optimism | Mainnet | TBD |
| `TrinityAnchorOApp` (dest) | Base | Sepolia testnet | TBD |
| `TrinityAnchorOApp` (dest) | Base | Mainnet | TBD |
| `TrinityAnchorOApp` (dest) | Arbitrum | Sepolia testnet | TBD |
| `TrinityAnchorOApp` (dest) | Arbitrum | Mainnet | TBD |
| `TrinityWormholeReceiver` | Ethereum | Sepolia testnet | TBD |
| `TrinityWormholeReceiver` | Ethereum | Mainnet | TBD |
| `TrinityFinality` | Ethereum | Sepolia testnet | TBD |
| `TrinityFinality` | Ethereum | Mainnet | TBD |
| `TrinityL2Anchor` | Optimism | Sepolia testnet | TBD |
| `TrinityL2Anchor` | Optimism | Mainnet | TBD |
| `TrinityL2Anchor` | Base | Sepolia testnet | TBD |
| `TrinityL2Anchor` | Base | Mainnet | TBD |
| `TrinityL2Anchor` | Arbitrum | Sepolia testnet | TBD |
| `TrinityL2Anchor` | Arbitrum | Mainnet | TBD |
| `TRI_OFT_Adapter` | FVM | Calibration testnet | TBD |
| `TRI_OFT_Adapter` | FVM | Mainnet | TBD |
| `TRI_OFT` | Ethereum | Mainnet | TBD |
| `TRI_OFT` | Optimism | Mainnet | TBD |
| `TRI_OFT` | Base | Mainnet | TBD |
| `TRI_OFT` | Arbitrum | Mainnet | TBD |
| Solana Program ID | Solana | Devnet | TBD |
| Solana Program ID | Solana | Mainnet | TBD |

---

## 11. Audit Plan

| Auditor | Scope | Rationale | Timeline |
|---|---|---|---|
| **[Trail of Bits](https://www.trailofbits.com/)** | `TrinityAnchorOApp.sol`, `TrinityFinality.sol` | Extensive LayerZero V2 OApp audit history; strong EVM expertise | Q2 2026 (pre-testnet) |
| **[Zellic](https://www.zellic.io/)** | `TrinityWormholeReceiver.sol`, VAA parsing logic | Zellic has audited Wormhole core and integrations; specialized in cross-chain message passing | Q2 2026 (pre-testnet) |
| **[Spearbit](https://spearbit.com/)** | `TRI_OFT_Adapter.sol`, `TRI_OFT.sol`, OFT token bridging | Spearbit has reviewed LayerZero OFT standard; token bridge security specialization | Q3 2026 (pre-mainnet) |
| **Internal review** | All contracts | Trinity engineering pre-audit; fuzzing via Foundry + Echidna | Ongoing from Q1 2026 |
| **Bug bounty** | All deployed contracts | [Immunefi](https://immunefi.com/) program; max bounty $500K for critical | Post-mainnet launch |

### 11.1 Audit Scope Details

**Trail of Bits (`TrinityAnchorOApp` + `TrinityFinality`):**
- DVN configuration correctness and privilege escalation vectors
- `_lzReceive` reentrancy and message ordering attacks
- `TrinityFinality` reconciliation window manipulation (timestamp griefing)
- Dispute resolution privilege abuse
- Cross-contract call surface with `TrinityWormholeReceiver`

**Zellic (Wormhole integration):**
- VAA replay protection completeness
- Guardian set rotation handling
- Emitter address spoofing
- `parseAndVerifyVM` edge cases with malformed payloads

**Spearbit (OFT token bridge):**
- Lock/mint invariant: total supply conservation across chains
- Cross-chain replay attacks
- OFT rate-limiting configuration
- LP incentive contract economic attack vectors

---

## 12. Deployment Timeline

| Phase | Date | Milestone | Networks |
|---|---|---|---|
| **Dev + Audit** | Q1–Q2 2026 | Contracts finalized; Trail of Bits + Zellic audits complete | — |
| **Testnet Alpha** | Q3 2026 | `TrinityAnchorOApp` + `TrinityFinality` live; synthetic anchors every hour | FVM Calibration + Optimism Sepolia |
| **Testnet Beta** | Q3 2026 | Wormhole receiver live; full 3-bridge reconciliation tested; Spearbit OFT audit complete | FVM Calibration + Optimism Sepolia + Ethereum Sepolia |
| **Mainnet Phase 1** | Q4 2026 | Production deployment; hourly anchors begin; $TRI OFT live | FVM Mainnet + Ethereum Mainnet + Optimism Mainnet |
| **Mainnet Phase 2** | Q1 2027 | Add Base, Arbitrum | + Base Mainnet + Arbitrum Mainnet |
| **Mainnet Phase 3** | Q2 2027 | Solana via Stargate | + Solana Mainnet |
| **Bug bounty open** | Q4 2026 | Immunefi program live at mainnet launch | All mainnet chains |
| **Community LP incentives** | Q1 2027 | $TRI LP emissions begin per emission schedule | FVM, Ethereum, Optimism, Base |

### 12.1 Go/No-Go Criteria for Mainnet Phase 1

- [ ] Trail of Bits and Zellic audits complete with all critical/high findings resolved
- [ ] ≥ 2,000 synthetic anchors processed on testnet without reconciliation failures
- [ ] Trinity Self-DVN running on ≥ 10 independent validator nodes
- [ ] FVM Calibration → Optimism Sepolia latency P99 < 20 min
- [ ] Emergency pause mechanism tested end-to-end on testnet
- [ ] Governance multisig (3-of-5) operational on FVM

---

## 13. References

| Resource | URL |
|---|---|
| LayerZero V2 Documentation | [https://docs.layerzero.network/v2](https://docs.layerzero.network/v2) |
| LayerZero OFT Quickstart | [https://docs.layerzero.network/v2/developers/evm/oft/quickstart](https://docs.layerzero.network/v2/developers/evm/oft/quickstart) |
| LayerZero DVN Framework | [https://docs.layerzero.network/v2/developers/evm/off-chain/build-dvns](https://docs.layerzero.network/v2/developers/evm/off-chain/build-dvns) |
| Wormhole Documentation | [https://wormhole.com/](https://wormhole.com/) |
| Wormhole Queries | [https://docs.wormhole.com/wormhole/queries/overview](https://docs.wormhole.com/wormhole/queries/overview) |
| Wormhole Solidity SDK | [https://github.com/wormhole-foundation/wormhole-solidity-sdk](https://github.com/wormhole-foundation/wormhole-solidity-sdk) |
| Optimism Documentation | [https://docs.optimism.io/](https://docs.optimism.io/) |
| Base Documentation | [https://docs.base.org/](https://docs.base.org/) |
| Stargate Finance | [https://stargate.finance/](https://stargate.finance/) |
| Circle CCTP | [https://www.circle.com/cross-chain-transfer-protocol](https://www.circle.com/cross-chain-transfer-protocol) |
| LayerZero Chain Endpoints | [https://docs.layerzero.network/v2/developers/evm/technical-reference/endpoints](https://docs.layerzero.network/v2/developers/evm/technical-reference/endpoints) |
| Wormhole Chain IDs | [https://docs.wormhole.com/wormhole/reference/chain-ids](https://docs.wormhole.com/wormhole/reference/chain-ids) |
| OP Stack Force Inclusion | [https://docs.optimism.io/builders/dapp-developers/bridging/messaging](https://docs.optimism.io/builders/dapp-developers/bridging/messaging) |
| Trinity `TrinityStorageRegistry.sol` | Filecoin storage spec (companion doc) |
| Trinity `MofNTrainingAttest.sol` | M1 training attestation spec (companion doc) |
| Trinity `BittensorSubnetAttest.sol` | M9 Bittensor subnet attestation spec (companion doc) |
| Immunefi Bug Bounty Platform | [https://immunefi.com/](https://immunefi.com/) |
| Trail of Bits | [https://www.trailofbits.com/](https://www.trailofbits.com/) |
| Zellic | [https://www.zellic.io/](https://www.zellic.io/) |
| Spearbit | [https://spearbit.com/](https://spearbit.com/) |

---

*End of CROSS_CHAIN_BRIDGE_SPEC.md — Trinity DePIN v0.1 Draft*
