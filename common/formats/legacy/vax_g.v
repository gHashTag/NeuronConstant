// vax_g.v — 64-bit VAX G-float
// Format: 1S + 11E (bias=1024) + 52M (IEEE-like layout, but VAX byte order)
// Level: IDENTITY — unsupported_in_f32; width > 32
// TODO: faithful arithmetic deferred to Phase 2
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind::VaxG
`timescale 1ns/1ps
`default_nettype none

module vax_g (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] din,
    input  wire        load,
    output wire [63:0] dout,
    output wire        sign,
    output wire [10:0] biased_exp,   // bias = 1024
    output wire [51:0] mantissa
);

    reg [63:0] storage_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            storage_r <= 64'h0;
        else if (load)
            storage_r <= din;
    end

    assign dout       = storage_r;
    // VAX G-float: word0[15:0] = {S, EXP[10:0], M[3:0]}, then 48 more mant bits
    assign sign       = storage_r[15];
    assign biased_exp = storage_r[14:4];
    assign mantissa   = {storage_r[63:16], storage_r[3:0]};

endmodule
`default_nettype wire
