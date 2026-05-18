// =============================================================================
// qformat_generic.v — Parameterized Q-Format Fixed-Point
// =============================================================================
// Q-format (Qm.n) represents numbers as integers scaled by 2^(-n).
// This module provides:
//   - Decode: raw bits → real value annotation
//   - Addition
//   - Multiplication via shift-add (R-SI-1 compliant)
//   - Format conversion (Q15 ↔ Q7, etc.)
//
// Parameters:
//   TOTAL_BITS : total word width (e.g., 16 for Q15, 8 for Q7)
//   Q_FRAC_BITS: fractional bits (e.g., 15 for Q0.15, 7 for Q0.7)
//   Q_INT_BITS : integer bits = TOTAL_BITS - Q_FRAC_BITS - 1 (implicit sign)
//
// Examples:
//   Q15: TOTAL=16, Q_FRAC=15  → range [-1, 1-2^-15]
//   Q7:  TOTAL=8,  Q_FRAC=7   → range [-1, 1-2^-7]
//   Q8.8: TOTAL=16, Q_FRAC=8  → range [-256, 256-2^-8]
//
// Multiply: A × B → result with Q_FRAC_BITS fractional bits
//   raw_product = A × B (2×TOTAL_BITS wide)
//   result = raw_product >> Q_FRAC_BITS (rescale)
//   Implemented as shift-add (R-SI-1 compliant).
//
// R-SI-1: No standalone '*' — shift-add only.
// =============================================================================

`default_nettype none

// -----------------------------------------------------------------------------
// qformat_add — Q-format addition (both operands must have same Q format)
// -----------------------------------------------------------------------------
module qformat_add #(
    parameter TOTAL_BITS  = 16,
    parameter Q_FRAC_BITS = 15
) (
    input  wire signed [TOTAL_BITS-1:0]  a_in,
    input  wire signed [TOTAL_BITS-1:0]  b_in,

    output wire signed [TOTAL_BITS-1:0]  sum_out,
    output wire                           overflow
);
    wire [TOTAL_BITS:0] sum_ext = {1'b0, a_in} + {1'b0, b_in};

    // Overflow: both operands same sign but result sign differs (16-bit)
    wire result_sign = sum_ext[TOTAL_BITS-1];
    wire ovf_pos = ~a_in[TOTAL_BITS-1] & ~b_in[TOTAL_BITS-1] &  result_sign;
    wire ovf_neg =  a_in[TOTAL_BITS-1] &  b_in[TOTAL_BITS-1] & ~result_sign;
    assign overflow = ovf_pos | ovf_neg;

    // Saturate
    assign sum_out = overflow
        ? (ovf_pos ? {1'b0, {(TOTAL_BITS-1){1'b1}}} : {1'b1, {(TOTAL_BITS-1){1'b0}}})
        : $signed(sum_ext[TOTAL_BITS-1:0]);
endmodule


// -----------------------------------------------------------------------------
// qformat_mul16 — Q15 × Q15 → Q15 multiply (shift-add, R-SI-1)
// For Q15: A × B = raw >> 15 (rescale)
// Output is TOTAL_BITS wide (saturated).
// -----------------------------------------------------------------------------
module qformat_mul16 #(
    parameter TOTAL_BITS  = 16,
    parameter Q_FRAC_BITS = 15
) (
    input  wire signed [TOTAL_BITS-1:0]  a_in,
    input  wire signed [TOTAL_BITS-1:0]  b_in,

    output wire signed [TOTAL_BITS-1:0]  prod_out,
    output wire                           overflow
);
    localparam PROD_BITS = TOTAL_BITS + TOTAL_BITS;  // 32 for 16-bit

    // Absolute values (shift-add: negate via ~x+1)
    wire a_neg = a_in[TOTAL_BITS-1];
    wire b_neg = b_in[TOTAL_BITS-1];
    wire res_neg = a_neg ^ b_neg;

    wire [TOTAL_BITS-1:0] a_abs = a_neg ? ((~a_in) + {{(TOTAL_BITS-1){1'b0}}, 1'b1}) : a_in;
    wire [TOTAL_BITS-1:0] b_abs = b_neg ? ((~b_in) + {{(TOTAL_BITS-1){1'b0}}, 1'b1}) : b_in;

    // Shift-add multiplier: b_abs × a_abs
    // 16 partial products, each is a_abs shifted left by bit_pos
    wire [PROD_BITS-1:0] a_ext = {{TOTAL_BITS{1'b0}}, a_abs};

    wire [PROD_BITS-1:0] pp0  = b_abs[0]  ? a_ext         : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp1  = b_abs[1]  ? (a_ext << 1)  : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp2  = b_abs[2]  ? (a_ext << 2)  : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp3  = b_abs[3]  ? (a_ext << 3)  : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp4  = b_abs[4]  ? (a_ext << 4)  : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp5  = b_abs[5]  ? (a_ext << 5)  : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp6  = b_abs[6]  ? (a_ext << 6)  : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp7  = b_abs[7]  ? (a_ext << 7)  : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp8  = b_abs[8]  ? (a_ext << 8)  : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp9  = b_abs[9]  ? (a_ext << 9)  : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp10 = b_abs[10] ? (a_ext << 10) : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp11 = b_abs[11] ? (a_ext << 11) : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp12 = b_abs[12] ? (a_ext << 12) : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp13 = b_abs[13] ? (a_ext << 13) : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp14 = b_abs[14] ? (a_ext << 14) : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp15 = b_abs[15] ? (a_ext << 15) : {PROD_BITS{1'b0}};

    // Wallace-tree addition (R-SI-1: all additions, no '*')
    wire [PROD_BITS-1:0] s01   = pp0  + pp1;
    wire [PROD_BITS-1:0] s23   = pp2  + pp3;
    wire [PROD_BITS-1:0] s45   = pp4  + pp5;
    wire [PROD_BITS-1:0] s67   = pp6  + pp7;
    wire [PROD_BITS-1:0] s89   = pp8  + pp9;
    wire [PROD_BITS-1:0] s1011 = pp10 + pp11;
    wire [PROD_BITS-1:0] s1213 = pp12 + pp13;
    wire [PROD_BITS-1:0] s1415 = pp14 + pp15;
    wire [PROD_BITS-1:0] s0123   = s01   + s23;
    wire [PROD_BITS-1:0] s4567   = s45   + s67;
    wire [PROD_BITS-1:0] s891011 = s89   + s1011;
    wire [PROD_BITS-1:0] s12131415 = s1213 + s1415;
    wire [PROD_BITS-1:0] s01234567 = s0123 + s4567;
    wire [PROD_BITS-1:0] s89101112131415 = s891011 + s12131415;
    wire [PROD_BITS-1:0] prod_raw = s01234567 + s89101112131415;

    // Rescale: right shift by Q_FRAC_BITS
    wire [PROD_BITS-1:0] prod_scaled = prod_raw >> Q_FRAC_BITS;

    // Overflow: upper half has significant bits
    assign overflow = |prod_scaled[PROD_BITS-1:TOTAL_BITS];

    wire [TOTAL_BITS-1:0] prod_mag = overflow ? {1'b0, {(TOTAL_BITS-1){1'b1}}} : prod_scaled[TOTAL_BITS-1:0];
    wire [TOTAL_BITS-1:0] prod_neg = (~prod_mag) + {{(TOTAL_BITS-1){1'b0}}, 1'b1};

    assign prod_out = res_neg ? $signed(prod_neg) : $signed(prod_mag);

endmodule


// -----------------------------------------------------------------------------
// qformat_mul8 — Q7 × Q7 → Q7 multiply (shift-add, R-SI-1)
// -----------------------------------------------------------------------------
module qformat_mul8 #(
    parameter TOTAL_BITS  = 8,
    parameter Q_FRAC_BITS = 7
) (
    input  wire signed [TOTAL_BITS-1:0]  a_in,
    input  wire signed [TOTAL_BITS-1:0]  b_in,

    output wire signed [TOTAL_BITS-1:0]  prod_out,
    output wire                           overflow
);
    localparam PROD_BITS = TOTAL_BITS + TOTAL_BITS;  // 16

    wire a_neg = a_in[TOTAL_BITS-1];
    wire b_neg = b_in[TOTAL_BITS-1];
    wire res_neg = a_neg ^ b_neg;

    wire [TOTAL_BITS-1:0] a_abs = a_neg ? ((~a_in) + {{(TOTAL_BITS-1){1'b0}}, 1'b1}) : a_in;
    wire [TOTAL_BITS-1:0] b_abs = b_neg ? ((~b_in) + {{(TOTAL_BITS-1){1'b0}}, 1'b1}) : b_in;

    wire [PROD_BITS-1:0] a_ext = {{TOTAL_BITS{1'b0}}, a_abs};

    wire [PROD_BITS-1:0] pp0 = b_abs[0] ? a_ext        : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp1 = b_abs[1] ? (a_ext << 1) : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp2 = b_abs[2] ? (a_ext << 2) : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp3 = b_abs[3] ? (a_ext << 3) : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp4 = b_abs[4] ? (a_ext << 4) : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp5 = b_abs[5] ? (a_ext << 5) : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp6 = b_abs[6] ? (a_ext << 6) : {PROD_BITS{1'b0}};
    wire [PROD_BITS-1:0] pp7 = b_abs[7] ? (a_ext << 7) : {PROD_BITS{1'b0}};

    wire [PROD_BITS-1:0] s01   = pp0 + pp1;
    wire [PROD_BITS-1:0] s23   = pp2 + pp3;
    wire [PROD_BITS-1:0] s45   = pp4 + pp5;
    wire [PROD_BITS-1:0] s67   = pp6 + pp7;
    wire [PROD_BITS-1:0] s0123 = s01 + s23;
    wire [PROD_BITS-1:0] s4567 = s45 + s67;
    wire [PROD_BITS-1:0] prod_raw = s0123 + s4567;

    wire [PROD_BITS-1:0] prod_scaled = prod_raw >> Q_FRAC_BITS;
    assign overflow = |prod_scaled[PROD_BITS-1:TOTAL_BITS];

    wire [TOTAL_BITS-1:0] prod_mag = overflow ? {1'b0, {(TOTAL_BITS-1){1'b1}}} : prod_scaled[TOTAL_BITS-1:0];
    wire [TOTAL_BITS-1:0] prod_neg = (~prod_mag) + {{(TOTAL_BITS-1){1'b0}}, 1'b1};

    assign prod_out = res_neg ? $signed(prod_neg) : $signed(prod_mag);

endmodule

`default_nettype wire
