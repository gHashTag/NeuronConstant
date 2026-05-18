// SPDX-License-Identifier: Apache-2.0
//
// tb_tri_slash.v — Self-checking testbench for tri_slash
//
// Part of the NeuronConstant DePIN v2 hardware stack.
// DOI: 10.5281/zenodo.19227877
//
// Verilog-2005 / iverilog -g2005-sv -Wall

`timescale 1ns/1ps
`default_nettype none

module tb_tri_slash;

    reg        clk;
    reg        rst_n;
    reg [15:0] balance_in;
    reg        invalid_pulse;

    wire [15:0] balance_out;

    tri_slash dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .balance_in   (balance_in),
        .invalid_pulse(invalid_pulse),
        .balance_out  (balance_out)
    );

    integer fail = 0;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("/tmp/tb_tri_slash.vcd");
        $dumpvars(0, tb_tri_slash);

        rst_n = 0; balance_in = 0; invalid_pulse = 0;
        #10;
        rst_n = 1;
        #5;

        // Test 1: balance=1000, slash -> 1000 - (1000>>4) = 1000 - 62 = 938
        // Note: 1000>>4 = 62 (integer), 1000-62=938
        balance_in = 16'd1000;
        invalid_pulse = 1;
        #2;
        if (balance_out !== 16'd938) begin
            $display("FAIL T1: balance=1000 slash, expected 938, got %0d", balance_out);
            fail = fail + 1;
        end
        invalid_pulse = 0;
        #2;
        // No slash -> passthrough
        if (balance_out !== 16'd1000) begin
            $display("FAIL T1b: no slash, expected 1000, got %0d", balance_out);
            fail = fail + 1;
        end

        // Test 2: balance=16, slash -> 16 - (16>>4) = 16 - 1 = 15
        balance_in = 16'd16;
        invalid_pulse = 1;
        #2;
        if (balance_out !== 16'd15) begin
            $display("FAIL T2: balance=16 slash, expected 15, got %0d", balance_out);
            fail = fail + 1;
        end
        invalid_pulse = 0;
        #2;

        // Test 3: balance=0, slash -> 0 - 0 = 0
        balance_in = 16'd0;
        invalid_pulse = 1;
        #2;
        if (balance_out !== 16'd0) begin
            $display("FAIL T3: balance=0 slash, expected 0, got %0d", balance_out);
            fail = fail + 1;
        end
        invalid_pulse = 0;
        #2;

        // Test 4: balance=15, slash -> 15 - (15>>4)=15 - 0 = 15
        balance_in = 16'd15;
        invalid_pulse = 1;
        #2;
        if (balance_out !== 16'd15) begin
            $display("FAIL T4: balance=15 slash, expected 15, got %0d", balance_out);
            fail = fail + 1;
        end
        invalid_pulse = 0;
        #2;

        // Test 5: balance=32, slash -> 32 - 2 = 30
        balance_in = 16'd32;
        invalid_pulse = 1;
        #2;
        if (balance_out !== 16'd30) begin
            $display("FAIL T5: balance=32 slash, expected 30, got %0d", balance_out);
            fail = fail + 1;
        end
        invalid_pulse = 0;
        #2;

        if (fail == 0)
            $display("PASS");
        else
            $display("FAIL: %0d error(s)", fail);

        $finish;
    end

endmodule

`default_nettype wire
