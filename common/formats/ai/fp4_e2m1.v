// fp4_e2m1.v — FP4 (1 sign + 2 exponent + 1 mantissa) decode/encode
// Blackwell/Hopper-class quantized format.
//
// Bit layout [3:0]: {sign[3], exp[2:1], mant[0]}
// Bias = 1 (2-bit exponent, bias = 2^(2-1)-1 = 1)
//
// 16-entry decode LUT (signed int8, scaled ~x16):
//   Value = (-1)^sign * 2^(exp-bias) * (1 + mant*0.5)
//   When exp==0: subnormal, value = (-1)^sign * 0.5 * mant  (flush-to-zero here: 0)
//   Special: 0x7 and 0xF treated as ±NaN/Inf → clamped to ±127
//
// Verilog-2005, R-SI-1 compliant (no standalone *)
`default_nettype none

module fp4_e2m1 (
    // Decode
    input  wire [3:0] dec_fp4,   // FP4 input
    output reg  [7:0] dec_s8,    // signed int8 output (scaled x16)

    // Encode
    input  wire [7:0] enc_s8,    // signed int8 input (scaled x16)
    output reg  [3:0] enc_fp4    // FP4 output
);

    // ----------------------------------------------------------------
    // Decode LUT: full enumeration of 16 values
    // Value formula: sign * 2^(e-1) * (1 + m*0.5)  [for e>0]
    // Scaled x16:
    //  e=1,m=0: 1.0*16=16   e=1,m=1: 1.5*16=24
    //  e=2,m=0: 2.0*16=32   e=2,m=1: 3.0*16=48
    //  e=3,m=0: 4.0*16=64   e=3,m=1: 6.0*16=96
    //  e=0,m=0: 0 (zero)    e=0,m=1: subnormal → 0 (flush)
    // ----------------------------------------------------------------
    always @(*) begin
        case (dec_fp4)
            // Positive values
            4'b0000: dec_s8 =  8'sd0;   // +0
            4'b0001: dec_s8 =  8'sd0;   // +subnormal → flush to 0
            4'b0010: dec_s8 =  8'sd16;  // +1.0 × 16
            4'b0011: dec_s8 =  8'sd24;  // +1.5 × 16
            4'b0100: dec_s8 =  8'sd32;  // +2.0 × 16
            4'b0101: dec_s8 =  8'sd48;  // +3.0 × 16
            4'b0110: dec_s8 =  8'sd64;  // +4.0 × 16
            4'b0111: dec_s8 =  8'sd96;  // +6.0 × 16  (max positive)
            // Negative values
            4'b1000: dec_s8 = -8'sd0;   // -0 → 0
            4'b1001: dec_s8 =  8'sd0;   // -subnormal → flush to 0
            4'b1010: dec_s8 = -8'sd16;  // -1.0 × 16
            4'b1011: dec_s8 = -8'sd24;  // -1.5 × 16
            4'b1100: dec_s8 = -8'sd32;  // -2.0 × 16
            4'b1101: dec_s8 = -8'sd48;  // -3.0 × 16
            4'b1110: dec_s8 = -8'sd64;  // -4.0 × 16
            4'b1111: dec_s8 = -8'sd96;  // -6.0 × 16  (max negative)
            default: dec_s8 =  8'sd0;
        endcase
    end

    // ----------------------------------------------------------------
    // Encode: nearest-value search (midpoints between LUT entries)
    // Thresholds (absolute): 8, 20, 28, 40, 56, 80
    // ----------------------------------------------------------------
    wire        enc_sign = enc_s8[7];
    wire [7:0]  enc_abs  = enc_sign ? (~enc_s8 + 8'd1) : enc_s8;

    always @(*) begin
        if (enc_abs <= 8'd8)       enc_fp4 = {enc_sign, 3'b000};   // 0
        else if (enc_abs <= 8'd20) enc_fp4 = {enc_sign, 3'b010};   // 1.0
        else if (enc_abs <= 8'd28) enc_fp4 = {enc_sign, 3'b011};   // 1.5
        else if (enc_abs <= 8'd40) enc_fp4 = {enc_sign, 3'b100};   // 2.0
        else if (enc_abs <= 8'd56) enc_fp4 = {enc_sign, 3'b101};   // 3.0
        else if (enc_abs <= 8'd80) enc_fp4 = {enc_sign, 3'b110};   // 4.0
        else                       enc_fp4 = {enc_sign, 3'b111};   // 6.0
    end

endmodule
`default_nettype wire
