// SPDX-License-Identifier: Apache-2.0
//
// tb_tri_3phase_commit.v — Self-checking testbench for tri_3phase_commit
//
// Part of the NeuronConstant DePIN v2 hardware stack.
// DOI: 10.5281/zenodo.19227877
//
// Verilog-2005 / iverilog -g2005-sv -Wall

`timescale 1ns/1ps
`default_nettype none

module tb_tri_3phase_commit;

    reg        clk;
    reg        rst_n;
    reg        claim_req;
    reg        work_done;
    reg        receipt_valid;
    reg        timeout;

    wire [1:0] state;
    wire       settled;
    wire       aborted;

    localparam [1:0] S_IDLE    = 2'b00;
    localparam [1:0] S_CLAIMED = 2'b01;
    localparam [1:0] S_WORKING = 2'b10;
    localparam [1:0] S_DONE    = 2'b11;

    tri_3phase_commit dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .claim_req    (claim_req),
        .work_done    (work_done),
        .receipt_valid(receipt_valid),
        .timeout      (timeout),
        .state        (state),
        .settled      (settled),
        .aborted      (aborted)
    );

    integer fail = 0;

    initial clk = 0;
    always #5 clk = ~clk;

    task pulse;
        input reg sig_ref;
        begin
            // Caller sets the signal, we just advance clock
            @(posedge clk); #1;
        end
    endtask

    initial begin
        $dumpfile("/tmp/tb_tri_3phase_commit.vcd");
        $dumpvars(0, tb_tri_3phase_commit);

        rst_n = 0; claim_req = 0; work_done = 0; receipt_valid = 0; timeout = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        // Check initial state is IDLE
        if (state !== S_IDLE) begin
            $display("FAIL: initial state should be IDLE, got %0d", state);
            fail = fail + 1;
        end

        // ---- Happy path ----
        // IDLE -> CLAIMED on claim_req
        claim_req = 1;
        @(posedge clk); #1;
        claim_req = 0;
        if (state !== S_CLAIMED) begin
            $display("FAIL HP1: should be CLAIMED, got %0d", state); fail = fail + 1;
        end
        if (settled || aborted) begin
            $display("FAIL HP1: no settled/aborted expected"); fail = fail + 1;
        end

        // CLAIMED -> WORKING on work_done
        work_done = 1;
        @(posedge clk); #1;
        work_done = 0;
        if (state !== S_WORKING) begin
            $display("FAIL HP2: should be WORKING, got %0d", state); fail = fail + 1;
        end

        // WORKING -> DONE on receipt_valid; settled pulse
        receipt_valid = 1;
        @(posedge clk); #1;
        receipt_valid = 0;
        if (state !== S_DONE) begin
            $display("FAIL HP3: should be DONE, got %0d", state); fail = fail + 1;
        end
        if (!settled) begin
            $display("FAIL HP3: settled should be 1"); fail = fail + 1;
        end
        if (aborted) begin
            $display("FAIL HP3: aborted should be 0"); fail = fail + 1;
        end

        // DONE -> IDLE auto-transition
        @(posedge clk); #1;
        if (state !== S_IDLE) begin
            $display("FAIL HP4: should auto-return to IDLE from DONE, got %0d", state);
            fail = fail + 1;
        end
        if (settled) begin
            $display("FAIL HP4: settled should clear"); fail = fail + 1;
        end

        // ---- Timeout path ----
        // IDLE -> CLAIMED
        claim_req = 1;
        @(posedge clk); #1;
        claim_req = 0;
        if (state !== S_CLAIMED) begin
            $display("FAIL TP1: should be CLAIMED"); fail = fail + 1;
        end

        // CLAIMED -> WORKING
        work_done = 1;
        @(posedge clk); #1;
        work_done = 0;
        if (state !== S_WORKING) begin
            $display("FAIL TP2: should be WORKING"); fail = fail + 1;
        end

        // WORKING -> IDLE on timeout; aborted pulse
        timeout = 1;
        @(posedge clk); #1;
        timeout = 0;
        if (state !== S_IDLE) begin
            $display("FAIL TP3: timeout should return to IDLE, got %0d", state);
            fail = fail + 1;
        end
        if (!aborted) begin
            $display("FAIL TP3: aborted should be 1 on timeout"); fail = fail + 1;
        end
        if (settled) begin
            $display("FAIL TP3: settled should be 0 on timeout"); fail = fail + 1;
        end

        @(posedge clk); #1;
        if (aborted) begin
            $display("FAIL TP4: aborted should clear next cycle"); fail = fail + 1;
        end

        if (fail == 0)
            $display("PASS");
        else
            $display("FAIL: %0d error(s)", fail);

        $finish;
    end

endmodule

`default_nettype wire
