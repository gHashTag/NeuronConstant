// posit16_add.v — Posit<16,1> addition (simplified decode → compute → encode)
// Posit format: 1 sign bit + regime (run-length coded) + 1 exponent bit + fraction
//
// Decode strategy: convert both operands to a common 32-bit fixed-point
// representation (Q16.15), add, then re-encode to Posit<16,1>.
//
// Posit<16,1> decode:
//   - If p == 0x0000: value = 0
//   - If p == 0x8000: value = NaR (Not-a-Real)
//   - Otherwise: decode regime (leading run of same-sign bits after sign bit),
//     extract exponent bit (es=1), extract fraction.
//
// Verilog-2005, R-SI-1 compliant (no standalone *)
`default_nettype none

module posit16_add (
    input  wire [15:0] a,        // Posit<16,1> operand A
    input  wire [15:0] b,        // Posit<16,1> operand B
    output reg  [15:0] result,   // Posit<16,1> sum
    output reg         nar_out   // 1 = NaR (propagated from input)
);

    // ----------------------------------------------------------------
    // Constants
    localparam NAR  = 16'h8000;
    localparam ZERO = 16'h0000;

    // ----------------------------------------------------------------
    // Posit decode function (combinational): posit → Q16.15 signed fixed
    // Returns 32-bit signed fixed-point (Q16.15) and nar flag.
    //
    // Algorithm:
    //   1. Handle zero / NaR
    //   2. 2's-complement negative: twos-complement to get positive magnitude
    //   3. Decode regime: count leading 1s (if MSB after sign=1) or 0s (if 0)
    //      regime value k = (run of 1s) - 1  or  k = -(run of 0s)
    //   4. useed = 2^(2^es) = 2^2 = 4 for es=1
    //   5. scale = useed^k * 2^exp = 4^k * 2^exp = 2^(2k+exp)
    //   6. value = scale * (1 + fraction)
    // ----------------------------------------------------------------

    // --- Decode A ---
    wire        sign_a  = a[15];
    wire [14:0] mag_a   = sign_a ? (~a[14:0] + 15'd1) : a[14:0];

    // Count leading 1s in mag_a[14:8] (up to 8) to find regime
    // regime_bit = mag_a[14]: 1→ positive regime (run of 1s), 0→ negative (run of 0s)
    wire rbit_a = mag_a[14];

    // Count regime run length (max 14 bits including terminator)
    reg [3:0] regime_len_a;   // number of bits in regime run (including terminator)
    reg signed [4:0] k_a;     // regime value
    always @(*) begin
        casez ({rbit_a, mag_a[13:7]})
            // rbit=1: count leading 1s in [13:7] after position 14
            8'b1111_1111: begin k_a =  5'sd7; regime_len_a = 4'd9; end
            8'b1111_1110: begin k_a =  5'sd6; regime_len_a = 4'd8; end
            8'b1111_110?: begin k_a =  5'sd5; regime_len_a = 4'd7; end
            8'b1111_10??: begin k_a =  5'sd4; regime_len_a = 4'd6; end
            8'b1111_0???: begin k_a =  5'sd3; regime_len_a = 4'd5; end
            8'b1110_????: begin k_a =  5'sd2; regime_len_a = 4'd4; end
            8'b110?_????: begin k_a =  5'sd1; regime_len_a = 4'd3; end
            8'b10??_????: begin k_a =  5'sd0; regime_len_a = 4'd2; end
            // rbit=0: count leading 0s
            8'b0000_0000: begin k_a = -5'sd7; regime_len_a = 4'd9; end
            8'b0000_0001: begin k_a = -5'sd6; regime_len_a = 4'd8; end
            8'b0000_001?: begin k_a = -5'sd5; regime_len_a = 4'd7; end
            8'b0000_01??: begin k_a = -5'sd4; regime_len_a = 4'd6; end
            8'b0000_1???: begin k_a = -5'sd3; regime_len_a = 4'd5; end
            8'b0001_????: begin k_a = -5'sd2; regime_len_a = 4'd4; end
            8'b001?_????: begin k_a = -5'sd1; regime_len_a = 4'd3; end
            default:      begin k_a =  5'sd0; regime_len_a = 4'd2; end
        endcase
    end

    // Extract exponent bit and fraction from remaining bits after regime
    // Remaining bits start at position (14 - regime_len_a)
    // For posit16: after sign(1) + regime(regime_len_a), exp at next bit, then fraction
    // We use a shifted version of mag_a
    wire [14:0] after_regime_a = mag_a << regime_len_a;
    wire        exp_a   = after_regime_a[14];
    wire [12:0] frac_a  = after_regime_a[13:1];

    // Scale = 2^(2*k + exp)  [useed=4, es=1]
    wire signed [5:0] scale_a = {k_a[4], k_a} + {5'd0, exp_a};  // 2*k + exp, approximate: use k<<1 + exp
    // 2*k: left shift
    wire signed [5:0] twok_a  = {k_a, 1'b0};  // k*2
    wire signed [5:0] total_scale_a = twok_a + {{5{1'b0}}, exp_a};

    // Fixed-point value = (1 + frac/2^13) * 2^scale, stored in Q16.15
    // = (2^13 + frac) << (scale - 13 + 15)  in 32-bit
    // = (2^13 + frac) << (scale + 2) if scale+2 >= 0
    wire [13:0] sig_a = {1'b1, frac_a};   // 1.fraction in 14-bit (1 + 13 frac bits)

    // Compute Q16.15 representation: shift sig_a to align
    // bit weight of MSB (implicit 1) in Q16.15 = 2^(total_scale_a)
    // MSB of sig_a is bit 13, so shift = total_scale_a - 13 + 15 = total_scale_a + 2
    // (since Q16.15 bit 15 = 2^0 integer part)
    wire signed [5:0] shift_a = total_scale_a + 6'sd2;

    reg [31:0] fixed_a;
    always @(*) begin
        if (shift_a >= 6'sd16)      fixed_a = 32'h7FFF0000; // overflow/clamp
        else if (shift_a >= 6'sd0)  fixed_a = {18'h0, sig_a} << shift_a[4:0];
        else if (shift_a >= -6'sd13) fixed_a = {18'h0, sig_a} >> (-shift_a[4:0]);
        else                         fixed_a = 32'h0;
    end

    wire [31:0] fixed_a_signed = sign_a ? (~fixed_a + 32'd1) : fixed_a;

    // --- Decode B (same logic) ---
    wire        sign_b  = b[15];
    wire [14:0] mag_b   = sign_b ? (~b[14:0] + 15'd1) : b[14:0];
    wire rbit_b = mag_b[14];

    reg [3:0] regime_len_b;
    reg signed [4:0] k_b;
    always @(*) begin
        casez ({rbit_b, mag_b[13:7]})
            8'b1111_1111: begin k_b =  5'sd7; regime_len_b = 4'd9; end
            8'b1111_1110: begin k_b =  5'sd6; regime_len_b = 4'd8; end
            8'b1111_110?: begin k_b =  5'sd5; regime_len_b = 4'd7; end
            8'b1111_10??: begin k_b =  5'sd4; regime_len_b = 4'd6; end
            8'b1111_0???: begin k_b =  5'sd3; regime_len_b = 4'd5; end
            8'b1110_????: begin k_b =  5'sd2; regime_len_b = 4'd4; end
            8'b110?_????: begin k_b =  5'sd1; regime_len_b = 4'd3; end
            8'b10??_????: begin k_b =  5'sd0; regime_len_b = 4'd2; end
            8'b0000_0000: begin k_b = -5'sd7; regime_len_b = 4'd9; end
            8'b0000_0001: begin k_b = -5'sd6; regime_len_b = 4'd8; end
            8'b0000_001?: begin k_b = -5'sd5; regime_len_b = 4'd7; end
            8'b0000_01??: begin k_b = -5'sd4; regime_len_b = 4'd6; end
            8'b0000_1???: begin k_b = -5'sd3; regime_len_b = 4'd5; end
            8'b0001_????: begin k_b = -5'sd2; regime_len_b = 4'd4; end
            8'b001?_????: begin k_b = -5'sd1; regime_len_b = 4'd3; end
            default:      begin k_b =  5'sd0; regime_len_b = 4'd2; end
        endcase
    end

    wire [14:0] after_regime_b = mag_b << regime_len_b;
    wire        exp_b   = after_regime_b[14];
    wire [12:0] frac_b  = after_regime_b[13:1];

    wire signed [5:0] twok_b       = {k_b, 1'b0};
    wire signed [5:0] total_scale_b = twok_b + {{5{1'b0}}, exp_b};

    wire [13:0] sig_b = {1'b1, frac_b};
    wire signed [5:0] shift_b = total_scale_b + 6'sd2;

    reg [31:0] fixed_b;
    always @(*) begin
        if (shift_b >= 6'sd16)       fixed_b = 32'h7FFF0000;
        else if (shift_b >= 6'sd0)   fixed_b = {18'h0, sig_b} << shift_b[4:0];
        else if (shift_b >= -6'sd13) fixed_b = {18'h0, sig_b} >> (-shift_b[4:0]);
        else                          fixed_b = 32'h0;
    end

    wire [31:0] fixed_b_signed = sign_b ? (~fixed_b + 32'd1) : fixed_b;

    // --- Fixed-point addition ---
    wire signed [31:0] sum_fixed = $signed(fixed_a_signed) + $signed(fixed_b_signed);

    // --- Encode fixed → Posit<16,1> ---
    // Extract sign, magnitude, find leading bit, build regime/exp/frac
    wire        sum_sign = sum_fixed[31];
    wire [30:0] sum_mag  = sum_sign ? (~sum_fixed[30:0] + 31'd1) : sum_fixed[30:0];

    // Find leading-one in sum_mag[30:0] → determines scale
    reg [4:0] lead_pos;
    always @(*) begin
        casez (sum_mag[30:16])
            15'b1??????????????: lead_pos = 5'd30;
            15'b01?????????????: lead_pos = 5'd29;
            15'b001????????????: lead_pos = 5'd28;
            15'b0001???????????: lead_pos = 5'd27;
            15'b00001??????????: lead_pos = 5'd26;
            15'b000001?????????: lead_pos = 5'd25;
            15'b0000001????????: lead_pos = 5'd24;
            15'b00000001???????: lead_pos = 5'd23;
            15'b000000001??????: lead_pos = 5'd22;
            15'b0000000001?????: lead_pos = 5'd21;
            15'b00000000001????: lead_pos = 5'd20;
            15'b000000000001???: lead_pos = 5'd19;
            15'b0000000000001??: lead_pos = 5'd18;
            15'b00000000000001?: lead_pos = 5'd17;
            default:             lead_pos = 5'd16;
        endcase
    end

    // scale = lead_pos - 15 (since bit 15 in Q16.15 = 2^0)
    wire signed [5:0] scale_out = {1'b0, lead_pos} - 6'sd15;
    // k_out = scale_out >> 1, exp_out = scale_out[0]
    wire signed [4:0] k_out   = scale_out[5:1];  // arithmetic right shift
    wire              exp_out  = scale_out[0];

    // Build regime field:
    // k >= 0: (k+1) ones followed by a zero → k+2 bits total
    // k < 0:  |k| zeros followed by a one  → |k|+1 bits total
    reg [14:0] posit_body;  // bits [14:0] of the posit word

    // Simplified encode: pack regime bits + exp bit + fraction
    wire [12:0] frac_out = sum_mag[lead_pos-1 -: 13];  // 13 fraction bits after leading 1

    // Regime packing (up to 8 regime bits, 1 exp bit, remaining = fraction)
    reg [14:0] regime_bits;
    reg [3:0]  reg_len_out;
    wire [4:0] abs_k_out = k_out[4] ? (~k_out + 5'd1) : {1'b0, k_out[3:0]};

    always @(*) begin
        if (k_out >= 5'sd7) begin
            // All 15 bits are regime
            regime_bits = 15'b111_1111_1111_1111;
            reg_len_out = 4'd15;
        end else if (k_out >= 5'sd0) begin
            // k+1 ones + terminator 0
            case (k_out[3:0])
                4'd0: begin regime_bits = 15'b100_0000_0000_0000; reg_len_out = 4'd2; end
                4'd1: begin regime_bits = 15'b110_0000_0000_0000; reg_len_out = 4'd3; end
                4'd2: begin regime_bits = 15'b111_0000_0000_0000; reg_len_out = 4'd4; end
                4'd3: begin regime_bits = 15'b111_1000_0000_0000; reg_len_out = 4'd5; end
                4'd4: begin regime_bits = 15'b111_1100_0000_0000; reg_len_out = 4'd6; end
                4'd5: begin regime_bits = 15'b111_1110_0000_0000; reg_len_out = 4'd7; end
                4'd6: begin regime_bits = 15'b111_1111_0000_0000; reg_len_out = 4'd8; end
                default: begin regime_bits = 15'b111_1111_1000_0000; reg_len_out = 4'd9; end
            endcase
        end else begin
            // |k| zeros + terminator 1
            case (abs_k_out[3:0])
                4'd1: begin regime_bits = 15'b010_0000_0000_0000; reg_len_out = 4'd2; end
                4'd2: begin regime_bits = 15'b001_0000_0000_0000; reg_len_out = 4'd3; end
                4'd3: begin regime_bits = 15'b000_1000_0000_0000; reg_len_out = 4'd4; end
                4'd4: begin regime_bits = 15'b000_0100_0000_0000; reg_len_out = 4'd5; end
                4'd5: begin regime_bits = 15'b000_0010_0000_0000; reg_len_out = 4'd6; end
                4'd6: begin regime_bits = 15'b000_0001_0000_0000; reg_len_out = 4'd7; end
                4'd7: begin regime_bits = 15'b000_0000_1000_0000; reg_len_out = 4'd8; end
                default: begin regime_bits = 15'b000_0000_0100_0000; reg_len_out = 4'd9; end
            endcase
        end
    end

    // Combine: regime_bits | (exp_out << (14 - reg_len_out)) | (frac >> (reg_len_out+1))
    wire [14:0] exp_placed  = {14'h0, exp_out} << (4'd14 - reg_len_out);
    wire [14:0] frac_placed = {frac_out, 2'b0} >> (reg_len_out + 4'd1);

    always @(*) begin
        nar_out = (a == NAR) || (b == NAR);
        if (nar_out) begin
            result = NAR;
        end else if ((a == ZERO) && (b == ZERO)) begin
            result = ZERO;
        end else if (a == ZERO) begin
            result = b;
        end else if (b == ZERO) begin
            result = a;
        end else if (sum_mag == 31'd0) begin
            result = ZERO;
        end else begin
            posit_body = regime_bits | exp_placed | frac_placed;
            result = {sum_sign, posit_body};
        end
    end

endmodule
`default_nettype wire
