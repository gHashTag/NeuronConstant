// binary128.v — IEEE 754-2008 binary128 Quad precision
// Format: 1S[127] + 15E[126:112] + 112M[111:0]
// Level: IDENTITY — unsupported_in_f32; width > 32
// TODO: faithful arithmetic deferred to Phase 2
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind::Binary128
`timescale 1ns/1ps
`default_nettype none

module binary128 (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [127:0] din,
    input  wire         load,
    output wire [127:0] dout,
    output wire         sign,
    output wire [14:0]  biased_exp,   // bias = 16383
    output wire [111:0] mantissa
);

    reg [127:0] storage_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            storage_r <= 128'h0;
        else if (load)
            storage_r <= din;
    end

    assign dout       = storage_r;
    assign sign       = storage_r[127];
    assign biased_exp = storage_r[126:112];
    assign mantissa   = storage_r[111:0];

endmodule
`default_nettype wire
