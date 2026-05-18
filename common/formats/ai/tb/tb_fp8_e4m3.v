// tb_fp8_e4m3.v — FP8-E4M3 decode/encode known values
// FP8-E4M3: bias=7, range ±448
// Key values:
//   1.0  → 0x38 (sign=0, exp=7→biased=7, mant=000) → 0_0111_000
//   0.5  → 0x30 (sign=0, exp=6→biased=6, mant=000) → 0_0110_000
//   2.0  → 0x40 (sign=0, exp=8→biased=8, mant=000) → 0_1000_000
//   -1.0 → 0xB8
//   NaN  → 0x7F (exp=1111, mant=111)
`timescale 1ns/1ps
`default_nettype none

module tb_fp8_e4m3;

    reg  [7:0]  dec_fp8;
    wire [15:0] dec_s16;
    wire        dec_nan;
    reg  [15:0] enc_s16;
    wire [7:0]  enc_fp8;
    integer     fail_count;

    fp8_e4m3 dut (
        .dec_fp8(dec_fp8),
        .dec_s16(dec_s16),
        .dec_nan(dec_nan),
        .enc_s16(enc_s16),
        .enc_fp8(enc_fp8)
    );

    initial begin
        fail_count = 0;

        // --- Decode tests ---
        // 1.0 = 0x38: unbiased_exp = 7-7 = 0, mant=000 → value=1.0 → Q8.7 = 128 = 0x0080
        dec_fp8 = 8'h38; #1;
        if (dec_s16 !== 16'd128) begin
            $display("FAIL dec 1.0: expected 128 got %0d", dec_s16); fail_count = fail_count + 1;
        end
        if (dec_nan !== 1'b0) begin
            $display("FAIL dec 1.0: nan should be 0"); fail_count = fail_count + 1;
        end

        // 0.5 = 0x30: unbiased = 6-7 = -1, value=0.5 → Q8.7 = 64
        dec_fp8 = 8'h30; #1;
        if (dec_s16 !== 16'd64) begin
            $display("FAIL dec 0.5: expected 64 got %0d", dec_s16); fail_count = fail_count + 1;
        end

        // 2.0 = 0x40: unbiased = 8-7 = 1, value=2.0 → Q8.7 = 256
        dec_fp8 = 8'h40; #1;
        if (dec_s16 !== 16'd256) begin
            $display("FAIL dec 2.0: expected 256 got %0d", dec_s16); fail_count = fail_count + 1;
        end

        // -1.0 = 0xB8 (sign=1 | 0x38): Q8.7 = -128 = 0xFF80
        dec_fp8 = 8'hB8; #1;
        if ($signed(dec_s16) !== -16'sd128) begin
            $display("FAIL dec -1.0: expected -128 got %0d", $signed(dec_s16)); fail_count = fail_count + 1;
        end

        // NaN = 0x7F (exp=1111, mant=111)
        dec_fp8 = 8'h7F; #1;
        if (dec_nan !== 1'b1) begin
            $display("FAIL dec NaN: nan should be 1"); fail_count = fail_count + 1;
        end

        // Zero = 0x00
        dec_fp8 = 8'h00; #1;
        if (dec_s16 !== 16'd0) begin
            $display("FAIL dec zero: expected 0 got %0d", dec_s16); fail_count = fail_count + 1;
        end

        if (fail_count == 0)
            $display("PASS");
        else
            $display("FAIL (%0d errors)", fail_count);

        $finish;
    end

endmodule
`default_nettype wire
