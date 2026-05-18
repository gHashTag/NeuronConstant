// tb_posit64.v — Testbench for posit64_decode, posit64_encode, posit64_add
//
// Posit<64,3> key values (ES=3, useed=256):
//   0x4000000000000000 = 1.0  (k=0, exp=000, mant=0)
//   0x4400000000000000 = 2.0  (k=0, exp=001, mant=0)
//   0x3C00000000000000 = 0.5  (k=-1, exp=7, mant=0)
//   NaR = 0x8000000000000000
//   Zero = 0x0000000000000000
`timescale 1ns/1ps

module tb_posit64;
    reg  [63:0] a, b;
    wire [63:0] add_result;
    wire        add_nar;
    wire        dec_sign;
    wire signed [7:0] dec_k;
    wire [2:0]  dec_exp;
    wire [58:0] dec_mant;
    wire        dec_zero, dec_nar;

    posit64_add DUT_add (.a(a), .b(b), .result(add_result), .nar_out(add_nar));
    posit64_decode DUT_dec (.p(a), .sign(dec_sign), .regime_k(dec_k),
                            .exp_3bit(dec_exp), .mant_59bit(dec_mant),
                            .is_zero(dec_zero), .is_nar(dec_nar));

    integer fail = 0;
    integer pass = 0;

    initial begin
        $display("=== tb_posit64 ===");

        // Test 1: decode 1.0 (k=0, exp=0, mant=0)
        a = 64'h4000000000000000;
        #1;
        $display("Decode 1.0: sign=%b k=%0d exp=%0d zero=%b nar=%b",
                 dec_sign, dec_k, dec_exp, dec_zero, dec_nar);
        if (dec_sign !== 1'b0 || dec_k !== 8'sd0 || dec_zero !== 1'b0 || dec_nar !== 1'b0) begin
            $display("FAIL  decode_1.0"); fail = fail + 1;
        end else begin
            $display("PASS  decode_1.0"); pass = pass + 1;
        end

        // Test 2: decode zero
        a = 64'h0000000000000000;
        #1;
        if (dec_zero !== 1'b1) begin
            $display("FAIL  decode_zero"); fail = fail + 1;
        end else begin
            $display("PASS  decode_zero"); pass = pass + 1;
        end

        // Test 3: decode NaR
        a = 64'h8000000000000000;
        #1;
        if (dec_nar !== 1'b1) begin
            $display("FAIL  decode_nar"); fail = fail + 1;
        end else begin
            $display("PASS  decode_nar"); pass = pass + 1;
        end

        // Test 4: NaR + x = NaR
        a = 64'h8000000000000000;
        b = 64'h4000000000000000;
        #1;
        if (add_result === 64'h8000000000000000 && add_nar === 1'b1) begin
            $display("PASS  nar_plus_one"); pass = pass + 1;
        end else begin
            $display("FAIL  nar_plus_one got=0x%016X nar=%b", add_result, add_nar); fail = fail + 1;
        end

        // Test 5: 0 + x = x
        a = 64'h0000000000000000;
        b = 64'h4000000000000000;
        #1;
        if (add_result === 64'h4000000000000000) begin
            $display("PASS  zero_plus_one"); pass = pass + 1;
        end else begin
            $display("FAIL  zero_plus_one got=0x%016X", add_result); fail = fail + 1;
        end

        // Test 6: 1.0 + 1.0 = 2.0 = 0x4400000000000000
        // Posit64 2.0: k=0, exp=1, mant=0 → regime "10" (bits 62..61) + exp=001 (bits 60..58)
        // = 0x4400000000000000
        a = 64'h4000000000000000; // 1.0
        b = 64'h4000000000000000; // 1.0
        #1;
        $display("1.0+1.0 = 0x%016X (expect 0x4400000000000000=2.0)", add_result);
        if (add_result === 64'h4400000000000000) begin
            $display("PASS  one_plus_one"); pass = pass + 1;
        end else begin
            $display("FAIL  one_plus_one got=0x%016X", add_result); fail = fail + 1;
        end

        // Test 7: 1.0 + (-1.0) = 0
        a = 64'h4000000000000000;
        b = 64'hC000000000000000; // -1.0
        #1;
        if (add_result === 64'h0000000000000000) begin
            $display("PASS  one_plus_neg_one"); pass = pass + 1;
        end else begin
            $display("FAIL  one_plus_neg_one got=0x%016X", add_result); fail = fail + 1;
        end

        // Test 8: negative decode
        a = 64'hC000000000000000;
        #1;
        if (dec_sign !== 1'b1) begin
            $display("FAIL  decode_neg1"); fail = fail + 1;
        end else begin
            $display("PASS  decode_neg1 k=%0d", dec_k); pass = pass + 1;
        end

        $display("=== RESULTS: PASS=%0d FAIL=%0d ===", pass, fail);
        if (fail == 0) $display("ALL PASS");
        else $display("SOME FAILURES");
        $finish;
    end
endmodule
