// SPDX-License-Identifier: MIT
// GF24 — GoldenFloat 24-bit wrapper
// Layout: [S(1) | E(9) | M(14)]  bias=255
// phi_dist=0.025
// SSOT: https://github.com/gHashTag/t27/blob/main/conformance/FORMAT-SPEC-001.json
//
// R-SI-1: no standalone * operators.
// Verilog-2005, default_nettype none/wire.

`default_nettype none

// ---------------------------------------------------------------------------
// gf24_decode
// ---------------------------------------------------------------------------
module gf24_decode (
    input  wire [23:0] raw,
    output wire        sign,
    output wire [8:0]  exp_raw,
    output wire signed [9:0] exp_unbiased,
    output wire [13:0] mant_raw,
    output wire        is_zero,
    output wire        is_inf,
    output wire        is_nan,
    output wire        is_subnormal
);
    gf_generic_decode #(
        .EXP_BITS  (9),
        .MANT_BITS (14),
        .BIAS      (255)
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
// gf24_mul
// ---------------------------------------------------------------------------
module gf24_mul (
    input  wire [23:0] a,
    input  wire [23:0] b,
    output wire [23:0] result,
    output wire        overflow,
    output wire        underflow
);
    gf_generic_mul #(
        .EXP_BITS  (9),
        .MANT_BITS (14),
        .BIAS      (255)
    ) u_mul (
        .a         (a),
        .b         (b),
        .result    (result),
        .overflow  (overflow),
        .underflow (underflow)
    );
endmodule

`default_nettype wire
