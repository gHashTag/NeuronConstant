// binary256.v — IEEE 754-2008 binary256 Octuple precision
// Format: 1S[255] + 19E[254:236] + 236M[235:0]
// Level: IDENTITY — unsupported_in_f32; width > 32 (256-bit)
// TODO: faithful arithmetic deferred to Phase 2
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind::Binary256
`timescale 1ns/1ps
`default_nettype none

module binary256 (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [255:0] din,
    input  wire         load,
    output wire [255:0] dout,
    output wire         sign,
    output wire [18:0]  biased_exp,   // bias = 262143
    output wire [235:0] mantissa
);

    reg [255:0] storage_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            storage_r <= 256'h0;
        else if (load)
            storage_r <= din;
    end

    assign dout       = storage_r;
    assign sign       = storage_r[255];
    assign biased_exp = storage_r[254:236];
    assign mantissa   = storage_r[235:0];

endmodule
`default_nettype wire
