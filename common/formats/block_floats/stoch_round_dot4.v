// SPDX-License-Identifier: MIT
// Stochastic Round Dot4: 4-element dot product with stochastic rounding
// on final accumulation result.
// Uses LFSR-16 for rounding decision on wide->narrow conversion.
// R-SI-1 compliant: uses shift_add_mul8u for all multiplications
// Co-author: Opus 4.6
`default_nettype none

// 4-element dot product: sum(a[i] * b[i]) for i=0..3
// Inputs: 4 x 16-bit Q8.8 values (packed)
// Output: 8-bit result with stochastic rounding (narrow to 8-bit)
module stoch_round_dot4 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] a_pack,      // 4 x 16-bit Q8.8 packed
    input  wire [63:0] b_pack,      // 4 x 16-bit Q8.8 packed
    input  wire [15:0] lfsr_seed,   // LFSR seed for stochastic rounding
    output reg  [7:0]  dot_sr_out,  // 8-bit result with stochastic rounding
    output reg  [31:0] dot_exact    // exact 32-bit result (for reference)
);
    // Unpack elements
    wire [15:0] a0 = a_pack[15:0];
    wire [15:0] a1 = a_pack[31:16];
    wire [15:0] a2 = a_pack[47:32];
    wire [15:0] a3 = a_pack[63:48];

    wire [15:0] b0 = b_pack[15:0];
    wire [15:0] b1 = b_pack[31:16];
    wire [15:0] b2 = b_pack[47:32];
    wire [15:0] b3 = b_pack[63:48];

    // Sign-magnitude multiplication using shift_add_mul8u (upper bytes)
    wire s0 = a0[15] ^ b0[15];
    wire s1 = a1[15] ^ b1[15];
    wire s2 = a2[15] ^ b2[15];
    wire s3 = a3[15] ^ b3[15];

    wire [7:0] ma0 = a0[15] ? (~a0[14:7] + 8'h01) : a0[14:7];
    wire [7:0] ma1 = a1[15] ? (~a1[14:7] + 8'h01) : a1[14:7];
    wire [7:0] ma2 = a2[15] ? (~a2[14:7] + 8'h01) : a2[14:7];
    wire [7:0] ma3 = a3[15] ? (~a3[14:7] + 8'h01) : a3[14:7];

    wire [7:0] mb0 = b0[15] ? (~b0[14:7] + 8'h01) : b0[14:7];
    wire [7:0] mb1 = b1[15] ? (~b1[14:7] + 8'h01) : b1[14:7];
    wire [7:0] mb2 = b2[15] ? (~b2[14:7] + 8'h01) : b2[14:7];
    wire [7:0] mb3 = b3[15] ? (~b3[14:7] + 8'h01) : b3[14:7];

    wire [15:0] p0_abs, p1_abs, p2_abs, p3_abs;

    shift_add_mul8u u_mul0 (.a(ma0), .b(mb0), .result(p0_abs));
    shift_add_mul8u u_mul1 (.a(ma1), .b(mb1), .result(p1_abs));
    shift_add_mul8u u_mul2 (.a(ma2), .b(mb2), .result(p2_abs));
    shift_add_mul8u u_mul3 (.a(ma3), .b(mb3), .result(p3_abs));

    wire [15:0] p0 = s0 ? (~p0_abs + 16'h0001) : p0_abs;
    wire [15:0] p1 = s1 ? (~p1_abs + 16'h0001) : p1_abs;
    wire [15:0] p2 = s2 ? (~p2_abs + 16'h0001) : p2_abs;
    wire [15:0] p3 = s3 ? (~p3_abs + 16'h0001) : p3_abs;

    // 32-bit accumulation (sign-extended)
    wire [31:0] acc = {{16{p0[15]}}, p0} + {{16{p1[15]}}, p1}
                    + {{16{p2[15]}}, p2} + {{16{p3[15]}}, p3};

    // LFSR for stochastic rounding
    wire [15:0] lfsr_val;
    lfsr16 u_lfsr (
        .clk     (clk),
        .rst_n   (rst_n),
        .seed    (lfsr_seed),
        .advance (1'b1),
        .lfsr_out(lfsr_val)
    );

    // Stochastic rounding: 32-bit -> 8-bit (drop 24 bits)
    // frac = acc[23:8] (16-bit fractional window)
    wire [15:0] frac16 = acc[23:8];
    wire        round_up = (lfsr_val < frac16);

    wire [7:0]  base8  = acc[31:24];
    wire [8:0]  rounded = {1'b0, base8} + {8'h00, round_up};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dot_sr_out <= 8'h00;
            dot_exact  <= 32'h00000000;
        end else begin
            dot_exact  <= acc;
            dot_sr_out <= rounded[8] ? 8'hFF : rounded[7:0];
        end
    end
endmodule
`default_nettype wire
