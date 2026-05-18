// nf4_dot4.v — Dot product of 4 NF4 pairs
// Pipeline: NF4 decode → unsigned magnitude × unsigned magnitude via tri_mant_mul
//           → apply sign → accumulate → output int16
//
// Input:  4 pairs of 4-bit NF4 indices (a0..a3, b0..b3)
// Output: int16 dot product (signed)
//
// Verilog-2005, R-SI-1 compliant (no standalone *)
`default_nettype none

module nf4_dot4 (
    input  wire [3:0] a0, a1, a2, a3,  // NF4 indices, vector A
    input  wire [3:0] b0, b1, b2, b3,  // NF4 indices, vector B
    output wire [15:0] dot_out          // signed int16 accumulation
);

    // ---- Decode all 8 NF4 values ----
    // dec_val is int8 signed; we extract sign + abs magnitude for tri_mant_mul

    wire [7:0] da0_raw, da1_raw, da2_raw, da3_raw;
    wire [7:0] db0_raw, db1_raw, db2_raw, db3_raw;
    wire [3:0] unused_enc [0:7];  // encode outputs not used here

    nf4_codec dec_a0 (.dec_idx(a0), .dec_val(da0_raw), .enc_in(8'h0), .enc_idx(unused_enc[0]));
    nf4_codec dec_a1 (.dec_idx(a1), .dec_val(da1_raw), .enc_in(8'h0), .enc_idx(unused_enc[1]));
    nf4_codec dec_a2 (.dec_idx(a2), .dec_val(da2_raw), .enc_in(8'h0), .enc_idx(unused_enc[2]));
    nf4_codec dec_a3 (.dec_idx(a3), .dec_val(da3_raw), .enc_in(8'h0), .enc_idx(unused_enc[3]));

    nf4_codec dec_b0 (.dec_idx(b0), .dec_val(db0_raw), .enc_in(8'h0), .enc_idx(unused_enc[4]));
    nf4_codec dec_b1 (.dec_idx(b1), .dec_val(db1_raw), .enc_in(8'h0), .enc_idx(unused_enc[5]));
    nf4_codec dec_b2 (.dec_idx(b2), .dec_val(db2_raw), .enc_in(8'h0), .enc_idx(unused_enc[6]));
    nf4_codec dec_b3 (.dec_idx(b3), .dec_val(db3_raw), .enc_in(8'h0), .enc_idx(unused_enc[7]));

    // ---- Extract sign and magnitude (int8 → sign + 7-bit abs) ----
    // For int8 range -127..+127 the absolute value fits in 7 bits.
    // Special case: -128 (0x80) is clamped to 127 for safety.

    wire sa0 = da0_raw[7];
    wire sa1 = da1_raw[7];
    wire sa2 = da2_raw[7];
    wire sa3 = da3_raw[7];
    wire sb0 = db0_raw[7];
    wire sb1 = db1_raw[7];
    wire sb2 = db2_raw[7];
    wire sb3 = db3_raw[7];

    // abs via 2's complement negation when negative
    wire [6:0] ma0 = sa0 ? (~da0_raw[6:0] + 7'd1) : da0_raw[6:0];
    wire [6:0] ma1 = sa1 ? (~da1_raw[6:0] + 7'd1) : da1_raw[6:0];
    wire [6:0] ma2 = sa2 ? (~da2_raw[6:0] + 7'd1) : da2_raw[6:0];
    wire [6:0] ma3 = sa3 ? (~da3_raw[6:0] + 7'd1) : da3_raw[6:0];

    wire [6:0] mb0 = sb0 ? (~db0_raw[6:0] + 7'd1) : db0_raw[6:0];
    wire [6:0] mb1 = sb1 ? (~db1_raw[6:0] + 7'd1) : db1_raw[6:0];
    wire [6:0] mb2 = sb2 ? (~db2_raw[6:0] + 7'd1) : db2_raw[6:0];
    wire [6:0] mb3 = sb3 ? (~db3_raw[6:0] + 7'd1) : db3_raw[6:0];

    // Use only upper 4 bits of magnitude as input to tri_mant_mul (4x4 → 8)
    // This gives us a scaled result (divided by 8 implicitly)
    wire [3:0] ta0 = ma0[6:3];
    wire [3:0] ta1 = ma1[6:3];
    wire [3:0] ta2 = ma2[6:3];
    wire [3:0] ta3 = ma3[6:3];

    wire [3:0] tb0 = mb0[6:3];
    wire [3:0] tb1 = mb1[6:3];
    wire [3:0] tb2 = mb2[6:3];
    wire [3:0] tb3 = mb3[6:3];

    // ---- Multiply via tri_mant_mul ----
    wire [7:0] prod0, prod1, prod2, prod3;

    tri_mant_mul mul0 (.a(ta0), .b(tb0), .result(prod0));
    tri_mant_mul mul1 (.a(ta1), .b(tb1), .result(prod1));
    tri_mant_mul mul2 (.a(ta2), .b(tb2), .result(prod2));
    tri_mant_mul mul3 (.a(ta3), .b(tb3), .result(prod3));

    // ---- Apply sign: XOR of operand signs ----
    wire sign0 = sa0 ^ sb0;
    wire sign1 = sa1 ^ sb1;
    wire sign2 = sa2 ^ sb2;
    wire sign3 = sa3 ^ sb3;

    // Signed 16-bit partial products (sign-extend then negate if needed)
    wire [15:0] sp0 = sign0 ? (~{8'h00, prod0} + 16'd1) : {8'h00, prod0};
    wire [15:0] sp1 = sign1 ? (~{8'h00, prod1} + 16'd1) : {8'h00, prod1};
    wire [15:0] sp2 = sign2 ? (~{8'h00, prod2} + 16'd1) : {8'h00, prod2};
    wire [15:0] sp3 = sign3 ? (~{8'h00, prod3} + 16'd1) : {8'h00, prod3};

    // ---- Accumulate ----
    assign dot_out = sp0 + sp1 + sp2 + sp3;

endmodule
`default_nettype wire
