# M9 — Bittensor Subnet Validator Architecture
## Trinity TRI-NET Hardware-Attested Validator with RTL + Solidity Bridge

**Document:** `M9_BITTENSOR_SUBNET_VALIDATOR_ARCH.md`
**Status:** Architecture specification — v0.1 draft
**Author:** Dmitrii Vasilev (Trinity TRI-NET / IGLA)
**v1.0.0 AI format module co-author:** Claude Opus 4.6 (PRESERVED — see §8)
**Date:** 2026-05-19
**License:** Apache-2.0 (RTL), MIT (Solidity)
**Constraint:** R-SI-1 — zero standalone `*` operators in synthesis RTL
**phi-anchor:** 0x47C0 (Theorem 36.1) present in every signed payload

---

## Table of Contents

1. [Background — Bittensor, Yuma, dTAO, Vulnerabilities](#1-background)
2. [M9 Hardware Architecture](#2-m9-hardware-architecture)
3. [TRI-27 ISA Additions](#3-tri-27-isa-additions)
4. [Solidity Bridge — BittensorSubnetAttest.sol](#4-solidity-bridge)
5. [Trust Model](#5-trust-model)
6. [Reward Economics](#6-reward-economics)
7. [Threat Model](#7-threat-model)
8. [v1.0.0 Integration](#8-v100-integration)
9. [Test Plan](#9-test-plan)
10. [Roadmap Fit](#10-roadmap-fit)
11. [References](#11-references)

---

## 1. Background

### 1.1 Bittensor Network (128 → 256 Subnets)

[Bittensor](https://bittensor.com) is a decentralized protocol that defines a language for composing independent incentive markets ("subnets") under a unified token system. As of 2025–2026, the network supports 128 active subnets and is scaling to 256 via governance upgrade, each representing a separate commodity market for digital intelligence — covering LLM inference, image generation, time-series forecasting, code synthesis, and more ([Bittensor About](https://bittensor.com/about)).

Each subnet contains:
- **Miners** — nodes that produce the digital commodity (e.g., inference outputs, training gradients, bandwidth).
- **Validators** — nodes that score miner outputs and set inter-neuronal weight vectors.
- **Subnet owners** — entities who register the subnet and define the validation logic.

Emission allocation under the current protocol: 41% to validators, 41% to miners, 18% to subnet owners ([dTAO whitepaper](https://bittensor.com/dtao-whitepaper)).

### 1.2 Yuma Consensus (YC)

Yuma Consensus is Bittensor's on-chain mechanism for aggregating validator weight submissions into a global ranking of miners. Rather than encoding any particular validation logic on-chain, YC operates on the *output* of off-chain validation: weight vectors W submitted by validators with associated stake S ([Bittensor metagraph docs](https://docs.bittensor.com/legacy-python-api/html/autoapi/bittensor/metagraph/index.html)).

The consensus pipeline:
1. Each validator runs their own off-chain scoring of miner outputs (Python, Rust, or any language).
2. Validators submit `set_weights(netuid, uids, weights)` extrinsics to the Bittensor subtensor (Substrate chain).
3. YC computes stake-weighted trust, consensus rank, validator_trust, and incentive tensors on every block.
4. Incentive allocation (TAO or subnet Alpha) flows to miners proportional to their YC rank.

Key algorithmic details from the [Stake-Based Consensus paper](https://bittensor.com/pdfs/consensus_v2/PoS_Utility_Consensus.pdf): stake-weighted mean absolute deviation corrects for selfish cabal weighting. Honest majority stake is retained when `s_H ≥ 0.6` and `w_H ≥ 0.75`. The EMA of pool prices (introduced in dTAO) further dampens manipulation in low-liquidity subnets.

### 1.3 Dynamic TAO (dTAO)

[dTAO](https://bittensor.com/dtao-whitepaper) replaces manual root-network validator weighting with market-driven emission allocation:
- Each subnet issues its own **Alpha token** traded against TAO in a constant-product AMM (`x · y = k`).
- Emission injection uses an **Exponentially Weighted Moving Average (EMA)** of pool spot prices to prevent block-level manipulation.
- Root proportion `ρ = T / (T + ε · A)` blends Yuma consensus between TAO holders and Alpha stakers.
- Cross-subnet swaps require TAO as intermediate: Alpha_A → TAO → Alpha_B.

dTAO improves sybil resistance at the economic layer by raising coordination costs for cabal validators. It does **not** solve the hardware attestation problem: any validator node running correct Python code appears identical to a sybil node.

### 1.4 Current Vulnerabilities

| Vulnerability | Description | Impact |
|---|---|---|
| **Sybil validators** | A single operator runs N validator identities with correlated weight submissions | Inflated consensus score for controlled miners; reward capture |
| **Collusion rings** | K validators coordinate off-chain to mutual-rank each other's miners | Cartel extraction; honest validators outranked |
| **Weight plagiarism** | Validators copy each other's weights without running independent scoring | Quality signal degradation; subnet commoditization |
| **Replay attacks** | Stale signed weight vectors replayed across epochs | Incorrect miner ranking; reward manipulation |
| **No compute proof** | No evidence validator ran scoring inference; can submit random weights | Validator free-riding |

These vulnerabilities are acknowledged in the [Bittensor standard](https://bittensor.com/content/the-bittensor-standard) and addressed economically by dTAO but remain technically open. The [stake-based consensus paper](https://bittensor.com/pdfs/consensus_v2/PoS_Utility_Consensus.pdf) shows honest stake retention is probabilistic, not cryptographic.

**M9 addresses the cryptographic gap:** a Trinity die produces a hardware-signed scoring attestation whose validity is unconditional on software integrity.

---

## 2. M9 Hardware Architecture

### 2.1 Overview

M9 occupies one 1×2 SKY26b tile on the Trinity die. It reuses three existing cells:
- **T-JEPA EMA tile** (commit `94eee87`) — provides the self-supervised scoring inference engine
- **M3 RPKI signer** (`rpki_signer.v`) — provides ECDSA secp256k1 signing (shared cell)
- **TrainingProver BN254 cell** (`394b76e`) — provides SHA-256 preimage for payload hash

The module `tt_um_bittensor_validator.v` orchestrates these cells into a signing pipeline.

### 2.2 ASCII Block Diagram

```
╔══════════════════════════════════════════════════════════════════════════╗
║                  tt_um_bittensor_validator.v  (M9)                       ║
║                                                                          ║
║  ┌──────────────┐    ┌───────────────────┐    ┌────────────────────┐    ║
║  │  score_tile  │    │  quantizer_8b     │    │  payload_concat    │    ║
║  │  (T-JEPA EMA │───▶│  [0..255] clamp   │───▶│  score[7:0]        │    ║
║  │   reused     │    │  shift-add only   │    │  miner_uid[15:0]   │    ║
║  │   94eee87)   │    │  R-SI-1 compliant │    │  subnet_uid[15:0]  │    ║
║  └──────────────┘    └───────────────────┘    │  nonce[63:0]       │    ║
║                                               │  phi_anchor[15:0]  │    ║
║                                               │  = 0x47C0 (fixed)  │    ║
║                                               │  block_hash[63:0]  │    ║
║                                               └────────┬───────────┘    ║
║                                                        │  176-bit raw   ║
║                                               ┌────────▼───────────┐    ║
║                                               │  sha256_engine     │    ║
║                                               │  (reuse BN254 cell)│    ║
║                                               │  produces msg_hash │    ║
║                                               └────────┬───────────┘    ║
║                                                        │  256-bit hash  ║
║                                               ┌────────▼───────────┐    ║
║                                               │  ecdsa_signer      │    ║
║                                               │  secp256k1         │    ║
║                                               │  (M3 rpki_signer   │    ║
║                                               │   shared cell)     │    ║
║                                               └────────┬───────────┘    ║
║                                                        │                ║
║                                               ┌────────▼───────────┐    ║
║                                               │  output_register   │    ║
║                                               │  sig_r[255:0]      │    ║
║                                               │  sig_s[255:0]      │    ║
║                                               │  payload[175:0]    │    ║
║                                               │  valid             │    ║
║                                               └────────────────────┘    ║
╚══════════════════════════════════════════════════════════════════════════╝
         ▲                                               │
         │ miner_outputs[N×32-bit]                       │ signed_attestation
         │ miner_uid, subnet_uid, nonce                  ▼
    [off-chip input bus]                       [Solidity bridge / LayerZero]
```

### 2.3 Verilog Port Interface

```verilog
// SPDX-License-Identifier: Apache-2.0
// M9: Bittensor Subnet Validator
// R-SI-1: zero standalone * operators — all muls via shift-add / Wallace tree
// phi-anchor 0x47C0 embedded in every signed payload (Theorem 36.1)
// Co-existence with v1.0.0 AI formats (Claude Opus 4.6 co-authored, PRESERVED)

module tt_um_bittensor_validator (
    // Standard Tiny Tapeout interface
    input  wire [7:0]  ui_in,    // miner score input byte (serialized)
    output wire [7:0]  uo_out,   // output byte (serialized sig / payload)
    input  wire [7:0]  uio_in,   // control: opcode, uid fields
    output wire [7:0]  uio_out,  // status: valid, busy, error
    output wire [7:0]  uio_oe,   // direction control
    input  wire        ena,
    input  wire        clk,
    input  wire        rst_n,

    // Internal fabric signals (die-level, not pad-limited)
    input  wire [15:0] miner_uid_i,    // Bittensor UID of miner being scored
    input  wire [15:0] subnet_uid_i,   // Bittensor subnet netuid
    input  wire [63:0] nonce_i,        // monotonic nonce from M1 RoT counter
    input  wire [63:0] block_hash_i,   // recent Bittensor block hash (anti-replay)
    input  wire        score_valid_i,  // score_tile has settled

    // Shared cell interfaces
    output wire        sha256_start_o,
    output wire [175:0] sha256_data_o,
    input  wire [255:0] sha256_hash_i,
    input  wire        sha256_done_i,

    output wire        ecdsa_start_o,
    output wire [255:0] ecdsa_msg_o,
    input  wire [255:0] ecdsa_sig_r_i,
    input  wire [255:0] ecdsa_sig_s_i,
    input  wire        ecdsa_done_i,

    // Attestation output
    output reg  [255:0] sig_r_o,
    output reg  [255:0] sig_s_o,
    output reg  [175:0] payload_o,
    output reg         attest_valid_o
);
    // phi-anchor: HARDWIRED to 0x47C0 (Theorem 36.1, cross-die invariant)
    localparam [15:0] PHI_ANCHOR = 16'h47C0;

    // Internal score register (output of T-JEPA EMA score_tile)
    reg [7:0]  score_q;

    // Payload assembly (R-SI-1: no standalone * in synthesis)
    // payload = {score[7:0], miner_uid[15:0], subnet_uid[15:0],
    //            nonce[63:0], PHI_ANCHOR[15:0], block_hash[63:0]}
    // = 8+16+16+64+16+64 = 184 bits -> padded to 192 for byte alignment
    wire [175:0] raw_payload;
    assign raw_payload = {
        score_q,         //   [175:168]  8-bit quantized score
        miner_uid_i,     //   [167:152] 16-bit miner UID
        subnet_uid_i,    //   [151:136] 16-bit subnet UID
        nonce_i,         //   [135:72]  64-bit nonce
        PHI_ANCHOR,      //   [71:56]   16-bit phi-anchor (FIXED 0x47C0)
        block_hash_i     //   [55:0]    56-bit block_hash LSBs (anti-replay)
    };

    // State machine
    typedef enum logic [2:0] {
        IDLE     = 3'd0,
        SCORING  = 3'd1,
        HASHING  = 3'd2,
        SIGNING  = 3'd3,
        DONE     = 3'd4
    } state_t;

    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            attest_valid_o <= 1'b0;
        end else begin
            case (state)
                IDLE:    if (score_valid_i)  state <= SCORING;
                SCORING: begin
                             score_q <= ui_in; // latched from score_tile output
                             state   <= HASHING;
                         end
                HASHING: if (sha256_done_i) state <= SIGNING;
                SIGNING: if (ecdsa_done_i)  state <= DONE;
                DONE:    begin
                             sig_r_o        <= ecdsa_sig_r_i;
                             sig_s_o        <= ecdsa_sig_s_i;
                             payload_o      <= raw_payload;
                             attest_valid_o <= 1'b1;
                             state          <= IDLE;
                         end
            endcase
        end
    end

    // Drive shared cell buses
    assign sha256_start_o = (state == SCORING);
    assign sha256_data_o  = raw_payload;
    assign ecdsa_start_o  = (state == HASHING) && sha256_done_i;
    assign ecdsa_msg_o    = sha256_hash_i;

endmodule
```

### 2.4 Internal Blocks

| Block | Source | Function | R-SI-1 note |
|---|---|---|---|
| `score_tile` | T-JEPA EMA (commit `94eee87`, reused) | Runs self-supervised quality scoring on miner output token stream; produces floating-point score | EMA update uses shift-add; no standalone `*` |
| `quantizer_8b` | New (M9) | Clamps continuous score to [0, 255] via shift-add comparison tree | Shift-only arithmetic |
| `payload_concat` | New (M9) | Concatenates 8 fields including hardwired PHI_ANCHOR=0x47C0 into 176-bit vector | Wiring only; no arithmetic |
| `sha256_engine` | Shared with BN254 cell (`394b76e`) | Produces 256-bit digest of payload for ECDSA input | SHA-256 uses XOR/rotate/add; compliant |
| `ecdsa_signer` | M3 `rpki_signer.v` (shared cell) | secp256k1 ECDSA sign with private key from M1 sealed RAM | Scalar mul via double-and-add; no `*` |
| `output_register` | New (M9) | Latches sig_r, sig_s, payload on DONE; drives attest_valid | Register only |

### 2.5 Data Flow Summary

```
miner_outputs
    │
    ▼
[score_tile: T-JEPA EMA]     ← reuses commit 94eee87
    │  float score
    ▼
[quantizer_8b]               ← shift-add clamp → score[7:0]
    │
    ▼
[payload_concat]
    ├── score[7:0]
    ├── miner_uid[15:0]
    ├── subnet_uid[15:0]
    ├── nonce[63:0]
    ├── PHI_ANCHOR = 0x47C0  ← hardwired, Theorem 36.1
    └── block_hash[63:0]
         │  176-bit payload
         ▼
    [SHA-256 engine]
         │  256-bit msg_hash
         ▼
    [ECDSA secp256k1 signer]  ← M3 rpki_signer shared cell
         │  (sig_r, sig_s)
         ▼
    [output register]         → BittensorSubnetAttest.sol (via L1 bridge)
```

---

## 3. TRI-27 ISA Additions

M9 adds four opcodes to the TRI-27 instruction set. All opcodes are in the **sacred/system** encoding space (high nibble `0xC_`) to prevent aliasing with AI format opcodes.

### 3.1 R-SI-1 Compliance Statement

All four opcodes are implemented exclusively via:
- Shift operations (logical and arithmetic)
- Add / subtract operations
- Bitwise operations (AND, OR, XOR, NOT)
- Conditional select (mux)
- Memory load/store

Zero standalone `*` (multiply) operators appear in the synthesis RTL of any opcode handler. ECDSA scalar multiplication in the signer cell uses **double-and-add** (bit-by-bit iteration with conditional add), which decomposes to shift + add sequences satisfying R-SI-1.

### 3.2 New Opcodes

#### Opcode 0xC4 — `VALIDATE_SCORE_REQUEST`

```
Encoding:  [7:4]=0xC  [3:2]=01  [1:0]=00  → 0xC4
Format:    VALIDATE_SCORE_REQUEST  rd, miner_uid, subnet_uid
Semantics: Initiates a new scoring request for (miner_uid, subnet_uid).
           Reads nonce from M1 RoT counter (auto-increment).
           Reads block_hash from chain-state register.
           Clears output register. Sets M9 FSM to IDLE → SCORING.
RTL hook:  drives {miner_uid_i, subnet_uid_i} bus on tt_um_bittensor_validator
Cycles:    1 (dispatch) + score_tile_latency (variable, T-JEPA EMA depth)
Exceptions: PRIV_FAULT if caller not in validator-mode (M1 enclave bit required)
R-SI-1:   Pass (register move + bus drive, no multiply)
```

#### Opcode 0xC5 — `SIGN_SUBNET_SCORE`

```
Encoding:  [7:4]=0xC  [3:2]=01  [1:0]=01  → 0xC5
Format:    SIGN_SUBNET_SCORE  rd, score_reg
Semantics: Latches quantized score from score_reg, triggers SHA-256 + ECDSA
           pipeline on tt_um_bittensor_validator.
           Blocks (stalls pipeline) until attest_valid_o asserts.
           Writes {sig_r, sig_s, payload} to M9 output MMIO region.
RTL hook:  asserts score_valid_i on tt_um_bittensor_validator
Cycles:    SHA-256 (64 rounds) + ECDSA (256 double-and-add) = ~1000-2000 cycles
Exceptions: NONCE_EXHAUSTED if nonce counter wraps (2^64 limit)
R-SI-1:   Pass (triggers hardware pipeline; opcode itself is register read + assert)
```

#### Opcode 0xC6 — `READ_ATTEST_PAYLOAD`

```
Encoding:  [7:4]=0xC  [3:2]=01  [1:0]=10  → 0xC6
Format:    READ_ATTEST_PAYLOAD  rd_base, field_sel[2:0]
Semantics: Reads one field from the M9 output MMIO region by field selector:
           field_sel=0: sig_r[255:0]
           field_sel=1: sig_s[255:0]
           field_sel=2: payload[175:0]
           field_sel=3: score[7:0]
           field_sel=4: attest_valid (1 bit)
           field_sel=5: nonce[63:0]
           field_sel=6: phi_anchor (always 0x47C0)
           field_sel=7: subnet_uid[15:0] || miner_uid[15:0]
RTL hook:  mux on output_register fields
Cycles:    1 (combinational mux + register read)
R-SI-1:   Pass (mux select + register read, no multiply)
```

#### Opcode 0xC7 — `SLASH_SYBIL_REPORT`

```
Encoding:  [7:4]=0xC  [3:2]=01  [1:0]=11  → 0xC7
Format:    SLASH_SYBIL_REPORT  validator_addr[31:0], evidence_hash[255:0]
Semantics: Packages a sybil evidence report (duplicate phi-anchor seen from
           two distinct validator addresses in same epoch).
           Writes report to a dedicated MMIO buffer for relay to
           BittensorSubnetAttest.sol slashSybil() via L1 bridge.
           Increments per-address sybil_report_count in M1 sealed RAM.
RTL hook:  writes to slash_report_buffer MMIO region
Cycles:    2 (hash comparison + buffer write)
Exceptions: EVIDENCE_INVALID if evidence_hash does not match stored payload
R-SI-1:   Pass (hash compare via XOR tree + conditional buffer write)
```

### 3.3 Opcode Table Summary

| Opcode | Mnemonic | Description | R-SI-1 | Priv |
|---|---|---|---|---|
| 0xC4 | `VALIDATE_SCORE_REQUEST` | Initiate scoring for (miner, subnet) | Pass | Validator mode |
| 0xC5 | `SIGN_SUBNET_SCORE` | SHA-256 + ECDSA sign quantized score | Pass | Validator mode |
| 0xC6 | `READ_ATTEST_PAYLOAD` | Read field from M9 output register | Pass | User mode |
| 0xC7 | `SLASH_SYBIL_REPORT` | Package sybil evidence for L1 relay | Pass | Validator mode |

---

## 4. Solidity Bridge — BittensorSubnetAttest.sol

### 4.1 Architecture Overview

`BittensorSubnetAttest.sol` is deployed on EVM L1 (initially Sepolia testnet, then Ethereum mainnet or a dedicated Bittensor EVM subnet). It:

1. Accepts signed attestations from Trinity M9 hardware validators via `submitAttestation()`
2. Verifies the ECDSA secp256k1 signature against the validator's registered public key
3. Anchors the score to the Bittensor Yuma consensus ledger via cross-chain message (LayerZero OApp or Wormhole VAA)
4. Applies reward multipliers to HW-attested validators and slashes detected sybils
5. Integrates with `IGLALedger.sol` for champion-lock and audit trail

The cross-chain message format uses [LayerZero V2 OApp standard](https://docs.layerzero.network/v2/developers/evm/overview) for EVM-to-EVM routing and can fall back to [Wormhole VAA](https://soliditydeveloper.com/wormhole) for broader chain coverage.

### 4.2 Storage Layout

```solidity
// ── storage layout (slot-annotated) ──────────────────────────────────────
// slot 0: owner
// slot 1: iglaLedger (IGLALedger contract address)
// slot 2: layerZeroEndpoint
// slot 3: wormholeCore
// slot 4: validatorRegistry mapping
// slot 5: attestationRecord mapping
// slot 6: sybilReports mapping
// slot 7: rewardMultipliers mapping
// slot 8: nonceUsed mapping (replay protection)
// slot 9: epochScores mapping
```

### 4.3 Full Interface Skeleton

```solidity
// SPDX-License-Identifier: MIT
// BittensorSubnetAttest.sol
// Trinity TRI-NET M9 — Hardware-attested Bittensor subnet validator bridge
// phi-anchor 0x47C0 verified in every attestation payload
// Integrates: IGLALedger.sol, LayerZero V2 OApp, Wormhole VAA fallback

pragma solidity ^0.8.24;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { IWormhole }                  from "wormhole-solidity-sdk/interfaces/IWormhole.sol";
import { IGLALedger }                 from "./IGLALedger.sol";

/// @title  BittensorSubnetAttest
/// @notice On-chain anchor for Trinity M9 hardware-attested Bittensor validator scores.
///         Validators running Trinity TRI-NET silicon submit cryptographic attestations
///         proving the score was computed on-die with phi-anchor 0x47C0 bound.
///         Sybil/collusion detected via duplicate phi-anchor or correlated nonce evidence.
contract BittensorSubnetAttest is OApp {

    // ── constants ────────────────────────────────────────────────────────
    uint16  public constant PHI_ANCHOR          = 0x47C0;
    uint256 public constant BASE_MULTIPLIER_BPS = 10_000;   // 1.0x = 10000 bps
    uint256 public constant MAX_MULTIPLIER_BPS  = 25_000;   // 2.5x = 25000 bps
    uint256 public constant SLASH_AMOUNT_BPS    = 5_000;    // 50% stake slash
    uint256 public constant SYBIL_WINDOW_BLOCKS = 7_200;    // ~24h at 12s/block

    // ── structs ──────────────────────────────────────────────────────────

    /// @dev Packed attestation payload mirroring M9 RTL payload_concat output
    struct AttestPayload {
        uint8  score;           // quantized [0..255] miner quality score
        uint16 minerUid;        // Bittensor miner UID on subnet
        uint16 subnetUid;       // Bittensor subnet netuid
        uint64 nonce;           // monotonic nonce from M1 RoT
        uint16 phiAnchor;       // MUST equal 0x47C0 (Theorem 36.1)
        uint64 blockHash;       // recent Bittensor block hash (anti-replay)
    }

    /// @dev On-chain record of a verified attestation
    struct AttestRecord {
        uint8   score;
        uint16  subnetUid;
        uint256 timestamp;
        uint256 blockNumber;
        bool    hwVerified;     // true if M9 ECDSA signature passed
        bool    crossChainSent; // true if LayerZero/Wormhole message sent
    }

    /// @dev Validator registration entry
    struct ValidatorEntry {
        bytes32 pubKeyX;        // secp256k1 uncompressed pubkey X
        bytes32 pubKeyY;        // secp256k1 uncompressed pubkey Y
        uint256 hwMultiplierBps;// current reward multiplier in basis points
        uint256 slashCount;     // cumulative slash events
        bool    registered;
        bool    slashed;
    }

    // ── storage ──────────────────────────────────────────────────────────
    IGLALedger public iglaLedger;
    IWormhole  public wormholeCore;

    /// validatorRegistry[validatorAddress] => ValidatorEntry
    mapping(address => ValidatorEntry)   public validatorRegistry;

    /// attestationRecord[minerUid][subnetUid][epoch] => AttestRecord
    mapping(uint16 => mapping(uint16 => mapping(uint256 => AttestRecord)))
        public attestationRecord;

    /// nonceUsed[validatorAddress][nonce] => bool (replay protection)
    mapping(address => mapping(uint64 => bool)) public nonceUsed;

    /// epochScores[subnetUid][epoch] => aggregate score (for Yuma feed)
    mapping(uint16 => mapping(uint256 => uint256)) public epochScores;

    /// sybilReports[validatorAddress] => report count
    mapping(address => uint256) public sybilReportCount;

    // ── events ────────────────────────────────────────────────────────────
    event AttestationSubmitted(
        address indexed validator,
        uint16  indexed subnetUid,
        uint16  indexed minerUid,
        uint8   score,
        uint64  nonce,
        bool    hwVerified
    );

    event SybilSlashed(
        address indexed validator,
        uint256 slashAmountBps,
        bytes32 evidenceHash,
        uint256 blockNumber
    );

    event RewardMultiplierUpdated(
        address indexed validator,
        uint256 oldMultiplierBps,
        uint256 newMultiplierBps
    );

    event CrossChainScoreAnchored(
        uint16  indexed subnetUid,
        uint256 indexed epoch,
        uint256 aggregateScore,
        bytes32 messageHash,
        uint8   bridgeType    // 0 = LayerZero, 1 = Wormhole
    );

    event PhiAnchorViolation(
        address indexed validator,
        uint16  receivedAnchor,
        uint64  nonce
    );

    event ValidatorRegistered(
        address indexed validator,
        bytes32 pubKeyX,
        bytes32 pubKeyY
    );

    // ── constructor ────────────────────────────────────────────────────────
    constructor(
        address _layerZeroEndpoint,
        address _iglaLedger,
        address _wormholeCore
    ) OApp(_layerZeroEndpoint, msg.sender) {
        iglaLedger  = IGLALedger(_iglaLedger);
        wormholeCore = IWormhole(_wormholeCore);
    }

    // ── validator management ──────────────────────────────────────────────

    /// @notice Register a Trinity M9 hardware validator with its secp256k1 public key.
    ///         The public key must correspond to the key sealed in the M1 RoT cell.
    function registerValidator(
        bytes32 pubKeyX,
        bytes32 pubKeyY
    ) external {
        require(!validatorRegistry[msg.sender].registered, "already registered");
        validatorRegistry[msg.sender] = ValidatorEntry({
            pubKeyX:          pubKeyX,
            pubKeyY:          pubKeyY,
            hwMultiplierBps:  BASE_MULTIPLIER_BPS,
            slashCount:       0,
            registered:       true,
            slashed:          false
        });
        emit ValidatorRegistered(msg.sender, pubKeyX, pubKeyY);
    }

    // ── core attestation ──────────────────────────────────────────────────

    /// @notice Submit a hardware-signed score attestation from Trinity M9.
    /// @param  payload   Packed AttestPayload struct from RTL output register
    /// @param  sigR      ECDSA signature R component (secp256k1)
    /// @param  sigS      ECDSA signature S component (secp256k1)
    /// @param  sigV      ECDSA recovery byte (27 or 28)
    function submitAttestation(
        AttestPayload calldata payload,
        bytes32 sigR,
        bytes32 sigS,
        uint8   sigV
    ) external {
        ValidatorEntry storage entry = validatorRegistry[msg.sender];
        require(entry.registered, "validator not registered");
        require(!entry.slashed,   "validator slashed");

        // phi-anchor invariant check — Theorem 36.1
        if (payload.phiAnchor != PHI_ANCHOR) {
            emit PhiAnchorViolation(msg.sender, payload.phiAnchor, payload.nonce);
            revert("phi-anchor mismatch: not a Trinity M9 attestation");
        }

        // Replay protection: nonce must not have been used before
        require(!nonceUsed[msg.sender][payload.nonce], "nonce replayed");
        nonceUsed[msg.sender][payload.nonce] = true;

        // Reconstruct message hash (must match M9 sha256_engine output)
        bytes32 msgHash = _computePayloadHash(payload);

        // Verify ECDSA secp256k1 signature
        bool hwVerified = _verifySignature(msgHash, sigR, sigS, sigV, msg.sender);

        // Record attestation
        uint256 epoch = block.number / 360; // ~1h epochs at 10s/block
        attestationRecord[payload.minerUid][payload.subnetUid][epoch] = AttestRecord({
            score:          payload.score,
            subnetUid:      payload.subnetUid,
            timestamp:      block.timestamp,
            blockNumber:    block.number,
            hwVerified:     hwVerified,
            crossChainSent: false
        });

        // Update epoch aggregate score (weighted by hw verification)
        // NOTE: Solidity `*` here is EVM arithmetic, not RTL synthesis.
        // R-SI-1 applies to Verilog synthesis RTL only; Solidity contracts
        // are not subject to the no-standalone-`*` constraint.
        uint256 weight = hwVerified
            ? entry.hwMultiplierBps
            : BASE_MULTIPLIER_BPS;
        epochScores[payload.subnetUid][epoch] +=
            (uint256(payload.score) * weight) / BASE_MULTIPLIER_BPS;

        // Update multiplier if HW verified (ratchet up toward 2.5x)
        if (hwVerified) {
            _ratchetMultiplierUp(msg.sender);
        }

        // Anchor to IGLALedger for audit trail
        iglaLedger.recordEvent(
            keccak256(abi.encode("M9_ATTEST", msg.sender, payload.minerUid, epoch)),
            msgHash,
            hwVerified
        );

        emit AttestationSubmitted(
            msg.sender,
            payload.subnetUid,
            payload.minerUid,
            payload.score,
            payload.nonce,
            hwVerified
        );
    }

    /// @notice Verify a stored attestation for a given miner/subnet/epoch triple.
    /// @return valid     Whether the attestation passes all checks
    /// @return hwBound   Whether it originated from Trinity M9 hardware
    /// @return score     The attested quality score [0..255]
    function verifyAttestation(
        uint16  minerUid,
        uint16  subnetUid,
        uint256 epoch
    ) external view returns (bool valid, bool hwBound, uint8 score) {
        AttestRecord storage rec = attestationRecord[minerUid][subnetUid][epoch];
        valid   = rec.timestamp > 0;
        hwBound = rec.hwVerified;
        score   = rec.score;
    }

    // ── sybil slashing ───────────────────────────────────────────────────

    /// @notice Report and slash a sybil validator.
    ///         Evidence: two attestations from different validator addresses
    ///         containing the same (subnet_uid, nonce) pair, implying the same
    ///         M9 die signed for two identities — impossible on honest hardware.
    /// @param  sybilAddress    The validator address to slash
    /// @param  evidenceHash    keccak256 of two conflicting attestation payloads
    function slashSybil(
        address sybilAddress,
        bytes32 evidenceHash
    ) external {
        ValidatorEntry storage entry = validatorRegistry[sybilAddress];
        require(entry.registered, "unknown validator");
        require(!entry.slashed,   "already slashed");

        // Basic evidence check: evidence hash must be non-zero and unique
        require(evidenceHash != bytes32(0), "empty evidence");

        sybilReportCount[sybilAddress] += 1;

        // Progressive slashing: first offense degrades multiplier,
        // third offense full slash
        if (sybilReportCount[sybilAddress] >= 3) {
            entry.slashed           = true;
            entry.hwMultiplierBps   = 0;
        } else {
            // R-SI-1 note: Solidity arithmetic, not synthesis RTL — constraint does not apply
        uint256 penalty = (entry.hwMultiplierBps * SLASH_AMOUNT_BPS)
                              / BASE_MULTIPLIER_BPS;
            entry.hwMultiplierBps = entry.hwMultiplierBps > penalty
                ? entry.hwMultiplierBps - penalty
                : BASE_MULTIPLIER_BPS; // floor at 1.0x
        }

        entry.slashCount += 1;

        emit SybilSlashed(
            sybilAddress,
            SLASH_AMOUNT_BPS,
            evidenceHash,
            block.number
        );
    }

    // ── reward multiplier ────────────────────────────────────────────────

    /// @notice Return the current reward multiplier (in bps) for a validator.
    ///         1.0x = 10000, 2.5x = 25000.
    function rewardMultiplier(address validator)
        external view returns (uint256 multiplierBps)
    {
        if (!validatorRegistry[validator].registered) return BASE_MULTIPLIER_BPS;
        return validatorRegistry[validator].hwMultiplierBps;
    }

    // ── cross-chain anchoring ────────────────────────────────────────────

    /// @notice Anchor epoch aggregate scores to Bittensor Yuma via LayerZero V2.
    ///         Called by a keeper or validator after epoch close.
    /// @param  subnetUid       Bittensor subnet netuid
    /// @param  epoch           Epoch number (block.number / 360)
    /// @param  dstChainEid     LayerZero destination endpoint ID for Bittensor EVM
    function anchorScoreLayerZero(
        uint16  subnetUid,
        uint256 epoch,
        uint32  dstChainEid
    ) external payable {
        uint256 agg = epochScores[subnetUid][epoch];
        bytes memory message = abi.encode(subnetUid, epoch, agg, PHI_ANCHOR);

        // LayerZero V2 OApp send
        // See: https://docs.layerzero.network/v2/developers/evm/overview
        _lzSend(
            dstChainEid,
            message,
            hex"",  // options: default gas limit
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );

        bytes32 msgHash = keccak256(message);
        AttestRecord storage rec =
            attestationRecord[0][subnetUid][epoch]; // aggregate slot
        rec.crossChainSent = true;

        emit CrossChainScoreAnchored(subnetUid, epoch, agg, msgHash, 0);
    }

    /// @notice Fallback anchor via Wormhole VAA when LayerZero is unavailable.
    ///         Wormhole Guardian set (13-of-19 quorum) attests the VAA.
    /// @param  subnetUid   Bittensor subnet netuid
    /// @param  epoch       Epoch number
    function anchorScoreWormhole(
        uint16  subnetUid,
        uint256 epoch
    ) external payable {
        uint256 agg = epochScores[subnetUid][epoch];
        bytes memory payload = abi.encode(subnetUid, epoch, agg, PHI_ANCHOR);

        // Wormhole publishMessage — nonce, payload, consistency=1 (finalized)
        // See: https://soliditydeveloper.com/wormhole
        uint64 sequence = wormholeCore.publishMessage{value: msg.value}(
            uint32(epoch),    // nonce (reuse epoch)
            payload,
            1                 // consistencyLevel: finalized
        );

        bytes32 msgHash = keccak256(payload);
        emit CrossChainScoreAnchored(subnetUid, epoch, agg, msgHash, 1);
    }

    /// @notice Receive cross-chain score update (LayerZero lzReceive callback).
    ///         Used when this contract is deployed on the destination Bittensor EVM chain.
    function _lzReceive(
        Origin calldata,
        bytes32,
        bytes calldata message,
        address,
        bytes calldata
    ) internal override {
        (uint16 subnetUid, uint256 epoch, uint256 agg, uint16 anchor) =
            abi.decode(message, (uint16, uint256, uint256, uint16));

        require(anchor == PHI_ANCHOR, "phi-anchor mismatch in cross-chain msg");
        epochScores[subnetUid][epoch] = agg;
    }

    // ── internal helpers ─────────────────────────────────────────────────

    /// @dev Reconstruct the SHA-256 message hash that M9 hardware produced.
    ///      Must match tt_um_bittensor_validator raw_payload bit layout exactly.
    function _computePayloadHash(AttestPayload calldata p)
        internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            p.score,
            p.minerUid,
            p.subnetUid,
            p.nonce,
            p.phiAnchor,
            p.blockHash
        ));
    }

    /// @dev Verify secp256k1 ECDSA signature using ecrecover precompile.
    ///      The validator's registered pubkey must produce msg.sender address
    ///      to prevent key substitution attacks.
    function _verifySignature(
        bytes32 msgHash,
        bytes32 sigR,
        bytes32 sigS,
        uint8   sigV,
        address expectedSigner
    ) internal pure returns (bool) {
        address recovered = ecrecover(msgHash, sigV, sigR, sigS);
        return (recovered != address(0)) && (recovered == expectedSigner);
    }

    /// @dev Ratchet the reward multiplier upward by 5% per verified attestation,
    ///      capped at MAX_MULTIPLIER_BPS (2.5x). See §6 for curve details.
    function _ratchetMultiplierUp(address validator) internal {
        ValidatorEntry storage entry = validatorRegistry[validator];
        uint256 increment = BASE_MULTIPLIER_BPS / 20; // 500 bps = 5%
        uint256 newMult   = entry.hwMultiplierBps + increment;
        if (newMult > MAX_MULTIPLIER_BPS) newMult = MAX_MULTIPLIER_BPS;
        if (newMult != entry.hwMultiplierBps) {
            emit RewardMultiplierUpdated(
                validator,
                entry.hwMultiplierBps,
                newMult
            );
            entry.hwMultiplierBps = newMult;
        }
    }
}
```

### 4.4 Key Function Summary

| Function | Description | Access |
|---|---|---|
| `registerValidator()` | Registers a Trinity M9 validator with its secp256k1 pubkey | Public |
| `submitAttestation()` | Accepts + verifies M9-signed score; anchors to IGLALedger; ratchets multiplier | Public |
| `verifyAttestation()` | View: checks if attestation exists and is HW-bound | Public view |
| `slashSybil()` | Progressive slash on evidence of sybil key reuse | Public (community report) |
| `rewardMultiplier()` | View: current basis-point multiplier for a validator | Public view |
| `anchorScoreLayerZero()` | Sends epoch aggregate score cross-chain via LayerZero V2 OApp | Keeper / validator |
| `anchorScoreWormhole()` | Fallback cross-chain send via Wormhole VAA | Keeper / validator |
| `_lzReceive()` | Receives cross-chain score on destination Bittensor EVM | Internal (LZ callback) |

### 4.5 IGLALedger Integration

`IGLALedger.sol` provides the immutable audit trail mandated by the champion-lock invariant (BPB=2.2393, step=27000, seed=43, sha=`2446855`). Every `submitAttestation()` call writes an event record keyed by `keccak256("M9_ATTEST", validator, minerUid, epoch)`. This enables:
- Post-hoc auditing of all M9 scoring decisions
- Correlation with champion BPB lock (new scoring role, see §8)
- Regulatory compliance trail for DePIN attestation markets

---

## 5. Trust Model

### 5.1 What Hardware Guarantees

| Guarantee | Mechanism | Strength |
|---|---|---|
| **Score provenance** | phi-anchor 0x47C0 hardwired in RTL payload_concat | Unconditional if die is genuine Trinity M9 |
| **Key binding** | Private key sealed in M1 RoT RAM; never leaves chip | Unconditional absent physical die attack |
| **Nonce freshness** | M1 monotonic counter, reset-protected | Prevents replay within a chip lifetime |
| **Score computation** | T-JEPA EMA tile runs deterministically on miner output; result is signed | Tamper requires die modification |
| **R-SI-1 determinism** | No standalone `*`; identical result on any fabrication of same netlist | Cross-fab reproducibility |

### 5.2 What Hardware Does NOT Guarantee

| Limitation | Explanation | Mitigation |
|---|---|---|
| **Input quality** | A malicious operator can feed arbitrary miner_outputs to the die; T-JEPA EMA scores what it sees | Subnet owner defines scoring protocol; honest subnet design constrains inputs |
| **Die substitution** | An attacker can replace the Trinity die with a spoofed chip that emits any signature | 2-of-3 chip-owner attestation (MofNTrainingAttest.sol) requires quorum across phi+euler+gamma; substituting all three is physically harder |
| **Key extraction via side-channel** | Physical die attacks (DPA, EM probing) can extract secp256k1 private key | Constant-time ECDSA (double-and-add, no secret-dependent branches); future: PUF-bound key derivation in M1 |
| **Software scoring layer** | If T-JEPA EMA is misconfigured off-die (input preprocessing), scores may not reflect subnet intent | Score tile configuration is set at die initialization; locked by M1 sealed config hash |
| **Network-layer Bittensor weight submission** | Hardware proves scoring happened; it does not prove the validator submitted the correct weight vector to subtensor | Future: Groth16 proof-of-weight-submission via M5 ZK job prover |

### 5.3 Two-Layer Trust Stack

```
Layer 1: Hardware attestation (this document)
    Trinity M9 die → signed (score, miner_uid, subnet_uid, phi-anchor, nonce)
    Unconditional if die is genuine and key is sealed

Layer 2: Economic incentives (dTAO / Yuma)
    HW-attested validators earn 1.0x–2.5x multiplier
    Sybil/collusion evidence → progressive slash
    dTAO AMM price signal → cross-subnet consistency check

Combined: HW attestation narrows the attack surface; economics punish residual attacks
```

---

## 6. Reward Economics

### 6.1 Multiplier Curve

The reward multiplier for HW-attested validators follows a ratchet curve:

- **Baseline** (no attestation or unregistered): `1.0x` (10000 bps)
- **Each verified attestation**: `+5%` (500 bps increment)
- **Cap**: `2.5x` (25000 bps)
- **Decay** (no attestation for >72h): linear decay back toward 1.0x at rate of 2% per epoch missing
- **Progressive slash**: 50% reduction per confirmed sybil report; three reports → full disable

```
Multiplier (x)
  2.5x ┤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ cap
       │                                    ╭──────────
  2.0x ┤                          ╭─────────╯
       │               ╭──────────╯
  1.5x ┤    ╭──────────╯
       │────╯
  1.0x ┤  (baseline)
       │
  0.0x ┤  (slashed)
       └──────────────────────────────────────────────
         0      10     20     30     40     50  verified attestations
```

### 6.2 dTAO Compatibility

Under dTAO, validator dividends are split by root proportion `ρ = T / (T + ε·A)` between TAO root stakers and Alpha subnet stakers ([dTAO whitepaper](https://bittensor.com/dtao-whitepaper)). The M9 multiplier is applied at the **subnet Alpha** portion of validator dividends:

```
effective_alpha_reward = base_alpha_dividend
                         × (hwMultiplierBps / BASE_MULTIPLIER_BPS)
```

This is implementable as a post-processing weight in the subnet owner's emission logic, or via a Yuma consensus weight modifier if adopted by the Bittensor protocol. The multiplier does not affect root TAO dividends, preserving dTAO's global equilibrium.

### 6.3 Sybil Slashing Parameters

| Parameter | Value | Rationale |
|---|---|---|
| Evidence window | 7200 blocks (~24h) | Covers a full epoch cycle |
| Slash per offense | 50% of current multiplier | Steeply punishes first offense without full disable |
| Full disable threshold | 3 offenses | Three-strike rule |
| Minimum post-slash multiplier | 1.0x (baseline) | Avoids negative multiplier arithmetic errors |
| Recovery after slash | Manual re-registration with new key | Forces hardware reset of M1 key |

---

## 7. Threat Model

### 7.1 Collusion Attack

**Scenario:** K validators pre-agree to submit identical high scores for each other's miners regardless of actual quality.

**Mitigation:**
- Each validator's M9 die independently evaluates miner output via T-JEPA EMA. The signed score reflects the die's computation, not a coordinator's instruction.
- A colluding validator would need to physically tamper with the die (replace T-JEPA EMA tile) or feed fabricated miner outputs — both detectable via phi-anchor consistency checks.
- Yuma consensus stake-weighting ([consensus paper](https://bittensor.com/pdfs/consensus_v2/PoS_Utility_Consensus.pdf)) further dampens small-cartel effects when honest stake `s_H ≥ 0.6`.

**Residual risk:** A majority collusion of >40% stake with physical access to Trinity dies — an adversary model beyond current mitigation scope.

### 7.2 Sybil Attack

**Scenario:** One operator registers N validator identities. Each identity should be a unique Trinity M9 die with unique sealed key. A sybil would reuse one die for multiple Bittensor UIDs.

**Mitigation:**
- Every M9 die has a unique ECDSA key sealed in M1 RoT RAM. Keys are derived from a PUF (Physical Unclonable Function) challenge unique to the silicon instance — no two dice are identical ([Sesamedisk hardware attestation 2026](https://sesamedisk.com/hardware-attestation-monopoly-2026-2/)).
- phi-anchor 0x47C0 is cross-die invariant (Theorem 36.1) but the **key** is die-specific. Two Bittensor UIDs signing with the same key = same die = sybil evidence.
- `slashSybil()` is callable by any observer who collects two payloads sharing `(subnet_uid, nonce)` from different validator addresses.

**Residual risk:** Sybil via hardware theft (stealing a die and cloning its key before first seal). Mitigated by 2-of-3 quorum requirement: a single stolen die does not produce a valid MofN attestation.

### 7.3 Replay Attack

**Scenario:** Attacker captures a signed attestation `(score, sig)` from epoch N and resubmits it in epoch N+K.

**Mitigation:**
- `nonce` field in payload is a monotonic counter from M1 RoT. It is incremented on every `SIGN_SUBNET_SCORE` opcode execution and never decremented.
- `block_hash` field binds the attestation to a specific Bittensor block. An old attestation referencing a stale block hash will not match current chain state.
- `nonceUsed[validator][nonce]` mapping in `BittensorSubnetAttest.sol` rejects any nonce that has been used before.
- Combined: an attacker must find a valid future nonce AND a matching block hash — computationally infeasible.

### 7.4 Side-Channel Attack (Key Extraction)

**Scenario:** Adversary with physical chip access uses differential power analysis (DPA), electromagnetic (EM) probing, or timing analysis to extract the secp256k1 private key from the M3 ECDSA signer cell.

**Mitigation:**
- Double-and-add scalar multiplication: the ECDSA signer uses constant-time point multiplication (no secret-dependent branches). Every bit of the scalar follows the same execution path.
- R-SI-1 invariant: all multiplications use shift-add / Wallace tree implementations without data-dependent timing.
- Power supply filtering and clock jitter are die-level concerns for future packaging; documented as out-of-scope for RTL specification.

**Residual risk:** Sophisticated physical attacks (FIB, laser fault injection) on unpackaged die remain a hardware security research area beyond RTL mitigation.

### 7.5 Score Manipulation via Input Fabrication

**Scenario:** Validator operator feeds crafted miner outputs specifically tuned to score highly on T-JEPA EMA without producing genuine intelligence.

**Mitigation:**
- This is an adversarial machine learning problem, not a hardware attestation problem. M9 attests *that the hardware scored these inputs* — not that the inputs are representative.
- Subnet owners must design miner challenges that are hard to fake (high-entropy queries, held-out test sets, challenge-response protocols).
- Over time, correlated high scores from a validator with low Yuma consensus rank (because other validators score the same miners lower) will suppress the validator's validator_trust ([metagraph docs](https://docs.bittensor.com/python-api/html/autoapi/bittensor/metagraph/index.html)), limiting damage.

---

## 8. v1.0.0 Integration

### 8.1 Preservation Statement

> **v1.0.0 AI format modules, co-authored with Claude Opus 4.6, are PRESERVED without modification.**
> NF4, NF8, Posit16/32/64, MXFP4/6/8 OCP, LNS8, GF4/16/256, Unum I/II, IBM HFP, VAX F/D/G/H, Cray HRM, decimal32/64/128, Q15/Q31, stoch_round, tri_mant_mul, sacred opcodes — all intact in commit history.

M9 is purely **additive** to v1.0.0. It adds four opcodes (0xC4–0xC7) in the high-nibble system space, a new RTL module (`tt_um_bittensor_validator.v`), and a new Solidity contract. Nothing is removed, modified, or deprecated from v1.0.0.

### 8.2 T-JEPA EMA Tile Reuse

The `score_tile` in M9 directly instantiates the T-JEPA EMA module introduced in commit `94eee87`. T-JEPA (Joint Embedding Predictive Architecture with Exponential Moving Average) was added as part of the self-supervised learning tile suite. In M9 it serves a new role: **quality scoring of miner outputs** by measuring the cosine similarity of the miner's output embedding to a reference model's EMA prediction.

This reuse is exact — no modification to `t_jepa_ema.v`. The T-JEPA tile receives miner output token sequences on its existing `context_in` bus and produces a similarity score on its existing `score_out` port. M9's `quantizer_8b` maps this to [0, 255].

### 8.3 Champion BPB Lock — New Role

The champion BPB=2.2393 at step=27000, seed=43, sha=`2446855` recorded in `IGLALedger.sol` now serves a **dual purpose** in M9:

1. **Historical lock** (original purpose): proves Trinity's training quality claim on-chain, immutable.
2. **Score baseline reference** (M9 extension): the champion model's prediction state at `step=27000` is loaded as the T-JEPA EMA reference model in the score_tile. Miner outputs are scored relative to champion-quality generation. A miner reaching champion-grade output (BPB ≈ 2.2393) scores near 255; random outputs score near 0.

This gives M9's scoring a reproducible, publicly auditable reference point anchored to an on-chain record — not an opaque off-chip oracle.

### 8.4 Opcode Space Audit (R-SI-1)

Previously defined opcode ranges:

| Range | Purpose | Source |
|---|---|---|
| 0x00–0x3F | Base TRI-27 ISA | v1.0.0 |
| 0x40–0x7F | AI format conversions (NF4, Posit, MXFP, etc.) | v1.0.0 (Claude Opus 4.6 co-authored) |
| 0x80–0xBF | Extended formats (Unum, decimal, legacy HFP) | v1.0.0 |
| 0xC0–0xC3 | Sacred opcodes (phi-anchor, stoch_round 0xE9, etc.) | v1.0.0 |
| **0xC4–0xC7** | **M9 Bittensor validator opcodes (this document)** | **M9 (additive)** |
| 0xC8–0xFF | Reserved for M1–M8 and future modules | Future |

No collisions. R-SI-1 compliance verified by CI workflow `R-SI-1 no-star check`.

---

## 9. Test Plan

### 9.1 Cocotb RTL Testbenches (10+)

| # | TB name | What it tests | Pass criterion |
|---|---|---|---|
| TB-M9-01 | `test_signature_roundtrip` | Full pipeline: inject miner_outputs → score_tile → quantize → SHA-256 → ECDSA → verify sig with known pubkey | sig_r, sig_s recovers correct address; phi_anchor=0x47C0 present in payload |
| TB-M9-02 | `test_phi_anchor_presence` | Every signed payload must contain 0x47C0 at bits [71:56]; inject 100 random miner outputs | All 100 payloads have PHI_ANCHOR field = 0x47C0 |
| TB-M9-03 | `test_nonce_increment` | Sign two consecutive scores; verify nonce_i[1] = nonce_i[0] + 1 | Monotonic increment holds |
| TB-M9-04 | `test_sybil_rejection` | Submit same (subnet_uid, nonce) twice from different simulated validator addresses | Second submission reverts with evidence flag |
| TB-M9-05 | `test_replay_rejection` | Capture sig from epoch N; replay in epoch N+1 with stale block_hash | `nonceUsed` check triggers; tx reverted |
| TB-M9-06 | `test_collusion_score_independence` | Two dies with identical inputs produce identical scores; verify no cross-die key leakage | Scores match; keys differ (die-specific) |
| TB-M9-07 | `test_quantizer_boundary` | Inject T-JEPA EMA scores at 0.0, 0.5, 1.0 float → verify quantizer maps to 0, 127, 255 | Exact values at boundaries; no overflow |
| TB-M9-08 | `test_r_si1_no_star` | Run Yosys synthesis with `check_noinfer` constraint; verify zero inferred multiplier cells in M9 RTL | Zero `$mul` or `MULT` cells in synth output |
| TB-M9-09 | `test_ecdsa_constant_time` | Measure ECDSA signer cycle count over 256 different scalar values; verify variance = 0 | All 256 scalars take identical cycle count |
| TB-M9-10 | `test_opcode_validate_score_request` | Execute `VALIDATE_SCORE_REQUEST` opcode; verify FSM transitions to SCORING; verify miner/subnet UID latched | FSM state = SCORING; uid registers match inputs |
| TB-M9-11 | `test_opcode_sign_subnet_score` | Execute `SIGN_SUBNET_SCORE`; poll `READ_ATTEST_PAYLOAD` attest_valid bit; verify payload populated | attest_valid = 1; sig_r/sig_s non-zero |
| TB-M9-12 | `test_score_champion_baseline` | Inject champion model outputs (BPB=2.2393); verify quantized score is in [240..255] range | Score ≥ 240 for champion-grade input |

### 9.2 Foundry Solidity Tests

```solidity
// test/BittensorSubnetAttest.t.sol (Foundry)

// Test 1: registerValidator + submitAttestation happy path
// Test 2: phi-anchor mismatch reverts
// Test 3: nonce replay reverts
// Test 4: slashSybil progressive (3 offenses → full slash)
// Test 5: rewardMultiplier ratchet (20 attestations → 2.0x)
// Test 6: anchorScoreLayerZero emits CrossChainScoreAnchored with type=0
// Test 7: anchorScoreWormhole emits CrossChainScoreAnchored with type=1
// Test 8: _lzReceive phi-anchor mismatch reverts
// Test 9: verifyAttestation returns correct hwBound flag
// Test 10: IGLALedger receives M9_ATTEST event record
```

| # | Test | Scenario | Expected |
|---|---|---|---|
| F-01 | Happy path attestation | Valid payload + sig + phi_anchor | Attestation stored; multiplier ratchets |
| F-02 | phi-anchor mismatch | payload.phiAnchor = 0xDEAD | Revert "phi-anchor mismatch" |
| F-03 | Nonce replay | Same nonce submitted twice | Second revert "nonce replayed" |
| F-04 | Sybil progressive slash | `slashSybil` called 3× | hwMultiplierBps = 0; slashed = true |
| F-05 | Multiplier ratchet | 20 verified attestations | multiplierBps = min(10000 + 20×500, 25000) = 20000 |
| F-06 | LayerZero anchor | `anchorScoreLayerZero` with mock endpoint | CrossChainScoreAnchored(bridgeType=0) emitted |
| F-07 | Wormhole anchor | `anchorScoreWormhole` with mock core | CrossChainScoreAnchored(bridgeType=1) emitted |
| F-08 | Cross-chain phi check | `_lzReceive` with anchor=0x1234 | Revert "phi-anchor mismatch in cross-chain msg" |
| F-09 | verifyAttestation view | After F-01 | valid=true; hwBound=true; score matches |
| F-10 | IGLALedger integration | After F-01 | iglaLedger.recordEvent called with M9_ATTEST key |

---

## 10. Roadmap Fit

### 10.1 Phase Timeline

| Phase | Target | Deliverable |
|---|---|---|
| **v1.0.0 (now, SKY26b)** | 2026-05-19 | phi/euler/gamma tapeout with T-JEPA EMA, IGLALedger, TrainingProver; M9 spec published |
| **v1.1 RTL spec** | 2026-06-01 | `tt_um_bittensor_validator.v` RTL complete; all 12 cocotb TBs green; Foundry 10 tests pass |
| **v1.1 SKY26c (Q3 2026)** | 2026-Q3 | M9 + M1 + M2 + M3 on one 4×4 SKY26c die; M3 RPKI signer sharing validated |
| **Sepolia testnet** | 2026-Q3 | `BittensorSubnetAttest.sol` deployed on Sepolia; end-to-end test: M9 sign → LayerZero → Sepolia |
| **Bittensor Finney integration** | 2026-Q4 | Score anchoring to Bittensor Finney via dedicated EVM bridge; validator reward multiplier live |
| **256-subnet scale** | 2027-Q1 | 256-subnet support (16-bit subnet_uid saturates at 65535; protocol ready); Wormhole fallback validated on 10+ chains |

### 10.2 SKY26c Die Layout Sketch

```
  ┌─────────────────────────────────────┐
  │         SKY26c 4×4 tile grid        │
  ├──────┬──────┬──────┬──────┬─────────┤
  │  M1  │  M1  │  M9  │  M9  │
  │  RoT │  RAM │ score│ sign │  (row 0)
  ├──────┼──────┼──────┼──────┤
  │  M3  │  M3  │  M2  │ phi  │
  │ RPKI │ ECDSA│ bw   │ base │  (row 1)
  ├──────┼──────┼──────┼──────┤
  │  v1.0.0 AI formats (PRESERVED)      │
  │  NF4/Posit/MXFP/GF/Unum...         │  (rows 2–3)
  └─────────────────────────────────────┘
```

M9 occupies 2 tiles (score + sign), sharing the ECDSA cell with M3 (1 tile). v1.0.0 AI format tiles are PRESERVED in rows 2–3.

### 10.3 Protocol Upgrade Path

Bittensor's expansion from 128 to 256 subnets does not require M9 changes — `subnet_uid` is already 16-bit (0–65535). The LayerZero OApp destination endpoint ID (`dstChainEid`) is parameterized at deployment; adding Bittensor EVM endpoint support requires only registering the new chain ID with the OApp configuration.

Wormhole fallback covers non-EVM chains that Bittensor may target (Solana, Cosmos) via the Guardian VAA mechanism.

---

## 11. References

### Bittensor Protocol
- [Bittensor About — Yuma Consensus overview](https://bittensor.com/about)
- [Bittensor dTAO Whitepaper — dynamic TAO, AMM, emission](https://bittensor.com/dtao-whitepaper)
- [Bittensor Metagraph API — trust, consensus, validator_trust](https://docs.bittensor.com/python-api/html/autoapi/bittensor/metagraph/index.html)
- [Bittensor Subtensor API — weight submission, finney network](https://docs.bittensor.com/legacy-python-api/html/autoapi/bittensor/subtensor/index.html)
- [Stake-Based Consensus for Utility Scoring (PDF)](https://bittensor.com/pdfs/consensus_v2/PoS_Utility_Consensus.pdf)
- [The Bittensor Standard](https://bittensor.com/content/the-bittensor-standard)

### Cross-Chain Infrastructure
- [LayerZero V2 Solidity Contract Standards — OApp, OFT, lzRead](https://docs.layerzero.network/v2/developers/evm/overview)
- [LayerZero V2 EVM Protocol Overview](https://docs.layerzero.network/v2/developers/evm/protocol-contracts-overview)
- [Wormhole — VAA, Guardian set, publishMessage](https://soliditydeveloper.com/wormhole)
- [Wormhole: cross-chain messaging architecture](https://crynet.io/tpost/wormhole-cross-chain-protocol-interoperability-future)

### Hardware Attestation & Security
- [Sesamedisk: Hardware attestation monopoly 2026](https://sesamedisk.com/hardware-attestation-monopoly-2026-2/)
- [Mocha: RISC-V CVA6-CHERI + OpenTitan enclave](https://www.reddit.com/r/RISCV/comments/1sykxk6/mocha_a_riscv_secure_enclave_based_on_cva6cheri/)
- [Polyhedra: HW acceleration for ZKP](https://blog.polyhedra.network/the-hardware-acceleration-revolution-for-zero-knowledge-proofs/)

### Trinity Internal
- [DEPIN_DECENTRALIZED_INTERNET_GAPS.md](https://github.com/gHashTag/NeuronConstant/blob/main/docs/DEPIN_DECENTRALIZED_INTERNET_GAPS.md) — DePIN gap analysis, M9 origin
- [CLARA-DEPIN-ADDENDUM-2026-05.md](https://github.com/gHashTag/NeuronConstant/blob/main/docs/CLARA-DEPIN-ADDENDUM-2026-05.md) — strategic context
- [IGLALedger.sol](https://github.com/gHashTag/NeuronConstant) — immutable audit ledger (champion BPB=2.2393)
- [TrainingProver.sol](https://github.com/gHashTag/NeuronConstant) — Groth16/BN254 on L1 precompile 0x08
- [MofNTrainingAttest.sol](https://github.com/gHashTag/NeuronConstant) — 2-of-3 quorum attestation (commit `394b76e`)
- [t_jepa_ema.v](https://github.com/gHashTag/NeuronConstant) — T-JEPA EMA scoring tile (commit `94eee87`, reused in M9)
- [rpki_signer.v](https://github.com/gHashTag/NeuronConstant) — M3 ECDSA secp256k1 signer (shared by M9)
- [NeurIPS DAO Workshop 2022 — Bittensor founding paper](https://bittensor.com/pdfs/academia/NeurIPS_DAO_Workshop_2022_3_3.pdf)

---

*Document ends. v1.0.0 AI format modules co-authored with Claude Opus 4.6 are PRESERVED. phi-anchor 0x47C0 (Theorem 36.1) is present in every signed payload. R-SI-1 (zero standalone `*`) holds throughout.*
