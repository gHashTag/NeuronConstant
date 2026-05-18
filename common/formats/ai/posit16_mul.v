// posit16_mul.v — Posit<16,1> multiplication
// Uses tri_mant_mul8 for mantissa product (no standalone *).
//
// Algorithm:
//   1. Decode both Posit<16,1> into (sign, scale, significand)
//      where scale = 2*k + exp  (k = regime value, exp = 1-bit exponent)
//   2. Multiply significands via tri_mant_mul8 (8x8 → 16 bits, no *)
//      significands are {1, frac[12:6]} → 8-bit with implicit leading 1
//   3. Add scales
//   4. Normalize product: if product overflows (bit 15 set), shift right + inc scale
//   5. Re-encode to Posit<16,1>
//
// Verilog-2005, R-SI-1 compliant (no standalone *)
`default_nettype none

module posit16_mul (
    input  wire [15:0] a,        // Posit<16,1> operand A
    input  wire [15:0] b,        // Posit<16,1> operand B
    output reg  [15:0] result,   // Posit<16,1> product
    output reg         nar_out   // 1 = NaR
);

    localparam NAR  = 16'h8000;
    localparam ZERO = 16'h0000;

    // ----------------------------------------------------------------
    // Decode A
    wire        sign_a  = a[15];
    wire [14:0] mag_a   = sign_a ? (~a[14:0] + 15'd1) : a[14:0];
    wire        rbit_a  = mag_a[14];

    reg [3:0] rlen_a;
    reg signed [4:0] k_a;
    always @(*) begin
        casez ({rbit_a, mag_a[13:7]})
            8'b1111_1111: begin k_a =  5'sd7; rlen_a = 4'd9; end
            8'b1111_1110: begin k_a =  5'sd6; rlen_a = 4'd8; end
            8'b1111_110?: begin k_a =  5'sd5; rlen_a = 4'd7; end
            8'b1111_10??: begin k_a =  5'sd4; rlen_a = 4'd6; end
            8'b1111_0???: begin k_a =  5'sd3; rlen_a = 4'd5; end
            8'b1110_????: begin k_a =  5'sd2; rlen_a = 4'd4; end
            8'b110?_????: begin k_a =  5'sd1; rlen_a = 4'd3; end
            8'b10??_????: begin k_a =  5'sd0; rlen_a = 4'd2; end
            8'b0000_0000: begin k_a = -5'sd7; rlen_a = 4'd9; end
            8'b0000_0001: begin k_a = -5'sd6; rlen_a = 4'd8; end
            8'b0000_001?: begin k_a = -5'sd5; rlen_a = 4'd7; end
            8'b0000_01??: begin k_a = -5'sd4; rlen_a = 4'd6; end
            8'b0000_1???: begin k_a = -5'sd3; rlen_a = 4'd5; end
            8'b0001_????: begin k_a = -5'sd2; rlen_a = 4'd4; end
            8'b001?_????: begin k_a = -5'sd1; rlen_a = 4'd3; end
            default:      begin k_a =  5'sd0; rlen_a = 4'd2; end
        endcase
    end

    wire [14:0] arm_a  = mag_a << rlen_a;
    wire        exp_a  = arm_a[14];
    wire [6:0]  frac7_a = arm_a[13:7];          // top 7 frac bits
    wire [7:0]  sig_a  = {1'b1, frac7_a};        // 8-bit significand (implicit 1)
    wire signed [5:0] scale_a = {k_a, 1'b0} + {{5{1'b0}}, exp_a};

    // Decode B
    wire        sign_b  = b[15];
    wire [14:0] mag_b   = sign_b ? (~b[14:0] + 15'd1) : b[14:0];
    wire        rbit_b  = mag_b[14];

    reg [3:0] rlen_b;
    reg signed [4:0] k_b;
    always @(*) begin
        casez ({rbit_b, mag_b[13:7]})
            8'b1111_1111: begin k_b =  5'sd7; rlen_b = 4'd9; end
            8'b1111_1110: begin k_b =  5'sd6; rlen_b = 4'd8; end
            8'b1111_110?: begin k_b =  5'sd5; rlen_b = 4'd7; end
            8'b1111_10??: begin k_b =  5'sd4; rlen_b = 4'd6; end
            8'b1111_0???: begin k_b =  5'sd3; rlen_b = 4'd5; end
            8'b1110_????: begin k_b =  5'sd2; rlen_b = 4'd4; end
            8'b110?_????: begin k_b =  5'sd1; rlen_b = 4'd3; end
            8'b10??_????: begin k_b =  5'sd0; rlen_b = 4'd2; end
            8'b0000_0000: begin k_b = -5'sd7; rlen_b = 4'd9; end
            8'b0000_0001: begin k_b = -5'sd6; rlen_b = 4'd8; end
            8'b0000_001?: begin k_b = -5'sd5; rlen_b = 4'd7; end
            8'b0000_01??: begin k_b = -5'sd4; rlen_b = 4'd6; end
            8'b0000_1???: begin k_b = -5'sd3; rlen_b = 4'd5; end
            8'b0001_????: begin k_b = -5'sd2; rlen_b = 4'd4; end
            8'b001?_????: begin k_b = -5'sd1; rlen_b = 4'd3; end
            default:      begin k_b =  5'sd0; rlen_b = 4'd2; end
        endcase
    end

    wire [14:0] arm_b  = mag_b << rlen_b;
    wire        exp_b  = arm_b[14];
    wire [6:0]  frac7_b = arm_b[13:7];
    wire [7:0]  sig_b  = {1'b1, frac7_b};
    wire signed [5:0] scale_b = {k_b, 1'b0} + {{5{1'b0}}, exp_b};

    // ----------------------------------------------------------------
    // Multiply significands via tri_mant_mul8 (8×8 → 16, no *)
    wire [15:0] sig_prod;
    tri_mant_mul8 mant_mul (
        .a(sig_a),
        .b(sig_b),
        .result(sig_prod)
    );

    // ----------------------------------------------------------------
    // Normalize: sig_a and sig_b are both in [1.0, 2.0) as Q1.7
    // Product sig_prod is Q2.14; leading bit is at [15] or [14]
    // If sig_prod[15] == 1: scale += 1, product mantissa = sig_prod[14:7]
    // If sig_prod[14] == 1: scale unchanged, product mantissa = sig_prod[13:6]

    wire product_overflow = sig_prod[15];
    wire signed [5:0] scale_sum = scale_a + scale_b + (product_overflow ? 6'sd1 : 6'sd0);
    wire [6:0] frac_prod = product_overflow ? sig_prod[14:8] : sig_prod[13:7];

    // ----------------------------------------------------------------
    // Re-encode to Posit<16,1>
    wire result_sign = sign_a ^ sign_b;

    // Decompose scale_sum: k_out = scale_sum >> 1, exp_out = scale_sum[0]
    // Arithmetic: if scale_sum is negative, floor-divide
    wire signed [5:0] scale_s  = scale_sum;
    wire signed [4:0] k_out    = scale_s[5:1];  // arithmetic right-shift by 1
    wire              exp_out  = scale_sum[0];

    // Build regime
    reg [14:0] regime_bits;
    reg [3:0]  reg_len_out;
    wire [4:0] abs_k_out = k_out[4] ? (~k_out + 5'd1) : {1'b0, k_out[3:0]};

    always @(*) begin
        if (k_out >= 5'sd7) begin
            regime_bits = 15'b111_1111_1111_1111; reg_len_out = 4'd15;
        end else if (k_out >= 5'sd0) begin
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

    wire [14:0] exp_placed  = {14'h0, exp_out} << (4'd14 - reg_len_out);
    wire [14:0] frac_placed = {frac_prod, 8'h0} >> (reg_len_out + 4'd1);
    wire [14:0] posit_body  = regime_bits | exp_placed | frac_placed;

    always @(*) begin
        nar_out = (a == NAR) || (b == NAR);
        if (nar_out) begin
            result = NAR;
        end else if ((a == ZERO) || (b == ZERO)) begin
            result = ZERO;
        end else begin
            result = {result_sign, posit_body};
        end
    end

endmodule
`default_nettype wire
