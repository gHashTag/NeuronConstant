// =============================================================================
// tb_afp.v — Testbench for afp.v (Adaptive Float-Point)
// =============================================================================
// Tests CONFIG changes affecting exp_size:
//   config=2'b010 → E=4 (IEEE half-like)
//   config=2'b011 → E=5 (bfloat-like)
//   config=2'b001 → E=3
// =============================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_afp;

    reg  [15:0] afp_in;
    reg  [2:0]  config_in;
    wire         sign_out;
    wire [7:0]   exp_out;
    wire [12:0]  frac_out;
    wire [3:0]   exp_bits, frac_bits;
    wire [7:0]   bias;
    wire signed [21:0] decoded_q813;
    wire         is_nan, is_inf, is_zero;

    afp dut (
        .afp_in      (afp_in),
        .config_in   (config_in),
        .sign_out    (sign_out),
        .exp_out     (exp_out),
        .frac_out    (frac_out),
        .exp_bits    (exp_bits),
        .frac_bits   (frac_bits),
        .bias        (bias),
        .decoded_q813(decoded_q813),
        .is_nan      (is_nan),
        .is_inf      (is_inf),
        .is_zero     (is_zero)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    task check_config;
        input [2:0]  cfg;
        input [3:0]  exp_e, exp_f;
        input [7:0]  exp_bias;
        input [7:0]  test_id;
        begin
            config_in = cfg;
            afp_in = 16'h0000;  // dummy input
            #1;
            if (exp_bits !== exp_e || frac_bits !== exp_f || bias !== exp_bias) begin
                $display("FAIL test %0d: cfg=%b exp_bits=%0d(exp %0d) frac_bits=%0d(exp %0d) bias=%0d(exp %0d)",
                    test_id, cfg, exp_bits, exp_e, frac_bits, exp_f, bias, exp_bias);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: cfg=%b E=%0d F=%0d bias=%0d", test_id, cfg, exp_bits, frac_bits, bias);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_sign;
        input [15:0] in_val;
        input [2:0]  cfg;
        input        exp_sign;
        input [7:0]  test_id;
        begin
            afp_in   = in_val;
            config_in = cfg;
            #1;
            if (sign_out !== exp_sign) begin
                $display("FAIL test %0d: afp=0x%04X cfg=%b sign=%b expected=%b",
                    test_id, in_val, cfg, sign_out, exp_sign);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: afp=0x%04X cfg=%b sign=%b", test_id, in_val, cfg, sign_out);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_special;
        input [15:0] in_val;
        input [2:0]  cfg;
        input        exp_zero, exp_inf, exp_nan;
        input [7:0]  test_id;
        begin
            afp_in   = in_val;
            config_in = cfg;
            #1;
            if (is_zero !== exp_zero || is_inf !== exp_inf || is_nan !== exp_nan) begin
                $display("FAIL test %0d: afp=0x%04X zero=%b(exp %b) inf=%b(exp %b) nan=%b(exp %b)",
                    test_id, in_val, is_zero, exp_zero, is_inf, exp_inf, is_nan, exp_nan);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS test %0d: afp=0x%04X zero=%b inf=%b nan=%b", test_id, in_val, is_zero, is_inf, is_nan);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== tb_afp ===");

        // Config decode tests
        // F = 15-E (total=1+E+F=16)
        // 3'b010 → E=4, F=11, bias=7
        check_config(3'b010, 4'd4, 4'd11, 8'd7,  8'd1);
        // 3'b011 → E=5, F=10, bias=15
        check_config(3'b011, 4'd5, 4'd10, 8'd15, 8'd2);
        // 3'b001 → E=3, F=12, bias=3
        check_config(3'b001, 4'd3, 4'd12, 8'd3,  8'd3);
        // 3'b000 → E=2, F=13, bias=1
        check_config(3'b000, 4'd2, 4'd13, 8'd1,  8'd4);
        // 3'b100 → E=6, F=9,  bias=31
        check_config(3'b100, 4'd6, 4'd9,  8'd31, 8'd5);
        // 3'b101 → E=7, F=8,  bias=63
        check_config(3'b101, 4'd7, 4'd8,  8'd63, 8'd6);
        // 3'b110 → E=8, F=7,  bias=127
        check_config(3'b110, 4'd8, 4'd7,  8'd127,8'd7);

        // Sign tests
        check_sign(16'h8000, 3'b010, 1'b1, 8'd8);  // negative
        check_sign(16'h0000, 3'b010, 1'b0, 8'd9);  // positive

        // Zero: exp=0, frac=0
        // Config=010 (E=4): exp at bits[14:11], zero bits = 0x0000
        check_special(16'h0000, 3'b010, 1'b1, 1'b0, 1'b0, 8'd10);

        // Infinity: exp=all-ones (for E=4: 0xF), frac=0
        // Bits[14:11] = 1111, bits[10:1] = 0 → 0b0 1111 0000000000 = 0x7800
        check_special(16'h7800, 3'b010, 1'b0, 1'b1, 1'b0, 8'd11);

        // NaN: exp=all-ones, frac≠0
        // 0b0 1111 0000000001 = 0x7801
        check_special(16'h7801, 3'b010, 1'b0, 1'b0, 1'b1, 8'd12);

        // Config change affects exp_bits dynamically
        begin
            afp_in = 16'h3C00; // some value
            config_in = 3'b010;
            #1;
            if (exp_bits === 4'd4) begin
                config_in = 3'b011;
                #1;
                if (exp_bits === 4'd5) begin
                    $display("PASS test 13: dynamic config change E=4->5");
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL test 13: config change to 011 gave E=%0d (expected 5)", exp_bits);
                    fail_count = fail_count + 1;
                end
            end else begin
                $display("FAIL test 13: config 010 gave E=%0d (expected 4)", exp_bits);
                fail_count = fail_count + 1;
            end
        end

        // Decoded Q8.13: 1.0 with E=4, bias=7, exp_field=7, frac=0
        // Layout E=4: bits[14:11]=0111, bits[10:1]=0 → 0b0 0111 0000000000 = 0x3800
        begin
            afp_in   = 16'h3800;
            config_in = 3'b010;
            #1;
            // 1.0 in Q8.13 (scale=8192) = 8192
            if (decoded_q813 === 22'sd8192) begin
                $display("PASS test 14: 1.0 decoded_q813=%0d", decoded_q813);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL test 14: 1.0 decoded_q813=%0d (expected 8192)", decoded_q813);
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
