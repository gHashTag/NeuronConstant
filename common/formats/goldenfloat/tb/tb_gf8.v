// SPDX-License-Identifier: MIT
// tb_gf8 — GF8 decode testbench (Verilog-2005)
// GF8: S=1, E=3, M=4, bias=3
// value = (-1)^S * 2^(E-3) * (1 + M/16)  [normal]
//
// Known vectors from t27 conformance:
//   zero       : raw=0x00 → is_zero=1
//   one        : raw=0x30 → sign=0, exp_raw=3, mant=0, dec=1.0
//   phi (~1.62): raw=0x3A → sign=0, exp_raw=3, mant=10, dec=1.625
//   neg_phi    : raw=0xBA → sign=1, dec=-1.625
//   max        : raw=0x6F → sign=0, exp_raw=6, mant=15, dec=15.5 (exp_max-1=6)

`default_nettype none
`timescale 1ns/1ps

module tb_gf8;

    reg [7:0] raw;

    wire        sign;
    wire [2:0]  exp_raw;
    wire signed [3:0] exp_unbiased;
    wire [3:0]  mant_raw;
    wire        is_zero, is_inf, is_nan, is_subnormal;

    gf8_decode dut (
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
        input [7:0]   r;
        input         exp_sign;
        input         exp_is_zero;
        input         exp_is_sub;
        input         exp_is_inf;
        input         exp_is_nan;
        input [2:0]   exp_exp;
        input [3:0]   exp_mant;
        input [127:0] name;
        begin
            raw = r;
            #1;
            if (sign !== exp_sign || is_zero !== exp_is_zero ||
                is_subnormal !== exp_is_sub || is_inf !== exp_is_inf ||
                is_nan !== exp_is_nan ||
                (!exp_is_zero && !exp_is_inf && !exp_is_nan && exp_exp !== 3'bxxx && exp_raw !== exp_exp) ||
                (!exp_is_zero && !exp_is_inf && !exp_is_nan && exp_mant !== 4'bxxxx && mant_raw !== exp_mant)) begin
                $display("FAIL GF8 at vector %s: raw=0x%02h sign=%b is_zero=%b is_sub=%b is_inf=%b is_nan=%b exp=%0d mant=%0d",
                         name, r, sign, is_zero, is_subnormal, is_inf, is_nan, exp_raw, mant_raw);
                fail_count = fail_count + 1;
            end else begin
                $display("  PASS GF8 %s", name);
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // zero: raw=0x00
        check_vec(8'h00, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 3'bxxx, 4'bxxxx, "zero_positive");

        // one: raw=0x30 → S=0, E=3'b011=3, M=4'b0000=0 → 2^(3-3)*(1+0)=1.0
        check_vec(8'h30, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 3'd3, 4'd0, "one_point_zero");

        // phi: raw=0x3A → S=0, E=0b011=3, M=0b1010=10 → 2^0*(1+10/16)=1.625
        check_vec(8'h3A, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 3'd3, 4'd10, "phi_approx");

        // neg_phi: raw=0xBA → S=1, E=0b011=3, M=0b1010=10 → -1.625
        check_vec(8'hBA, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 3'd3, 4'd10, "neg_phi_approx");

        // max: raw=0x6F → S=0, E=0b110=6, M=0b1111=15 → 2^3*(1+15/16)=15.5
        check_vec(8'h6F, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 3'd6, 4'd15, "max_value");

        // inf_pos: E=7 (all ones), M=0
        check_vec(8'h70, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 3'bxxx, 4'bxxxx, "inf_pos");

        // inf_neg: 0xF0
        check_vec(8'hF0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 3'bxxx, 4'bxxxx, "inf_neg");

        // nan: E=7, M=1
        check_vec(8'h71, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 3'bxxx, 4'bxxxx, "nan");

        // subnormal: E=0, M=1
        check_vec(8'h01, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 3'd0, 4'd1, "subnormal_min");

        if (fail_count == 0)
            $display("PASS GF8");
        else
            $display("FAIL GF8 (%0d failures)", fail_count);

        $finish;
    end

endmodule

`default_nettype wire
