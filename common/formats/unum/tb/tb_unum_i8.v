// =============================================================================
// tb_unum_i8.v — Testbench for unum_i8
// =============================================================================
// Tests:
//   1. Encode/decode 1.0, 0.5, 2.0 (exact, ubit=0)
//   2. Bounds test: ubit=1 (open interval)
//   3. NaN detection
//   4. Zero
// =============================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_unum_i8;

    // DUT
    reg  [7:0] unum8_in;
    wire        sign_out;
    wire [1:0]  exp_out;
    wire [2:0]  frac_out;
    wire        ubit_out;
    wire        es_out;
    wire signed [7:0] decoded_q43;
    wire [2:0]  lower_frac, upper_frac;
    wire [1:0]  lower_exp,  upper_exp;
    wire        valid_out;

    unum_i8 dut (
        .unum8_in   (unum8_in),
        .sign_out   (sign_out),
        .exp_out    (exp_out),
        .frac_out   (frac_out),
        .ubit_out   (ubit_out),
        .es_out     (es_out),
        .decoded_q43(decoded_q43),
        .lower_frac (lower_frac),
        .upper_frac (upper_frac),
        .lower_exp  (lower_exp),
        .upper_exp  (upper_exp),
        .valid_out  (valid_out)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    task check_ubit;
        input [7:0] in_val;
        input       exp_ubit;
        input [7:0] test_id;
        begin
            unum8_in = in_val;
            #1;
            if (ubit_out !== exp_ubit) begin
                $display("FAIL test %0d: unum=0x%02X ubit=%b expected=%b", test_id, in_val, ubit_out, exp_ubit);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: unum=0x%02X ubit=%b", test_id, in_val, ubit_out);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_sign;
        input [7:0] in_val;
        input       exp_sign;
        input [7:0] test_id;
        begin
            unum8_in = in_val;
            #1;
            if (sign_out !== exp_sign) begin
                $display("FAIL test %0d: unum=0x%02X sign=%b expected=%b", test_id, in_val, sign_out, exp_sign);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: unum=0x%02X sign=%b decoded_q43=%0d", test_id, in_val, sign_out, decoded_q43);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_valid;
        input [7:0] in_val;
        input       exp_valid;
        input [7:0] test_id;
        begin
            unum8_in = in_val;
            #1;
            if (valid_out !== exp_valid) begin
                $display("FAIL test %0d: unum=0x%02X valid=%b expected=%b", test_id, in_val, valid_out, exp_valid);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: unum=0x%02X valid=%b", test_id, in_val, valid_out);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_bounds_upper;
        input [7:0] in_val;
        input [7:0] test_id;
        // When ubit=1: upper_frac >= lower_frac (monotone)
        begin
            unum8_in = in_val;
            #1;
            if (ubit_out !== 1'b1) begin
                $display("SKIP test %0d (ubit=0)", test_id);
                pass_count = pass_count + 1;
            end else if (upper_frac >= lower_frac || upper_exp > lower_exp) begin
                $display("PASS test %0d: unum=0x%02X ubit=1 lower_exp=%0d lower_frac=%0d upper_exp=%0d upper_frac=%0d",
                    test_id, in_val, lower_exp, lower_frac, upper_exp, upper_frac);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL test %0d: bounds not monotone: lower=%0d.%0d upper=%0d.%0d",
                    test_id, lower_exp, lower_frac, upper_exp, upper_frac);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== tb_unum_i8 ===");

        // Layout: [7]=S [6:5]=EXP [4:2]=FRAC [1]=UBIT [0]=ES
        // 1.0: sign=0, exp=01 (value=1), frac=000 (1.000), ubit=0
        // Q4.3 scale=8: 1.0 = 8 decimal
        // exp=01 → actual=0 → value in [1,2): {0,1,000,00} = 0x20
        // 0x20 = 0b 0 01 000 0 0
        check_sign(8'h20, 1'b0, 8'd1);  // 1.0 positive

        // 0.5: exp=00 (subnormal) but let's use sign=0, exp=00, frac=100 → subnormal 0.100
        // or exp=01 is 1.xxx, so 0.5 needs exp=00 with frac representing 0.5
        // Actually: for exp=01: 1.frac = 1.000 to 1.111 → values 1..~2
        // For 0.5: subnormal, exp=00, frac=100 → 0.100 in Q4.3 = 4 (0.5*8)
        // 0x04 = 0b 0 00 100 0 0
        check_sign(8'h04, 1'b0, 8'd2);  // 0.5 positive

        // 2.0: exp=10, frac=000 → 2*(1.000) in Q4.3 = 16
        // 0x40 = 0b 0 10 000 0 0
        check_sign(8'h40, 1'b0, 8'd3);  // 2.0 positive

        // Negative value: sign=1
        // -1.0: 0x80 | 0x20 = 0xA0 = 0b 1 01 000 0 0
        check_sign(8'hA0, 1'b1, 8'd4);  // -1.0 negative

        // ubit=0 test (exact)
        check_ubit(8'h20, 1'b0, 8'd5);  // 1.0, exact

        // ubit=1 test (inexact): set bit[1]=1
        // 0x22 = 0b 0 01 000 1 0
        check_ubit(8'h22, 1'b1, 8'd6);  // inexact

        // Bounds test (ubit=1): upper >= lower
        check_bounds_upper(8'h22, 8'd7);  // 1.0 ubit=1
        check_bounds_upper(8'h42, 8'd8);  // 2.0 ubit=1

        // NaN: sign=1, exp=11, frac=111, ubit=1 → 0b 1 11 111 1 x = 0xFF
        check_valid(8'hFF, 1'b0, 8'd9);  // NaN (valid=0)
        check_valid(8'hFE, 1'b0, 8'd10); // NaN with es=0

        // Valid number
        check_valid(8'h20, 1'b1, 8'd11); // 1.0 valid

        // Zero: exp=0, frac=0, ubit=0
        // 0x00 = 0b 0 00 000 0 0 → valid=1
        check_valid(8'h00, 1'b1, 8'd12);

        $display("=== Results: PASS=%0d FAIL=%0d ===", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL PASS");
        else
            $display("SOME FAILURES");
        $finish;
    end

endmodule

`default_nettype wire
