// fp80.v — x87 80-bit Extended Precision
// Format: 1S[79] + 15E[78:64] + 1J[63] (integer bit, explicit) + 63M[62:0]
// Level: IDENTITY — unsupported_in_f32; width > 32
// TODO: faithful arithmetic deferred to Phase 2
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind::Fp80
`timescale 1ns/1ps
`default_nettype none

module fp80 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [79:0] din,
    input  wire        load,
    output wire [79:0] dout,
    // Decode fields (combinational)
    output wire        sign,
    output wire [14:0] biased_exp,    // bias = 16383
    output wire        integer_bit,   // explicit leading 1
    output wire [62:0] mantissa
);

    reg [79:0] storage_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            storage_r <= 80'h0;
        else if (load)
            storage_r <= din;
    end

    assign dout        = storage_r;
    assign sign        = storage_r[79];
    assign biased_exp  = storage_r[78:64];
    assign integer_bit = storage_r[63];
    assign mantissa    = storage_r[62:0];

    // decode = raw fields, encode = input (identity arithmetic)
    // TODO Phase 2: fp80 normalization and rounding

endmodule
`default_nettype wire
