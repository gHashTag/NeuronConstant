// bf16_mul.v — bfloat16 multiplier (1 sign + 8 exponent + 7 mantissa)
// Compatible with Google Brain float16 / TensorFlow / PyTorch AI training format.
// Range: ±3.4e38, same as FP32 but lower precision.
//
// Uses tri_mant_mul8 for 8×8 mantissa multiplication (no standalone *).
//
// Inputs:  two bfloat16 values
// Outputs: bfloat16 product (round-to-zero / truncate)
//
// Special cases:
//   - Zero × anything = Zero
//   - Inf × anything (non-zero) = Inf
//   - NaN (exp=0xFF, mant≠0) propagates NaN
//   - Inf × Zero = NaN
//
// Verilog-2005, R-SI-1 compliant (no standalone *)
`default_nettype none

module bf16_mul (
    input  wire [15:0] a,        // bfloat16 operand A
    input  wire [15:0] b,        // bfloat16 operand B
    output reg  [15:0] result    // bfloat16 product
);

    // ----------------------------------------------------------------
    // Decompose A
    wire        sign_a = a[15];
    wire [7:0]  exp_a  = a[14:7];
    wire [6:0]  mant_a = a[6:0];

    // Decompose B
    wire        sign_b = b[15];
    wire [7:0]  exp_b  = b[14:7];
    wire [6:0]  mant_b = b[6:0];

    // ----------------------------------------------------------------
    // Special-case flags
    wire a_nan  = (exp_a == 8'hFF) && (mant_a != 7'd0);
    wire b_nan  = (exp_b == 8'hFF) && (mant_b != 7'd0);
    wire a_inf  = (exp_a == 8'hFF) && (mant_a == 7'd0);
    wire b_inf  = (exp_b == 8'hFF) && (mant_b == 7'd0);
    wire a_zero = (exp_a == 8'h00) && (mant_a == 7'd0);
    wire b_zero = (exp_b == 8'h00) && (mant_b == 7'd0);
    wire a_sub  = (exp_a == 8'h00) && (mant_a != 7'd0);
    wire b_sub  = (exp_b == 8'h00) && (mant_b != 7'd0);

    wire result_sign = sign_a ^ sign_b;

    // ----------------------------------------------------------------
    // Significands: {implicit_1, mant[6:0]} = 8 bits
    // For subnormals we use {0, mant} (flush-to-zero on output anyway)
    wire [7:0] sig_a = a_sub ? {1'b0, mant_a} : {1'b1, mant_a};
    wire [7:0] sig_b = b_sub ? {1'b0, mant_b} : {1'b1, mant_b};

    // ----------------------------------------------------------------
    // Mantissa multiply via tri_mant_mul8 (8x8 → 16, no *)
    wire [15:0] mant_prod;
    tri_mant_mul8 mant_mul (
        .a(sig_a),
        .b(sig_b),
        .result(mant_prod)
    );

    // ----------------------------------------------------------------
    // Exponent addition: unbiased_result = (exp_a - 127) + (exp_b - 127)
    //                    biased_result   = exp_a + exp_b - 127
    // Use 10-bit arithmetic to handle overflow/underflow
    wire [9:0] exp_sum = {2'b00, exp_a} + {2'b00, exp_b};
    // Subtract bias (127 = 8'h7F) to get biased result exponent
    wire [9:0] exp_result_raw = exp_sum - 10'd127;

    // ----------------------------------------------------------------
    // Normalize: mant_prod is Q2.14 (product of two Q1.7 numbers)
    // If bit [15] is set: overflow → shift mantissa right 1, increment exp
    // If bit [14] is set: normal result
    wire norm_overflow = mant_prod[15];

    wire [7:0] mant_out = norm_overflow ? mant_prod[14:7] : mant_prod[13:6];
    wire [9:0] exp_adj  = norm_overflow ? (exp_result_raw + 10'd1) : exp_result_raw;

    // Extract 7-bit mantissa (drop implicit leading 1)
    wire [6:0] mant_final = mant_out[6:0];

    // Detect underflow / overflow in exponent
    wire exp_underflow = exp_adj[9] || (exp_adj == 10'd0);  // signed underflow or zero
    wire exp_overflow  = (exp_adj >= 10'd255) && !exp_adj[9];

    // ----------------------------------------------------------------
    // Result selection
    always @(*) begin
        if (a_nan || b_nan || (a_inf && b_zero) || (b_inf && a_zero)) begin
            // NaN output: sign=0, exp=0xFF, mant=0x40 (canonical quiet NaN)
            result = {result_sign, 8'hFF, 7'h40};
        end else if (a_inf || b_inf) begin
            result = {result_sign, 8'hFF, 7'h00};  // ±Inf
        end else if (a_zero || b_zero || a_sub || b_sub) begin
            result = {result_sign, 15'h0000};       // flush sub/zero to zero
        end else if (exp_overflow) begin
            result = {result_sign, 8'hFF, 7'h00};  // overflow → Inf
        end else if (exp_underflow) begin
            result = {result_sign, 15'h0000};       // underflow → zero
        end else begin
            result = {result_sign, exp_adj[7:0], mant_final};
        end
    end

endmodule
`default_nettype wire
