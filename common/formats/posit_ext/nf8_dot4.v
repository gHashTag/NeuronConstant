// nf8_dot4.v — Dot product of 4 Nf8 pairs
//
// Computes: sum = a0*b0 + a1*b1 + a2*b2 + a3*b3
// where each input is an 8-bit Nf8 index decoded to signed Q1.15 via nf8 LUT.
// Product is Q2.30 (17-bit significand), sum is Q5.30 (35-bit).
// Output: dot_out (32-bit signed, Q5.27 — shifted right 3 for headroom).
//
// R-SI-1: multiplication via shift-add (16x16 → 32, no standalone *)
// Each product: 16-bit * 16-bit = 32-bit via 16 partial products generate loop.
//
// Verilog-2005, `default_nettype none
`default_nettype none

module nf8_dot4 (
    input  wire [7:0]  a0, a1, a2, a3,  // Nf8 indices
    input  wire [7:0]  b0, b1, b2, b3,
    output wire [31:0] dot_out           // signed Q5.27 dot product
);

    // ----------------------------------------------------------------
    // Decode all 8 inputs via nf8 LUT
    wire [15:0] da0_raw, da1_raw, da2_raw, da3_raw;
    wire [15:0] db0_raw, db1_raw, db2_raw, db3_raw;
    wire [7:0]  dummy_enc [0:7]; // unused encode outputs

    nf8 dec_a0 (.in_idx(a0), .lut_out(da0_raw), .enc_in(16'h0000), .enc_idx(dummy_enc[0]));
    nf8 dec_a1 (.in_idx(a1), .lut_out(da1_raw), .enc_in(16'h0000), .enc_idx(dummy_enc[1]));
    nf8 dec_a2 (.in_idx(a2), .lut_out(da2_raw), .enc_in(16'h0000), .enc_idx(dummy_enc[2]));
    nf8 dec_a3 (.in_idx(a3), .lut_out(da3_raw), .enc_in(16'h0000), .enc_idx(dummy_enc[3]));
    nf8 dec_b0 (.in_idx(b0), .lut_out(db0_raw), .enc_in(16'h0000), .enc_idx(dummy_enc[4]));
    nf8 dec_b1 (.in_idx(b1), .lut_out(db1_raw), .enc_in(16'h0000), .enc_idx(dummy_enc[5]));
    nf8 dec_b2 (.in_idx(b2), .lut_out(db2_raw), .enc_in(16'h0000), .enc_idx(dummy_enc[6]));
    nf8 dec_b3 (.in_idx(b3), .lut_out(db3_raw), .enc_in(16'h0000), .enc_idx(dummy_enc[7]));

    // Treat decoded values as signed
    wire signed [15:0] da0 = $signed(da0_raw);
    wire signed [15:0] da1 = $signed(da1_raw);
    wire signed [15:0] da2 = $signed(da2_raw);
    wire signed [15:0] da3 = $signed(da3_raw);
    wire signed [15:0] db0 = $signed(db0_raw);
    wire signed [15:0] db1 = $signed(db1_raw);
    wire signed [15:0] db2 = $signed(db2_raw);
    wire signed [15:0] db3 = $signed(db3_raw);

    // ----------------------------------------------------------------
    // Signed 16x16 → 32-bit shift-add multiplier (R-SI-1: no standalone *)
    // For signed multiply: handle sign separately, multiply magnitudes
    // mag_a * mag_b via 16 partial products (generate loop)
    // ----------------------------------------------------------------

    // Macro: compute |x|
    // For signed 16-bit: abs = x[15] ? (~x+1) : x
    wire [15:0] mag_a0 = da0[15] ? (~da0 + 16'd1) : da0;
    wire [15:0] mag_a1 = da1[15] ? (~da1 + 16'd1) : da1;
    wire [15:0] mag_a2 = da2[15] ? (~da2 + 16'd1) : da2;
    wire [15:0] mag_a3 = da3[15] ? (~da3 + 16'd1) : da3;
    wire [15:0] mag_b0 = db0[15] ? (~db0 + 16'd1) : db0;
    wire [15:0] mag_b1 = db1[15] ? (~db1 + 16'd1) : db1;
    wire [15:0] mag_b2 = db2[15] ? (~db2 + 16'd1) : db2;
    wire [15:0] mag_b3 = db3[15] ? (~db3 + 16'd1) : db3;

    wire sign_p0 = da0[15] ^ db0[15];
    wire sign_p1 = da1[15] ^ db1[15];
    wire sign_p2 = da2[15] ^ db2[15];
    wire sign_p3 = da3[15] ^ db3[15];

    // 16x16 unsigned shift-add via generate
    wire [31:0] pp0 [0:15];
    wire [31:0] pp1 [0:15];
    wire [31:0] pp2 [0:15];
    wire [31:0] pp3 [0:15];

    genvar gi;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : mul_pp
            assign pp0[gi] = mag_b0[gi] ? ({16'b0, mag_a0} << gi) : 32'b0;
            assign pp1[gi] = mag_b1[gi] ? ({16'b0, mag_a1} << gi) : 32'b0;
            assign pp2[gi] = mag_b2[gi] ? ({16'b0, mag_a2} << gi) : 32'b0;
            assign pp3[gi] = mag_b3[gi] ? ({16'b0, mag_a3} << gi) : 32'b0;
        end
    endgenerate

    reg [31:0] mag_prod0, mag_prod1, mag_prod2, mag_prod3;
    integer pi;
    always @(*) begin
        mag_prod0 = 32'b0;
        mag_prod1 = 32'b0;
        mag_prod2 = 32'b0;
        mag_prod3 = 32'b0;
        for (pi = 0; pi < 16; pi = pi + 1) begin
            mag_prod0 = mag_prod0 + pp0[pi];
            mag_prod1 = mag_prod1 + pp1[pi];
            mag_prod2 = mag_prod2 + pp2[pi];
            mag_prod3 = mag_prod3 + pp3[pi];
        end
    end

    // Apply signs: signed product = sign ? -mag_prod : mag_prod
    wire signed [31:0] prod0 = sign_p0 ? (32'b0 - mag_prod0) : mag_prod0;
    wire signed [31:0] prod1 = sign_p1 ? (32'b0 - mag_prod1) : mag_prod1;
    wire signed [31:0] prod2 = sign_p2 ? (32'b0 - mag_prod2) : mag_prod2;
    wire signed [31:0] prod3 = sign_p3 ? (32'b0 - mag_prod3) : mag_prod3;

    // Sum 4 products → 34-bit to avoid overflow
    wire signed [33:0] dot_sum = $signed({{2{prod0[31]}}, prod0})
                                + $signed({{2{prod1[31]}}, prod1})
                                + $signed({{2{prod2[31]}}, prod2})
                                + $signed({{2{prod3[31]}}, prod3});

    // Output: shift right by 2 to fit in 32-bit signed (Q5.28)
    assign dot_out = dot_sum[33:2];

endmodule
`default_nettype wire
