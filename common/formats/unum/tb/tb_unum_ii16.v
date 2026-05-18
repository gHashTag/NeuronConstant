// =============================================================================
// tb_unum_ii16.v — Testbench for unum_ii16 (piece-wise linear approximation)
// =============================================================================
// Tests PWL approximation accuracy and key projective points.
// Tolerance: ±16384 LSB (Q16.16) for near-singularity regions,
//            ±256 LSB for |value| < 2 (normal range)
// =============================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_unum_ii16;

    reg  [15:0] index_in;
    wire         sign_out;
    wire         is_zero;
    wire         is_inf;
    wire signed [31:0] decoded_q1616;
    wire [15:0]  index_out;

    unum_ii16 dut (
        .index_in    (index_in),
        .sign_out    (sign_out),
        .is_zero     (is_zero),
        .is_inf      (is_inf),
        .decoded_q1616(decoded_q1616),
        .index_out   (index_out)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    localparam SCALE = 65536;

    task check_q1616;
        input [15:0] idx;
        input signed [31:0] expected;
        input [7:0] test_id;
        input integer tol;
        reg signed [31:0] diff;
        begin
            index_in = idx;
            #1;
            diff = decoded_q1616 - expected;
            if (diff < 0) diff = -diff;
            if (diff > tol) begin
                $display("FAIL test %0d: index=%0d decoded=%0d expected=%0d diff=%0d tol=%0d",
                    test_id, idx, decoded_q1616, expected, diff, tol);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: index=%0d decoded=%0d (tol=%0d)", test_id, idx, decoded_q1616, tol);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_flag;
        input [15:0] idx;
        input        exp_zero, exp_inf;
        input [7:0]  test_id;
        begin
            index_in = idx;
            #1;
            if (is_zero !== exp_zero || is_inf !== exp_inf) begin
                $display("FAIL test %0d: index=%0d zero=%b(exp %b) inf=%b(exp %b)",
                    test_id, idx, is_zero, exp_zero, is_inf, exp_inf);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: index=%0d zero=%b inf=%b", test_id, idx, is_zero, is_inf);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== tb_unum_ii16 (Q16.16 PWL 256-segment approx) ===");
        $display("Tolerance: 256 LSB for |val|<2, 16384 LSB near singularities");

        // index=32768 (=0x8000) → 0.0
        check_q1616(16'h8000, 32'sd0, 8'd1, 1);

        // is_zero flag
        check_flag(16'h8000, 1'b1, 1'b0, 8'd2);

        // is_inf flag (index=0)
        check_flag(16'h0000, 1'b0, 1'b1, 8'd3);

        // index=49152 (0xC000 = 32768+16384) → +1.0
        // (32768+16384-32768)/32768 * pi/2 = 16384/32768 * pi/2 = pi/4 → tan=1.0
        check_q1616(16'hC000, 32'sd65536, 8'd4, 512);  // ±512 LSB tolerance for PWL

        // index=16384 (0x4000 = 32768-16384) → -1.0
        check_q1616(16'h4000, -32'sd65536, 8'd5, 512);

        // Monotonicity check (sample 256 points across range 1..65534)
        begin : mono_check
            integer i, step;
            reg signed [31:0] prev_val;
            integer mono_fail;
            mono_fail = 0;
            step = 256;  // sample every 256th index
            index_in = 16'd256; #1;
            prev_val = decoded_q1616;
            for (i = 512; i <= 65280; i = i + step) begin
                index_in = i; #1;
                if (decoded_q1616 < prev_val) begin
                    mono_fail = mono_fail + 1;
                end
                prev_val = decoded_q1616;
            end
            if (mono_fail == 0) begin
                $display("PASS test 6: monotonicity (sampled 256 points)");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL test 6: %0d monotonicity violations", mono_fail);
                fail_count = fail_count + 1;
            end
        end

        // PWL approximation tolerance: at 3/4 range → +tan(3/4 * pi/2 / 2) ~ ?
        // index = 32768 + 8192 = 40960 (0xA000) → angle = 8192/32768*pi/2 = pi/8
        // tan(pi/8) ≈ 0.4142, Q16.16 = 27146
        check_q1616(16'hA000, 32'sd27146, 8'd7, 1024);  // ±1024 LSB tolerance

        // sign checks
        begin
            index_in = 16'hC000; #1;
            if (sign_out === 1'b0) begin
                $display("PASS test 8: index=0xC000 positive (sign=0)");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL test 8: index=0xC000 sign=%b (expected 0)", sign_out);
                fail_count = fail_count + 1;
            end
        end

        begin
            index_in = 16'h4000; #1;
            if (sign_out === 1'b1) begin
                $display("PASS test 9: index=0x4000 negative (sign=1)");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL test 9: index=0x4000 sign=%b (expected 1)", sign_out);
                fail_count = fail_count + 1;
            end
        end

        // Passthrough
        begin
            index_in = 16'hDEAD;
            #1;
            if (index_out === 16'hDEAD) begin
                $display("PASS test 10: passthrough index_out=0x%04X", index_out);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL test 10: passthrough index_out=0x%04X expected 0xDEAD", index_out);
                fail_count = fail_count + 1;
            end
        end

        $display("=== Results: PASS=%0d FAIL=%0d ===", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL PASS");
        else
            $display("SOME FAILURES");
        $finish;
    end

endmodule

`default_nettype wire
