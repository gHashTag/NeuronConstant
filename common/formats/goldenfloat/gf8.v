// SPDX-License-Identifier: MIT
// GF8 — GoldenFloat 8-bit wrapper
// Layout: [S(1) | E(3) | M(4)]  bias=3
// phi_dist=0.132
// SSOT: https://github.com/gHashTag/t27/blob/main/conformance/FORMAT-SPEC-001.json
//
// R-SI-1: no standalone * operators.
// Verilog-2005, default_nettype none/wire.

`default_nettype none

// ---------------------------------------------------------------------------
// gf8_decode
// ---------------------------------------------------------------------------
module gf8_decode (
    input  wire [7:0]  raw,
    output wire        sign,
    output wire [2:0]  exp_raw,
    output wire signed [3:0] exp_unbiased,
    output wire [3:0]  mant_raw,
    output wire        is_zero,
    output wire        is_inf,
    output wire        is_nan,
    output wire        is_subnormal
);
    gf_generic_decode #(
        .EXP_BITS  (3),
        .MANT_BITS (4),
        .BIAS      (3)
    ) u_dec (
        .raw         (raw),
        .sign        (sign),
        .exp_raw     (exp_raw),
        .exp_unbiased(exp_unbiased),
        .mant_raw    (mant_raw),
        .is_zero     (is_zero),
        .is_inf      (is_inf),
        .is_nan      (is_nan),
        .is_subnormal(is_subnormal)
    );
endmodule

// ---------------------------------------------------------------------------
// gf8_mul
// ---------------------------------------------------------------------------
module gf8_mul (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] result,
    output wire       overflow,
    output wire       underflow
);
    gf_generic_mul #(
        .EXP_BITS  (3),
        .MANT_BITS (4),
        .BIAS      (3)
    ) u_mul (
        .a         (a),
        .b         (b),
        .result    (result),
        .overflow  (overflow),
        .underflow (underflow)
    );
endmodule

`default_nettype wire
