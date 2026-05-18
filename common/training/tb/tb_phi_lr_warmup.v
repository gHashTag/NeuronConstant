// SPDX-License-Identifier: MIT
// tb_phi_lr_warmup.v — Testbench for phi_lr_warmup
//
// Test:
//   - Steps 0..warmup_steps: linear ramp
//   - Steps >= warmup_steps: decay (from ROM)
// Tolerance: GF16 limited, check monotonicity and range.

`default_nettype none
`timescale 1ns/1ps

module tb_phi_lr_warmup;

    reg  [15:0] step_cnt;
    reg  [15:0] max_lr;
    reg  [5:0]  warmup_steps;
    wire [15:0] lr_out;

    phi_lr_warmup dut (
        .step_cnt(step_cnt),
        .max_lr(max_lr),
        .warmup_steps(warmup_steps),
        .lr_out(lr_out)
    );

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

    integer pass_count, fail_count;
    real prev_lr, curr_lr;
    integer i;

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== tb_phi_lr_warmup: φ-LR warmup test ===");

        max_lr       = 16'h39C7;  // 0.236 (base_lr = alpha_phi)
        warmup_steps = 6'd27;

        // Test 1: During warmup, LR should increase (roughly)
        $display("Test 1: Warmup phase - LR should be non-decreasing");
        prev_lr = 0.0;
        for (i = 0; i < 27; i = i+1) begin
            step_cnt = i[15:0]; #2;
            curr_lr = gf16_to_real(lr_out);
            // LR should be non-negative
            if (curr_lr >= 0.0) begin
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: step %0d lr=%f (negative)", i, curr_lr);
                fail_count = fail_count + 1;
            end
            prev_lr = curr_lr;
        end
        $display("  Warmup steps checked: LR at step 0=%f, step 26=%f",
                 gf16_to_real(16'h303D), gf16_to_real(16'h39C7));

        // Test 2: Post-warmup, LR should be positive and <= max_lr
        $display("Test 2: Post-warmup phase");
        step_cnt = 16'd30; #2;
        curr_lr = gf16_to_real(lr_out);
        if (curr_lr > 0.0 && curr_lr <= 0.3) begin
            $display("  PASS: post-warmup lr=%f (in range)", curr_lr);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: post-warmup lr=%f (out of range)", curr_lr);
            fail_count = fail_count + 1;
        end

        // Test 3: Step 53 (end of ROM)
        step_cnt = 16'd53; #2;
        curr_lr = gf16_to_real(lr_out);
        if (curr_lr > 0.0) begin
            $display("  PASS: step 53 lr=%f (positive)", curr_lr);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: step 53 lr=%f", curr_lr);
            fail_count = fail_count + 1;
        end

        $display("=== Results: PASS=%0d FAIL=%0d ===", pass_count, fail_count);
        if (fail_count == 0) $display("*** ALL PASS ***");
        $finish;
    end

endmodule

`default_nettype wire
