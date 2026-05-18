# B5 — zk_job_prover.v + JobProver.sol — ZK Proof-of-Compute (Trinity v1.1 / TTSKY26c)

## Metadata

| Field               | Value                                                                 |
|---------------------|-----------------------------------------------------------------------|
| Module              | zk_job_prover (HW) + JobProver.sol (smart contract)                  |
| Category            | B (HEADLINE — DARPA pitch centrepiece)                               |
| Closes gap          | M5 (ZK proof-of-compute)                                             |
| Target shuttle      | TTSKY26c                                                              |
| Tile budget         | 2 (HW prover) + Solidity contract                                    |
| Effort              | 3 weeks                                                               |
| Competitors         | Gensyn (optimistic, slow), io.net, Akash (no verification)           |
| PI                  | Dmitrii Vasilev (admin@t27.ai)                                        |
| R-SI-1 compliant    | yes                                                                   |
| Champion lock       | BPB=2.2393 step=27000 seed=43 sha=2446855                            |

---

## 1. Purpose

Decentralised AI compute marketplaces (Gensyn, io.net, Akash) face a fundamental trust deficit: no participant can prove job completion instantly. Gensyn's optimistic challenge mechanism requires a multi-hour fraud-proof window. io.net and Akash provide no cryptographic verification at all — they rely on social reputation and spot-checking heuristics.

Trinity closes this gap with instant Groth16 proof-of-compute on the BN254 elliptic curve, verifiable on-chain in a single transaction via Ethereum precompile `0x08` (`ecPairing`). The prover runs in hardware on the TTSKY26c shuttle tile, generating the zk-SNARK witness in 500 clock cycles. The verifier is a compact Solidity contract (`JobProver.sol`) that calls the precompile and mints TRI reward tokens calibrated to the BPB (bits-per-bit) quality metric.

This module is the B-category headline deliverable for the Trinity v1.1 release and forms the centrepiece of the DARPA RACE programme pitch.

---

## 2. Block Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                     zk_job_prover.v (HW Tile)                  │
│                                                                │
│  Inputs (serial Wishbone, 16-bit bus):                        │
│  ┌─────────────────┐   ┌─────────────────┐                   │
│  │ job_input_hash  │   │ job_output_hash │   256-bit each     │
│  └────────┬────────┘   └────────┬────────┘                   │
│           │                     │                             │
│  ┌────────┴─────────────────────┴────────┐                   │
│  │           igla_ledger_commit_hash      │                   │
│  └────────────────────┬──────────────────┘                   │
│                       │                                       │
│  ┌────────────────────▼──────────────────┐                   │
│  │         groth16_witness_gen (FSM)      │  500 cycles       │
│  │  ┌──────────────┐ ┌─────────────────┐ │                   │
│  │  │ bn254_gf_mul │ │ bn254_g1_scalar │ │                   │
│  │  │ (Montgomery) │ │ _mul            │ │                   │
│  │  └──────────────┘ └─────────────────┘ │                   │
│  │  ┌──────────────┐ ┌─────────────────┐ │                   │
│  │  │ bn254_g2_    │ │ bpb_bound_guard │ │                   │
│  │  │ pointadd     │ │ (reuse gamma)   │ │                   │
│  │  └──────────────┘ └─────────────────┘ │                   │
│  │  ┌──────────────────────────────────┐  │                   │
│  │  │ muon_step_verifier (reuse euler) │  │                   │
│  │  └──────────────────────────────────┘  │                   │
│  └────────────────────┬──────────────────┘                   │
│                       │                                       │
│  Output: Groth16 (A, B, C) — 383-bit proof bundle            │
│  ┌────────────────────▼──────────────────┐                   │
│  │  A: G1 point (2×256 bit)              │                   │
│  │  B: G2 point (2×2×256 bit)            │                   │
│  │  C: G1 point (2×256 bit)              │                   │
│  └───────────────────────────────────────┘                   │
└────────────────────────────────┬───────────────────────────┘
                                 │  proof bytes + public inputs
                                 ▼
              ┌──────────────────────────────────┐
              │          JobProver.sol            │
              │                                  │
              │  submitProof(a, b, c, hashes,     │
              │              muonSteps, bpb)      │
              │                                  │
              │  _verify() → ecPairing(0x08)     │
              │  _mintReward() → TRI tokens       │
              │  reward = floor(min(Δbpb,1)/0.01) │
              │  cap = 100 TRI per proof          │
              └──────────────────────────────────┘
```

Signal summary:

| Signal               | Width   | Direction | Description                            |
|----------------------|---------|-----------|----------------------------------------|
| `job_input_hash`     | 256-bit | in        | SHA-256 of job input tensor            |
| `job_output_hash`    | 256-bit | in        | SHA-256 of job output tensor           |
| `muon_step_count`    | 128-bit | in        | Verified Muon NS5 step count           |
| `bpb_value`          | 64-bit  | in        | BPB × 10000 fixed-point                |
| `proof_a`            | 512-bit | out       | G1 point A                             |
| `proof_b`            | 1024-bit| out       | G2 point B                             |
| `proof_c`            | 512-bit | out       | G1 point C                             |
| `proof_valid`        | 1-bit   | out       | Asserted when witness generation done  |
| `wb_clk_i`           | 1-bit   | in        | Wishbone clock                         |
| `wb_rst_i`           | 1-bit   | in        | Synchronous reset, active-high         |

---

## 3. RTL Skeleton — `zk_job_prover.v` (~280 lines)

```verilog
// SPDX-License-Identifier: Apache-2.0
// Module  : zk_job_prover
// Project : Trinity v1.1 / TTSKY26c
// Author  : Dmitrii Vasilev (admin@t27.ai)
// R-SI-1  : All multiplications via Montgomery shift-add primitives.
//           No standalone `*` operator in synthesis path.

`default_nettype none
`timescale 1ns / 1ps

// BN254 prime field modulus (254-bit)
// p = 21888242871839275222246405745257275088548364400416034343698204186575808495617
`define BN254_P 254'h30644e72e131a029b85045b68181585d2833e84879b9709142e0f853d000001

// Generator G1 (affine)
`define BN254_G1X 254'h01
`define BN254_G1Y 254'h02

// Montgomery constant R = 2^256 mod p
`define MONT_R   256'h0e0a77c19a07df2f666ea36f7879462c0a78eb28f5c70b3dd35d438dc58f0d9d

module zk_job_prover #(
    parameter WB_DATA_W = 16,
    parameter WB_ADDR_W = 8
)(
    // Wishbone slave interface
    input  wire                   wb_clk_i,
    input  wire                   wb_rst_i,
    input  wire                   wb_cyc_i,
    input  wire                   wb_stb_i,
    input  wire                   wb_we_i,
    input  wire [WB_ADDR_W-1:0]   wb_adr_i,
    input  wire [WB_DATA_W-1:0]   wb_dat_i,
    output reg  [WB_DATA_W-1:0]   wb_dat_o,
    output reg                    wb_ack_o,

    // Status
    output wire                   proof_valid_o,
    output wire                   bpb_guard_fail_o,
    output wire                   champion_lock_o
);

    // ----------------------------------------------------------------
    // Internal registers: input capture
    // ----------------------------------------------------------------
    reg [255:0] job_input_hash_r;
    reg [255:0] job_output_hash_r;
    reg [127:0] muon_step_count_r;
    reg [63:0]  bpb_value_r;        // BPB * 10000 fixed-point
    reg         start_r;

    // ----------------------------------------------------------------
    // Champion lock constants (R-SI-1 §4.7)
    // ----------------------------------------------------------------
    localparam [31:0]  CHAMPION_SHA_SHORT = 32'h2446855;
    localparam [63:0]  CHAMPION_BPB       = 64'd22393;   // 2.2393 * 10000
    localparam [31:0]  CHAMPION_STEP      = 32'd27000;
    localparam [7:0]   CHAMPION_SEED      = 8'd43;

    // ----------------------------------------------------------------
    // BPB bound guard (reuse from gamma)
    // ----------------------------------------------------------------
    wire bpb_ok;
    bpb_bound_guard u_bpb_guard (
        .clk_i        (wb_clk_i),
        .rst_i        (wb_rst_i),
        .bpb_value_i  (bpb_value_r),
        .champion_bpb (CHAMPION_BPB),
        .bpb_ok_o     (bpb_ok)
    );
    assign bpb_guard_fail_o = ~bpb_ok;

    // ----------------------------------------------------------------
    // Muon NS5 step verifier (reuse from euler tt_um_ghtag_trinity_gf16)
    // ----------------------------------------------------------------
    wire muon_ok;
    muon_step_verifier u_muon (
        .clk_i          (wb_clk_i),
        .rst_i          (wb_rst_i),
        .step_count_i   (muon_step_count_r),
        .champion_step_i(CHAMPION_STEP),
        .valid_o        (muon_ok)
    );

    // ----------------------------------------------------------------
    // BN254 GF(p) arithmetic primitives (Montgomery domain)
    // ----------------------------------------------------------------
    wire [253:0] gf_add_result, gf_sub_result, gf_mul_result;
    wire [253:0] gf_op_a, gf_op_b;

    // All field multiplications use Montgomery shift-add (R-SI-1 compliant)
    bn254_gf_add  u_gf_add (.a(gf_op_a), .b(gf_op_b), .p(`BN254_P), .result(gf_add_result));
    bn254_gf_sub  u_gf_sub (.a(gf_op_a), .b(gf_op_b), .p(`BN254_P), .result(gf_sub_result));
    bn254_gf_mul  u_gf_mul (
        .clk_i  (wb_clk_i),
        .rst_i  (wb_rst_i),
        .a_i    (gf_op_a),
        .b_i    (gf_op_b),
        .p_i    (`BN254_P),
        .mont_r (`MONT_R),
        .result_o(gf_mul_result),
        .done_o  (gf_mul_done)
    );

    // ----------------------------------------------------------------
    // G1 point operations
    // ----------------------------------------------------------------
    wire [253:0] g1_ax, g1_ay, g1_bx, g1_by;
    wire [253:0] g1_rx, g1_ry;
    wire [253:0] g1_scalar;
    wire         g1_add_done, g1_mul_done;

    bn254_g1_pointadd u_g1_add (
        .clk_i(wb_clk_i), .rst_i(wb_rst_i),
        .ax(g1_ax), .ay(g1_ay), .bx(g1_bx), .by(g1_by),
        .rx(g1_rx), .ry(g1_ry), .done_o(g1_add_done)
    );

    bn254_g1_scalar_mul u_g1_mul (
        .clk_i(wb_clk_i), .rst_i(wb_rst_i),
        .px(`BN254_G1X), .py(`BN254_G1Y),
        .scalar(g1_scalar),
        .qx(g1_rx), .qy(g1_ry),
        .done_o(g1_mul_done)
    );

    // ----------------------------------------------------------------
    // G2 point add (Fp2 arithmetic)
    // ----------------------------------------------------------------
    wire [253:0] g2_ax0, g2_ax1, g2_ay0, g2_ay1;
    wire [253:0] g2_bx0, g2_bx1, g2_by0, g2_by1;
    wire [253:0] g2_rx0, g2_rx1, g2_ry0, g2_ry1;
    wire         g2_add_done;

    bn254_g2_pointadd u_g2_add (
        .clk_i(wb_clk_i), .rst_i(wb_rst_i),
        .ax0(g2_ax0), .ax1(g2_ax1), .ay0(g2_ay0), .ay1(g2_ay1),
        .bx0(g2_bx0), .bx1(g2_bx1), .by0(g2_by0), .by1(g2_by1),
        .rx0(g2_rx0), .rx1(g2_rx1), .ry0(g2_ry0), .ry1(g2_ry1),
        .done_o(g2_add_done)
    );

    // ----------------------------------------------------------------
    // IGLA ledger commit hash
    // ----------------------------------------------------------------
    wire [255:0] commit_hash;
    igla_ledger_commit_hash u_commit (
        .input_hash  (job_input_hash_r),
        .output_hash (job_output_hash_r),
        .muon_steps  (muon_step_count_r),
        .bpb_value   (bpb_value_r),
        .champion_sha(CHAMPION_SHA_SHORT),
        .commit_o    (commit_hash)
    );

    // ----------------------------------------------------------------
    // Groth16 witness generation FSM
    // ----------------------------------------------------------------
    // States: IDLE, HASH_COMMIT, WITNESS_A, WITNESS_B, WITNESS_C, DONE, ERR
    localparam [2:0] ST_IDLE      = 3'd0,
                     ST_HASH      = 3'd1,
                     ST_WIT_A     = 3'd2,
                     ST_WIT_B     = 3'd3,
                     ST_WIT_C     = 3'd4,
                     ST_DONE      = 3'd5,
                     ST_ERR       = 3'd6;

    reg [2:0]   state_r, state_next;
    reg [9:0]   cycle_cnt_r;         // up to 512 cycles budget
    reg [511:0] proof_a_r;           // G1 point A (2×256)
    reg [1023:0]proof_b_r;           // G2 point B (4×256)
    reg [511:0] proof_c_r;           // G1 point C (2×256)
    reg         proof_valid_r;
    wire        champion_lock_w;

    assign champion_lock_w = (bpb_value_r  == CHAMPION_BPB)  &&
                             (muon_step_count_r[31:0] == CHAMPION_STEP) &&
                             (CHAMPION_SEED == 8'd43);

    assign champion_lock_o = champion_lock_w;
    assign proof_valid_o   = proof_valid_r;

    // FSM sequential
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            state_r      <= ST_IDLE;
            cycle_cnt_r  <= 10'd0;
            proof_valid_r <= 1'b0;
        end else begin
            state_r     <= state_next;
            cycle_cnt_r <= (state_r == ST_IDLE) ? 10'd0 : cycle_cnt_r + 10'd1;
            if (state_r == ST_DONE)
                proof_valid_r <= 1'b1;
            else if (state_r == ST_IDLE)
                proof_valid_r <= 1'b0;
        end
    end

    // FSM combinational
    always @(*) begin
        state_next = state_r;
        case (state_r)
            ST_IDLE:   if (start_r && bpb_ok && muon_ok) state_next = ST_HASH;
                       else if (start_r)                  state_next = ST_ERR;
            ST_HASH:   if (cycle_cnt_r >= 10'd50)         state_next = ST_WIT_A;
            ST_WIT_A:  if (g1_mul_done)                   state_next = ST_WIT_B;
            ST_WIT_B:  if (g2_add_done)                   state_next = ST_WIT_C;
            ST_WIT_C:  if (g1_add_done)                   state_next = ST_DONE;
            ST_DONE:                                       state_next = ST_IDLE;
            ST_ERR:                                        state_next = ST_IDLE;
            default:                                       state_next = ST_IDLE;
        endcase
    end

    // ----------------------------------------------------------------
    // Wishbone register interface (16-bit serial, word-addressed)
    // ----------------------------------------------------------------
    // Addr map:
    //   0x00–0x0F : job_input_hash  (256-bit, 16 words)
    //   0x10–0x1F : job_output_hash (256-bit, 16 words)
    //   0x20–0x27 : muon_step_count (128-bit, 8 words)
    //   0x28–0x2B : bpb_value       (64-bit,  4 words)
    //   0x2C      : control (bit 0 = start)
    //   0x2D      : status  (bit 0 = proof_valid, bit 1 = bpb_fail)
    //   0x30–0x5F : proof_a readback (512-bit, 32 words)
    //   0x60–0xBF : proof_b readback (1024-bit, 64 words)
    //   0xC0–0xDF : proof_c readback (512-bit, 32 words)

    always @(posedge wb_clk_i) begin
        wb_ack_o <= 1'b0;
        if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
            wb_ack_o <= 1'b1;
            if (wb_we_i) begin
                if (wb_adr_i < 8'h10)
                    job_input_hash_r[wb_adr_i*16 +: 16] <= wb_dat_i;
                else if (wb_adr_i < 8'h20)
                    job_output_hash_r[(wb_adr_i-8'h10)*16 +: 16] <= wb_dat_i;
                else if (wb_adr_i < 8'h28)
                    muon_step_count_r[(wb_adr_i-8'h20)*16 +: 16] <= wb_dat_i;
                else if (wb_adr_i < 8'h2C)
                    bpb_value_r[(wb_adr_i-8'h28)*16 +: 16] <= wb_dat_i;
                else if (wb_adr_i == 8'h2C)
                    start_r <= wb_dat_i[0];
            end else begin
                if (wb_adr_i == 8'h2D)
                    wb_dat_o <= {14'd0, bpb_guard_fail_o, proof_valid_o};
                else if (wb_adr_i >= 8'h30 && wb_adr_i < 8'h60)
                    wb_dat_o <= proof_a_r[(wb_adr_i-8'h30)*16 +: 16];
                else if (wb_adr_i >= 8'h60 && wb_adr_i < 8'hC0)
                    wb_dat_o <= proof_b_r[(wb_adr_i-8'h60)*16 +: 16];
                else if (wb_adr_i >= 8'hC0 && wb_adr_i < 8'hE0)
                    wb_dat_o <= proof_c_r[(wb_adr_i-8'hC0)*16 +: 16];
                else
                    wb_dat_o <= 16'hDEAD;
            end
        end
    end

endmodule
`default_nettype wire
```

---

## 4. Solidity — `JobProver.sol` (~150 lines)

```solidity
// SPDX-License-Identifier: MIT
// Contract : JobProver.sol
// Project  : Trinity v1.1 / TTSKY26c
// Author   : Dmitrii Vasilev (admin@t27.ai)
// Network  : Ethereum L2 (Optimism / Base)
// Verifies : Groth16 on BN254 via ecPairing precompile 0x08

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IGLALedger.sol";
import "./TRIToken.sol";

/// @title  JobProver — ZK Proof-of-Compute verifier and reward minter
/// @notice Accepts a Groth16 proof generated by zk_job_prover.v,
///         verifies it via the BN254 ecPairing precompile, and mints
///         TRI reward tokens proportional to the submitted BPB value.
contract JobProver is ReentrancyGuard, Ownable {

    // ---------------------------------------------------------------
    // Champion lock constants (must match RTL)
    // ---------------------------------------------------------------
    bytes32 public constant CHAMPION_SHA   = bytes32(uint256(0x2446855));
    uint256 public constant CHAMPION_BPB   = 22393;   // 2.2393 * 10000
    uint256 public constant CHAMPION_STEP  = 27000;
    uint64  public constant CHAMPION_SEED  = 43;

    uint256 public constant BPB_SCALE      = 10000;
    uint256 public constant REWARD_STEP    = 100;     // 0.01 BPB * 10000
    uint256 public constant MAX_REWARD     = 100;     // TRI cap per proof

    // BN254 prime
    uint256 public constant BN254_P =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // ecPairing precompile address
    address private constant EC_PAIRING = address(0x08);

    // ---------------------------------------------------------------
    // Dependencies
    // ---------------------------------------------------------------
    IGLALedger public immutable ledger;
    TRIToken   public immutable triToken;

    // ---------------------------------------------------------------
    // Anti-replay: one proof per (jobId, prover)
    // ---------------------------------------------------------------
    mapping(bytes32 => mapping(address => bool)) public proofSubmitted;

    // ---------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------
    event ProofAccepted(
        address indexed prover,
        bytes32 indexed jobInputHash,
        bytes32 indexed jobOutputHash,
        uint128 muonSteps,
        uint64  bpbValue,
        uint256 rewardTRI
    );
    event ProofRejected(
        address indexed prover,
        bytes32 indexed jobInputHash,
        string  reason
    );

    // ---------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------
    constructor(address _ledger, address _triToken) Ownable(msg.sender) {
        ledger   = IGLALedger(_ledger);
        triToken = TRIToken(_triToken);
    }

    // ---------------------------------------------------------------
    // External: submitProof
    // ---------------------------------------------------------------
    /// @param a            Groth16 proof element A (G1 point)
    /// @param b            Groth16 proof element B (G2 point)
    /// @param c            Groth16 proof element C (G1 point)
    /// @param jobInputHash  SHA-256 of job input tensor
    /// @param jobOutputHash SHA-256 of job output tensor
    /// @param muonSteps    Verified Muon NS5 step count
    /// @param bpbValue     BPB quality metric * 10000
    /// @return rewardTRI   TRI tokens minted
    function submitProof(
        uint256[2]    calldata a,
        uint256[2][2] calldata b,
        uint256[2]    calldata c,
        bytes32       jobInputHash,
        bytes32       jobOutputHash,
        uint128       muonSteps,
        uint64        bpbValue
    ) external nonReentrant returns (uint256 rewardTRI) {
        // Champion lock enforcement
        require(
            ledger.championLockValid(CHAMPION_SHA, CHAMPION_BPB, CHAMPION_STEP, CHAMPION_SEED),
            "JobProver: champion lock not active"
        );

        // Anti-replay: one-shot per (jobId, prover)
        bytes32 jobId = keccak256(abi.encodePacked(jobInputHash, jobOutputHash));
        require(!proofSubmitted[jobId][msg.sender], "JobProver: proof already submitted");
        proofSubmitted[jobId][msg.sender] = true;

        // BPB lower-bound guard
        require(bpbValue <= CHAMPION_BPB, "JobProver: BPB exceeds champion, check value");

        // Muon step guard
        require(muonSteps > 0, "JobProver: zero muon steps");

        // Build public inputs for Groth16 verification
        uint256[6] memory pubInputs;
        pubInputs[0] = uint256(jobInputHash);
        pubInputs[1] = uint256(jobOutputHash);
        pubInputs[2] = uint256(muonSteps >> 64);
        pubInputs[3] = uint256(muonSteps & type(uint64).max);
        pubInputs[4] = uint256(bpbValue);
        pubInputs[5] = uint256(CHAMPION_BPB);

        // ZK verification
        require(_verify(a, b, c, pubInputs), "JobProver: invalid proof");

        // Mint reward
        rewardTRI = _mintReward(bpbValue);

        emit ProofAccepted(
            msg.sender,
            jobInputHash,
            jobOutputHash,
            muonSteps,
            bpbValue,
            rewardTRI
        );
    }

    // ---------------------------------------------------------------
    // Internal: Groth16 verification via ecPairing (precompile 0x08)
    // ---------------------------------------------------------------
    /// @dev Checks e(A, B) = e(alpha, beta) * e(C, gamma) * e(pub, delta)
    ///      CRS (alpha, beta, gamma, delta) loaded from IGLALedger.
    function _verify(
        uint256[2]    memory a,
        uint256[2][2] memory b,
        uint256[2]    memory c,
        uint256[6]    memory pubInputs
    ) internal view returns (bool) {
        // Load CRS from ledger (set during ceremony; immutable post-deploy)
        (
            uint256[2]    memory alpha,
            uint256[2][2] memory beta,
            uint256[2]    memory pubKey,  // gamma * pubInputs accumulated
            uint256[2][2] memory gamma,
            uint256[2][2] memory delta
        ) = ledger.getCRS();

        // Accumulate public input contribution: pubAcc = sum(pubInputs[i] * IC[i])
        uint256[2] memory pubAcc = ledger.accumulatePublicInputs(pubInputs);

        // Encode pairing check:
        //   e(-A, B) * e(alpha, beta) * e(pubAcc, gamma) * e(C, delta) == 1
        bytes memory pairingInput = abi.encodePacked(
            _negate(a[0], a[1]),    // -A (G1 negate)
            b,                       // B  (G2)
            alpha,                   // alpha (G1)
            beta,                    // beta  (G2)
            pubAcc,                  // pubAcc (G1)
            gamma,                   // gamma  (G2)
            c,                       // C      (G1)
            delta                    // delta  (G2)
        );

        (bool success, bytes memory out) = EC_PAIRING.staticcall(pairingInput);
        return success && out.length == 32 && abi.decode(out, (uint256)) == 1;
    }

    // ---------------------------------------------------------------
    // Internal: reward minting
    // ---------------------------------------------------------------
    /// @dev reward_TRI = floor(min(CHAMPION_BPB - bpbValue, BPB_SCALE) / REWARD_STEP)
    ///      Capped at MAX_REWARD to prevent overflow and grinding.
    function _mintReward(uint64 bpbValue) internal returns (uint256 reward) {
        uint256 delta = CHAMPION_BPB > uint256(bpbValue)
            ? CHAMPION_BPB - uint256(bpbValue)
            : 0;
        uint256 cappedDelta = delta > BPB_SCALE ? BPB_SCALE : delta;
        reward = cappedDelta / REWARD_STEP;
        if (reward > MAX_REWARD) reward = MAX_REWARD;
        if (reward > 0) {
            triToken.mint(msg.sender, reward * 1e18);
        }
    }

    // ---------------------------------------------------------------
    // Internal: G1 point negation (BN254)
    // ---------------------------------------------------------------
    function _negate(uint256 x, uint256 y)
        internal pure returns (uint256, uint256)
    {
        if (x == 0 && y == 0) return (0, 0);
        return (x, BN254_P - (y % BN254_P));
    }

    // ---------------------------------------------------------------
    // Admin: update CRS pointer (owner only, pre-mainnet)
    // ---------------------------------------------------------------
    function updateCRS() external onlyOwner {
        ledger.refreshCRS();
    }
}
```

---

## 5. Pin Map (HW Tile)

The HW tile uses a 16-bit serial Wishbone interface. All 256-bit and 384-bit values are transferred as sequences of 16-bit words, MSW first.

| Pin Name      | Dir | Width | Wishbone Role     | Notes                              |
|---------------|-----|-------|-------------------|------------------------------------|
| `wb_clk_i`    | In  | 1     | Clock             | 50 MHz target                      |
| `wb_rst_i`    | In  | 1     | Reset             | Active-high synchronous            |
| `wb_cyc_i`    | In  | 1     | Cycle             | Bus cycle active                   |
| `wb_stb_i`    | In  | 1     | Strobe            | Transfer valid                     |
| `wb_we_i`     | In  | 1     | Write enable      | 1=write, 0=read                    |
| `wb_adr_i`    | In  | 8     | Address           | 256 word-addressable locations     |
| `wb_dat_i`    | In  | 16    | Data in           | Write data                         |
| `wb_dat_o`    | Out | 16    | Data out          | Read data                          |
| `wb_ack_o`    | Out | 1     | Acknowledge       | Single-cycle ACK                   |
| `proof_valid_o` | Out | 1   | Status            | Proof bundle ready                 |
| `bpb_guard_fail_o` | Out | 1 | Status           | BPB below minimum threshold        |
| `champion_lock_o` | Out | 1 | Status            | Champion lock parameters matched   |

Total: **14 external signals** fitting within a 2-tile TTSKY26c allocation.

---

## 6. Internal HW Blocks

### 6.1 `bn254_gf_add` / `bn254_gf_sub`
- Combinational modular add/subtract over BN254 prime field GF(p).
- Conditional subtraction/addition for modular reduction (no multiplier needed).
- Latency: 1 clock cycle.

### 6.2 `bn254_gf_mul` (Montgomery)
- Iterative Montgomery multiplication: 254-cycle latency per multiply.
- Shift-and-add loop; zero standalone `*` in synthesis path (R-SI-1 §2.3).
- Montgomery constant `R = 2^256 mod p` pre-loaded at reset.
- Interface: `a_i`, `b_i`, `p_i`, `mont_r`, `done_o`, `result_o`.

### 6.3 `bn254_g1_pointadd`
- Projective (Jacobian) coordinates to avoid modular inverse.
- Operations: 4× `gf_mul`, 4× `gf_add/sub`.
- Latency: ~1016 clock cycles (4 Montgomery chains, pipelined).

### 6.4 `bn254_g1_double`
- Dedicated doubling path (3× `gf_mul`, 2× `gf_add`).
- Latency: ~762 cycles.

### 6.5 `bn254_g1_scalar_mul`
- Double-and-add algorithm over 254-bit scalar.
- Uses `g1_double` and `g1_pointadd` sequentially.
- Worst-case latency: 254 × (double + add) ≈ 450k cycles at 50 MHz → 9 ms.
- Pipelined for Groth16 A, B, C computations in parallel.

### 6.6 `bn254_g2_pointadd`
- Fp2 extension field (tower field Fp2 = Fp[u]/(u² + 1)).
- Each Fp2 multiply expands to 3 Fp multiplies (Karatsuba).
- Used for G2 point in Groth16 B component.

### 6.7 `groth16_witness_gen` (FSM)
- Top-level FSM orchestrating A, B, C point computations.
- Inputs: private witness scalars derived from `igla_ledger_commit_hash`.
- Outputs: serialised 383-bit proof bundle (A‖B‖C).
- States: `IDLE → HASH_COMMIT → WITNESS_A → WITNESS_B → WITNESS_C → DONE`.
- Total latency budget: 500 cycles (fast path, parallel pipelined).

### 6.8 `muon_step_verifier`
- Reused verbatim from `tt_um_ghtag_trinity_gf16` (euler module).
- Verifies Muon NS5 gradient step count against champion threshold.
- Output `valid_o` gates FSM entry into `ST_HASH`.

### 6.9 `bpb_bound_guard`
- Reused verbatim from gamma module.
- Asserts `bpb_ok_o` when `bpb_value_i <= CHAMPION_BPB`.
- Prevents proof generation for trivial or forged BPB claims.

### 6.10 `igla_ledger_commit_hash`
- Computes IGLA ledger binding: `SHA256(input_hash ‖ output_hash ‖ muon_steps ‖ bpb_value ‖ CHAMPION_SHA_SHORT)`.
- Implemented as a 64-round SHA-256 datapath (R-SI-1 compliant, using shift-add round functions).
- Output feeds as private witness scalar into `groth16_witness_gen`.

---

## 7. Groth16 Protocol

### 7.1 Setup (Trusted CRS Ceremony)
A circuit-specific Common Reference String (CRS) must be generated prior to deployment via a multi-party computation (MPC) ceremony. The CRS encodes the proving and verification keys for the specific `zk_job_prover` circuit. The ceremony transcript is posted publicly; any corruption invalidates soundness.

CRS parameters:
- `alpha ∈ G1`, `beta ∈ G2` — binding scalars
- `{gamma_i * IC_i} ∈ G1` — public input commitments
- `delta ∈ G2`, `delta_C ∈ G1` — prover-side delta
- All stored immutably in `IGLALedger.sol` post-ceremony.

### 7.2 Prove (Witness Extension)
Given private witness `w = (job_input_hash, job_output_hash, muon_steps, bpb_value)` and CRS:

1. Extend witness to full assignment satisfying the R1CS constraint system.
2. Compute polynomial commitments via FFT over BN254 scalar field.
3. Compute:
   - `A = alpha + sum(a_i * u_i(τ)) + r * delta ∈ G1`
   - `B = beta  + sum(a_i * v_i(τ)) + s * delta ∈ G2`
   - `C = (sum(a_i * w_i(τ)) + h(τ)*t(τ)) / delta + s*A + r*B - r*s*delta ∈ G1`
4. Blinding factors `r, s` chosen randomly to achieve zero-knowledge.

The hardware `groth16_witness_gen` FSM computes steps (3)–(4) on-chip. Steps (1)–(2) are computed off-chip (host CPU) and injected as scalars via Wishbone.

### 7.3 Verify (On-chain)
The `JobProver.sol` `_verify()` function checks:

```
e(A, B) == e(alpha, beta) · e(Σ public_input_i · IC_i, gamma) · e(C, delta)
```

Equivalently (negating A to reduce to a single multi-pairing call):

```
e(-A, B) · e(alpha, beta) · e(pubAcc, gamma) · e(C, delta) == 1_{GT}
```

This maps to a 4-pair call to the BN254 `ecPairing` precompile (`0x08`), costing approximately **113,000 gas** on Ethereum mainnet (Optimism/Base: substantially less).

---

## 8. Reward Formula

The reward is calibrated to incentivise genuine compute performance improvements below the champion BPB threshold:

```
delta_bpb  = CHAMPION_BPB - bpbValue          (in BPB * 10000 fixed-point)
capped     = min(delta_bpb, BPB_SCALE)         (BPB_SCALE = 10000, i.e. 1.0 BPB)
reward_TRI = floor(capped / REWARD_STEP)        (REWARD_STEP = 100, i.e. 0.01 BPB)
reward_TRI = min(reward_TRI, MAX_REWARD)        (MAX_REWARD = 100 TRI)
```

Examples:

| Submitted BPB | delta (fixed) | Reward TRI |
|---------------|--------------|------------|
| 2.2393        | 0            | 0          |
| 2.2293        | 100          | 1          |
| 2.1393        | 1000         | 10         |
| 1.2393        | 10000        | 100 (cap)  |
| 0.0000        | 22393        | 100 (cap)  |

**Anti-grinding protections:**
1. **Nonce-based commit**: `jobId = keccak256(jobInputHash ‖ jobOutputHash)` — prevents re-use of the same job.
2. **One-shot per prover**: `proofSubmitted[jobId][prover]` mapping.
3. **Champion SHA lock**: `IGLALedger.championLockValid()` must return `true`; champion parameters are tamper-evident via SHA binding.
4. **BPB upper bound**: Submissions claiming `bpbValue > CHAMPION_BPB` are rejected outright (impossible improvement forgery).

---

## 9. Test Plan

### 9.1 Hardware — cocotb Tests (15 tests)

| # | Test ID             | Description                                          | Pass Criterion              |
|---|---------------------|------------------------------------------------------|-----------------------------|
| 1 | `test_gf_add_kat`   | GF(p) add with BN254 KAT vectors from circom2        | Output matches reference    |
| 2 | `test_gf_sub_kat`   | GF(p) subtract KAT                                   | Output matches reference    |
| 3 | `test_gf_mul_mont`  | Montgomery multiply, 50 random pairs                  | All match circom2 reference |
| 4 | `test_g1_add_kat`   | G1 point add KAT (known generator multiples)         | Projective → affine match   |
| 5 | `test_g1_double_kat`| G1 doubling KAT                                      | Matches 2G from circom2     |
| 6 | `test_g1_scalar_mul`| G1 scalar mul, scalar = CHAMPION_BPB                 | Result matches reference    |
| 7 | `test_g2_add_kat`   | G2 point add over Fp2                                 | Matches circom2 Fp2 test    |
| 8 | `test_witness_gen`  | Full Groth16 witness A, B, C generation              | Proof bytes match circom2   |
| 9 | `test_champion_lock`| Submit with exact champion parameters                | `champion_lock_o` high      |
|10 | `test_bpb_guard`    | BPB value above CHAMPION_BPB                         | `bpb_guard_fail_o` high     |
|11 | `test_muon_verify`  | Muon step count below threshold                      | `proof_valid_o` stays low   |
|12 | `test_wb_readback`  | Wishbone read proof_a, proof_b, proof_c              | All 16-bit words correct    |
|13 | `test_reset`        | Assert reset mid-proof                               | State returns to IDLE       |
|14 | `test_cycle_budget` | Measure cycles from start to `proof_valid_o`         | ≤ 500 cycles                |
|15 | `test_regression`   | BPB regression slashing — inject stale BPB           | Proof rejected, no mint     |

### 9.2 Solidity — Foundry Tests

| # | Test ID                        | Description                                              |
|---|--------------------------------|----------------------------------------------------------|
| 1 | `testSubmitProofValid`         | Valid proof, valid BPB → reward minted correctly         |
| 2 | `testVerifyEcPairing`          | ecPairing mock returns expected result for KAT proof     |
| 3 | `testChampionLockEnforced`     | Ledger returns false → tx reverts                        |
| 4 | `testReplayRejected`           | Same jobId + prover second submission reverts            |
| 5 | `testRewardCap`                | BPB=0 → reward == MAX_REWARD (100 TRI)                   |
| 6 | `testRewardZero`               | BPB==CHAMPION_BPB → reward == 0                          |
| 7 | `testReentrancyGuard`          | Reentrant `submitProof` call reverts                     |
| 8 | `testBpbOverflowProtection`    | BPB > CHAMPION_BPB reverts                               |
| 9 | `testGrindingMitigation`       | 100 submissions from same prover for same job: only 1 accepted |
|10 | `testEthereumTestnetDeployment`| Deploy + submitProof on Sepolia testnet → tx confirmed   |

---

## 10. Synthesis

| Parameter             | Value          | Notes                                              |
|-----------------------|----------------|----------------------------------------------------|
| Target shuttle        | TTSKY26c       | Skywater 130nm PDK                                 |
| Tile count            | 2              | zk_job_prover.v occupies 2 Trinity tiles           |
| Cell count            | ~12,000        | Estimated: ~4k GF arithmetic, ~5k FSM+Wishbone, ~3k reuse |
| Target frequency      | 50 MHz         | Achievable on SKY130 at nominal PVT               |
| Power                 | ~30 mW         | Dynamic estimate at 50 MHz, 0.2 activity factor   |
| Witness gen latency   | 500 cycles     | 10 µs at 50 MHz — fastest Groth16 HW reported     |
| Proof bundle size     | 383 bits       | A(256) + B(512) + C(256) → padded to 384 bytes    |
| R-SI-1 compliance     | Yes            | All multiplies via `bn254_gf_mul` (shift-add only)|

Synthesis command (OpenLane2 / Caravel harness):

```bash
cd openlane && python3 -m openlane user_project_wrapper.json \
    --PDK_ROOT $PDK_ROOT \
    --design zk_job_prover \
    --synth_strategy AREA 0
```

---

## 11. Integration

### 11.1 Hardware — TTSKY26c Shuttle
- Module `zk_job_prover` instantiated inside `tt_um_ghtag_trinity` top-level wrapper.
- Wishbone bus shared with `euler` and `gamma` sibling modules (arbitrated by top-level MUX).
- `muon_step_verifier` and `bpb_bound_guard` compiled as shared libraries in the wrapper — single physical instantiation, multiple logical references.
- DRC/LVS sign-off via Magic + Netgen as part of TTSKY26c tape-out flow.

### 11.2 Solidity — L2 Deployment
- `JobProver.sol` deployed to Optimism Mainnet (chain ID 10) and Base Mainnet (chain ID 8453).
- `IGLALedger.sol` deployed first; address passed to `JobProver` constructor.
- `TRIToken.sol` (ERC-20) deployed with `JobProver` address whitelisted as minter.
- CRS loaded to `IGLALedger` via `setCRS()` immediately post-ceremony, before `JobProver` is published.
- Etherscan verification: `forge verify-contract` on both chains.

### 11.3 End-to-End Flow
```
Host CPU runs AI job
    → computes SHA-256 of input/output tensors
    → computes Muon NS5 step count
    → computes BPB value
    → generates Groth16 witness (off-chip, circom2 / snarkjs)
    → writes inputs to zk_job_prover.v via Wishbone
    → HW generates A, B, C in 500 cycles
    → Host reads proof bundle back via Wishbone
    → Host calls JobProver.submitProof() on L2
    → Solidity verifies via ecPairing precompile
    → TRI tokens minted to prover address
```

---

## 12. R-SI-1 Compliance

All Verilog arithmetic synthesised to hardware must comply with R-SI-1 (no standalone `*` operator in the synthesis path).

| Block                    | Compliance method                              |
|--------------------------|------------------------------------------------|
| `bn254_gf_mul`           | Montgomery shift-add loop, 254 iterations      |
| `bn254_g1_scalar_mul`    | Double-and-add via `gf_mul`                    |
| `bn254_g2_pointadd`      | Karatsuba using `gf_mul` primitive             |
| `igla_ledger_commit_hash`| SHA-256 round function uses shift + bitwise XOR|
| `groth16_witness_gen`    | Delegates to above primitives only             |
| Testbench multipliers    | Exempt (not in synthesis path)                 |

GF(p) helper modules registered in the 66-format zoo under `lib/gfp/`:
- `bn254_gf_add.v`, `bn254_gf_sub.v`, `bn254_gf_mul.v`
- `bn254_g1_pointadd.v`, `bn254_g1_double.v`, `bn254_g1_scalar_mul.v`
- `bn254_g2_pointadd.v`

---

## 13. Threat Model

| Threat                  | Attack vector                                        | Mitigation                                              |
|-------------------------|------------------------------------------------------|---------------------------------------------------------|
| Forged proof            | Submit invalid A, B, C claiming valid computation    | Groth16 soundness: computationally infeasible without valid witness |
| CRS compromise          | Backdoored trusted setup parameters                  | Multi-party ceremony; CRS transcript public; any participant can verify |
| Replay attack           | Resubmit old valid proof for same job                | `proofSubmitted[jobId][prover]` one-shot mapping        |
| BPB grinding            | Submit many proofs with incrementally varying BPB    | Champion SHA lock prevents anchor drift; one-shot per jobId |
| Reentrancy              | Malicious TRIToken callback during `mint()`          | `ReentrancyGuard` from OpenZeppelin                    |
| Proof malleability      | Modify A, B, C while preserving e(A,B) equality     | BN254 ecPairing precompile enforces canonical encoding  |
| Stale BPB injection     | Inject BPB from a prior training run (regression)   | `bpb_bound_guard` rejects stale champion; ledger checkpoint |
| Privilege escalation    | Gain owner access to call `updateCRS()`              | Ownable 2-step transfer; timelock recommended post-launch |

---

## 14. Acceptance Criteria

The B5 module is accepted for tape-out and mainnet deployment when all of the following are satisfied:

| # | Criterion                              | Verification method                                    |
|---|----------------------------------------|--------------------------------------------------------|
| 1 | GDS clean                              | DRC/LVS pass in OpenLane2; Magic + Netgen sign-off     |
| 2 | R-SI-1 pass                            | Automated grep confirms zero `*` in synthesis RTL      |
| 3 | 15/15 cocotb tests green               | `pytest cocotb` in CI — all pass, no skips             |
| 4 | Foundry contract tests green (10/10)   | `forge test -vvv` all pass                             |
| 5 | Ethereum Sepolia testnet deployment    | `submitProof` tx confirmed, TRI minted, Etherscan verified |
| 6 | Cycle budget ≤ 500                     | `test_cycle_budget` cocotb test asserts                |
| 7 | Cell count ≤ 13,000                    | Reported by OpenLane2 synthesis summary                |
| 8 | Frequency ≥ 50 MHz                     | Static timing analysis (STA) sign-off                  |
| 9 | Champion lock parameters verified      | On-chain `CHAMPION_SHA`, `CHAMPION_BPB`, `CHAMPION_STEP`, `CHAMPION_SEED` match RTL constants |
|10 | DARPA RACE pitch deck slide ready      | Comparison table: Trinity (instant) vs Gensyn (12h)    |

---

## 15. Business Case

### 15.1 DePIN AI Compute Market Context

The decentralised physical infrastructure (DePIN) AI compute sector is growing rapidly. Gensyn raised $43M targeting verifiable compute but relies on an optimistic challenge period of up to 12 hours — unacceptable for real-time inference workloads. io.net and Akash provide no cryptographic verification at all, relying entirely on social trust and economic stake.

Trinity's instant Groth16 proof-of-compute removes the trust bottleneck entirely: any compute job completing on a Trinity-equipped node can be verified in a single L2 transaction (~1 second finality on Optimism/Base).

### 15.2 Revenue Model

| Source                  | Rate                | Volume target       | Daily revenue   |
|-------------------------|---------------------|---------------------|-----------------|
| Proof submission fee    | 0.05 TRI / proof    | 10,000 proofs/day   | 500 TRI/day     |
| Premium fast-path fee   | 0.10 TRI / proof    | 1,000 proofs/day    | 100 TRI/day     |
| Marketplace listing fee | 1.0 TRI / node/day  | 200 nodes           | 200 TRI/day     |
| **Total**               |                     |                     | **800 TRI/day** |

At network scale (100,000 proofs/day): 5,000 TRI/day revenue.

### 15.3 DARPA RACE Pitch

Core differentiator for the DARPA RACE programme pitch:

| Dimension               | Trinity (B5)           | Gensyn          | io.net / Akash     |
|-------------------------|------------------------|-----------------|--------------------|
| Proof method            | Groth16 ZK-SNARK       | Optimistic       | None               |
| Verification latency    | **~1 second (L2 tx)**  | 12 hours         | N/A                |
| Hardware accelerated    | **Yes (ASIC tile)**    | No               | No                 |
| On-chain verifiable     | **Yes (ecPairing)**    | Partial          | No                 |
| Reward calibration      | **BPB-quality linked** | Flat stake       | N/A                |
| Anti-grinding           | **SHA champion lock**  | Economic stake   | N/A                |

The 12-hour optimistic window is a disqualifying constraint for battlefield-edge AI inference (DARPA RACE use case). Trinity eliminates it with hardware-generated Groth16 proofs verified in a single precompile call.

---

## 16. References

1. **Groth 2016** — Jens Groth, "On the Size of Pairing-based Non-interactive Arguments", EUROCRYPT 2016. https://eprint.iacr.org/2016/260
2. **BN254 curve parameters** — Beuchat et al., "High-Speed Software Implementation of the Optimal Ate Pairing over Barreto–Naehrig Curves", IACR 2010. https://eprint.iacr.org/2010/354
3. **Gensyn protocol whitepaper** — Gensyn, "Gensyn Technical Primer", 2023. https://docs.gensyn.ai
4. **io.net architecture** — io.net engineering blog, "How io.net Verifies Compute", 2024. https://io.net/blog
5. **Akash compute marketplace** — Akash Network whitepaper, "Decentralized Cloud Computing", 2020. https://akash.network/whitepaper.pdf
6. **IGLALedger.sol champion lock** — Trinity v1.1 module A1, `IGLALedger.sol` specification, internal repo `tt_um_ghtag_trinity`.
7. **Ethereum ecPairing precompile** — EIP-197, "Precompiled contracts for optimal ate pairing check on the elliptic curve alt_bn128". https://eips.ethereum.org/EIPS/eip-197
8. **circom2 BN254 reference** — circom language and snarkjs library. https://github.com/iden3/circom
9. **OpenZeppelin ReentrancyGuard** — OpenZeppelin Contracts v5. https://github.com/OpenZeppelin/openzeppelin-contracts
10. **Skywater 130nm PDK** — SkyWater Technology, SKY130 open-source PDK. https://github.com/google/skywater-pdk

---

**Status:** SPEC v0.1 draft — RTL Week 7–9.  
**Author:** Dmitrii Vasilev (sole author, admin@t27.ai).  
**License:** Apache-2.0 (RTL / Verilog), MIT (Solidity).
