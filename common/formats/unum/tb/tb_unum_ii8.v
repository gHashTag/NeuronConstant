// =============================================================================
// tb_unum_ii8.v — Testbench for unum_ii8
// =============================================================================
// Projective real line tests:
//   index=128 → 0.0 (is_zero=1)
//   index=192 → +1.0 (Q16.16 = 65536)
//   index= 64 → -1.0 (Q16.16 = -65536)
//   index=  0 → projective -∞ (is_inf=1)
// =============================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_unum_ii8;

    reg  [7:0]  index_in;
    wire         sign_out;
    wire         is_zero;
    wire         is_inf;
    wire signed [31:0] decoded_q1616;
    wire [7:0]  index_out;

    unum_ii8 dut (
        .index_in    (index_in),
        .sign_out    (sign_out),
        .is_zero     (is_zero),
        .is_inf      (is_inf),
        .decoded_q1616(decoded_q1616),
        .index_out   (index_out)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    // Q16.16 scale = 65536
    localparam SCALE = 65536;
    // 1 LSB tolerance
    localparam TOL = 1;

    task check_q1616;
        input [7:0] idx;
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
                $display("FAIL test %0d: index=%0d decoded=%0d expected=%0d (diff=%0d > tol=%0d)",
                    test_id, idx, decoded_q1616, expected, diff, tol);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: index=%0d decoded=%0d (exp=%0d)", test_id, idx, decoded_q1616, expected);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_flag;
        input [7:0]  idx;
        input        exp_zero, exp_inf, exp_sign;
        input [7:0]  test_id;
        begin
            index_in = idx;
            #1;
            if (is_zero !== exp_zero || is_inf !== exp_inf || sign_out !== exp_sign) begin
                $display("FAIL test %0d: index=%0d zero=%b(exp %b) inf=%b(exp %b) sign=%b(exp %b)",
                    test_id, idx, is_zero, exp_zero, is_inf, exp_inf, sign_out, exp_sign);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: index=%0d zero=%b inf=%b sign=%b", test_id, idx, is_zero, is_inf, sign_out);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== tb_unum_ii8 (Q16.16 scale=65536) ===");
        $display("Projective real line mapping: index 0..255 -> tan((i-128)/128 * pi/2)");

        // index=128 → 0.0
        check_q1616(8'd128, 32'sd0, 8'd1, 1);

        // index=128 → is_zero=1, sign irrelevant (it's 0)
        check_flag(8'd128, 1'b1, 1'b0, 1'b0, 8'd2);

        // index=192 → +1.0 (Q16.16=65536)
        // angle = (192-128)/128 * pi/2 = 64/128 * pi/2 = pi/4 → tan=1.0
        check_q1616(8'd192, 32'sd65536, 8'd3, TOL);

        // index=64 → -1.0 (Q16.16=-65536)
        // angle = (64-128)/128 * pi/2 = -64/128 * pi/2 = -pi/4 → tan=-1.0
        check_q1616(8'd64, -32'sd65536, 8'd4, TOL);

        // index=0 → projective -∞ (is_inf=1)
        check_flag(8'd0, 1'b0, 1'b1, 1'b1, 8'd5);

        // index=0 sign: negative half (MSB=0 → sign=1)
        begin
            index_in = 8'd0;
            #1;
            if (sign_out === 1'b1 && is_inf === 1'b1) begin
                $display("PASS test 6: index=0 is_inf=1 sign=1 (projective -inf)");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL test 6: index=0 sign=%b is_inf=%b", sign_out, is_inf);
                fail_count = fail_count + 1;
            end
        end

        // index=255 → large positive (near +∞)
        begin
            index_in = 8'd255;
            #1;
            if (decoded_q1616 > 32'sd0) begin
                $display("PASS test 7: index=255 large positive decoded=%0d", decoded_q1616);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL test 7: index=255 expected large positive, got %0d", decoded_q1616);
                fail_count = fail_count + 1;
            end
        end

        // index=1 → large negative (near -∞)
        begin
            index_in = 8'd1;
            #1;
            if (decoded_q1616 < 32'sd0) begin
                $display("PASS test 8: index=1 large negative decoded=%0d", decoded_q1616);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL test 8: index=1 expected large negative, got %0d", decoded_q1616);
                fail_count = fail_count + 1;
            end
        end

        // Monotonicity: decoded values should be monotonically increasing
        begin : mono_check
            reg signed [31:0] prev_val;
            integer i;
            integer mono_fail;
            mono_fail = 0;
            index_in = 8'd1; #1;
            prev_val = decoded_q1616;
            for (i = 2; i <= 255; i = i + 1) begin
                index_in = i; #1;
                if (decoded_q1616 < prev_val) begin
                    mono_fail = mono_fail + 1;
                end
                prev_val = decoded_q1616;
            end
            if (mono_fail == 0) begin
                $display("PASS test 9: monotonicity check (indices 1..255)");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL test 9: %0d monotonicity violations", mono_fail);
                fail_count = fail_count + 1;
            end
        end

        // index passthrough
        begin
            index_in = 8'hAB;
            #1;
            if (index_out === 8'hAB) begin
                $display("PASS test 10: passthrough index_out=0x%02X", index_out);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL test 10: passthrough index_out=0x%02X expected 0xAB", index_out);
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
