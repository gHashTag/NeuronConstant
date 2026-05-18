// posit64_decode.v — Posit<64,3> decoder
//
// Posit<64,3> format:
//   bit 63   : sign
//   bits 62:? : regime (unary run)
//   3 bits   : exponent (ES=3)
//   remaining: mantissa fraction (up to 56 bits)
//
// Special values:
//   0x0000000000000000 = exact zero
//   0x8000000000000000 = NaR
//
// Decode formula:
//   useed = 2^(2^3) = 256
//   value = (-1)^sign * 256^k * 2^exp * (1 + mant_frac)
//   total scale = 8*k + exp
//
// Verilog-2005, `default_nettype none, R-SI-1 compliant
`default_nettype none

module posit64_decode (
    input  wire [63:0]       p,
    output wire              sign,
    output reg  signed [7:0] regime_k,
    output reg  [2:0]        exp_3bit,
    output reg  [58:0]       mant_59bit,
    output wire              is_zero,
    output wire              is_nar
);

    assign is_zero = (p == 64'h0000000000000000);
    assign is_nar  = (p == 64'h8000000000000000);
    assign sign    = p[63];

    wire [62:0] mag = sign ? (~p[62:0] + 63'd1) : p[62:0];
    wire rbit = mag[62];

    reg [5:0] rlen;

    always @(*) begin
        casez (mag[62:46])
            17'b1_0???_????_????_????: begin regime_k =  8'sd0;  rlen = 6'd2;  end
            17'b1_10??_????_????_????: begin regime_k =  8'sd1;  rlen = 6'd3;  end
            17'b1_110?_????_????_????: begin regime_k =  8'sd2;  rlen = 6'd4;  end
            17'b1_1110_????_????_????: begin regime_k =  8'sd3;  rlen = 6'd5;  end
            17'b1_1111_0???_????_????: begin regime_k =  8'sd4;  rlen = 6'd6;  end
            17'b1_1111_10??_????_????: begin regime_k =  8'sd5;  rlen = 6'd7;  end
            17'b1_1111_110?_????_????: begin regime_k =  8'sd6;  rlen = 6'd8;  end
            17'b1_1111_1110_????_????: begin regime_k =  8'sd7;  rlen = 6'd9;  end
            17'b1_1111_1111_0???_????: begin regime_k =  8'sd8;  rlen = 6'd10; end
            17'b1_1111_1111_10??_????: begin regime_k =  8'sd9;  rlen = 6'd11; end
            17'b1_1111_1111_110?_????: begin regime_k =  8'sd10; rlen = 6'd12; end
            17'b1_1111_1111_1110_????: begin regime_k =  8'sd11; rlen = 6'd13; end
            17'b1_1111_1111_1111_0???: begin regime_k =  8'sd12; rlen = 6'd14; end
            17'b1_1111_1111_1111_10??: begin regime_k =  8'sd13; rlen = 6'd15; end
            17'b1_1111_1111_1111_110?: begin regime_k =  8'sd14; rlen = 6'd16; end
            17'b1_1111_1111_1111_1110: begin regime_k =  8'sd15; rlen = 6'd17; end
            17'b1_1111_1111_1111_1111: begin regime_k =  8'sd16; rlen = 6'd18; end
            17'b0_1???_????_????_????: begin regime_k = -8'sd1;  rlen = 6'd2;  end
            17'b0_01??_????_????_????: begin regime_k = -8'sd2;  rlen = 6'd3;  end
            17'b0_001?_????_????_????: begin regime_k = -8'sd3;  rlen = 6'd4;  end
            17'b0_0001_????_????_????: begin regime_k = -8'sd4;  rlen = 6'd5;  end
            17'b0_0000_1???_????_????: begin regime_k = -8'sd5;  rlen = 6'd6;  end
            17'b0_0000_01??_????_????: begin regime_k = -8'sd6;  rlen = 6'd7;  end
            17'b0_0000_001?_????_????: begin regime_k = -8'sd7;  rlen = 6'd8;  end
            17'b0_0000_0001_????_????: begin regime_k = -8'sd8;  rlen = 6'd9;  end
            17'b0_0000_0000_1???_????: begin regime_k = -8'sd9;  rlen = 6'd10; end
            17'b0_0000_0000_01??_????: begin regime_k = -8'sd10; rlen = 6'd11; end
            17'b0_0000_0000_001?_????: begin regime_k = -8'sd11; rlen = 6'd12; end
            17'b0_0000_0000_0001_????: begin regime_k = -8'sd12; rlen = 6'd13; end
            17'b0_0000_0000_0000_1???: begin regime_k = -8'sd13; rlen = 6'd14; end
            17'b0_0000_0000_0000_01??: begin regime_k = -8'sd14; rlen = 6'd15; end
            17'b0_0000_0000_0000_001?: begin regime_k = -8'sd15; rlen = 6'd16; end
            17'b0_0000_0000_0000_0001: begin regime_k = -8'sd16; rlen = 6'd17; end
            default:                   begin regime_k = -8'sd16; rlen = 6'd18; end
        endcase
    end

    wire [62:0] after_regime = mag << rlen;

    always @(*) begin
        if (is_zero || is_nar) begin
            exp_3bit   = 3'b000;
            mant_59bit = 59'b0;
        end else begin
            exp_3bit   = after_regime[62:60];
            mant_59bit = after_regime[59:1];
        end
    end

endmodule
`default_nettype wire
