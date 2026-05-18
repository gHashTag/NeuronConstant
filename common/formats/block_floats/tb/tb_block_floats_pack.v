// SPDX-License-Identifier: MIT
// Testbench: block_floats_pack - round-trip each format
`timescale 1ns/1ps
`default_nettype none

module tb_block_floats_pack;
    integer errors;

    reg  [3:0]   format_id;
    reg  [255:0] data_in;
    reg  [7:0]   block_exp;
    reg  [31:0]  operand_b;
    wire [15:0]  result_out;
    wire [7:0]   lns_result;
    wire [31:0]  q31_result;

    block_floats_pack u_pack (
        .format_id  (format_id),
        .data_in    (data_in),
        .block_exp  (block_exp),
        .operand_b  (operand_b),
        .result_out (result_out),
        .lns_result (lns_result),
        .q31_result (q31_result)
    );

    task check16;
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
        $display("=== TB BLOCK_FLOATS_PACK ===");

        block_exp = 8'd127;
        operand_b = 32'h4000; // 0.5 in Q0.15 for Q15 test
        data_in   = 256'h0;

        // Format 0: MXFP4 - decode 1.0
        // FP4: S=0, E=01, M=0 = 4'b0010 = 0x2
        format_id          = 4'd0;
        data_in[3:0]       = 4'b0010;
        block_exp          = 8'd127;
        #10;
        check16("FMT0_MXFP4_1.0", result_out, 16'h0100, 16'h0020);

        // Format 1: MXFP6 E2M3 - decode 1.0
        // FP6 E2M3: S=0, E=01, M=000 = 6'b001000 = 0x08
        format_id    = 4'd1;
        data_in[5:0] = 6'b001000;
        block_exp    = 8'd127;
        #10;
        check16("FMT1_MXFP6_E2M3_1.0", result_out, 16'h0100, 16'h0030);

        // Format 2: MXFP6 E3M2 - decode 1.0
        // FP6 E3M2: S=0, E=011, M=00 = 6'b001100
        format_id    = 4'd2;
        data_in[5:0] = 6'b001100;
        block_exp    = 8'd127;
        #10;
        check16("FMT2_MXFP6_E3M2_1.0", result_out, 16'h0100, 16'h0030);

        // Format 3: MXFP8 E4M3 - decode 1.0
        // FP8 E4M3: 0_0111_000 = 0x38
        format_id    = 4'd3;
        data_in[7:0] = 8'h38;
        block_exp    = 8'd127;
        #10;
        check16("FMT3_MXFP8_E4M3_1.0", result_out, 16'h0100, 16'h0020);

        // Format 4: MXFP8 E5M2 - decode 1.0
        // FP8 E5M2: 0_01111_00 = 0x3C
        format_id    = 4'd4;
        data_in[7:0] = 8'h3C;
        block_exp    = 8'd127;
        #10;
        check16("FMT4_MXFP8_E5M2_1.0", result_out, 16'h0100, 16'h0020);

        // Format 5: LNS8 - decode ~1.0
        // LNS8: sign=0, log_idx=48 -> 1.0
        format_id    = 4'd5;
        data_in[7:0] = 8'h30; // log_idx=48
        block_exp    = 8'd0;
        #10;
        check16("FMT5_LNS8_1.0", result_out, 16'h0100, 16'h0030);

        // Format 6: Q15 multiply - 0.5 * 0.5 = 0.25
        format_id     = 4'd6;
        data_in[15:0] = 16'h4000; // 0.5 in Q0.15
        operand_b     = 32'h00004000; // 0.5 in Q0.15 (lower 16 bits)
        #10;
        check16("FMT6_Q15_0.5x0.5=0.25", result_out, 16'h2000, 16'h0100);

        // Format 7: Q31 multiply - 0.5 * 0.5 = 0.25
        format_id     = 4'd7;
        data_in[31:0] = 32'h40000000; // 0.5 Q0.31
        operand_b     = 32'h40000000;
        #10;
        $display("  INFO FMT7_Q31_full: q31_result=0x%08x (exp ~0x20000000)", q31_result);
        $display("  INFO FMT7_Q31_lower16: result_out=0x%04x", result_out);
        if (q31_result >= 32'h10000000 && q31_result <= 32'h30000000) begin
            $display("  PASS FMT7_Q31_range");
        end else begin
            $display("  FAIL FMT7_Q31_range: 0x%08x out of [0x10000000, 0x30000000]", q31_result);
            errors = errors + 1;
        end

        // Format 8: StochRound - integer part passthrough
        format_id     = 4'd8;
        data_in[31:0] = 32'h42000000; // upper 8 bits = 0x42, frac=0
        block_exp     = 8'd01; // non-zero seed
        #10;
        $display("  INFO FMT8_SR: result_out=0x%04x (lower 8 = 0x%02x, exp ~0x42)",
                 result_out, result_out[7:0]);
        if (result_out[7:0] == 8'h42 || result_out[7:0] == 8'h43) begin
            $display("  PASS FMT8_StochRound");
        end else begin
            $display("  FAIL FMT8_StochRound: got 0x%02x (expected 0x42 or 0x43)", result_out[7:0]);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: tb_block_floats_pack all checks passed");
        else
            $display("FAIL: tb_block_floats_pack %0d errors", errors);

        $finish;
    end
endmodule
`default_nettype wire
