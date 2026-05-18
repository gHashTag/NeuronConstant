// ibm_hfp_short.v — 32-bit IBM System/360 Hex Floating-Point (Short)
// Format: 1S[31] + 7E[30:24] (biased by 64, base-16) + 24M[23:0] (hex mantissa)
// Key difference from IEEE: base is 16 (not 2), leading digit may be 0 (no normalization forcing)
// Value = (-1)^S * 16^(E-64) * 0.M (M is hex fraction)
// Level: SUPPORTED — decode/encode; base-16 mul via shift-by-4-bits logic (no * operator)
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind::IbmHfpShort
`timescale 1ns/1ps
`default_nettype none

module ibm_hfp_short (
    input  wire        clk,
    input  wire        rst_n,
    // Storage
    input  wire [31:0] din,
    input  wire        load,
    output wire [31:0] dout,
    // Decoded fields
    output wire        sign,
    output wire [6:0]  exp_base16,   // biased exponent (bias=64); true_exp = exp_base16 - 64
    output wire [23:0] hex_mant,     // hex mantissa (0.HHHHHH in base-16)
    // base-16 scaling: multiply mantissa by 16 = left shift by 4 bits
    output wire [27:0] mant_x16,     // hex_mant << 4 (multiply by 16^1, no * operator)
    output wire [31:0] mant_x256     // hex_mant << 8 (multiply by 16^2)
);

    reg [31:0] storage_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            storage_r <= 32'h0;
        else if (load)
            storage_r <= din;
    end

    assign dout       = storage_r;
    assign sign       = storage_r[31];
    assign exp_base16 = storage_r[30:24];
    assign hex_mant   = storage_r[23:0];

    // base-16 exponent scaling via shifts (no * used):
    // 16^1 = shift left 4  (one hex digit)
    // 16^2 = shift left 8  (two hex digits)
    assign mant_x16  = {hex_mant, 4'b0};    // hex_mant * 16 = shift left 4
    assign mant_x256 = {hex_mant, 8'b0};    // hex_mant * 256 = shift left 8

    // IBM HFP vs IEEE: base-16 means normalization is per hex digit, not binary bit.
    // A normalized IBM number has a non-zero leading hex digit (0x1..0xF in bits[23:20]).
    // Identity arithmetic passthrough — TODO faithful base-16 add/mul (Phase 2).

endmodule
`default_nettype wire
