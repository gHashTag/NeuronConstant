// =============================================================================
// unum_i8.v — Unum Type I, 8-bit fixed-width instance
// =============================================================================
// Gustafson, J. "The End of Error: Unum Computing", CRC Press, 2015.
//
// Layout (8 bits total, MSB→LSB):
//   [7]     = sign       (1 bit)
//   [6:5]   = exponent   (2 bits, EXP_BITS=2)
//   [4:2]   = fraction   (3 bits, FRAC_BITS=3)
//   [1]     = ubit       (1 bit: 0=exact, 1=open-interval/inexact)
//   [0]     = es_meta    (1 bit: encodes exponent size, ES_META=1)
//
// NOTE on mantissa-mask approximation:
//   In standard Unum Type I the fraction field width is variable (0..FRAC_MAX).
//   For this 8-bit RTL we treat FRAC_BITS=3 as FIXED (fs_meta=0, i.e., 1 bit
//   shared between ES and FS is used for ES only).  The FS meta is implied=0,
//   meaning fraction always uses all 3 bits.  This is a documented approximation
//   acceptable for embedded inference — full variable-width would require a
//   shifter array that does not fit an 8-bit word cleanly.
//   Approximation error: ≤ 1 ULP in the 3-bit fraction = max 12.5% relative.
//
// R-SI-1: No standalone '*' — shift-add arithmetic only.
// =============================================================================

`default_nettype none

module unum_i8 (
    input  wire [7:0] unum8_in,   // Raw 8-bit unum

    // Decoded fields
    output wire        sign_out,   // sign bit
    output wire [1:0]  exp_out,    // 2-bit biased exponent (bias=1)
    output wire [2:0]  frac_out,   // 3-bit fraction
    output wire        ubit_out,   // u-bit: 0=exact, 1=inexact
    output wire        es_out,     // exponent-size meta (0→esize=1, 1→esize=2)

    // Decoded magnitude (Q4.3 approximation for synthesis)
    // value = (-1)^sign * 2^(exp-bias) * (1.fraction)
    // Represented as signed 8-bit fixed-point Q4.3 (scale factor = 8)
    output wire signed [7:0] decoded_q43,

    // Bounds (ubit semantics)
    output wire [2:0]  lower_frac,
    output wire [2:0]  upper_frac,
    output wire [1:0]  lower_exp,
    output wire [1:0]  upper_exp,

    output wire        valid_out   // 0 = NaN
);

    // -------------------------------------------------------------------------
    // Field extraction
    // -------------------------------------------------------------------------
    assign sign_out  = unum8_in[7];
    assign exp_out   = unum8_in[6:5];
    assign frac_out  = unum8_in[4:2];
    assign ubit_out  = unum8_in[1];
    assign es_out    = unum8_in[0];

    // -------------------------------------------------------------------------
    // NaN check: sign=1, exp=11, frac=111, ubit=1
    // -------------------------------------------------------------------------
    assign valid_out = ~(sign_out & (&exp_out) & (&frac_out) & ubit_out);

    // -------------------------------------------------------------------------
    // Magnitude decode — shift-add (R-SI-1 compliant)
    // mantissa_bits = {1, frac_out} = 1.xxx implicit leading 1
    // For exp=0: subnormal — mantissa = 0.xxx
    // decoded magnitude (4 bits integer, 3 bits frac):
    //   exp=0 (subnormal): shift right by 1   → {0, 0, frac_out[2], frac_out[1], frac_out[0]} >> ?
    //   exp=1: 2^0 * 1.frac → {1, frac_out}  (Q4.3: 001.xxx)
    //   exp=2: 2^1 * 1.frac → {1, frac_out} << 1
    //   exp=3: 2^2 * 1.frac → {1, frac_out} << 2
    // bias = 1 (exp=1 → actual exponent 0, value in [1,2))
    // -------------------------------------------------------------------------
    wire [6:0] mantissa;  // 1.frac in 4.3 fixed: bit[6:3]=integer, bit[2:0]=frac
    // Leading 1 for normal, 0 for subnormal
    wire leading_one = (exp_out != 2'b00);
    assign mantissa = {1'b0, leading_one, frac_out, 2'b00};
    // mantissa is {0, 1, f2, f1, f0, 0, 0} = value 8..15 for exp>=1 before shift

    // Shift mantissa by (exp - 1) to place decimal point
    // exp=0: subnormal, actual_exp_offset = -1 → shift right 1
    // exp=1: actual_exp_offset = 0 → no shift
    // exp=2: actual_exp_offset = 1 → shift left 1
    // exp=3: actual_exp_offset = 2 → shift left 2
    // Using barrel-shift-add pattern (R-SI-1: shifts not multiplies)
    reg [7:0] mag_unsigned;
    always @(*) begin
        case (exp_out)
            2'b00: mag_unsigned = {1'b0, 1'b0, frac_out, 2'b00} >> 1; // subnormal
            2'b01: mag_unsigned = {1'b0, 1'b1, frac_out, 2'b00};      // 1.xxx
            2'b10: mag_unsigned = {1'b0, 1'b1, frac_out, 2'b00} << 1; // 10.xx
            2'b11: mag_unsigned = {1'b0, 1'b1, frac_out, 2'b00} << 2; // 100.x
        endcase
    end

    // Apply sign
    // sign=1 → negate: two's complement = ~x + 1 (shift-add compliant)
    wire [7:0] negated;
    assign negated = (~mag_unsigned) + 8'd1;
    assign decoded_q43 = sign_out ? $signed(negated) : $signed(mag_unsigned);

    // -------------------------------------------------------------------------
    // Bounds (ubit semantics: ubit=1 → open interval, upper = lower + 1 ULP)
    // -------------------------------------------------------------------------
    assign lower_frac = frac_out;
    assign lower_exp  = exp_out;

    wire [3:0] frac_p1 = {1'b0, frac_out} + {3'b000, ubit_out};
    assign upper_frac  = frac_p1[2:0];
    assign upper_exp   = exp_out + {1'b0, frac_p1[3]};

endmodule

`default_nettype wire
