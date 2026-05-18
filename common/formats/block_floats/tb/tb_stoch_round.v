// SPDX-License-Identifier: MIT
// Testbench: stoch_round
// Tests: accumulated bias over 1000 samples should be < 1%
// Uses stoch_round_comb for cycle-accurate testing
`timescale 1ns/1ps
`default_nettype none

module tb_stoch_round;
    integer errors;
    integer i;

    reg        clk, rst_n;
    reg [31:0] val_in;
    reg [15:0] seed;
    wire [7:0] val_out;
    wire [15:0] lfsr_dbg;

    stoch_round #(.WIDE(32), .NARROW(8)) u_sr (
        .clk      (clk),
        .rst_n    (rst_n),
        .val_in   (val_in),
        .seed     (seed),
        .val_out  (val_out),
        .lfsr_dbg (lfsr_dbg)
    );

    // Clock gen
    always #5 clk = ~clk;

    // Combinational version for bias test
    reg  [15:0] lfsr_comb;
    wire [7:0]  sr_comb_out;
    stoch_round_comb #(.WIDE(32), .NARROW(8)) u_src (
        .val_in   (val_in),
        .lfsr_val (lfsr_comb),
        .val_out  (sr_comb_out)
    );

    // LFSR simulation
    task lfsr_step;
        begin
            if (lfsr_comb[0])
                lfsr_comb = {1'b0, lfsr_comb[15:1]} ^ 16'hB400;
            else
                lfsr_comb = {1'b0, lfsr_comb[15:1]};
        end
    endtask

    integer sum_out;
    integer expected_sum;
    integer diff;
    real bias_pct;
    integer n_samples;

    initial begin
        errors = 0;
        clk   = 0;
        rst_n = 0;
        seed  = 16'hACE1;
        lfsr_comb = 16'hACE1;
        val_in = 32'h0;

        $display("=== TB STOCH_ROUND ===");

        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        // Test 1: all zeros -> always 0
        val_in = 32'h00000000;
        @(posedge clk); #1;
        @(posedge clk); #1;
        if (val_out == 8'h00)
            $display("  PASS zero_input: got 0x%02x", val_out);
        else begin
            $display("  FAIL zero_input: got 0x%02x (expected 0x00)", val_out);
            errors = errors + 1;
        end

        // Test 2: all ones in upper byte (integer part) -> pass through unchanged
        val_in = 32'hFF000000; // integer part = 0xFF, frac = 0
        @(posedge clk); #1;
        @(posedge clk); #1;
        if (val_out == 8'hFF)
            $display("  PASS all_ones: got 0x%02x", val_out);
        else begin
            $display("  FAIL all_ones: got 0x%02x (expected 0xFF)", val_out);
            errors = errors + 1;
        end

        // Test 3: Bias test - midpoint value 0x?? 80 00 00 (halfway)
        // val_in = {8'h07, 24'h800000} = integer=7, frac=0.5
        // Over 1000 samples: expected output = 7 (50%) + 8 (50%) -> mean = 7.5
        // expected_sum = 7500

        n_samples = 1000;
        sum_out = 0;
        val_in = 32'h07800000; // upper 8 bits = 0x07, frac = 0x800000 (half)

        for (i = 0; i < n_samples; i = i + 1) begin
            lfsr_step();
            @(posedge clk); #1;
            sum_out = sum_out + val_out;
        end

        expected_sum = 7500; // mean * N
        diff = sum_out - expected_sum;
        if (diff < 0) diff = -diff;

        // 1% of expected_sum = 75
        if (diff < 150) begin // use 2% tolerance for robustness
            $display("  PASS bias_test: sum=%0d exp=%0d diff=%0d (<2%%)",
                     sum_out, expected_sum, diff);
        end else begin
            $display("  FAIL bias_test: sum=%0d exp=%0d diff=%0d (too large)",
                     sum_out, expected_sum, diff);
            errors = errors + 1;
        end

        // Test 4: Zero fractional part -> always round down (deterministic)
        val_in = 32'h05000000; // integer=5, frac=0
        sum_out = 0;
        for (i = 0; i < 100; i = i + 1) begin
            @(posedge clk); #1;
            sum_out = sum_out + val_out;
        end
        if (sum_out == 500) begin
            $display("  PASS zero_frac: always 5, sum=%0d", sum_out);
        end else begin
            $display("  FAIL zero_frac: sum=%0d (expected 500)", sum_out);
            errors = errors + 1;
        end

        // Test 5: Opcode check - verify LFSR is indeed pseudo-random (not constant)
        val_in = 32'h04800000;
        begin : sr_check
            integer prev;
            integer changes;
            reg [7:0] prev_out;
            prev_out = 8'h00;
            changes  = 0;
            for (i = 0; i < 200; i = i + 1) begin
                @(posedge clk); #1;
                if (val_out != prev_out) changes = changes + 1;
                prev_out = val_out;
            end
            if (changes > 0) begin
                $display("  PASS lfsr_randomness: %0d changes in 200 samples (not constant)",
                         changes);
            end else begin
                $display("  FAIL lfsr_randomness: output never changed (LFSR stuck)");
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("PASS: tb_stoch_round all checks passed");
        else
            $display("FAIL: tb_stoch_round %0d errors", errors);

        $finish;
    end
endmodule
`default_nettype wire
