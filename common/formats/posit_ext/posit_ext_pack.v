// posit_ext_pack.v — Format dispatcher for posit_ext family
//
// Routes operations to the appropriate sub-module based on format_id.
//
// format_id encoding (3-bit):
//   3'd0 = Posit32    — Posit<32,2>
//   3'd1 = Posit64    — Posit<64,3>
//   3'd2 = Nf8        — 8-bit NormalFloat (CDF-inverse quantization)
//   3'd3 = TaperedFp16 — Tapered FP WIDTH=16
//   3'd4 = TaperedFp32 — Tapered FP WIDTH=32
//
// Operations (op encoding, 2-bit):
//   2'b00 = ADD    (a + b)
//   2'b01 = MUL    (a * b)
//   2'b10 = DECODE (a → decoded fields in result[63:0])
//   2'b11 = ENCODE (fields in a → encoded word in result)
//
// For Posit32/64: a and b are the full-width operands (zero-extended to 64-bit).
// For Nf8:  a[7:0] = index_a, b[7:0] = index_b (ADD/MUL not supported → result=0)
//           DECODE: a[7:0] → result[15:0] = decoded Q1.15 value
// For TaperedFp: a[WIDTH-1:0] operand, b[WIDTH-1:0] second operand
//               DECODE: result[63:0] = {sign, k[7:0], mant[28:0], ...}
//
// Result is always 64-bit; unused upper bits are zero.
// nar_out is asserted when either input is NaR (Posit) or reserved (Nf8).
//
// Verilog-2005, `default_nettype none, R-SI-1 compliant
`default_nettype none

module posit_ext_pack (
    input  wire [2:0]  format_id,
    input  wire [1:0]  op,
    input  wire [63:0] a,
    input  wire [63:0] b,
    output reg  [63:0] result,
    output reg         nar_out
);

    // ----------------------------------------------------------------
    // Posit32 wires
    wire [31:0] p32_add_r;  wire p32_add_nar;
    wire [31:0] p32_mul_r;  wire p32_mul_nar;

    posit32_add p32add (
        .a(a[31:0]), .b(b[31:0]),
        .result(p32_add_r), .nar_out(p32_add_nar)
    );
    posit32_mul p32mul (
        .a(a[31:0]), .b(b[31:0]),
        .result(p32_mul_r), .nar_out(p32_mul_nar)
    );

    // Posit32 decode outputs
    wire        p32d_sign;
    wire signed [6:0] p32d_k;
    wire [1:0]  p32d_exp;
    wire [28:0] p32d_mant;
    wire        p32d_zero, p32d_nar;
    posit32_decode p32dec (
        .p(a[31:0]), .sign(p32d_sign), .regime_k(p32d_k),
        .exp_2bit(p32d_exp), .mant_29bit(p32d_mant),
        .is_zero(p32d_zero), .is_nar(p32d_nar)
    );

    // Posit32 encode (from b field: b[38:32]=k, b[34:33]=exp, b[63:35]=mant)
    wire [31:0] p32e_out;
    posit32_encode p32enc (
        .is_zero(b[0]), .is_nar(b[1]), .sign(b[2]),
        .k_in(b[9:3]), .exp_in(b[11:10]), .mant_in(b[40:12]),
        .p_out(p32e_out)
    );

    // ----------------------------------------------------------------
    // Posit64 wires
    wire [63:0] p64_add_r; wire p64_add_nar;
    wire [63:0] p64_mul_r; wire p64_mul_nar;

    posit64_add p64add (
        .a(a), .b(b),
        .result(p64_add_r), .nar_out(p64_add_nar)
    );
    posit64_mul p64mul (
        .a(a), .b(b),
        .result(p64_mul_r), .nar_out(p64_mul_nar)
    );

    wire        p64d_sign;
    wire signed [7:0] p64d_k;
    wire [2:0]  p64d_exp;
    wire [58:0] p64d_mant;
    wire        p64d_zero, p64d_nar;
    posit64_decode p64dec (
        .p(a), .sign(p64d_sign), .regime_k(p64d_k),
        .exp_3bit(p64d_exp), .mant_59bit(p64d_mant),
        .is_zero(p64d_zero), .is_nar(p64d_nar)
    );

    wire [63:0] p64e_out;
    posit64_encode p64enc (
        .is_zero(b[0]), .is_nar(b[1]), .sign(b[2]),
        .k_in(b[10:3]), .exp_in(b[13:11]), .mant_in(b[72:14]),
        .p_out(p64e_out)
    );

    // ----------------------------------------------------------------
    // Nf8 wires (decode only — ADD/MUL not defined for Nf8 in dispatcher)
    wire [15:0] nf8_dec_out;
    wire [7:0]  nf8_enc_out;
    nf8 nf8_inst (
        .in_idx(a[7:0]), .lut_out(nf8_dec_out),
        .enc_in(a[15:0]), .enc_idx(nf8_enc_out)
    );

    // ----------------------------------------------------------------
    // TaperedFP16
    wire        tfp16_dec_sign;
    wire signed [7:0] tfp16_dec_k;
    wire [28:0] tfp16_dec_mant;
    wire        tfp16_dec_zero, tfp16_dec_nar;
    wire [15:0] tfp16_enc_out;

    tapered_fp #(.WIDTH(16)) tfp16 (
        .tfp_in(a[15:0]),
        .dec_sign(tfp16_dec_sign), .dec_k(tfp16_dec_k),
        .dec_mant(tfp16_dec_mant), .dec_zero(tfp16_dec_zero), .dec_nar(tfp16_dec_nar),
        .enc_sign(b[0]), .enc_k(b[8:1]), .enc_mant(b[37:9]),
        .enc_zero(b[38]), .enc_nar(b[39]),
        .tfp_out(tfp16_enc_out)
    );

    // TaperedFP32
    wire        tfp32_dec_sign;
    wire signed [7:0] tfp32_dec_k;
    wire [28:0] tfp32_dec_mant;
    wire        tfp32_dec_zero, tfp32_dec_nar;
    wire [31:0] tfp32_enc_out;

    tapered_fp #(.WIDTH(32)) tfp32 (
        .tfp_in(a[31:0]),
        .dec_sign(tfp32_dec_sign), .dec_k(tfp32_dec_k),
        .dec_mant(tfp32_dec_mant), .dec_zero(tfp32_dec_zero), .dec_nar(tfp32_dec_nar),
        .enc_sign(b[0]), .enc_k(b[8:1]), .enc_mant(b[37:9]),
        .enc_zero(b[38]), .enc_nar(b[39]),
        .tfp_out(tfp32_enc_out)
    );

    // ----------------------------------------------------------------
    // Dispatch
    always @(*) begin
        result  = 64'b0;
        nar_out = 1'b0;
        case (format_id)
            3'd0: begin // Posit32
                case (op)
                    2'b00: begin result = {32'b0, p32_add_r}; nar_out = p32_add_nar; end
                    2'b01: begin result = {32'b0, p32_mul_r}; nar_out = p32_mul_nar; end
                    2'b10: begin result = {p32d_nar, p32d_zero, p32d_mant,
                                           p32d_exp, p32d_k, 23'b0, p32d_sign};
                                 nar_out = p32d_nar; end
                    2'b11: begin result = {32'b0, p32e_out}; end
                    default: result = 64'b0;
                endcase
            end
            3'd1: begin // Posit64
                case (op)
                    2'b00: begin result = p64_add_r; nar_out = p64_add_nar; end
                    2'b01: begin result = p64_mul_r; nar_out = p64_mul_nar; end
                    2'b10: begin result = {p64d_nar, p64d_zero, p64d_mant[58:29],
                                           p64d_exp, p64d_k, p64d_mant[28:0], p64d_sign};
                                 nar_out = p64d_nar; end
                    2'b11: begin result = p64e_out; end
                    default: result = 64'b0;
                endcase
            end
            3'd2: begin // Nf8
                case (op)
                    2'b10: begin result = {48'b0, nf8_dec_out}; end  // decode
                    2'b11: begin result = {56'b0, nf8_enc_out}; end  // encode
                    default: result = 64'b0;
                endcase
            end
            3'd3: begin // TaperedFp16
                case (op)
                    2'b10: begin result = {tfp16_dec_nar, tfp16_dec_zero, tfp16_dec_mant,
                                           tfp16_dec_k, 15'b0, tfp16_dec_sign};
                                 nar_out = tfp16_dec_nar; end
                    2'b11: begin result = {48'b0, tfp16_enc_out}; end
                    default: result = 64'b0;
                endcase
            end
            3'd4: begin // TaperedFp32
                case (op)
                    2'b10: begin result = {tfp32_dec_nar, tfp32_dec_zero, tfp32_dec_mant,
                                           tfp32_dec_k, 15'b0, tfp32_dec_sign};
                                 nar_out = tfp32_dec_nar; end
                    2'b11: begin result = {32'b0, tfp32_enc_out}; end
                    default: result = 64'b0;
                endcase
            end
            default: begin result = 64'b0; nar_out = 1'b0; end
        endcase
    end

endmodule
`default_nettype wire
