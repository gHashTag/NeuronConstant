// =============================================================================
// unum_ii8.v — Unum Type II, 8-bit (256-entry projective LUT)
// =============================================================================
// Gustafson, J. "A Radical Approach to Computation with Real Numbers"
// SuperComputing 2016 / Type II Unum (Posit predecessor).
//
// 8-bit Unum Type II: 256 unsigned indices map to the projective real line.
//   index 0   → projective −∞ (clamped to 32'h80000000 = -32768.0 in Q16.16)
//   index 64  → −1.0 (Q16.16 = -65536)
//   index 128 → 0.0
//   index 192 → +1.0 (Q16.16 = 65536)
//   index 255 → ~+81.5 (near +∞)
//
// Output: 32-bit signed Q16.16 fixed-point (scale = 2^16 = 65536)
//
// LUT precomputed as: round(tan((i-128)/128 * pi/2) * 65536)
// Clamped to signed 32-bit for i near 0 (−∞) and 255 (near +∞).
//
// R-SI-1: ROM lookup only — no arithmetic operators.
// =============================================================================

`default_nettype none

module unum_ii8 (
    input  wire [7:0]         index_in,     // projective index 0..255

    output wire               sign_out,     // 0=positive, 1=negative
    output wire               is_zero,      // index=128 → value=0
    output wire               is_inf,       // index=0 → projective ∞

    // Q16.16 decoded value (32-bit signed, scale=65536)
    output wire signed [31:0] decoded_q1616,

    // Passthrough
    output wire [7:0]         index_out
);

    assign sign_out  = ~index_in[7];   // MSB=0 → negative half
    assign is_zero   = (index_in == 8'd128);
    assign is_inf    = (index_in == 8'd0);
    assign index_out = index_in;

    // -------------------------------------------------------------------------
    // 256-entry projective ROM (Q16.16 fixed-point)
    // Computed: lut[i] = round(tan((i-128)/128 * pi/2) * 65536)
    // -------------------------------------------------------------------------
    reg signed [31:0] lut [0:255];

    integer lut_init_i;
    initial begin
        lut[8'd  0] = $signed(32'h80000000); // ≈-32768.0000
        lut[8'd  1] = $signed(32'hFFAE844A); // ≈-81.4832
        lut[8'd  2] = $signed(32'hFFD743B7); // ≈-40.7355
        lut[8'd  3] = $signed(32'hFFE4D98E); // ≈-27.1502
        lut[8'd  4] = $signed(32'hFFEBA500); // ≈-20.3555
        lut[8'd  5] = $signed(32'hFFEFB916); // ≈-16.2770
        lut[8'd  6] = $signed(32'hFFF2717E); // ≈-13.5567
        lut[8'd  7] = $signed(32'hFFF4633A); // ≈-11.6124
        lut[8'd  8] = $signed(32'hFFF5D8CA); // ≈-10.1532
        lut[8'd  9] = $signed(32'hFFF6FB92); // ≈-9.0173
        lut[8'd 10] = $signed(32'hFFF7E468); // ≈-8.1078
        lut[8'd 11] = $signed(32'hFFF8A31A); // ≈-7.3629
        lut[8'd 12] = $signed(32'hFFF94230); // ≈-6.7415
        lut[8'd 13] = $signed(32'hFFF9C8F7); // ≈-6.2150
        lut[8'd 14] = $signed(32'hFFFA3CA3); // ≈-5.7631
        lut[8'd 15] = $signed(32'hFFFAA107); // ≈-5.3710
        lut[8'd 16] = $signed(32'hFFFAF900); // ≈-5.0273
        lut[8'd 17] = $signed(32'hFFFB46C0); // ≈-4.7236
        lut[8'd 18] = $signed(32'hFFFB8BFB); // ≈-4.4532
        lut[8'd 19] = $signed(32'hFFFBCA09); // ≈-4.2108
        lut[8'd 20] = $signed(32'hFFFC01FE); // ≈-3.9922
        lut[8'd 21] = $signed(32'hFFFC34B8); // ≈-3.7941
        lut[8'd 22] = $signed(32'hFFFC62EF); // ≈-3.6135
        lut[8'd 23] = $signed(32'hFFFC8D3A); // ≈-3.4483
        lut[8'd 24] = $signed(32'hFFFCB415); // ≈-3.2966
        lut[8'd 25] = $signed(32'hFFFCD7EA); // ≈-3.1566
        lut[8'd 26] = $signed(32'hFFFCF914); // ≈-3.0270
        lut[8'd 27] = $signed(32'hFFFD17DD); // ≈-2.9068
        lut[8'd 28] = $signed(32'hFFFD3487); // ≈-2.7948
        lut[8'd 29] = $signed(32'hFFFD4F4B); // ≈-2.6903
        lut[8'd 30] = $signed(32'hFFFD6858); // ≈-2.5924
        lut[8'd 31] = $signed(32'hFFFD7FDA); // ≈-2.5006
        lut[8'd 32] = $signed(32'hFFFD95F6); // ≈-2.4142
        lut[8'd 33] = $signed(32'hFFFDAACC); // ≈-2.3328
        lut[8'd 34] = $signed(32'hFFFDBE79); // ≈-2.2560
        lut[8'd 35] = $signed(32'hFFFDD117); // ≈-2.1832
        lut[8'd 36] = $signed(32'hFFFDE2BC); // ≈-2.1143
        lut[8'd 37] = $signed(32'hFFFDF37C); // ≈-2.0489
        lut[8'd 38] = $signed(32'hFFFE036A); // ≈-1.9867
        lut[8'd 39] = $signed(32'hFFFE1296); // ≈-1.9274
        lut[8'd 40] = $signed(32'hFFFE210F); // ≈-1.8709
        lut[8'd 41] = $signed(32'hFFFE2EE1); // ≈-1.8169
        lut[8'd 42] = $signed(32'hFFFE3C19); // ≈-1.7652
        lut[8'd 43] = $signed(32'hFFFE48C1); // ≈-1.7158
        lut[8'd 44] = $signed(32'hFFFE54E4); // ≈-1.6684
        lut[8'd 45] = $signed(32'hFFFE608A); // ≈-1.6229
        lut[8'd 46] = $signed(32'hFFFE6BBB); // ≈-1.5792
        lut[8'd 47] = $signed(32'hFFFE7680); // ≈-1.5371
        lut[8'd 48] = $signed(32'hFFFE80DE); // ≈-1.4966
        lut[8'd 49] = $signed(32'hFFFE8ADD); // ≈-1.4576
        lut[8'd 50] = $signed(32'hFFFE9482); // ≈-1.4199
        lut[8'd 51] = $signed(32'hFFFE9DD2); // ≈-1.3835
        lut[8'd 52] = $signed(32'hFFFEA6D3); // ≈-1.3483
        lut[8'd 53] = $signed(32'hFFFEAF89); // ≈-1.3143
        lut[8'd 54] = $signed(32'hFFFEB7F7); // ≈-1.2814
        lut[8'd 55] = $signed(32'hFFFEC023); // ≈-1.2495
        lut[8'd 56] = $signed(32'hFFFEC810); // ≈-1.2185
        lut[8'd 57] = $signed(32'hFFFECFC1); // ≈-1.1885
        lut[8'd 58] = $signed(32'hFFFED73A); // ≈-1.1593
        lut[8'd 59] = $signed(32'hFFFEDE7C); // ≈-1.1309
        lut[8'd 60] = $signed(32'hFFFEE58C); // ≈-1.1033
        lut[8'd 61] = $signed(32'hFFFEEC6C); // ≈-1.0765
        lut[8'd 62] = $signed(32'hFFFEF31D); // ≈-1.0503
        lut[8'd 63] = $signed(32'hFFFEF9A3); // ≈-1.0249
        lut[8'd 64] = $signed(32'hFFFF0000); // ≈-1.0000
        lut[8'd 65] = $signed(32'hFFFF0635); // ≈-0.9758
        lut[8'd 66] = $signed(32'hFFFF0C45); // ≈-0.9521
        lut[8'd 67] = $signed(32'hFFFF1230); // ≈-0.9290
        lut[8'd 68] = $signed(32'hFFFF17FA); // ≈-0.9063
        lut[8'd 69] = $signed(32'hFFFF1DA2); // ≈-0.8842
        lut[8'd 70] = $signed(32'hFFFF232C); // ≈-0.8626
        lut[8'd 71] = $signed(32'hFFFF2898); // ≈-0.8414
        lut[8'd 72] = $signed(32'hFFFF2DE8); // ≈-0.8207
        lut[8'd 73] = $signed(32'hFFFF331D); // ≈-0.8003
        lut[8'd 74] = $signed(32'hFFFF3837); // ≈-0.7804
        lut[8'd 75] = $signed(32'hFFFF3D39); // ≈-0.7608
        lut[8'd 76] = $signed(32'hFFFF4223); // ≈-0.7417
        lut[8'd 77] = $signed(32'hFFFF46F7); // ≈-0.7228
        lut[8'd 78] = $signed(32'hFFFF4BB4); // ≈-0.7043
        lut[8'd 79] = $signed(32'hFFFF505D); // ≈-0.6861
        lut[8'd 80] = $signed(32'hFFFF54F2); // ≈-0.6682
        lut[8'd 81] = $signed(32'hFFFF5974); // ≈-0.6506
        lut[8'd 82] = $signed(32'hFFFF5DE4); // ≈-0.6332
        lut[8'd 83] = $signed(32'hFFFF6242); // ≈-0.6162
        lut[8'd 84] = $signed(32'hFFFF668F); // ≈-0.5994
        lut[8'd 85] = $signed(32'hFFFF6ACC); // ≈-0.5828
        lut[8'd 86] = $signed(32'hFFFF6EFA); // ≈-0.5665
        lut[8'd 87] = $signed(32'hFFFF7319); // ≈-0.5504
        lut[8'd 88] = $signed(32'hFFFF772A); // ≈-0.5345
        lut[8'd 89] = $signed(32'hFFFF7B2E); // ≈-0.5188
        lut[8'd 90] = $signed(32'hFFFF7F24); // ≈-0.5034
        lut[8'd 91] = $signed(32'hFFFF830E); // ≈-0.4881
        lut[8'd 92] = $signed(32'hFFFF86EC); // ≈-0.4730
        lut[8'd 93] = $signed(32'hFFFF8ABE); // ≈-0.4580
        lut[8'd 94] = $signed(32'hFFFF8E86); // ≈-0.4433
        lut[8'd 95] = $signed(32'hFFFF9243); // ≈-0.4287
        lut[8'd 96] = $signed(32'hFFFF95F6); // ≈-0.4142
        lut[8'd 97] = $signed(32'hFFFF99A0); // ≈-0.3999
        lut[8'd 98] = $signed(32'hFFFF9D40); // ≈-0.3857
        lut[8'd 99] = $signed(32'hFFFFA0D8); // ≈-0.3717
        lut[8'd100] = $signed(32'hFFFFA467); // ≈-0.3578
        lut[8'd101] = $signed(32'hFFFFA7EE); // ≈-0.3440
        lut[8'd102] = $signed(32'hFFFFAB6E); // ≈-0.3304
        lut[8'd103] = $signed(32'hFFFFAEE6); // ≈-0.3168
        lut[8'd104] = $signed(32'hFFFFB258); // ≈-0.3033
        lut[8'd105] = $signed(32'hFFFFB5C3); // ≈-0.2900
        lut[8'd106] = $signed(32'hFFFFB928); // ≈-0.2767
        lut[8'd107] = $signed(32'hFFFFBC87); // ≈-0.2636
        lut[8'd108] = $signed(32'hFFFFBFE0); // ≈-0.2505
        lut[8'd109] = $signed(32'hFFFFC334); // ≈-0.2375
        lut[8'd110] = $signed(32'hFFFFC683); // ≈-0.2246
        lut[8'd111] = $signed(32'hFFFFC9CE); // ≈-0.2117
        lut[8'd112] = $signed(32'hFFFFCD14); // ≈-0.1989
        lut[8'd113] = $signed(32'hFFFFD056); // ≈-0.1862
        lut[8'd114] = $signed(32'hFFFFD394); // ≈-0.1735
        lut[8'd115] = $signed(32'hFFFFD6CF); // ≈-0.1609
        lut[8'd116] = $signed(32'hFFFFDA07); // ≈-0.1483
        lut[8'd117] = $signed(32'hFFFFDD3B); // ≈-0.1358
        lut[8'd118] = $signed(32'hFFFFE06D); // ≈-0.1233
        lut[8'd119] = $signed(32'hFFFFE39C); // ≈-0.1109
        lut[8'd120] = $signed(32'hFFFFE6C9); // ≈-0.0985
        lut[8'd121] = $signed(32'hFFFFE9F4); // ≈-0.0861
        lut[8'd122] = $signed(32'hFFFFED1E); // ≈-0.0738
        lut[8'd123] = $signed(32'hFFFFF046); // ≈-0.0614
        lut[8'd124] = $signed(32'hFFFFF36C); // ≈-0.0491
        lut[8'd125] = $signed(32'hFFFFF692); // ≈-0.0368
        lut[8'd126] = $signed(32'hFFFFF9B7); // ≈-0.0246
        lut[8'd127] = $signed(32'hFFFFFCDC); // ≈-0.0123
        lut[8'd128] = $signed(32'h00000000); // ≈+0.0000
        lut[8'd129] = $signed(32'h00000324); // ≈+0.0123
        lut[8'd130] = $signed(32'h00000649); // ≈+0.0246
        lut[8'd131] = $signed(32'h0000096E); // ≈+0.0368
        lut[8'd132] = $signed(32'h00000C94); // ≈+0.0491
        lut[8'd133] = $signed(32'h00000FBA); // ≈+0.0614
        lut[8'd134] = $signed(32'h000012E2); // ≈+0.0738
        lut[8'd135] = $signed(32'h0000160C); // ≈+0.0861
        lut[8'd136] = $signed(32'h00001937); // ≈+0.0985
        lut[8'd137] = $signed(32'h00001C64); // ≈+0.1109
        lut[8'd138] = $signed(32'h00001F93); // ≈+0.1233
        lut[8'd139] = $signed(32'h000022C5); // ≈+0.1358
        lut[8'd140] = $signed(32'h000025F9); // ≈+0.1483
        lut[8'd141] = $signed(32'h00002931); // ≈+0.1609
        lut[8'd142] = $signed(32'h00002C6C); // ≈+0.1735
        lut[8'd143] = $signed(32'h00002FAA); // ≈+0.1862
        lut[8'd144] = $signed(32'h000032EC); // ≈+0.1989
        lut[8'd145] = $signed(32'h00003632); // ≈+0.2117
        lut[8'd146] = $signed(32'h0000397D); // ≈+0.2246
        lut[8'd147] = $signed(32'h00003CCC); // ≈+0.2375
        lut[8'd148] = $signed(32'h00004020); // ≈+0.2505
        lut[8'd149] = $signed(32'h00004379); // ≈+0.2636
        lut[8'd150] = $signed(32'h000046D8); // ≈+0.2767
        lut[8'd151] = $signed(32'h00004A3D); // ≈+0.2900
        lut[8'd152] = $signed(32'h00004DA8); // ≈+0.3033
        lut[8'd153] = $signed(32'h0000511A); // ≈+0.3168
        lut[8'd154] = $signed(32'h00005492); // ≈+0.3304
        lut[8'd155] = $signed(32'h00005812); // ≈+0.3440
        lut[8'd156] = $signed(32'h00005B99); // ≈+0.3578
        lut[8'd157] = $signed(32'h00005F28); // ≈+0.3717
        lut[8'd158] = $signed(32'h000062C0); // ≈+0.3857
        lut[8'd159] = $signed(32'h00006660); // ≈+0.3999
        lut[8'd160] = $signed(32'h00006A0A); // ≈+0.4142
        lut[8'd161] = $signed(32'h00006DBD); // ≈+0.4287
        lut[8'd162] = $signed(32'h0000717A); // ≈+0.4433
        lut[8'd163] = $signed(32'h00007542); // ≈+0.4580
        lut[8'd164] = $signed(32'h00007914); // ≈+0.4730
        lut[8'd165] = $signed(32'h00007CF2); // ≈+0.4881
        lut[8'd166] = $signed(32'h000080DC); // ≈+0.5034
        lut[8'd167] = $signed(32'h000084D2); // ≈+0.5188
        lut[8'd168] = $signed(32'h000088D6); // ≈+0.5345
        lut[8'd169] = $signed(32'h00008CE7); // ≈+0.5504
        lut[8'd170] = $signed(32'h00009106); // ≈+0.5665
        lut[8'd171] = $signed(32'h00009534); // ≈+0.5828
        lut[8'd172] = $signed(32'h00009971); // ≈+0.5994
        lut[8'd173] = $signed(32'h00009DBE); // ≈+0.6162
        lut[8'd174] = $signed(32'h0000A21C); // ≈+0.6332
        lut[8'd175] = $signed(32'h0000A68C); // ≈+0.6506
        lut[8'd176] = $signed(32'h0000AB0E); // ≈+0.6682
        lut[8'd177] = $signed(32'h0000AFA3); // ≈+0.6861
        lut[8'd178] = $signed(32'h0000B44C); // ≈+0.7043
        lut[8'd179] = $signed(32'h0000B909); // ≈+0.7228
        lut[8'd180] = $signed(32'h0000BDDD); // ≈+0.7417
        lut[8'd181] = $signed(32'h0000C2C7); // ≈+0.7608
        lut[8'd182] = $signed(32'h0000C7C9); // ≈+0.7804
        lut[8'd183] = $signed(32'h0000CCE3); // ≈+0.8003
        lut[8'd184] = $signed(32'h0000D218); // ≈+0.8207
        lut[8'd185] = $signed(32'h0000D768); // ≈+0.8414
        lut[8'd186] = $signed(32'h0000DCD4); // ≈+0.8626
        lut[8'd187] = $signed(32'h0000E25E); // ≈+0.8842
        lut[8'd188] = $signed(32'h0000E806); // ≈+0.9063
        lut[8'd189] = $signed(32'h0000EDD0); // ≈+0.9290
        lut[8'd190] = $signed(32'h0000F3BB); // ≈+0.9521
        lut[8'd191] = $signed(32'h0000F9CB); // ≈+0.9758
        lut[8'd192] = $signed(32'h00010000); // ≈+1.0000
        lut[8'd193] = $signed(32'h0001065D); // ≈+1.0249
        lut[8'd194] = $signed(32'h00010CE3); // ≈+1.0503
        lut[8'd195] = $signed(32'h00011394); // ≈+1.0765
        lut[8'd196] = $signed(32'h00011A74); // ≈+1.1033
        lut[8'd197] = $signed(32'h00012184); // ≈+1.1309
        lut[8'd198] = $signed(32'h000128C6); // ≈+1.1593
        lut[8'd199] = $signed(32'h0001303F); // ≈+1.1885
        lut[8'd200] = $signed(32'h000137F0); // ≈+1.2185
        lut[8'd201] = $signed(32'h00013FDD); // ≈+1.2495
        lut[8'd202] = $signed(32'h00014809); // ≈+1.2814
        lut[8'd203] = $signed(32'h00015077); // ≈+1.3143
        lut[8'd204] = $signed(32'h0001592D); // ≈+1.3483
        lut[8'd205] = $signed(32'h0001622E); // ≈+1.3835
        lut[8'd206] = $signed(32'h00016B7E); // ≈+1.4199
        lut[8'd207] = $signed(32'h00017523); // ≈+1.4576
        lut[8'd208] = $signed(32'h00017F22); // ≈+1.4966
        lut[8'd209] = $signed(32'h00018980); // ≈+1.5371
        lut[8'd210] = $signed(32'h00019445); // ≈+1.5792
        lut[8'd211] = $signed(32'h00019F76); // ≈+1.6229
        lut[8'd212] = $signed(32'h0001AB1C); // ≈+1.6684
        lut[8'd213] = $signed(32'h0001B73F); // ≈+1.7158
        lut[8'd214] = $signed(32'h0001C3E7); // ≈+1.7652
        lut[8'd215] = $signed(32'h0001D11F); // ≈+1.8169
        lut[8'd216] = $signed(32'h0001DEF1); // ≈+1.8709
        lut[8'd217] = $signed(32'h0001ED6A); // ≈+1.9274
        lut[8'd218] = $signed(32'h0001FC96); // ≈+1.9867
        lut[8'd219] = $signed(32'h00020C84); // ≈+2.0489
        lut[8'd220] = $signed(32'h00021D44); // ≈+2.1143
        lut[8'd221] = $signed(32'h00022EE9); // ≈+2.1832
        lut[8'd222] = $signed(32'h00024187); // ≈+2.2560
        lut[8'd223] = $signed(32'h00025534); // ≈+2.3328
        lut[8'd224] = $signed(32'h00026A0A); // ≈+2.4142
        lut[8'd225] = $signed(32'h00028026); // ≈+2.5006
        lut[8'd226] = $signed(32'h000297A8); // ≈+2.5924
        lut[8'd227] = $signed(32'h0002B0B5); // ≈+2.6903
        lut[8'd228] = $signed(32'h0002CB79); // ≈+2.7948
        lut[8'd229] = $signed(32'h0002E823); // ≈+2.9068
        lut[8'd230] = $signed(32'h000306EC); // ≈+3.0270
        lut[8'd231] = $signed(32'h00032816); // ≈+3.1566
        lut[8'd232] = $signed(32'h00034BEB); // ≈+3.2966
        lut[8'd233] = $signed(32'h000372C6); // ≈+3.4483
        lut[8'd234] = $signed(32'h00039D11); // ≈+3.6135
        lut[8'd235] = $signed(32'h0003CB48); // ≈+3.7941
        lut[8'd236] = $signed(32'h0003FE02); // ≈+3.9922
        lut[8'd237] = $signed(32'h000435F7); // ≈+4.2108
        lut[8'd238] = $signed(32'h00047405); // ≈+4.4532
        lut[8'd239] = $signed(32'h0004B940); // ≈+4.7236
        lut[8'd240] = $signed(32'h00050700); // ≈+5.0273
        lut[8'd241] = $signed(32'h00055EF9); // ≈+5.3710
        lut[8'd242] = $signed(32'h0005C35D); // ≈+5.7631
        lut[8'd243] = $signed(32'h00063709); // ≈+6.2150
        lut[8'd244] = $signed(32'h0006BDD0); // ≈+6.7415
        lut[8'd245] = $signed(32'h00075CE6); // ≈+7.3629
        lut[8'd246] = $signed(32'h00081B98); // ≈+8.1078
        lut[8'd247] = $signed(32'h0009046E); // ≈+9.0173
        lut[8'd248] = $signed(32'h000A2736); // ≈+10.1532
        lut[8'd249] = $signed(32'h000B9CC6); // ≈+11.6124
        lut[8'd250] = $signed(32'h000D8E82); // ≈+13.5567
        lut[8'd251] = $signed(32'h001046EA); // ≈+16.2770
        lut[8'd252] = $signed(32'h00145B00); // ≈+20.3555
        lut[8'd253] = $signed(32'h001B2672); // ≈+27.1502
        lut[8'd254] = $signed(32'h0028BC49); // ≈+40.7355
        lut[8'd255] = $signed(32'h00517BB6); // ≈+81.4832
    end

    assign decoded_q1616 = lut[index_in];

endmodule

`default_nettype wire
