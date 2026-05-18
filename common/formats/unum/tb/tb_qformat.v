// =============================================================================
// tb_qformat.v — Testbench for qformat_generic.v (Q-format)
// =============================================================================
// Tests:
//   1. Q15 addition
//   2. Q7  addition
//   3. Q15 multiplication (shift-add, R-SI-1 compliant)
//   4. Q7  multiplication
//   5. Overflow saturation
//   6. Negative values
// =============================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_qformat;

    // --- Q15 (TOTAL=16, Q_FRAC=15) add ---
    reg  signed [15:0] qa15_a, qa15_b;
    wire signed [15:0] qs15_sum;
    wire               qs15_ovf;

    qformat_add #(.TOTAL_BITS(16), .Q_FRAC_BITS(15)) u_add15 (
        .a_in    (qa15_a),
        .b_in    (qa15_b),
        .sum_out (qs15_sum),
        .overflow(qs15_ovf)
    );

    // --- Q7 (TOTAL=8, Q_FRAC=7) add ---
    reg  signed [7:0]  qa7_a, qa7_b;
    wire signed [7:0]  qs7_sum;
    wire               qs7_ovf;

    qformat_add #(.TOTAL_BITS(8), .Q_FRAC_BITS(7)) u_add7 (
        .a_in    (qa7_a),
        .b_in    (qa7_b),
        .sum_out (qs7_sum),
        .overflow(qs7_ovf)
    );

    // --- Q15 mul ---
    reg  signed [15:0] qm15_a, qm15_b;
    wire signed [15:0] qp15_out;
    wire               qp15_ovf;

    qformat_mul16 #(.TOTAL_BITS(16), .Q_FRAC_BITS(15)) u_mul15 (
        .a_in    (qm15_a),
        .b_in    (qm15_b),
        .prod_out(qp15_out),
        .overflow(qp15_ovf)
    );

    // --- Q7 mul ---
    reg  signed [7:0]  qm7_a, qm7_b;
    wire signed [7:0]  qp7_out;
    wire               qp7_ovf;

    qformat_mul8 #(.TOTAL_BITS(8), .Q_FRAC_BITS(7)) u_mul7 (
        .a_in    (qm7_a),
        .b_in    (qm7_b),
        .prod_out(qp7_out),
        .overflow(qp7_ovf)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    // Q15 scale = 32768 (2^15)
    // Q7  scale = 128   (2^7)

    // Check Q15 add
    task check_add15;
        input signed [15:0] a, b;
        input signed [15:0] expected;
        input [7:0]  test_id;
        input        exp_ovf;
        begin
            qa15_a = a; qa15_b = b;
            #1;
            if (qs15_sum !== expected || qs15_ovf !== exp_ovf) begin
                $display("FAIL test %0d: Q15 add %0d+%0d = %0d (exp %0d) ovf=%b(exp %b)",
                    test_id, a, b, qs15_sum, expected, qs15_ovf, exp_ovf);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: Q15 add %0d+%0d=%0d", test_id, a, b, qs15_sum);
                pass_count = pass_count + 1;
            end
        end
    endtask

    // Check Q7 add
    task check_add7;
        input signed [7:0] a, b;
        input signed [7:0] expected;
        input [7:0]  test_id;
        input        exp_ovf;
        begin
            qa7_a = a; qa7_b = b;
            #1;
            if (qs7_sum !== expected || qs7_ovf !== exp_ovf) begin
                $display("FAIL test %0d: Q7 add %0d+%0d = %0d (exp %0d) ovf=%b(exp %b)",
                    test_id, a, b, qs7_sum, expected, qs7_ovf, exp_ovf);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: Q7 add %0d+%0d=%0d", test_id, a, b, qs7_sum);
                pass_count = pass_count + 1;
            end
        end
    endtask

    // Check Q15 mul (tolerance)
    task check_mul15;
        input signed [15:0] a, b;
        input signed [15:0] expected;
        input [7:0]  test_id;
        input integer tol;
        reg signed [15:0] diff;
        begin
            qm15_a = a; qm15_b = b;
            #1;
            diff = qp15_out - expected;
            if (diff < 0) diff = -diff;
            if (diff > tol) begin
                $display("FAIL test %0d: Q15 mul %0d*%0d = %0d (exp %0d, diff=%0d > tol=%0d)",
                    test_id, a, b, qp15_out, expected, diff, tol);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: Q15 mul %0d*%0d = %0d (exp~%0d)", test_id, a, b, qp15_out, expected);
                pass_count = pass_count + 1;
            end
        end
    endtask

    // Check Q7 mul (tolerance)
    task check_mul7;
        input signed [7:0] a, b;
        input signed [7:0] expected;
        input [7:0] test_id;
        input integer tol;
        reg signed [7:0] diff;
        begin
            qm7_a = a; qm7_b = b;
            #1;
            diff = qp7_out - expected;
            if (diff < 0) diff = -diff;
            if (diff > tol) begin
                $display("FAIL test %0d: Q7 mul %0d*%0d = %0d (exp %0d, diff=%0d > tol=%0d)",
                    test_id, a, b, qp7_out, expected, diff, tol);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: Q7 mul %0d*%0d = %0d (exp~%0d)", test_id, a, b, qp7_out, expected);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== tb_qformat ===");
        $display("Q15: scale=32768, Q7: scale=128");

        // --- Q15 Addition tests ---
        // 0.5 + 0.5 = 1.0: Q15: 16384 + 16384 = 32767 (saturated at max)
        // Actually: 0.5 in Q15 = 16384 (0x4000). 1.0 in Q15 = 32767 (0x7FFF, max positive)
        // 16384 + 16384 = 32768 → overflow → saturate to 32767
        check_add15(16'sd16384, 16'sd16384, 16'sd32767, 8'd1, 1'b1); // overflow to max

        // 0.25 + 0.25 = 0.5: 8192 + 8192 = 16384
        check_add15(16'sd8192,  16'sd8192,  16'sd16384, 8'd2, 1'b0);

        // 0.0 + 0.5 = 0.5
        check_add15(16'sd0,     16'sd16384, 16'sd16384, 8'd3, 1'b0);

        // -0.5 + 0.5 = 0.0: -16384 + 16384 = 0
        check_add15(-16'sd16384, 16'sd16384, 16'sd0, 8'd4, 1'b0);

        // --- Q7 Addition tests ---
        // 0.5 + 0.5: Q7: 64 + 64 = 128 → saturate to 127
        check_add7(8'sd64, 8'sd64, 8'sd127, 8'd5, 1'b1);

        // 0.25 + 0.25 = 0.5: 32 + 32 = 64
        check_add7(8'sd32, 8'sd32, 8'sd64, 8'd6, 1'b0);

        // -1 + 1 = 0: -128 + 0 is -128, but Q7: -1 = -128 (min)
        // -0.5 + 0.5 = 0: -64 + 64 = 0
        check_add7(-8'sd64, 8'sd64, 8'sd0, 8'd7, 1'b0);

        // --- Q15 Multiply tests ---
        // 0.5 * 0.5 = 0.25: Q15: 16384 * 16384 >> 15 = 8192
        check_mul15(16'sd16384, 16'sd16384, 16'sd8192, 8'd8, 1); // ±1 LSB

        // 0.5 * 1.0 → but 1.0 = 32767 in Q15
        // 16384 * 32767 >> 15 ≈ 16383 (0.5 * 1.0 ≈ 0.5)
        check_mul15(16'sd16384, 16'sd32767, 16'sd16383, 8'd9, 2);

        // 0.25 * 0.5 = 0.125: 8192 * 16384 >> 15 = 4096
        check_mul15(16'sd8192,  16'sd16384, 16'sd4096,  8'd10, 1);

        // -0.5 * 0.5 = -0.25: -16384 * 16384 >> 15 = -8192
        check_mul15(-16'sd16384, 16'sd16384, -16'sd8192, 8'd11, 1);

        // --- Q7 Multiply tests ---
        // 0.5 * 0.5 = 0.25: Q7: 64 * 64 >> 7 = 32
        check_mul7(8'sd64, 8'sd64, 8'sd32, 8'd12, 1);

        // 0.25 * 0.5 = 0.125: 32 * 64 >> 7 = 16
        check_mul7(8'sd32, 8'sd64, 8'sd16, 8'd13, 1);

        // -0.5 * 0.5 = -0.25: -64 * 64 >> 7 = -32
        check_mul7(-8'sd64, 8'sd64, -8'sd32, 8'd14, 1);

        // 0 * anything = 0
        check_mul7(8'sd0, 8'sd64, 8'sd0, 8'd15, 0);

        $display("=== Results: PASS=%0d FAIL=%0d ===", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL PASS");
        else
            $display("SOME FAILURES");
        $finish;
    end

endmodule

`default_nettype wire
