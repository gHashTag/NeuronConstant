// SPDX-License-Identifier: MIT
// tri_mant_mul_wide — parametric shift-add mantissa multiplier
//
// R-SI-1 compliant: ZERO standalone '*' operators.
// Implements WIDTH × WIDTH → 2*WIDTH unsigned multiply via shift-add
// (binary partial-product expansion).
//
// Common/formats/goldenfloat canonical copy.
// If common/formats/ai/tri_mant_mul.v exists, this module provides
// a wider, parameterised variant (WIDTH up to 32).
//
// Verilog-2005, default_nettype none/wire.

`default_nettype none

// ---------------------------------------------------------------------------
// tri_mant_mul_wide
//   Parameters : WIDTH — operand bit width (e.g. 10 for GF16 full mant)
//   Inputs     : a, b — WIDTH-bit unsigned mantissa (with implicit leading 1)
//   Output     : product — 2*WIDTH-bit result
// ---------------------------------------------------------------------------
module tri_mant_mul_wide #(
    parameter WIDTH = 10
) (
    input  wire [WIDTH-1:0]   a,
    input  wire [WIDTH-1:0]   b,
    output wire [2*WIDTH-1:0] product
);

    // Partial products via generate — one per bit of b.
    // pp[i] = b[i] ? (a << i) : 0  (2*WIDTH wide, zero-extended)
    // Sum tree built with plain + (Verilog structural add, not mul op).

    genvar i;

    // Declare array of partial products
    wire [2*WIDTH-1:0] pp [0:WIDTH-1];

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pp
            // Shift a left by i, zero-extend to 2*WIDTH
            wire [2*WIDTH-1:0] shifted;
            assign shifted = {{WIDTH{1'b0}}, a} << i;
            assign pp[i] = b[i] ? shifted : {2*WIDTH{1'b0}};
        end
    endgenerate

    // Sum all partial products using a combinational adder chain.
    // Synthesis will optimise to a carry-save / Wallace tree as needed.
    wire [2*WIDTH-1:0] psum [0:WIDTH-1];
    assign psum[0] = pp[0];

    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_sum
            assign psum[i] = psum[i-1] + pp[i];
        end
    endgenerate

    assign product = psum[WIDTH-1];

endmodule

`default_nettype wire
