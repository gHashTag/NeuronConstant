// tb_posit16_mul.v — Posit<16,1> multiplication basic checks
// Posit encoding for simple values:
//   0x4000 = 1.0   (regime: 1 bit → k=0, exp=0, frac=0)
//   0x0000 = 0
//   0x8000 = NaR
//   0x4800 = 1.5   (k=0, exp=1 → scale=1, sig=1.0 → 2.0? verify)
// We test:
//   1.0 * 1.0 = 1.0
//   0 * 1.0 = 0
//   NaR * anything = NaR
`timescale 1ns/1ps
`default_nettype none

module tb_posit16_mul;

    reg  [15:0] a, b;
    wire [15:0] result;
    wire        nar_out;
    integer     fail_count;

    posit16_mul dut (.a(a), .b(b), .result(result), .nar_out(nar_out));

    initial begin
        fail_count = 0;

        // 1.0 * 1.0 = 1.0
        // Posit<16,1> 1.0 = 0x4000
        // sign=0, mag=0x4000: rbit=1, k=0, rlen=2
        // arm = mag<<2 = 0x0000, exp=0, frac=0
        // sig = 0x80, scale = 0
        // product: sig_prod = 0x80*0x80 = 0x4000, norm_overflow=0
        // scale_sum = 0, k_out=0, exp_out=0
        // regime: k=0 → 0b10_0000... → 0x4000 body → result = 0x4000
        a = 16'h4000; b = 16'h4000; #1;
        if (result !== 16'h4000) begin
            $display("FAIL 1.0*1.0: expected 0x4000 got 0x%04X", result);
            fail_count = fail_count + 1;
        end

        // 0 * 1.0 = 0
        a = 16'h0000; b = 16'h4000; #1;
        if (result !== 16'h0000) begin
            $display("FAIL 0*1: expected 0x0000 got 0x%04X", result);
            fail_count = fail_count + 1;
        end

        // NaR * 1.0 = NaR
        a = 16'h8000; b = 16'h4000; #1;
        if (result !== 16'h8000 || nar_out !== 1'b1) begin
            $display("FAIL NaR*1: expected NaR got 0x%04X nar=%b", result, nar_out);
            fail_count = fail_count + 1;
        end

        // 1.0 * NaR = NaR
        a = 16'h4000; b = 16'h8000; #1;
        if (result !== 16'h8000 || nar_out !== 1'b1) begin
            $display("FAIL 1*NaR: expected NaR got 0x%04X nar=%b", result, nar_out);
            fail_count = fail_count + 1;
        end

        // -1.0 * 1.0 = -1.0
        // Posit<16,1> -1.0 = 2's complement of 0x4000 = 0xC000
        a = 16'hC000; b = 16'h4000; #1;
        if (result !== 16'hC000) begin
            $display("FAIL -1*1: expected 0xC000 got 0x%04X", result);
            fail_count = fail_count + 1;
        end

        if (fail_count == 0)
            $display("PASS");
        else
            $display("FAIL (%0d errors)", fail_count);

        $finish;
    end

endmodule
`default_nettype wire
