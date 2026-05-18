// decimal128.v — IEEE 754-2008 Decimal128 BID encoding (128-bit)
// Level: IDENTITY — unsupported_in_f32; width > 32. Storage + identity passthrough.
// TODO: faithful arithmetic deferred to Phase 2
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind::Decimal128
`timescale 1ns/1ps
`default_nettype none

module decimal128 (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [127:0] din,
    input  wire         load,
    output wire [127:0] dout
);

    // 128-bit storage — identity passthrough
    reg [127:0] storage_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            storage_r <= 128'h0;
        else if (load)
            storage_r <= din;
    end

    assign dout = storage_r;
    // decode = raw, encode = input (identity)

endmodule
`default_nettype wire
