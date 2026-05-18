// =============================================================================
// unum_arith.v — Unum Type I Arithmetic Helpers (Add, Mul)
// =============================================================================
// Gustafson, J. "The End of Error: Unum Computing", CRC Press, 2015.
//
// Provides add and multiply helpers for Unum Type I decoded Q4.3 (8-bit)
// and Q8.9 (16-bit) representations.
//
// Both operations work on DECODED fixed-point values (output of unum_i8 /
// unum_i16 decoded_q43 / decoded_q89) rather than raw unum bit patterns.
//
// Ubit propagation rules (Gustafson):
//   - result_ubit = a_ubit OR b_ubit  (inexact × anything = inexact)
//   - If overflow occurs: result_ubit = 1 (open interval near ±∞)
//
// R-SI-1: No standalone '*' operator — shift-add multiplication.
// =============================================================================

`default_nettype none

// -----------------------------------------------------------------------------
// unum_arith_add8 — Add two 8-bit Unum Type I values (Q4.3 decoded)
// -----------------------------------------------------------------------------
module unum_arith_add8 (
    input  wire signed [7:0]  a_val,    // decoded Q4.3 value A
    input  wire               a_ubit,   // u-bit of A
    input  wire signed [7:0]  b_val,    // decoded Q4.3 value B
    input  wire               b_ubit,   // u-bit of B

    output wire signed [7:0]  sum_val,  // result (saturating)
    output wire               sum_ubit, // result u-bit
    output wire               overflow  // saturation flag
);

    // 9-bit extended addition to detect overflow
    wire signed [8:0] sum_ext = $signed({a_val[7], a_val}) + $signed({b_val[7], b_val});

    // Overflow: sign bits agree but result sign differs
    wire ovf_pos = ~a_val[7] & ~b_val[7] &  sum_ext[8];
    wire ovf_neg =  a_val[7] &  b_val[7] & ~sum_ext[8];
    assign overflow = ovf_pos | ovf_neg;

    // Saturate on overflow
    assign sum_val  = overflow ? (ovf_pos ? 8'h7F : 8'h80) : sum_ext[7:0];

    // Ubit propagation: inexact if either operand inexact, or overflow
    assign sum_ubit = a_ubit | b_ubit | overflow;

endmodule


// -----------------------------------------------------------------------------
// unum_arith_mul8 — Multiply two 8-bit Unum Type I decoded Q4.3 values
// Shift-add implementation (R-SI-1 compliant)
//
// Q4.3 × Q4.3 = Q8.6, truncated back to Q4.3 (lower 7 bits of integer part)
// -----------------------------------------------------------------------------
module unum_arith_mul8 (
    input  wire signed [7:0]  a_val,    // Q4.3 value A
    input  wire               a_ubit,
    input  wire signed [7:0]  b_val,    // Q4.3 value B
    input  wire               b_ubit,

    output wire signed [7:0]  prod_val, // Q4.3 result (saturated)
    output wire               prod_ubit,
    output wire               overflow
);

    // Absolute values for shift-add
    wire a_neg = a_val[7];
    wire b_neg = b_val[7];
    wire result_neg = a_neg ^ b_neg;

    // Two's complement to positive: ~x + 1 (shift-add: add 1)
    wire [7:0] a_abs = a_neg ? ((~a_val) + 8'd1) : a_val;
    wire [7:0] b_abs = b_neg ? ((~b_val) + 8'd1) : b_val;

    // Shift-add: a_abs × b_abs via partial products
    // b_abs[7:0] × a_abs = sum of (a_abs << bit_pos) for each set bit in b_abs
    // Product width: 16 bits (8 + 8)
    wire [15:0] pp0 = b_abs[0] ? {8'b0, a_abs}        : 16'b0;
    wire [15:0] pp1 = b_abs[1] ? {7'b0, a_abs, 1'b0}  : 16'b0;
    wire [15:0] pp2 = b_abs[2] ? {6'b0, a_abs, 2'b0}  : 16'b0;
    wire [15:0] pp3 = b_abs[3] ? {5'b0, a_abs, 3'b0}  : 16'b0;
    wire [15:0] pp4 = b_abs[4] ? {4'b0, a_abs, 4'b0}  : 16'b0;
    wire [15:0] pp5 = b_abs[5] ? {3'b0, a_abs, 5'b0}  : 16'b0;
    wire [15:0] pp6 = b_abs[6] ? {2'b0, a_abs, 6'b0}  : 16'b0;
    wire [15:0] pp7 = b_abs[7] ? {1'b0, a_abs, 7'b0}  : 16'b0;

    // Sum partial products (pure addition tree, R-SI-1 compliant)
    wire [15:0] sum01 = pp0 + pp1;
    wire [15:0] sum23 = pp2 + pp3;
    wire [15:0] sum45 = pp4 + pp5;
    wire [15:0] sum67 = pp6 + pp7;
    wire [15:0] sum0123 = sum01 + sum23;
    wire [15:0] sum4567 = sum45 + sum67;
    wire [15:0] prod_raw = sum0123 + sum4567;  // Q8.6 (3+3=6 frac bits)

    // Rescale Q8.6 → Q4.3: drop 3 frac bits (right shift 3), keep 8 bits
    wire [15:0] prod_scaled = prod_raw >> 3;  // Q4.3, unsigned

    // Apply sign: two's complement
    wire [7:0] prod_pos = prod_scaled[7:0];
    wire [7:0] prod_neg = (~prod_pos) + 8'd1;

    // Overflow: if any upper bits of prod_scaled are set
    assign overflow = |prod_scaled[15:8] | (result_neg & (prod_pos == 8'h80));

    wire [7:0] prod_mag = overflow ? 8'h7F : prod_pos;
    assign prod_val  = result_neg ? $signed(prod_neg) : $signed(prod_mag);
    assign prod_ubit = a_ubit | b_ubit | overflow;

endmodule


// -----------------------------------------------------------------------------
// unum_arith_add16 — Add two 16-bit Unum Type I values (Q8.9 decoded)
// -----------------------------------------------------------------------------
module unum_arith_add16 (
    input  wire signed [16:0] a_val,    // Q8.9 value A (17-bit)
    input  wire               a_ubit,
    input  wire signed [16:0] b_val,    // Q8.9 value B
    input  wire               b_ubit,

    output wire signed [16:0] sum_val,
    output wire               sum_ubit,
    output wire               overflow
);

    wire signed [17:0] sum_ext = $signed({a_val[16], a_val}) + $signed({b_val[16], b_val});

    wire ovf_pos = ~a_val[16] & ~b_val[16] &  sum_ext[17];
    wire ovf_neg =  a_val[16] &  b_val[16] & ~sum_ext[17];
    assign overflow = ovf_pos | ovf_neg;

    assign sum_val  = overflow ? (ovf_pos ? 17'h0FFFF : 17'h10000) : sum_ext[16:0];
    assign sum_ubit = a_ubit | b_ubit | overflow;

endmodule

`default_nettype wire
