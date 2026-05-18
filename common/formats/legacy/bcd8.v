// bcd8.v — 8-bit BCD = 2 decimal digits
// Uses bcd_packed as 1-stage add
// Level: SUPPORTED
`timescale 1ns/1ps
`default_nettype none

module bcd8 (
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    input  wire        cin,
    output wire [7:0]  sum,
    output wire        cout
);

    bcd_packed u_add (
        .a    (a),
        .b    (b),
        .cin  (cin),
        .sum  (sum),
        .cout (cout)
    );

endmodule
`default_nettype wire
