// SPDX-License-Identifier: MIT
// OCP MX FP6 with per-block 8-bit shared exponent (E8M0)
// Two variants via parameter: E2M3 (1S+2E+3M) and E3M2 (1S+3E+2M)
// Reference: OCP MX Spec https://www.opencompute.org/projects/microscaling-formats-mx
// Co-author: Opus 4.6
`default_nettype none

// Single-element FP6 decoder
// VARIANT=0: E2M3 (1S + 2E + 3M, bias=1)
// VARIANT=1: E3M2 (1S + 3E + 2M, bias=3)
module mxfp6_decode #(
    parameter VARIANT = 0
) (
    input  wire [5:0]  fp6_in,
    input  wire [7:0]  block_exp,
    output reg  [15:0] result_q8
);
    wire sign_bit = fp6_in[5];
    wire [1:0] exp_e2  = fp6_in[4:3];
    wire [2:0] mant_m3 = fp6_in[2:0];
    wire [2:0] exp_e3  = fp6_in[4:2];
    wire [1:0] mant_m2 = fp6_in[1:0];

    reg [15:0]       abs_val;
    reg signed [8:0] eff_exp;
    reg [15:0]       mant_q88;
    reg [3:0]        sh_pos;

    always @(*) begin
        abs_val  = 16'h0000;
        eff_exp  = 9'sd0;
        mant_q88 = 16'h0100;
        sh_pos   = 4'd0;

        if (VARIANT == 0) begin
            // E2M3 bias=1
            if (exp_e2 == 2'b00) begin
                abs_val = 16'h0000;
            end else begin
                eff_exp  = ($signed({1'b0, block_exp}) - 9'sd127)
                         + ($signed({7'b0, exp_e2}) - 9'sd1);
                // (1 + mant/8): mant_q88 = 0x0100 + mant<<5
                mant_q88 = 16'h0100 + {8'b0, mant_m3, 5'b0};
                if      (eff_exp >= 9'sd7)  abs_val = 16'hFFFF;
                else if (eff_exp >= 9'sd0)  abs_val = mant_q88 << eff_exp[2:0];
                else if (eff_exp >= -9'sd8) begin
                    sh_pos  = 4'(-eff_exp);
                    abs_val = mant_q88 >> sh_pos;
                end else abs_val = 16'h0000;
            end
        end else begin
            // E3M2 bias=3
            if (exp_e3 == 3'b000) begin
                abs_val = 16'h0000;
            end else begin
                eff_exp  = ($signed({1'b0, block_exp}) - 9'sd127)
                         + ($signed({6'b0, exp_e3}) - 9'sd3);
                // (1 + mant/4): mant_q88 = 0x0100 + mant<<6
                mant_q88 = 16'h0100 + {8'b0, mant_m2, 6'b0};
                if      (eff_exp >= 9'sd7)  abs_val = 16'hFFFF;
                else if (eff_exp >= 9'sd0)  abs_val = mant_q88 << eff_exp[2:0];
                else if (eff_exp >= -9'sd8) begin
                    sh_pos  = 4'(-eff_exp);
                    abs_val = mant_q88 >> sh_pos;
                end else abs_val = 16'h0000;
            end
        end

        result_q8 = sign_bit ? (~abs_val + 16'h0001) : abs_val;
    end
endmodule

// Single-element FP6 encoder
module mxfp6_encode #(
    parameter VARIANT = 0
) (
    input  wire [15:0] val_q8,
    input  wire [7:0]  block_exp,
    output reg  [5:0]  fp6_out
);
    wire        sign_bit = val_q8[15];
    wire [15:0] abs_val  = sign_bit ? (~val_q8 + 16'h0001) : val_q8;

    reg [4:0]        highest_bit;
    reg signed [8:0] val_exp;
    reg signed [8:0] le;
    reg [2:0]        mant_bits;

    always @(*) begin
        fp6_out = 6'b000000;

        if (abs_val == 16'h0000) begin
            fp6_out = {sign_bit, 5'b00000};
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

            val_exp = $signed({4'b0, highest_bit}) - 9'sd8;

            if (VARIANT == 0) begin
                le = val_exp - ($signed({1'b0, block_exp}) - 9'sd127) + 9'sd1;
                if (le < 9'sd1) le = 9'sd1;
                if (le > 9'sd3) le = 9'sd3;
                mant_bits = 3'b000;
                if (highest_bit >= 5'd3)
                    mant_bits = abs_val[highest_bit-5'd1 -: 3];
                else if (highest_bit == 5'd2)
                    mant_bits = {abs_val[1:0], 1'b0};
                else if (highest_bit == 5'd1)
                    mant_bits = {abs_val[0], 2'b0};
                fp6_out = {sign_bit, le[1:0], mant_bits};
            end else begin
                le = val_exp - ($signed({1'b0, block_exp}) - 9'sd127) + 9'sd3;
                if (le < 9'sd1) le = 9'sd1;
                if (le > 9'sd6) le = 9'sd6;
                mant_bits = 3'b000;
                if (highest_bit >= 5'd2)
                    mant_bits[2:1] = abs_val[highest_bit-5'd1 -: 2];
                else if (highest_bit == 5'd1)
                    mant_bits = {1'b0, abs_val[0], 1'b0};
                fp6_out = {sign_bit, le[2:0], mant_bits[2:1]};
            end
        end
    end
endmodule

// Block decoder: 32 FP6 elements with shared E8M0 exponent
module mxfp6_block_decode #(
    parameter VARIANT = 0
) (
    input  wire [191:0] fp6_block,
    input  wire [7:0]   block_exp,
    output wire [511:0] results_q8
);
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : dec_gen
            mxfp6_decode #(.VARIANT(VARIANT)) u_dec (
                .fp6_in    (fp6_block[6*i+5 : 6*i]),
                .block_exp (block_exp),
                .result_q8 (results_q8[16*i+15 : 16*i])
            );
        end
    endgenerate
endmodule
`default_nettype wire
