// nf8.v — 8-bit NormalFloat (Nf8) codec
//
// Nf8 is an 8-bit distribution-aware quantization format inspired by
// Tim Dettmers' NF4 (QLoRA, 2023) extended to 256 entries.
//
// LUT construction:
//   The 256 canonical values are sampled from the inverse CDF of the standard
//   normal distribution at quantiles (i+0.5)/256 for i in 0..255.
//   Values are normalized to [-1, 1] and stored as signed Q1.15 (int16 scaled x32767).
//   Decode: real_value ≈ lut_out / 32767.0
//   Encode: argmin |target - lut_value| over all 256 entries.
//
// Interface:
//   DECODE: in_idx (8-bit) → lut_out (16-bit signed Q1.15)
//   ENCODE: enc_in (16-bit signed Q1.15) → enc_idx (8-bit), using linear search
//           enc_valid must be high; result available combinationally.
//
// Verilog-2005, `default_nettype none, R-SI-1 compliant
`default_nettype none

module nf8 (
    // Decode port
    input  wire [7:0]  in_idx,     // Nf8 8-bit index
    output reg  [15:0] lut_out,    // decoded value, signed Q1.15

    // Encode port (combinational argmin)
    input  wire [15:0] enc_in,     // target value to quantize (signed Q1.15)
    output reg  [7:0]  enc_idx     // nearest Nf8 index
);

    // ----------------------------------------------------------------
    // Decode: 256-entry ROM (CDF-inverse normal distribution)
    // ----------------------------------------------------------------
    always @(*) begin
        case (in_idx)
            8'h00: lut_out = 16'h8001; // -1.000000
            8'h01: lut_out = 16'h9027; // -0.873828
            8'h02: lut_out = 16'h9859; // -0.809801
            8'h03: lut_out = 16'h9E0B; // -0.765324
            8'h04: lut_out = 16'hA278; // -0.730735
            8'h05: lut_out = 16'hA620; // -0.702182
            8'h06: lut_out = 16'hA941; // -0.677720
            8'h07: lut_out = 16'hAC01; // -0.656228
            8'h08: lut_out = 16'hAE78; // -0.636992
            8'h09: lut_out = 16'hB0B4; // -0.619536
            8'h0A: lut_out = 16'hB2C1; // -0.603519
            8'h0B: lut_out = 16'hB4A6; // -0.588692
            8'h0C: lut_out = 16'hB66B; // -0.574867
            8'h0D: lut_out = 16'hB814; // -0.561898
            8'h0E: lut_out = 16'hB9A5; // -0.549668
            8'h0F: lut_out = 16'hBB21; // -0.538084
            8'h10: lut_out = 16'hBC8A; // -0.527069
            8'h11: lut_out = 16'hBDE2; // -0.516560
            8'h12: lut_out = 16'hBF2B; // -0.506504
            8'h13: lut_out = 16'hC068; // -0.496855
            8'h14: lut_out = 16'hC198; // -0.487575
            8'h15: lut_out = 16'hC2BD; // -0.478630
            8'h16: lut_out = 16'hC3D8; // -0.469992
            8'h17: lut_out = 16'hC4EA; // -0.461635
            8'h18: lut_out = 16'hC5F3; // -0.453536
            8'h19: lut_out = 16'hC6F4; // -0.445677
            8'h1A: lut_out = 16'hC7EF; // -0.438040
            8'h1B: lut_out = 16'hC8E2; // -0.430608
            8'h1C: lut_out = 16'hC9CF; // -0.423369
            8'h1D: lut_out = 16'hCAB7; // -0.416309
            8'h1E: lut_out = 16'hCB99; // -0.409416
            8'h1F: lut_out = 16'hCC75; // -0.402681
            8'h20: lut_out = 16'hCD4D; // -0.396095
            8'h21: lut_out = 16'hCE20; // -0.389647
            8'h22: lut_out = 16'hCEEF; // -0.383331
            8'h23: lut_out = 16'hCFBA; // -0.377139
            8'h24: lut_out = 16'hD081; // -0.371065
            8'h25: lut_out = 16'hD145; // -0.365102
            8'h26: lut_out = 16'hD205; // -0.359245
            8'h27: lut_out = 16'hD2C1; // -0.353488
            8'h28: lut_out = 16'hD37B; // -0.347826
            8'h29: lut_out = 16'hD431; // -0.342256
            8'h2A: lut_out = 16'hD4E5; // -0.336772
            8'h2B: lut_out = 16'hD596; // -0.331371
            8'h2C: lut_out = 16'hD644; // -0.326049
            8'h2D: lut_out = 16'hD6F0; // -0.320802
            8'h2E: lut_out = 16'hD79A; // -0.315628
            8'h2F: lut_out = 16'hD841; // -0.310522
            8'h30: lut_out = 16'hD8E6; // -0.305483
            8'h31: lut_out = 16'hD989; // -0.300508
            8'h32: lut_out = 16'hDA2A; // -0.295593
            8'h33: lut_out = 16'hDAC9; // -0.290737
            8'h34: lut_out = 16'hDB67; // -0.285937
            8'h35: lut_out = 16'hDC02; // -0.281191
            8'h36: lut_out = 16'hDC9C; // -0.276497
            8'h37: lut_out = 16'hDD34; // -0.271853
            8'h38: lut_out = 16'hDDCB; // -0.267257
            8'h39: lut_out = 16'hDE60; // -0.262707
            8'h3A: lut_out = 16'hDEF3; // -0.258203
            8'h3B: lut_out = 16'hDF86; // -0.253741
            8'h3C: lut_out = 16'hE017; // -0.249320
            8'h3D: lut_out = 16'hE0A6; // -0.244940
            8'h3E: lut_out = 16'hE134; // -0.240599
            8'h3F: lut_out = 16'hE1C1; // -0.236294
            8'h40: lut_out = 16'hE24D; // -0.232026
            8'h41: lut_out = 16'hE2D8; // -0.227793
            8'h42: lut_out = 16'hE362; // -0.223593
            8'h43: lut_out = 16'hE3EA; // -0.219426
            8'h44: lut_out = 16'hE472; // -0.215290
            8'h45: lut_out = 16'hE4F8; // -0.211184
            8'h46: lut_out = 16'hE57E; // -0.207108
            8'h47: lut_out = 16'hE602; // -0.203060
            8'h48: lut_out = 16'hE686; // -0.199040
            8'h49: lut_out = 16'hE709; // -0.195046
            8'h4A: lut_out = 16'hE78B; // -0.191078
            8'h4B: lut_out = 16'hE80C; // -0.187134
            8'h4C: lut_out = 16'hE88D; // -0.183215
            8'h4D: lut_out = 16'hE90C; // -0.179319
            8'h4E: lut_out = 16'hE98B; // -0.175445
            8'h4F: lut_out = 16'hEA09; // -0.171593
            8'h50: lut_out = 16'hEA87; // -0.167763
            8'h51: lut_out = 16'hEB04; // -0.163952
            8'h52: lut_out = 16'hEB80; // -0.160161
            8'h53: lut_out = 16'hEBFC; // -0.156389
            8'h54: lut_out = 16'hEC77; // -0.152636
            8'h55: lut_out = 16'hECF1; // -0.148900
            8'h56: lut_out = 16'hED6B; // -0.145182
            8'h57: lut_out = 16'hEDE4; // -0.141480
            8'h58: lut_out = 16'hEE5D; // -0.137794
            8'h59: lut_out = 16'hEED5; // -0.134124
            8'h5A: lut_out = 16'hEF4D; // -0.130469
            8'h5B: lut_out = 16'hEFC4; // -0.126828
            8'h5C: lut_out = 16'hF03B; // -0.123201
            8'h5D: lut_out = 16'hF0B1; // -0.119587
            8'h5E: lut_out = 16'hF127; // -0.115987
            8'h5F: lut_out = 16'hF19D; // -0.112399
            8'h60: lut_out = 16'hF212; // -0.108822
            8'h61: lut_out = 16'hF287; // -0.105258
            8'h62: lut_out = 16'hF2FB; // -0.101704
            8'h63: lut_out = 16'hF370; // -0.098161
            8'h64: lut_out = 16'hF3E3; // -0.094629
            8'h65: lut_out = 16'hF457; // -0.091106
            8'h66: lut_out = 16'hF4CA; // -0.087592
            8'h67: lut_out = 16'hF53D; // -0.084088
            8'h68: lut_out = 16'hF5AF; // -0.080592
            8'h69: lut_out = 16'hF622; // -0.077104
            8'h6A: lut_out = 16'hF694; // -0.073624
            8'h6B: lut_out = 16'hF705; // -0.070151
            8'h6C: lut_out = 16'hF777; // -0.066685
            8'h6D: lut_out = 16'hF7E8; // -0.063226
            8'h6E: lut_out = 16'hF859; // -0.059774
            8'h6F: lut_out = 16'hF8CA; // -0.056327
            8'h70: lut_out = 16'hF93B; // -0.052886
            8'h71: lut_out = 16'hF9AC; // -0.049450
            8'h72: lut_out = 16'hFA1C; // -0.046019
            8'h73: lut_out = 16'hFA8C; // -0.042592
            8'h74: lut_out = 16'hFAFD; // -0.039169
            8'h75: lut_out = 16'hFB6D; // -0.035751
            8'h76: lut_out = 16'hFBDC; // -0.032335
            8'h77: lut_out = 16'hFC4C; // -0.028923
            8'h78: lut_out = 16'hFCBC; // -0.025514
            8'h79: lut_out = 16'hFD2C; // -0.022107
            8'h7A: lut_out = 16'hFD9B; // -0.018702
            8'h7B: lut_out = 16'hFE0B; // -0.015300
            8'h7C: lut_out = 16'hFE7A; // -0.011898
            8'h7D: lut_out = 16'hFEEA; // -0.008498
            8'h7E: lut_out = 16'hFF59; // -0.005098
            8'h7F: lut_out = 16'hFFC8; // -0.001699
            8'h80: lut_out = 16'h0038; // 0.001699
            8'h81: lut_out = 16'h00A7; // 0.005098
            8'h82: lut_out = 16'h0116; // 0.008498
            8'h83: lut_out = 16'h0186; // 0.011898
            8'h84: lut_out = 16'h01F5; // 0.015300
            8'h85: lut_out = 16'h0265; // 0.018702
            8'h86: lut_out = 16'h02D4; // 0.022107
            8'h87: lut_out = 16'h0344; // 0.025514
            8'h88: lut_out = 16'h03B4; // 0.028923
            8'h89: lut_out = 16'h0424; // 0.032335
            8'h8A: lut_out = 16'h0493; // 0.035751
            8'h8B: lut_out = 16'h0503; // 0.039169
            8'h8C: lut_out = 16'h0574; // 0.042592
            8'h8D: lut_out = 16'h05E4; // 0.046019
            8'h8E: lut_out = 16'h0654; // 0.049450
            8'h8F: lut_out = 16'h06C5; // 0.052886
            8'h90: lut_out = 16'h0736; // 0.056327
            8'h91: lut_out = 16'h07A7; // 0.059774
            8'h92: lut_out = 16'h0818; // 0.063226
            8'h93: lut_out = 16'h0889; // 0.066685
            8'h94: lut_out = 16'h08FB; // 0.070151
            8'h95: lut_out = 16'h096C; // 0.073624
            8'h96: lut_out = 16'h09DE; // 0.077104
            8'h97: lut_out = 16'h0A51; // 0.080592
            8'h98: lut_out = 16'h0AC3; // 0.084088
            8'h99: lut_out = 16'h0B36; // 0.087592
            8'h9A: lut_out = 16'h0BA9; // 0.091106
            8'h9B: lut_out = 16'h0C1D; // 0.094629
            8'h9C: lut_out = 16'h0C90; // 0.098161
            8'h9D: lut_out = 16'h0D05; // 0.101704
            8'h9E: lut_out = 16'h0D79; // 0.105258
            8'h9F: lut_out = 16'h0DEE; // 0.108822
            8'hA0: lut_out = 16'h0E63; // 0.112399
            8'hA1: lut_out = 16'h0ED9; // 0.115987
            8'hA2: lut_out = 16'h0F4F; // 0.119587
            8'hA3: lut_out = 16'h0FC5; // 0.123201
            8'hA4: lut_out = 16'h103C; // 0.126828
            8'hA5: lut_out = 16'h10B3; // 0.130469
            8'hA6: lut_out = 16'h112B; // 0.134124
            8'hA7: lut_out = 16'h11A3; // 0.137794
            8'hA8: lut_out = 16'h121C; // 0.141480
            8'hA9: lut_out = 16'h1295; // 0.145182
            8'hAA: lut_out = 16'h130F; // 0.148900
            8'hAB: lut_out = 16'h1389; // 0.152636
            8'hAC: lut_out = 16'h1404; // 0.156389
            8'hAD: lut_out = 16'h1480; // 0.160161
            8'hAE: lut_out = 16'h14FC; // 0.163952
            8'hAF: lut_out = 16'h1579; // 0.167763
            8'hB0: lut_out = 16'h15F7; // 0.171593
            8'hB1: lut_out = 16'h1675; // 0.175445
            8'hB2: lut_out = 16'h16F4; // 0.179319
            8'hB3: lut_out = 16'h1773; // 0.183215
            8'hB4: lut_out = 16'h17F4; // 0.187134
            8'hB5: lut_out = 16'h1875; // 0.191078
            8'hB6: lut_out = 16'h18F7; // 0.195046
            8'hB7: lut_out = 16'h197A; // 0.199040
            8'hB8: lut_out = 16'h19FE; // 0.203060
            8'hB9: lut_out = 16'h1A82; // 0.207108
            8'hBA: lut_out = 16'h1B08; // 0.211184
            8'hBB: lut_out = 16'h1B8E; // 0.215290
            8'hBC: lut_out = 16'h1C16; // 0.219426
            8'hBD: lut_out = 16'h1C9E; // 0.223593
            8'hBE: lut_out = 16'h1D28; // 0.227793
            8'hBF: lut_out = 16'h1DB3; // 0.232026
            8'hC0: lut_out = 16'h1E3F; // 0.236294
            8'hC1: lut_out = 16'h1ECC; // 0.240599
            8'hC2: lut_out = 16'h1F5A; // 0.244940
            8'hC3: lut_out = 16'h1FE9; // 0.249320
            8'hC4: lut_out = 16'h207A; // 0.253741
            8'hC5: lut_out = 16'h210D; // 0.258203
            8'hC6: lut_out = 16'h21A0; // 0.262707
            8'hC7: lut_out = 16'h2235; // 0.267257
            8'hC8: lut_out = 16'h22CC; // 0.271853
            8'hC9: lut_out = 16'h2364; // 0.276497
            8'hCA: lut_out = 16'h23FE; // 0.281191
            8'hCB: lut_out = 16'h2499; // 0.285937
            8'hCC: lut_out = 16'h2537; // 0.290737
            8'hCD: lut_out = 16'h25D6; // 0.295593
            8'hCE: lut_out = 16'h2677; // 0.300508
            8'hCF: lut_out = 16'h271A; // 0.305483
            8'hD0: lut_out = 16'h27BF; // 0.310522
            8'hD1: lut_out = 16'h2866; // 0.315628
            8'hD2: lut_out = 16'h2910; // 0.320802
            8'hD3: lut_out = 16'h29BC; // 0.326049
            8'hD4: lut_out = 16'h2A6A; // 0.331371
            8'hD5: lut_out = 16'h2B1B; // 0.336772
            8'hD6: lut_out = 16'h2BCF; // 0.342256
            8'hD7: lut_out = 16'h2C85; // 0.347826
            8'hD8: lut_out = 16'h2D3F; // 0.353488
            8'hD9: lut_out = 16'h2DFB; // 0.359245
            8'hDA: lut_out = 16'h2EBB; // 0.365102
            8'hDB: lut_out = 16'h2F7F; // 0.371065
            8'hDC: lut_out = 16'h3046; // 0.377139
            8'hDD: lut_out = 16'h3111; // 0.383331
            8'hDE: lut_out = 16'h31E0; // 0.389647
            8'hDF: lut_out = 16'h32B3; // 0.396095
            8'hE0: lut_out = 16'h338B; // 0.402681
            8'hE1: lut_out = 16'h3467; // 0.409416
            8'hE2: lut_out = 16'h3549; // 0.416309
            8'hE3: lut_out = 16'h3631; // 0.423369
            8'hE4: lut_out = 16'h371E; // 0.430608
            8'hE5: lut_out = 16'h3811; // 0.438040
            8'hE6: lut_out = 16'h390C; // 0.445677
            8'hE7: lut_out = 16'h3A0D; // 0.453536
            8'hE8: lut_out = 16'h3B16; // 0.461635
            8'hE9: lut_out = 16'h3C28; // 0.469992
            8'hEA: lut_out = 16'h3D43; // 0.478630
            8'hEB: lut_out = 16'h3E68; // 0.487575
            8'hEC: lut_out = 16'h3F98; // 0.496855
            8'hED: lut_out = 16'h40D5; // 0.506504
            8'hEE: lut_out = 16'h421E; // 0.516560
            8'hEF: lut_out = 16'h4376; // 0.527069
            8'hF0: lut_out = 16'h44DF; // 0.538084
            8'hF1: lut_out = 16'h465B; // 0.549668
            8'hF2: lut_out = 16'h47EC; // 0.561898
            8'hF3: lut_out = 16'h4995; // 0.574867
            8'hF4: lut_out = 16'h4B5A; // 0.588692
            8'hF5: lut_out = 16'h4D3F; // 0.603519
            8'hF6: lut_out = 16'h4F4C; // 0.619536
            8'hF7: lut_out = 16'h5188; // 0.636992
            8'hF8: lut_out = 16'h53FF; // 0.656228
            8'hF9: lut_out = 16'h56BF; // 0.677720
            8'hFA: lut_out = 16'h59E0; // 0.702182
            8'hFB: lut_out = 16'h5D88; // 0.730735
            8'hFC: lut_out = 16'h61F5; // 0.765324
            8'hFD: lut_out = 16'h67A7; // 0.809801
            8'hFE: lut_out = 16'h6FD9; // 0.873828
            8'hFF: lut_out = 16'h7FFF; // 1.000000
            default: lut_out = 16'h0000;
        endcase
    end

    // ----------------------------------------------------------------
    // Encode: combinational argmin distance search
    // Iterates all 256 LUT entries and finds index with minimum |enc_in - lut[i]|
    // ----------------------------------------------------------------
    reg [15:0] lut_val [0:255];
    integer ei;

    // Initialize LUT array for encode search (matches decode ROM above)
    // Synthesis: inferred as ROM, no FF
    always @(*) begin
        lut_val[0] = 16'h8001;
        lut_val[1] = 16'h9027;
        lut_val[2] = 16'h9859;
        lut_val[3] = 16'h9E0B;
        lut_val[4] = 16'hA278;
        lut_val[5] = 16'hA620;
        lut_val[6] = 16'hA941;
        lut_val[7] = 16'hAC01;
        lut_val[8] = 16'hAE78;
        lut_val[9] = 16'hB0B4;
        lut_val[10] = 16'hB2C1;
        lut_val[11] = 16'hB4A6;
        lut_val[12] = 16'hB66B;
        lut_val[13] = 16'hB814;
        lut_val[14] = 16'hB9A5;
        lut_val[15] = 16'hBB21;
        lut_val[16] = 16'hBC8A;
        lut_val[17] = 16'hBDE2;
        lut_val[18] = 16'hBF2B;
        lut_val[19] = 16'hC068;
        lut_val[20] = 16'hC198;
        lut_val[21] = 16'hC2BD;
        lut_val[22] = 16'hC3D8;
        lut_val[23] = 16'hC4EA;
        lut_val[24] = 16'hC5F3;
        lut_val[25] = 16'hC6F4;
        lut_val[26] = 16'hC7EF;
        lut_val[27] = 16'hC8E2;
        lut_val[28] = 16'hC9CF;
        lut_val[29] = 16'hCAB7;
        lut_val[30] = 16'hCB99;
        lut_val[31] = 16'hCC75;
        lut_val[32] = 16'hCD4D;
        lut_val[33] = 16'hCE20;
        lut_val[34] = 16'hCEEF;
        lut_val[35] = 16'hCFBA;
        lut_val[36] = 16'hD081;
        lut_val[37] = 16'hD145;
        lut_val[38] = 16'hD205;
        lut_val[39] = 16'hD2C1;
        lut_val[40] = 16'hD37B;
        lut_val[41] = 16'hD431;
        lut_val[42] = 16'hD4E5;
        lut_val[43] = 16'hD596;
        lut_val[44] = 16'hD644;
        lut_val[45] = 16'hD6F0;
        lut_val[46] = 16'hD79A;
        lut_val[47] = 16'hD841;
        lut_val[48] = 16'hD8E6;
        lut_val[49] = 16'hD989;
        lut_val[50] = 16'hDA2A;
        lut_val[51] = 16'hDAC9;
        lut_val[52] = 16'hDB67;
        lut_val[53] = 16'hDC02;
        lut_val[54] = 16'hDC9C;
        lut_val[55] = 16'hDD34;
        lut_val[56] = 16'hDDCB;
        lut_val[57] = 16'hDE60;
        lut_val[58] = 16'hDEF3;
        lut_val[59] = 16'hDF86;
        lut_val[60] = 16'hE017;
        lut_val[61] = 16'hE0A6;
        lut_val[62] = 16'hE134;
        lut_val[63] = 16'hE1C1;
        lut_val[64] = 16'hE24D;
        lut_val[65] = 16'hE2D8;
        lut_val[66] = 16'hE362;
        lut_val[67] = 16'hE3EA;
        lut_val[68] = 16'hE472;
        lut_val[69] = 16'hE4F8;
        lut_val[70] = 16'hE57E;
        lut_val[71] = 16'hE602;
        lut_val[72] = 16'hE686;
        lut_val[73] = 16'hE709;
        lut_val[74] = 16'hE78B;
        lut_val[75] = 16'hE80C;
        lut_val[76] = 16'hE88D;
        lut_val[77] = 16'hE90C;
        lut_val[78] = 16'hE98B;
        lut_val[79] = 16'hEA09;
        lut_val[80] = 16'hEA87;
        lut_val[81] = 16'hEB04;
        lut_val[82] = 16'hEB80;
        lut_val[83] = 16'hEBFC;
        lut_val[84] = 16'hEC77;
        lut_val[85] = 16'hECF1;
        lut_val[86] = 16'hED6B;
        lut_val[87] = 16'hEDE4;
        lut_val[88] = 16'hEE5D;
        lut_val[89] = 16'hEED5;
        lut_val[90] = 16'hEF4D;
        lut_val[91] = 16'hEFC4;
        lut_val[92] = 16'hF03B;
        lut_val[93] = 16'hF0B1;
        lut_val[94] = 16'hF127;
        lut_val[95] = 16'hF19D;
        lut_val[96] = 16'hF212;
        lut_val[97] = 16'hF287;
        lut_val[98] = 16'hF2FB;
        lut_val[99] = 16'hF370;
        lut_val[100] = 16'hF3E3;
        lut_val[101] = 16'hF457;
        lut_val[102] = 16'hF4CA;
        lut_val[103] = 16'hF53D;
        lut_val[104] = 16'hF5AF;
        lut_val[105] = 16'hF622;
        lut_val[106] = 16'hF694;
        lut_val[107] = 16'hF705;
        lut_val[108] = 16'hF777;
        lut_val[109] = 16'hF7E8;
        lut_val[110] = 16'hF859;
        lut_val[111] = 16'hF8CA;
        lut_val[112] = 16'hF93B;
        lut_val[113] = 16'hF9AC;
        lut_val[114] = 16'hFA1C;
        lut_val[115] = 16'hFA8C;
        lut_val[116] = 16'hFAFD;
        lut_val[117] = 16'hFB6D;
        lut_val[118] = 16'hFBDC;
        lut_val[119] = 16'hFC4C;
        lut_val[120] = 16'hFCBC;
        lut_val[121] = 16'hFD2C;
        lut_val[122] = 16'hFD9B;
        lut_val[123] = 16'hFE0B;
        lut_val[124] = 16'hFE7A;
        lut_val[125] = 16'hFEEA;
        lut_val[126] = 16'hFF59;
        lut_val[127] = 16'hFFC8;
        lut_val[128] = 16'h0038;
        lut_val[129] = 16'h00A7;
        lut_val[130] = 16'h0116;
        lut_val[131] = 16'h0186;
        lut_val[132] = 16'h01F5;
        lut_val[133] = 16'h0265;
        lut_val[134] = 16'h02D4;
        lut_val[135] = 16'h0344;
        lut_val[136] = 16'h03B4;
        lut_val[137] = 16'h0424;
        lut_val[138] = 16'h0493;
        lut_val[139] = 16'h0503;
        lut_val[140] = 16'h0574;
        lut_val[141] = 16'h05E4;
        lut_val[142] = 16'h0654;
        lut_val[143] = 16'h06C5;
        lut_val[144] = 16'h0736;
        lut_val[145] = 16'h07A7;
        lut_val[146] = 16'h0818;
        lut_val[147] = 16'h0889;
        lut_val[148] = 16'h08FB;
        lut_val[149] = 16'h096C;
        lut_val[150] = 16'h09DE;
        lut_val[151] = 16'h0A51;
        lut_val[152] = 16'h0AC3;
        lut_val[153] = 16'h0B36;
        lut_val[154] = 16'h0BA9;
        lut_val[155] = 16'h0C1D;
        lut_val[156] = 16'h0C90;
        lut_val[157] = 16'h0D05;
        lut_val[158] = 16'h0D79;
        lut_val[159] = 16'h0DEE;
        lut_val[160] = 16'h0E63;
        lut_val[161] = 16'h0ED9;
        lut_val[162] = 16'h0F4F;
        lut_val[163] = 16'h0FC5;
        lut_val[164] = 16'h103C;
        lut_val[165] = 16'h10B3;
        lut_val[166] = 16'h112B;
        lut_val[167] = 16'h11A3;
        lut_val[168] = 16'h121C;
        lut_val[169] = 16'h1295;
        lut_val[170] = 16'h130F;
        lut_val[171] = 16'h1389;
        lut_val[172] = 16'h1404;
        lut_val[173] = 16'h1480;
        lut_val[174] = 16'h14FC;
        lut_val[175] = 16'h1579;
        lut_val[176] = 16'h15F7;
        lut_val[177] = 16'h1675;
        lut_val[178] = 16'h16F4;
        lut_val[179] = 16'h1773;
        lut_val[180] = 16'h17F4;
        lut_val[181] = 16'h1875;
        lut_val[182] = 16'h18F7;
        lut_val[183] = 16'h197A;
        lut_val[184] = 16'h19FE;
        lut_val[185] = 16'h1A82;
        lut_val[186] = 16'h1B08;
        lut_val[187] = 16'h1B8E;
        lut_val[188] = 16'h1C16;
        lut_val[189] = 16'h1C9E;
        lut_val[190] = 16'h1D28;
        lut_val[191] = 16'h1DB3;
        lut_val[192] = 16'h1E3F;
        lut_val[193] = 16'h1ECC;
        lut_val[194] = 16'h1F5A;
        lut_val[195] = 16'h1FE9;
        lut_val[196] = 16'h207A;
        lut_val[197] = 16'h210D;
        lut_val[198] = 16'h21A0;
        lut_val[199] = 16'h2235;
        lut_val[200] = 16'h22CC;
        lut_val[201] = 16'h2364;
        lut_val[202] = 16'h23FE;
        lut_val[203] = 16'h2499;
        lut_val[204] = 16'h2537;
        lut_val[205] = 16'h25D6;
        lut_val[206] = 16'h2677;
        lut_val[207] = 16'h271A;
        lut_val[208] = 16'h27BF;
        lut_val[209] = 16'h2866;
        lut_val[210] = 16'h2910;
        lut_val[211] = 16'h29BC;
        lut_val[212] = 16'h2A6A;
        lut_val[213] = 16'h2B1B;
        lut_val[214] = 16'h2BCF;
        lut_val[215] = 16'h2C85;
        lut_val[216] = 16'h2D3F;
        lut_val[217] = 16'h2DFB;
        lut_val[218] = 16'h2EBB;
        lut_val[219] = 16'h2F7F;
        lut_val[220] = 16'h3046;
        lut_val[221] = 16'h3111;
        lut_val[222] = 16'h31E0;
        lut_val[223] = 16'h32B3;
        lut_val[224] = 16'h338B;
        lut_val[225] = 16'h3467;
        lut_val[226] = 16'h3549;
        lut_val[227] = 16'h3631;
        lut_val[228] = 16'h371E;
        lut_val[229] = 16'h3811;
        lut_val[230] = 16'h390C;
        lut_val[231] = 16'h3A0D;
        lut_val[232] = 16'h3B16;
        lut_val[233] = 16'h3C28;
        lut_val[234] = 16'h3D43;
        lut_val[235] = 16'h3E68;
        lut_val[236] = 16'h3F98;
        lut_val[237] = 16'h40D5;
        lut_val[238] = 16'h421E;
        lut_val[239] = 16'h4376;
        lut_val[240] = 16'h44DF;
        lut_val[241] = 16'h465B;
        lut_val[242] = 16'h47EC;
        lut_val[243] = 16'h4995;
        lut_val[244] = 16'h4B5A;
        lut_val[245] = 16'h4D3F;
        lut_val[246] = 16'h4F4C;
        lut_val[247] = 16'h5188;
        lut_val[248] = 16'h53FF;
        lut_val[249] = 16'h56BF;
        lut_val[250] = 16'h59E0;
        lut_val[251] = 16'h5D88;
        lut_val[252] = 16'h61F5;
        lut_val[253] = 16'h67A7;
        lut_val[254] = 16'h6FD9;
        lut_val[255] = 16'h7FFF;
        // Find argmin |enc_in - lut_val[i]| over all 256 entries
        // Use signed difference, absolute value via conditional negate
        enc_idx = 8'h00;
        begin : enc_search
            reg [15:0] best_dist;
            reg [15:0] cur_dist;
            reg signed [16:0] diff;
            best_dist = 16'hFFFF;
            for (ei = 0; ei < 256; ei = ei + 1) begin
                diff = $signed({1'b0, enc_in}) - $signed({1'b0, lut_val[ei]});
                cur_dist = diff[16] ? (~diff[15:0] + 16'd1) : diff[15:0];
                if (cur_dist < best_dist) begin
                    best_dist = cur_dist;
                    enc_idx = ei[7:0];
                end
            end
        end
    end

endmodule
`default_nettype wire
