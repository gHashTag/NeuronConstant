// SPDX-License-Identifier: MIT
// block_floats_pack: top-level dispatcher for all block-float formats
// format_id (4-bit):
//   0 = MXFP4      (OCP MX FP4, E2M1, block E8M0)
//   1 = MXFP6_E2M3 (OCP MX FP6 E2M3)
//   2 = MXFP6_E3M2 (OCP MX FP6 E3M2)
//   3 = MXFP8_E4M3 (OCP MX FP8 E4M3)
//   4 = MXFP8_E5M2 (OCP MX FP8 E5M2)
//   5 = LNS8       (Logarithmic NS 8-bit)
//   6 = Q15        (Q0.15 fixed-point)
//   7 = Q31        (Q0.31 fixed-point)
//   8 = StochRound (Stochastic Rounding 32->8)
// Operation mode: decode only (encode paths in per-module files)
// Reference: OCP MX Spec https://www.opencompute.org/projects/microscaling-formats-mx
// Co-author: Opus 4.6
`default_nettype none

module block_floats_pack (
    input  wire [3:0]   format_id,
    // Generic input: up to 256-bit element data + 8-bit block exp
    input  wire [255:0] data_in,
    input  wire [7:0]   block_exp,
    // Q15/Q31 multiply inputs (second operand)
    input  wire [31:0]  operand_b,
    // Output: 16-bit result (single element decode / multiply result)
    output reg  [15:0]  result_out,
    // LNS multiply output
    output reg  [7:0]   lns_result,
    // Q31 result
    output reg  [31:0]  q31_result
);

    // --- MXFP4 single-element decode ---
    wire [15:0] mxfp4_dec_out;
    mxfp4_decode u_mxfp4_dec (
        .fp4_in    (data_in[3:0]),
        .block_exp (block_exp),
        .result_q8 (mxfp4_dec_out)
    );

    // --- MXFP6 E2M3 single-element decode ---
    wire [15:0] mxfp6_e2m3_out;
    mxfp6_decode #(.VARIANT(0)) u_mxfp6_e2m3 (
        .fp6_in    (data_in[5:0]),
        .block_exp (block_exp),
        .result_q8 (mxfp6_e2m3_out)
    );

    // --- MXFP6 E3M2 single-element decode ---
    wire [15:0] mxfp6_e3m2_out;
    mxfp6_decode #(.VARIANT(1)) u_mxfp6_e3m2 (
        .fp6_in    (data_in[5:0]),
        .block_exp (block_exp),
        .result_q8 (mxfp6_e3m2_out)
    );

    // --- MXFP8 E4M3 single-element decode ---
    wire [15:0] mxfp8_e4m3_out;
    mxfp8_decode #(.VARIANT(0)) u_mxfp8_e4m3 (
        .fp8_in    (data_in[7:0]),
        .block_exp (block_exp),
        .result_q8 (mxfp8_e4m3_out)
    );

    // --- MXFP8 E5M2 single-element decode ---
    wire [15:0] mxfp8_e5m2_out;
    mxfp8_decode #(.VARIANT(1)) u_mxfp8_e5m2 (
        .fp8_in    (data_in[7:0]),
        .block_exp (block_exp),
        .result_q8 (mxfp8_e5m2_out)
    );

    // --- LNS8 decode ---
    wire [15:0] lns8_dec_out;
    lns8_decode u_lns8_dec (
        .lns8_in   (data_in[7:0]),
        .result_q8 (lns8_dec_out)
    );

    // --- LNS8 multiply ---
    wire [7:0] lns8_mul_out;
    lns8_mul u_lns8_mul (
        .a_lns      (data_in[7:0]),
        .b_lns      (operand_b[7:0]),
        .result_lns (lns8_mul_out)
    );

    // --- Q15 multiply ---
    wire [15:0] q15_mul_out;
    q15_mul u_q15_mul (
        .a_q15     (data_in[15:0]),
        .b_q15     (operand_b[15:0]),
        .result_q15(q15_mul_out)
    );

    // --- Q31 multiply ---
    wire [31:0] q31_mul_out;
    q31_mul u_q31_mul (
        .a_q31     (data_in[31:0]),
        .b_q31     (operand_b),
        .result_q31(q31_mul_out)
    );

    // --- StochRound combinational (32->8) ---
    wire [7:0] sr_out;
    stoch_round_comb #(.WIDE(32), .NARROW(8)) u_sr_comb (
        .val_in  (data_in[31:0]),
        .lfsr_val(block_exp[7:0] == 8'h00 ? 16'hACE1 : {block_exp, block_exp}),
        .val_out (sr_out)
    );

    // --- Output mux ---
    always @(*) begin
        result_out = 16'h0000;
        lns_result = 8'h00;
        q31_result = 32'h00000000;

        case (format_id)
            4'd0: result_out = mxfp4_dec_out;
            4'd1: result_out = mxfp6_e2m3_out;
            4'd2: result_out = mxfp6_e3m2_out;
            4'd3: result_out = mxfp8_e4m3_out;
            4'd4: result_out = mxfp8_e5m2_out;
            4'd5: begin
                result_out = lns8_dec_out;
                lns_result = lns8_mul_out;
            end
            4'd6: result_out = q15_mul_out;
            4'd7: begin
                result_out = q31_mul_out[15:0];
                q31_result = q31_mul_out;
            end
            4'd8: result_out = {8'h00, sr_out};
            default: result_out = 16'h0000;
        endcase
    end
endmodule
`default_nettype wire
