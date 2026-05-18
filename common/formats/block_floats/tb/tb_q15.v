// SPDX-License-Identifier: MIT
// Testbench: Q0.15 fixed-point
// Tests: 0.5 * 0.5 = 0.25 in Q0.15
`timescale 1ns/1ps
`default_nettype none

module tb_q15;
    integer errors;

    reg  [15:0] a_q15, b_q15;
    wire [15:0] mul_out;
    wire [15:0] add_out;

    q15_mul u_mul (
        .a_q15     (a_q15),
        .b_q15     (b_q15),
        .result_q15(mul_out)
    );

    q15_add u_add (
        .a_q15     (a_q15),
        .b_q15     (b_q15),
        .result_q15(add_out)
    );

    task check16;
        input [127:0] name;
        input [15:0] got;
        input [15:0] expected;
        input [15:0] tol;
        begin
            if (got >= expected - tol && got <= expected + tol) begin
                $display("  PASS %0s: got=0x%04x exp=0x%04x", name, got, expected);
            end else begin
                $display("  FAIL %0s: got=0x%04x exp=0x%04x", name, got, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        $display("=== TB Q15 ===");

        // Q0.15: 1.0 is unrepresentable (max = 0x7FFF = 0.99997...)
        // 0.5 = 0x4000 (bit 14 = 2^-1)
        // 0.25 = 0x2000 (bit 13 = 2^-2)
        // 0.5 * 0.5 = 0.25 = 0x2000

        a_q15 = 16'h4000; // 0.5
        b_q15 = 16'h4000; // 0.5
        #10;
        check16("q15_0.5x0.5=0.25", mul_out, 16'h2000, 16'h0100);

        // 0.5 + 0.5 = 1.0 -> saturate to 0x7FFF
        #10;
        check16("q15_0.5+0.5=sat", add_out, 16'h7FFF, 16'h0001);

        // -0.5 * -0.5 = 0.25
        a_q15 = 16'hC000; // -0.5 = 0xC000 in Q0.15
        b_q15 = 16'hC000;
        #10;
        check16("q15_-0.5x-0.5=0.25", mul_out, 16'h2000, 16'h0100);

        // 0.5 * -0.5 = -0.25
        a_q15 = 16'h4000; // +0.5
        b_q15 = 16'hC000; // -0.5
        #10;
        check16("q15_0.5x-0.5=-0.25", mul_out, 16'hE000, 16'h0100);

        // 0 * anything = 0
        a_q15 = 16'h0000;
        b_q15 = 16'h4000;
        #10;
        check16("q15_0x0.5=0", mul_out, 16'h0000, 16'h0000);

        // Saturation test: add two positives that overflow
        a_q15 = 16'h7FFF;
        b_q15 = 16'h0001;
        #10;
        check16("q15_add_sat_pos", add_out, 16'h7FFF, 16'h0000);

        // Negative saturation
        a_q15 = 16'h8000;
        b_q15 = 16'hFFFF;
        #10;
        check16("q15_add_sat_neg", add_out, 16'h8000, 16'h0000);

        // -1 * -1 saturation test (special case)
        a_q15 = 16'h8000;
        b_q15 = 16'h8000;
        #10;
        check16("q15_-1x-1_sat", mul_out, 16'h7FFF, 16'h0000);

        // 0.25 * 0.5 = 0.125
        a_q15 = 16'h2000; // 0.25
        b_q15 = 16'h4000; // 0.5
        #10;
        check16("q15_0.25x0.5=0.125", mul_out, 16'h1000, 16'h0100);

        if (errors == 0)
            $display("PASS: tb_q15 all checks passed");
        else
            $display("FAIL: tb_q15 %0d errors", errors);

        $finish;
    end
endmodule
`default_nettype wire
