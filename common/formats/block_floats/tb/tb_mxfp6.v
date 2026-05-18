// SPDX-License-Identifier: MIT
// Testbench: MXFP6 - both variants E2M3 and E3M2
`timescale 1ns/1ps
`default_nettype none

module tb_mxfp6;
    integer errors;

    // E2M3 decode
    reg  [5:0]  fp6_in;
    reg  [7:0]  block_exp;
    wire [15:0] dec_e2m3;
    wire [15:0] dec_e3m2;

    mxfp6_decode #(.VARIANT(0)) u_dec_e2m3 (
        .fp6_in    (fp6_in),
        .block_exp (block_exp),
        .result_q8 (dec_e2m3)
    );

    mxfp6_decode #(.VARIANT(1)) u_dec_e3m2 (
        .fp6_in    (fp6_in),
        .block_exp (block_exp),
        .result_q8 (dec_e3m2)
    );

    task check;
        input [127:0] name;
        input [15:0] got;
        input [15:0] expected;
        input [15:0] tol;
        begin
            if (got >= expected - tol && got <= expected + tol) begin
                $display("  PASS %0s: got=0x%04x exp=0x%04x", name, got, expected);
            end else begin
                $display("  FAIL %0s: got=0x%04x exp=0x%04x", name, got, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        $display("=== TB MXFP6 ===");

        // E2M3 variant (1S+2E+3M, bias=1)
        // Test: 1.0 = S=0, E=01, M=000 -> eff_exp=0, mant=1.0 -> 0x0100
        // fp6_in layout: [5]=S, [4:3]=E, [2:0]=M
        // S=0, E=01, M=000 -> {0,01,000} = 6'b001000
        block_exp = 8'd127;
        fp6_in    = 6'b001000; // S=0, E=01, M=000
        #10;
        check("E2M3_1.0", dec_e2m3, 16'h0100, 16'h0020);

        // E2M3: 1.5 = S=0, E=01, M=100 -> mant = 1 + 4/8 = 1.5 -> 0x0180
        fp6_in = 6'b000110; // S=0, E=01, M=100 -> bits [5:0]={0,01,100}={0,0,1,1,0,0} = 6'b001100
        // Wait: layout fp6_in[5]=S, fp6_in[4:3]=E, fp6_in[2:0]=M
        // 1.5: S=0, E=01, M=100 -> fp6_in = {0, 01, 100} = 6'b001100
        fp6_in = 6'b001100;
        #10;
        check("E2M3_1.5", dec_e2m3, 16'h0180, 16'h0020);

        // E2M3: 0.5 = S=0, E=01, M=000 with block_exp=126 -> eff=-1 -> 0x0080
        block_exp = 8'd126;
        fp6_in    = 6'b001000; // S=0, E=01, M=000
        #10;
        check("E2M3_0.5", dec_e2m3, 16'h0080, 16'h0020);

        // E2M3: zero (E=00)
        block_exp = 8'd127;
        fp6_in    = 6'b000000;
        #10;
        check("E2M3_zero", dec_e2m3, 16'h0000, 16'h0000);

        // E2M3: negative 1.0
        fp6_in = 6'b101000; // S=1, E=01, M=000 -> -1.0
        block_exp = 8'd127;
        #10;
        check("E2M3_-1.0", dec_e2m3, 16'hFF00, 16'h0020);

        $display("--- E3M2 variant ---");

        // E3M2 variant (1S+3E+2M, bias=3)
        // Test: 1.0 = S=0, E=011, M=00 -> eff_exp = 3-3 = 0 -> 1.0
        // fp6_in: [5]=S, [4:2]=E, [1:0]=M
        block_exp = 8'd127;
        fp6_in    = 6'b001100; // S=0, E=011, M=00
        #10;
        check("E3M2_1.0", dec_e3m2, 16'h0100, 16'h0020);

        // E3M2: 2.0 = S=0, E=100, M=00 -> eff_exp = 4-3 = 1 -> 2.0
        fp6_in = 6'b010000; // S=0, E=100, M=00
        #10;
        check("E3M2_2.0", dec_e3m2, 16'h0200, 16'h0020);

        // E3M2: 0.5 = S=0, E=010, M=00 -> eff_exp = 2-3 = -1 -> 0.5
        fp6_in = 6'b001000; // S=0, E=010, M=00
        // Wait: {0, 010, 00} = 6'b001000
        fp6_in = 6'b001000;
        block_exp = 8'd127;
        #10;
        check("E3M2_0.5", dec_e3m2, 16'h0080, 16'h0020);

        // E3M2: zero (E=000)
        fp6_in = 6'b000000;
        #10;
        check("E3M2_zero", dec_e3m2, 16'h0000, 16'h0000);

        if (errors == 0)
            $display("PASS: tb_mxfp6 all checks passed");
        else
            $display("FAIL: tb_mxfp6 %0d errors", errors);

        $finish;
    end
endmodule
`default_nettype wire
