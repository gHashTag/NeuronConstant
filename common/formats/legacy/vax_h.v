// vax_h.v — 128-bit VAX H-float
// Format: 1S + 15E (bias=16384) + 112M across 8x16-bit words (PDP-11 ordering)
// Level: IDENTITY — unsupported_in_f32; width > 32 (128-bit)
// TODO: faithful arithmetic deferred to Phase 2
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind::VaxH
`timescale 1ns/1ps
`default_nettype none

module vax_h (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [127:0] din,
    input  wire         load,
    output wire [127:0] dout,
    output wire         sign,
    output wire [14:0]  biased_exp,   // bias = 16384
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
    // VAX H-float: word0[15:0] = {S, EXP[14:0]}, word1..7 = mantissa
    assign sign       = storage_r[15];
    assign biased_exp = storage_r[14:0];
    assign mantissa   = storage_r[127:16];

endmodule
`default_nettype wire
