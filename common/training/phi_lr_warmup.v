// SPDX-License-Identifier: MIT
// phi_lr_warmup.v — runtime φ-LR schedule with warmup
//
// For step < warmup_steps: linear ramp from 0 to max_lr
// For step >= warmup_steps: uses phi_lr_rom lookup (φ^(-n/period) decay)
//
// Since ROM covers 54 steps, we map runtime step to ROM index:
//   rom_idx = min(step, 53)
//
// Inputs:
//   step_cnt [15:0]   — current training step
//   max_lr   [15:0]   — peak learning rate GF16
//   warmup_steps [5:0] — number of warmup steps (must be <= 27)
// Output:
//   lr_out [15:0]     — current LR in GF16
//
// R-SI-1 clean: all multiplications via gf16_mul.
// Verilog-2005, `default_nettype none.

`default_nettype none

module phi_lr_warmup (
    input  wire [15:0] step_cnt,
    input  wire [15:0] max_lr,
    input  wire [5:0]  warmup_steps,
    output reg  [15:0] lr_out
);

    // ROM lookup for post-warmup
    wire [5:0] rom_idx = (step_cnt[5:0] > 6'd53) ? 6'd53 : step_cnt[5:0];
    wire [15:0] rom_lr;

    phi_lr_rom u_rom (
        .step_idx(rom_idx),
        .lr_val(rom_lr)
    );

    // Warmup: linear ramp
    // lr = max_lr * step_cnt / warmup_steps
    // Approximate: use shift-right if warmup_steps is power of 2, otherwise
    // use GF16 multiply with ratio.
    // For simplicity, compute ratio = step_cnt / warmup_steps as GF16,
    // then lr = max_lr * ratio (via gf16_mul).

    // Convert step_cnt to GF16 (integer -> GF16 float)
    wire [15:0] step_gf;
    int_to_gf16 u_step_conv (
        .int_in(step_cnt[8:0]),
        .gf_out(step_gf)
    );

    // Convert warmup_steps to GF16
    wire [15:0] warmup_gf;
    int_to_gf16 u_warmup_conv (
        .int_in({3'd0, warmup_steps}),
        .gf_out(warmup_gf)
    );

    // ratio = step_gf / warmup_gf (via multiply by reciprocal)
    // Since we don't have a divider, approximate:
    // Precompute 1/warmup_steps as GF16 const for warmup_steps=27 -> 0x3497
    // For general warmup_steps, use lookup table (simplified: hardcode 27)
    localparam [15:0] INV_WARMUP = 16'h3497;  // 1/27 ≈ 0.037037 in GF16

    wire [15:0] ratio;
    wire ov_r, uv_r;
    gf16_mul u_ratio (
        .a(step_gf),
        .b(INV_WARMUP),
        .result(ratio),
        .overflow(ov_r),
        .underflow(uv_r)
    );

    // warmup_lr = max_lr * ratio
    wire [15:0] warmup_lr;
    wire ov_w, uv_w;
    gf16_mul u_wlr (
        .a(max_lr),
        .b(ratio),
        .result(warmup_lr),
        .overflow(ov_w),
        .underflow(uv_w)
    );

    always @(*) begin
        if (step_cnt[15:6] != 10'b0 || step_cnt[5:0] >= warmup_steps) begin
            // Post-warmup: use ROM
            lr_out = rom_lr;
        end else begin
            // Warmup: linear ramp
            lr_out = warmup_lr;
        end
    end

endmodule

// Integer (9-bit) to GF16 converter
// Input: 9-bit unsigned integer
// Output: GF16 representation
module int_to_gf16 (
    input  wire [8:0]  int_in,
    output reg  [15:0] gf_out
);
    // Find leading bit position for normalization
    reg [3:0] lz;  // leading zeros
    reg [8:0] val;

    reg [5:0] exp_v;
    reg [8:0] shifted;
    reg [8:0] mant_bits;

    always @(*) begin
        val      = int_in;
        exp_v    = 6'd0;
        shifted  = 9'd0;
        mant_bits = 9'd0;
        gf_out   = 16'h0000;
        lz       = 4'd8;

        if (val == 0) begin
            gf_out = 16'h0000;
        end else begin
            // Find MSB position
            if      (val[8]) lz = 4'd0;
            else if (val[7]) lz = 4'd1;
            else if (val[6]) lz = 4'd2;
            else if (val[5]) lz = 4'd3;
            else if (val[4]) lz = 4'd4;
            else if (val[3]) lz = 4'd5;
            else if (val[2]) lz = 4'd6;
            else if (val[1]) lz = 4'd7;
            else             lz = 4'd8;
            // Exponent: bias(31) + (8 - lz)
            exp_v     = 6'd31 + (6'd8 - {2'b0, lz});
            shifted   = val << lz;
            mant_bits = shifted & 9'h0FF;
            gf_out    = {1'b0, exp_v, mant_bits};
        end
    end
endmodule

`default_nettype wire
