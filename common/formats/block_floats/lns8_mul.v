// SPDX-License-Identifier: MIT
// LNS8 Multiply: result_log = a_log + b_log, sign XOR
// This is the key advantage of LNS: multiplication = addition
// R-SI-1 keystone: ZERO multiplication operators used
// Author: Dmitrii Vasilev (gHashTag)
`default_nettype none

// LNS8 multiply: a * b in LNS domain
// a_lns = {sa, la[6:0]}, b_lns = {sb, lb[6:0]}
// result_lns = {sa^sb, la+lb} (log addition, no overflow wrapping)
module lns8_mul (
    input  wire [7:0] a_lns,        // LNS8 operand A
    input  wire [7:0] b_lns,        // LNS8 operand B
    output reg  [7:0] result_lns    // LNS8 product
);
    wire sa = a_lns[7];
    wire sb = b_lns[7];
    wire [6:0] la = a_lns[6:0];
    wire [6:0] lb = b_lns[6:0];

    wire result_sign = sa ^ sb;  // sign XOR

    // Log addition (R-SI-1: pure addition, no multiplication)
    wire [7:0] log_sum = {1'b0, la} + {1'b0, lb};  // 8-bit sum

    // Handle zero: if either operand is zero (log_bits=0 and sign=0), result=0
    wire a_zero = (a_lns == 8'h00);
    wire b_zero = (b_lns == 8'h00);

    // Saturate log sum to 7 bits
    wire [6:0] log_sat = log_sum[7] ? 7'h7F : log_sum[6:0];

    always @(*) begin
        if (a_zero || b_zero)
            result_lns = 8'h00;
        else
            result_lns = {result_sign, log_sat};
    end
endmodule

// LNS8 divide: a / b = result_log = a_log - b_log
module lns8_div (
    input  wire [7:0] a_lns,
    input  wire [7:0] b_lns,
    output reg  [7:0] result_lns
);
    wire sa = a_lns[7];
    wire sb = b_lns[7];
    wire [6:0] la = a_lns[6:0];
    wire [6:0] lb = b_lns[6:0];

    wire result_sign = sa ^ sb;

    // Log subtraction
    wire [7:0] log_diff = {1'b0, la} - {1'b0, lb};
    wire [6:0] log_sat  = log_diff[7] ? 7'h00 : log_diff[6:0]; // underflow -> 0

    wire b_zero = (b_lns == 8'h00);

    always @(*) begin
        if (b_zero)
            result_lns = 8'h7F; // infinity / NaN representation
        else
            result_lns = {result_sign, log_sat};
    end
endmodule

// LNS8 square: a^2 = log*2 = log << 1
module lns8_square (
    input  wire [7:0] a_lns,
    output reg  [7:0] result_lns
);
    wire [6:0] la  = a_lns[6:0];
    wire [7:0] log2 = {la, 1'b0};  // shift left 1 = multiply log by 2
    wire [6:0] log_sat = log2[7] ? 7'h7F : log2[6:0];

    always @(*) begin
        result_lns = {1'b0, log_sat};  // square always positive
    end
endmodule
`default_nettype wire
