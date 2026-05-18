// SPDX-License-Identifier: MIT
// OCP MX FP4 (E2M1) with per-block 8-bit shared exponent (E8M0)
// Format: 1S + 2E + 1M, block size = 32 elements
// Blackwell B100/B200 class micro-format
// Reference: OCP MX Spec https://www.opencompute.org/projects/microscaling-formats-mx
// Co-author: Opus 4.6
`default_nettype none

// Decode one FP4 element + block shared exponent -> Q8.8 signed fixed-point
// Decode: (-1)^S * 2^(block_exp - 127 + local_exp - 1) * (1 + local_mant/2)
module mxfp4_decode (
    input  wire [3:0]  fp4_in,      // 1S + 2E + 1M
    input  wire [7:0]  block_exp,   // shared E8M0 exponent for block
    output reg  [15:0] result_q8    // Q8.8 signed result
);
    wire        sign_bit   = fp4_in[3];
    wire [1:0]  local_exp  = fp4_in[2:1];
    wire        local_mant = fp4_in[0];

    reg [15:0] abs_val;
    reg signed [8:0] eff_exp;
    reg [15:0] mant_q88;
    reg [3:0]  sh_pos;

    always @(*) begin
        abs_val = 16'h0000;

        if (local_exp == 2'b00) begin
            abs_val = 16'h0000;
        end else begin
            // eff_exp = (block_exp - 127) + (local_exp - 1)
            eff_exp = ($signed({1'b0, block_exp}) - 9'sd127)
                    + ($signed({7'b0, local_exp}) - 9'sd1);

            // Mantissa Q8.8: base = 0x0100 (=1.0), add 0x0080 if local_mant
            mant_q88 = local_mant ? 16'h0180 : 16'h0100;

            if (eff_exp >= 9'sd7) begin
                abs_val = 16'hFFFF;
            end else if (eff_exp >= 9'sd0) begin
                sh_pos  = eff_exp[3:0];
                abs_val = mant_q88 << sh_pos;
            end else if (eff_exp >= -9'sd8) begin
                sh_pos  = (-eff_exp[3:0]);
                abs_val = mant_q88 >> sh_pos;
            end else begin
                abs_val = 16'h0000;
            end
        end

        result_q8 = sign_bit ? (~abs_val + 16'h0001) : abs_val;
    end
endmodule

// Encode Q8.8 -> FP4 given shared block exponent
module mxfp4_encode (
    input  wire [15:0] val_q8,
    input  wire [7:0]  block_exp,
    output reg  [3:0]  fp4_out
);
    wire        sign_bit = val_q8[15];
    wire [15:0] abs_val  = sign_bit ? (~val_q8 + 16'h0001) : val_q8;

    reg [4:0]  highest_bit;
    reg signed [8:0] val_exp;
    reg signed [8:0] le;
    reg        local_mant;

    always @(*) begin
        fp4_out = 4'b0000;

        if (abs_val == 16'h0000) begin
            fp4_out = {sign_bit, 3'b000};
        end else begin
            // Find highest set bit
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

            // val_exp: bit 8 = 2^0 in Q8.8
            val_exp = $signed({4'b0, highest_bit}) - 9'sd8;

            // local_exp = val_exp - (block_exp - 127) + 1
            le = val_exp - ($signed({1'b0, block_exp}) - 9'sd127) + 9'sd1;
            if (le < 9'sd1)      le = 9'sd1;
            else if (le > 9'sd3) le = 9'sd3;

            // Extract mantissa bit below highest
            if (highest_bit >= 5'd1)
                local_mant = abs_val[highest_bit - 5'd1];
            else
                local_mant = 1'b0;

            fp4_out = {sign_bit, le[1:0], local_mant};
        end
    end
endmodule

// Block-level FP4 decoder: 32 elements sharing one 8-bit exponent
module mxfp4_block_decode (
    input  wire [127:0] fp4_block,  // 32 x 4-bit elements packed
    input  wire [7:0]   block_exp,  // shared E8M0 exponent
    output wire [511:0] results_q8  // 32 x 16-bit Q8.8 results packed
);
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : dec_gen
            mxfp4_decode u_dec (
                .fp4_in    (fp4_block[4*i+3 : 4*i]),
                .block_exp (block_exp),
                .result_q8 (results_q8[16*i+15 : 16*i])
            );
        end
    endgenerate
endmodule

// Block-level FP4 encoder: 32 Q8.8 values -> pack + shared exponent
// Uses generate-based encoding (avoids dynamic part selects in Verilog-2005)
module mxfp4_block_encode (
    input  wire [511:0] vals_q8,
    output reg  [7:0]   block_exp,
    output wire [127:0] fp4_block
);
    reg signed [9:0] be_tmp;

    // Find max exponent using individual element signals
    wire [15:0] elem [0:31];
    wire [15:0] aelem [0:31];
    wire [4:0]  hbits [0:31];
    wire signed [8:0] vexp [0:31];

    genvar gi;
    generate
        for (gi = 0; gi < 32; gi = gi + 1) begin : elem_gen
            assign elem[gi]  = vals_q8[16*gi+15 : 16*gi];
            assign aelem[gi] = elem[gi][15] ? (~elem[gi] + 16'h0001) : elem[gi];
            // Priority encode highest bit
            assign hbits[gi] =
                aelem[gi][15] ? 5'd15 : aelem[gi][14] ? 5'd14 :
                aelem[gi][13] ? 5'd13 : aelem[gi][12] ? 5'd12 :
                aelem[gi][11] ? 5'd11 : aelem[gi][10] ? 5'd10 :
                aelem[gi][9]  ? 5'd9  : aelem[gi][8]  ? 5'd8  :
                aelem[gi][7]  ? 5'd7  : aelem[gi][6]  ? 5'd6  :
                aelem[gi][5]  ? 5'd5  : aelem[gi][4]  ? 5'd4  :
                aelem[gi][3]  ? 5'd3  : aelem[gi][2]  ? 5'd2  :
                aelem[gi][1]  ? 5'd1  : 5'd0;
            assign vexp[gi] = $signed({4'b0, hbits[gi]}) - 9'sd8;
        end
    endgenerate

    // Reduce: find max exponent
    wire signed [8:0] max01  = (vexp[0]  > vexp[1])  ? vexp[0]  : vexp[1];
    wire signed [8:0] max23  = (vexp[2]  > vexp[3])  ? vexp[2]  : vexp[3];
    wire signed [8:0] max45  = (vexp[4]  > vexp[5])  ? vexp[4]  : vexp[5];
    wire signed [8:0] max67  = (vexp[6]  > vexp[7])  ? vexp[6]  : vexp[7];
    wire signed [8:0] max89  = (vexp[8]  > vexp[9])  ? vexp[8]  : vexp[9];
    wire signed [8:0] maxab  = (vexp[10] > vexp[11]) ? vexp[10] : vexp[11];
    wire signed [8:0] maxcd  = (vexp[12] > vexp[13]) ? vexp[12] : vexp[13];
    wire signed [8:0] maxef  = (vexp[14] > vexp[15]) ? vexp[14] : vexp[15];
    wire signed [8:0] maxgh  = (vexp[16] > vexp[17]) ? vexp[16] : vexp[17];
    wire signed [8:0] maxij  = (vexp[18] > vexp[19]) ? vexp[18] : vexp[19];
    wire signed [8:0] maxkl  = (vexp[20] > vexp[21]) ? vexp[20] : vexp[21];
    wire signed [8:0] maxmn  = (vexp[22] > vexp[23]) ? vexp[22] : vexp[23];
    wire signed [8:0] maxop  = (vexp[24] > vexp[25]) ? vexp[24] : vexp[25];
    wire signed [8:0] maxqr  = (vexp[26] > vexp[27]) ? vexp[26] : vexp[27];
    wire signed [8:0] maxst  = (vexp[28] > vexp[29]) ? vexp[28] : vexp[29];
    wire signed [8:0] maxuv  = (vexp[30] > vexp[31]) ? vexp[30] : vexp[31];
    wire signed [8:0] max0123   = (max01 > max23)   ? max01 : max23;
    wire signed [8:0] max4567   = (max45 > max67)   ? max45 : max67;
    wire signed [8:0] max89ab   = (max89 > maxab)   ? max89 : maxab;
    wire signed [8:0] maxcdef   = (maxcd > maxef)   ? maxcd : maxef;
    wire signed [8:0] maxghij   = (maxgh > maxij)   ? maxgh : maxij;
    wire signed [8:0] maxklmn   = (maxkl > maxmn)   ? maxkl : maxmn;
    wire signed [8:0] maxopqr   = (maxop > maxqr)   ? maxop : maxqr;
    wire signed [8:0] maxstuv   = (maxst > maxuv)   ? maxst : maxuv;
    wire signed [8:0] max07     = (max0123 > max4567)   ? max0123 : max4567;
    wire signed [8:0] max8f     = (max89ab > maxcdef)   ? max89ab : maxcdef;
    wire signed [8:0] maxgn     = (maxghij > maxklmn)   ? maxghij : maxklmn;
    wire signed [8:0] maxov     = (maxopqr > maxstuv)   ? maxopqr : maxstuv;
    wire signed [8:0] max0f     = (max07 > max8f)   ? max07 : max8f;
    wire signed [8:0] maxgv     = (maxgn > maxov)   ? maxgn : maxov;
    wire signed [8:0] max_exp_w = (max0f > maxgv)   ? max0f : maxgv;

    always @(*) begin
        be_tmp = $signed({max_exp_w[8], max_exp_w}) + 10'sd127 - 10'sd2;
        if (be_tmp < 10'sd0)        block_exp = 8'd0;
        else if (be_tmp > 10'sd255) block_exp = 8'd255;
        else                        block_exp = be_tmp[7:0];
    end

    // Encode all 32 elements
    wire [3:0] fp4_out_w [0:31];
    generate
        for (gi = 0; gi < 32; gi = gi + 1) begin : enc_gen
            mxfp4_encode u_enc (
                .val_q8    (vals_q8[16*gi+15 : 16*gi]),
                .block_exp (block_exp),
                .fp4_out   (fp4_out_w[gi])
            );
            assign fp4_block[4*gi+3 : 4*gi] = fp4_out_w[gi];
        end
    endgenerate
endmodule
`default_nettype wire
