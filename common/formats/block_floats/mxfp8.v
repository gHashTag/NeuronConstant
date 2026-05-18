// SPDX-License-Identifier: MIT
// OCP MX FP8 with per-block 8-bit shared exponent (E8M0)
// Two variants: E4M3 (1S+4E+3M, bias=7) and E5M2 (1S+5E+2M, bias=15) via parameter
// Reference: OCP MX Spec https://www.opencompute.org/projects/microscaling-formats-mx
// Co-author: Opus 4.6
`default_nettype none

// FP8 single-element decoder
// VARIANT=0: E4M3 (bias=7), VARIANT=1: E5M2 (bias=15)
module mxfp8_decode #(
    parameter VARIANT = 0
) (
    input  wire [7:0]  fp8_in,
    input  wire [7:0]  block_exp,
    output reg  [15:0] result_q8
);
    wire sign_bit = fp8_in[7];
    wire [3:0] exp_e4  = fp8_in[6:3];
    wire [2:0] mant_m3 = fp8_in[2:0];
    wire [4:0] exp_e5  = fp8_in[6:2];
    wire [1:0] mant_m2 = fp8_in[1:0];

    reg [15:0]       abs_val;
    reg signed [9:0] eff_exp;
    reg [15:0]       mant_q88;
    reg [3:0]        sh_pos;

    always @(*) begin
        abs_val  = 16'h0000;
        eff_exp  = 10'sd0;
        mant_q88 = 16'h0100;
        sh_pos   = 4'd0;

        if (VARIANT == 0) begin
            // E4M3 bias=7
            if (exp_e4 == 4'b0000) begin
                abs_val = 16'h0000;
            end else begin
                eff_exp  = ($signed({2'b0, block_exp}) - 10'sd127)
                         + ($signed({6'b0, exp_e4}) - 10'sd7);
                // (1 + mant/8): mant_q88 = 0x0100 + mant<<5
                mant_q88 = 16'h0100 + {8'b0, mant_m3, 5'b0};
                if      (eff_exp >= 10'sd7)  abs_val = 16'hFFFF;
                else if (eff_exp >= 10'sd0)  abs_val = mant_q88 << eff_exp[2:0];
                else if (eff_exp >= -10'sd8) begin
                    sh_pos  = 4'(-eff_exp);
                    abs_val = mant_q88 >> sh_pos;
                end else abs_val = 16'h0000;
            end
        end else begin
            // E5M2 bias=15
            if (exp_e5 == 5'b00000) begin
                abs_val = 16'h0000;
            end else begin
                eff_exp  = ($signed({2'b0, block_exp}) - 10'sd127)
                         + ($signed({5'b0, exp_e5}) - 10'sd15);
                // (1 + mant/4): mant_q88 = 0x0100 + mant<<6
                mant_q88 = 16'h0100 + {8'b0, mant_m2, 6'b0};
                if      (eff_exp >= 10'sd7)  abs_val = 16'hFFFF;
                else if (eff_exp >= 10'sd0)  abs_val = mant_q88 << eff_exp[2:0];
                else if (eff_exp >= -10'sd8) begin
                    sh_pos  = 4'(-eff_exp);
                    abs_val = mant_q88 >> sh_pos;
                end else abs_val = 16'h0000;
            end
        end

        result_q8 = sign_bit ? (~abs_val + 16'h0001) : abs_val;
    end
endmodule

// FP8 single-element encoder
module mxfp8_encode #(
    parameter VARIANT = 0
) (
    input  wire [15:0] val_q8,
    input  wire [7:0]  block_exp,
    output reg  [7:0]  fp8_out
);
    wire        sign_bit = val_q8[15];
    wire [15:0] abs_val  = sign_bit ? (~val_q8 + 16'h0001) : val_q8;

    reg [4:0]        highest_bit;
    reg signed [9:0] val_exp;
    reg signed [9:0] le;
    reg [2:0]        mant3;
    reg [1:0]        mant2;

    always @(*) begin
        fp8_out = 8'h00;
        if (abs_val == 16'h0000) begin
            fp8_out = {sign_bit, 7'b0};
        end else begin
            highest_bit = 5'd0;
            if      (abs_val[15]) highest_bit = 5'd15;
            else if (abs_val[14]) highest_bit = 5'd14;
            else if (abs_val[13]) highest_bit = 5'd13;
            else if (abs_val[12]) highest_bit = 5'd12;
            else if (abs_val[11]) highest_bit = 5'd11;
            else if (abs_val[10]) highest_bit = 5'd10;
            else if (abs_val[9])  highest_bit = 5'd9;
            else if (abs_val[8])  highest_bit = 5'd8;
            else if (abs_val[7])  highest_bit = 5'd7;
            else if (abs_val[6])  highest_bit = 5'd6;
            else if (abs_val[5])  highest_bit = 5'd5;
            else if (abs_val[4])  highest_bit = 5'd4;
            else if (abs_val[3])  highest_bit = 5'd3;
            else if (abs_val[2])  highest_bit = 5'd2;
            else if (abs_val[1])  highest_bit = 5'd1;
            else                  highest_bit = 5'd0;

            val_exp = $signed({5'b0, highest_bit}) - 10'sd8;

            if (VARIANT == 0) begin
                le = val_exp - ($signed({2'b0, block_exp}) - 10'sd127) + 10'sd7;
                if (le < 10'sd1)  le = 10'sd1;
                if (le > 10'sd14) le = 10'sd14;
                mant3 = 3'b000;
                if (highest_bit >= 5'd3)
                    mant3 = abs_val[highest_bit-5'd1 -: 3];
                else if (highest_bit == 5'd2)
                    mant3 = {abs_val[1:0], 1'b0};
                else if (highest_bit == 5'd1)
                    mant3 = {abs_val[0], 2'b0};
                fp8_out = {sign_bit, le[3:0], mant3};
            end else begin
                le = val_exp - ($signed({2'b0, block_exp}) - 10'sd127) + 10'sd15;
                if (le < 10'sd1)  le = 10'sd1;
                if (le > 10'sd30) le = 10'sd30;
                mant2 = 2'b00;
                if (highest_bit >= 5'd2)
                    mant2 = abs_val[highest_bit-5'd1 -: 2];
                else if (highest_bit == 5'd1)
                    mant2 = {abs_val[0], 1'b0};
                fp8_out = {sign_bit, le[4:0], mant2};
            end
        end
    end
endmodule

// Block decoder: 32 FP8 elements
module mxfp8_block_decode #(
    parameter VARIANT = 0
) (
    input  wire [255:0] fp8_block,
    input  wire [7:0]   block_exp,
    output wire [511:0] results_q8
);
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : dec_gen
            mxfp8_decode #(.VARIANT(VARIANT)) u_dec (
                .fp8_in    (fp8_block[8*i+7 : 8*i]),
                .block_exp (block_exp),
                .result_q8 (results_q8[16*i+15 : 16*i])
            );
        end
    endgenerate
endmodule
`default_nettype wire
