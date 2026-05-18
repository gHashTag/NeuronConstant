// tb_bf16_mul.v — bfloat16 multiplier known values
// bfloat16: 1s + 8e + 7m, bias=127
// Key encodings:
//   1.0 = 0x3F80 (sign=0, exp=127, mant=0)
//   2.0 = 0x4000 (sign=0, exp=128, mant=0)
//   0.5 = 0x3F00 (sign=0, exp=126, mant=0)
//  -1.0 = 0xBF80
//   NaN = 0x7FC0 (exp=0xFF, mant≠0)
//   Inf = 0x7F80 (exp=0xFF, mant=0)
//   0   = 0x0000
`timescale 1ns/1ps
`default_nettype none

module tb_bf16_mul;

    reg  [15:0] a, b;
    wire [15:0] result;
    integer     fail_count;

    bf16_mul dut (.a(a), .b(b), .result(result));

    initial begin
        fail_count = 0;

        // 1.0 * 1.0 = 1.0
        a = 16'h3F80; b = 16'h3F80; #1;
        if (result !== 16'h3F80) begin
            $display("FAIL 1.0*1.0: expected 0x3F80 got 0x%04X", result);
            fail_count = fail_count + 1;
        end

        // 2.0 * 0.5 = 1.0
        a = 16'h4000; b = 16'h3F00; #1;
        if (result !== 16'h3F80) begin
            $display("FAIL 2.0*0.5: expected 0x3F80 got 0x%04X", result);
            fail_count = fail_count + 1;
        end

        // 1.0 * -1.0 = -1.0
        a = 16'h3F80; b = 16'hBF80; #1;
        if (result !== 16'hBF80) begin
            $display("FAIL 1*-1: expected 0xBF80 got 0x%04X", result);
            fail_count = fail_count + 1;
        end

        // 0 * 1.0 = 0
        a = 16'h0000; b = 16'h3F80; #1;
        if (result[14:0] !== 15'h0000) begin
            $display("FAIL 0*1: expected 0x0000 got 0x%04X", result);
            fail_count = fail_count + 1;
        end

        // Inf * 1.0 = Inf
        a = 16'h7F80; b = 16'h3F80; #1;
        if (result !== 16'h7F80) begin
            $display("FAIL Inf*1: expected 0x7F80 got 0x%04X", result);
            fail_count = fail_count + 1;
        end

        // NaN * 1.0 = NaN (exp=0xFF)
        a = 16'h7FC0; b = 16'h3F80; #1;
        if (result[14:7] !== 8'hFF) begin
            $display("FAIL NaN*1: expected NaN exp=FF got exp=0x%02X", result[14:7]);
            fail_count = fail_count + 1;
        end

        if (fail_count == 0)
            $display("PASS");
        else
            $display("FAIL (%0d errors)", fail_count);

        $finish;
    end

endmodule
`default_nettype wire
