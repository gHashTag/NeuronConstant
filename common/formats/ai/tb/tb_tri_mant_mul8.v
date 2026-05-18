// tb_tri_mant_mul8.v — Testbench for tri_mant_mul8 (8x8 → 16-bit)
`timescale 1ns/1ps
`default_nettype none

module tb_tri_mant_mul8;

    reg  [7:0]  a, b;
    wire [15:0] result;
    integer     fail_count;

    tri_mant_mul8 dut (.a(a), .b(b), .result(result));

    task check;
        input [7:0]  ta, tb_v;
        input [15:0] expected;
        begin
            a = ta; b = tb_v;
            #1;
            if (result !== expected) begin
                $display("FAIL: %0d*%0d expected=%0d got=%0d", ta, tb_v, expected, result);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // 0xFF * 0xFF = 65025 = 0xFE01
        check(8'hFF, 8'hFF, 16'hFE01);
        // 0x80 * 0x02 = 256 = 0x0100
        check(8'h80, 8'h02, 16'h0100);
        // 0x10 * 0x10 = 256 = 0x0100
        check(8'h10, 8'h10, 16'h0100);
        // 1 * 1 = 1
        check(8'h01, 8'h01, 16'h0001);
        // 0x0F * 0x0F = 225 = 0x00E1
        check(8'h0F, 8'h0F, 16'h00E1);
        // 0x00 * 0xFF = 0
        check(8'h00, 8'hFF, 16'h0000);
        // 0x7F * 0x02 = 254
        check(8'h7F, 8'h02, 16'h00FE);
        // 0x80 * 0x80 = 16384 = 0x4000
        check(8'h80, 8'h80, 16'h4000);
        // 0xAB * 0x03 = 513 = 0x0201
        check(8'hAB, 8'h03, 16'h0201);

        if (fail_count == 0)
            $display("PASS");
        else
            $display("FAIL (%0d errors)", fail_count);

        $finish;
    end

endmodule
`default_nettype wire
