// =============================================================================
// afp.v — Adaptive Float-Point (AfP)
// =============================================================================
// AfP (Adaptive Floating-Point): A parameterized floating-point format where
// the exponent field width is configurable at runtime via a CONFIG register.
// This is a research-grade approximation format suited for neural network
// inference where exponent range vs. precision can be traded off dynamically.
//
// Bit layout (16-bit word, runtime-configurable exponent):
//   [15]        = sign (1 bit, always)
//   [14:14-E+1] = exponent (E bits)
//   [14-E:0]    = fraction (F = 15-E bits)
//   Total = 1 + E + F = 1 + E + (15-E) = 16 bits always.
//
// CONFIG encoding (3 bits):
//   3'b000 → E=2, F=13  (exp range ±1, large fraction)
//   3'b001 → E=3, F=12  (exp range ±3)
//   3'b010 → E=4, F=11  (exp range ±7)  [IEEE half-like]
//   3'b011 → E=5, F=10  (exp range ±15) [brain-float like]
//   3'b100 → E=6, F= 9  (exp range ±31)
//   3'b101 → E=7, F= 8  (exp range ±63)
//   3'b110 → E=8, F= 7  (exp range ±127)
//   3'b111 → E=2, F=13  (reserved → same as 000)
//
// Exponent bias = 2^(E-1) - 1
// Infinity:  exp_field = all-ones, frac = 0
// NaN:       exp_field = all-ones, frac ≠ 0
// Zero:      exp_field = 0, frac = 0
//
// R-SI-1: No standalone '*' — shift-add only.
// =============================================================================

`default_nettype none

module afp (
    input  wire [15:0]  afp_in,    // Raw 16-bit AfP value
    input  wire [2:0]   config_in, // Runtime exponent config

    // Decoded fields (max width, upper bits 0 when E < max)
    output wire          sign_out,
    output wire [7:0]    exp_out,   // up to 8 bits, zero-extended
    output wire [12:0]   frac_out,  // up to 13 bits, zero-extended

    // Actual field widths from config
    output wire [3:0]    exp_bits,  // 2..8 actual exponent bits
    output wire [3:0]    frac_bits, // 7..13 actual fraction bits
    output wire [7:0]    bias,      // exponent bias = 2^(E-1) - 1

    // Decoded value as Q8.13 signed (22-bit, scale=8192=2^13)
    output wire signed [21:0] decoded_q813,

    // Validity flags
    output wire          is_nan,
    output wire          is_inf,
    output wire          is_zero
);

    // -------------------------------------------------------------------------
    // Config decode: E bits
    // -------------------------------------------------------------------------
    reg [3:0] e_bits_r;
    always @(*) begin
        case (config_in)
            3'b000: e_bits_r = 4'd2;
            3'b001: e_bits_r = 4'd3;
            3'b010: e_bits_r = 4'd4;
            3'b011: e_bits_r = 4'd5;
            3'b100: e_bits_r = 4'd6;
            3'b101: e_bits_r = 4'd7;
            3'b110: e_bits_r = 4'd8;
            3'b111: e_bits_r = 4'd2;
        endcase
    end

    assign exp_bits  = e_bits_r;
    // F = 15 - E (total = 1+E+F = 16)
    assign frac_bits = 4'd15 - e_bits_r;

    // Bias = 2^(E-1) - 1 (shift-add: 1 << (E-1) - 1)
    assign bias = (8'd1 << (e_bits_r - 4'd1)) - 8'd1;

    // -------------------------------------------------------------------------
    // Sign: MSB
    // -------------------------------------------------------------------------
    assign sign_out = afp_in[15];

    // -------------------------------------------------------------------------
    // afp_body = bits[14:0]
    // -------------------------------------------------------------------------
    wire [14:0] afp_body = afp_in[14:0];

    // -------------------------------------------------------------------------
    // Exponent field: bits [14 : 15-E] (E bits wide)
    // Shift right by (15-E) = frac_bits to get the exponent
    // -------------------------------------------------------------------------
    reg [14:0] exp_sh_r;
    always @(*) begin
        case (frac_bits)  // frac_bits = 15 - E
            4'd13: exp_sh_r = afp_body >> 13;  // E=2
            4'd12: exp_sh_r = afp_body >> 12;  // E=3
            4'd11: exp_sh_r = afp_body >> 11;  // E=4
            4'd10: exp_sh_r = afp_body >> 10;  // E=5
            4'd9:  exp_sh_r = afp_body >> 9;   // E=6
            4'd8:  exp_sh_r = afp_body >> 8;   // E=7
            4'd7:  exp_sh_r = afp_body >> 7;   // E=8
            default: exp_sh_r = afp_body >> 11;
        endcase
    end

    // Mask to exp_bits width
    reg [7:0] exp_mask_r;
    always @(*) begin
        case (e_bits_r)
            4'd2: exp_mask_r = 8'h03;
            4'd3: exp_mask_r = 8'h07;
            4'd4: exp_mask_r = 8'h0F;
            4'd5: exp_mask_r = 8'h1F;
            4'd6: exp_mask_r = 8'h3F;
            4'd7: exp_mask_r = 8'h7F;
            4'd8: exp_mask_r = 8'hFF;
            default: exp_mask_r = 8'h0F;
        endcase
    end

    assign exp_out = exp_sh_r[7:0] & exp_mask_r;

    // -------------------------------------------------------------------------
    // Fraction field: lower frac_bits bits of afp_body
    // -------------------------------------------------------------------------
    reg [12:0] frac_r;
    always @(*) begin
        case (frac_bits)
            4'd13: frac_r = afp_body[12:0];
            4'd12: frac_r = {1'b0,  afp_body[11:0]};
            4'd11: frac_r = {2'b0,  afp_body[10:0]};
            4'd10: frac_r = {3'b0,  afp_body[9:0]};
            4'd9:  frac_r = {4'b0,  afp_body[8:0]};
            4'd8:  frac_r = {5'b0,  afp_body[7:0]};
            4'd7:  frac_r = {6'b0,  afp_body[6:0]};
            default: frac_r = {2'b0, afp_body[10:0]};
        endcase
    end
    assign frac_out = frac_r;

    // -------------------------------------------------------------------------
    // Special cases
    // -------------------------------------------------------------------------
    wire exp_all_ones = (exp_out == exp_mask_r);
    wire frac_nonzero = |frac_out;
    wire exp_all_zero = ~(|exp_out);

    assign is_nan  = exp_all_ones & frac_nonzero;
    assign is_inf  = exp_all_ones & ~frac_nonzero;
    assign is_zero = exp_all_zero & ~frac_nonzero;

    // -------------------------------------------------------------------------
    // Decode to Q8.13 (22-bit signed, scale=8192=2^13)
    // mantissa = {leading_one, frac_out} in Q1.F format
    // actual_exp = exp_out - bias (signed)
    // value = (-1)^sign * 2^actual_exp * 1.frac_out
    //
    // In Q8.13: mantissa at bit position 13 (implicit 1 is at scale 2^13)
    // Shift by actual_exp to place value.
    //
    // For subnormal (exp=0): leading_one=0, actual_exp = -(bias) but we use -(bias-1)
    //   to maintain correct subnormal representation.
    //
    // R-SI-1: barrel shifts, no multiplication.
    // -------------------------------------------------------------------------
    wire        leading_one = ~exp_all_zero;
    // Extend mantissa: {leading_one, frac[12:0]} = 14 bits max, placed at Q8.13
    wire [13:0] mantissa14  = {leading_one, frac_out};

    // actual_exp = exp_out - bias (signed 9-bit)
    wire signed [8:0] actual_exp_s = $signed({1'b0, exp_out}) - $signed({1'b0, bias});

    wire        act_neg   = actual_exp_s[8];
    wire [7:0]  shift_amt = act_neg ? (~actual_exp_s[7:0] + 8'd1) : actual_exp_s[7:0];

    // Extend mantissa into 28-bit working register for shifting
    wire [27:0] mant_ext = {14'b0, mantissa14};

    reg [27:0] shifted;
    always @(*) begin
        if (is_nan | is_inf | is_zero)
            shifted = 28'd0;
        else if (act_neg) begin
            // Shift right
            case (shift_amt[3:0])
                4'd0: shifted = mant_ext;
                4'd1: shifted = mant_ext >> 1;
                4'd2: shifted = mant_ext >> 2;
                4'd3: shifted = mant_ext >> 3;
                4'd4: shifted = mant_ext >> 4;
                4'd5: shifted = mant_ext >> 5;
                4'd6: shifted = mant_ext >> 6;
                4'd7: shifted = mant_ext >> 7;
                default: shifted = 28'd0;
            endcase
        end else begin
            // Shift left
            case (shift_amt[3:0])
                4'd0:  shifted = mant_ext;
                4'd1:  shifted = mant_ext << 1;
                4'd2:  shifted = mant_ext << 2;
                4'd3:  shifted = mant_ext << 3;
                4'd4:  shifted = mant_ext << 4;
                4'd5:  shifted = mant_ext << 5;
                4'd6:  shifted = mant_ext << 6;
                4'd7:  shifted = mant_ext << 7;
                4'd8:  shifted = mant_ext << 8;
                default: shifted = mant_ext;
            endcase
        end
    end

    wire [21:0] mag_q813 = shifted[21:0];
    wire [21:0] neg_q813 = (~mag_q813) + 22'd1;
    assign decoded_q813  = sign_out ? $signed(neg_q813) : $signed(mag_q813);

endmodule

`default_nettype wire
