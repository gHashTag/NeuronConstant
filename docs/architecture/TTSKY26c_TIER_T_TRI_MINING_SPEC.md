# TTSKY26c — Tier T: TRI Mining RTL Module Specification

<!-- SPDX-License-Identifier: Apache-2.0 -->

---

## Frontmatter

| Field | Value |
|---|---|
| **Author** | Dmitrii Vasilev \<admin@t27.ai\> |
| **License** | Apache-2.0 |
| **Date** | 2026-05-18 |
| **Status** | planning — TTSKY26c submission window 2026-09-01 → 2026-11-15 |
| **Silicon target** | TTSKY26c (projected tape-out 2026-12-16, silicon Q1 2027) |
| **Parent doc** | `TTSKY26c_UNIFIED_COMPUTER_RTL_ROADMAP.md` (commit 7f8efce) |
| **Support matrix** | `TRI_SILICON_SUPPORT_MATRIX.md` (commit ab446d4) |
| **Honest perf** | ~1 GOPS @ ~50 MHz @ ~1 W ternary (projected, pending tape-out 2026-12-16) |

**TL;DR:** This document specifies 9 Tier-T RTL modules that add TRI-mining-specific capability to
TTSKY26c. Aggregate tile cost is ~22 tiles distributed across Euler (14 tiles) and Gamma (8 tiles);
Phi absorbs two trivially small fold-ins (M2, M4) at negligible area. All Tier-T work is strictly
additive — no v1.0.0 module (NF4, Posit16, GF4/16/256, `tri_mant_mul`, sacred opcodes) is
disturbed. The Phi 1×1 die has only one tile total; accordingly only fold-in modules (M2 era
counter, M4 constant ROM) are placed there — all substantive logic lives on Euler and Gamma.

---

## Tile Arithmetic

TTSKY26c as defined in the G6 roadmap already allocates ~35 tiles for Tier M+U modules. Tier T
adds ~22 tiles, bringing the projected total to ~57 tiles. TTSKY26c can theoretically accommodate
up to ~150 tiles across all three dies, so headroom exists — however per-die budgets are binding.

**Critical note — Euler near-saturation:** Tier T alone consumes ~14 of Euler 8×2's 16 available
tiles. If M6 (bn254_pairing_unit, 6 tiles) is retained, only ~2 spare Euler tiles remain for
debug or future micro-increments. **Tile drop-priority: defer M6 to TTSKY26d; this reduces Euler
Tier-T usage to 8/16 tiles and restores comfortable margin.**

| # | Module | Die | Tiles | v1.0.0 dependencies |
|---|---|---|---|---|
| M1 | `mining_proof_engine` | Gamma 8×4 | 4 | `tri_mant_mul`, sha256 stub |
| M2 | `era_halving_counter` | Phi 1×1 | \<1 (fold into top) | none |
| M3 | `chip_uptime_attestor` | Euler 8×2 | 1 | none |
| M4 | `champion_bpb_oracle` | Phi 1×1 | \<1 (constant ROM, fold into top) | anchor 0x47C0 |
| M5 | `coptic_subunit_decoder` | Euler 8×2 | 1 | none |
| M6 | `bn254_pairing_unit` | Euler 8×2 | 6 (largest; fallback: defer to TTSKY26d) | `tri_mant_mul`, GF256 |
| M7 | `yuma_consensus_accel` | Gamma 8×4 | 4 | `tri_mant_mul` |
| M8 | `conviction_ema_tracker` | Euler 8×2 | 2 | none |
| M9 | `sr25519_signer` | Euler 8×2 | 4 | `tri_mant_mul`, GF arithmetic |
| — | **TOTAL** | Euler 14 + Gamma 8 + Phi ~0 | **~22** | |

---

## M1 — mining_proof_engine.v

**Purpose:** SHA-256-based mining proof generator for TRI block validation. Accepts a 32-bit
nonce, 256-bit block data payload, and 4-bit era index; produces a 256-bit proof digest plus a
validity flag. The `anchor_check` output is hardwired to the 16-bit chip identity constant
`0x47C0` whenever a valid proof is asserted, enabling host-side chip-authenticity verification.
Difficulty target is selected from a per-era lookup table (shift-based; no standalone multiply).
The SHA-256 compression unit is shared with the v1.0.0 hash module — this block instantiates
that shared unit rather than duplicating it.

**Die:** Gamma 8×4  
**Tiles:** 4  
**v1.0.0 dependencies:** `tri_mant_mul`, sha256 stub (shared)  
**R-SI-1 compliance:** No standalone `*` operators. All internal scaling uses shift-add sequences.
`tri_mant_mul` is instantiated for any ternary-weighted accumulation steps. Bit-select expressions
of the form `[idx*W +: W]` are whitelisted by the R-SI-1 linter and are used for block-word
indexing only.

### Top-level Verilog signature

```verilog
`default_nettype none

module mining_proof_engine #(
    parameter ANCHOR       = 16'h47C0,
    parameter ERA_COUNT    = 4'd9,
    parameter DATA_W       = 256,
    parameter PROOF_W      = 256
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [31:0]       nonce,
    input  wire [DATA_W-1:0] block_data,
    input  wire [3:0]        era,
    input  wire              mine_en,
    output reg  [PROOF_W-1:0] proof,
    output reg               proof_valid,
    output reg  [15:0]       anchor_check   // = ANCHOR when proof_valid
);
    // Behaviour summary:
    // 1. On mine_en assert, latch nonce, block_data, era into pipeline stage 0.
    // 2. Shared sha256_core instance hashes {nonce, block_data}; 64-cycle latency.
    // 3. Era-indexed difficulty threshold is read from a ROM (9 entries, shift-encoded).
    //    Threshold comparison: leading-zero count on digest vs era_shift[era] — no * used.
    // 4. If digest meets threshold: proof <= digest, proof_valid <= 1,
    //    anchor_check <= ANCHOR (16'h47C0).
    // 5. Else: proof_valid <= 0, anchor_check <= 16'h0000.
    // 6. tri_mant_mul instance used if ternary-weighted nonce mixing is enabled (era >= 4).
    //    mul instance: u_tmm (.clk, .a(nonce_ext), .b(era_weight), .p(nonce_mixed))
    //    where era_weight is shift-encoded constant — no standalone * in that path.
endmodule

`default_nettype wire
```

### Cocotb test plan

- **Test 1: known-answer SHA256** — feed fixed (nonce=0, block_data=known_vec, era=0); verify
  proof matches reference digest; check proof_valid asserts after expected latency.
- **Test 2: difficulty gating** — sweep nonces 0..1023 at era=3; verify proof_valid only
  asserts when leading-zero count ≥ era_shift[3]; check anchor_check == 16'h47C0 on valid.
- **Test 3: era boundary** — step era from 0→8 each with representative nonce; verify threshold
  tightens monotonically.
- **Test 4: reset behavior** — assert rst_n mid-computation; verify proof_valid deasserts and
  proof output is zeroed.
- **Coverage target:** ≥85% line, ≥80% branch.

### Risk / mitigation

- **Risk:** SHA-256 shared unit arbitration increases proof latency under concurrent load.
- **Mitigation:** Insert a 2-deep request queue; grant round-robin; worst-case latency documented
  in integration sim.

---

## M2 — era_halving_counter.v

**Purpose:** Tracks the total number of valid proofs submitted since genesis and derives the
current mining era index (0–8). Emits `current_era[3:0]` for use by M1 and host software. Era
boundaries are at proof-count thresholds that double with each era (1 M, 2 M, 4 M, … 128 M
proofs), implemented as a shift-register comparator with no multiply logic. Folds into Phi top
(`tt_um_trinity_nano.v`) in unused-wire territory; consumes negligible area.

**Die:** Phi 1×1 (fold into top)  
**Tiles:** \<1  
**v1.0.0 dependencies:** none  
**R-SI-1 compliance:** No standalone `*`. All threshold constants are power-of-two shifts;
comparators use plain `>=` on left-shifted literals.

### Top-level Verilog signature

```verilog
`default_nettype none

module era_halving_counter #(
    parameter PROOF_CTR_W = 28          // supports up to 256 M proofs
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    proof_inc,    // pulse per valid proof
    output reg  [3:0]              current_era,
    output reg  [PROOF_CTR_W-1:0]  proof_count
);
    // Behaviour summary:
    // 1. proof_count increments on proof_inc; saturates at (1 << PROOF_CTR_W)-1.
    // 2. Nine thresholds stored as shift-encoded parameters:
    //    era_thresh[0]=1<<20 (1M), era_thresh[1]=1<<21, ..., era_thresh[8]=1<<27 (128M).
    //    No * operators — threshold values are pre-computed parameters.
    // 3. current_era is updated combinatorially: highest i where proof_count >= era_thresh[i].
    // 4. current_era is monotonically non-decreasing (Coq monotonicity proof target).
endmodule

`default_nettype wire
```

### Cocotb test plan

- **Test 1: era transitions** — drive proof_inc for 1 M+1 cycles; verify current_era steps
  0→1 at the correct proof_count value.
- **Test 2: saturation** — overflow proof_count to max; verify it saturates and era stays at 8.
- **Test 3: reset** — mid-count reset; verify proof_count=0 and current_era=0.
- **Coverage target:** ≥85% line, ≥80% branch.

### Risk / mitigation

- **Risk:** 28-bit counter in Phi 1×1 routing congestion.
- **Mitigation:** Synthesize as register chain; confirm fit in Phi top P&R early in flow.

---

## M3 — chip_uptime_attestor.v

**Purpose:** Accumulates a 48-bit cycle count since the last hard reset, providing a monotonically
increasing uptime word as part of the chip attestation payload. The `mining_proof_engine` (M1)
can use the uptime value to apply a conviction-weighting bonus to longer-running chips (older
chips with sustained uptime receive incremental reward weighting). Output is registered and
exported to the Euler top via the xchip attestation bus.

**Die:** Euler 8×2  
**Tiles:** 1  
**v1.0.0 dependencies:** none  
**R-SI-1 compliance:** Pure counter; no multiply path anywhere in this module.

### Top-level Verilog signature

```verilog
`default_nettype none

module chip_uptime_attestor #(
    parameter UPTIME_W = 48
)(
    input  wire                clk,
    input  wire                rst_n,
    output reg  [UPTIME_W-1:0] uptime,
    output wire                uptime_valid   // always 1 after reset
);
    // Behaviour summary:
    // 1. uptime increments by 1 every clk cycle after rst_n deasserts.
    // 2. Saturates at {UPTIME_W{1'b1}} — no wrap.
    // 3. uptime_valid ties high once rst_n has been seen; used by M1 as gating flag.
    // 4. No multiply logic; pure increment register.
endmodule

`default_nettype wire
```

### Cocotb test plan

- **Test 1: increment** — run 1000 cycles post-reset; verify uptime == 1000.
- **Test 2: saturation** — pre-load uptime near max via force; verify it saturates and does not
  wrap.
- **Test 3: valid flag** — verify uptime_valid deasserts during rst_n, reasserts one cycle after.
- **Coverage target:** ≥85% line, ≥80% branch.

### Risk / mitigation

- **Risk:** 48-bit saturating adder may add a carry-chain cycle to timing closure.
- **Mitigation:** Register at mid-chain; relax to 2-cycle latency if needed (uptime is not on
  critical path for mining throughput).

---

## M4 — champion_bpb_oracle.v

**Purpose:** Read-only ROM exposing two chip-identity constants: the BPB lock constant `2.2393`
encoded as Q4.12 fixed-point (`16'h23D2`) and the chip anchor `0x47C0`. The oracle contains zero
sequential logic — it is purely combinational constant assignment. Host software reads these via
the xchip debug bus to verify chip authenticity without needing to run a full proof. Folds into
Phi top (`tt_um_trinity_nano.v`) in unused-wire territory.

**Die:** Phi 1×1 (fold into top)  
**Tiles:** \<1 (constant ROM, no flip-flops)  
**v1.0.0 dependencies:** anchor 0x47C0  
**R-SI-1 compliance:** Constant-only module; no operators of any kind.

### Top-level Verilog signature

```verilog
`default_nettype none

module champion_bpb_oracle #(
    parameter ANCHOR      = 16'h47C0,
    parameter BPB_Q4_12   = 16'h23D2    // 2.2393 in Q4.12 fixed-point
)(
    input  wire        clk,             // present for std cell tie-off consistency
    input  wire        rst_n,
    input  wire        rd_en,
    output wire [15:0] bpb_const,       // = BPB_Q4_12 when rd_en
    output wire [15:0] anchor_out       // = ANCHOR always
);
    // Behaviour summary:
    // 1. anchor_out is wired directly to parameter ANCHOR — no logic.
    // 2. bpb_const is gated by rd_en (simple AND-with-constant).
    //    bpb_const = rd_en ? BPB_Q4_12 : 16'h0000.
    // 3. No flip-flops; clk/rst_n present only for netlist consistency requirements.
    // 4. Formal proof target: anchor_out === 16'h47C0 under all input conditions.
endmodule

`default_nettype wire
```

### Cocotb test plan

- **Test 1: anchor constant** — assert rd_en; verify anchor_out == 16'h47C0 unconditionally.
- **Test 2: BPB constant** — assert rd_en; verify bpb_const == 16'h23D2.
- **Test 3: rd_en gate** — deassert rd_en; verify bpb_const == 16'h0000; anchor_out unchanged.
- **Formal target:** Bounded model check (depth 1) proving anchor_out === ANCHOR for all inputs.
- **Coverage target:** ≥85% line, ≥80% branch.

### Risk / mitigation

- **Risk:** Synthesis tool may optimise away unused clk/rst_n, leaving dangling nets in Phi top.
- **Mitigation:** Add `(* keep *)` attribute or tie-off cells in Phi top wrapper.

---

## M5 — coptic_subunit_decoder.v

**Purpose:** Pure combinational decoder for TRI sub-unit denominations as defined in
`04_SUB_UNITS_COPTIC.md`. Accepts a 4-bit denomination code and outputs a 5-bit
`multiplier_shift` value that the host or on-chip arithmetic unit applies as a left-shift to
convert between denomination layers. No sequential state; zero flip-flops. All scaling is
shift-based — no standalone multiply operators.

**Die:** Euler 8×2  
**Tiles:** 1  
**v1.0.0 dependencies:** none  
**R-SI-1 compliance:** Pure combinational decode; no `*` of any kind. Output is a shift amount,
not a product.

### Top-level Verilog signature

```verilog
`default_nettype none

module coptic_subunit_decoder (
    input  wire [3:0] denom_code,       // denomination index per 04_SUB_UNITS_COPTIC.md
    output reg  [4:0] multiplier_shift, // log2 of the multiplier for this denomination
    output reg        decode_valid      // 0 if denom_code is reserved/undefined
);
    // Behaviour summary:
    // 1. 16-entry case statement mapping denom_code → multiplier_shift.
    //    Example: 4'h0 → 5'd0 (base unit, shift 0), 4'h1 → 5'd3 (milli-TRI = >>3), etc.
    // 2. decode_valid = 1 for codes 4'h0..4'hB (12 defined denominations),
    //    decode_valid = 0 for reserved codes 4'hC..4'hF.
    // 3. No registers; pure combinational logic; no clk/rst pins.
    // 4. Caller applies: value_in >> multiplier_shift to get base-unit equivalent.
endmodule

`default_nettype wire
```

### Cocotb test plan

- **Test 1: all valid codes** — iterate denom_code 0..11; verify multiplier_shift matches
  reference table; verify decode_valid == 1.
- **Test 2: reserved codes** — iterate 12..15; verify decode_valid == 0.
- **Test 3: conversion integration** — pick three representative denominations; apply shift to a
  known value; verify result matches expected base-unit value.
- **Coverage target:** ≥85% line, ≥80% branch.

### Risk / mitigation

- **Risk:** `04_SUB_UNITS_COPTIC.md` denomination table may be revised before tapeout.
- **Mitigation:** Encode table as a localparameter array; single-point update; re-run test suite.

---

## M6 — bn254_pairing_unit.v

**Purpose:** BN254 elliptic-curve pairing engine for ZK-mining-receipt verification. Executes an
optimal Ate pairing over BN254 (the same curve used by Aztec, Ethereum `bn256` precompile), which
allows on-chip verification of zk-SNARK proofs attached to mining receipts. This is the largest
Tier-T module at 6 tiles. The Ate pairing Miller loop is fully pipelined at ~200 clock cycles
per pairing. All GF(p) field multiplications go through `tri_mant_mul` instances; no standalone
`*` operators appear anywhere in the RTL. Implementation follows the Apache-2.0 Aztec
barretenberg-style reference to avoid patent exposure (see R3 in risk table).

**⚠ Tile-budget fallback:** If Euler tile headroom is insufficient at tapeout submission, M6 is
the first candidate for deferral to TTSKY26d. Deferral drops Euler Tier-T usage from 14 to 8
out of 16 tiles and restores a comfortable margin.

**Die:** Euler 8×2  
**Tiles:** 6  
**v1.0.0 dependencies:** `tri_mant_mul`, GF256  
**R-SI-1 compliance:** No standalone `*`. All GF(p) multiplications are routed through
`tri_mant_mul` instances. Bit-select indexing `[i*LIMB_W +: LIMB_W]` is whitelisted.

### Top-level Verilog signature

```verilog
`default_nettype none

module bn254_pairing_unit #(
    parameter FIELD_W  = 254,
    parameter LIMB_W   = 64,
    parameter PIPELINE = 200    // cycles per pairing, projected
)(
    input  wire              clk,
    input  wire              rst_n,
    // G1 point (affine, uncompressed)
    input  wire [FIELD_W-1:0] g1_x,
    input  wire [FIELD_W-1:0] g1_y,
    // G2 point (affine, Fp2 coordinates)
    input  wire [FIELD_W-1:0] g2_x0,
    input  wire [FIELD_W-1:0] g2_x1,
    input  wire [FIELD_W-1:0] g2_y0,
    input  wire [FIELD_W-1:0] g2_y1,
    input  wire              pair_en,
    // Result: GT element (Fp12, serialised)
    output reg  [FIELD_W*12-1:0] gt_result,
    output reg               pair_valid,
    output reg               pair_busy
);
    // Behaviour summary:
    // 1. On pair_en: latch G1/G2 inputs; assert pair_busy; start Miller loop FSM.
    // 2. Miller loop (~68 doubling + ~6 addition steps) uses tri_mant_mul for each
    //    GF(p) limb multiply. tri_mant_mul instances: u_tmm_0..u_tmm_3 (4 instances,
    //    time-multiplexed across loop iterations).
    // 3. Final exponentiation follows Miller loop; same tri_mant_mul reuse.
    // 4. pair_valid asserts for one cycle on completion; pair_busy deasserts.
    // 5. GF256 instance used for Fp2 extension field bookkeeping.
    // 6. No standalone * anywhere; all limb products via tri_mant_mul.
endmodule

`default_nettype wire
```

### Cocotb test plan

- **Test 1: identity pairing** — e(G1, G2) using generator points; verify result equals known
  reference GT element.
- **Test 2: bilinearity** — e(a·G1, G2) == e(G1, a·G2) for scalar a; verify equality.
- **Test 3: invalid point** — feed point at infinity; verify pair_valid still asserts with
  correct identity GT output.
- **Test 4: back-to-back** — issue two consecutive pair_en without gap; verify pair_busy
  gating and correct sequential results.
- **Coverage target:** ≥85% line, ≥80% branch.

### Risk / mitigation

- **Risk:** 6-tile cost may exceed Euler per-die budget at final P&R.
- **Mitigation:** Defer to TTSKY26d as primary fallback; alternatively reduce pipeline width
  (accept ~400-cycle latency to halve area).

---

## M7 — yuma_consensus_accel.v

**Purpose:** Hardware accelerator for Bittensor BIT-0011 Yuma consensus weight aggregation.
Accepts 32-element validator weight vectors and stake vectors; outputs a 32-bit consensus score
representing the stake-weighted normalised validator agreement. Uses `tri_mant_mul` for all
weighted-sum operations; no standalone `*` operators.

**Attribution notice:** Yuma consensus is the original work of the OpenTensor Foundation,
described in the publicly available BIT-0011 specification. This module is a hardware
accelerator implementing the published algorithm. NeuronConstant / T27 AI are not the inventors
of Yuma consensus and make no claim to the algorithm itself.

**Die:** Gamma 8×4  
**Tiles:** 4  
**v1.0.0 dependencies:** `tri_mant_mul`  
**R-SI-1 compliance:** No standalone `*`. All weighted sums computed via `tri_mant_mul`
instances (u_tmm_w0..u_tmm_w3, 4 instances). Accumulator uses shift-add for normalisation.

### Top-level Verilog signature

```verilog
`default_nettype none

module yuma_consensus_accel #(
    parameter N_VALIDATORS = 32,
    parameter SCORE_W      = 32,
    parameter WEIGHT_W     = 16
)(
    input  wire                              clk,
    input  wire                              rst_n,
    input  wire [N_VALIDATORS*WEIGHT_W-1:0]  validator_weights,  // packed
    input  wire [N_VALIDATORS*WEIGHT_W-1:0]  stake_vec,          // packed
    input  wire                              compute_en,
    output reg  [SCORE_W-1:0]               consensus_score,
    output reg                              score_valid
);
    // Behaviour summary:
    // 1. On compute_en: unpack validator_weights and stake_vec into 32 lanes.
    //    Lane unpacking uses [i*WEIGHT_W +: WEIGHT_W] bit-select — whitelisted.
    // 2. For each lane i: partial = tri_mant_mul(validator_weights[i], stake_vec[i]).
    //    Uses 4 tri_mant_mul instances time-multiplexed, 8 lanes per instance → 8 cycles.
    // 3. Accumulate 32 partials via shift-add tree (no standalone *).
    // 4. Normalise by right-shifting total stake sum (log2 approximation).
    // 5. consensus_score <= normalised result; score_valid pulses for one cycle.
    // 6. Attribution: algorithm per OpenTensor Foundation BIT-0011 public spec.
endmodule

`default_nettype wire
```

### Cocotb test plan

- **Test 1: uniform weights** — all validator_weights equal, uniform stake; verify
  consensus_score equals input weight (identity case).
- **Test 2: single-dominant validator** — one validator weight = max, rest zero; verify
  consensus_score reflects that single validator.
- **Test 3: stake-weighted skew** — varied stakes; verify output shifts toward high-stake
  validators as expected by BIT-0011 formula.
- **Test 4: zero stake** — all stake_vec = 0; verify no divide-by-zero pathology; score_valid
  still asserts; score = 0.
- **Coverage target:** ≥85% line, ≥80% branch.

### Risk / mitigation

- **Risk:** tri_mant_mul reuse contention when M7 and M1 both active on Gamma simultaneously.
- **Mitigation:** Instantiate 2 dedicated tri_mant_mul copies in yuma_consensus_accel; cost
  is +0.5 tile on Gamma (within budget).

---

## M8 — conviction_ema_tracker.v

**Purpose:** Computes an exponential moving average (EMA) of per-chip conviction scores as they
arrive from the consensus layer. The smoothing coefficient alpha is a 4-bit shift parameter
(0–15), making the EMA update: `ema_next = (ema_prev × (16 - alpha) + new_score × alpha) >> 4`.
All arithmetic is implemented with shift-add — no standalone multiply operators. The EMA output
feeds M9 (sr25519_signer) to include conviction level in the signed payload.

**Die:** Euler 8×2  
**Tiles:** 2  
**v1.0.0 dependencies:** none  
**R-SI-1 compliance:** No standalone `*`. The factor `(16 - alpha)` is computed as a
shift-and-subtract; the factor `alpha` as a conditional shift. Division by 16 is a 4-bit right
shift. No `tri_mant_mul` needed — shift-add sufficient for 16-bit operands.

### Top-level Verilog signature

```verilog
`default_nettype none

module conviction_ema_tracker #(
    parameter SCORE_W = 16,
    parameter ALPHA_W = 4       // alpha in range [0..15], divide-by-16 normalisation
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire [SCORE_W-1:0] new_score,
    input  wire [ALPHA_W-1:0] alpha,
    input  wire               score_en,
    output reg  [SCORE_W-1:0] ema_out,
    output reg                ema_valid
);
    // Behaviour summary:
    // 1. On score_en: compute weight_old = (16 - alpha) as 5-bit value (0..16).
    //    Shift: old_contrib = ema_out << weight_old, then right-normalise >> 4.
    //    new_contrib = new_score << alpha, then right-normalise >> 4.
    //    ema_next = old_contrib + new_contrib  (no standalone * anywhere).
    // 2. ema_out <= ema_next; ema_valid pulses one cycle.
    // 3. On rst_n: ema_out = 0; ema_valid = 0.
    // 4. alpha = 0 → ema frozen (old weight = 1.0, new weight = 0).
    //    alpha = 15 → fast decay toward new_score.
    // 5. Coq monotonicity proof target: with fixed alpha and monotonically increasing
    //    new_score, ema_out is monotonically non-decreasing.
endmodule

`default_nettype wire
```

### Cocotb test plan

- **Test 1: step response** — drive new_score = MAX with alpha = 8 from ema = 0; verify EMA
  converges toward MAX over ~20 cycles.
- **Test 2: alpha extremes** — alpha = 0 (ema frozen); alpha = 15 (near-instant track);
  verify boundary behavior.
- **Test 3: reset mid-stream** — assert rst_n during active EMA; verify ema_out zeroes and
  ema_valid deasserts.
- **Test 4: monotonicity** — feed slowly increasing new_score; verify ema_out is
  monotonically non-decreasing.
- **Coverage target:** ≥85% line, ≥80% branch.

### Risk / mitigation

- **Risk:** Shift-add approximation of EMA introduces rounding bias for small alpha values.
- **Mitigation:** Add 1-bit guard bit in accumulator; document precision bound in module header.

---

## M9 — sr25519_signer.v

**Purpose:** Schnorrkel sr25519 signature generation for Bittensor wallet transaction signing.
Produces a 512-bit (64-byte) Ristretto255 Schnorr signature, streamed out in 32-bit words.
Scalar multiplication on the Ristretto255 group is the primary compute cost and uses
`tri_mant_mul` for limb-level GF arithmetic. The module asserts `sig_done` on completion and
holds `sig[511:0]` valid until the next `sign_en`. Follows the Apache-2.0 sr25519 reference
implementation (see R2 in risk table); CITATION.cff added to repository root.

**Die:** Euler 8×2  
**Tiles:** 4  
**v1.0.0 dependencies:** `tri_mant_mul`, GF arithmetic (GF4/GF16 from v1.0.0 used for
intermediate field bookkeeping)  
**R-SI-1 compliance:** No standalone `*`. All scalar field multiplications routed through
`tri_mant_mul` instances (u_tmm_sr0..u_tmm_sr1). Bit-select `[i*32 +: 32]` whitelisted.

### Top-level Verilog signature

```verilog
`default_nettype none

module sr25519_signer #(
    parameter KEY_W    = 256,
    parameter MSG_W    = 256,
    parameter SIG_W    = 512
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [KEY_W-1:0]  secret_key,
    input  wire [MSG_W-1:0]  message,
    input  wire              sign_en,
    output reg  [SIG_W-1:0]  sig,
    output reg               sig_done,
    output reg               sig_busy
);
    // Behaviour summary:
    // 1. On sign_en: latch secret_key, message; assert sig_busy.
    // 2. Nonce generation: deterministic hash of (secret_key, message) → nonce scalar r.
    // 3. Scalar multiply R = r * B on Ristretto255 group:
    //    Uses tri_mant_mul instances for 255-bit limb products (u_tmm_sr0, u_tmm_sr1).
    //    No standalone * in scalar ladder implementation.
    // 4. Challenge e = H(R || public_key || message) via shared sha256_core.
    // 5. Response s = r + e * secret_key (mod group order):
    //    Again via tri_mant_mul for the product e * secret_key.
    // 6. sig <= {R_compressed[255:0], s[255:0]}; sig_done pulses; sig_busy deasserts.
    // 7. GF4/GF16 from v1.0.0 used for extension-field intermediate steps.
    // 8. Stream output: sig words available word-by-word at [i*32 +: 32], i=0..15.
endmodule

`default_nettype wire
```

### Cocotb test plan

- **Test 1: signature generation** — provide known (secret_key, message) pair; verify
  sig[511:0] matches reference sr25519 test vector.
- **Test 2: sig_done timing** — measure cycles from sign_en to sig_done; verify within
  budget (target ≤ 512 cycles @ 50 MHz).
- **Test 3: busy gating** — assert sign_en while sig_busy is high; verify second request is
  held off correctly.
- **Test 4: reset during signing** — assert rst_n mid-signature; verify sig_busy deasserts
  and sig output zeroes.
- **Coverage target:** ≥85% line, ≥80% branch.

### Risk / mitigation

- **Risk:** sr25519 involves third-party Ristretto255 / Schnorrkel IP considerations.
- **Mitigation:** Implement from Apache-2.0 sr25519-dalek reference spec; add `CITATION.cff`
  crediting Ristretto255 originators; legal review before tapeout submission.

---

## Verification Strategy

### Per-module cocotb benches

Each module M1–M9 has a dedicated cocotb test file under `tests/tier_t/<module_name>_tb.py`.
Tests are parameterised to cover edge cases listed in per-module test plans above.
Coverage threshold: ≥85% line, ≥80% branch (measured via `verilator --coverage`).

### Tri-die integration simulation

A top-level integration bench exercises the complete mining flow across all three dies:

```
M2 (era_halving_counter)  ──┐
M3 (chip_uptime_attestor) ──┤→ M1 (mining_proof_engine) ──→ M6 (bn254_pairing_unit)
M4 (champion_bpb_oracle)  ──┘                               ──→ M8 (conviction_ema_tracker)
                                                               ──→ M9 (sr25519_signer)
```

Integration bench verifies:
1. Era counter feeds correct era index to M1.
2. Uptime from M3 is embedded in proof payload.
3. Anchor 0x47C0 from M4 matches anchor_check output of M1.
4. Valid proof from M1 triggers M6 pairing verification.
5. EMA in M8 converges after 10 valid proofs.
6. M9 signature covers both proof digest and EMA score.

### R-SI-1 lint workflow

Branch `depin-v2/tier-t` (future) will run `rtl_lint_rsi1.py --check-star` on every push. The
linter whitelists:
- `[idx*W +: W]` bit-select indexing (synthesis-inert).
- `{N*W{1'b0}}` replication constants.
- Parameter and localparameter width expressions.

Any other standalone `*` token in RTL triggers CI failure.

### Formal proofs

- **M4 champion_bpb_oracle:** Bounded model check (depth 1) proving
  `anchor_out === 16'h47C0` unconditionally.
- **M2 era_halving_counter:** Formal proof of monotonicity — `current_era` never decreases.

### Coq proofs (critical-path, mirroring G6 roadmap methodology)

- **M1 mining_proof_engine:** Coq proof that difficulty calculation (leading-zero threshold
  comparison) is correct for all era values 0–8.
- **M8 conviction_ema_tracker:** Coq proof that EMA output is monotonically non-decreasing
  when input sequence is non-decreasing and alpha is fixed.

---

## Integration into Existing v1.0.0

All Tier-T modules are strictly additive. No v1.0.0 module is modified.

### Gamma top — `tt_um_trinity_max_true.v`

```
tt_um_trinity_max_true
├── [v1.0.0 preserved] nf4_*, posit16_*, sacred_opcode_*
├── [NEW] mining_proof_engine  (M1, 4 tiles)
└── [NEW] yuma_consensus_accel (M7, 4 tiles)
```

### Euler top — `tt_um_ghtag_trinity_gf16.v`

```
tt_um_ghtag_trinity_gf16
├── [v1.0.0 preserved] xchip_opcode_decoder, gf4_*, gf16_*, gf256_*, tri_mant_mul
├── [NEW] chip_uptime_attestor    (M3, 1 tile)
├── [NEW] coptic_subunit_decoder  (M5, 1 tile)
├── [NEW] bn254_pairing_unit      (M6, 6 tiles — see fallback note)
├── [NEW] conviction_ema_tracker  (M8, 2 tiles)
└── [NEW] sr25519_signer          (M9, 4 tiles)
```

### Phi top — `tt_um_trinity_nano.v`

```
tt_um_trinity_nano
├── [v1.0.0 preserved] all existing Phi logic
├── [NEW, folded] era_halving_counter  (M2, <1 tile, unused-wire territory)
└── [NEW, folded] champion_bpb_oracle  (M4, <1 tile, constant ROM)
```

**All v1.0.0 modules are preserved.** NF4, Posit16, GF4/GF16/GF256, `tri_mant_mul`, and sacred
opcodes remain unmodified. Tier T is additive overlay only.

---

## Risk Table

| # | Risk | Mitigation |
|---|---|---|
| R1 | Euler 8×2 tile near-saturation (~14/16 tiles used by Tier T alone) | Defer M6 to TTSKY26d; reduces to 8/16 tiles; comfortable margin restored |
| R2 | sr25519 IP — third-party Schnorrkel/Ristretto255 scheme | Implement from Apache-2.0 sr25519-dalek reference; add `CITATION.cff` |
| R3 | BN254 pairing patents | Use Aztec barretenberg-style impl (Apache-2.0); legal review pre-submission |
| R4 | Yuma consensus IP | Cite OpenTensor Foundation BIT-0011 publicly; attribution in RTL header |
| R5 | `tri_mant_mul` reuse contention (M1+M7 on Gamma; M6+M9 on Euler) | Instantiate 2 dedicated copies per die where contention identified; cost +0.5–1 tile |

---

## Open Questions for PI

1. **M6 curve selection:** BN254 vs BLS12-381. BLS12-381 can be cheaper in some pairing
   implementations and is preferred by Ethereum's next-generation precompiles. Needs PI decision
   before RTL authoring begins.
2. **M9 signature scheme:** sr25519 (Ristretto255/Schnorrkel) vs ed25519 (Edwards25519). ed25519
   is cheaper in tiles (~2 vs ~4) and has more reference implementations. Decision depends on
   Bittensor wallet toolchain requirements.
3. **M2 era thresholds:** Fixed at compile-time (current spec) or programmable via a register
   write port? Programmable adds ~0.1 tile on Phi but future-proofs era schedule changes.

---

## License and Footer

```
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Dmitrii Vasilev <admin@t27.ai>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

- **Sole author:** Dmitrii Vasilev \<admin@t27.ai\>
- **No AI co-author.**
- **v1.0.0 modules preserved** — NF4, Posit16, GF4/GF16/GF256, `tri_mant_mul`, sacred opcodes.
- **Honest performance:** ~1 GOPS @ ~50 MHz @ ~1 W ternary (projected, pending tape-out 2026-12-16).
- **Anchor:** 0x47C0 appears in M1 (anchor_check output), M4 (champion_bpb_oracle constant ROM).

---

## See Also

- **Parent roadmap:** `TTSKY26c_UNIFIED_COMPUTER_RTL_ROADMAP.md` (commit 7f8efce)
- **Support matrix:** `TRI_SILICON_SUPPORT_MATRIX.md` (commit ab446d4)
- **Whitepaper:** §9 Trinity Is One Computer
- **Tokenomics:** TRI tokenomics v2 INDEX
- **BIT-0011:** OpenTensor Foundation Yuma consensus public specification

---

## Русское резюме (Russian Summary)

Настоящий документ описывает 9 RTL-модулей уровня Tier T для кремния TTSKY26c
(окно подачи: 2026-09-01 — 2026-11-15; ожидаемый tape-out: 2026-12-16; кремний: Q1 2027).

**Модули:**

| № | Модуль | Кристалл | Тайлы |
|---|---|---|---|
| M1 | `mining_proof_engine` — SHA-256 генератор доказательств | Gamma | 4 |
| M2 | `era_halving_counter` — счётчик эпох halvingа (свёртывается в Phi top) | Phi | \<1 |
| M3 | `chip_uptime_attestor` — счётчик непрерывной работы чипа | Euler | 1 |
| M4 | `champion_bpb_oracle` — ПЗУ констант BPB + якорь 0x47C0 (свёртывается в Phi top) | Phi | \<1 |
| M5 | `coptic_subunit_decoder` — дешифратор субноминалов TRI (коптическая система) | Euler | 1 |
| M6 | `bn254_pairing_unit` — BN254 паросочетание для zk-майнинг-квитанций | Euler | 6 |
| M7 | `yuma_consensus_accel` — аппаратный ускоритель консенсуса Yuma (BIT-0011) | Gamma | 4 |
| M8 | `conviction_ema_tracker` — EMA-трекер оценок убеждённости | Euler | 2 |
| M9 | `sr25519_signer` — sr25519-подписчик для кошелька Bittensor | Euler | 4 |

**Совокупный итог:** ~22 тайла — Euler 14 + Gamma 8 + Phi (≈0, fold-in).

**Ключевые ограничения:**
- Кристалл Phi 1×1 имеет всего 1 тайл; только fold-in модули (M2, M4) размещаются там.
- Euler близок к насыщению при включении M6 (14/16 тайлов). Приоритет переноса: M6 → TTSKY26d.
- R-SI-1: ноль самостоятельных операторов `*` в RTL; все умножения — через `tri_mant_mul`.
- Якорь 0x47C0 присутствует в M1 (вывод `anchor_check`) и M4 (константа ПЗУ).
- Все модули v1.0.0 сохранены без изменений. Tier T — только аддитивное расширение.
- Автор: Дмитрий Васильев \<admin@t27.ai\>. Лицензия: Apache-2.0.
- Честная производительность: ~1 GOPS @ ~50 МГц @ ~1 Вт тернарных операций
  (проектируемые показатели, окончательные — после tape-out 2026-12-16).
