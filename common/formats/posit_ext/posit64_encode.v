// posit64_encode.v — Posit<64,3> encoder
//
// Inputs:
//   sign     : 1-bit
//   k_in     : signed 8-bit regime value k
//   exp_in   : 3-bit exponent
//   mant_in  : 59-bit mantissa fraction
//   is_zero  : force 0x0000000000000000
//   is_nar   : force 0x8000000000000000
//
// Output:
//   p_out    : 64-bit Posit<64,3>
//
// Verilog-2005, `default_nettype none, R-SI-1 compliant
`default_nettype none

module posit64_encode (
    input  wire              is_zero,
    input  wire              is_nar,
    input  wire              sign,
    input  wire signed [7:0] k_in,
    input  wire [2:0]        exp_in,
    input  wire [58:0]       mant_in,
    output reg  [63:0]       p_out
);

    wire signed [7:0] k_clamped = (k_in > 8'sd61)  ? 8'sd61  :
                                   (k_in < -8'sd62) ? -8'sd62 : k_in;

    wire k_pos  = ~k_clamped[7];
    wire [6:0] abs_k = k_clamped[7] ? (~k_clamped[6:0] + 7'd1) : k_clamped[6:0];

    wire [6:0] reg_len = k_pos ? (abs_k + 7'd2) : (abs_k + 7'd1);

    // Build 63-bit regime field (left-aligned from bit 62)
    reg [62:0] regime_field;
    integer i;
    always @(*) begin
        regime_field = 63'b0;
        if (k_pos) begin
            for (i = 0; i < 63; i = i + 1)
                if (i <= abs_k)
                    regime_field[62-i] = 1'b1;
        end else begin
            if (abs_k < 7'd63)
                regime_field[62 - abs_k] = 1'b1;
        end
    end

    // exp and mant placement
    wire [6:0] exp_start  = 7'd62 - reg_len;
    wire [6:0] mant_start = exp_start - 7'd3;

    reg [62:0] exp_field;
    reg [62:0] mant_field;
    always @(*) begin
        exp_field  = 63'b0;
        mant_field = 63'b0;
        if (reg_len <= 7'd60) begin
            if (exp_start >= 7'd2)
                exp_field = {60'b0, exp_in} << (exp_start - 7'd2);
        end
        if (reg_len <= 7'd57 && mant_start < 7'd63) begin
            mant_field = {4'b0, mant_in} >> (7'd58 - mant_start);
        end
    end

    wire [62:0] mag_bits = regime_field | exp_field | mant_field;
    wire [62:0] signed_mag = sign ? (~mag_bits + 63'd1) : mag_bits;

    always @(*) begin
        if (is_nar)
            p_out = 64'h8000000000000000;
        else if (is_zero)
            p_out = 64'h0000000000000000;
        else
            p_out = {sign, signed_mag};
    end

endmodule
`default_nettype wire
