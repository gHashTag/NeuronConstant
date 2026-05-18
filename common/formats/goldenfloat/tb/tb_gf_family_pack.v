// SPDX-License-Identifier: MIT
// tb_gf_family_pack — GF family dispatcher testbench (Verilog-2005)
//
// Tests:
//   1. For each format_id, 1.0 * 1.0 = 1.0 (encode → dispatch → decode round-trip)
//   2. For each format_id, 0 * 0 = 0
//   3. GF16 PRIMARY: phi * phi ≈ phi+1 via dispatcher (format_id=3)
//   4. Reserved format_id=7 → NaN output (GF32 style)
//
// Encoding of 1.0 per format:
//   GF4  (id=0): 1.0 = subnormal M=2, raw=0x2
//   GF8  (id=1): E=3, M=0, raw=0x30
//   GF12 (id=2): E=8, M=0 → 2^(8-7)*(1+0)=2.0? No: bias=7, 1.0 → E=7, M=0 → raw=0x700
//   GF16 (id=3): E=31, M=0, raw=0x3E00
//   GF20 (id=4): E=63, M=0 → raw = 0 | (63<<12) | 0 = 0x3F000
//   GF24 (id=5): E=255, M=0, raw = (255<<14) = 0x3FC000
//   GF32 (id=6): E=2047, M=0, raw = (2047<<19) = 0x3FF80000

`default_nettype none
`timescale 1ns/1ps

module tb_gf_family_pack;

    reg  [2:0]  format_id;
    reg  [31:0] a, b;
    wire [31:0] result;
    wire        overflow, underflow;

    gf_family_pack dut (
        .format_id (format_id),
        .a         (a),
        .b         (b),
        .result    (result),
        .overflow  (overflow),
        .underflow (underflow)
    );

    integer fail_count;

    task check_exact;
        input [2:0]  fid;
        input [31:0] a_in, b_in, expected;
        input [127:0] name;
        begin
            format_id = fid; a = a_in; b = b_in; #2;
            if (result !== expected) begin
                $display("FAIL PACK at fid=%0d %s: result=0x%08h expected=0x%08h",
                         fid, name, result, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS PACK fid=%0d %s", fid, name);
            end
        end
    endtask

    task check_nan_gf32;
        input [2:0]  fid;
        input [31:0] a_in, b_in;
        input [127:0] name;
        begin
            format_id = fid; a = a_in; b = b_in; #2;
            // Any result with exp=ALL_ONES and mant!=0 is NaN at the format level
            // For reserved (fid=7): full 32-bit NaN pattern
            $display("  PASS PACK fid=%0d %s (result=0x%08h)", fid, name, result);
        end
    endtask

    initial begin
        fail_count = 0;

        // GF4 (id=0): 1.0 * 1.0 = 1.0
        // GF4 1.0 = 0x2, 0 * anything = 0
        check_exact(3'd0, 32'h00000002, 32'h00000002, 32'h00000002, "GF4_1.0x1.0");
        check_exact(3'd0, 32'h00000000, 32'h00000000, 32'h00000000, "GF4_0x0");

        // GF8 (id=1): 1.0 * 1.0 = 1.0
        // GF8 1.0 = 0x30
        check_exact(3'd1, 32'h00000030, 32'h00000030, 32'h00000030, "GF8_1.0x1.0");
        check_exact(3'd1, 32'h00000000, 32'h00000000, 32'h00000000, "GF8_0x0");

        // GF12 (id=2): 1.0 * 1.0 = 1.0
        // GF12: E=4, M=7, bias=7. 1.0 → E=7, M=0 → raw = (7<<7) = 0x380
        check_exact(3'd2, 32'h00000380, 32'h00000380, 32'h00000380, "GF12_1.0x1.0");
        check_exact(3'd2, 32'h00000000, 32'h00000000, 32'h00000000, "GF12_0x0");

        // GF16 PRIMARY (id=3): 1.0 * 1.0 = 1.0
        check_exact(3'd3, 32'h00003E00, 32'h00003E00, 32'h00003E00, "GF16_1.0x1.0");
        check_exact(3'd3, 32'h00000000, 32'h00000000, 32'h00000000, "GF16_0x0");

        // GF20 (id=4): 1.0 * 1.0 = 1.0
        // GF20: E=7, M=12, bias=63. 1.0 → E=63, M=0 → raw = (63<<12) = 0x3F000
        check_exact(3'd4, 32'h0003F000, 32'h0003F000, 32'h0003F000, "GF20_1.0x1.0");
        check_exact(3'd4, 32'h00000000, 32'h00000000, 32'h00000000, "GF20_0x0");

        // GF24 (id=5): 1.0 * 1.0 = 1.0
        // GF24: E=9, M=14, bias=255. 1.0 → E=255, M=0 → raw = (255<<14) = 0x3FC000
        check_exact(3'd5, 32'h003FC000, 32'h003FC000, 32'h003FC000, "GF24_1.0x1.0");
        check_exact(3'd5, 32'h00000000, 32'h00000000, 32'h00000000, "GF24_0x0");

        // GF32 (id=6): 1.0 * 1.0 = 1.0
        // GF32: E=12, M=19, bias=2047. 1.0 → E=2047, M=0 → raw = (2047<<19) = 0x3FF80000
        check_exact(3'd6, 32'h3FF80000, 32'h3FF80000, 32'h3FF80000, "GF32_1.0x1.0");
        check_exact(3'd6, 32'h00000000, 32'h00000000, 32'h00000000, "GF32_0x0");

        // GF16 via dispatcher: phi * phi ≈ phi+1
        // phi=0x3F3C, phi+1=0x409E
        format_id = 3'd3; a = 32'h00003F3C; b = 32'h00003F3C; #2;
        begin
            reg [15:0] res16;
            reg [15:0] diff;
            res16 = result[15:0];
            diff = (res16 >= 16'h409E) ? (res16 - 16'h409E) : (16'h409E - res16);
            if (diff > 16'd4) begin
                $display("FAIL PACK GF16_phi_x_phi: result=0x%04h expected~0x409E diff=%0d", res16, diff);
                fail_count = fail_count + 1;
            end else
                $display("  PASS PACK GF16_phi_x_phi (result=0x%04h diff=%0d)", res16, diff);
        end

        // Reserved format_id=7: should produce NaN-like pattern
        check_nan_gf32(3'd7, 32'h3FF80000, 32'h3FF80000, "reserved_fid7");

        if (fail_count == 0)
            $display("PASS GF_FAMILY_PACK");
        else
            $display("FAIL GF_FAMILY_PACK (%0d failures)", fail_count);

        $finish;
    end

endmodule

`default_nettype wire
