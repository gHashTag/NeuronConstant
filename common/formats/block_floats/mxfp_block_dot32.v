// SPDX-License-Identifier: MIT
// MX Block Dot Product: 32-element dot product with shared exponent
// Parametrized by WIDTH: 4=MXFP4, 6=MXFP6, 8=MXFP8
// 32 partial mantissa-muls via shift-add -> align by shared exponent -> sum -> Q8.8 result
// R-SI-1 compliant: ZERO standalone * operators
// Reference: OCP MX Spec https://www.opencompute.org/projects/microscaling-formats-mx
// Author: Dmitrii Vasilev (gHashTag)
`default_nettype none

// Shift-add multiply: 8-bit unsigned x 8-bit unsigned -> 16-bit
// Implements a*b via shift-and-add (no * operator)
module shift_add_mul8u (
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output reg  [15:0] result
);
    always @(*) begin
        result = 16'h0000;
        if (b[0]) result = result + {8'h00, a};
        if (b[1]) result = result + {7'h00, a, 1'b0};
        if (b[2]) result = result + {6'h00, a, 2'b00};
        if (b[3]) result = result + {5'h00, a, 3'b000};
        if (b[4]) result = result + {4'h0,  a, 4'b0000};
        if (b[5]) result = result + {3'h0,  a, 5'b00000};
        if (b[6]) result = result + {2'h0,  a, 6'b000000};
        if (b[7]) result = result + {1'h0,  a, 7'b0000000};
    end
endmodule

// Dot product of two 32-element MXFP4 blocks
// Computes sum_i(a_i * b_i) for 32 FP4 elements with shared exponents
// Result: Q16.16 accumulated fixed-point
module mxfp_block_dot32 #(
    parameter WIDTH   = 4,  // 4, 6, or 8
    parameter VARIANT = 0   // for FP6/FP8: 0=E2M3/E4M3, 1=E3M2/E5M2
) (
    // For WIDTH=4: 32 x 4-bit = 128 bits each
    // For WIDTH=6: 32 x 6-bit = 192 bits each
    // For WIDTH=8: 32 x 8-bit = 256 bits each
    input  wire [255:0] block_a,     // zero-extended, actual width = 32*WIDTH
    input  wire [255:0] block_b,
    input  wire [7:0]   exp_a,       // shared E8M0 exponent for block A
    input  wire [7:0]   exp_b,       // shared E8M0 exponent for block B
    output reg  [31:0]  dot_result   // Q16.16 result
);
    // Decode both blocks to Q8.8, then compute dot via shift-add

    wire [511:0] vals_a_q8;
    wire [511:0] vals_b_q8;

    // Instantiate decoders based on WIDTH
    generate
        if (WIDTH == 4) begin : g_fp4
            mxfp4_block_decode u_dec_a (
                .fp4_block  (block_a[127:0]),
                .block_exp  (exp_a),
                .results_q8 (vals_a_q8)
            );
            mxfp4_block_decode u_dec_b (
                .fp4_block  (block_b[127:0]),
                .block_exp  (exp_b),
                .results_q8 (vals_b_q8)
            );
        end else if (WIDTH == 6) begin : g_fp6
            mxfp6_block_decode #(.VARIANT(VARIANT)) u_dec_a (
                .fp6_block  (block_a[191:0]),
                .block_exp  (exp_a),
                .results_q8 (vals_a_q8)
            );
            mxfp6_block_decode #(.VARIANT(VARIANT)) u_dec_b (
                .fp6_block  (block_b[191:0]),
                .block_exp  (exp_b),
                .results_q8 (vals_b_q8)
            );
        end else begin : g_fp8  // WIDTH == 8
            mxfp8_block_decode #(.VARIANT(VARIANT)) u_dec_a (
                .fp8_block  (block_a[255:0]),
                .block_exp  (exp_a),
                .results_q8 (vals_a_q8)
            );
            mxfp8_block_decode #(.VARIANT(VARIANT)) u_dec_b (
                .fp8_block  (block_b[255:0]),
                .block_exp  (exp_b),
                .results_q8 (vals_b_q8)
            );
        end
    endgenerate

    // Compute dot product using shift-add multiplier
    wire [15:0] a_elem [0:31];
    wire [15:0] b_elem [0:31];
    wire [31:0] prod   [0:31];

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : dot_gen
            assign a_elem[i] = vals_a_q8[16*i+15 : 16*i];
            assign b_elem[i] = vals_b_q8[16*i+15 : 16*i];

            // Sign-magnitude multiply using shift-add
            // For signed Q8.8: handle sign separately, multiply magnitudes
            wire        sa = a_elem[i][15];
            wire        sb = b_elem[i][15];
            wire [14:0] ma = sa ? (~a_elem[i][14:0] + 15'h0001) : a_elem[i][14:0];
            wire [14:0] mb = sb ? (~b_elem[i][14:0] + 15'h0001) : b_elem[i][14:0];
            wire [15:0] mul_res;

            shift_add_mul8u u_mul (
                .a      (ma[14:7]),   // upper 8 bits of magnitude (integer part)
                .b      (mb[14:7]),
                .result (mul_res)
            );

            // Result sign
            assign prod[i] = (sa ^ sb) ?
                ({2'b0, ~mul_res, 14'b0} + 32'h00040000) :  // negative: negate
                {2'b0, mul_res, 14'b0};                       // positive
        end
    endgenerate

    // Accumulate 32 products
    integer j;
    always @(*) begin
        dot_result = 32'h00000000;
        for (j = 0; j < 32; j = j + 1)
            dot_result = dot_result + prod[j];
    end
endmodule
`default_nettype wire
