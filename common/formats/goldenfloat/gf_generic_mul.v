// SPDX-License-Identifier: MIT
// gf_generic_mul — parametric GoldenFloat multiplier
//
// Implements full IEEE-style multiply for any GF* width:
//   result_sign = a.sign ^ b.sign
//   result_exp  = a.exp_raw + b.exp_raw - BIAS
//   result_mant = (1.a_mant * 1.b_mant) >> normalize  [shift-add, no *]
//
// Special cases:
//   NaN × anything = NaN
//   ±Inf × 0       = NaN
//   ±Inf × finite  = ±Inf
//   0    × finite  = 0
//
// R-SI-1 compliant: ZERO standalone '*' operators.
// Uses tri_mant_mul_wide for mantissa multiplication.
// Verilog-2005, default_nettype none/wire.

`default_nettype none

module gf_generic_mul #(
    parameter EXP_BITS  = 6,
    parameter MANT_BITS = 9,
    parameter BIAS      = 31
) (
    input  wire [EXP_BITS+MANT_BITS:0] a,
    input  wire [EXP_BITS+MANT_BITS:0] b,
    output reg  [EXP_BITS+MANT_BITS:0] result,
    output reg                          overflow,
    output reg                          underflow
);

    localparam TOTAL     = 1 + EXP_BITS + MANT_BITS;
    localparam FULL_MANT = MANT_BITS + 1;    // with implicit leading 1
    localparam EXP_MAX   = (1 << EXP_BITS) - 1;

    // --- Decode a ---
    wire        sign_a    = a[EXP_BITS+MANT_BITS];
    wire [EXP_BITS-1:0] exp_a  = a[EXP_BITS+MANT_BITS-1 : MANT_BITS];
    wire [MANT_BITS-1:0] mant_a = a[MANT_BITS-1:0];

    wire is_zero_a    = (exp_a == {EXP_BITS{1'b0}}) && (mant_a == {MANT_BITS{1'b0}});
    wire is_special_a = &exp_a;
    wire is_inf_a     = is_special_a && (mant_a == {MANT_BITS{1'b0}});
    wire is_nan_a     = is_special_a && (mant_a != {MANT_BITS{1'b0}});

    // --- Decode b ---
    wire        sign_b    = b[EXP_BITS+MANT_BITS];
    wire [EXP_BITS-1:0] exp_b  = b[EXP_BITS+MANT_BITS-1 : MANT_BITS];
    wire [MANT_BITS-1:0] mant_b = b[MANT_BITS-1:0];

    wire is_zero_b    = (exp_b == {EXP_BITS{1'b0}}) && (mant_b == {MANT_BITS{1'b0}});
    wire is_special_b = &exp_b;
    wire is_inf_b     = is_special_b && (mant_b == {MANT_BITS{1'b0}});
    wire is_nan_b     = is_special_b && (mant_b != {MANT_BITS{1'b0}});

    wire result_sign = sign_a ^ sign_b;

    // --- Full mantissa (1.mant) ---
    wire [FULL_MANT-1:0] full_mant_a = {1'b1, mant_a};
    wire [FULL_MANT-1:0] full_mant_b = {1'b1, mant_b};

    // --- Shift-add product via tri_mant_mul_wide ---
    wire [2*FULL_MANT-1:0] mant_prod;
    tri_mant_mul_wide #(.WIDTH(FULL_MANT)) u_mul (
        .a      (full_mant_a),
        .b      (full_mant_b),
        .product(mant_prod)
    );

    // --- Exponent sum (needs extra bit for overflow detection) ---
    wire [EXP_BITS+1:0] exp_sum = {2'b00, exp_a} + {2'b00, exp_b};

    // --- Normalise & pack result ---
    // Product bit [2*FULL_MANT-1] = 1 if result is 1x.xxx (shift needed)
    // Product bit [2*FULL_MANT-2] = 1 if result is 0.1xxx (no shift)
    wire prod_msb = mant_prod[2*FULL_MANT-1];

    // Normalised mantissa = top MANT_BITS after implicit-1
    wire [MANT_BITS-1:0] mant_norm;
    wire [EXP_BITS+1:0]  raw_exp;

    assign mant_norm = prod_msb
                     ? mant_prod[2*FULL_MANT-2 : 2*FULL_MANT-1-MANT_BITS]
                     : mant_prod[2*FULL_MANT-3 : 2*FULL_MANT-2-MANT_BITS];

    assign raw_exp   = prod_msb
                     ? (exp_sum - BIAS + 1)
                     : (exp_sum - BIAS);

    wire exp_overflow  = (raw_exp[EXP_BITS+1:EXP_BITS] != 2'b00) &&
                         (raw_exp[EXP_BITS+1] == 1'b0); // positive overflow
    wire exp_underflow = raw_exp[EXP_BITS+1];            // MSB set = negative

    wire [EXP_BITS-1:0] final_exp  = raw_exp[EXP_BITS-1:0];
    wire [MANT_BITS-1:0] final_mant = mant_norm;

    // NaN canonical encoding: exp=ALL_ONES, mant[0]=1
    localparam [TOTAL-1:0] NAN_VAL = {{1'b0}, {EXP_BITS{1'b1}}, {{MANT_BITS-1{1'b0}}, 1'b1}};
    localparam [TOTAL-1:0] INF_POS = {1'b0, {EXP_BITS{1'b1}}, {MANT_BITS{1'b0}}};
    localparam [TOTAL-1:0] INF_NEG = {1'b1, {EXP_BITS{1'b1}}, {MANT_BITS{1'b0}}};

    always @(*) begin
        overflow  = 1'b0;
        underflow = 1'b0;

        if (is_nan_a || is_nan_b) begin
            result = NAN_VAL;
        end else if ((is_zero_a && is_inf_b) || (is_zero_b && is_inf_a)) begin
            result = NAN_VAL;                         // 0 × ±Inf = NaN
        end else if (is_zero_a || is_zero_b) begin
            result = result_sign ? {1'b1, {TOTAL-1{1'b0}}} : {TOTAL{1'b0}};
        end else if (is_inf_a || is_inf_b) begin
            result = result_sign ? INF_NEG : INF_POS;
        end else if (exp_overflow) begin
            overflow = 1'b1;
            result   = result_sign ? INF_NEG : INF_POS;
        end else if (exp_underflow) begin
            underflow = 1'b1;
            result    = result_sign ? {1'b1, {TOTAL-1{1'b0}}} : {TOTAL{1'b0}};
        end else begin
            result = {result_sign, final_exp, final_mant};
        end
    end

endmodule

`default_nettype wire
