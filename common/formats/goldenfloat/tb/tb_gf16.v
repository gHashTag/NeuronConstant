// SPDX-License-Identifier: MIT
// tb_gf16 — GF16 decode testbench (Verilog-2005)
// GF16 PRIMARY: S=1, E=6, M=9, bias=31
// value = (-1)^S * 2^(E-31) * (1 + M/512)  [normal]
//
// Known vectors (t27 conformance + manual):
//   zero_positive : 0x0000 → is_zero=1
//   one_point_zero: 0x3E00 → S=0, E=31, M=0, dec=1.0
//   two           : 0x4000 → S=0, E=32, M=0, dec=2.0
//   half          : 0x3C00 → S=0, E=30, M=0, dec=0.5
//   neg_one       : 0xBE00 → S=1, E=31, M=0, dec=-1.0
//   phi           : 0x3F3C → S=0, E=31, M=0x13C=316, dec=1.617188
//   phi_squared   : 0x409E → S=0, E=32, M=0x09E=158, dec=2.617188
//   inf_pos       : 0x7E00 → is_inf=1
//   nan           : 0x7E01 → is_nan=1

`default_nettype none
`timescale 1ns/1ps

module tb_gf16;

    reg [15:0] raw;

    wire        sign;
    wire [5:0]  exp_raw;
    wire signed [6:0] exp_unbiased;
    wire [8:0]  mant_raw;
    wire        is_zero, is_inf, is_nan, is_subnormal;

    gf16_decode dut (
        .raw         (raw),
        .sign        (sign),
        .exp_raw     (exp_raw),
        .exp_unbiased(exp_unbiased),
        .mant_raw    (mant_raw),
        .is_zero     (is_zero),
        .is_inf      (is_inf),
        .is_nan      (is_nan),
        .is_subnormal(is_subnormal)
    );

    integer fail_count;

    task check_vec;
        input [15:0]  r;
        input         exp_sign;
        input         exp_is_zero;
        input         exp_is_sub;
        input         exp_is_inf;
        input         exp_is_nan;
        input [5:0]   exp_exp;
        input [8:0]   exp_mant;
        input [127:0] name;
        begin
            raw = r;
            #1;
            if (sign !== exp_sign ||
                is_zero !== exp_is_zero ||
                is_subnormal !== exp_is_sub ||
                is_inf !== exp_is_inf ||
                is_nan !== exp_is_nan ||
                (!exp_is_zero && !exp_is_inf && !exp_is_nan &&
                 exp_exp !== 6'b111111 && exp_raw !== exp_exp) ||
                (!exp_is_zero && !exp_is_inf && !exp_is_nan &&
                 exp_mant !== 9'b111111111 && mant_raw !== exp_mant)) begin
                $display("FAIL GF16 at vector %s: raw=0x%04h sign=%b is_zero=%b is_sub=%b is_inf=%b is_nan=%b exp=%0d mant=0x%03h",
                         name, r, sign, is_zero, is_subnormal, is_inf, is_nan, exp_raw, mant_raw);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS GF16 %s", name);
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // zero_positive
        check_vec(16'h0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 6'd0, 9'd0, "zero_positive");

        // zero_negative
        check_vec(16'h8000, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 6'd0, 9'd0, "zero_negative");

        // one_point_zero: E=31, M=0 → 2^(31-31)*(1+0)=1.0
        check_vec(16'h3E00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 6'd31, 9'd0, "one_point_zero");

        // two: E=32, M=0 → 2^(32-31)*1=2.0
        check_vec(16'h4000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 6'd32, 9'd0, "two");

        // half: E=30, M=0 → 2^(30-31)=0.5
        check_vec(16'h3C00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 6'd30, 9'd0, "half");

        // neg_one: S=1, E=31, M=0
        check_vec(16'hBE00, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 6'd31, 9'd0, "neg_one");

        // phi: raw=0x3F3C → S=0, E=0x1F=31, M=0x13C=316
        // Wait: 0x3F3C: bits 15=0, bits 14:9 = 0x1F=31, bits 8:0 = 0x13C=316
        // But 0x3F3C = 0011 1111 0011 1100
        // bit15=0 (sign=0), bits14:9 = 011111=31, bits8:0 = 000111100 = 0x03C = 60
        // Hmm, let me recalculate: 0x3F3C = 0011 1111 0011 1100
        //   sign = bit15 = 0
        //   exp  = bits[14:9] = 011111 = 31
        //   mant = bits[8:0]  = 000111100 = 60
        // dec = 2^0 * (1 + 60/512) = 1.117... that's wrong
        // Let me recalculate: 0x3F3C
        //   0x3F3C = 16188
        //   sign = 16188>>15 = 0
        //   exp  = (16188>>9)&63 = (31)&63 = 31
        //   mant = 16188&511 = 16188 - 31*512 = 16188-15872 = 316
        // dec = 2^(31-31)*(1+316/512) = 1+0.617 = 1.617  ✓
        check_vec(16'h3F3C, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 6'd31, 9'd316, "phi_approx");

        // phi_squared: 0x409E
        //   0x409E = 16542
        //   sign = 0, exp = (16542>>9)&63 = 32, mant = 16542&511 = 16542-32*512=16542-16384=158
        //   dec = 2^1*(1+158/512) = 2*(1.308) = 2.617  ✓
        check_vec(16'h409E, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 6'd32, 9'd158, "phi_squared");

        // inf_pos: E=63 (all ones), M=0
        check_vec(16'h7E00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 6'b111111, 9'd0, "inf_pos");

        // inf_neg: S=1, E=63, M=0
        check_vec(16'hFE00, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 6'b111111, 9'd0, "inf_neg");

        // nan: E=63, M=1
        check_vec(16'h7E01, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 6'b111111, 9'b111111111, "nan");

        // subnormal: E=0, M=1
        check_vec(16'h0001, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 6'd0, 9'd1, "subnormal_min");

        if (fail_count == 0)
            $display("PASS GF16");
        else
            $display("FAIL GF16 (%0d failures)", fail_count);

        $finish;
    end

endmodule

`default_nettype wire
