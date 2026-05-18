// cray_float.v — Cray-1 64-bit Floating-Point
// Format: 1S[63] + 15E[62:48] (bias=16384) + 48M[47:0]
// Key differences from IEEE:
//   - No implicit leading 1 (mantissa is stored explicitly, including leading 0)
//   - No denormals, no infinity, no NaN
//   - Normalization: leading mantissa bit must be 1 for normalized numbers
// Level: SUPPORTED — decode/encode
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind::CrayFloat
`timescale 1ns/1ps
`default_nettype none

module cray_float (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] din,
    input  wire        load,
    output wire [63:0] dout,
    // Decode
    output wire        sign,
    output wire [14:0] biased_exp,   // bias = 16384; true_exp = biased_exp - 16384
    output wire [47:0] mantissa,     // explicit (no implicit leading 1)
    output wire        normalized,   // 1 if mantissa[47] == 1 (normalized)
    // Encode (round-trip)
    output wire [63:0] encoded
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
    assign biased_exp = storage_r[62:48];
    assign mantissa   = storage_r[47:0];
    assign normalized = mantissa[47];          // Cray: MSB of mantissa must be 1

    // Re-encode: straightforward reassembly
    assign encoded = {sign, biased_exp, mantissa};

    // Note: Cray 1.0 = 0x4001000000000000
    //   sign=0, exp=0x4001=16385 → 16385-16384=1, mant=0x100000000000 → 0.5 * 16^1 = 0.5*2=1.0
    // Cray uses 0.M convention (mantissa is 0.MMMM...), so value = (-1)^S * 2^(E-16384) * 0.M
    // Leading 1 in M bit 47 means 0.1xxx... in binary = 0.5 + fraction

endmodule
`default_nettype wire
