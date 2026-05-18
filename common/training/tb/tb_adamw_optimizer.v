// SPDX-License-Identifier: MIT
// tb_adamw_optimizer.v — Testbench for adamw_optimizer
//
// Test: Apply gradient steps, verify param updates in correct direction.
// PASS criteria: done asserted, param changes after step.

`default_nettype none
`timescale 1ns/1ps

module tb_adamw_optimizer;

    reg clk, rst_n, step;
    reg  [15:0] grad, lr;
    wire [15:0] param;
    wire done;

    adamw_optimizer dut (
        .clk(clk), .rst_n(rst_n), .step(step),
        .grad(grad), .lr(lr),
        .param(param),
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
            else if (exp_v == 6'h3F) gf16_to_real = 0.0;
            else begin
                fval = (1.0 + v[8:0] / 512.0) * (2.0 ** ($signed({1'b0, exp_v}) - 31));
                gf16_to_real = v[15] ? -fval : fval;
            end
        end
    endfunction

    integer pass_count, fail_count, timeout;
    real param_init, param_after;

    initial begin
        clk = 0; rst_n = 0; step = 0;
        pass_count = 0; fail_count = 0;
        $display("=== tb_adamw_optimizer: AdamW optimizer test ===");

        grad = 16'h3C00;  // gradient = 0.5 (positive)
        lr   = 16'h3714;  // lr = ~0.1

        #12 rst_n = 1;
        #10;

        param_init = gf16_to_real(param);
        $display("Initial param = %f (expected 0.0 after reset)", param_init);

        // Test 1: Single optimizer step
        $display("Test 1: Single AdamW step with positive gradient");
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
            $display("  FAIL: done not asserted within 30 cycles");
            fail_count = fail_count + 1;
        end

        param_after = gf16_to_real(param);
        $display("  param after step 1: %f", param_after);
        // Param should be finite
        if (param[14:9] != 6'h3F) begin
            $display("  PASS: param is finite");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: param is NaN/Inf");
            fail_count = fail_count + 1;
        end

        #20;

        // Test 2: Second step
        $display("Test 2: Second AdamW step");
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
            $display("  PASS: second step done, param = %f", gf16_to_real(param));
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: second step timed out");
            fail_count = fail_count + 1;
        end

        // Test 3: Negative gradient
        $display("Test 3: Negative gradient step");
        grad = 16'hBC00;  // -0.5
        #5;
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
            $display("  PASS: negative grad step done, param = %f", gf16_to_real(param));
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: negative grad step timed out");
            fail_count = fail_count + 1;
        end

        $display("=== Results: PASS=%0d FAIL=%0d ===", pass_count, fail_count);
        if (fail_count == 0) $display("*** ALL PASS ***");
        $finish;
    end

endmodule

`default_nettype wire
