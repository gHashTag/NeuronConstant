// bcd16.v — 16-bit BCD = 4 decimal digits
// Two cascaded bcd_packed stages (each handles 2 digits)
// Level: SUPPORTED
`timescale 1ns/1ps
`default_nettype none

module bcd16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        cin,
    output wire [15:0] sum,
    output wire        cout
);

    wire mid_carry;

    // Low byte: digits 0-1
    bcd_packed u_low (
        .a    (a[7:0]),
        .b    (b[7:0]),
        .cin  (cin),
        .sum  (sum[7:0]),
        .cout (mid_carry)
    );

    // High byte: digits 2-3
    bcd_packed u_hi (
        .a    (a[15:8]),
        .b    (b[15:8]),
        .cin  (mid_carry),
        .sum  (sum[15:8]),
        .cout (cout)
    );

endmodule
`default_nettype wire
