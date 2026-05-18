// SPDX-License-Identifier: Apache-2.0
//
// tb_tri_mofn_attest.v — Self-checking testbench for tri_mofn_attest
//
// Part of the NeuronConstant DePIN v2 hardware stack.
// DOI: 10.5281/zenodo.19227877
//
// Verilog-2005 / iverilog -g2005-sv -Wall

`timescale 1ns/1ps
`default_nettype none

module tb_tri_mofn_attest;

    reg       clk;
    reg       rst_n;
    reg       attest_phi;
    reg       attest_eul;
    reg       attest_gam;
    reg [7:0] job_id;

    wire      consensus_ok;
    wire [2:0] winning_set;

    tri_mofn_attest dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .attest_phi  (attest_phi),
        .attest_eul  (attest_eul),
        .attest_gam  (attest_gam),
        .job_id      (job_id),
        .consensus_ok(consensus_ok),
        .winning_set (winning_set)
    );

    integer fail = 0;
    integer i;
    integer consensus_seen;

    initial clk = 0;
    always #5 clk = ~clk;

    // Task: reset and wait 2 cycles
    task do_reset;
        begin
            rst_n = 0; attest_phi = 0; attest_eul = 0; attest_gam = 0; job_id = 0;
            @(posedge clk); #1;
            @(posedge clk); #1;
            rst_n = 1;
            @(posedge clk); #1;
        end
    endtask

    // Task: run N clock cycles collecting any consensus_ok pulses
    // Returns total count seen across all cycles
    task run_collect;
        input integer n;
        output integer seen;
        integer k;
        begin
            seen = 0;
            for (k = 0; k < n; k = k + 1) begin
                if (consensus_ok) seen = seen + 1;
                @(posedge clk); #1;
            end
            if (consensus_ok) seen = seen + 1;  // check final state
        end
    endtask

    initial begin
        $dumpfile("/tmp/tb_tri_mofn_attest.vcd");
        $dumpvars(0, tb_tri_mofn_attest);

        // ---- Test 1: Only phi -> consensus_ok should never fire ----
        do_reset;
        job_id = 8'h01;
        // Assert phi for 1 cycle
        attest_phi = 1;
        @(posedge clk); #1;
        attest_phi = 0;
        // Wait 20 cycles, check no consensus
        consensus_seen = 0;
        for (i = 0; i < 20; i = i + 1) begin
            if (consensus_ok) consensus_seen = consensus_seen + 1;
            @(posedge clk); #1;
        end
        if (consensus_ok) consensus_seen = consensus_seen + 1;
        if (consensus_seen != 0) begin
            $display("FAIL T1: only phi, expected 0 consensus, got %0d", consensus_seen);
            fail = fail + 1;
        end

        // ---- Test 2: phi + eul within window -> consensus_ok fires ----
        do_reset;
        job_id = 8'h02;
        consensus_seen = 0;
        // phi attest
        attest_phi = 1;
        @(posedge clk); #1;
        attest_phi = 0;
        // eul attest next cycle
        attest_eul = 1;
        @(posedge clk); #1;
        attest_eul = 0;
        // Now collect over 20 more cycles
        for (i = 0; i < 20; i = i + 1) begin
            if (consensus_ok) consensus_seen = consensus_seen + 1;
            @(posedge clk); #1;
        end
        if (consensus_ok) consensus_seen = consensus_seen + 1;
        if (consensus_seen < 1) begin
            $display("FAIL T2: phi+eul, expected >=1 consensus, got %0d", consensus_seen);
            fail = fail + 1;
        end

        // ---- Test 3: all 3 -> consensus_ok fires ----
        do_reset;
        job_id = 8'h03;
        consensus_seen = 0;
        // phi attest
        attest_phi = 1;
        @(posedge clk); #1;
        attest_phi = 0;
        // eul attest next cycle
        attest_eul = 1;
        @(posedge clk); #1;
        attest_eul = 0;
        // gam attest next cycle
        attest_gam = 1;
        @(posedge clk); #1;
        attest_gam = 0;
        // Collect over 20 cycles including during attest sequence
        for (i = 0; i < 25; i = i + 1) begin
            if (consensus_ok) consensus_seen = consensus_seen + 1;
            @(posedge clk); #1;
        end
        if (consensus_ok) consensus_seen = consensus_seen + 1;
        if (consensus_seen < 1) begin
            $display("FAIL T3: all 3 attests, expected >=1 consensus, got %0d", consensus_seen);
            fail = fail + 1;
        end

        // ---- Test 4: attestations spread >16 cycles -> no consensus ----
        // Send phi at cycle 0, eul at cycle 18 (beyond 16-cycle window)
        do_reset;
        job_id = 8'h04;
        consensus_seen = 0;
        attest_phi = 1;
        @(posedge clk); #1;
        attest_phi = 0;
        // Wait 18 cycles (phi ages out of 16-cycle window)
        for (i = 0; i < 18; i = i + 1) begin
            if (consensus_ok) consensus_seen = consensus_seen + 1;
            @(posedge clk); #1;
        end
        // Now attest eul (phi gone from window)
        attest_eul = 1;
        @(posedge clk); #1;
        attest_eul = 0;
        // Check no consensus
        for (i = 0; i < 20; i = i + 1) begin
            if (consensus_ok) consensus_seen = consensus_seen + 1;
            @(posedge clk); #1;
        end
        if (consensus_ok) consensus_seen = consensus_seen + 1;
        if (consensus_seen != 0) begin
            $display("FAIL T4: spread >16 cycles, expected 0 consensus, got %0d", consensus_seen);
            fail = fail + 1;
        end

        if (fail == 0)
            $display("PASS");
        else
            $display("FAIL: %0d error(s)", fail);

        $finish;
    end

endmodule

`default_nettype wire
