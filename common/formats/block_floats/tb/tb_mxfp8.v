// SPDX-License-Identifier: MIT
// Testbench: MXFP8 - E4M3 and E5M2 variants
`timescale 1ns/1ps
`default_nettype none

module tb_mxfp8;
    integer errors;

    reg  [7:0]  fp8_in;
    reg  [7:0]  block_exp;
    wire [15:0] dec_e4m3;
    wire [15:0] dec_e5m2;

    mxfp8_decode #(.VARIANT(0)) u_e4m3 (
        .fp8_in    (fp8_in),
        .block_exp (block_exp),
        .result_q8 (dec_e4m3)
    );

    mxfp8_decode #(.VARIANT(1)) u_e5m2 (
        .fp8_in    (fp8_in),
        .block_exp (block_exp),
        .result_q8 (dec_e5m2)
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
        $display("=== TB MXFP8 ===");

        // ---- E4M3 (bias=7) ----
        // 1.0: S=0, E=0111 (=7, eff=0), M=000 -> fp8={0, 0111, 000} = 8'h38
        block_exp = 8'd127;
        fp8_in    = 8'h38; // 0_0111_000
        #10;
        check("E4M3_1.0", dec_e4m3, 16'h0100, 16'h0020);

        // 2.0: S=0, E=1000 (=8, eff=1), M=000 -> fp8={0, 1000, 000} = 8'h40
        fp8_in = 8'h40;
        #10;
        check("E4M3_2.0", dec_e4m3, 16'h0200, 16'h0020);

        // 0.5: S=0, E=0110 (=6, eff=-1), M=000 -> fp8={0, 0110, 000} = 8'h30
        fp8_in = 8'h30;
        #10;
        check("E4M3_0.5", dec_e4m3, 16'h0080, 16'h0020);

        // -1.0: S=1, E=0111, M=000 = 8'hB8
        fp8_in = 8'hB8;
        #10;
        check("E4M3_-1.0", dec_e4m3, 16'hFF00, 16'h0020);

        // zero (E=0000)
        fp8_in = 8'h00;
        #10;
        check("E4M3_zero", dec_e4m3, 16'h0000, 16'h0000);

        // 1.5: S=0, E=0111, M=100 -> fp8={0,0111,100} = 8'h3C
        fp8_in = 8'h3C;
        #10;
        check("E4M3_1.5", dec_e4m3, 16'h0180, 16'h0020);

        $display("--- E5M2 ---");

        // ---- E5M2 (bias=15) ----
        // 1.0: S=0, E=01111 (=15, eff=0), M=00 -> fp8={0,01111,00} = 8'h3C
        fp8_in = 8'h3C;
        #10;
        check("E5M2_1.0", dec_e5m2, 16'h0100, 16'h0020);

        // 2.0: S=0, E=10000 (=16, eff=1), M=00 -> fp8={0,10000,00} = 8'h40
        fp8_in = 8'h40;
        #10;
        check("E5M2_2.0", dec_e5m2, 16'h0200, 16'h0020);

        // 0.5: S=0, E=01110 (=14, eff=-1), M=00 -> fp8={0,01110,00} = 8'h38
        fp8_in = 8'h38;
        #10;
        check("E5M2_0.5", dec_e5m2, 16'h0080, 16'h0020);

        // zero
        fp8_in = 8'h00;
        #10;
        check("E5M2_zero", dec_e5m2, 16'h0000, 16'h0000);

        if (errors == 0)
            $display("PASS: tb_mxfp8 all checks passed");
        else
            $display("FAIL: tb_mxfp8 %0d errors", errors);

        $finish;
    end
endmodule
`default_nettype wire
