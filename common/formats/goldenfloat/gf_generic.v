// SPDX-License-Identifier: MIT
// GoldenFloat (GF*) — Canonical Bridge Module
// Source of Truth: https://github.com/gHashTag/t27/blob/main/conformance/FORMAT-SPEC-001.json
//
// GoldenFloat = sign-magnitude floating-point with phi-driven exp/mant split.
// Identity: φ² = φ + 1  (Ring 45 proven, f64 hex evidence in SSOT).
//
// Value formula:  (-1)^S * 2^(E - bias) * (1 + M / 2^mant_bits)
// Bit layout:     [S | E | M]  (MSB → LSB)
//
// R-SI-1: ZERO standalone * operators — shift-add only for mantissa.
// Verilog-2005, default_nettype none/wire.

`default_nettype none

// ---------------------------------------------------------------------------
// gf_generic_decode
//   Parameters : EXP_BITS, MANT_BITS, BIAS
//   Total width: 1 + EXP_BITS + MANT_BITS  bits
// ---------------------------------------------------------------------------
module gf_generic_decode #(
    parameter EXP_BITS  = 6,
    parameter MANT_BITS = 9,
    parameter BIAS      = 31
) (
    input  wire [EXP_BITS+MANT_BITS:0] raw,          // 1+E+M bits, MSB=sign
    output wire                         sign,
    output wire [EXP_BITS-1:0]         exp_raw,
    output wire signed [EXP_BITS:0]    exp_unbiased,  // E_raw − BIAS (may be neg)
    output wire [MANT_BITS-1:0]        mant_raw,
    output wire                         is_zero,
    output wire                         is_inf,
    output wire                         is_nan,
    output wire                         is_subnormal
);
    assign sign        = raw[EXP_BITS+MANT_BITS];
    assign exp_raw     = raw[EXP_BITS+MANT_BITS-1 : MANT_BITS];
    assign mant_raw    = raw[MANT_BITS-1:0];

    // exp_unbiased = signed(exp_raw) − BIAS
    assign exp_unbiased = $signed({1'b0, exp_raw}) - $signed(BIAS[EXP_BITS:0]);

    assign is_zero      = (exp_raw == {EXP_BITS{1'b0}}) && (mant_raw == {MANT_BITS{1'b0}});
    assign is_subnormal = (exp_raw == {EXP_BITS{1'b0}}) && (mant_raw != {MANT_BITS{1'b0}});

    wire exp_all_ones;
    assign exp_all_ones = &exp_raw;

    assign is_inf  = exp_all_ones && (mant_raw == {MANT_BITS{1'b0}});
    assign is_nan  = exp_all_ones && (mant_raw != {MANT_BITS{1'b0}});

endmodule

// ---------------------------------------------------------------------------
// gf_generic_encode
//   Packs (sign, exp_raw, mant_raw) back into flat bit vector.
//   No arithmetic — purely structural concatenation.
// ---------------------------------------------------------------------------
module gf_generic_encode #(
    parameter EXP_BITS  = 6,
    parameter MANT_BITS = 9
) (
    input  wire                  sign,
    input  wire [EXP_BITS-1:0]  exp_raw,
    input  wire [MANT_BITS-1:0] mant_raw,
    output wire [EXP_BITS+MANT_BITS:0] raw
);
    assign raw = {sign, exp_raw, mant_raw};
endmodule

`default_nettype wire
