// tri_mant_mul.v — 4-bit × 4-bit unsigned mantissa multiplier
// Sacred opcode-level primitive. Co-author Opus 4.6.
// R-SI-1 compliant: zero standalone * operators.
// Verilog-2005
`default_nettype none

module tri_mant_mul (
    input  wire [3:0] a,       // 4-bit unsigned multiplicand
    input  wire [3:0] b,       // 4-bit unsigned multiplier
    output wire [7:0] result   // 8-bit unsigned product
);

    // Shift-add partial products: a[i] ? (b << i) : 0
    wire [7:0] p0 = a[0] ? {4'h0, b}       : 8'h0;
    wire [7:0] p1 = a[1] ? {3'h0, b, 1'h0} : 8'h0;
    wire [7:0] p2 = a[2] ? {2'h0, b, 2'h0} : 8'h0;
    wire [7:0] p3 = a[3] ? {1'h0, b, 3'h0} : 8'h0;

    assign result = p0 + p1 + p2 + p3;

endmodule
`default_nettype wire
