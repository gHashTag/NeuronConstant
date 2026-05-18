// SPDX-License-Identifier: MIT
// GF12 — GoldenFloat 12-bit wrapper
// Layout: [S(1) | E(4) | M(7)]  bias=7
// phi_dist=0.047
// SSOT: https://github.com/gHashTag/t27/blob/main/conformance/FORMAT-SPEC-001.json
//
// R-SI-1: no standalone * operators.
// Verilog-2005, default_nettype none/wire.

`default_nettype none

// ---------------------------------------------------------------------------
// gf12_decode
// ---------------------------------------------------------------------------
module gf12_decode (
    input  wire [11:0] raw,
    output wire        sign,
    output wire [3:0]  exp_raw,
    output wire signed [4:0] exp_unbiased,
    output wire [6:0]  mant_raw,
    output wire        is_zero,
    output wire        is_inf,
    output wire        is_nan,
    output wire        is_subnormal
);
    gf_generic_decode #(
        .EXP_BITS  (4),
        .MANT_BITS (7),
        .BIAS      (7)
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
// gf12_mul
// ---------------------------------------------------------------------------
module gf12_mul (
    input  wire [11:0] a,
    input  wire [11:0] b,
    output wire [11:0] result,
    output wire        overflow,
    output wire        underflow
);
    gf_generic_mul #(
        .EXP_BITS  (4),
        .MANT_BITS (7),
        .BIAS      (7)
    ) u_mul (
        .a         (a),
        .b         (b),
        .result    (result),
        .overflow  (overflow),
        .underflow (underflow)
    );
endmodule

`default_nettype wire
