// SPDX-License-Identifier: MIT
// Testbench: Q0.31 fixed-point
// Tests: 0.5 * 0.5 = 0.25 in Q0.31
`timescale 1ns/1ps
`default_nettype none

module tb_q31;
    integer errors;

    reg  [31:0] a_q31, b_q31;
    wire [31:0] mul_out;
    wire [31:0] add_out;

    q31_mul u_mul (
        .a_q31     (a_q31),
        .b_q31     (b_q31),
        .result_q31(mul_out)
    );

    q31_add u_add (
        .a_q31     (a_q31),
        .b_q31     (b_q31),
        .result_q31(add_out)
    );

    task check32;
        input [127:0] name;
        input [31:0] got;
        input [31:0] expected;
        input [31:0] tol;
        begin
            if (got >= expected - tol && got <= expected + tol) begin
                $display("  PASS %0s: got=0x%08x exp=0x%08x", name, got, expected);
            end else begin
                $display("  FAIL %0s: got=0x%08x exp=0x%08x", name, got, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        $display("=== TB Q31 ===");

        // Q0.31: 0.5 = 0x40000000
        // 0.5 * 0.5 = 0.25 = 0x20000000
        a_q31 = 32'h40000000; // 0.5
        b_q31 = 32'h40000000; // 0.5
        #10;
        check32("q31_0.5x0.5=0.25", mul_out, 32'h20000000, 32'h00100000);

        // 0.5 + 0.5 = 1.0 (max representable ~1.0 - epsilon)
        // Result should saturate to 0x7FFFFFFF
        #10;
        check32("q31_0.5+0.5=sat", add_out, 32'h7FFFFFFF, 32'h00000001);

        // -0.5 * -0.5 = 0.25
        a_q31 = 32'hC0000000; // -0.5
        b_q31 = 32'hC0000000;
        #10;
        check32("q31_-0.5x-0.5=0.25", mul_out, 32'h20000000, 32'h00100000);

        // 0.5 * -0.5 = -0.25
        a_q31 = 32'h40000000;
        b_q31 = 32'hC0000000;
        #10;
        check32("q31_0.5x-0.5=-0.25", mul_out, 32'hE0000000, 32'h00100000);

        // 0 * 0.5 = 0
        a_q31 = 32'h00000000;
        b_q31 = 32'h40000000;
        #10;
        check32("q31_0x0.5=0", mul_out, 32'h00000000, 32'h00000000);

        // Saturation test
        a_q31 = 32'h7FFFFFFF;
        b_q31 = 32'h00000001;
        #10;
        check32("q31_add_sat", add_out, 32'h7FFFFFFF, 32'h00000000);

        // -1 * -1 saturate to max positive
        a_q31 = 32'h80000000;
        b_q31 = 32'h80000000;
        #10;
        check32("q31_-1x-1_sat", mul_out, 32'h7FFFFFFF, 32'h00000000);

        if (errors == 0)
            $display("PASS: tb_q31 all checks passed");
        else
            $display("FAIL: tb_q31 %0d errors", errors);

        $finish;
    end
endmodule
`default_nettype wire
