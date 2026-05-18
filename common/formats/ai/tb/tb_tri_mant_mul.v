// tb_tri_mant_mul.v — Testbench for tri_mant_mul (4x4 → 8-bit)
`timescale 1ns/1ps
`default_nettype none

module tb_tri_mant_mul;

    reg  [3:0] a, b;
    wire [7:0] result;
    integer    fail_count;

    tri_mant_mul dut (.a(a), .b(b), .result(result));

    task check;
        input [3:0] ta, tb_v;
        input [7:0] expected;
        input [63:0] label;
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

        // 0xF * 0xF = 0xE1 = 225
        check(4'hF, 4'hF, 8'hE1, "F*F");
        // 0x5 * 0x3 = 15 = 0x0F
        check(4'h5, 4'h3, 8'h0F, "5*3");
        // 0x8 * 0x2 = 16 = 0x10
        check(4'h8, 4'h2, 8'h10, "8*2");
        // 0x1 * 0x1 = 1
        check(4'h1, 4'h1, 8'h01, "1*1");
        // 0xA * 0x6 = 60 = 0x3C
        check(4'hA, 4'h6, 8'h3C, "A*6");
        // 0x0 * 0xF = 0
        check(4'h0, 4'hF, 8'h00, "0*F");
        // 0xF * 0x0 = 0
        check(4'hF, 4'h0, 8'h00, "F*0");
        // 0x4 * 0x4 = 16 = 0x10
        check(4'h4, 4'h4, 8'h10, "4*4");

        if (fail_count == 0)
            $display("PASS");
        else
            $display("FAIL (%0d errors)", fail_count);

        $finish;
    end

endmodule
`default_nettype wire
