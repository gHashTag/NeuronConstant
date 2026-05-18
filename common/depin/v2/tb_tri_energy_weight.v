// SPDX-License-Identifier: Apache-2.0
//
// tb_tri_energy_weight.v — Self-checking testbench for tri_energy_weight
//
// Part of the NeuronConstant DePIN v2 hardware stack.
// DOI: 10.5281/zenodo.19227877
//
// Verilog-2005 / iverilog -g2005-sv -Wall

`timescale 1ns/1ps
`default_nettype none

module tb_tri_energy_weight;

    reg        clk;
    reg        rst_n;
    reg  [3:0] base_reward;
    reg        active_state;
    reg        idle_state;
    reg        fbb_active;

    wire [5:0] weighted_reward;

    tri_energy_weight dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .base_reward    (base_reward),
        .active_state   (active_state),
        .idle_state     (idle_state),
        .fbb_active     (fbb_active),
        .weighted_reward(weighted_reward)
    );

    integer fail = 0;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("/tmp/tb_tri_energy_weight.vcd");
        $dumpvars(0, tb_tri_energy_weight);

        rst_n = 0; base_reward = 0; active_state = 0; idle_state = 0; fbb_active = 0;
        #10;
        rst_n = 1;
        #5;

        // Test 1: idle base=2 -> 2
        base_reward = 4'd2; idle_state = 1; active_state = 0; fbb_active = 0;
        #2;
        if (weighted_reward !== 6'd2) begin
            $display("FAIL T1: idle base=2, expected 2, got %0d", weighted_reward);
            fail = fail + 1;
        end

        // Test 2: active base=2 -> 4
        base_reward = 4'd2; idle_state = 0; active_state = 1; fbb_active = 0;
        #2;
        if (weighted_reward !== 6'd4) begin
            $display("FAIL T2: active base=2, expected 4, got %0d", weighted_reward);
            fail = fail + 1;
        end

        // Test 3: fbb base=2 -> 8
        base_reward = 4'd2; idle_state = 0; active_state = 0; fbb_active = 1;
        #2;
        if (weighted_reward !== 6'd8) begin
            $display("FAIL T3: fbb base=2, expected 8, got %0d", weighted_reward);
            fail = fail + 1;
        end

        // Test 4: fbb priority over active
        base_reward = 4'd2; idle_state = 0; active_state = 1; fbb_active = 1;
        #2;
        if (weighted_reward !== 6'd8) begin
            $display("FAIL T4: fbb+active base=2, expected fbb=8, got %0d", weighted_reward);
            fail = fail + 1;
        end

        // Test 5: base=0 all states -> 0
        base_reward = 4'd0; idle_state = 1; active_state = 0; fbb_active = 0;
        #2;
        if (weighted_reward !== 6'd0) begin
            $display("FAIL T5: base=0 idle, expected 0, got %0d", weighted_reward);
            fail = fail + 1;
        end

        // Test 6: base=15 fbb -> 15<<2=60
        base_reward = 4'd15; idle_state = 0; active_state = 0; fbb_active = 1;
        #2;
        if (weighted_reward !== 6'd60) begin
            $display("FAIL T6: fbb base=15, expected 60, got %0d", weighted_reward);
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
