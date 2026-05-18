// vax_d.v — 64-bit VAX D-float
// Format: 1S + 8E (bias=128) + 55M across 4x16-bit words (PDP-11 ordering)
// Level: IDENTITY — unsupported_in_f32; width > 32. Storage + identity passthrough.
// TODO: faithful arithmetic deferred to Phase 2
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind::VaxD
`timescale 1ns/1ps
`default_nettype none

module vax_d (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] din,
    input  wire        load,
    output wire [63:0] dout,
    // Field decode (combinational)
    output wire        sign,
    output wire [7:0]  biased_exp,   // bias = 128
    output wire [54:0] mantissa
);

    reg [63:0] storage_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            storage_r <= 64'h0;
        else if (load)
            storage_r <= din;
    end

    assign dout       = storage_r;
    // VAX D-float: first 16-bit word [15:0] = {S, EXP[7:0], M[6:0]}
    assign sign       = storage_r[15];
    assign biased_exp = storage_r[14:7];
    // mantissa spans [6:0] of word0 + words 1-3 = 7 + 48 = 55 bits
    assign mantissa   = {storage_r[63:16], storage_r[6:0]};

endmodule
`default_nettype wire
