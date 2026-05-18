// SPDX-License-Identifier: MIT
// jepa_ema.v — T-JEPA EMA update for one parameter
//
// Implements EMA update:
//   target_new = decay * target + (1 - decay) * online
//
// Default decay = 0.998 (GF16: 0x3DFE)
// 1 - decay = 0.002 (GF16: 0x2C0C)
//
// Combinational module (single cycle).
//
// References:
//   - LeCun et al. "Self-Supervised Learning from Images with JEPA" 2023
//   - trios-trainer-igla/src/jepa/ema.rs
//
// R-SI-1 clean: all multiplications via gf16_mul.
// Verilog-2005, `default_nettype none.

`default_nettype none

module jepa_ema (
    input  wire [15:0] target,   // current target parameter GF16
    input  wire [15:0] online,   // online encoder parameter GF16
    input  wire [15:0] decay,    // decay factor GF16 (typ 0x3DFE = 0.998)
    output wire [15:0] target_new // updated target GF16
);

    // Compute 1 - decay via GF16 subtraction
    // 1.0 in GF16 = 0x3E00
    wire [15:0] one_minus_decay;
    localparam [15:0] GF16_ONE = 16'h3E00;

    // 1 - decay = GF16_ONE - decay  (negate decay sign then add)
    gf16_add u_omd (
        .a(GF16_ONE),
        .b({~decay[15], decay[14:0]}),  // negate
        .result(one_minus_decay)
    );

    // decay * target
    wire [15:0] decay_target;
    wire ov1, uv1;
    gf16_mul u_dt (
        .a(decay),
        .b(target),
        .result(decay_target),
        .overflow(ov1),
        .underflow(uv1)
    );

    // (1 - decay) * online
    wire [15:0] omd_online;
    wire ov2, uv2;
    gf16_mul u_oo (
        .a(one_minus_decay),
        .b(online),
        .result(omd_online),
        .overflow(ov2),
        .underflow(uv2)
    );

    // target_new = decay*target + (1-decay)*online
    gf16_add u_sum (
        .a(decay_target),
        .b(omd_online),
        .result(target_new)
    );

endmodule

`default_nettype wire
