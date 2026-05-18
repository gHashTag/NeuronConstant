// tri_mant_mul8.v — 8-bit × 8-bit unsigned mantissa multiplier
// Wider variant for Posit16 / FP8 / bfloat16 mantissa multiplication.
// R-SI-1 compliant: zero standalone * operators. Shift-add only.
// Verilog-2005
`default_nettype none

module tri_mant_mul8 (
    input  wire [7:0] a,        // 8-bit unsigned multiplicand
    input  wire [7:0] b,        // 8-bit unsigned multiplier
    output wire [15:0] result   // 16-bit unsigned product
);

    // 8 partial products via conditional shift
    wire [15:0] p0 = a[0] ? {8'h00, b}          : 16'h0000;
    wire [15:0] p1 = a[1] ? {7'b0, b, 1'b0}      : 16'h0000;
    wire [15:0] p2 = a[2] ? {6'b0, b, 2'b00}    : 16'h0000;
    wire [15:0] p3 = a[3] ? {5'b0, b, 3'b000}   : 16'h0000;
    wire [15:0] p4 = a[4] ? {4'b0, b, 4'b0000}  : 16'h0000;
    wire [15:0] p5 = a[5] ? {3'b0, b, 5'b00000} : 16'h0000;
    wire [15:0] p6 = a[6] ? {2'b0, b, 6'b000000}: 16'h0000;
    wire [15:0] p7 = a[7] ? {1'b0, b, 7'b0000000}:16'h0000;

    // Sum all partial products (carry-propagate adder chain, synthesiser-friendly)
    wire [15:0] s01  = p0 + p1;
    wire [15:0] s23  = p2 + p3;
    wire [15:0] s45  = p4 + p5;
    wire [15:0] s67  = p6 + p7;
    wire [15:0] s0123 = s01 + s23;
    wire [15:0] s4567 = s45 + s67;

    assign result = s0123 + s4567;

endmodule
`default_nettype wire
