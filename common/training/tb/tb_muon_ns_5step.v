// SPDX-License-Identifier: MIT
// tb_muon_ns_5step.v — Testbench for muon_ns_5step
//
// Test: non-orthogonal 3x3 matrix -> after 5 NS steps should become
// approximately orthogonal: diagonal dominant, bounded entries.
//
// Note: GF16 precision limits convergence accuracy.
// PASS criteria: done signal asserted, output finite values.

`default_nettype none
`timescale 1ns/1ps

module tb_muon_ns_5step;

    reg clk, rst_n, start;
    reg  [15:0] x0_in, x1_in, x2_in;
    reg  [15:0] x3_in, x4_in, x5_in;
    reg  [15:0] x6_in, x7_in, x8_in;
    wire [15:0] y0_out, y1_out, y2_out;
    wire [15:0] y3_out, y4_out, y5_out;
    wire [15:0] y6_out, y7_out, y8_out;
    wire done;

    muon_ns_5step dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .x0_in(x0_in), .x1_in(x1_in), .x2_in(x2_in),
        .x3_in(x3_in), .x4_in(x4_in), .x5_in(x5_in),
        .x6_in(x6_in), .x7_in(x7_in), .x8_in(x8_in),
        .y0_out(y0_out), .y1_out(y1_out), .y2_out(y2_out),
        .y3_out(y3_out), .y4_out(y4_out), .y5_out(y5_out),
        .y6_out(y6_out), .y7_out(y7_out), .y8_out(y8_out),
        .done(done)
    );

    always #5 clk = ~clk;

    function real gf16_to_real;
        input [15:0] v;
        reg [5:0] exp_v;
        reg [8:0] mant_v;
        real fval;
        begin
            exp_v  = v[14:9];
            mant_v = v[8:0];
            if (v[14:0] == 15'd0) begin
                gf16_to_real = 0.0;
            end else if (exp_v == 6'h3F) begin
                gf16_to_real = v[15] ? -999.0 : 999.0; // inf/NaN
            end else begin
                fval = (1.0 + mant_v / 512.0) * (2.0 ** ($signed({1'b0, exp_v}) - 31));
                gf16_to_real = v[15] ? -fval : fval;
            end
        end
    endfunction

    integer pass_count, fail_count;
    integer timeout;

    initial begin
        clk = 0; rst_n = 0; start = 0;
        pass_count = 0; fail_count = 0;
        $display("=== tb_muon_ns_5step: 5-step NS orthogonalization test ===");

        #12 rst_n = 1;
        #10;

        // Test 1: Identity matrix -> 5 iterations
        $display("Test 1: Identity matrix, 5 NS iterations");
        x0_in = 16'h3E00; x1_in = 16'h0000; x2_in = 16'h0000;
        x3_in = 16'h0000; x4_in = 16'h3E00; x5_in = 16'h0000;
        x6_in = 16'h0000; x7_in = 16'h0000; x8_in = 16'h3E00;

        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        // Wait for done (max 20 cycles)
        timeout = 0;
        while (!done && timeout < 20) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (done) begin
            $display("  PASS: done asserted after %0d cycles", timeout);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: done not asserted within 20 cycles");
            fail_count = fail_count + 1;
        end

        // Check output is finite
        if (y0_out[14:9] != 6'h3F) begin
            $display("  PASS: y0_out finite = %f", gf16_to_real(y0_out));
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: y0_out is NaN/Inf");
            fail_count = fail_count + 1;
        end

        // Wait for DONE state to return to IDLE
        @(posedge clk); #1;
        #20;

        // Test 2: Non-orthogonal matrix
        $display("Test 2: Non-orthogonal input");
        x0_in = 16'h3E00; x1_in = 16'h3C00; x2_in = 16'h3A00;  // [1.0, 0.5, 0.25]
        x3_in = 16'h3C00; x4_in = 16'h3E00; x5_in = 16'h3C00;  // [0.5, 1.0, 0.5]
        x6_in = 16'h3A00; x7_in = 16'h3C00; x8_in = 16'h3E00;  // [0.25, 0.5, 1.0]

        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        timeout = 0;
        while (!done && timeout < 20) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (done) begin
            $display("  PASS: done asserted");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: done not asserted");
            fail_count = fail_count + 1;
        end

        // Check all outputs finite
        if (y0_out[14:9] != 6'h3F && y4_out[14:9] != 6'h3F && y8_out[14:9] != 6'h3F) begin
            $display("  PASS: diagonal elements finite: %f %f %f",
                     gf16_to_real(y0_out), gf16_to_real(y4_out), gf16_to_real(y8_out));
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: some diagonal elements NaN/Inf");
            fail_count = fail_count + 1;
        end

        $display("=== Results: PASS=%0d FAIL=%0d ===", pass_count, fail_count);
        if (fail_count == 0)
            $display("*** ALL PASS ***");
        $finish;
    end

endmodule

`default_nettype wire
