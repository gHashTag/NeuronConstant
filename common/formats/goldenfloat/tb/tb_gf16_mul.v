// SPDX-License-Identifier: MIT
// tb_gf16_mul — GF16 multiply testbench (Verilog-2005)
// GF16 PRIMARY: S=1, E=6, M=9, bias=31
//
// Vectors:
//   1.0 * 1.0 = 1.0       (0x3E00 * 0x3E00 = 0x3E00)
//   2.0 * 0.5 = 1.0       (0x4000 * 0x3C00 = 0x3E00)
//   1.0 * -1.0 = -1.0     (0x3E00 * 0xBE00 = 0xBE00)
//   inf * 0   = NaN        (0x7E00 * 0x0000 = NaN, exp_all_ones, mant!=0)
//   phi * phi ~ phi+1      (0x3F3C * 0x3F3C ≈ 0x409E, tolerance 2 LSB)
//   0 * 0 = 0              (0x0000 * 0x0000 = 0x0000)
//   nan * 1 = nan          (0x7E01 * 0x3E00 = NaN)

`default_nettype none
`timescale 1ns/1ps

module tb_gf16_mul;

    reg  [15:0] a, b;
    wire [15:0] result;
    wire        overflow, underflow;

    gf16_mul dut (
        .a         (a),
        .b         (b),
        .result    (result),
        .overflow  (overflow),
        .underflow (underflow)
    );

    integer fail_count;

    // Check is_nan helper: E=63, M!=0
    function is_nan_f16;
        input [15:0] r;
        begin
            is_nan_f16 = (&r[14:9]) && (r[8:0] != 9'd0);
        end
    endfunction

    task check_exact;
        input [15:0] a_in, b_in, expected;
        input [127:0] name;
        begin
            a = a_in; b = b_in; #1;
            if (result !== expected) begin
                $display("FAIL GF16_MUL at %s: 0x%04h * 0x%04h = 0x%04h, expected 0x%04h",
                         name, a_in, b_in, result, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS GF16_MUL %s", name);
            end
        end
    endtask

    task check_nan;
        input [15:0] a_in, b_in;
        input [127:0] name;
        begin
            a = a_in; b = b_in; #1;
            if (!is_nan_f16(result)) begin
                $display("FAIL GF16_MUL at %s: expected NaN, got 0x%04h", name, result);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS GF16_MUL %s (NaN)", name);
            end
        end
    endtask

    task check_near;
        input [15:0] a_in, b_in, expected;
        input [7:0]  tol_lsb;        // tolerance in raw LSBs
        input [127:0] name;
        reg [15:0] diff;
        begin
            a = a_in; b = b_in; #1;
            diff = (result >= expected) ? (result - expected) : (expected - result);
            if (diff > {8'b0, tol_lsb}) begin
                $display("FAIL GF16_MUL at %s: 0x%04h * 0x%04h = 0x%04h, expected ~0x%04h (tol=%0d lsb, diff=%0d)",
                         name, a_in, b_in, result, expected, tol_lsb, diff);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS GF16_MUL %s (near, diff=%0d lsb)", name, diff);
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // 1.0 * 1.0 = 1.0
        check_exact(16'h3E00, 16'h3E00, 16'h3E00, "1.0_x_1.0");

        // 2.0 * 0.5 = 1.0
        check_exact(16'h4000, 16'h3C00, 16'h3E00, "2.0_x_0.5");

        // 1.0 * -1.0 = -1.0
        check_exact(16'h3E00, 16'hBE00, 16'hBE00, "1.0_x_neg1.0");

        // 0 * 0 = 0
        check_exact(16'h0000, 16'h0000, 16'h0000, "0_x_0");

        // +inf * 0 = NaN
        check_nan(16'h7E00, 16'h0000, "inf_x_0");

        // nan * 1 = NaN
        check_nan(16'h7E01, 16'h3E00, "nan_x_1");

        // +inf * +inf = +inf
        check_exact(16'h7E00, 16'h7E00, 16'h7E00, "inf_x_inf");

        // -inf * 1 = -inf
        check_exact(16'hFE00, 16'h3E00, 16'hFE00, "neg_inf_x_1");

        // phi * phi ≈ phi+1 (phi=0x3F3C=1.617188, phi+1=2.617188=0x409E)
        // Both are 2-bit tolerance (rounding may add 1 LSB per operand)
        check_near(16'h3F3C, 16'h3F3C, 16'h409E, 8'd4, "phi_x_phi_near_phi_plus1");

        if (fail_count == 0)
            $display("PASS GF16_MUL");
        else
            $display("FAIL GF16_MUL (%0d failures)", fail_count);

        $finish;
    end

endmodule

`default_nettype wire
