// posit32_encode.v — Posit<32,2> encoder
//
// Inputs:
//   sign     : 1-bit sign
//   k_in     : signed 7-bit regime value k (-30..30)
//   exp_in   : 2-bit exponent
//   mant_in  : 29-bit mantissa fraction (MSB = 2^-1)
//   is_zero  : force output to 0
//   is_nar   : force output to NaR (0x80000000)
//
// Output:
//   p_out    : 32-bit Posit<32,2>
//
// Regime encoding:
//   k >= 0: (k+1) ones, then a 0 terminator → length k+2
//   k <  0: |k| zeros, then a 1 terminator → length |k|+1
//
// Verilog-2005, `default_nettype none, R-SI-1 compliant
`default_nettype none

module posit32_encode (
    input  wire              is_zero,
    input  wire              is_nar,
    input  wire              sign,
    input  wire signed [6:0] k_in,
    input  wire [1:0]        exp_in,
    input  wire [28:0]       mant_in,
    output reg  [31:0]       p_out
);

    // Build regime run into a 31-bit field (mag without sign)
    // Max useful k for 32-bit posit: k=29 (30 ones + terminator = 31 bits, no room for exp/mant)

    // Clamp k to valid range
    wire signed [6:0] k_clamped = (k_in > 7'sd29)  ? 7'sd29  :
                                   (k_in < -7'sd30) ? -7'sd30 : k_in;

    wire k_pos = ~k_clamped[6]; // sign bit: 0 if k>=0

    // |k|
    wire [5:0] abs_k = k_clamped[6] ? (~k_clamped[5:0] + 6'd1) : k_clamped[5:0];

    // Regime field length:
    //   k >= 0: length = k+2 (k+1 ones + 1 zero)
    //   k <  0: length = |k|+1 (|k| zeros + 1 one)
    wire [5:0] reg_len = k_pos ? (abs_k + 6'd2) : (abs_k + 6'd1);

    // Build regime bits in a 31-bit wide field (aligned to MSB = bit 30)
    // For k>=0: 1s from bit 30 down to (30-(k)), then 0 at (30-k-1)
    // For k< 0: 0s from bit 30 down, then 1 at the terminator
    // We build as a 31-bit vector then insert exp + mant below

    // Generate regime in a 32-bit register, left-aligned at bit 30
    reg [30:0] regime_field;
    integer i;
    always @(*) begin
        regime_field = 31'b0;
        if (k_pos) begin
            // Place (abs_k+1) ones starting at bit 30 downward
            for (i = 0; i < 31; i = i + 1)
                if (i <= abs_k)
                    regime_field[30-i] = 1'b1;
            // Terminator 0 is implicit (bit initialized to 0)
        end else begin
            // abs_k zeros, then terminator 1
            // Zeros from bit 30 down to (30-abs_k+1), then 1 at (30-abs_k)
            if (abs_k < 6'd31)
                regime_field[30 - abs_k] = 1'b1;
        end
    end

    // Place exp and mant after regime
    // exp starts at bit (30 - reg_len), mant follows
    wire [5:0] exp_start  = 6'd30 - reg_len;          // bit position of exp MSB
    wire [5:0] mant_start = exp_start - 6'd2;          // bit position of mant MSB

    // Shift exp_in into position
    // exp_start can range 0..27 (when regime takes 2..30 bits)
    reg [30:0] exp_field;
    reg [30:0] mant_field;
    always @(*) begin
        exp_field  = 31'b0;
        mant_field = 31'b0;
        // Only insert if there's room (exp_start >= 1 for 2-bit exp)
        if (reg_len <= 6'd29) begin
            // exp occupies 2 bits at [exp_start:exp_start-1]
            // shift 2-bit exp_in so its MSB lands at exp_start
            if (exp_start >= 6'd1)
                exp_field = {29'b0, exp_in} << (exp_start - 6'd1);
        end
        if (reg_len <= 6'd27 && mant_start < 6'd31) begin
            // mant: 29 bits starting at mant_start (may be truncated)
            mant_field = mant_in[28:0] >> (6'd28 - mant_start);
        end
    end

    wire [30:0] mag_bits = regime_field | exp_field | mant_field;

    // Apply sign: positive → mag_bits, negative → 2's complement
    wire [30:0] signed_mag = sign ? (~mag_bits + 31'd1) : mag_bits;

    always @(*) begin
        if (is_nar)
            p_out = 32'h80000000;
        else if (is_zero)
            p_out = 32'h00000000;
        else
            p_out = {sign, signed_mag};
    end

endmodule
`default_nettype wire
