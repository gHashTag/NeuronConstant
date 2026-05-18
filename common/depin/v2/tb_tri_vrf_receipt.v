// SPDX-License-Identifier: Apache-2.0
//
// tb_tri_vrf_receipt.v — Self-checking testbench for tri_vrf_receipt
//
// Part of the NeuronConstant DePIN v2 hardware stack.
// DOI: 10.5281/zenodo.19227877
//
// Verilog-2005 / iverilog -g2005-sv -Wall

`timescale 1ns/1ps
`default_nettype none

module tb_tri_vrf_receipt;

    reg        clk;
    reg        rst_n;
    reg  [7:0] job_id;
    reg [31:0] result_hash;
    reg [31:0] prev_receipt_hash;
    reg [15:0] nonce;
    reg        commit;

    wire [31:0] receipt_hash;
    wire        valid;

    // DUT
    tri_vrf_receipt dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .job_id           (job_id),
        .result_hash      (result_hash),
        .prev_receipt_hash(prev_receipt_hash),
        .nonce            (nonce),
        .commit           (commit),
        .receipt_hash     (receipt_hash),
        .valid            (valid)
    );

    integer fail = 0;

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper: compute expected hash
    function [31:0] expected_hash;
        input [31:0] prev;
        input [7:0]  jid;
        input [31:0] res;
        input [15:0] nc;
        begin
            expected_hash = prev ^ {jid, 24'h000000} ^ {res[23:0], 8'h00} ^ {16'h0000, nc};
        end
    endfunction

    reg [31:0] h0, h1, h2;

    initial begin
        $dumpfile("/tmp/tb_tri_vrf_receipt.vcd");
        $dumpvars(0, tb_tri_vrf_receipt);

        // Reset
        rst_n = 0; commit = 0;
        job_id = 0; result_hash = 0; prev_receipt_hash = 0; nonce = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        // Check: after reset, valid=0
        if (valid !== 1'b0) begin
            $display("FAIL: valid should be 0 after reset, got %b", valid);
            fail = fail + 1;
        end

        // --- Receipt 0: prev=0, job=8'hAA, result=32'h12345678, nonce=16'h0001
        prev_receipt_hash = 32'h00000000;
        job_id            = 8'hAA;
        result_hash       = 32'h12345678;
        nonce             = 16'h0001;
        commit            = 1;
        @(posedge clk); #1;
        commit = 0;

        h0 = expected_hash(32'h00000000, 8'hAA, 32'h12345678, 16'h0001);
        if (!valid) begin
            $display("FAIL: valid not asserted after commit0"); fail = fail + 1;
        end
        if (receipt_hash !== h0) begin
            $display("FAIL: receipt0 expected %h got %h", h0, receipt_hash); fail = fail + 1;
        end

        @(posedge clk); #1;
        // valid should be de-asserted
        if (valid !== 1'b0) begin
            $display("FAIL: valid should clear after 1 cycle"); fail = fail + 1;
        end

        // --- Receipt 1: chain from h0
        prev_receipt_hash = h0;
        job_id            = 8'hBB;
        result_hash       = 32'hDEADBEEF;
        nonce             = 16'h0002;
        commit            = 1;
        @(posedge clk); #1;
        commit = 0;

        h1 = expected_hash(h0, 8'hBB, 32'hDEADBEEF, 16'h0002);
        if (!valid) begin
            $display("FAIL: valid not asserted after commit1"); fail = fail + 1;
        end
        if (receipt_hash !== h1) begin
            $display("FAIL: receipt1 expected %h got %h", h1, receipt_hash); fail = fail + 1;
        end
        // Check distinct from h0
        if (h1 === h0) begin
            $display("FAIL: receipt1 == receipt0, should be distinct"); fail = fail + 1;
        end

        @(posedge clk); #1;

        // --- Receipt 2: chain from h1
        prev_receipt_hash = h1;
        job_id            = 8'hCC;
        result_hash       = 32'hCAFEBABE;
        nonce             = 16'h0003;
        commit            = 1;
        @(posedge clk); #1;
        commit = 0;

        h2 = expected_hash(h1, 8'hCC, 32'hCAFEBABE, 16'h0003);
        if (!valid) begin
            $display("FAIL: valid not asserted after commit2"); fail = fail + 1;
        end
        if (receipt_hash !== h2) begin
            $display("FAIL: receipt2 expected %h got %h", h2, receipt_hash); fail = fail + 1;
        end
        // All three distinct
        if (h2 === h1 || h2 === h0) begin
            $display("FAIL: receipt2 not distinct from prior receipts"); fail = fail + 1;
        end

        @(posedge clk); #1;

        // --- Same inputs at different time produce different hashes (chained prev)
        // Repeat receipt0 inputs but with prev=h2 (different prev)
        prev_receipt_hash = h2;
        job_id            = 8'hAA;
        result_hash       = 32'h12345678;
        nonce             = 16'h0001;
        commit            = 1;
        @(posedge clk); #1;
        commit = 0;

        // This should differ from h0 because prev differs
        if (receipt_hash === h0) begin
            $display("FAIL: same inputs with different prev should yield different hash");
            fail = fail + 1;
        end

        @(posedge clk); #1;

        if (fail == 0)
            $display("PASS");
        else
            $display("FAIL: %0d error(s)", fail);

        $finish;
    end

endmodule

`default_nettype wire
