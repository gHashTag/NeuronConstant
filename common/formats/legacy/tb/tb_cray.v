// tb_cray.v — Testbench for Cray-1 float
// Cray-1 1.0 = 0x4001800000000000:
//   sign=0, exp=0x4001=16385 (bias=16384, true_exp=1)
//   mant=0x800000000000 (bit47=1 → normalized 0.1_binary → 0.5)
//   value = 2^1 * 0.5 = 1.0 ✓
// Note: task stated 0x4001000000000000 which would give mant=0 (denorm zero)
//       Corrected to standard Cray encoding per hardware reference manual.
`timescale 1ns/1ps
`default_nettype none

module tb_cray;
    integer fail_count;
    reg clk, rst_n;

    reg  [63:0] din;
    reg         load;
    wire [63:0] dout, encoded;
    wire        sign, normalized;
    wire [14:0] biased_exp;
    wire [47:0] mantissa;

    cray_float u_cray (
        .clk(clk), .rst_n(rst_n),
        .din(din), .load(load), .dout(dout),
        .sign(sign), .biased_exp(biased_exp),
        .mantissa(mantissa), .normalized(normalized), .encoded(encoded)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; fail_count = 0; din = 0; load = 0;
        #12; rst_n = 1;

        // --- Cray 1.0 = 0x4001800000000000 ---
        // sign=0, exp[62:48]=0x4001, mant[47:0]=0x800000000000
        din = 64'h4001800000000000; load = 1'b1;
        @(posedge clk); #1; load = 1'b0;

        if (dout !== 64'h4001800000000000) begin
            $display("FAIL cray round-trip 1.0: got %h", dout);
            fail_count = fail_count + 1;
        end
        if (sign !== 1'b0) begin
            $display("FAIL cray sign for 1.0: got %b", sign);
            fail_count = fail_count + 1;
        end
        if (biased_exp !== 15'h4001) begin
            $display("FAIL cray exp for 1.0: got %h (expected 4001)", biased_exp);
            fail_count = fail_count + 1;
        end
        if (mantissa !== 48'h800000000000) begin
            $display("FAIL cray mant for 1.0: got %h (expected 800000000000)", mantissa);
            fail_count = fail_count + 1;
        end
        if (normalized !== 1'b1) begin
            $display("FAIL cray normalized for 1.0: got %b", normalized);
            fail_count = fail_count + 1;
        end
        if (encoded !== 64'h4001800000000000) begin
            $display("FAIL cray encoded 1.0: got %h", encoded);
            fail_count = fail_count + 1;
        end

        // --- Zero ---
        din = 64'h0; load = 1'b1;
        @(posedge clk); #1; load = 1'b0;
        if (dout !== 64'h0) begin
            $display("FAIL cray round-trip zero: got %h", dout);
            fail_count = fail_count + 1;
        end
        if (normalized !== 1'b0) begin
            $display("FAIL cray normalized for zero: got %b", normalized);
            fail_count = fail_count + 1;
        end

        // --- Arbitrary pattern ---
        din = 64'hDEADBEEFCAFEBABE; load = 1'b1;
        @(posedge clk); #1; load = 1'b0;
        if (dout !== 64'hDEADBEEFCAFEBABE) begin
            $display("FAIL cray round-trip arbitrary: got %h", dout);
            fail_count = fail_count + 1;
        end

        if (fail_count == 0)
            $display("PASS cray_float (1.0=0x4001800000000000 verified, normalized=1)");
        else
            $display("FAIL cray_float (%0d failures)", fail_count);
        $finish;
    end
endmodule
`default_nettype wire
