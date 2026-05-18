// SPDX-License-Identifier: MIT
// LNS8: Logarithmic Number System 8-bit
// Format: 1S + 7-bit log (two's complement fixed-point log2 value, Q3.4)
// Value = (-1)^S * 2^(log_val / 16.0)  [log stored as Q3.4 with scale=16]
// Advantage: multiplication becomes addition (R-SI-1 native)
// LUT: 128-entry log2 -> linear conversion
// Author: Dmitrii Vasilev (gHashTag)
`default_nettype none

// LNS8 decode: 8-bit LNS -> Q8.8 linear value
module lns8_decode (
    input  wire [7:0]  lns8_in,     // 1S + 7-bit log (Q3.4, signed)
    output reg  [15:0] result_q8    // Q8.8 signed output
);
    wire        sign_bit = lns8_in[7];
    wire [6:0]  log_bits = lns8_in[6:0];  // 7-bit unsigned log index

    // LUT: 128 entries, each entry = 2^(i/16) scaled to Q8.8
    // index i represents log2 value = (i - 48) / 16 (range approx -3 to +4.9375)
    // So 2^(i/16 - 3) = 2^(i/16) / 8
    // LUT[i] = round(2^((i-48)/16) * 256) clamped to 16 bits
    // We interpret log_bits as unsigned index 0..127

    reg [15:0] lut_val;
    reg [15:0] abs_val;

    // LUT implemented as combinational case
    always @(*) begin
        case (log_bits)
            7'd0:   lut_val = 16'h0020; // 2^(-3.000) * 256 = 32
            7'd1:   lut_val = 16'h0022; // 2^(-2.9375)
            7'd2:   lut_val = 16'h0023;
            7'd3:   lut_val = 16'h0025;
            7'd4:   lut_val = 16'h0027; // 2^(-2.75)
            7'd5:   lut_val = 16'h0029;
            7'd6:   lut_val = 16'h002B;
            7'd7:   lut_val = 16'h002D;
            7'd8:   lut_val = 16'h002D; // 2^(-2.5) ~ 45
            7'd9:   lut_val = 16'h0030;
            7'd10:  lut_val = 16'h0032;
            7'd11:  lut_val = 16'h0034;
            7'd12:  lut_val = 16'h0036; // 2^(-2.25)
            7'd13:  lut_val = 16'h0039;
            7'd14:  lut_val = 16'h003B;
            7'd15:  lut_val = 16'h003E;
            7'd16:  lut_val = 16'h0040; // 2^(-2.0) * 256 = 64
            7'd17:  lut_val = 16'h0043;
            7'd18:  lut_val = 16'h0046;
            7'd19:  lut_val = 16'h0049;
            7'd20:  lut_val = 16'h004D; // 2^(-1.75)
            7'd21:  lut_val = 16'h0050;
            7'd22:  lut_val = 16'h0054;
            7'd23:  lut_val = 16'h0057;
            7'd24:  lut_val = 16'h005B; // 2^(-1.5) ~ 91
            7'd25:  lut_val = 16'h005F;
            7'd26:  lut_val = 16'h0064;
            7'd27:  lut_val = 16'h0068;
            7'd28:  lut_val = 16'h006D; // 2^(-1.25)
            7'd29:  lut_val = 16'h0072;
            7'd30:  lut_val = 16'h0077;
            7'd31:  lut_val = 16'h007C;
            7'd32:  lut_val = 16'h0080; // 2^(-1.0) * 256 = 128
            7'd33:  lut_val = 16'h0086;
            7'd34:  lut_val = 16'h008C;
            7'd35:  lut_val = 16'h0092;
            7'd36:  lut_val = 16'h0099; // 2^(-0.75)
            7'd37:  lut_val = 16'h00A0;
            7'd38:  lut_val = 16'h00A8;
            7'd39:  lut_val = 16'h00B0;
            7'd40:  lut_val = 16'h00B5; // 2^(-0.5) ~ 181
            7'd41:  lut_val = 16'h00BE;
            7'd42:  lut_val = 16'h00C7;
            7'd43:  lut_val = 16'h00D1;
            7'd44:  lut_val = 16'h00DB; // 2^(-0.25)
            7'd45:  lut_val = 16'h00E6;
            7'd46:  lut_val = 16'h00F1;
            7'd47:  lut_val = 16'h00FB;
            7'd48:  lut_val = 16'h0100; // 2^(0.0) * 256 = 256 = 1.0 in Q8.8
            7'd49:  lut_val = 16'h010B;
            7'd50:  lut_val = 16'h0116;
            7'd51:  lut_val = 16'h0122;
            7'd52:  lut_val = 16'h012F; // 2^(0.25)
            7'd53:  lut_val = 16'h013C;
            7'd54:  lut_val = 16'h014A;
            7'd55:  lut_val = 16'h0159;
            7'd56:  lut_val = 16'h0169; // 2^(0.5)
            7'd57:  lut_val = 16'h0179;
            7'd58:  lut_val = 16'h018A;
            7'd59:  lut_val = 16'h019C;
            7'd60:  lut_val = 16'h01AF; // 2^(0.75)
            7'd61:  lut_val = 16'h01C3;
            7'd62:  lut_val = 16'h01D8;
            7'd63:  lut_val = 16'h01EE;
            7'd64:  lut_val = 16'h0200; // 2^(1.0) * 256 = 512 = 2.0 in Q8.8
            7'd65:  lut_val = 16'h0217;
            7'd66:  lut_val = 16'h022D;
            7'd67:  lut_val = 16'h0245;
            7'd68:  lut_val = 16'h025E; // 2^(1.25)
            7'd69:  lut_val = 16'h0278;
            7'd70:  lut_val = 16'h0294;
            7'd71:  lut_val = 16'h02B1;
            7'd72:  lut_val = 16'h02D4; // 2^(1.5)
            7'd73:  lut_val = 16'h02F8;
            7'd74:  lut_val = 16'h031F;
            7'd75:  lut_val = 16'h0347;
            7'd76:  lut_val = 16'h0372; // 2^(1.75)
            7'd77:  lut_val = 16'h039F;
            7'd78:  lut_val = 16'h03CE;
            7'd79:  lut_val = 16'h0400;
            7'd80:  lut_val = 16'h0400; // 2^(2.0) * 256 = 1024 = 4.0 in Q8.8
            7'd81:  lut_val = 16'h042E;
            7'd82:  lut_val = 16'h045A;
            7'd83:  lut_val = 16'h048A;
            7'd84:  lut_val = 16'h04BC; // 2^(2.25)
            7'd85:  lut_val = 16'h04F1;
            7'd86:  lut_val = 16'h0528;
            7'd87:  lut_val = 16'h0562;
            7'd88:  lut_val = 16'h05A8; // 2^(2.5)
            7'd89:  lut_val = 16'h05F1;
            7'd90:  lut_val = 16'h063D;
            7'd91:  lut_val = 16'h068E;
            7'd92:  lut_val = 16'h06E4; // 2^(2.75)
            7'd93:  lut_val = 16'h073E;
            7'd94:  lut_val = 16'h079C;
            7'd95:  lut_val = 16'h0800;
            7'd96:  lut_val = 16'h0800; // 2^(3.0) * 256 = 2048 = 8.0 in Q8.8
            7'd97:  lut_val = 16'h085C;
            7'd98:  lut_val = 16'h08B4;
            7'd99:  lut_val = 16'h0914;
            7'd100: lut_val = 16'h0978; // 2^(3.25)
            7'd101: lut_val = 16'h09E2;
            7'd102: lut_val = 16'h0A50;
            7'd103: lut_val = 16'h0AC4;
            7'd104: lut_val = 16'h0B50; // 2^(3.5)
            7'd105: lut_val = 16'h0BE2;
            7'd106: lut_val = 16'h0C7A;
            7'd107: lut_val = 16'h0D1C;
            7'd108: lut_val = 16'h0DC8; // 2^(3.75)
            7'd109: lut_val = 16'h0E7C;
            7'd110: lut_val = 16'h0F38;
            7'd111: lut_val = 16'h1000;
            7'd112: lut_val = 16'h1000; // 2^(4.0) * 256 = 16.0 in Q8.8
            7'd113: lut_val = 16'h10B8;
            7'd114: lut_val = 16'h1168;
            7'd115: lut_val = 16'h1228;
            7'd116: lut_val = 16'h12F0; // 2^(4.25)
            7'd117: lut_val = 16'h13C4;
            7'd118: lut_val = 16'h14A0;
            7'd119: lut_val = 16'h1588;
            7'd120: lut_val = 16'h16A0; // 2^(4.5)
            7'd121: lut_val = 16'h17C4;
            7'd122: lut_val = 16'h18F4;
            7'd123: lut_val = 16'h1A38;
            7'd124: lut_val = 16'h1B90; // 2^(4.75)
            7'd125: lut_val = 16'h1CF8;
            7'd126: lut_val = 16'h1E70;
            7'd127: lut_val = 16'hFFFF; // overflow / NaN
            default: lut_val = 16'h0000;
        endcase

        abs_val = lut_val;
        result_q8 = sign_bit ? (~abs_val + 16'h0001) : abs_val;
    end
endmodule

// LNS8 encode: Q8.8 linear -> LNS8
// Finds log2(abs_val) via leading-bit detection + interpolation
module lns8_encode (
    input  wire [15:0] val_q8,
    output reg  [7:0]  lns8_out
);
    wire        sign_bit = val_q8[15];
    wire [15:0] abs_val  = sign_bit ? (~val_q8 + 16'h0001) : val_q8;

    // Find log2 index: highest_bit gives integer part
    // log_index = (highest_bit - 8) * 16 + 48 + fractional_approx
    // fractional from next 4 bits below highest_bit

    always @(*) begin
        lns8_out = 8'h00;
        if (abs_val == 16'h0000) begin
            lns8_out = 8'h00;
        end else begin : enc_lns8
            reg [4:0]  hb;
            reg [3:0]  frac4;
            reg signed [7:0] log_idx;
            reg [7:0]  log_u;

            hb = 5'd0;
            if      (abs_val[15]) hb = 5'd15;
            else if (abs_val[14]) hb = 5'd14;
            else if (abs_val[13]) hb = 5'd13;
            else if (abs_val[12]) hb = 5'd12;
            else if (abs_val[11]) hb = 5'd11;
            else if (abs_val[10]) hb = 5'd10;
            else if (abs_val[9])  hb = 5'd9;
            else if (abs_val[8])  hb = 5'd8;
            else if (abs_val[7])  hb = 5'd7;
            else if (abs_val[6])  hb = 5'd6;
            else if (abs_val[5])  hb = 5'd5;
            else if (abs_val[4])  hb = 5'd4;
            else if (abs_val[3])  hb = 5'd3;
            else if (abs_val[2])  hb = 5'd2;
            else if (abs_val[1])  hb = 5'd1;
            else                  hb = 5'd0;

            // Extract 4 bits below hb for fractional part
            if (hb >= 5'd4)
                frac4 = abs_val[hb-5'd1 -: 4];
            else if (hb == 5'd3)
                frac4 = {abs_val[2:0], 1'b0};
            else if (hb == 5'd2)
                frac4 = {abs_val[1:0], 2'b00};
            else if (hb == 5'd1)
                frac4 = {abs_val[0], 3'b000};
            else
                frac4 = 4'b0000;

            // log_index = 48 + (hb-8)*16 + frac4
            // R-SI-1: use shift (<<4) instead of * for multiply by 16
            begin : lns8_shift
                reg signed [8:0] hb_adj;
                reg signed [8:0] hb_shift;
                hb_adj   = $signed({4'b0, hb}) - 9'sd8;
                hb_shift = hb_adj <<< 4;  // shift-left 4 = multiply by 16 (R-SI-1)
                log_idx  = 8'sd48 + hb_shift[7:0] + $signed({4'b0, frac4});
            end

            if (log_idx < 8'sd0)        log_u = 8'd0;
            else if (log_idx > 8'sd126) log_u = 8'd126;
            else                        log_u = log_idx[7:0];

            lns8_out = {sign_bit, log_u[6:0]};
        end
    end
endmodule
`default_nettype wire
