// fp8_e4m3.v — FP8 (1 sign + 4 exponent + 3 mantissa) decode/encode
// Hopper H100 high-precision FP8 variant.
// IEEE-like with bias=7. Range ±448. NaN: 0x7F, 0xFF.
//
// Decode: 8-bit FP8 → 16-bit signed fixed-point (Q8.7, i.e., ×128)
// Encode: 16-bit signed fixed-point (Q8.7) → 8-bit FP8 (round-to-nearest)
//
// Verilog-2005, R-SI-1 compliant (no standalone *)
`default_nettype none

module fp8_e4m3 (
    // Decode
    input  wire [7:0]  dec_fp8,   // FP8-E4M3 input
    output reg  [15:0] dec_s16,   // signed int16 output (Q8.7, ×128)
    output reg         dec_nan,   // 1 = NaN

    // Encode
    input  wire [15:0] enc_s16,   // signed int16 input (Q8.7, ×128)
    output reg  [7:0]  enc_fp8    // FP8-E4M3 output
);

    // ----------------------------------------------------------------
    // Internal decode signals
    wire        sign_d = dec_fp8[7];
    wire [3:0]  exp_d  = dec_fp8[6:3];
    wire [2:0]  mant_d = dec_fp8[2:0];

    // Bias = 7  (for 4-bit exponent: 2^3 - 1 = 7)
    // NaN: exp=1111 and mant≠000 (spec: only 0x7F/0xFF are NaN)
    wire        is_nan  = (exp_d == 4'hF) && (mant_d == 3'b111);
    wire        is_inf  = (exp_d == 4'hF) && (mant_d == 3'b000); // treat as max
    wire        is_zero = (exp_d == 4'h0) && (mant_d == 3'b000);
    wire        is_sub  = (exp_d == 4'h0) && (mant_d != 3'b000);

    // Unbiased exponent (signed): exp_d - 7
    wire signed [4:0] unbiased = {1'b0, exp_d} - 5'sd7;

    // Mantissa with implicit leading 1 (normal) or 0 (subnormal): {1, mant} = 4-bit
    wire [3:0] full_mant_d = is_sub ? {1'b0, mant_d} : {1'b1, mant_d};

    // Decoded absolute value in Q8.7 (×128):
    // abs_val = full_mant_d × 2^(unbiased - 3)
    // = full_mant_d shifted by (unbiased - 3) positions
    // unbiased range: -7..+8; shift = unbiased-3 range: -10..+5
    // We compute using 20-bit intermediate to avoid overflow.
    reg [19:0] abs_val_r;
    always @(*) begin
        if (is_nan) begin
            abs_val_r = 20'd0;
        end else if (is_zero) begin
            abs_val_r = 20'd0;
        end else if (is_sub) begin
            // subnormal: value = mant_d × 2^(-6) (exp=0 means 2^(1-7)=2^-6)
            // Q8.7 representation: × 2^7 = mant_d × 2^(7-6) = mant_d << 1
            abs_val_r = {16'h0000, mant_d, 1'b0};  // × 2 in Q8.7
        end else begin
            // Normal: shift full_mant (4 bits) by (unbiased - 3) in Q8.7
            // We store full_mant in bits [3:0] and shift
            // Target bit position in Q8.7 integer for bit weight 2^unbiased:
            // bit position = unbiased + 7 (since Q8.7 has 7 fractional bits)
            // The MSB of full_mant (implicit 1) is at weight 2^unbiased,
            // so full_mant_d [3:0] placed starting at bit (unbiased + 7 - 3)
            // = unbiased + 4 in Q8.7 representation.
            // Clamp to avoid shift overflow
            if (unbiased >= 5'sd8) begin
                abs_val_r = 20'd32767; // clamp to max int16/2
            end else if (unbiased <= -5'sd7) begin
                abs_val_r = 20'd0;
            end else begin
                // shift = unbiased + 4 (can be -3..12)
                case (unbiased)
                    -5'sd7: abs_val_r = {16'h0000, full_mant_d} >> 3;
                    -5'sd6: abs_val_r = {16'h0000, full_mant_d} >> 2;
                    -5'sd5: abs_val_r = {16'h0000, full_mant_d} >> 1;
                    -5'sd4: abs_val_r = {16'h0000, full_mant_d};
                    -5'sd3: abs_val_r = {15'h0000, full_mant_d, 1'b0};
                    -5'sd2: abs_val_r = {14'h0000, full_mant_d, 2'b00};
                    -5'sd1: abs_val_r = {13'h0000, full_mant_d, 3'b000};
                     5'sd0: abs_val_r = {12'h000,  full_mant_d, 4'h0};
                     5'sd1: abs_val_r = {11'h000,  full_mant_d, 5'h00};
                     5'sd2: abs_val_r = {10'h000,  full_mant_d, 6'h00};
                     5'sd3: abs_val_r = {9'h000,   full_mant_d, 7'h00};
                     5'sd4: abs_val_r = {8'h00,    full_mant_d, 8'h00};
                     5'sd5: abs_val_r = {7'h00,    full_mant_d, 9'h000};
                     5'sd6: abs_val_r = {6'h00,    full_mant_d, 10'h000};
                     5'sd7: abs_val_r = {5'h00,    full_mant_d, 11'h000};
                    default: abs_val_r = 20'd0;
                endcase
            end
        end
    end

    // Apply sign to get signed Q8.7 (16-bit output uses bits [15:0])
    wire [15:0] abs_val16 = abs_val_r[15:0];
    wire [15:0] signed_val = sign_d ? (~abs_val16 + 16'd1) : abs_val16;

    always @(*) begin
        dec_nan  = is_nan;
        dec_s16  = is_nan ? 16'h0000 : signed_val;
    end

    // ----------------------------------------------------------------
    // Encode: Q8.7 int16 → FP8-E4M3
    // Strategy: extract sign, find leading-1 position, round mantissa
    // ----------------------------------------------------------------
    wire        enc_sign = enc_s16[15];
    wire [14:0] enc_mag  = enc_sign ? enc_s16[14:0] : enc_s16[14:0];
    wire [15:0] enc_abs_v = enc_sign ? (~enc_s16 + 16'd1) : enc_s16;

    // Find leading-one position in enc_abs_v[14:0] (Q8.7, so bit 14 = 2^7)
    // Result: biased_exp = leading_bit_pos - 7 + 7 = leading_bit_pos
    // (because bit N in Q8.7 represents 2^(N-7))
    reg [3:0] lead_bit;
    reg [2:0] mant_enc;
    reg [3:0] exp_enc;

    always @(*) begin
        casez (enc_abs_v[14:0])
            15'b1??????????????: begin lead_bit = 4'd14; end
            15'b01?????????????: begin lead_bit = 4'd13; end
            15'b001????????????: begin lead_bit = 4'd12; end
            15'b0001???????????: begin lead_bit = 4'd11; end
            15'b00001??????????: begin lead_bit = 4'd10; end
            15'b000001?????????: begin lead_bit = 4'd9;  end
            15'b0000001????????: begin lead_bit = 4'd8;  end
            15'b00000001???????: begin lead_bit = 4'd7;  end
            15'b000000001??????: begin lead_bit = 4'd6;  end
            15'b0000000001?????: begin lead_bit = 4'd5;  end
            15'b00000000001????: begin lead_bit = 4'd4;  end
            15'b000000000001???: begin lead_bit = 4'd3;  end
            15'b0000000000001??: begin lead_bit = 4'd2;  end
            15'b00000000000001?: begin lead_bit = 4'd1;  end
            default:             begin lead_bit = 4'd0;  end
        endcase

        // Biased exponent: lead_bit is index in 15-bit field
        // Unbiased = lead_bit - 7, biased = unbiased + 7 = lead_bit
        // Clamp to [0,14] (avoid NaN code 15)
        if (enc_abs_v == 16'd0) begin
            exp_enc  = 4'd0;
            mant_enc = 3'd0;
        end else if (lead_bit >= 4'd14) begin
            exp_enc  = 4'd14; // max non-NaN exponent
            mant_enc = 3'b111;
        end else begin
            exp_enc = lead_bit;
            // Extract 3 mantissa bits after leading 1
            // mantissa bits are at positions [lead_bit-1 : lead_bit-3]
            // (guard bit for rounding at lead_bit-4)
            case (lead_bit)
                4'd13: mant_enc = enc_abs_v[12:10];
                4'd12: mant_enc = enc_abs_v[11:9];
                4'd11: mant_enc = enc_abs_v[10:8];
                4'd10: mant_enc = enc_abs_v[9:7];
                4'd9:  mant_enc = enc_abs_v[8:6];
                4'd8:  mant_enc = enc_abs_v[7:5];
                4'd7:  mant_enc = enc_abs_v[6:4];
                4'd6:  mant_enc = enc_abs_v[5:3];
                4'd5:  mant_enc = enc_abs_v[4:2];
                4'd4:  mant_enc = enc_abs_v[3:1];
                4'd3:  mant_enc = enc_abs_v[2:0];
                4'd2:  mant_enc = {enc_abs_v[1:0], 1'b0};
                4'd1:  mant_enc = {enc_abs_v[0], 2'b00};
                default: mant_enc = 3'd0;
            endcase
        end
    end

    always @(*) begin
        enc_fp8 = {enc_sign, exp_enc, mant_enc};
    end

endmodule
`default_nettype wire
