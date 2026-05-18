// posit32_decode.v — Posit<32,2> decoder
//
// Posit<32,2> format:
//   bit 31   : sign
//   bits 30:? : regime (unary run of equal bits, terminated by opposite bit)
//   2 bits   : exponent (ES=2)
//   remaining: mantissa fraction (up to 27 bits)
//
// Special values:
//   0x00000000 = exact zero (is_zero=1)
//   0x80000000 = NaR (is_nar=1)
//
// Posit<32,2> decode formula:
//   useed = 2^(2^2) = 16
//   value = (-1)^sign * 16^k * 2^exp * (1 + mant_frac)
//   total linear scale = 4*k + exp
//
// Regime decode:
//   rbit = mag[30] (first bit after sign in magnitude)
//   If rbit=1: count consecutive 1s from bit 30; k = run_length - 1
//   If rbit=0: count consecutive 0s from bit 30; k = -run_length
//   Terminator bit follows the run
//
// Verilog-2005, `default_nettype none, R-SI-1 compliant
`default_nettype none

module posit32_decode (
    input  wire [31:0]      p,
    output wire             sign,
    output reg  signed [6:0] regime_k,
    output reg  [1:0]       exp_2bit,
    output reg  [28:0]      mant_29bit,
    output wire             is_zero,
    output wire             is_nar
);

    assign is_zero = (p == 32'h00000000);
    assign is_nar  = (p == 32'h80000000);
    assign sign    = p[31];

    wire [30:0] mag = sign ? (~p[30:0] + 31'd1) : p[30:0];
    wire rbit = mag[30];

    reg [4:0] rlen;

    always @(*) begin
        casez ({rbit, mag[29:15]})
            16'b1_0??_????_????_????: begin regime_k =  7'sd0;  rlen = 5'd2;  end
            16'b1_10?_????_????_????: begin regime_k =  7'sd1;  rlen = 5'd3;  end
            16'b1_110_????_????_????: begin regime_k =  7'sd2;  rlen = 5'd4;  end
            16'b1_111_0???_????_????: begin regime_k =  7'sd3;  rlen = 5'd5;  end
            16'b1_111_10??_????_????: begin regime_k =  7'sd4;  rlen = 5'd6;  end
            16'b1_111_110?_????_????: begin regime_k =  7'sd5;  rlen = 5'd7;  end
            16'b1_111_1110_????_????: begin regime_k =  7'sd6;  rlen = 5'd8;  end
            16'b1_111_1111_0???_????: begin regime_k =  7'sd7;  rlen = 5'd9;  end
            16'b1_111_1111_10??_????: begin regime_k =  7'sd8;  rlen = 5'd10; end
            16'b1_111_1111_110?_????: begin regime_k =  7'sd9;  rlen = 5'd11; end
            16'b1_111_1111_1110_????: begin regime_k =  7'sd10; rlen = 5'd12; end
            16'b1_111_1111_1111_0???: begin regime_k =  7'sd11; rlen = 5'd13; end
            16'b1_111_1111_1111_10??: begin regime_k =  7'sd12; rlen = 5'd14; end
            16'b1_111_1111_1111_110?: begin regime_k =  7'sd13; rlen = 5'd15; end
            16'b1_111_1111_1111_1110: begin regime_k =  7'sd14; rlen = 5'd16; end
            16'b1_111_1111_1111_1111: begin regime_k =  7'sd15; rlen = 5'd17; end
            16'b0_1??_????_????_????: begin regime_k = -7'sd1;  rlen = 5'd2;  end
            16'b0_01?_????_????_????: begin regime_k = -7'sd2;  rlen = 5'd3;  end
            16'b0_001_????_????_????: begin regime_k = -7'sd3;  rlen = 5'd4;  end
            16'b0_000_1???_????_????: begin regime_k = -7'sd4;  rlen = 5'd5;  end
            16'b0_000_01??_????_????: begin regime_k = -7'sd5;  rlen = 5'd6;  end
            16'b0_000_001?_????_????: begin regime_k = -7'sd6;  rlen = 5'd7;  end
            16'b0_000_0001_????_????: begin regime_k = -7'sd7;  rlen = 5'd8;  end
            16'b0_000_0000_1???_????: begin regime_k = -7'sd8;  rlen = 5'd9;  end
            16'b0_000_0000_01??_????: begin regime_k = -7'sd9;  rlen = 5'd10; end
            16'b0_000_0000_001?_????: begin regime_k = -7'sd10; rlen = 5'd11; end
            16'b0_000_0000_0001_????: begin regime_k = -7'sd11; rlen = 5'd12; end
            16'b0_000_0000_0000_1???: begin regime_k = -7'sd12; rlen = 5'd13; end
            16'b0_000_0000_0000_01??: begin regime_k = -7'sd13; rlen = 5'd14; end
            16'b0_000_0000_0000_001?: begin regime_k = -7'sd14; rlen = 5'd15; end
            16'b0_000_0000_0000_0001: begin regime_k = -7'sd15; rlen = 5'd16; end
            default:                  begin regime_k = -7'sd15; rlen = 5'd17; end
        endcase
    end

    wire [30:0] after_regime = mag << rlen;

    always @(*) begin
        if (is_zero || is_nar) begin
            exp_2bit   = 2'b00;
            mant_29bit = 29'b0;
        end else begin
            exp_2bit   = after_regime[30:29];
            mant_29bit = after_regime[28:0];
        end
    end

endmodule
`default_nettype wire
