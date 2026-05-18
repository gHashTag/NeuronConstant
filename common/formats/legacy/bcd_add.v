// bcd_add.v — Generic N-digit BCD addition with carry chain
// Parameter N_DIGITS: number of BCD decimal digits (each 4 bits)
// Width = N_DIGITS << 2 bits (using shifts to avoid * operator, R-SI-1 clean)
// Level: SUPPORTED
`timescale 1ns/1ps
`default_nettype none

// N_DIGITS=1: 4-bit, N_DIGITS=2: 8-bit, N_DIGITS=4: 16-bit, N_DIGITS=8: 32-bit
module bcd_add #(
    parameter N_DIGITS = 4         // default: 4 digits (16-bit BCD)
) (
    input  wire [(N_DIGITS<<2)-1:0] a,
    input  wire [(N_DIGITS<<2)-1:0] b,
    input  wire                      cin,
    output wire [(N_DIGITS<<2)-1:0]  sum,
    output wire                      cout
);

    // Internal carry chain: N_DIGITS+1 entries
    wire [N_DIGITS:0] carry;
    assign carry[0] = cin;
    assign cout      = carry[N_DIGITS];

    genvar i;
    generate
        for (i = 0; i < N_DIGITS; i = i + 1) begin : digit_add
            localparam LSB = (i << 2);       // i * 4 via left shift
            localparam MSB = (i << 2) + 3;   // i * 4 + 3 via shift+add
            // Extract nibbles
            wire [3:0] a_nibble = a[MSB : LSB];
            wire [3:0] b_nibble = b[MSB : LSB];
            // Raw 5-bit add
            wire [4:0] raw_sum  = {1'b0, a_nibble} + {1'b0, b_nibble} + {4'b0, carry[i]};
            // BCD adjust: if > 9 add 6
            wire       need_adj = (raw_sum > 5'd9);
            wire [4:0] adj_sum  = need_adj ? (raw_sum + 5'd6) : raw_sum;
            assign sum[MSB : LSB] = adj_sum[3:0];
            assign carry[i+1]     = adj_sum[4];
        end
    endgenerate

endmodule
`default_nettype wire
