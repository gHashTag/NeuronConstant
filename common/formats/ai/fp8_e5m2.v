// fp8_e5m2.v — FP8 (1 sign + 5 exponent + 2 mantissa) decode/encode
// Hopper H100 high-range FP8 variant.
// IEEE-like with bias=15. Range ±57344. NaN: exp=11111, mant≠00.
//
// Decode: 8-bit FP8 → 16-bit signed fixed-point (Q9.6, ×64)
// Encode: 16-bit signed fixed-point (Q9.6, ×64) → 8-bit FP8
//
// Verilog-2005, R-SI-1 compliant (no standalone *)
`default_nettype none

module fp8_e5m2 (
    // Decode
    input  wire [7:0]  dec_fp8,   // FP8-E5M2 input
    output reg  [15:0] dec_s16,   // signed int16 output (Q9.6, ×64)
    output reg         dec_nan,   // 1 = NaN

    // Encode
    input  wire [15:0] enc_s16,   // signed int16 input (Q9.6, ×64)
    output reg  [7:0]  enc_fp8    // FP8-E5M2 output
);

    // ----------------------------------------------------------------
    // Decode
    wire        sign_d = dec_fp8[7];
    wire [4:0]  exp_d  = dec_fp8[6:2];
    wire [1:0]  mant_d = dec_fp8[1:0];

    // Bias = 15 (5-bit exponent: 2^4 - 1 = 15)
    wire is_nan  = (exp_d == 5'h1F) && (mant_d != 2'b00);
    wire is_inf  = (exp_d == 5'h1F) && (mant_d == 2'b00); // treat as max
    wire is_zero = (exp_d == 5'h00) && (mant_d == 2'b00);
    wire is_sub  = (exp_d == 5'h00) && (mant_d != 2'b00);

    // full_mant_d: {implicit_1, mant_d} = 3-bit
    wire [2:0] full_mant_d = is_sub ? {1'b0, mant_d} : {1'b1, mant_d};

    // Unbiased exponent (signed 6-bit): exp_d - 15
    wire signed [5:0] unbiased = {1'b0, exp_d} - 6'sd15;

    // Decode abs value in Q9.6 (×64):
    // abs_val = full_mant_d × 2^(unbiased - 2)
    // shift = unbiased - 2 + 6 = unbiased + 4
    reg [19:0] abs_val_r;
    always @(*) begin
        if (is_nan || is_zero) begin
            abs_val_r = 20'd0;
        end else if (is_sub) begin
            // value = mant_d × 2^(-14) in real; in Q9.6: × 2^(-8) → ≈0
            abs_val_r = {18'h00000, mant_d};
        end else if (is_inf || unbiased >= 6'sd9) begin
            abs_val_r = 20'd32767; // clamp
        end else if (unbiased < -6'sd6) begin
            abs_val_r = 20'd0;
        end else begin
            // shift = unbiased + 4
            case (unbiased)
                -6'sd6: abs_val_r = {17'h00000, full_mant_d} >> 2;
                -6'sd5: abs_val_r = {17'h00000, full_mant_d} >> 1;
                -6'sd4: abs_val_r = {17'h00000, full_mant_d};
                -6'sd3: abs_val_r = {16'h0000,  full_mant_d, 1'b0};
                -6'sd2: abs_val_r = {15'h0000,  full_mant_d, 2'b00};
                -6'sd1: abs_val_r = {14'h0000,  full_mant_d, 3'b000};
                 6'sd0: abs_val_r = {13'h0000,  full_mant_d, 4'h0};
                 6'sd1: abs_val_r = {12'h000,   full_mant_d, 5'h00};
                 6'sd2: abs_val_r = {11'h000,   full_mant_d, 6'h00};
                 6'sd3: abs_val_r = {10'h000,   full_mant_d, 7'h00};
                 6'sd4: abs_val_r = {9'h000,    full_mant_d, 8'h00};
                 6'sd5: abs_val_r = {8'h00,     full_mant_d, 9'h000};
                 6'sd6: abs_val_r = {7'h00,     full_mant_d, 10'h000};
                 6'sd7: abs_val_r = {6'h00,     full_mant_d, 11'h000};
                 6'sd8: abs_val_r = {5'h00,     full_mant_d, 12'h000};
                default: abs_val_r = 20'd0;
            endcase
        end
    end

    wire [15:0] abs_val16  = abs_val_r[15:0];
    wire [15:0] signed_val = sign_d ? (~abs_val16 + 16'd1) : abs_val16;

    always @(*) begin
        dec_nan = is_nan;
        dec_s16 = is_nan ? 16'h0000 : signed_val;
    end

    // ----------------------------------------------------------------
    // Encode: Q9.6 int16 → FP8-E5M2
    wire [15:0] enc_abs_v = enc_s16[15] ? (~enc_s16 + 16'd1) : enc_s16;

    reg [4:0] exp_enc;
    reg [1:0] mant_enc;

    always @(*) begin
        casez (enc_abs_v[14:0])
            15'b1??????????????: begin exp_enc = 5'd14 + 5'd15; mant_enc = enc_abs_v[13:12]; end
            15'b01?????????????: begin exp_enc = 5'd13 + 5'd15; mant_enc = enc_abs_v[12:11]; end
            15'b001????????????: begin exp_enc = 5'd12 + 5'd15; mant_enc = enc_abs_v[11:10]; end
            15'b0001???????????: begin exp_enc = 5'd11 + 5'd15; mant_enc = enc_abs_v[10:9];  end
            15'b00001??????????: begin exp_enc = 5'd10 + 5'd15; mant_enc = enc_abs_v[9:8];   end
            15'b000001?????????: begin exp_enc = 5'd9  + 5'd15; mant_enc = enc_abs_v[8:7];   end
            15'b0000001????????: begin exp_enc = 5'd8  + 5'd15; mant_enc = enc_abs_v[7:6];   end
            15'b00000001???????: begin exp_enc = 5'd7  + 5'd15; mant_enc = enc_abs_v[6:5];   end
            15'b000000001??????: begin exp_enc = 5'd6  + 5'd15; mant_enc = enc_abs_v[5:4];   end
            15'b0000000001?????: begin exp_enc = 5'd5  + 5'd15; mant_enc = enc_abs_v[4:3];   end
            15'b00000000001????: begin exp_enc = 5'd4  + 5'd15; mant_enc = enc_abs_v[3:2];   end
            15'b000000000001???: begin exp_enc = 5'd3  + 5'd15; mant_enc = enc_abs_v[2:1];   end
            15'b0000000000001??: begin exp_enc = 5'd2  + 5'd15; mant_enc = enc_abs_v[1:0];   end
            15'b00000000000001?: begin exp_enc = 5'd1  + 5'd15; mant_enc = {enc_abs_v[0], 1'b0}; end
            default:             begin exp_enc = 5'd0;          mant_enc = 2'b00; end
        endcase
        // clamp exponent to max non-Inf (30)
        if (exp_enc >= 5'd31) begin
            exp_enc  = 5'd30;
            mant_enc = 2'b11;
        end
    end

    always @(*) begin
        enc_fp8 = {enc_s16[15], exp_enc, mant_enc};
    end

endmodule
`default_nettype wire
