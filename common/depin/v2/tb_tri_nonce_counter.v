// SPDX-License-Identifier: Apache-2.0
//
// tb_tri_nonce_counter.v — Self-checking testbench for tri_nonce_counter
//
// Part of the NeuronConstant DePIN v2 hardware stack.
// DOI: 10.5281/zenodo.19227877
//
// Verilog-2005 / iverilog -g2005-sv -Wall

`timescale 1ns/1ps
`default_nettype none

module tb_tri_nonce_counter;

    reg        clk;
    reg        rst_n;
    reg        advance;

    wire [15:0] nonce;
    wire        wrap_flag;

    tri_nonce_counter dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .advance  (advance),
        .nonce    (nonce),
        .wrap_flag(wrap_flag)
    );

    integer fail = 0;
    integer i;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("/tmp/tb_tri_nonce_counter.vcd");
        $dumpvars(0, tb_tri_nonce_counter);

        // Reset
        rst_n = 0; advance = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        // After reset nonce=0, wrap_flag=0
        if (nonce !== 16'h0000) begin
            $display("FAIL: nonce should be 0 after reset, got %0d", nonce);
            fail = fail + 1;
        end
        if (wrap_flag !== 1'b0) begin
            $display("FAIL: wrap_flag should be 0 after reset"); fail = fail + 1;
        end

        // 5 advances -> nonce=5
        for (i = 0; i < 5; i = i + 1) begin
            advance = 1;
            @(posedge clk); #1;
            advance = 0;
            @(posedge clk); #1;
        end

        if (nonce !== 16'h0005) begin
            $display("FAIL: nonce should be 5 after 5 advances, got %0d", nonce);
            fail = fail + 1;
        end

        // Advance to 0xFFFE
        // Reset and count to 0xFFFE directly via many cycles
        rst_n = 0;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        // Load nonce to 0xFFFE via continuous advance
        // Use a repeated advance without waiting (just clock edges)
        // This would take too long; instead test wrap at current nonce=0
        // Let's advance to 0xFFFF then one more
        // Reset to 0 first
        if (nonce !== 16'h0000) begin
            $display("FAIL: nonce should be 0 after second reset, got %0d", nonce);
            fail = fail + 1;
        end

        // Advance 5 times again, check nonce=5
        for (i = 0; i < 5; i = i + 1) begin
            advance = 1;
            @(posedge clk); #1;
            advance = 0;
            @(posedge clk); #1;
        end
        if (nonce !== 16'h0005) begin
            $display("FAIL: nonce should be 5, got %0d", nonce); fail = fail + 1;
        end

        // Now reset and set up near wrap: advance to 0xFFFF then wrap
        rst_n = 0;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        // Simulate being at 0xFFFF by forcing the nonce register
        // We'll just do 65535 quick advances using advance=1 for consecutive cycles
        // But that's impractical in sim time. Instead we verify the wrap logic
        // by applying advance 65535 times at 1 cycle each (no idle gap).
        // At 10ns/cycle x 65535 = 655350ns — acceptable for iverilog sim.
        for (i = 0; i < 65535; i = i + 1) begin
            advance = 1;
            @(posedge clk); #1;
        end
        advance = 0;

        // nonce should now be 0xFFFF
        if (nonce !== 16'hFFFF) begin
            $display("FAIL: nonce should be 0xFFFF, got %h", nonce); fail = fail + 1;
        end
        if (wrap_flag !== 1'b0) begin
            $display("FAIL: wrap_flag should still be 0 at 0xFFFF"); fail = fail + 1;
        end

        // One more advance -> wrap
        advance = 1;
        @(posedge clk); #1;
        advance = 0;

        if (nonce !== 16'h0000) begin
            $display("FAIL: nonce should wrap to 0, got %h", nonce); fail = fail + 1;
        end
        if (wrap_flag !== 1'b1) begin
            $display("FAIL: wrap_flag should be 1 on wrap"); fail = fail + 1;
        end

        // Next cycle wrap_flag clears
        @(posedge clk); #1;
        if (wrap_flag !== 1'b0) begin
            $display("FAIL: wrap_flag should clear next cycle"); fail = fail + 1;
        end

        if (fail == 0)
            $display("PASS");
        else
            $display("FAIL: %0d error(s)", fail);

        $finish;
    end

endmodule

`default_nettype wire
