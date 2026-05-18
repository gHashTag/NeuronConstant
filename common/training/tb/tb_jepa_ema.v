// SPDX-License-Identifier: MIT
// tb_jepa_ema.v — Testbench for jepa_ema
//
// Test: target=0.0, online=1.0, decay=0.998
//   Expected: target_new = 0.998*0 + 0.002*1.0 = 0.002
// Tolerance: ±0.001 (GF16 precision ~0.2% for this range)

`default_nettype none
`timescale 1ns/1ps

module tb_jepa_ema;

    reg  [15:0] target_in, online_in, decay_in;
    wire [15:0] target_out;

    jepa_ema dut (
        .target(target_in),
        .online(online_in),
        .decay(decay_in),
        .target_new(target_out)
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
    real actual, expected, err;

    task check_approx;
        input [15:0] actual_gf;
        input real expected_v;
        input real abs_tol;
        input [127:0] label;
        begin
            actual = gf16_to_real(actual_gf);
            err = actual - expected_v;
            if (err < 0) err = -err;
            if (err <= abs_tol) begin
                $display("  PASS: %s = %f (expected %f, err=%f)", label, actual, expected_v, err);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %s = %f (expected %f, err=%f)", label, actual, expected_v, err);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== tb_jepa_ema: T-JEPA EMA test ===");

        // Test 1: target=0, online=1.0, decay=0.998
        // Expected: 0.998*0 + 0.002*1.0 = 0.002
        $display("Test 1: target=0, online=1.0, decay=0.998");
        target_in = 16'h0000;   // 0.0
        online_in = 16'h3E00;   // 1.0
        decay_in  = 16'h3DFE;   // 0.998 (GF16)
        #5;
        // Expected ≈ 0.002 (GF16: 0x2C0C ≈ 0.002)
        check_approx(target_out, 0.002, 0.003, "ema1");

        // Test 2: target=1.0, online=0.0, decay=0.998
        // Expected: 0.998*1.0 + 0.002*0.0 = 0.998
        $display("Test 2: target=1.0, online=0.0, decay=0.998");
        target_in = 16'h3E00;   // 1.0
        online_in = 16'h0000;   // 0.0
        decay_in  = 16'h3DFE;   // 0.998
        #5;
        check_approx(target_out, 0.998, 0.015, "ema2");

        // Test 3: decay=0.5, target=1.0, online=0.0
        // Expected: 0.5*1.0 + 0.5*0.0 = 0.5
        $display("Test 3: decay=0.5, target=1.0, online=0.0");
        target_in = 16'h3E00;   // 1.0
        online_in = 16'h0000;   // 0.0
        decay_in  = 16'h3C00;   // 0.5
        #5;
        check_approx(target_out, 0.5, 0.05, "ema3");

        // Test 4: decay=0.9, target=0.5, online=0.5
        // Expected: 0.9*0.5 + 0.1*0.5 = 0.5 (no change)
        $display("Test 4: target=online=0.5 -> should stay 0.5");
        target_in = 16'h3C00;   // 0.5
        online_in = 16'h3C00;   // 0.5
        decay_in  = 16'h3CF9;   // ~0.618 (phi^-1)
        #5;
        check_approx(target_out, 0.5, 0.05, "ema4");

        $display("=== Results: PASS=%0d FAIL=%0d ===", pass_count, fail_count);
        if (fail_count == 0) $display("*** ALL PASS ***");
        $finish;
    end

endmodule

`default_nettype wire
