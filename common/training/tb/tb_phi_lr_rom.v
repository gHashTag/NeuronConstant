// SPDX-License-Identifier: MIT
// tb_phi_lr_rom.v — Testbench for phi_lr_rom
//
// Test: verify key ROM entries match expected phi-LR schedule values.
// PASS criteria:
//   step  0 -> min warmup LR (~0.00874)
//   step 26 -> max_lr (~0.236, peak of warmup at step 26)
//   step 27 -> same as step 26 (step27 = peak)
//   step 53 -> min decay LR (~0.148)
// Tolerance: ±10% relative (GF16 precision limited).

`default_nettype none
`timescale 1ns/1ps

module tb_phi_lr_rom;

    reg  [5:0]  step_idx;
    wire [15:0] lr_val;

    phi_lr_rom dut (
        .step_idx(step_idx),
        .lr_val(lr_val)
    );

    function real gf16_to_real;
        input [15:0] v;
        reg [5:0] exp_v;
        real fval;
        begin
            exp_v = v[14:9];
            if (v[14:0] == 15'd0) gf16_to_real = 0.0;
            else begin
                fval = (1.0 + v[8:0] / 512.0) * (2.0 ** ($signed({1'b0, exp_v}) - 31));
                gf16_to_real = v[15] ? -fval : fval;
            end
        end
    endfunction

    integer pass_count, fail_count;
    real actual, expected, rel_err;

    task check_rel;
        input [15:0] actual_gf;
        input real   expected_v;
        input real   rel_tol;
        input [63:0] label;
        begin
            actual  = gf16_to_real(actual_gf);
            if (expected_v != 0.0)
                rel_err = (actual - expected_v) / expected_v;
            else
                rel_err = actual;
            if (rel_err < 0) rel_err = -rel_err;
            if (rel_err <= rel_tol) begin
                $display("  PASS: step %s: lr=%f (expected %f, rel_err=%f%%)",
                         label, actual, expected_v, rel_err*100);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: step %s: lr=%f (expected %f, rel_err=%f%%)",
                         label, actual, expected_v, rel_err*100);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== tb_phi_lr_rom: φ-LR ROM test ===");

        // Step 0: first warmup step = base_lr/27 = 0.236/27 ≈ 0.00874
        step_idx = 6'd0; #1;
        check_rel(lr_val, 0.008743, 0.15, "0 ");

        // Step 13: mid-warmup ≈ base_lr * 14/27 ≈ 0.1225
        step_idx = 6'd13; #1;
        check_rel(lr_val, 0.122406, 0.12, "13");

        // Step 26: peak warmup = base_lr ≈ 0.2361
        step_idx = 6'd26; #1;
        check_rel(lr_val, 0.236068, 0.12, "26");

        // Step 27: same as 26 (peak post-warmup)
        step_idx = 6'd27; #1;
        check_rel(lr_val, 0.236068, 0.12, "27");

        // Step 40: mid-decay ≈ 0.187
        step_idx = 6'd40; #1;
        check_rel(lr_val, 0.187246, 0.12, "40");

        // Step 53: minimum decay LR ≈ 0.1485
        step_idx = 6'd53; #1;
        check_rel(lr_val, 0.148522, 0.12, "53");

        // Step 63 (out of range): should return min
        step_idx = 6'd63; #1;
        check_rel(lr_val, 0.148522, 0.20, "63(default)");

        $display("=== Results: PASS=%0d FAIL=%0d ===", pass_count, fail_count);
        if (fail_count == 0) $display("*** ALL PASS ***");
        $finish;
    end

endmodule

`default_nettype wire
