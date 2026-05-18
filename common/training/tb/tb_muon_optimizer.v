// SPDX-License-Identifier: MIT
// tb_muon_optimizer.v — Testbench for muon_optimizer
//
// Test: apply synthetic gradient, verify orthogonalized output is produced.
// PASS criteria: done asserted, output finite and non-zero.

`default_nettype none
`timescale 1ns/1ps

module tb_muon_optimizer;

    reg clk, rst_n, step;
    reg  [15:0] g0, g1, g2, g3, g4, g5, g6, g7, g8;
    wire [15:0] u0, u1, u2, u3, u4, u5, u6, u7, u8;
    wire done;

    muon_optimizer dut (
        .clk(clk), .rst_n(rst_n), .step(step),
        .g0(g0), .g1(g1), .g2(g2),
        .g3(g3), .g4(g4), .g5(g5),
        .g6(g6), .g7(g7), .g8(g8),
        .u0(u0), .u1(u1), .u2(u2),
        .u3(u3), .u4(u4), .u5(u5),
        .u6(u6), .u7(u7), .u8(u8),
        .done(done)
    );

    always #5 clk = ~clk;

    function real gf16_to_real;
        input [15:0] v;
        reg [5:0] exp_v;
        real fval;
        begin
            exp_v = v[14:9];
            if (v[14:0] == 15'd0) gf16_to_real = 0.0;
            else if (exp_v == 6'h3F) gf16_to_real = v[15] ? -999.0 : 999.0;
            else begin
                fval = (1.0 + v[8:0] / 512.0) * (2.0 ** ($signed({1'b0, exp_v}) - 31));
                gf16_to_real = v[15] ? -fval : fval;
            end
        end
    endfunction

    integer pass_count, fail_count, timeout;

    initial begin
        clk = 0; rst_n = 0; step = 0;
        pass_count = 0; fail_count = 0;
        $display("=== tb_muon_optimizer: Muon optimizer test ===");

        #12 rst_n = 1;
        #10;

        // Test 1: Gradient = identity-like matrix
        $display("Test 1: Apply identity gradient");
        g0 = 16'h3E00; g1 = 16'h0000; g2 = 16'h0000;
        g3 = 16'h0000; g4 = 16'h3E00; g5 = 16'h0000;
        g6 = 16'h0000; g7 = 16'h0000; g8 = 16'h3E00;

        @(posedge clk); #1;
        step = 1;
        @(posedge clk); #1;
        step = 0;

        timeout = 0;
        while (!done && timeout < 30) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (done) begin
            $display("  PASS: done asserted after %0d cycles", timeout+1);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: done not asserted");
            fail_count = fail_count + 1;
        end

        // Verify output is non-zero and finite
        if (u0[14:0] != 15'd0 && u0[14:9] != 6'h3F) begin
            $display("  PASS: u0 = %f (non-zero, finite)", gf16_to_real(u0));
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: u0 = %f (zero or non-finite)", gf16_to_real(u0));
            fail_count = fail_count + 1;
        end

        #20;

        // Test 2: Apply same gradient twice (momentum accumulation)
        $display("Test 2: Second step with same gradient (momentum)");
        @(posedge clk); #1;
        step = 1;
        @(posedge clk); #1;
        step = 0;

        timeout = 0;
        while (!done && timeout < 30) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (done) begin
            $display("  PASS: second step done");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: second step timed out");
            fail_count = fail_count + 1;
        end

        $display("=== Results: PASS=%0d FAIL=%0d ===", pass_count, fail_count);
        if (fail_count == 0) $display("*** ALL PASS ***");
        $finish;
    end

endmodule

`default_nettype wire
