// tb_fp8_e5m2.v — FP8-E5M2 decode/encode known values
// FP8-E5M2: bias=15, range ±57344
// Key values (Q9.6 = ×64 fixed-point):
//   1.0 → 0x3C (sign=0, exp=15→biased=15, mant=00) → 0_01111_00
//         unbiased=0, value=1.0 → Q9.6 = 64
//   2.0 → 0x40 (exp=16→biased=16, mant=00) → 0_10000_00
//         unbiased=1, value=2.0 → Q9.6 = 128
//   0.5 → 0x38 (exp=14, mant=00) unbiased=-1 → value=0.5 → Q9.6 = 32
//   NaN → exp=11111, mant≠00 (e.g. 0x7F = 0_11111_11)
`timescale 1ns/1ps
`default_nettype none

module tb_fp8_e5m2;

    reg  [7:0]  dec_fp8;
    wire [15:0] dec_s16;
    wire        dec_nan;
    reg  [15:0] enc_s16;
    wire [7:0]  enc_fp8;
    integer     fail_count;

    fp8_e5m2 dut (
        .dec_fp8(dec_fp8),
        .dec_s16(dec_s16),
        .dec_nan(dec_nan),
        .enc_s16(enc_s16),
        .enc_fp8(enc_fp8)
    );

    initial begin
        fail_count = 0;

        // 1.0 = 0x3C: unbiased=0, full_mant={1,00}=4, shift=0+4=4
        //   abs_val = 4 << 4 = 64 → Q9.6 = 64
        dec_fp8 = 8'h3C; #1;
        if (dec_s16 !== 16'd64) begin
            $display("FAIL dec 1.0: expected 64 got %0d", dec_s16); fail_count = fail_count + 1;
        end
        if (dec_nan !== 1'b0) begin
            $display("FAIL dec 1.0: nan should be 0"); fail_count = fail_count + 1;
        end

        // 2.0 = 0x40: unbiased=1, full_mant=4, shift=1+4=5 → 4<<5=128
        dec_fp8 = 8'h40; #1;
        if (dec_s16 !== 16'd128) begin
            $display("FAIL dec 2.0: expected 128 got %0d", dec_s16); fail_count = fail_count + 1;
        end

        // 0.5 = 0x38: unbiased=-1, full_mant=4, shift=-1+4=3 → 4<<3=32
        dec_fp8 = 8'h38; #1;
        if (dec_s16 !== 16'd32) begin
            $display("FAIL dec 0.5: expected 32 got %0d", dec_s16); fail_count = fail_count + 1;
        end

        // -1.0 = 0xBC: Q9.6 = -64
        dec_fp8 = 8'hBC; #1;
        if ($signed(dec_s16) !== -16'sd64) begin
            $display("FAIL dec -1.0: expected -64 got %0d", $signed(dec_s16)); fail_count = fail_count + 1;
        end

        // NaN = 0x7F (exp=11111, mant=11)
        dec_fp8 = 8'h7F; #1;
        if (dec_nan !== 1'b1) begin
            $display("FAIL dec NaN: nan should be 1"); fail_count = fail_count + 1;
        end

        // Zero
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
