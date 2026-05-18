// =============================================================================
// tb_unum_i16.v — Testbench for unum_i16
// =============================================================================
// Extended vectors for 16-bit Unum Type I.
// Layout: [15]=S [14:11]=EXP(4) [10:2]=FRAC(9) [1]=UBIT [0]=ES_META
// Bias = 7: exp=7 → actual=0 (value in [1,2))
// =============================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_unum_i16;

    reg  [15:0] unum16_in;
    wire         sign_out;
    wire [3:0]   exp_out;
    wire [8:0]   frac_out;
    wire         ubit_out;
    wire         es_out;
    wire signed [16:0] decoded_q89;
    wire signed [4:0]  actual_exp;
    wire [8:0]   lower_frac, upper_frac;
    wire [3:0]   lower_exp,  upper_exp;
    wire         is_zero, is_inf, is_nan, valid_out;

    unum_i16 dut (
        .unum16_in  (unum16_in),
        .sign_out   (sign_out),
        .exp_out    (exp_out),
        .frac_out   (frac_out),
        .ubit_out   (ubit_out),
        .es_out     (es_out),
        .decoded_q89(decoded_q89),
        .actual_exp (actual_exp),
        .lower_frac (lower_frac),
        .upper_frac (upper_frac),
        .lower_exp  (lower_exp),
        .upper_exp  (upper_exp),
        .is_zero    (is_zero),
        .is_inf     (is_inf),
        .is_nan     (is_nan),
        .valid_out  (valid_out)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    // Q8.9 scale = 512
    // 1.0 = 512, 0.5 = 256, 2.0 = 1024

    task check_decode;
        input [15:0]  in_val;
        input signed [16:0] expected_q89;
        input [7:0]   test_id;
        input integer tolerance;
        reg signed [16:0] diff;
        begin
            unum16_in = in_val;
            #1;
            diff = decoded_q89 - expected_q89;
            if (diff < 0) diff = -diff;
            if (diff > tolerance) begin
                $display("FAIL test %0d: unum=0x%04X decoded=%0d expected=%0d (diff=%0d > tol=%0d)",
                    test_id, in_val, decoded_q89, expected_q89, diff, tolerance);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: unum=0x%04X decoded=%0d (exp~%0d tol=%0d)",
                    test_id, in_val, decoded_q89, expected_q89, tolerance);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_field;
        input [15:0] in_val;
        input        exp_ubit;
        input        exp_sign;
        input [7:0]  test_id;
        begin
            unum16_in = in_val;
            #1;
            if (ubit_out !== exp_ubit || sign_out !== exp_sign) begin
                $display("FAIL test %0d: unum=0x%04X sign=%b(exp %b) ubit=%b(exp %b)",
                    test_id, in_val, sign_out, exp_sign, ubit_out, exp_ubit);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: unum=0x%04X sign=%b ubit=%b", test_id, in_val, sign_out, ubit_out);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_special;
        input [15:0] in_val;
        input        exp_zero, exp_inf, exp_nan;
        input [7:0]  test_id;
        begin
            unum16_in = in_val;
            #1;
            if (is_zero !== exp_zero || is_inf !== exp_inf || is_nan !== exp_nan) begin
                $display("FAIL test %0d: unum=0x%04X zero=%b(exp %b) inf=%b(exp %b) nan=%b(exp %b)",
                    test_id, in_val, is_zero, exp_zero, is_inf, exp_inf, is_nan, exp_nan);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: unum=0x%04X zero=%b inf=%b nan=%b", test_id, in_val, is_zero, is_inf, is_nan);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== tb_unum_i16 (Q8.9 scale=512) ===");

        // Layout: [15]=S [14:11]=EXP [10:2]=FRAC [1]=UBIT [0]=ES
        // exp bias = 7: exp_field=7 → actual_exp=0 → value in [1,2)
        //
        // 1.0: S=0, EXP=0111=7, FRAC=0_0000_0000=0, UBIT=0, ES=0
        // Bits: 0 0111 000000000 0 0 = 0x3800
        // 0011_1000_0000_0000 = 0x3800
        check_decode(16'h3800, 17'sd512,  8'd1, 1);  // 1.0 Q8.9=512

        // 0.5: exp=6 (actual=-1), frac=0
        // S=0, EXP=0110, FRAC=0, UBIT=0, ES=0
        // 0 0110 000000000 0 0 = 0x3000
        check_decode(16'h3000, 17'sd256,  8'd2, 1);  // 0.5 Q8.9=256

        // 2.0: exp=8 (actual=1), frac=0
        // S=0, EXP=1000, FRAC=0, UBIT=0, ES=0
        // 0 1000 000000000 0 0 = 0x4000
        check_decode(16'h4000, 17'sd1024, 8'd3, 1);  // 2.0 Q8.9=1024

        // -1.0: S=1, EXP=0111, FRAC=0, UBIT=0, ES=0
        // 1 0111 000000000 0 0 = 0xB800
        check_decode(16'hB800, -17'sd512, 8'd4, 1);  // -1.0 Q8.9=-512

        // 1.5: exp=7, frac=100000000 (0.5 added) → 1.1 binary = 1.5
        // S=0, EXP=0111, FRAC=100000000=0x100, UBIT=0, ES=0
        // 0 0111 100000000 0 0 = 0x3C00
        check_decode(16'h3C00, 17'sd768,  8'd5, 2);  // 1.5 Q8.9=768

        // ubit=1 (inexact): 1.0 + ubit set
        // 0x3800 | 0x0002 = 0x3802
        check_field(16'h3802, 1'b1, 1'b0, 8'd6);

        // ubit=0 (exact)
        check_field(16'h3800, 1'b0, 1'b0, 8'd7);

        // Zero: exp=0, frac=0, ubit=0
        check_special(16'h0000, 1'b1, 1'b0, 1'b0, 8'd8);

        // Infinity: exp=1111=15, frac=0
        // 0 1111 000000000 0 0 = 0x7800
        check_special(16'h7800, 1'b0, 1'b1, 1'b0, 8'd9);

        // NaN: exp=1111, frac≠0, ubit=1
        // 0 1111 111111111 1 0 = 0x7FFE
        check_special(16'h7FFE, 1'b0, 1'b0, 1'b1, 8'd10);

        // Bounds: ubit=1 at 1.0 → upper_frac = lower_frac + 1
        begin
            unum16_in = 16'h3802; // 1.0 with ubit=1
            #1;
            if (upper_frac == lower_frac + 9'd1 && upper_exp == lower_exp) begin
                $display("PASS test 11: bounds ULP: lower_frac=%0d upper_frac=%0d", lower_frac, upper_frac);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL test 11: bounds ULP: lower_frac=%0d upper_frac=%0d (expected +1)", lower_frac, upper_frac);
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
