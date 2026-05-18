// SPDX-License-Identifier: MIT
// tb_gf32 — GF32 decode testbench (Verilog-2005)
// GF32: S=1, E=12, M=19, bias=2047
// value = (-1)^S * 2^(E-2047) * (1 + M/524288) [normal]
//
// Known vectors:
//   zero       : 0x00000000 → is_zero=1
//   one        : 0x3FF80000 → S=0, E=2047, M=0 → 2^0*1.0=1.0
//   phi        : 0x3FFCF1BC → S=0, E=2047, M=0x4F1BC=324028 → ~1.618034
//   neg_phi    : 0xBFFCF1BC → S=1, dec=-1.618034
//   inf_pos    : S=0, E=4095 (all ones), M=0
//   nan        : S=0, E=4095, M=1

`default_nettype none
`timescale 1ns/1ps

module tb_gf32;

    reg [31:0] raw;

    wire         sign;
    wire [11:0]  exp_raw;
    wire signed [12:0] exp_unbiased;
    wire [18:0]  mant_raw;
    wire         is_zero, is_inf, is_nan, is_subnormal;

    gf32_decode dut (
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
        input [31:0] r;
        input        exp_sign;
        input        exp_is_zero;
        input        exp_is_sub;
        input        exp_is_inf;
        input        exp_is_nan;
        input [11:0] exp_exp;
        input [18:0] exp_mant;
        input [127:0] name;
        begin
            raw = r;
            #1;
            if (sign !== exp_sign ||
                is_zero !== exp_is_zero ||
                is_subnormal !== exp_is_sub ||
                is_inf !== exp_is_inf ||
                is_nan !== exp_is_nan) begin
                $display("FAIL GF32 at vector %s: raw=0x%08h sign=%b is_zero=%b is_sub=%b is_inf=%b is_nan=%b",
                         name, r, sign, is_zero, is_subnormal, is_inf, is_nan);
                fail_count = fail_count + 1;
            end else if (!exp_is_zero && !exp_is_inf && !exp_is_nan &&
                         exp_exp !== 12'hfff && exp_raw !== exp_exp) begin
                $display("FAIL GF32 at vector %s: exp expected %0d got %0d",
                         name, exp_exp, exp_raw);
                fail_count = fail_count + 1;
            end else if (!exp_is_zero && !exp_is_inf && !exp_is_nan &&
                         exp_mant !== 19'h7ffff && mant_raw !== exp_mant) begin
                $display("FAIL GF32 at vector %s: mant expected 0x%05h got 0x%05h",
                         name, exp_mant, mant_raw);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS GF32 %s", name);
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // zero_positive
        check_vec(32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 12'hfff, 19'h7ffff, "zero_positive");

        // zero_negative
        check_vec(32'h80000000, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 12'hfff, 19'h7ffff, "zero_negative");

        // one: 0x3FF80000
        // E = (0x3FF80000 >> 19) & 0xFFF = 0x1FF = 2047, M = 0
        // dec = 2^(2047-2047)*(1+0)=1.0
        check_vec(32'h3FF80000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 12'd2047, 19'd0, "one_point_zero");

        // phi: 0x3FFCF1BC
        // E = (0x3FFCF1BC >> 19) & 0xFFF = 0x1FF = 2047
        // M = 0x3FFCF1BC & 0x7FFFF = 0x4F1BC = 324028
        // dec = 1 + 324028/524288 = 1 + 0.618034... ≈ 1.618034
        check_vec(32'h3FFCF1BC, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 12'd2047, 19'd324028, "phi");

        // neg_phi
        check_vec(32'hBFFCF1BC, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 12'd2047, 19'd324028, "neg_phi");

        // inf_pos: E=0xFFF (all ones), M=0
        check_vec(32'h7FF80000, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 12'hfff, 19'h7ffff, "inf_pos");

        // inf_neg
        check_vec(32'hFFF80000, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 12'hfff, 19'h7ffff, "inf_neg");

        // nan: E=0xFFF, M=1
        check_vec(32'h7FF80001, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 12'hfff, 19'h7ffff, "nan");

        // subnormal: E=0, M=1
        check_vec(32'h00000001, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 12'hfff, 19'h7ffff, "subnormal_min");

        if (fail_count == 0)
            $display("PASS GF32");
        else
            $display("FAIL GF32 (%0d failures)", fail_count);

        $finish;
    end

endmodule

`default_nettype wire
