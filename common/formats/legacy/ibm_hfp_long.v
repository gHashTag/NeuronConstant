// ibm_hfp_long.v — 64-bit IBM System/360 Hex Floating-Point (Long)
// Format: 1S[63] + 7E[62:56] (biased by 64, base-16) + 56M[55:0]
// Level: IDENTITY — unsupported_in_f32; width > 32. Storage + identity passthrough.
// TODO: faithful base-16 arithmetic deferred to Phase 2
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind::IbmHfpLong
`timescale 1ns/1ps
`default_nettype none

module ibm_hfp_long (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] din,
    input  wire        load,
    output wire [63:0] dout,
    output wire        sign,
    output wire [6:0]  exp_base16,
    output wire [55:0] hex_mant
);

    reg [63:0] storage_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            storage_r <= 64'h0;
        else if (load)
            storage_r <= din;
    end

    assign dout       = storage_r;
    assign sign       = storage_r[63];
    assign exp_base16 = storage_r[62:56];
    assign hex_mant   = storage_r[55:0];
    // decode = raw, encode = input (identity)

endmodule
`default_nettype wire
