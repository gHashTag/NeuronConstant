# Trinity DePIN ↔ Filecoin/IPFS Integration Specification

**Document ID:** TRINITY-STOR-001  
**Status:** DRAFT — all prices and replica counts marked *preliminary*  
**Last Updated:** 2025-07-14  
**Authors:** Trinity DePIN Architecture Working Group  
**Related:** Trinity DePIN Gap Analysis (github.com/NeuronConstant), Zenodo DOI [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

---

## Table of Contents

1. [Why Filecoin over S3/Arweave](#1-why-filecoin-over-s3arweave)
2. [Trinity Storage Objects](#2-trinity-storage-objects)
3. [Storage Deal Flow](#3-storage-deal-flow)
4. [TrinityStorageRegistry.sol](#4-trinystorageregistrysol)
5. [Retrieval Architecture](#5-retrieval-architecture)
6. [Incentive Layer](#6-incentive-layer)
7. [Anti-DoS / Spam](#7-anti-dos--spam)
8. [Backup Paths](#8-backup-paths)
9. [Privacy Considerations](#9-privacy-considerations)
10. [Implementation Timeline](#10-implementation-timeline)
11. [References](#11-references)
12. [Open Questions](#12-open-questions)

---

## 1. Why Filecoin over S3/Arweave

Trinity DePIN requires a storage layer with three non-negotiable properties: **cryptographic proof of persistence**, **decentralized redundancy**, and **on-chain verifiability**. The following comparison evaluates the primary candidates.

### 1.1 Comparison Table

| Property | Filecoin | Arweave | AWS S3 | IPFS (pinning alone) |
|---|---|---|---|---|
| **Payment model** | Ongoing FIL rent per epoch | One-time AR fee at upload | Monthly USD per GB | Free (no incentive) |
| **Persistence guarantee** | Cryptographic: PoRep + PoSt every 24h ([spec.filecoin.io](https://spec.filecoin.io/#algorithms__pos)) | Economic endowment model; no continuous replication proof | SLA-backed centralized durability | None — content evicted if no pinner |
| **Replication proof** | Yes — PoRep proves unique sealed copy per SP | No — SPoRA proves access to data but not N distinct copies | No | No |
| **EVM compatibility** | Yes — Filecoin Virtual Machine (FVM) allows Solidity contracts ([docs.filecoin.io/smart-contracts/fundamentals/the-fvm](https://docs.filecoin.io/smart-contracts/fundamentals/the-fvm)) | No native EVM; bridge required | N/A | No |
| **Slashing / challenge** | Storage Providers slashed for missed PoSt; `WindowPoSt` every proving period | No slashing mechanism | N/A | N/A |
| **Censorship resistance** | High — permissionless SP market | High | Low — single provider, account closure risk | Medium — depends on pinner set |
| **Retrieval layer** | Filecoin retrieval markets + Saturn CDN + Lassie fallback | Native Arweave gateways | HTTPS | IPFS HTTP gateways |
| **On-chain anchoring** | Native via FVM Solidity; CID + PoRep proof emitted as event | Requires external bridge | Requires oracle | Requires external contract |
| **Trinity fit** | ✅ Best fit | Backup for Zenodo-tier artifacts only | ❌ Centralized | ❌ No persistence guarantee |

### 1.2 Key Rationale

**Proof-of-Spacetime (PoSt)** requires Storage Providers to repeatedly prove, at every 24-hour `WindowPoSt` deadline, that they still hold the exact sealed sectors containing client data ([spec.filecoin.io § Proof-of-Spacetime](https://spec.filecoin.io/#algorithms__pos__nontechnical_description)). A missed PoSt triggers automatic slashing of the SP's pre-committed collateral. This is the closest existing primitive to a cryptographic SLA, and it maps directly onto Trinity's requirement that training bundle persistence be auditable on-chain.

**FVM** enables Trinity's `TrinityStorageRegistry.sol` contract to live on the same chain as the storage deals, accepting PoRep proofs as calldata without a cross-chain bridge. This reduces the oracle trust surface compared to anchoring on Ethereum while referencing off-chain Filecoin state.

**Arweave** is retained as a tertiary fallback only for Zenodo-class release artifacts (GDS tarballs, RTL snapshots) where the one-time permaweb model is operationally convenient and the absence of replication proofs is acceptable given the long-tail nature of the data.

---

## 2. Trinity Storage Objects

Every object stored on Filecoin is content-addressed via CID v1 (SHA-256 multihash, `dag-pb` codec or `raw` for leaf nodes). The IPFS layer provides the retrieval namespace; Filecoin provides the persistence layer.

### 2.1 Object Taxonomy

| Object Class | Size (est.) | Frequency | Replicas (*preliminary*) | Encryption | On-chain anchor |
|---|---|---|---|---|---|
| **Training Bundle** | ~50 MB | Per training run | 3 | Operator AES-256 + Shamir 3-of-5 | `anchorTrainingBundle()` |
| **Inference Receipt Batch** | ~1 KB × 1,000/day/node | Daily per node | 3 | None (public) | `anchorInferenceBatch()` |
| **Reproducibility Package** | ~500 MB per release | Per formal release | 5 (*preliminary*) | None (public) | `anchorTrainingBundle()` with `type=RELEASE` |
| **Public Datasets (BPB)** | Variable, ~1–100 GB | On acquisition | 3 | None (public) | `anchorDataset()` |
| **Zenodo Mirror** | ~500 MB (DOI 10.5281/zenodo.19227877) | Once + updates | 5 | None (public) | `anchorZenodo()` |

### 2.2 Training Bundle Schema (v0.1)

A training bundle is a deterministic tar archive produced at the end of each Trinity training epoch:

```
training_bundle_v0.tar
├── checkpoint/
│   ├── weights.nf4          # NF4 quantized weights checkpoint
│   ├── weights.posit16      # Posit16 format (Opus 4.6 co-authored)
│   └── weights.gf           # GF (Generic Float) format
├── audit/
│   └── r_si_1_audit.log     # R-SI-1 audit log (append-only)
├── quorum/
│   └── mofn_signatures.json # M-of-N quorum signatures (BLS, threshold M)
├── proof/
│   └── lucas_post.trace     # Lucas-POST execution trace
└── manifest.json            # SHA-256 hashes of all above, bundle CID, epoch ID
```

**Manifest format:**

```json
{
  "schema_version": "0.1",
  "epoch_id": "<uint64>",
  "timestamp_utc": "<ISO-8601>",
  "bundle_cid": "<CIDv1-base32>",
  "weights": {
    "nf4_sha256": "<hex>",
    "posit16_sha256": "<hex>",
    "gf_sha256": "<hex>"
  },
  "quorum": {
    "threshold_m": "<int>",
    "total_n": "<int>",
    "signers": ["<address>", "..."],
    "aggregate_bls_sig": "<hex>"
  },
  "lucas_post_root": "<hex>",
  "anchor": "0x47C0"
}
```

### 2.3 Inference Receipt Batch Schema (v0.1)

Inference receipts are batched daily per node into a single IPLD CAR file:

```json
{
  "schema_version": "0.1",
  "node_id": "<die_address>",
  "batch_date": "<YYYY-MM-DD>",
  "receipts": [
    {
      "inference_id": "<uuid>",
      "model_cid": "<CIDv1>",
      "input_hash": "<sha256-hex>",
      "output_hash": "<sha256-hex>",
      "silicon_sig": "<hex>",
      "signer_die": "<address>",
      "timestamp_utc": "<ISO-8601>"
    }
  ],
  "batch_root": "<merkle-root-hex>",
  "anchor": "0x47C0"
}
```

Silicon signatures use the on-die secure enclave key; the `signer_die` address is the public key fingerprint registered in the Trinity node registry contract.

---

## 3. Storage Deal Flow

### 3.1 Actors

| Actor | Role |
|---|---|
| **Trinity Node** | Produces bundles, pins to IPFS, initiates Filecoin deals |
| **Filecoin SP (Storage Provider)** | Accepts deals, seals sectors, proves PoRep + PoSt |
| **Trinity FVM Contract** (`TrinityStorageRegistry.sol`) | On-chain registry; accepts PoRep proofs; emits `StorageAnchored` events |
| **IPFS Gateway** | `trinity-ipfs.depin.dev` (placeholder) — retrieval endpoint |
| **Lassie** | Filecoin retrieval fallback for cached content not available on IPFS |
| **Saturn** | CDN retrieval network over Filecoin ([saturn.tech](https://saturn.tech)) |

### 3.2 Sequence Diagram — Training Bundle

```
Trinity Node              IPFS Node           Filecoin SP         TrinityStorageRegistry.sol
     |                        |                    |                         |
     |--pin(bundle_tar)------>|                    |                         |
     |<--CID v1 (base32)------|                    |                         |
     |                        |                    |                         |
     |--make_deal(CID,        |                    |                         |
     |    duration=365d,      |                    |                         |
     |    replicas=3,         |---->               |                         |
     |    price=*preliminary*)-------->----------->|                         |
     |                        |         accept_deal|                         |
     |                        |                    |--PoRep(seal sector)---->|
     |                        |                    |   (24-48h sealing)      |
     |                        |                    |                         |
     |<---deal_id, porep_proof--------------------|                         |
     |                        |                    |                         |
     |--anchorTrainingBundle( |                    |                         |
     |    cid,                |                    |                         |
     |    mofn_quorum_sig,    |                    |                         |
     |    porep_proof)----------------------------------------->----------->|
     |                        |                    |         emit StorageAnchored(cid, 0x47C0)
     |<--tx_receipt-------------------------------------------------<--------|
     |                        |                    |                         |
     :   (every 24h)          :                    |                         |
     :                        :                    |--WindowPoSt------------>|
     :                        :                    |   (prove sector still   |
     :                        :                    |    held, or slash)      |
```

### 3.3 Sequence Diagram — Inference Receipt Batch (Daily)

```
Trinity Node              IPFS Node           TrinityStorageRegistry.sol
     |                        |                         |
     |--aggregate_receipts()  |                         |
     |   (1,000 receipts/day) |                         |
     |--pin(batch.car)------->|                         |
     |<--CID v1---------------|                         |
     |--anchorInferenceBatch( |                         |
     |    cid,                |                         |
     |    signer_die,         |                         |
     |    silicon_sig)--------------------------------->|
     |                        |         emit StorageAnchored(cid, 0x47C0)
     |<--tx_receipt---------------------------------<---|
```

*Note: Inference batches use IPFS-only storage for 30 days, then migrate to Filecoin deals for archival (deal duration: 180d, 3 replicas, *preliminary*).*

### 3.4 Deal Parameters (Preliminary)

| Parameter | Training Bundle | Inference Batch (archival) | Reproducibility Package |
|---|---|---|---|
| Duration | 365 days | 180 days | 1,095 days (3 yr) |
| Replicas | 3 (*preliminary*) | 3 (*preliminary*) | 5 (*preliminary*) |
| Verified deal | Yes (DataCap if eligible) | No | Yes |
| Start epoch offset | +2880 epochs (~24h) | +2880 epochs | +5760 epochs (~48h) |
| Price cap (*preliminary*) | 0.0000000005 FIL/GiB/epoch | 0.0000000005 FIL/GiB/epoch | 0.0000000005 FIL/GiB/epoch |

Epoch duration on Filecoin mainnet: 30 seconds ([spec.filecoin.io § Expected Consensus](https://spec.filecoin.io/#algorithms__expected_consensus)).

---

## 4. TrinityStorageRegistry.sol

This contract is deployed on the **Filecoin Virtual Machine (FVM)** ([docs.filecoin.io/smart-contracts/fundamentals/the-fvm](https://docs.filecoin.io/smart-contracts/fundamentals/the-fvm)). It serves as the authoritative on-chain index of all Trinity storage anchors.

### 4.1 Storage Layout

```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @title  TrinityStorageRegistry
/// @notice On-chain registry for Trinity DePIN storage anchors on FVM.
///         Accepts Filecoin PoRep proofs and M-of-N quorum signatures as
///         calldata; emits StorageAnchored events indexable by CID.
/// @dev    Deployed on Filecoin Mainnet (chainId 314) and Calibration (chainId 314159).
///         anchor constant 0x47C0 is the Trinity anchor tag (see Trinity DePIN spec).
contract TrinityStorageRegistry {

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    uint256 public constant ANCHOR = 0x47C0;
    uint256 public constant CHALLENGE_WINDOW = 7 days;
    uint256 public constant STORAGE_SUBSIDY_EPOCHS = 365 days; // preliminary

    // -------------------------------------------------------------------------
    // Storage Layout
    // -------------------------------------------------------------------------

    /// @notice Registry of anchored CIDs → anchor metadata
    mapping(bytes32 => AnchorRecord) public anchors;

    /// @notice Active storage challenges
    mapping(bytes32 => Challenge) public challenges;

    /// @notice Approved Storage Provider addresses (Trinity-preferred allowlist)
    mapping(address => bool) public approvedSPs;

    /// @notice Treasury address (receives $TRI burn proceeds for subsidy)
    address public treasury;

    /// @notice DAO multisig admin
    address public admin;

    /// @notice Quorum verifier contract (validates M-of-N BLS signatures)
    address public quorumVerifier;

    struct AnchorRecord {
        bytes32  cid;             // CIDv1 multihash (SHA-256, truncated to bytes32)
        uint8    objectType;      // 0=TrainingBundle, 1=InferenceBatch, 2=Release, 3=Dataset, 4=Zenodo
        address  operator;        // Trinity node operator
        address  signerDie;       // On-die signer address (inference receipts)
        uint256  anchoredAt;      // block.timestamp
        uint256  dealExpiry;      // Filecoin deal expiry epoch (converted to timestamp)
        bool     subsidized;      // Whether storage subsidy was granted
        bool     challenged;      // Whether an active challenge exists
    }

    struct Challenge {
        address  challenger;
        uint256  issuedAt;
        uint256  deadline;        // issuedAt + CHALLENGE_WINDOW
        bool     resolved;
        bool     slashed;
    }

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted whenever a CID is anchored (training bundle, inference batch, etc.)
    event StorageAnchored(bytes32 indexed cid, uint256 anchor);

    /// @notice Emitted when a storage challenge is opened
    event StorageChallenged(bytes32 indexed cid, address indexed challenger, uint256 deadline);

    /// @notice Emitted when a challenge is resolved (SP responded with fresh PoSt)
    event ChallengeResolved(bytes32 indexed cid, bool slashed);

    /// @notice Emitted when a subsidy is granted from treasury
    event SubsidyGranted(bytes32 indexed cid, address indexed operator, uint256 amount);

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error CIDAlreadyAnchored(bytes32 cid);
    error InvalidQuorumSignature();
    error InvalidPoRepProof();
    error InvalidSiliconSignature();
    error ChallengeAlreadyActive(bytes32 cid);
    error ChallengePeriodExpired(bytes32 cid);
    error ChallengeNotFound(bytes32 cid);
    error NotApprovedSP(address sp);
    error Unauthorized();

    // -------------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------------

    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized();
        _;
    }

    modifier notAnchored(bytes32 cid) {
        if (anchors[cid].anchoredAt != 0) revert CIDAlreadyAnchored(cid);
        _;
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    constructor(address _treasury, address _admin, address _quorumVerifier) {
        treasury       = _treasury;
        admin          = _admin;
        quorumVerifier = _quorumVerifier;
    }

    // -------------------------------------------------------------------------
    // Core Anchor Functions
    // -------------------------------------------------------------------------

    /// @notice Anchor a training bundle CID after verifying M-of-N quorum sig + PoRep proof.
    /// @param  cid            CIDv1 multihash (SHA-256) of the training bundle tar archive.
    /// @param  mof_quorum_sig Aggregated BLS signature from M-of-N quorum signers (M >= threshold).
    /// @param  porep_proof    Filecoin PoRep proof bytes from the sealing SP.
    /// @param  dealExpiry     Filecoin deal expiry as Unix timestamp.
    function anchorTrainingBundle(
        bytes32          cid,
        bytes   calldata mof_quorum_sig,
        bytes   calldata porep_proof,
        uint256          dealExpiry
    )
        external
        notAnchored(cid)
    {
        // Verify M-of-N quorum signature over (cid, block.chainid)
        bool quorumValid = IQuorumVerifier(quorumVerifier).verify(
            cid,
            mof_quorum_sig
        );
        if (!quorumValid) revert InvalidQuorumSignature();

        // Verify Filecoin PoRep proof (delegated to precompile or verifier contract)
        bool porepValid = _verifyPoRep(cid, porep_proof);
        if (!porepValid) revert InvalidPoRepProof();

        anchors[cid] = AnchorRecord({
            cid:         cid,
            objectType:  0,
            operator:    msg.sender,
            signerDie:   address(0),
            anchoredAt:  block.timestamp,
            dealExpiry:  dealExpiry,
            subsidized:  false,
            challenged:  false
        });

        emit StorageAnchored(cid, ANCHOR);

        // Attempt treasury subsidy for valid training bundles in first year
        _tryGrantSubsidy(cid, msg.sender);
    }

    /// @notice Anchor a daily inference receipt batch.
    /// @param  cid         CIDv1 multihash of the batch CAR file.
    /// @param  signer_die  Address of the on-die signer that produced silicon_sig.
    /// @param  silicon_sig ECDSA or EdDSA signature from the on-die secure enclave key.
    function anchorInferenceBatch(
        bytes32          cid,
        address          signer_die,
        bytes   calldata silicon_sig
    )
        external
        notAnchored(cid)
    {
        // Verify silicon signature: signer_die signed keccak256(cid)
        bytes32 digest = keccak256(abi.encodePacked(cid, block.chainid));
        bool sigValid = _verifySiliconSig(signer_die, digest, silicon_sig);
        if (!sigValid) revert InvalidSiliconSignature();

        anchors[cid] = AnchorRecord({
            cid:         cid,
            objectType:  1,
            operator:    msg.sender,
            signerDie:   signer_die,
            anchoredAt:  block.timestamp,
            dealExpiry:  block.timestamp + 180 days,  // preliminary
            subsidized:  false,
            challenged:  false
        });

        emit StorageAnchored(cid, ANCHOR);
    }

    // -------------------------------------------------------------------------
    // Challenge Mechanism
    // -------------------------------------------------------------------------

    /// @notice Anyone can challenge a CID's storage. The SP must produce a fresh
    ///         WindowPoSt within CHALLENGE_WINDOW (7 days) or lose deal collateral.
    /// @param  cid  The CIDv1 to challenge.
    function challengeStorage(bytes32 cid) external {
        AnchorRecord storage rec = anchors[cid];
        if (rec.anchoredAt == 0) revert ChallengeNotFound(cid);
        if (rec.challenged)      revert ChallengeAlreadyActive(cid);

        rec.challenged = true;
        challenges[cid] = Challenge({
            challenger: msg.sender,
            issuedAt:   block.timestamp,
            deadline:   block.timestamp + CHALLENGE_WINDOW,
            resolved:   false,
            slashed:    false
        });

        emit StorageChallenged(cid, msg.sender, block.timestamp + CHALLENGE_WINDOW);
    }

    /// @notice SP calls this to resolve a challenge by submitting a fresh PoSt proof.
    /// @param  cid       The challenged CIDv1.
    /// @param  post_proof Fresh WindowPoSt proof bytes.
    function resolveChallenge(bytes32 cid, bytes calldata post_proof) external {
        Challenge storage ch = challenges[cid];
        if (ch.resolved)                       revert ChallengeNotFound(cid);
        if (block.timestamp > ch.deadline)     revert ChallengePeriodExpired(cid);

        bool postValid = _verifyWindowPoSt(cid, post_proof);
        ch.resolved = true;
        ch.slashed  = !postValid;

        anchors[cid].challenged = false;

        if (ch.slashed) {
            _slashSubsidy(cid);
        }

        emit ChallengeResolved(cid, ch.slashed);
    }

    // -------------------------------------------------------------------------
    // Admin
    // -------------------------------------------------------------------------

    function setApprovedSP(address sp, bool approved) external onlyAdmin {
        approvedSPs[sp] = approved;
    }

    function setTreasury(address _treasury) external onlyAdmin {
        treasury = _treasury;
    }

    // -------------------------------------------------------------------------
    // Internal Helpers (stubs — implement with FVM precompiles / verifier libs)
    // -------------------------------------------------------------------------

    function _verifyPoRep(bytes32 cid, bytes calldata proof)
        internal view returns (bool) { /* TODO: FVM precompile call */ }

    function _verifyWindowPoSt(bytes32 cid, bytes calldata proof)
        internal view returns (bool) { /* TODO: FVM precompile call */ }

    function _verifySiliconSig(address signer, bytes32 digest, bytes calldata sig)
        internal pure returns (bool) { /* TODO: ecrecover or EdDSA lib */ }

    function _tryGrantSubsidy(bytes32 cid, address operator) internal { /* TODO */ }

    function _slashSubsidy(bytes32 cid) internal { /* TODO */ }
}

interface IQuorumVerifier {
    function verify(bytes32 cid, bytes calldata aggregateSig) external view returns (bool);
}
```

### 4.2 Deployment Addresses (Placeholder)

| Network | Chain ID | Contract Address |
|---|---|---|
| Filecoin Calibration (testnet) | 314159 | TBD — Q3 2026 |
| Filecoin Mainnet | 314 | TBD — Q4 2026 |

### 4.3 Gas Considerations

PoRep proof verification on FVM involves calling the built-in `VerifyAPI` actor ([docs.filecoin.io/smart-contracts/developing-contracts/solidity-libraries](https://docs.filecoin.io/smart-contracts/developing-contracts/solidity-libraries/)). Gas costs for `anchorTrainingBundle` are estimated at ~500k gas units (*preliminary*). Inference batch anchoring (~80k gas units per batch, *preliminary*) uses only signature verification.

---

## 5. Retrieval Architecture

### 5.1 Retrieval Stack

```
                        ┌──────────────────────────────────────────────┐
                        │         Trinity Retrieval Stack               │
                        │                                               │
  Client request        │  1. IPFS Gateway (fast path, cached)         │
  (CID v1) ────────────>│     https://trinity-ipfs.depin.dev/ipfs/<CID>│
                        │     (placeholder URL)                         │
                        │            │                                  │
                        │            │ cache miss                       │
                        │            ▼                                  │
                        │  2. Saturn CDN (saturn.tech)                  │
                        │     Filecoin retrieval market CDN layer       │
                        │            │                                  │
                        │            │ not found / timeout              │
                        │            ▼                                  │
                        │  3. Lassie (github.com/filecoin-project/lassie)│
                        │     Direct Filecoin retrieval fallback        │
                        │     lassie fetch <CID> --output <file>        │
                        └──────────────────────────────────────────────┘
```

### 5.2 Trinity Node as Pinning Service

Each Trinity node runs an IPFS daemon configured as a pinning service for its own dies' receipts. The node maintains a local pin set of:

- All inference receipt batches from its dies for the last 90 days
- The most recent 5 training bundles (checkpoint history)
- The current release reproducibility package

Pinning is managed via the [IPFS Pinning Service API](https://ipfs.github.io/pinning-services-api-spec/) spec, enabling compatibility with third-party pinning services (Pinata, web3.storage) as backup.

### 5.3 IPFS Gateway

**Endpoint:** `https://trinity-ipfs.depin.dev/ipfs/<CIDv1>` *(placeholder — not yet live)*

The gateway is operated by the Trinity DAO multisig-controlled infrastructure and is rate-limited to prevent abuse. It supports:

- `/ipfs/<CID>` — standard path-based retrieval
- `/ipfs/<CID>/<path>` — DAG traversal for bundle sub-objects
- `Accept: application/vnd.ipld.car` header — raw CAR stream download

### 5.4 On-Die CID Verification

Trinity silicon dies contain a hardware SHA-256 accelerator. When a die receives an inference receipt bundle over the retrieval network, it can independently compute `sha256(blob)` and compare against the CID multihash to verify content integrity without trusting any intermediary gateway. This is the security-critical path: the die only executes models whose weight CID matches the on-chain `AnchorRecord.cid`.

```
Die receives: blob + claimed_cid
Die computes: sha256(blob) → local_hash
Die checks:   local_hash == multihash_digest(claimed_cid)
              ✓ proceed   |   ✗ reject + log tamper event
```

### 5.5 Lassie Retrieval Fallback

[Lassie](https://github.com/filecoin-project/lassie) is the reference Filecoin retrieval client. Trinity nodes use it as a last-resort fallback when both the IPFS gateway and Saturn CDN fail:

```bash
# Install
go install github.com/filecoin-project/lassie/cmd/lassie@latest

# Retrieve a training bundle by CID
lassie fetch \
  --output ./bundle.car \
  --protocols graphsync,bitswap \
  bafyrei<CIDv1base32>
```

Expected retrieval latency via Lassie: 5–60 seconds depending on SP and network conditions (*preliminary*).

---

## 6. Incentive Layer

### 6.1 Storage Cost Model

Trinity operators pay Filecoin Storage Providers in FIL for storage deals. The Trinity DePIN treasury subsidizes 50% of storage costs for valid training bundles in the first year of operation (i.e., storage deals posted after mainnet launch, expiring no later than 12 months post-launch). Subsidy is paid in $TRI tokens burned from the protocol fee pool, converted to FIL via a designated DEX bridge (*preliminary mechanism*).

### 6.2 Cost Projection (*Preliminary*)

| Parameter | Value |
|---|---|
| Nodes | 1,000 |
| Training bundle size | 50 MB |
| Bundles per node per day | 1 |
| Inference batch size | ~1 MB (1,000 receipts × 1 KB) |
| Daily storage delta per node | ~51 MB |
| Annual storage per node | ~18 GB |
| **Total annual storage (1,000 nodes)** | **~18 TB** |
| Filecoin price per TB/month (*preliminary, as of 2025*) | ~$0.30 |
| Total annual storage cost (1,000 nodes) | ~$65/year total (*preliminary*) |
| 50% treasury subsidy | ~$32.50/year/1,000 nodes (*preliminary*) |

*Note: Filecoin storage prices are market-determined and volatile. The $0.30/TB/month figure is illustrative based on 2025 SP pricing surveys. Actual costs will be re-evaluated at Q3 2026 testnet launch.*

**Expanded projection with reproducibility packages:**

| Object Class | Annual Volume (1,000 nodes) | Cost @ $0.30/TB/mo (*preliminary*) |
|---|---|---|
| Training bundles | 18 TB | ~$65/yr |
| Inference receipt batches | ~365 GB | ~$1.31/yr |
| Reproducibility packages (10 releases) | 5 TB | ~$18/yr |
| Public datasets (BPB suites) | ~2 TB | ~$7.20/yr |
| Zenodo mirror (DOI 10.5281/zenodo.19227877) | ~0.5 TB | ~$1.80/yr |
| **Total** | **~25.9 TB** | **~$93/yr** |

### 6.3 Subsidy Eligibility Criteria

A training bundle is eligible for the 50% storage subsidy if and only if:

1. The bundle's `mof_quorum_sig` is verified valid by `IQuorumVerifier.verify()`
2. The `lucas_post.trace` root hash in the manifest matches the value committed in the quorum signatures
3. The originating operator holds a non-zero $TRI stake in the Trinity node registry
4. The bundle is anchored within 48 hours of the training epoch timestamp in the manifest
5. No active slashing event exists on the operator's address

---

## 7. Anti-DoS / Spam

### 7.1 Training Bundle Spam

- Only training bundles with valid M-of-N quorum signatures qualify for storage subsidies. Bundles without valid quorum signatures are accepted for anchoring but operators pay full Filecoin costs.
- Rate limit: maximum 1 subsidized training bundle anchor per 24 hours per operator address (*preliminary*).
- Lucas-POST failures: if the `lucas_post.trace` root is invalid or absent, the bundle is marked `subsidized=false` and the operator's subsidy allocation for that epoch is slashed.

### 7.2 Inference Batch Spam

- Each inference batch anchor requires the submitting operator to hold a minimum $TRI stake (exact amount: TBD, see Open Questions).
- Batches from dies not registered in the Trinity node registry contract are rejected by `anchorInferenceBatch()`.
- Silicon signatures from revoked die keys (as tracked in the on-chain die registry) are rejected.

### 7.3 Challenge Spam

- `challengeStorage()` requires a small FIL deposit (*preliminary: 0.01 FIL*) that is returned if the challenge is upheld (SP fails to produce valid PoSt) or forfeited if the SP resolves successfully.
- Maximum 1 active challenge per CID at any time.

### 7.4 Storage Provider Filtering

- Trinity nodes SHOULD only submit deals to SPs on the `approvedSPs` allowlist maintained by the DAO admin in `TrinityStorageRegistry.sol`.
- Allowlist criteria: SP reputation score ≥ X (TBD), geographic diversity requirement (no more than 2 of 3 replicas in the same datacenter region), uptime SLA > 99% over trailing 30 days.

---

## 8. Backup Paths

### 8.1 SP Failure — Automatic Re-pin

If a Filecoin SP misses two consecutive `WindowPoSt` deadlines for a sector containing Trinity data (detectable via Filecoin chain state query on `MinerActorState.FaultSet`), the Trinity node's storage daemon automatically:

1. Detects the fault via periodic chain state poll (every 2,880 epochs = 24h)
2. Issues a new storage deal for the affected CID to a different approved SP from the allowlist
3. Submits a new `anchorTrainingBundle()` call referencing the replacement deal's PoRep proof

```
┌──────────────────────────────────────────────────────────┐
│                  SP Failure Recovery Flow                  │
│                                                           │
│  Detect:   FaultSet contains sector_id for CID           │
│            (poll interval: 2,880 epochs / 24h)           │
│                     │                                     │
│  Select:   Next SP from Trinity-preferred allowlist       │
│            (geographic diversity enforced)                │
│                     │                                     │
│  Re-deal:  make_deal(CID, backup_SP, same params)        │
│                     │                                     │
│  Re-anchor: anchorTrainingBundle(CID, quorum_sig,        │
│              new_porep_proof)                             │
│                     │                                     │
│  Alert:    Emit TrinityStorageAlert event on-chain       │
└──────────────────────────────────────────────────────────┘
```

### 8.2 Arweave Permanent Fallback

For **Zenodo-tier artifacts** (reproducibility packages, GDS tarballs, RTL source snapshots, formal release weights), a secondary upload to Arweave is made at release time. Arweave's permaweb provides a one-time-payment permanent storage guarantee with no ongoing proof requirements — acceptable for archival data where replication proof is less critical than permanent availability.

Arweave upload occurs via the [Bundlr Network](https://bundlr.network) (now Irys) for atomic, instant finality:

```bash
irys upload training_bundle_v42_release.tar \
  --network mainnet \
  --currency ethereum \
  --tags Content-Type:application/x-tar \
          Trinity-CID:<CIDv1> \
          Trinity-Anchor:0x47C0
```

The Arweave transaction ID is stored in the `AnchorRecord` as an extended field in a future contract upgrade.

### 8.3 Priority Hierarchy

```
Primary:    Filecoin (3 replicas, PoSt-verified, FVM-anchored)
Secondary:  IPFS pinning by Trinity nodes (fast retrieval, no persistence guarantee)
Tertiary:   Filecoin backup SPs from allowlist (automatic on fault detection)
Quaternary: Arweave (Zenodo-tier release artifacts only, one-time cost, permanent)
```

---

## 9. Privacy Considerations

### 9.1 Training Data and Weights

Training bundle blobs are **encrypted at rest on Filecoin**. Only the bundle CID (a content-addressed hash of the encrypted blob) and the quorum signatures over that hash appear on-chain. The encryption scheme:

- **Symmetric key**: AES-256-GCM per bundle, key derived from `HKDF(epoch_seed, operator_key)`
- **Key splitting**: Shamir Secret Sharing (3-of-5) across five DAO custodian addresses
- **Custodian key storage**: Each custodian holds their share in an HSM or hardware wallet; reconstruction requires 3 of 5 custodians to cooperate
- **Key rotation**: Annual key rotation for long-lived storage deals; re-encryption of stored blobs or new deal with re-encrypted content

| Data element | On-chain visibility | Filecoin visibility | Notes |
|---|---|---|---|
| Training weights (NF4/Posit16/GF) | Hash (CID) only | Encrypted blob | AES-256-GCM + Shamir 3-of-5 |
| R-SI-1 audit log | Hash only | Encrypted blob | Same key as weights |
| M-of-N quorum signatures | Full (calldata) | Encrypted blob | Signatures are public proofs |
| Lucas-POST trace root | Hash only | Encrypted blob | |
| Inference receipts | Full (calldata + CID) | Plaintext | Verifiability requires public access |
| Dataset hashes (BPB) | Hash only | Plaintext | Datasets are public |

### 9.2 Inference Receipts

Inference receipts are **intentionally public** — the core value proposition of Trinity's silicon-signed inference layer is that any party can verify a given model produced a given output on a specific die, without trusting the operator. All receipt batch blobs are stored unencrypted on Filecoin and pinned publicly on IPFS.

The `signer_die` field contains the die's public key address, which is a pseudonym. Trinity does not associate die addresses with operator PII on-chain; however, operators should be aware that inference traffic patterns may be analyzable from public receipt batches.

### 9.3 Regulatory Notes

Training bundles containing weights derived from private datasets MUST NOT be stored on Filecoin without encryption. If any training data subject to GDPR Art. 17 (right to erasure) is used, operators must retain the ability to re-encrypt or delete the encryption key (cryptographic deletion), effectively making the stored blob unrecoverable. The Shamir 3-of-5 key structure supports this: destroying all 5 shares (or reducing available shares below threshold) constitutes cryptographic deletion of the stored content.

---

## 10. Implementation Timeline

| Phase | Quarter | Milestone | Network |
|---|---|---|---|
| **Phase 0 — Design** | Q2 2026 | `TrinityStorageRegistry.sol` audit complete; CID schema finalized | — |
| **Phase 1 — Testnet** | Q3 2026 | Deploy `TrinityStorageRegistry` on Calibration network (chainId 314159); first training bundle anchored | Calibration |
| **Phase 1 cont.** | Q3 2026 | `trinity-ipfs.depin.dev` gateway live; Lassie integration tested; 10-node pilot | Calibration |
| **Phase 2 — Mainnet** | Q4 2026 | Deploy to Filecoin Mainnet (chainId 314); storage deals active; PoRep verification live | Mainnet FVM |
| **Phase 2 cont.** | Q4 2026 | $TRI subsidy mechanism live; challenge/slash mechanism live | Mainnet FVM |
| **Phase 3 — Retrieval Markets** | Q1 2027 | Saturn CDN integration; Lassie v2 retrieval market support; retrieval SLA monitoring | Mainnet FVM |
| **Phase 3 cont.** | Q1 2027 | Arweave backup pipeline for Zenodo-tier artifacts; DataCap application for Filecoin Plus | Mainnet FVM |
| **Phase 4 — Cross-chain** | Q2 2027 | Evaluate LayerZero bridge for anchoring on Ethereum L2 / other EVM chains (see Open Questions) | TBD |

### Key Dependencies

- Filecoin Calibration network stability for testnet (see [calibration.filecoin.io](https://calibration.filecoin.io))
- FVM FEVM/Solidity tooling: Hardhat + `hardhat-filecoin` plugin
- PoRep proof verification precompile availability on FVM (tracked in [github.com/filecoin-project/ref-fvm](https://github.com/filecoin-project/ref-fvm))
- Trinity quorum verifier contract (M-of-N BLS aggregation) — parallel development track
- Trinity $TRI tokenomics spec finalized (treasury subsidy mechanism)

---

## 11. References

| # | Source | URL |
|---|---|---|
| 1 | Filecoin Protocol Specification | https://spec.filecoin.io |
| 2 | Filecoin Virtual Machine (FVM) Docs | https://docs.filecoin.io/smart-contracts/fundamentals/the-fvm |
| 3 | FVM Solidity Libraries | https://docs.filecoin.io/smart-contracts/developing-contracts/solidity-libraries |
| 4 | Filecoin Proof-of-Spacetime spec | https://spec.filecoin.io/#algorithms__pos |
| 5 | Filecoin Expected Consensus (epoch timing) | https://spec.filecoin.io/#algorithms__expected_consensus |
| 6 | IPFS Specifications | https://specs.ipfs.tech |
| 7 | IPFS Content Addressing (CIDv1) | https://docs.ipfs.tech/concepts/content-addressing |
| 8 | IPFS Pinning Service API Spec | https://ipfs.github.io/pinning-services-api-spec |
| 9 | Lassie — Filecoin Retrieval Client | https://github.com/filecoin-project/lassie |
| 10 | Saturn Retrieval Network | https://saturn.tech |
| 11 | Filecoin Calibration Testnet | https://calibration.filecoin.io |
| 12 | ref-fvm (FVM reference implementation) | https://github.com/filecoin-project/ref-fvm |
| 13 | Trinity DePIN Gap Analysis | https://github.com/NeuronConstant (see repository) |
| 14 | Zenodo DOI 10.5281/zenodo.19227877 | https://doi.org/10.5281/zenodo.19227877 |
| 15 | Arweave / Irys (Bundlr) permanent storage | https://irys.xyz |
| 16 | LayerZero cross-chain messaging | https://layerzero.network |
| 17 | Filecoin Plus (DataCap program) | https://docs.filecoin.io/storage-providers/filecoin-plus |
| 18 | hardhat-filecoin plugin | https://github.com/filecoin-project/filecoin-solidity |

---

## 12. Open Questions

The following items require resolution before Phase 1 testnet deployment:

| # | Question | Current Default | Decision Needed By |
|---|---|---|---|
| OQ-1 | **Final replica count** for training bundles and inference batches | 3 (*preliminary*) | Q2 2026 (pre-testnet) |
| OQ-2 | **Retrieval SLA target** — what percentile latency for IPFS gateway? | 95th percentile < 1s for cached content (*preliminary*) | Q3 2026 |
| OQ-3 | **Cross-chain anchoring** — should `StorageAnchored` events be relayed to Ethereum mainnet / L2 via LayerZero? | No bridge in v1 | Q4 2026 |
| OQ-4 | **PoRep proof verification** on FVM — available as precompile, or must Trinity use an off-chain verifier + oracle? | Pending FVM roadmap | Q3 2026 |
| OQ-5 | **Minimum $TRI stake** for inference batch anchoring (anti-spam) | TBD | Q2 2026 |
| OQ-6 | **Challenge deposit** amount in FIL | 0.01 FIL (*preliminary*) | Q3 2026 |
| OQ-7 | **Key custodian selection** for Shamir 3-of-5 AES key splitting | DAO multisig members (TBD) | Q2 2026 |
| OQ-8 | **DataCap eligibility** — should Trinity apply for Filecoin Plus DataCap to reduce storage costs for public datasets? | Under evaluation | Q3 2026 |
| OQ-9 | **Arweave trigger policy** — at what point does an artifact get promoted to Arweave backup? (e.g., after N failed Filecoin SPs?) | Formal releases only | Q4 2026 |
| OQ-10 | **Zenodo DOI mirror cadence** — how frequently should `10.5281/zenodo.19227877` be re-mirrored to Filecoin? | Per-release | Q2 2026 |

---

*End of TRINITY-STOR-001 v0.1 DRAFT*

*All prices, replica counts, gas estimates, and SLA targets marked "preliminary" are subject to change based on testnet results and Filecoin market conditions. This document should be reviewed alongside the Trinity DePIN Gap Analysis at [github.com/NeuronConstant](https://github.com/NeuronConstant) and the Zenodo dataset at [doi.org/10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877).*
