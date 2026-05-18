// minifloat.v — Generic configurable minifloat
// Parameters: S_BITS (sign), E_BITS (exponent), M_BITS (mantissa), BIAS
// Total width = S_BITS + E_BITS + M_BITS (must be <= 32)
// Catch-all for exotic 4/8-bit float variants (e.g., E4M3, E5M2, float8)
// Level: SUPPORTED (parameterized storage + decode)
// Origin: trios-trainer-igla/src/fake_quant.rs minifloat/float8 variants
`timescale 1ns/1ps
`default_nettype none

module minifloat #(
    parameter S_BITS = 1,    // sign bits (0 or 1)
    parameter E_BITS = 4,    // exponent bits
    parameter M_BITS = 3,    // mantissa bits
    parameter BIAS   = 7     // exponent bias (default: E4M3 style, bias=7)
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [S_BITS+E_BITS+M_BITS-1:0] din,
    input  wire        load,
    output wire [S_BITS+E_BITS+M_BITS-1:0] dout,
    // Decoded fields
    output wire [S_BITS-1:0]               sign_out,
    output wire [E_BITS-1:0]               exp_out,
    output wire [M_BITS-1:0]               mant_out,
    // Re-encode
    output wire [S_BITS+E_BITS+M_BITS-1:0] encoded
);

    localparam WIDTH = S_BITS + E_BITS + M_BITS;

    reg [WIDTH-1:0] storage_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            storage_r <= {WIDTH{1'b0}};
        else if (load)
            storage_r <= din;
    end

    assign dout     = storage_r;
    // Field extraction: [WIDTH-1] = sign (if S_BITS=1), [WIDTH-2 : M_BITS] = exp, [M_BITS-1:0] = mant
    assign sign_out = storage_r[WIDTH-1 : WIDTH-S_BITS];
    assign exp_out  = storage_r[WIDTH-S_BITS-1 : M_BITS];
    assign mant_out = storage_r[M_BITS-1:0];
    // Round-trip encode
    assign encoded  = {sign_out, exp_out, mant_out};

    // Example instantiations:
    //   E4M3: minifloat #(.S_BITS(1),.E_BITS(4),.M_BITS(3),.BIAS(7))
    //   E5M2: minifloat #(.S_BITS(1),.E_BITS(5),.M_BITS(2),.BIAS(15))
    //   FP4:  minifloat #(.S_BITS(1),.E_BITS(2),.M_BITS(1),.BIAS(1))

endmodule
`default_nettype wire
