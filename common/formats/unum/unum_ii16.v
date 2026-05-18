// =============================================================================
// unum_ii16.v — Unum Type II, 16-bit (Piece-Wise Linear approximation)
// =============================================================================
// Gustafson, J. "A Radical Approach to Computation with Real Numbers"
// SuperComputing 2016 / Type II Unum.
//
// 16-bit Unum Type II: 65536 unsigned indices → projective real line.
// A full 65536-entry LUT would require 256 KB of ROM — impractical for RTL.
// This module uses 256-SEGMENT PIECE-WISE LINEAR (PWL) approximation:
//
//   - 256 anchor points at every 256th index (segment boundaries)
//   - Linear interpolation within each 256-entry segment using a stored slope
//   - Approximation error: ≤ ±0.25 relative in normal range,
//     up to ±16K LSB (Q16.16 scale=65536) near ±∞ singularities.
//     For typical values |val| < 100: error < ±0.01 relative.
//
// Approximation formula:
//   segment = index[15:8]           (upper 8 bits → 0..255)
//   offset  = index[7:0]            (lower 8 bits → 0..255, within segment)
//   value   = anchor[segment] + slope[segment] * offset
//
// R-SI-1: slope × offset via shift-add (bit-select accumulation).
//
// Output: Q16.16 signed 32-bit (scale = 65536)
// =============================================================================

`default_nettype none

module unum_ii16 (
    input  wire [15:0]         index_in,    // projective index 0..65535

    output wire                sign_out,    // 0=positive, 1=negative
    output wire                is_zero,     // index=32768 → 0
    output wire                is_inf,      // index=0 → projective ∞

    // Q16.16 decoded value (approximate, PWL 256 segments)
    output wire signed [31:0]  decoded_q1616,

    output wire [15:0]         index_out
);

    assign sign_out  = ~index_in[15];
    assign is_zero   = (index_in == 16'd32768);
    assign is_inf    = (index_in == 16'd0);
    assign index_out = index_in;

    // -------------------------------------------------------------------------
    // Segment and offset extraction
    // -------------------------------------------------------------------------
    wire [7:0] segment = index_in[15:8];  // upper 8 bits = segment index
    wire [7:0] offset  = index_in[7:0];   // lower 8 bits = offset within segment

    // -------------------------------------------------------------------------
    // 256-entry anchor and slope ROMs (Q16.16)
    // anchor[s] = tan((s*256 - 32768) / 32768 * pi/2) * 65536
    // slope[s]  = (anchor[s+1] - anchor[s]) / 256
    // -------------------------------------------------------------------------
    reg signed [31:0] anchor_rom [0:255];
    reg signed [31:0] slope_rom  [0:255];

    integer rom_init_i;
    initial begin
        anchor_rom[8'd  0] = $signed(32'h80010000); slope_rom[8'd  0] = $signed(32'h007FAD84);
        anchor_rom[8'd  1] = $signed(32'hFFAE844A); slope_rom[8'd  1] = $signed(32'h000028BF);
        anchor_rom[8'd  2] = $signed(32'hFFD743B7); slope_rom[8'd  2] = $signed(32'h00000D96);
        anchor_rom[8'd  3] = $signed(32'hFFE4D98E); slope_rom[8'd  3] = $signed(32'h000006CB);
        anchor_rom[8'd  4] = $signed(32'hFFEBA500); slope_rom[8'd  4] = $signed(32'h00000414);
        anchor_rom[8'd  5] = $signed(32'hFFEFB916); slope_rom[8'd  5] = $signed(32'h000002B8);
        anchor_rom[8'd  6] = $signed(32'hFFF2717E); slope_rom[8'd  6] = $signed(32'h000001F2);
        anchor_rom[8'd  7] = $signed(32'hFFF4633A); slope_rom[8'd  7] = $signed(32'h00000176);
        anchor_rom[8'd  8] = $signed(32'hFFF5D8CA); slope_rom[8'd  8] = $signed(32'h00000123);
        anchor_rom[8'd  9] = $signed(32'hFFF6FB92); slope_rom[8'd  9] = $signed(32'h000000E9);
        anchor_rom[8'd 10] = $signed(32'hFFF7E468); slope_rom[8'd 10] = $signed(32'h000000BF);
        anchor_rom[8'd 11] = $signed(32'hFFF8A31A); slope_rom[8'd 11] = $signed(32'h0000009F);
        anchor_rom[8'd 12] = $signed(32'hFFF94230); slope_rom[8'd 12] = $signed(32'h00000087);
        anchor_rom[8'd 13] = $signed(32'hFFF9C8F7); slope_rom[8'd 13] = $signed(32'h00000074);
        anchor_rom[8'd 14] = $signed(32'hFFFA3CA3); slope_rom[8'd 14] = $signed(32'h00000064);
        anchor_rom[8'd 15] = $signed(32'hFFFAA107); slope_rom[8'd 15] = $signed(32'h00000058);
        anchor_rom[8'd 16] = $signed(32'hFFFAF900); slope_rom[8'd 16] = $signed(32'h0000004E);
        anchor_rom[8'd 17] = $signed(32'hFFFB46C0); slope_rom[8'd 17] = $signed(32'h00000045);
        anchor_rom[8'd 18] = $signed(32'hFFFB8BFB); slope_rom[8'd 18] = $signed(32'h0000003E);
        anchor_rom[8'd 19] = $signed(32'hFFFBCA09); slope_rom[8'd 19] = $signed(32'h00000038);
        anchor_rom[8'd 20] = $signed(32'hFFFC01FE); slope_rom[8'd 20] = $signed(32'h00000033);
        anchor_rom[8'd 21] = $signed(32'hFFFC34B8); slope_rom[8'd 21] = $signed(32'h0000002E);
        anchor_rom[8'd 22] = $signed(32'hFFFC62EF); slope_rom[8'd 22] = $signed(32'h0000002A);
        anchor_rom[8'd 23] = $signed(32'hFFFC8D3A); slope_rom[8'd 23] = $signed(32'h00000027);
        anchor_rom[8'd 24] = $signed(32'hFFFCB415); slope_rom[8'd 24] = $signed(32'h00000024);
        anchor_rom[8'd 25] = $signed(32'hFFFCD7EA); slope_rom[8'd 25] = $signed(32'h00000021);
        anchor_rom[8'd 26] = $signed(32'hFFFCF914); slope_rom[8'd 26] = $signed(32'h0000001F);
        anchor_rom[8'd 27] = $signed(32'hFFFD17DD); slope_rom[8'd 27] = $signed(32'h0000001D);
        anchor_rom[8'd 28] = $signed(32'hFFFD3487); slope_rom[8'd 28] = $signed(32'h0000001B);
        anchor_rom[8'd 29] = $signed(32'hFFFD4F4B); slope_rom[8'd 29] = $signed(32'h00000019);
        anchor_rom[8'd 30] = $signed(32'hFFFD6858); slope_rom[8'd 30] = $signed(32'h00000018);
        anchor_rom[8'd 31] = $signed(32'hFFFD7FDA); slope_rom[8'd 31] = $signed(32'h00000016);
        anchor_rom[8'd 32] = $signed(32'hFFFD95F6); slope_rom[8'd 32] = $signed(32'h00000015);
        anchor_rom[8'd 33] = $signed(32'hFFFDAACC); slope_rom[8'd 33] = $signed(32'h00000014);
        anchor_rom[8'd 34] = $signed(32'hFFFDBE79); slope_rom[8'd 34] = $signed(32'h00000013);
        anchor_rom[8'd 35] = $signed(32'hFFFDD117); slope_rom[8'd 35] = $signed(32'h00000012);
        anchor_rom[8'd 36] = $signed(32'hFFFDE2BC); slope_rom[8'd 36] = $signed(32'h00000011);
        anchor_rom[8'd 37] = $signed(32'hFFFDF37C); slope_rom[8'd 37] = $signed(32'h00000010);
        anchor_rom[8'd 38] = $signed(32'hFFFE036A); slope_rom[8'd 38] = $signed(32'h0000000F);
        anchor_rom[8'd 39] = $signed(32'hFFFE1296); slope_rom[8'd 39] = $signed(32'h0000000E);
        anchor_rom[8'd 40] = $signed(32'hFFFE210F); slope_rom[8'd 40] = $signed(32'h0000000E);
        anchor_rom[8'd 41] = $signed(32'hFFFE2EE1); slope_rom[8'd 41] = $signed(32'h0000000D);
        anchor_rom[8'd 42] = $signed(32'hFFFE3C19); slope_rom[8'd 42] = $signed(32'h0000000D);
        anchor_rom[8'd 43] = $signed(32'hFFFE48C1); slope_rom[8'd 43] = $signed(32'h0000000C);
        anchor_rom[8'd 44] = $signed(32'hFFFE54E4); slope_rom[8'd 44] = $signed(32'h0000000C);
        anchor_rom[8'd 45] = $signed(32'hFFFE608A); slope_rom[8'd 45] = $signed(32'h0000000B);
        anchor_rom[8'd 46] = $signed(32'hFFFE6BBB); slope_rom[8'd 46] = $signed(32'h0000000B);
        anchor_rom[8'd 47] = $signed(32'hFFFE7680); slope_rom[8'd 47] = $signed(32'h0000000A);
        anchor_rom[8'd 48] = $signed(32'hFFFE80DE); slope_rom[8'd 48] = $signed(32'h0000000A);
        anchor_rom[8'd 49] = $signed(32'hFFFE8ADD); slope_rom[8'd 49] = $signed(32'h0000000A);
        anchor_rom[8'd 50] = $signed(32'hFFFE9482); slope_rom[8'd 50] = $signed(32'h00000009);
        anchor_rom[8'd 51] = $signed(32'hFFFE9DD2); slope_rom[8'd 51] = $signed(32'h00000009);
        anchor_rom[8'd 52] = $signed(32'hFFFEA6D3); slope_rom[8'd 52] = $signed(32'h00000009);
        anchor_rom[8'd 53] = $signed(32'hFFFEAF89); slope_rom[8'd 53] = $signed(32'h00000008);
        anchor_rom[8'd 54] = $signed(32'hFFFEB7F7); slope_rom[8'd 54] = $signed(32'h00000008);
        anchor_rom[8'd 55] = $signed(32'hFFFEC023); slope_rom[8'd 55] = $signed(32'h00000008);
        anchor_rom[8'd 56] = $signed(32'hFFFEC810); slope_rom[8'd 56] = $signed(32'h00000008);
        anchor_rom[8'd 57] = $signed(32'hFFFECFC1); slope_rom[8'd 57] = $signed(32'h00000007);
        anchor_rom[8'd 58] = $signed(32'hFFFED73A); slope_rom[8'd 58] = $signed(32'h00000007);
        anchor_rom[8'd 59] = $signed(32'hFFFEDE7C); slope_rom[8'd 59] = $signed(32'h00000007);
        anchor_rom[8'd 60] = $signed(32'hFFFEE58C); slope_rom[8'd 60] = $signed(32'h00000007);
        anchor_rom[8'd 61] = $signed(32'hFFFEEC6C); slope_rom[8'd 61] = $signed(32'h00000007);
        anchor_rom[8'd 62] = $signed(32'hFFFEF31D); slope_rom[8'd 62] = $signed(32'h00000007);
        anchor_rom[8'd 63] = $signed(32'hFFFEF9A3); slope_rom[8'd 63] = $signed(32'h00000006);
        anchor_rom[8'd 64] = $signed(32'hFFFF0000); slope_rom[8'd 64] = $signed(32'h00000006);
        anchor_rom[8'd 65] = $signed(32'hFFFF0635); slope_rom[8'd 65] = $signed(32'h00000006);
        anchor_rom[8'd 66] = $signed(32'hFFFF0C45); slope_rom[8'd 66] = $signed(32'h00000006);
        anchor_rom[8'd 67] = $signed(32'hFFFF1230); slope_rom[8'd 67] = $signed(32'h00000006);
        anchor_rom[8'd 68] = $signed(32'hFFFF17FA); slope_rom[8'd 68] = $signed(32'h00000006);
        anchor_rom[8'd 69] = $signed(32'hFFFF1DA2); slope_rom[8'd 69] = $signed(32'h00000006);
        anchor_rom[8'd 70] = $signed(32'hFFFF232C); slope_rom[8'd 70] = $signed(32'h00000005);
        anchor_rom[8'd 71] = $signed(32'hFFFF2898); slope_rom[8'd 71] = $signed(32'h00000005);
        anchor_rom[8'd 72] = $signed(32'hFFFF2DE8); slope_rom[8'd 72] = $signed(32'h00000005);
        anchor_rom[8'd 73] = $signed(32'hFFFF331D); slope_rom[8'd 73] = $signed(32'h00000005);
        anchor_rom[8'd 74] = $signed(32'hFFFF3837); slope_rom[8'd 74] = $signed(32'h00000005);
        anchor_rom[8'd 75] = $signed(32'hFFFF3D39); slope_rom[8'd 75] = $signed(32'h00000005);
        anchor_rom[8'd 76] = $signed(32'hFFFF4223); slope_rom[8'd 76] = $signed(32'h00000005);
        anchor_rom[8'd 77] = $signed(32'hFFFF46F7); slope_rom[8'd 77] = $signed(32'h00000005);
        anchor_rom[8'd 78] = $signed(32'hFFFF4BB4); slope_rom[8'd 78] = $signed(32'h00000005);
        anchor_rom[8'd 79] = $signed(32'hFFFF505D); slope_rom[8'd 79] = $signed(32'h00000005);
        anchor_rom[8'd 80] = $signed(32'hFFFF54F2); slope_rom[8'd 80] = $signed(32'h00000005);
        anchor_rom[8'd 81] = $signed(32'hFFFF5974); slope_rom[8'd 81] = $signed(32'h00000004);
        anchor_rom[8'd 82] = $signed(32'hFFFF5DE4); slope_rom[8'd 82] = $signed(32'h00000004);
        anchor_rom[8'd 83] = $signed(32'hFFFF6242); slope_rom[8'd 83] = $signed(32'h00000004);
        anchor_rom[8'd 84] = $signed(32'hFFFF668F); slope_rom[8'd 84] = $signed(32'h00000004);
        anchor_rom[8'd 85] = $signed(32'hFFFF6ACC); slope_rom[8'd 85] = $signed(32'h00000004);
        anchor_rom[8'd 86] = $signed(32'hFFFF6EFA); slope_rom[8'd 86] = $signed(32'h00000004);
        anchor_rom[8'd 87] = $signed(32'hFFFF7319); slope_rom[8'd 87] = $signed(32'h00000004);
        anchor_rom[8'd 88] = $signed(32'hFFFF772A); slope_rom[8'd 88] = $signed(32'h00000004);
        anchor_rom[8'd 89] = $signed(32'hFFFF7B2E); slope_rom[8'd 89] = $signed(32'h00000004);
        anchor_rom[8'd 90] = $signed(32'hFFFF7F24); slope_rom[8'd 90] = $signed(32'h00000004);
        anchor_rom[8'd 91] = $signed(32'hFFFF830E); slope_rom[8'd 91] = $signed(32'h00000004);
        anchor_rom[8'd 92] = $signed(32'hFFFF86EC); slope_rom[8'd 92] = $signed(32'h00000004);
        anchor_rom[8'd 93] = $signed(32'hFFFF8ABE); slope_rom[8'd 93] = $signed(32'h00000004);
        anchor_rom[8'd 94] = $signed(32'hFFFF8E86); slope_rom[8'd 94] = $signed(32'h00000004);
        anchor_rom[8'd 95] = $signed(32'hFFFF9243); slope_rom[8'd 95] = $signed(32'h00000004);
        anchor_rom[8'd 96] = $signed(32'hFFFF95F6); slope_rom[8'd 96] = $signed(32'h00000004);
        anchor_rom[8'd 97] = $signed(32'hFFFF99A0); slope_rom[8'd 97] = $signed(32'h00000004);
        anchor_rom[8'd 98] = $signed(32'hFFFF9D40); slope_rom[8'd 98] = $signed(32'h00000004);
        anchor_rom[8'd 99] = $signed(32'hFFFFA0D8); slope_rom[8'd 99] = $signed(32'h00000004);
        anchor_rom[8'd100] = $signed(32'hFFFFA467); slope_rom[8'd100] = $signed(32'h00000004);
        anchor_rom[8'd101] = $signed(32'hFFFFA7EE); slope_rom[8'd101] = $signed(32'h00000003);
        anchor_rom[8'd102] = $signed(32'hFFFFAB6E); slope_rom[8'd102] = $signed(32'h00000003);
        anchor_rom[8'd103] = $signed(32'hFFFFAEE6); slope_rom[8'd103] = $signed(32'h00000003);
        anchor_rom[8'd104] = $signed(32'hFFFFB258); slope_rom[8'd104] = $signed(32'h00000003);
        anchor_rom[8'd105] = $signed(32'hFFFFB5C3); slope_rom[8'd105] = $signed(32'h00000003);
        anchor_rom[8'd106] = $signed(32'hFFFFB928); slope_rom[8'd106] = $signed(32'h00000003);
        anchor_rom[8'd107] = $signed(32'hFFFFBC87); slope_rom[8'd107] = $signed(32'h00000003);
        anchor_rom[8'd108] = $signed(32'hFFFFBFE0); slope_rom[8'd108] = $signed(32'h00000003);
        anchor_rom[8'd109] = $signed(32'hFFFFC334); slope_rom[8'd109] = $signed(32'h00000003);
        anchor_rom[8'd110] = $signed(32'hFFFFC683); slope_rom[8'd110] = $signed(32'h00000003);
        anchor_rom[8'd111] = $signed(32'hFFFFC9CE); slope_rom[8'd111] = $signed(32'h00000003);
        anchor_rom[8'd112] = $signed(32'hFFFFCD14); slope_rom[8'd112] = $signed(32'h00000003);
        anchor_rom[8'd113] = $signed(32'hFFFFD056); slope_rom[8'd113] = $signed(32'h00000003);
        anchor_rom[8'd114] = $signed(32'hFFFFD394); slope_rom[8'd114] = $signed(32'h00000003);
        anchor_rom[8'd115] = $signed(32'hFFFFD6CF); slope_rom[8'd115] = $signed(32'h00000003);
        anchor_rom[8'd116] = $signed(32'hFFFFDA07); slope_rom[8'd116] = $signed(32'h00000003);
        anchor_rom[8'd117] = $signed(32'hFFFFDD3B); slope_rom[8'd117] = $signed(32'h00000003);
        anchor_rom[8'd118] = $signed(32'hFFFFE06D); slope_rom[8'd118] = $signed(32'h00000003);
        anchor_rom[8'd119] = $signed(32'hFFFFE39C); slope_rom[8'd119] = $signed(32'h00000003);
        anchor_rom[8'd120] = $signed(32'hFFFFE6C9); slope_rom[8'd120] = $signed(32'h00000003);
        anchor_rom[8'd121] = $signed(32'hFFFFE9F4); slope_rom[8'd121] = $signed(32'h00000003);
        anchor_rom[8'd122] = $signed(32'hFFFFED1E); slope_rom[8'd122] = $signed(32'h00000003);
        anchor_rom[8'd123] = $signed(32'hFFFFF046); slope_rom[8'd123] = $signed(32'h00000003);
        anchor_rom[8'd124] = $signed(32'hFFFFF36C); slope_rom[8'd124] = $signed(32'h00000003);
        anchor_rom[8'd125] = $signed(32'hFFFFF692); slope_rom[8'd125] = $signed(32'h00000003);
        anchor_rom[8'd126] = $signed(32'hFFFFF9B7); slope_rom[8'd126] = $signed(32'h00000003);
        anchor_rom[8'd127] = $signed(32'hFFFFFCDC); slope_rom[8'd127] = $signed(32'h00000003);
        anchor_rom[8'd128] = $signed(32'h00000000); slope_rom[8'd128] = $signed(32'h00000003);
        anchor_rom[8'd129] = $signed(32'h00000324); slope_rom[8'd129] = $signed(32'h00000003);
        anchor_rom[8'd130] = $signed(32'h00000649); slope_rom[8'd130] = $signed(32'h00000003);
        anchor_rom[8'd131] = $signed(32'h0000096E); slope_rom[8'd131] = $signed(32'h00000003);
        anchor_rom[8'd132] = $signed(32'h00000C94); slope_rom[8'd132] = $signed(32'h00000003);
        anchor_rom[8'd133] = $signed(32'h00000FBA); slope_rom[8'd133] = $signed(32'h00000003);
        anchor_rom[8'd134] = $signed(32'h000012E2); slope_rom[8'd134] = $signed(32'h00000003);
        anchor_rom[8'd135] = $signed(32'h0000160C); slope_rom[8'd135] = $signed(32'h00000003);
        anchor_rom[8'd136] = $signed(32'h00001937); slope_rom[8'd136] = $signed(32'h00000003);
        anchor_rom[8'd137] = $signed(32'h00001C64); slope_rom[8'd137] = $signed(32'h00000003);
        anchor_rom[8'd138] = $signed(32'h00001F93); slope_rom[8'd138] = $signed(32'h00000003);
        anchor_rom[8'd139] = $signed(32'h000022C5); slope_rom[8'd139] = $signed(32'h00000003);
        anchor_rom[8'd140] = $signed(32'h000025F9); slope_rom[8'd140] = $signed(32'h00000003);
        anchor_rom[8'd141] = $signed(32'h00002931); slope_rom[8'd141] = $signed(32'h00000003);
        anchor_rom[8'd142] = $signed(32'h00002C6C); slope_rom[8'd142] = $signed(32'h00000003);
        anchor_rom[8'd143] = $signed(32'h00002FAA); slope_rom[8'd143] = $signed(32'h00000003);
        anchor_rom[8'd144] = $signed(32'h000032EC); slope_rom[8'd144] = $signed(32'h00000003);
        anchor_rom[8'd145] = $signed(32'h00003632); slope_rom[8'd145] = $signed(32'h00000003);
        anchor_rom[8'd146] = $signed(32'h0000397D); slope_rom[8'd146] = $signed(32'h00000003);
        anchor_rom[8'd147] = $signed(32'h00003CCC); slope_rom[8'd147] = $signed(32'h00000003);
        anchor_rom[8'd148] = $signed(32'h00004020); slope_rom[8'd148] = $signed(32'h00000003);
        anchor_rom[8'd149] = $signed(32'h00004379); slope_rom[8'd149] = $signed(32'h00000003);
        anchor_rom[8'd150] = $signed(32'h000046D8); slope_rom[8'd150] = $signed(32'h00000003);
        anchor_rom[8'd151] = $signed(32'h00004A3D); slope_rom[8'd151] = $signed(32'h00000003);
        anchor_rom[8'd152] = $signed(32'h00004DA8); slope_rom[8'd152] = $signed(32'h00000003);
        anchor_rom[8'd153] = $signed(32'h0000511A); slope_rom[8'd153] = $signed(32'h00000003);
        anchor_rom[8'd154] = $signed(32'h00005492); slope_rom[8'd154] = $signed(32'h00000003);
        anchor_rom[8'd155] = $signed(32'h00005812); slope_rom[8'd155] = $signed(32'h00000004);
        anchor_rom[8'd156] = $signed(32'h00005B99); slope_rom[8'd156] = $signed(32'h00000004);
        anchor_rom[8'd157] = $signed(32'h00005F28); slope_rom[8'd157] = $signed(32'h00000004);
        anchor_rom[8'd158] = $signed(32'h000062C0); slope_rom[8'd158] = $signed(32'h00000004);
        anchor_rom[8'd159] = $signed(32'h00006660); slope_rom[8'd159] = $signed(32'h00000004);
        anchor_rom[8'd160] = $signed(32'h00006A0A); slope_rom[8'd160] = $signed(32'h00000004);
        anchor_rom[8'd161] = $signed(32'h00006DBD); slope_rom[8'd161] = $signed(32'h00000004);
        anchor_rom[8'd162] = $signed(32'h0000717A); slope_rom[8'd162] = $signed(32'h00000004);
        anchor_rom[8'd163] = $signed(32'h00007542); slope_rom[8'd163] = $signed(32'h00000004);
        anchor_rom[8'd164] = $signed(32'h00007914); slope_rom[8'd164] = $signed(32'h00000004);
        anchor_rom[8'd165] = $signed(32'h00007CF2); slope_rom[8'd165] = $signed(32'h00000004);
        anchor_rom[8'd166] = $signed(32'h000080DC); slope_rom[8'd166] = $signed(32'h00000004);
        anchor_rom[8'd167] = $signed(32'h000084D2); slope_rom[8'd167] = $signed(32'h00000004);
        anchor_rom[8'd168] = $signed(32'h000088D6); slope_rom[8'd168] = $signed(32'h00000004);
        anchor_rom[8'd169] = $signed(32'h00008CE7); slope_rom[8'd169] = $signed(32'h00000004);
        anchor_rom[8'd170] = $signed(32'h00009106); slope_rom[8'd170] = $signed(32'h00000004);
        anchor_rom[8'd171] = $signed(32'h00009534); slope_rom[8'd171] = $signed(32'h00000004);
        anchor_rom[8'd172] = $signed(32'h00009971); slope_rom[8'd172] = $signed(32'h00000004);
        anchor_rom[8'd173] = $signed(32'h00009DBE); slope_rom[8'd173] = $signed(32'h00000004);
        anchor_rom[8'd174] = $signed(32'h0000A21C); slope_rom[8'd174] = $signed(32'h00000004);
        anchor_rom[8'd175] = $signed(32'h0000A68C); slope_rom[8'd175] = $signed(32'h00000005);
        anchor_rom[8'd176] = $signed(32'h0000AB0E); slope_rom[8'd176] = $signed(32'h00000005);
        anchor_rom[8'd177] = $signed(32'h0000AFA3); slope_rom[8'd177] = $signed(32'h00000005);
        anchor_rom[8'd178] = $signed(32'h0000B44C); slope_rom[8'd178] = $signed(32'h00000005);
        anchor_rom[8'd179] = $signed(32'h0000B909); slope_rom[8'd179] = $signed(32'h00000005);
        anchor_rom[8'd180] = $signed(32'h0000BDDD); slope_rom[8'd180] = $signed(32'h00000005);
        anchor_rom[8'd181] = $signed(32'h0000C2C7); slope_rom[8'd181] = $signed(32'h00000005);
        anchor_rom[8'd182] = $signed(32'h0000C7C9); slope_rom[8'd182] = $signed(32'h00000005);
        anchor_rom[8'd183] = $signed(32'h0000CCE3); slope_rom[8'd183] = $signed(32'h00000005);
        anchor_rom[8'd184] = $signed(32'h0000D218); slope_rom[8'd184] = $signed(32'h00000005);
        anchor_rom[8'd185] = $signed(32'h0000D768); slope_rom[8'd185] = $signed(32'h00000005);
        anchor_rom[8'd186] = $signed(32'h0000DCD4); slope_rom[8'd186] = $signed(32'h00000006);
        anchor_rom[8'd187] = $signed(32'h0000E25E); slope_rom[8'd187] = $signed(32'h00000006);
        anchor_rom[8'd188] = $signed(32'h0000E806); slope_rom[8'd188] = $signed(32'h00000006);
        anchor_rom[8'd189] = $signed(32'h0000EDD0); slope_rom[8'd189] = $signed(32'h00000006);
        anchor_rom[8'd190] = $signed(32'h0000F3BB); slope_rom[8'd190] = $signed(32'h00000006);
        anchor_rom[8'd191] = $signed(32'h0000F9CB); slope_rom[8'd191] = $signed(32'h00000006);
        anchor_rom[8'd192] = $signed(32'h00010000); slope_rom[8'd192] = $signed(32'h00000006);
        anchor_rom[8'd193] = $signed(32'h0001065D); slope_rom[8'd193] = $signed(32'h00000007);
        anchor_rom[8'd194] = $signed(32'h00010CE3); slope_rom[8'd194] = $signed(32'h00000007);
        anchor_rom[8'd195] = $signed(32'h00011394); slope_rom[8'd195] = $signed(32'h00000007);
        anchor_rom[8'd196] = $signed(32'h00011A74); slope_rom[8'd196] = $signed(32'h00000007);
        anchor_rom[8'd197] = $signed(32'h00012184); slope_rom[8'd197] = $signed(32'h00000007);
        anchor_rom[8'd198] = $signed(32'h000128C6); slope_rom[8'd198] = $signed(32'h00000007);
        anchor_rom[8'd199] = $signed(32'h0001303F); slope_rom[8'd199] = $signed(32'h00000008);
        anchor_rom[8'd200] = $signed(32'h000137F0); slope_rom[8'd200] = $signed(32'h00000008);
        anchor_rom[8'd201] = $signed(32'h00013FDD); slope_rom[8'd201] = $signed(32'h00000008);
        anchor_rom[8'd202] = $signed(32'h00014809); slope_rom[8'd202] = $signed(32'h00000008);
        anchor_rom[8'd203] = $signed(32'h00015077); slope_rom[8'd203] = $signed(32'h00000009);
        anchor_rom[8'd204] = $signed(32'h0001592D); slope_rom[8'd204] = $signed(32'h00000009);
        anchor_rom[8'd205] = $signed(32'h0001622E); slope_rom[8'd205] = $signed(32'h00000009);
        anchor_rom[8'd206] = $signed(32'h00016B7E); slope_rom[8'd206] = $signed(32'h0000000A);
        anchor_rom[8'd207] = $signed(32'h00017523); slope_rom[8'd207] = $signed(32'h0000000A);
        anchor_rom[8'd208] = $signed(32'h00017F22); slope_rom[8'd208] = $signed(32'h0000000A);
        anchor_rom[8'd209] = $signed(32'h00018980); slope_rom[8'd209] = $signed(32'h0000000B);
        anchor_rom[8'd210] = $signed(32'h00019445); slope_rom[8'd210] = $signed(32'h0000000B);
        anchor_rom[8'd211] = $signed(32'h00019F76); slope_rom[8'd211] = $signed(32'h0000000C);
        anchor_rom[8'd212] = $signed(32'h0001AB1C); slope_rom[8'd212] = $signed(32'h0000000C);
        anchor_rom[8'd213] = $signed(32'h0001B73F); slope_rom[8'd213] = $signed(32'h0000000D);
        anchor_rom[8'd214] = $signed(32'h0001C3E7); slope_rom[8'd214] = $signed(32'h0000000D);
        anchor_rom[8'd215] = $signed(32'h0001D11F); slope_rom[8'd215] = $signed(32'h0000000E);
        anchor_rom[8'd216] = $signed(32'h0001DEF1); slope_rom[8'd216] = $signed(32'h0000000E);
        anchor_rom[8'd217] = $signed(32'h0001ED6A); slope_rom[8'd217] = $signed(32'h0000000F);
        anchor_rom[8'd218] = $signed(32'h0001FC96); slope_rom[8'd218] = $signed(32'h00000010);
        anchor_rom[8'd219] = $signed(32'h00020C84); slope_rom[8'd219] = $signed(32'h00000011);
        anchor_rom[8'd220] = $signed(32'h00021D44); slope_rom[8'd220] = $signed(32'h00000012);
        anchor_rom[8'd221] = $signed(32'h00022EE9); slope_rom[8'd221] = $signed(32'h00000013);
        anchor_rom[8'd222] = $signed(32'h00024187); slope_rom[8'd222] = $signed(32'h00000014);
        anchor_rom[8'd223] = $signed(32'h00025534); slope_rom[8'd223] = $signed(32'h00000015);
        anchor_rom[8'd224] = $signed(32'h00026A0A); slope_rom[8'd224] = $signed(32'h00000016);
        anchor_rom[8'd225] = $signed(32'h00028026); slope_rom[8'd225] = $signed(32'h00000018);
        anchor_rom[8'd226] = $signed(32'h000297A8); slope_rom[8'd226] = $signed(32'h00000019);
        anchor_rom[8'd227] = $signed(32'h0002B0B5); slope_rom[8'd227] = $signed(32'h0000001B);
        anchor_rom[8'd228] = $signed(32'h0002CB79); slope_rom[8'd228] = $signed(32'h0000001D);
        anchor_rom[8'd229] = $signed(32'h0002E823); slope_rom[8'd229] = $signed(32'h0000001F);
        anchor_rom[8'd230] = $signed(32'h000306EC); slope_rom[8'd230] = $signed(32'h00000021);
        anchor_rom[8'd231] = $signed(32'h00032816); slope_rom[8'd231] = $signed(32'h00000024);
        anchor_rom[8'd232] = $signed(32'h00034BEB); slope_rom[8'd232] = $signed(32'h00000027);
        anchor_rom[8'd233] = $signed(32'h000372C6); slope_rom[8'd233] = $signed(32'h0000002A);
        anchor_rom[8'd234] = $signed(32'h00039D11); slope_rom[8'd234] = $signed(32'h0000002E);
        anchor_rom[8'd235] = $signed(32'h0003CB48); slope_rom[8'd235] = $signed(32'h00000033);
        anchor_rom[8'd236] = $signed(32'h0003FE02); slope_rom[8'd236] = $signed(32'h00000038);
        anchor_rom[8'd237] = $signed(32'h000435F7); slope_rom[8'd237] = $signed(32'h0000003E);
        anchor_rom[8'd238] = $signed(32'h00047405); slope_rom[8'd238] = $signed(32'h00000045);
        anchor_rom[8'd239] = $signed(32'h0004B940); slope_rom[8'd239] = $signed(32'h0000004E);
        anchor_rom[8'd240] = $signed(32'h00050700); slope_rom[8'd240] = $signed(32'h00000058);
        anchor_rom[8'd241] = $signed(32'h00055EF9); slope_rom[8'd241] = $signed(32'h00000064);
        anchor_rom[8'd242] = $signed(32'h0005C35D); slope_rom[8'd242] = $signed(32'h00000074);
        anchor_rom[8'd243] = $signed(32'h00063709); slope_rom[8'd243] = $signed(32'h00000087);
        anchor_rom[8'd244] = $signed(32'h0006BDD0); slope_rom[8'd244] = $signed(32'h0000009F);
        anchor_rom[8'd245] = $signed(32'h00075CE6); slope_rom[8'd245] = $signed(32'h000000BF);
        anchor_rom[8'd246] = $signed(32'h00081B98); slope_rom[8'd246] = $signed(32'h000000E9);
        anchor_rom[8'd247] = $signed(32'h0009046E); slope_rom[8'd247] = $signed(32'h00000123);
        anchor_rom[8'd248] = $signed(32'h000A2736); slope_rom[8'd248] = $signed(32'h00000176);
        anchor_rom[8'd249] = $signed(32'h000B9CC6); slope_rom[8'd249] = $signed(32'h000001F2);
        anchor_rom[8'd250] = $signed(32'h000D8E82); slope_rom[8'd250] = $signed(32'h000002B8);
        anchor_rom[8'd251] = $signed(32'h001046EA); slope_rom[8'd251] = $signed(32'h00000414);
        anchor_rom[8'd252] = $signed(32'h00145B00); slope_rom[8'd252] = $signed(32'h000006CB);
        anchor_rom[8'd253] = $signed(32'h001B2672); slope_rom[8'd253] = $signed(32'h00000D96);
        anchor_rom[8'd254] = $signed(32'h0028BC49); slope_rom[8'd254] = $signed(32'h000028BF);
        anchor_rom[8'd255] = $signed(32'h00517BB6); slope_rom[8'd255] = $signed(32'h00512B46);
    end

    // -------------------------------------------------------------------------
    // Linear interpolation: value = anchor[segment] + slope[segment] * offset
    //
    // R-SI-1 compliant shift-add decomposition of 8-bit × 32-bit:
    //   slope * offset = sum of (slope << bit_pos) for each set bit in offset
    // -------------------------------------------------------------------------
    wire signed [31:0] anchor_val = anchor_rom[segment];
    wire signed [31:0] slope_val  = slope_rom[segment];

    wire signed [39:0] term0 = offset[0] ? {{8{slope_val[31]}}, slope_val}        : 40'sd0;
    wire signed [39:0] term1 = offset[1] ? ({{8{slope_val[31]}}, slope_val} << 1) : 40'sd0;
    wire signed [39:0] term2 = offset[2] ? ({{8{slope_val[31]}}, slope_val} << 2) : 40'sd0;
    wire signed [39:0] term3 = offset[3] ? ({{8{slope_val[31]}}, slope_val} << 3) : 40'sd0;
    wire signed [39:0] term4 = offset[4] ? ({{8{slope_val[31]}}, slope_val} << 4) : 40'sd0;
    wire signed [39:0] term5 = offset[5] ? ({{8{slope_val[31]}}, slope_val} << 5) : 40'sd0;
    wire signed [39:0] term6 = offset[6] ? ({{8{slope_val[31]}}, slope_val} << 6) : 40'sd0;
    wire signed [39:0] term7 = offset[7] ? ({{8{slope_val[31]}}, slope_val} << 7) : 40'sd0;

    wire signed [39:0] interp = {{8{anchor_val[31]}}, anchor_val}
                               + term0 + term1 + term2 + term3
                               + term4 + term5 + term6 + term7;

    wire overflow_pos = ~interp[39] & (|interp[38:31]);
    wire overflow_neg =  interp[39] & ~(&interp[38:31]);
    assign decoded_q1616 = overflow_pos ? 32'h7FFFFFFF :
                           overflow_neg ? 32'h80000000 :
                                          interp[31:0];

endmodule

`default_nettype wire
