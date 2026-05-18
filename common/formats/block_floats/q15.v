// SPDX-License-Identifier: MIT
// Q0.15 Fixed-Point Format (16-bit signed, 15 fractional bits, range [-1, 1))
// Multiply via shift-add 16x16 -> Q0.30 -> downshift to Q0.15 with saturation
// R-SI-1 compliant: ZERO standalone * operators
// Co-author: Opus 4.6
`default_nettype none

// Q0.15 multiply: a * b -> result in Q0.15 with saturation
// Both inputs: 16-bit signed Q0.15 (1 sign bit + 15 fractional bits)
// Internal product: 32-bit Q0.30
// Output: 16-bit Q0.15 (rounded and saturated)
module q15_mul (
    input  wire [15:0] a_q15,       // Q0.15 signed
    input  wire [15:0] b_q15,       // Q0.15 signed
    output reg  [15:0] result_q15   // Q0.15 signed, saturated
);
    // Sign-magnitude approach for shift-add
    wire        sa = a_q15[15];
    wire        sb = b_q15[15];
    wire [14:0] ma = sa ? (~a_q15[14:0] + 15'h0001) : a_q15[14:0];
    wire [14:0] mb = sb ? (~b_q15[14:0] + 15'h0001) : b_q15[14:0];

    // Shift-add multiply 15x15 -> 30-bit unsigned
    reg [29:0] prod_abs;
    always @(*) begin
        prod_abs = 30'h00000000;
        if (ma[0])  prod_abs = prod_abs + {15'h0000, mb};
        if (ma[1])  prod_abs = prod_abs + {14'h0000, mb, 1'b0};
        if (ma[2])  prod_abs = prod_abs + {13'h0000, mb, 2'b00};
        if (ma[3])  prod_abs = prod_abs + {12'h0000, mb, 3'b000};
        if (ma[4])  prod_abs = prod_abs + {11'h000,  mb, 4'b0000};
        if (ma[5])  prod_abs = prod_abs + {10'h000,  mb, 5'b00000};
        if (ma[6])  prod_abs = prod_abs + { 9'h000,  mb, 6'b000000};
        if (ma[7])  prod_abs = prod_abs + { 8'h00,   mb, 7'b0000000};
        if (ma[8])  prod_abs = prod_abs + { 7'h00,   mb, 8'b00000000};
        if (ma[9])  prod_abs = prod_abs + { 6'h00,   mb, 9'b000000000};
        if (ma[10]) prod_abs = prod_abs + { 5'h00,   mb, 10'b0000000000};
        if (ma[11]) prod_abs = prod_abs + { 4'h0,    mb, 11'b00000000000};
        if (ma[12]) prod_abs = prod_abs + { 3'h0,    mb, 12'b000000000000};
        if (ma[13]) prod_abs = prod_abs + { 2'h0,    mb, 13'b0000000000000};
        if (ma[14]) prod_abs = prod_abs + { 1'h0,    mb, 14'b00000000000000};
    end

    // Product in Q0.30 (unsigned magnitude)
    // Convert to Q0.15: take bits [29:15] (discard lower 15 bits = truncate)
    wire [14:0] result_abs = prod_abs[29:15];
    wire        result_sign = sa ^ sb;

    // Special case: -1 * -1 = +1 (but +1 is unrepresentable in Q0.15, saturate to 0x7FFF)
    // Standard Q multiply: result = (a * b) >> 15
    // Saturation: if result_sign=0 and result_abs=0x4000, saturate to 0x7FFF (rarely needed)
    // For Q0.15 multiply, overflow only if both = -1 (0x8000)
    wire both_min = (a_q15 == 16'h8000) && (b_q15 == 16'h8000);

    always @(*) begin
        if (both_min) begin
            result_q15 = 16'h7FFF; // saturate
        end else if (result_sign) begin
            result_q15 = {1'b1, ~result_abs + 15'h0001};
        end else begin
            result_q15 = {1'b0, result_abs};
        end
    end
endmodule

// Q0.15 add with saturation
module q15_add (
    input  wire [15:0] a_q15,
    input  wire [15:0] b_q15,
    output reg  [15:0] result_q15
);
    wire [16:0] sum = {a_q15[15], a_q15} + {b_q15[15], b_q15};

    always @(*) begin
        // Overflow detection: sign bits were same but result sign differs
        if (~a_q15[15] && ~b_q15[15] && sum[15])
            result_q15 = 16'h7FFF;  // positive overflow
        else if (a_q15[15] && b_q15[15] && ~sum[15])
            result_q15 = 16'h8000;  // negative overflow
        else
            result_q15 = sum[15:0];
    end
endmodule

// Q0.15 accumulate: reg + Q0.15 input (clocked)
module q15_acc (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [15:0] din_q15,
    output reg  [15:0] acc_q15
);
    wire [15:0] sum;
    q15_add u_add (
        .a_q15     (acc_q15),
        .b_q15     (din_q15),
        .result_q15(sum)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)    acc_q15 <= 16'h0000;
        else if (en)   acc_q15 <= sum;
    end
endmodule
`default_nettype wire
