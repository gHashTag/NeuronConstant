// decimal64.v — IEEE 754-2008 Decimal64 BID encoding
// Format: 1S + 8E (combination) + 50T (trailing significand)
// Level: IDENTITY (storage struct; arithmetic TODO faithful)
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind::Decimal64
`timescale 1ns/1ps
`default_nettype none

module decimal64 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] din,
    input  wire        load,
    output wire [63:0] dout,
    output wire        sign,
    output wire [9:0]  biased_exp,
    output wire [49:0] trailing_sig
);

    // 64-bit storage
    reg [63:0] storage_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            storage_r <= 64'h0;
        else if (load)
            storage_r <= din;
    end

    assign dout         = storage_r;
    assign sign         = storage_r[63];
    assign biased_exp   = {4'b0, storage_r[62:57]};   // simplified combination
    assign trailing_sig = storage_r[49:0];

    // TODO: faithful BID decode (Phase 2)

endmodule
`default_nettype wire
