// SPDX-License-Identifier: MIT
// GF16 — GoldenFloat 16-bit wrapper  *** PRIMARY FORMAT ***
// Layout: [S(1) | E(6) | M(9)]  bias=31
// phi_dist=0.0486  exp/mant_ratio=0.667
// SSOT: https://github.com/gHashTag/t27/blob/main/conformance/FORMAT-SPEC-001.json
//
// Pinout-compatible with gen/verilog/numeric/gf16.v from t27.
// Also compatible with tiles/*/rtl/gf16_*.v (confirmed GoldenFloat, not Galois Field).
//
// R-SI-1: no standalone * operators.
// Verilog-2005, default_nettype none/wire.

`default_nettype none

// ---------------------------------------------------------------------------
// gf16_decode
// ---------------------------------------------------------------------------
module gf16_decode (
    input  wire [15:0] raw,
    output wire        sign,
    output wire [5:0]  exp_raw,
    output wire signed [6:0] exp_unbiased,
    output wire [8:0]  mant_raw,
    output wire        is_zero,
    output wire        is_inf,
    output wire        is_nan,
    output wire        is_subnormal
);
    gf_generic_decode #(
        .EXP_BITS  (6),
        .MANT_BITS (9),
        .BIAS      (31)
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
// gf16_decode_full — also exposes mant_normalized_q (Q1.9 fixed-point)
// ---------------------------------------------------------------------------
module gf16_decode_full (
    input  wire [15:0] raw,
    output wire        sign,
    output wire signed [6:0] exp_unbiased,
    output wire [9:0]  mant_normalized_q,   // 1.mant (implicit leading 1)
    output wire        is_zero,
    output wire        is_inf,
    output wire        is_nan,
    output wire        is_subnormal
);
    wire [5:0]  exp_raw;
    wire [8:0]  mant_raw;

    gf_generic_decode #(
        .EXP_BITS  (6),
        .MANT_BITS (9),
        .BIAS      (31)
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

    // mant_normalized_q: 1.mantissa in Q1.9 (subnormals use 0.mantissa)
    assign mant_normalized_q = is_subnormal ? {1'b0, mant_raw}
                                            : {1'b1, mant_raw};
endmodule

// ---------------------------------------------------------------------------
// gf16_mul  (delegates to gf16_mul_opt for optimised PRIMARY path)
// ---------------------------------------------------------------------------
module gf16_mul (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [15:0] result,
    output wire        overflow,
    output wire        underflow
);
    gf_generic_mul #(
        .EXP_BITS  (6),
        .MANT_BITS (9),
        .BIAS      (31)
    ) u_mul (
        .a         (a),
        .b         (b),
        .result    (result),
        .overflow  (overflow),
        .underflow (underflow)
    );
endmodule

`default_nettype wire
