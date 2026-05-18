// SPDX-License-Identifier: Apache-2.0
//
// tb_tri_share_split.v — Self-checking testbench for tri_share_split
//
// Part of the NeuronConstant DePIN v2 hardware stack.
// DOI: 10.5281/zenodo.19227877
//
// Verilog-2005 / iverilog -g2005-sv -Wall

`timescale 1ns/1ps
`default_nettype none

module tb_tri_share_split;

    reg  [5:0] total_reward;
    reg  [1:0] share_phi;
    reg  [1:0] share_eul;
    reg  [1:0] share_gam;

    wire [5:0] phi_get;
    wire [5:0] eul_get;
    wire [5:0] gam_get;

    tri_share_split dut (
        .total_reward(total_reward),
        .share_phi   (share_phi),
        .share_eul   (share_eul),
        .share_gam   (share_gam),
        .phi_get     (phi_get),
        .eul_get     (eul_get),
        .gam_get     (gam_get)
    );

    integer fail = 0;

    initial begin
        $dumpfile("/tmp/tb_tri_share_split.vcd");
        $dumpvars(0, tb_tri_share_split);

        // Test 1: total=12, shares=1/1/1 -> 4/4/4
        total_reward = 6'd12; share_phi = 2'd1; share_eul = 2'd1; share_gam = 2'd1;
        #5;
        if (phi_get !== 6'd4 || eul_get !== 6'd4 || gam_get !== 6'd4) begin
            $display("FAIL T1: 12 1/1/1, expected 4/4/4, got %0d/%0d/%0d",
                     phi_get, eul_get, gam_get);
            fail = fail + 1;
        end

        // Test 2: total=12, shares=0/1/2 -> 0/4/8
        total_reward = 6'd12; share_phi = 2'd0; share_eul = 2'd1; share_gam = 2'd2;
        #5;
        if (phi_get !== 6'd0 || eul_get !== 6'd4 || gam_get !== 6'd8) begin
            $display("FAIL T2: 12 0/1/2, expected 0/4/8, got %0d/%0d/%0d",
                     phi_get, eul_get, gam_get);
            fail = fail + 1;
        end

        // Test 3: total=9, shares=1/1/1 -> 3/3/3
        total_reward = 6'd9; share_phi = 2'd1; share_eul = 2'd1; share_gam = 2'd1;
        #5;
        if (phi_get !== 6'd3 || eul_get !== 6'd3 || gam_get !== 6'd3) begin
            $display("FAIL T3: 9 1/1/1, expected 3/3/3, got %0d/%0d/%0d",
                     phi_get, eul_get, gam_get);
            fail = fail + 1;
        end

        // Test 4: total=6, shares=0/0/3 -> 0/0/6
        total_reward = 6'd6; share_phi = 2'd0; share_eul = 2'd0; share_gam = 2'd3;
        #5;
        if (phi_get !== 6'd0 || eul_get !== 6'd0 || gam_get !== 6'd6) begin
            $display("FAIL T4: 6 0/0/3, expected 0/0/6, got %0d/%0d/%0d",
                     phi_get, eul_get, gam_get);
            fail = fail + 1;
        end

        // Test 5: total=3, shares=1/1/1 -> 1/1/1
        total_reward = 6'd3; share_phi = 2'd1; share_eul = 2'd1; share_gam = 2'd1;
        #5;
        if (phi_get !== 6'd1 || eul_get !== 6'd1 || gam_get !== 6'd1) begin
            $display("FAIL T5: 3 1/1/1, expected 1/1/1, got %0d/%0d/%0d",
                     phi_get, eul_get, gam_get);
            fail = fail + 1;
        end

        // Test 6: total=0, shares=1/1/1 -> 0/0/0
        total_reward = 6'd0; share_phi = 2'd1; share_eul = 2'd1; share_gam = 2'd1;
        #5;
        if (phi_get !== 6'd0 || eul_get !== 6'd0 || gam_get !== 6'd0) begin
            $display("FAIL T6: 0 1/1/1, expected 0/0/0, got %0d/%0d/%0d",
                     phi_get, eul_get, gam_get);
            fail = fail + 1;
        end

        // Test 7: total=63, shares=1/1/1 -> 21/21/21
        total_reward = 6'd63; share_phi = 2'd1; share_eul = 2'd1; share_gam = 2'd1;
        #5;
        if (phi_get !== 6'd21 || eul_get !== 6'd21 || gam_get !== 6'd21) begin
            $display("FAIL T7: 63 1/1/1, expected 21/21/21, got %0d/%0d/%0d",
                     phi_get, eul_get, gam_get);
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
