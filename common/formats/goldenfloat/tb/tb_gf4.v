// SPDX-License-Identifier: MIT
// tb_gf4 — GF4 decode testbench (Verilog-2005)
// GF4: S=1, E=1, M=2, bias=0
// All values are subnormals or special (E=1bit → exp_max=1 = ALL_ONES)
// value = mant/4 * 2  (for subnormals, bias=0, E=0)
//
// Known vectors (hardcoded from t27 conformance):
//   zero_positive : raw=0x0 → sign=0, is_zero=1
//   one_point_zero: raw=0x2 → sign=0, is_subnormal=1, mant=2, dec=1.0
//   max_value     : raw=0x3 → sign=0, is_subnormal=1, mant=3, dec=1.5
//   half          : raw=0x1 → sign=0, is_subnormal=1, mant=1, dec=0.5
//   neg_half      : raw=0x9 → sign=1, is_subnormal=1, mant=1, dec=-0.5

`default_nettype none
`timescale 1ns/1ps

module tb_gf4;

    reg [3:0] raw;

    wire        sign;
    wire [0:0]  exp_raw;
    wire signed [1:0] exp_unbiased;
    wire [1:0]  mant_raw;
    wire        is_zero, is_inf, is_nan, is_subnormal;

    gf4_decode dut (
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
        input [3:0]  r;
        input        exp_sign;
        input        exp_is_zero;
        input        exp_is_sub;
        input        exp_is_inf;
        input        exp_is_nan;
        input [1:0]  exp_mant;
        input [127:0] name;
        begin
            raw = r;
            #1;
            if (sign !== exp_sign || is_zero !== exp_is_zero ||
                is_subnormal !== exp_is_sub || is_inf !== exp_is_inf ||
                is_nan !== exp_is_nan ||
                (exp_mant !== 2'bxx && mant_raw !== exp_mant)) begin
                $display("FAIL GF4 at vector %s: raw=%b sign=%b is_zero=%b is_sub=%b is_inf=%b is_nan=%b mant=%b",
                         name, r, sign, is_zero, is_subnormal, is_inf, is_nan, mant_raw);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS GF4 %s", name);
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // zero_positive: raw=0x0
        check_vec(4'h0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'bxx, "zero_positive");

        // zero_negative: raw=0x8
        check_vec(4'h8, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 2'bxx, "zero_negative");

        // one_point_zero: raw=0x2 (subnormal M=2, val=2/4*2=1.0)
        check_vec(4'h2, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'd2, "one_point_zero");

        // max_value: raw=0x3 (subnormal M=3, val=3/4*2=1.5)
        check_vec(4'h3, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'd3, "max_value");

        // half: raw=0x1 (subnormal M=1, val=1/4*2=0.5)
        check_vec(4'h1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'd1, "half");

        // neg_half: raw=0x9
        check_vec(4'h9, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 2'd1, "neg_half");

        // inf_pos: raw=0x4 (E=1, M=0)
        check_vec(4'h4, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'bxx, "inf_pos");

        // inf_neg: raw=0xC
        check_vec(4'hC, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 2'bxx, "inf_neg");

        // nan: raw=0x5 (E=1, M!=0)
        check_vec(4'h5, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'bxx, "nan");

        if (fail_count == 0)
            $display("PASS GF4");
        else
            $display("FAIL GF4 (%0d failures)", fail_count);

        $finish;
    end

endmodule

`default_nettype wire
