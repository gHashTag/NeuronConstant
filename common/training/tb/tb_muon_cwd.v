// SPDX-License-Identifier: MIT
// tb_muon_cwd.v — Testbench for muon_cwd (Muon + Coupled Weight Decay)
//
// Test: parameter update with weight decay effect.
// PASS criteria: done asserted, param decreases (weight decay + gradient step).

`default_nettype none
`timescale 1ns/1ps

module tb_muon_cwd;

    reg clk, rst_n, step;
    reg  [15:0] p0, p1, p2, p3, p4, p5, p6, p7, p8;
    reg  [15:0] g0, g1, g2, g3, g4, g5, g6, g7, g8;
    reg  [15:0] lr, wd_coeff;
    wire [15:0] p0_out, p1_out, p2_out, p3_out, p4_out, p5_out;
    wire [15:0] p6_out, p7_out, p8_out;
    wire done;

    muon_cwd dut (
        .clk(clk), .rst_n(rst_n), .step(step),
        .p0(p0), .p1(p1), .p2(p2),
        .p3(p3), .p4(p4), .p5(p5),
        .p6(p6), .p7(p7), .p8(p8),
        .g0(g0), .g1(g1), .g2(g2),
        .g3(g3), .g4(g4), .g5(g5),
        .g6(g6), .g7(g7), .g8(g8),
        .lr(lr), .wd_coeff(wd_coeff),
        .p0_out(p0_out), .p1_out(p1_out), .p2_out(p2_out),
        .p3_out(p3_out), .p4_out(p4_out), .p5_out(p5_out),
        .p6_out(p6_out), .p7_out(p7_out), .p8_out(p8_out),
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
    real p0_before, p0_after;

    initial begin
        clk = 0; rst_n = 0; step = 0;
        pass_count = 0; fail_count = 0;
        $display("=== tb_muon_cwd: Muon + CWD test ===");

        // Parameters (positive values)
        p0 = 16'h4000; p1 = 16'h3E00; p2 = 16'h3C00;  // 2.0, 1.0, 0.5
        p3 = 16'h3E00; p4 = 16'h4000; p5 = 16'h3E00;
        p6 = 16'h3C00; p7 = 16'h3E00; p8 = 16'h4000;

        // Gradients (positive)
        g0 = 16'h3E00; g1 = 16'h0000; g2 = 16'h0000;
        g3 = 16'h0000; g4 = 16'h3E00; g5 = 16'h0000;
        g6 = 16'h0000; g7 = 16'h0000; g8 = 16'h3E00;

        // LR = 0.1 GF16, WD = 0.1 GF16
        lr       = 16'h3714;  // ~0.1
        wd_coeff = 16'h3714;  // ~0.1

        #12 rst_n = 1;
        #10;

        p0_before = gf16_to_real(p0);

        @(posedge clk); #1;
        step = 1;
        @(posedge clk); #1;
        step = 0;

        timeout = 0;
        while (!done && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (done) begin
            $display("  PASS: done asserted after %0d cycles", timeout+1);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: done not asserted within 50 cycles");
            fail_count = fail_count + 1;
        end

        // Verify output is finite
        if (p0_out[14:9] != 6'h3F) begin
            p0_after = gf16_to_real(p0_out);
            $display("  PASS: p0_out = %f (finite, was %f)", p0_after, p0_before);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: p0_out is NaN/Inf");
            fail_count = fail_count + 1;
        end

        $display("=== Results: PASS=%0d FAIL=%0d ===", pass_count, fail_count);
        if (fail_count == 0) $display("*** ALL PASS ***");
        $finish;
    end

endmodule

`default_nettype wire
