// SPDX-License-Identifier: MIT
// GF4 — GoldenFloat 4-bit wrapper
// Layout: [S(1) | E(1) | M(2)]  bias=0
// phi_dist=0.118
// SSOT: https://github.com/gHashTag/t27/blob/main/conformance/FORMAT-SPEC-001.json
//
// R-SI-1: no standalone * operators.
// Verilog-2005, default_nettype none/wire.

`default_nettype none

// ---------------------------------------------------------------------------
// gf4_decode
// ---------------------------------------------------------------------------
module gf4_decode (
    input  wire [3:0]  raw,
    output wire        sign,
    output wire [0:0]  exp_raw,
    output wire signed [1:0] exp_unbiased,
    output wire [1:0]  mant_raw,
    output wire        is_zero,
    output wire        is_inf,
    output wire        is_nan,
    output wire        is_subnormal
);
    // GF4: EXP=1, MANT=2, BIAS=0 — only 2 exponent codes (0 and 1)
    // With 1 exp bit: ALL_ONES = 1'b1
    // Special encoding: E=1,M!=0 → NaN; E=1,M=0 → Inf
    // With BIAS=0: exp_unbiased = E (0 or 1)
    gf_generic_decode #(
        .EXP_BITS  (1),
        .MANT_BITS (2),
        .BIAS      (0)
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
// gf4_mul — custom subnormal-aware multiplier
// GF4 has NO normal encodings (E=1bit: 0=zero/subnormal, 1=inf/nan).
// All finite non-zero values are subnormals.
// val = mant / 4 * 2 = mant / 2   (for subnormal, bias=0)
//
// product rule: mant_result = round(mant_a * mant_b * 2^(1-bias-M))  (GF4: >>1)
// Implemented via shift-add + round (R-SI-1 compliant).
// ---------------------------------------------------------------------------
module gf4_mul (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [3:0] result,
    output reg        overflow,
    output reg        underflow
);
    wire        sign_a  = a[3];
    wire [0:0]  exp_a   = a[2];
    wire [1:0]  mant_a  = a[1:0];
    wire        sign_b  = b[3];
    wire [0:0]  exp_b   = b[2];
    wire [1:0]  mant_b  = b[1:0];

    wire is_zero_a    = ~exp_a && (mant_a == 2'd0);
    wire is_zero_b    = ~exp_b && (mant_b == 2'd0);
    wire is_inf_a     =  exp_a && (mant_a == 2'd0);
    wire is_inf_b     =  exp_b && (mant_b == 2'd0);
    wire is_nan_a     =  exp_a && (mant_a != 2'd0);
    wire is_nan_b     =  exp_b && (mant_b != 2'd0);

    wire result_sign  = sign_a ^ sign_b;

    // subnormal * subnormal product:
    // mant_a[1:0] * mant_b[1:0] via shift-add (max 3*3=9, 4 bits needed)
    // pp0 = mant_b[0] ? mant_a : 0
    // pp1 = mant_b[1] ? {mant_a, 1'b0} : 0
    wire [3:0] pp0_gf4 = mant_b[0] ? {2'b00, mant_a} : 4'b0;
    wire [3:0] pp1_gf4 = mant_b[1] ? {1'b0, mant_a, 1'b0} : 4'b0;
    wire [3:0] raw_prod = pp0_gf4 + pp1_gf4;   // max 9 = 4'b1001

    // Divide by 2 (pure truncation): mant_result = raw_prod >> 1
    // raw_prod max = 9 (4'b1001).  raw_prod >> 1 uses top 3 bits:
    //   bit[2] = overflow flag (result > 3);
    //   bit[1:0] = 2-bit mantissa result
    wire [2:0] mant_res_shifted = {1'b0, raw_prod[3:1]};  // raw_prod >> 1 (3 bits)
    wire [1:0] mant_res   = mant_res_shifted[1:0];
    wire       mul_overflow = mant_res_shifted[2];

    always @(*) begin
        overflow  = 1'b0;
        underflow = 1'b0;

        if (is_nan_a || is_nan_b) begin
            result = 4'h5;   // NaN (E=1, M=01)
        end else if ((is_zero_a && is_inf_b) || (is_zero_b && is_inf_a)) begin
            result = 4'h5;   // 0 × inf = NaN
        end else if (is_zero_a || is_zero_b) begin
            result = result_sign ? 4'h8 : 4'h0;
        end else if (is_inf_a || is_inf_b) begin
            result = result_sign ? 4'hC : 4'h4;
        end else if (mul_overflow) begin
            // Result too large for GF4 → inf
            overflow = 1'b1;
            result   = result_sign ? 4'hC : 4'h4;
        end else if (mant_res == 2'd0) begin
            // Underflow (product < 0.25, rounds to zero)
            underflow = 1'b1;
            result    = result_sign ? 4'h8 : 4'h0;
        end else begin
            result = {result_sign, 1'b0, mant_res};   // subnormal result
        end
    end
endmodule

`default_nettype wire
