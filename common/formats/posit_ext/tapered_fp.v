// tapered_fp.v — Tapered Floating Point (Morris/Gustafson variable-exponent format)
//
// Reference: John L. Gustafson "Beating Floating Point at its Own Game" (2017),
//            Robert Morris "Tapered Floating Point" (1971)
//
// Concept: Bits are allocated dynamically between exponent and mantissa depending
//          on magnitude. Large exponents use more bits (less precision), small
//          exponents leave more bits for mantissa (more precision near 1.0).
//
// This implementation: parameterized by WIDTH (default 16).
//   Bit layout:
//     bit [WIDTH-1]     : sign
//     bits [WIDTH-2:?]  : regime (unary, same encoding as Posit, ES=0 fixed)
//     remaining bits    : mantissa
//
//   ES=0 means no explicit exponent field — the regime directly encodes
//   the power of 2: value = (-1)^sign * 2^k * (1 + mant_frac)
//   This is the simplified Tapered FP per Gustafson's minimal variant.
//
//   Regime ≥ 2 bits always present:
//     k >= 0: (k+1) ones + 0 terminator   (k+2 bits)
//     k <  0: |k| zeros + 1 terminator   (|k|+1 bits)
//
// Parameters: WIDTH in {8, 16, 32} tested; other widths possible.
//
// Decode output: sign (1b), dec_k (8b signed), dec_mant (29b, MSB-aligned)
// Encode input: enc_sign, enc_k, enc_mant → WIDTH-bit TaperedFP
//
// Verilog-2005, `default_nettype none, R-SI-1 compliant
`default_nettype none

module tapered_fp #(
    parameter WIDTH = 16
) (
    // Decode
    input  wire [WIDTH-1:0]  tfp_in,
    output wire              dec_sign,
    output reg  signed [7:0] dec_k,
    output reg  [28:0]       dec_mant,   // 29-bit mantissa (MSB-aligned, zero-padded)
    output wire              dec_zero,
    output wire              dec_nar,

    // Encode
    input  wire              enc_sign,
    input  wire signed [7:0] enc_k,
    input  wire [28:0]       enc_mant,   // 29-bit mantissa input (MSB-aligned)
    input  wire              enc_zero,
    input  wire              enc_nar,
    output reg  [WIDTH-1:0]  tfp_out
);

    // ----------------------------------------------------------------
    // Decode
    assign dec_zero = (tfp_in == {WIDTH{1'b0}});
    assign dec_nar  = (tfp_in[WIDTH-1] && (tfp_in[WIDTH-2:0] == {(WIDTH-1){1'b0}}));
    assign dec_sign = tfp_in[WIDTH-1];

    // Magnitude: 2's complement when negative (WIDTH-1 bits)
    reg [WIDTH-2:0] mag;
    always @(*) begin
        if (dec_sign)
            mag = (~tfp_in[WIDTH-2:0] + {{(WIDTH-2){1'b0}}, 1'b1});
        else
            mag = tfp_in[WIDTH-2:0];
    end

    wire rbit = mag[WIDTH-2];

    // Regime decode: check top bits of mag
    reg [4:0] rlen_d;
    always @(*) begin
        casez ({rbit, mag[WIDTH-3: (WIDTH>11 ? WIDTH-11 : 0)]})
            // rbit=1: count consecutive 1s after bit [WIDTH-2]
            11'b1_111_1111_111: begin dec_k = 8'sd9;  rlen_d = 5'd11; end
            11'b1_111_1111_110: begin dec_k = 8'sd8;  rlen_d = 5'd10; end
            11'b1_111_1111_10?: begin dec_k = 8'sd7;  rlen_d = 5'd9;  end
            11'b1_111_1111_0??: begin dec_k = 8'sd6;  rlen_d = 5'd8;  end
            11'b1_111_110?_???: begin dec_k = 8'sd5;  rlen_d = 5'd7;  end
            11'b1_111_10??_???: begin dec_k = 8'sd4;  rlen_d = 5'd6;  end
            11'b1_111_0???_???: begin dec_k = 8'sd3;  rlen_d = 5'd5;  end
            11'b1_110_????_???: begin dec_k = 8'sd2;  rlen_d = 5'd4;  end
            11'b1_10?_????_???: begin dec_k = 8'sd1;  rlen_d = 5'd3;  end
            11'b1_0??_????_???: begin dec_k = 8'sd0;  rlen_d = 5'd2;  end
            // rbit=0: count consecutive 0s
            11'b0_000_0000_000: begin dec_k = -8'sd9; rlen_d = 5'd11; end
            11'b0_000_0000_001: begin dec_k = -8'sd8; rlen_d = 5'd10; end
            11'b0_000_0000_01?: begin dec_k = -8'sd7; rlen_d = 5'd9;  end
            11'b0_000_0000_1??: begin dec_k = -8'sd6; rlen_d = 5'd8;  end
            11'b0_000_001?_???: begin dec_k = -8'sd5; rlen_d = 5'd7;  end
            11'b0_000_01??_???: begin dec_k = -8'sd4; rlen_d = 5'd6;  end
            11'b0_000_1???_???: begin dec_k = -8'sd3; rlen_d = 5'd5;  end
            11'b0_001_????_???: begin dec_k = -8'sd2; rlen_d = 5'd4;  end
            11'b0_01?_????_???: begin dec_k = -8'sd1; rlen_d = 5'd3;  end
            default:             begin dec_k =  8'sd0; rlen_d = 5'd2;  end
        endcase
    end

    // Mantissa: remaining bits after regime (shifted up to 29 bits, MSB-aligned)
    reg [WIDTH-2:0] after_regime_d;
    always @(*) begin
        after_regime_d = mag << rlen_d;
        if (dec_zero || dec_nar)
            dec_mant = 29'b0;
        else begin
            // Pack into 29-bit MSB-aligned
            dec_mant = 29'b0;
            dec_mant[28: (29 - (WIDTH-1))] = after_regime_d[WIDTH-2:0];
        end
    end

    // ----------------------------------------------------------------
    // Encode
    // Clamp k to what fits in WIDTH
    // Max k for WIDTH: regime occupies at most WIDTH-1 bits → k_max = WIDTH-3
    wire signed [7:0] k_c;
    wire [6:0] k_max_pos = WIDTH[6:0] - 7'd3;
    wire [6:0] k_max_neg = WIDTH[6:0] - 7'd2;
    assign k_c = ($signed(enc_k) > $signed({1'b0, k_max_pos}))  ? {1'b0, k_max_pos} :
                 ($signed(enc_k) < $signed(-{1'b0, k_max_neg})) ? -{1'b0, k_max_neg} : enc_k;

    wire k_pos_e = ~k_c[7];
    wire [6:0] abs_k_e = k_c[7] ? (~k_c[6:0] + 7'd1) : k_c[6:0];
    wire [6:0] reg_len_e = k_pos_e ? (abs_k_e + 7'd2) : (abs_k_e + 7'd1);

    // Build regime in WIDTH-1 bits (left aligned)
    reg [WIDTH-2:0] regime_e;
    integer i;
    always @(*) begin
        regime_e = {(WIDTH-1){1'b0}};
        if (k_pos_e) begin
            for (i = 0; i < WIDTH-1; i = i + 1)
                if (i[6:0] <= abs_k_e)
                    regime_e[WIDTH-2-i] = 1'b1;
        end else begin
            if (abs_k_e < WIDTH[6:0] - 7'd1)
                regime_e[WIDTH-2 - abs_k_e] = 1'b1;
        end
    end

    // Mantissa placement: after regime, up to (WIDTH-1 - reg_len_e) bits
    // Use top WIDTH-1 bits of enc_mant (29-bit), shifted right by reg_len_e
    // enc_mant[28:0] MSB-aligned, we take top (WIDTH-1) bits → just enc_mant[28:30-WIDTH]
    // For WIDTH<=30: top_mant = enc_mant[28:30-WIDTH]  (WIDTH-1 bits)
    // Place these at position (WIDTH-2-reg_len_e) counting from top
    // → right-shift the (WIDTH-1)-bit value by reg_len_e positions
    wire [28:0] top_mant_full = enc_mant;
    reg [WIDTH-2:0] mant_e;
    always @(*) begin
        mant_e = {(WIDTH-1){1'b0}};
        if (reg_len_e < WIDTH[6:0] - 7'd1) begin
            // Take top (WIDTH-1) bits of enc_mant and shift right by reg_len_e
            mant_e = top_mant_full[28:30-WIDTH] >> reg_len_e[4:0];
        end
    end

    wire [WIDTH-2:0] mag_e = regime_e | mant_e;
    reg  [WIDTH-2:0] signed_mag_e;
    always @(*) begin
        if (enc_sign)
            signed_mag_e = ~mag_e + {{(WIDTH-2){1'b0}}, 1'b1};
        else
            signed_mag_e = mag_e;
    end

    always @(*) begin
        if (enc_nar)
            tfp_out = {1'b1, {(WIDTH-1){1'b0}}};
        else if (enc_zero)
            tfp_out = {WIDTH{1'b0}};
        else
            tfp_out = {enc_sign, signed_mag_e};
    end

endmodule
`default_nettype wire
