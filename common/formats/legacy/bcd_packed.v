// bcd_packed.v — Packed BCD: 2 decimal digits per byte (8-bit)
// Add via classic 4-bit BCD adder with carry adjust (no * operator)
// Level: SUPPORTED
// Origin: trios-trainer-igla/src/fake_quant.rs BCD encoding support
`timescale 1ns/1ps
`default_nettype none

module bcd_packed (
    input  wire [7:0]  a,        // packed BCD: {high_digit[3:0], low_digit[3:0]}
    input  wire [7:0]  b,
    input  wire        cin,
    output wire [7:0]  sum,
    output wire        cout
);

    // --------------------------------------------------------------------------
    // Low nibble BCD add: a[3:0] + b[3:0] + cin
    // --------------------------------------------------------------------------
    wire [4:0] low_raw  = {1'b0, a[3:0]} + {1'b0, b[3:0]} + {4'b0, cin};
    wire       low_adj  = (low_raw > 5'd9);             // need +6 adjust
    wire [4:0] low_sum5 = low_adj ? (low_raw + 5'd6) : low_raw;
    wire       low_carry = low_sum5[4];

    // --------------------------------------------------------------------------
    // High nibble BCD add: a[7:4] + b[7:4] + low_carry
    // --------------------------------------------------------------------------
    wire [4:0] hi_raw   = {1'b0, a[7:4]} + {1'b0, b[7:4]} + {4'b0, low_carry};
    wire       hi_adj   = (hi_raw > 5'd9);
    wire [4:0] hi_sum5  = hi_adj ? (hi_raw + 5'd6) : hi_raw;

    assign sum  = {hi_sum5[3:0], low_sum5[3:0]};
    assign cout = hi_sum5[4];

endmodule
`default_nettype wire
