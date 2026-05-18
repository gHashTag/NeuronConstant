// vax_f.v — 32-bit VAX F-float
// Format: 1S[15] + 8E[14:7] (bias=128) + 23M[6:0,31:16] (split across 16-bit words)
// VAX/PDP-11 byte ordering: bytes stored {W1[15:0], W0[15:0]} where W0 is HIGH word
// Bit layout of the 32-bit register:
//   Bits [31:16] = W0 (second physical word) = mantissa[22:7]
//   Bits [15:0]  = W1 (first physical word)  = {S, EXP[7:0], mant[6:0]}
// Differences from IEEE-754: bias=128 (not 127), no +infinity/NaN/denormals.
// Level: SUPPORTED — decode/encode
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind::VaxF
`timescale 1ns/1ps
`default_nettype none

module vax_f (
    input  wire        clk,
    input  wire        rst_n,
    // Raw VAX 32-bit word (PDP byte order)
    input  wire [31:0] din,
    input  wire        load,
    output wire [31:0] dout,
    // Decoded fields (logical view)
    output wire        sign,
    output wire [7:0]  biased_exp,   // bias = 128
    output wire [22:0] mantissa,     // implicit leading 1 assumed if exp != 0
    // Re-encoded output (round-trip)
    output wire [31:0] encoded
);

    reg [31:0] storage_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            storage_r <= 32'h0;
        else if (load)
            storage_r <= din;
    end

    assign dout = storage_r;

    // VAX F-float physical layout in 32-bit register (native VAX word):
    //   storage_r[31:16] = fraction high  (mantissa[22:7])
    //   storage_r[15]    = sign
    //   storage_r[14:7]  = exponent (bias 128)
    //   storage_r[6:0]   = mantissa[6:0]
    assign sign        = storage_r[15];
    assign biased_exp  = storage_r[14:7];
    assign mantissa    = {storage_r[31:16], storage_r[6:0]};

    // Re-encode: rebuild identical storage layout
    assign encoded = {mantissa[22:7], sign, biased_exp, mantissa[6:0]};

    // Note: VAX F uses bias=128 vs IEEE bias=127.
    // true_exp = biased_exp - 128 (biased_exp=0 means zero/reserved).
    // No infinity or NaN — hardware raises reserved operand trap instead.

endmodule
`default_nettype wire
