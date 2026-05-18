// =============================================================================
// unum_i16.v — Unum Type I, 16-bit fixed-width instance
// =============================================================================
// Gustafson, J. "The End of Error: Unum Computing", CRC Press, 2015.
//
// Layout (16 bits total, MSB→LSB):
//   [15]    = sign       (1 bit)
//   [14:11] = exponent   (4 bits, EXP_BITS=4)
//   [10:2]  = fraction   (9 bits, FRAC_BITS=9)
//   [1]     = ubit       (1 bit: 0=exact, 1=open-interval/inexact)
//   [0]     = es_meta    (1 bit: encodes exponent size)
//
// Exponent bias = 7 (2^(EXP_BITS-1) - 1 = 7), actual_exp = exp_field - 7
// Subnormal: exp_field = 0 → actual_exp = -6, mantissa = 0.fraction
// Normal: exp_field 1..14 → mantissa = 1.fraction
// Infinity/NaN: exp_field = 15 (all ones)
//
// Decoded output: Q8.9 fixed-point (17-bit signed, scale=512)
//   value ≈ (-1)^sign × 2^(exp_field - 7) × 1.fraction
//
// R-SI-1: No standalone '*' — shift-add only.
// =============================================================================

`default_nettype none

module unum_i16 (
    input  wire [15:0] unum16_in,  // Raw 16-bit unum

    // Decoded fields
    output wire         sign_out,   // sign bit
    output wire [3:0]   exp_out,    // 4-bit biased exponent (bias=7)
    output wire [8:0]   frac_out,   // 9-bit fraction
    output wire         ubit_out,   // u-bit
    output wire         es_out,     // exponent-size meta

    // Decoded value as signed Q8.9 fixed-point (17 bits, scale=512)
    output wire signed [16:0] decoded_q89,

    // Actual signed exponent (for external use), range -7..8
    output wire signed [4:0]  actual_exp,

    // Bounds
    output wire [8:0]   lower_frac,
    output wire [8:0]   upper_frac,
    output wire [3:0]   lower_exp,
    output wire [3:0]   upper_exp,

    // Special cases
    output wire         is_zero,
    output wire         is_inf,
    output wire         is_nan,
    output wire         valid_out
);

    // -------------------------------------------------------------------------
    // Field extraction
    // -------------------------------------------------------------------------
    assign sign_out  = unum16_in[15];
    assign exp_out   = unum16_in[14:11];
    assign frac_out  = unum16_in[10:2];
    assign ubit_out  = unum16_in[1];
    assign es_out    = unum16_in[0];

    // -------------------------------------------------------------------------
    // Special cases
    // -------------------------------------------------------------------------
    wire exp_all_ones  = (&exp_out);
    wire frac_zero     = ~(|frac_out);
    wire exp_zero      = ~(|exp_out);

    assign is_nan   = exp_all_ones & (~frac_zero) & ubit_out;
    assign is_inf   = exp_all_ones & frac_zero;
    assign is_zero  = exp_zero & frac_zero & ~ubit_out;
    assign valid_out = ~is_nan;

    // -------------------------------------------------------------------------
    // Actual exponent: exp_field - bias (bias=7)
    // Using addition: actual_exp = exp_out + (-7) = exp_out - 7
    // R-SI-1: addition, not multiply
    // -------------------------------------------------------------------------
    assign actual_exp = $signed({1'b0, exp_out}) + $signed(5'b11001); // -7 in signed 5-bit

    // -------------------------------------------------------------------------
    // Magnitude decode to Q8.9 fixed-point (17-bit signed, scale=512=2^9)
    // mantissa_bits = {leading_one, frac_out}  (10 bits: 1.xxxxxxxxx)
    // In Q1.9: this = 2^9 for value 1.0
    //
    // For exponent e (actual_exp), value = mantissa × 2^e
    // In Q8.9: shift mantissa left by e (if e>0) or right by -e (if e<0)
    //
    // Range supported: e in [-7..+8] → shift range [-7..+8]
    // 10-bit mantissa shifted into 17-bit result.
    //
    // R-SI-1: barrel shifts (not multiplications).
    // -------------------------------------------------------------------------
    wire        leading_one = ~exp_zero;  // subnormal: leading 0
    wire [9:0]  mantissa10  = {leading_one, frac_out};

    // Extend mantissa to 25 bits for shift room (worst case: shift left 8 = need 18 bits)
    wire [24:0] mant_ext = {15'b0, mantissa10};

    // Barrel shift by actual_exp: left for positive, right for negative
    // actual_exp is signed 5-bit
    wire        exp_neg   = actual_exp[4];
    wire [4:0]  shift_amt = exp_neg ? (~actual_exp + 5'd1) : actual_exp; // abs value

    reg [24:0] shifted;
    always @(*) begin
        if (is_zero | is_nan | is_inf)
            shifted = 25'd0;
        else if (exp_neg) begin
            // Shift right: shift_amt in [1..7]
            case (shift_amt[2:0])
                3'd0: shifted = mant_ext;
                3'd1: shifted = mant_ext >> 1;
                3'd2: shifted = mant_ext >> 2;
                3'd3: shifted = mant_ext >> 3;
                3'd4: shifted = mant_ext >> 4;
                3'd5: shifted = mant_ext >> 5;
                3'd6: shifted = mant_ext >> 6;
                3'd7: shifted = mant_ext >> 7;
            endcase
        end else begin
            // Shift left: shift_amt in [0..8]
            case (shift_amt[3:0])
                4'd0: shifted = mant_ext;
                4'd1: shifted = mant_ext << 1;
                4'd2: shifted = mant_ext << 2;
                4'd3: shifted = mant_ext << 3;
                4'd4: shifted = mant_ext << 4;
                4'd5: shifted = mant_ext << 5;
                4'd6: shifted = mant_ext << 6;
                4'd7: shifted = mant_ext << 7;
                4'd8: shifted = mant_ext << 8;
                default: shifted = mant_ext;
            endcase
        end
    end

    // Take lower 17 bits as Q8.9 magnitude
    wire [16:0] mag_q89 = shifted[16:0];

    // Apply sign (two's complement, shift-add: ~x + 1)
    wire [16:0] neg_q89 = (~mag_q89) + 17'd1;
    assign decoded_q89  = sign_out ? $signed(neg_q89) : $signed(mag_q89);

    // -------------------------------------------------------------------------
    // Bounds
    // -------------------------------------------------------------------------
    assign lower_frac = frac_out;
    assign lower_exp  = exp_out;

    wire [9:0] frac_p1 = {1'b0, frac_out} + {9'd0, ubit_out};
    assign upper_frac  = frac_p1[8:0];
    assign upper_exp   = exp_out + {3'b000, frac_p1[9]};

endmodule

`default_nettype wire
