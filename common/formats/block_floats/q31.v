// SPDX-License-Identifier: MIT
// Q0.31 Fixed-Point Format (32-bit signed, 31 fractional bits, range [-1, 1))
// Multiply via shift-add 32x32 -> Q0.62 -> downshift to Q0.31 with saturation
// R-SI-1 compliant: ZERO standalone * operators
// Co-author: Opus 4.6
`default_nettype none

// Q0.31 multiply: a * b -> result in Q0.31 with saturation
module q31_mul (
    input  wire [31:0] a_q31,
    input  wire [31:0] b_q31,
    output reg  [31:0] result_q31
);
    wire        sa = a_q31[31];
    wire        sb = b_q31[31];
    wire [30:0] ma = sa ? (~a_q31[30:0] + 31'h00000001) : a_q31[30:0];
    wire [30:0] mb = sb ? (~b_q31[30:0] + 31'h00000001) : b_q31[30:0];

    // Shift-add multiply 31x31 -> 62-bit
    // To keep RTL manageable: split ma into 4 bytes and accumulate
    // ma = {ma[30:24], ma[23:16], ma[15:8], ma[7:0]}
    // prod = sum over i of (mb << i) if ma[i]=1

    // We implement via 4 x 8-bit partial products using 31x8 shift-add chunks
    // chunk_k = mb * ma[8k+7:8k] via shift-add (k=0..3, last chunk 7-bit)

    reg [61:0] prod_abs;
    integer i;

    always @(*) begin
        prod_abs = 62'h0;
        for (i = 0; i < 31; i = i + 1) begin
            if (ma[i])
                prod_abs = prod_abs + ({31'h0, mb} << i);
        end
    end

    // Q0.62 -> Q0.31: take bits [61:31]
    wire [30:0] result_abs = prod_abs[61:31];
    wire        result_sign = sa ^ sb;

    wire both_min = (a_q31 == 32'h80000000) && (b_q31 == 32'h80000000);

    always @(*) begin
        if (both_min)
            result_q31 = 32'h7FFFFFFF;
        else if (result_sign)
            result_q31 = {1'b1, ~result_abs + 31'h00000001};
        else
            result_q31 = {1'b0, result_abs};
    end
endmodule

// Q0.31 add with saturation
module q31_add (
    input  wire [31:0] a_q31,
    input  wire [31:0] b_q31,
    output reg  [31:0] result_q31
);
    wire [32:0] sum = {a_q31[31], a_q31} + {b_q31[31], b_q31};

    always @(*) begin
        if (~a_q31[31] && ~b_q31[31] && sum[31])
            result_q31 = 32'h7FFFFFFF;
        else if (a_q31[31] && b_q31[31] && ~sum[31])
            result_q31 = 32'h80000000;
        else
            result_q31 = sum[31:0];
    end
endmodule

// Q0.31 accumulate (clocked)
module q31_acc (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [31:0] din_q31,
    output reg  [31:0] acc_q31
);
    wire [31:0] sum;
    q31_add u_add (
        .a_q31     (acc_q31),
        .b_q31     (din_q31),
        .result_q31(sum)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)   acc_q31 <= 32'h00000000;
        else if (en)  acc_q31 <= sum;
    end
endmodule
`default_nettype wire
