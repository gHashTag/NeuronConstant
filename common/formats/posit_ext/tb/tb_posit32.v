// tb_posit32.v — Testbench for posit32_decode, posit32_encode, posit32_add
//
// Posit<32,2> key values:
//   0x40000000 = 1.0  (k=0, exp=00, mant=0)
//   0x44000000 = 2.0  (k=0, exp=10, mant=0)  — wait, let's verify
//   0x48000000 = 2.0  more carefully:
//     For Posit32: 1.0 is represented as k=0, exp=0, mant=0 → 0b0_10_00...0 = 0x40000000
//     2.0: k=0, exp=2 → regime=10 (2 bits), exp=10, rest=0
//          bit31=0, regime=10(2bits), exp=10(2bits) → 0b0_10_10_000...0 = 0x50000000
//          Actually let's be precise: regime run of k=0 means 1 one + terminator 0 = "10"
//          Then 2-bit exp = 10 (value 2), then mant=0
//          So: 0 10 10 000...0 = 0b0101_0000_0000_0000_0000_0000_0000_0000 = 0x50000000
//   0.5: value = 2^-1 → scale=-1 → k=-1, exp=3 (4*(-1)+3=−1) wait...
//        Posit32: scale = 4*k + exp (ES=2, useed=16)
//        0.5 = 2^-1 → need 4*k + exp = -1 → k=0, exp actually... 
//        Actually simpler: for positive k=0, exp=0: scale=0, value=1.0
//        For 0.5: scale=-1, k=0, exp=−1 → but exp must be 0..3
//        Actually 4*(-1)+3 = -1, so k=-1, exp=3 gives scale=-1 → value=2^-1=0.5
//        k=-1: regime = 01 (1 zero + terminator 1), exp=11 (3), mant=0
//        0 01 11 000...0 = 0b0011_1000_0000_0000_0000_0000_0000_0000 = 0x38000000
//
// NaR = 0x80000000, Zero = 0x00000000
`timescale 1ns/1ps

module tb_posit32;
    reg  [31:0] a, b;
    wire [31:0] add_result;
    wire        add_nar;
    wire        dec_sign;
    wire signed [6:0] dec_k;
    wire [1:0]  dec_exp;
    wire [28:0] dec_mant;
    wire        dec_zero, dec_nar;

    posit32_add DUT_add (.a(a), .b(b), .result(add_result), .nar_out(add_nar));
    posit32_decode DUT_dec (.p(a), .sign(dec_sign), .regime_k(dec_k),
                            .exp_2bit(dec_exp), .mant_29bit(dec_mant),
                            .is_zero(dec_zero), .is_nar(dec_nar));

    integer fail = 0;
    integer pass = 0;

    task check_eq;
        input [31:0] got;
        input [31:0] exp;
        input [127:0] name;
        begin
            if (got === exp) begin
                $display("PASS  %-20s got=0x%08X", name, got);
                pass = pass + 1;
            end else begin
                $display("FAIL  %-20s got=0x%08X exp=0x%08X", name, got, exp);
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        $display("=== tb_posit32 ===");

        // Test 1: decode 1.0 (0x40000000)
        a = 32'h40000000;
        #1;
        $display("Decode 0x40000000: sign=%b k=%0d exp=%0d mant=0x%07X zero=%b nar=%b",
                 dec_sign, dec_k, dec_exp, dec_mant, dec_zero, dec_nar);
        if (dec_sign !== 1'b0 || dec_k !== 7'sd0 || dec_zero !== 1'b0 || dec_nar !== 1'b0) begin
            $display("FAIL  decode_1.0"); fail = fail + 1;
        end else begin
            $display("PASS  decode_1.0"); pass = pass + 1;
        end

        // Test 2: decode zero
        a = 32'h00000000;
        #1;
        if (dec_zero !== 1'b1) begin
            $display("FAIL  decode_zero"); fail = fail + 1;
        end else begin
            $display("PASS  decode_zero"); pass = pass + 1;
        end

        // Test 3: decode NaR
        a = 32'h80000000;
        #1;
        if (dec_nar !== 1'b1) begin
            $display("FAIL  decode_nar"); fail = fail + 1;
        end else begin
            $display("PASS  decode_nar"); pass = pass + 1;
        end

        // Test 4: NaR + anything = NaR
        a = 32'h80000000;
        b = 32'h40000000; // 1.0
        #1;
        check_eq(add_result, 32'h80000000, "nar_plus_one");
        if (add_nar !== 1'b1) begin
            $display("FAIL  nar_plus_one_nar_flag"); fail = fail + 1;
        end else begin
            $display("PASS  nar_plus_one_nar_flag"); pass = pass + 1;
        end

        // Test 5: 0 + x = x
        a = 32'h00000000;
        b = 32'h40000000; // 1.0
        #1;
        check_eq(add_result, 32'h40000000, "zero_plus_one");

        // Test 6: x + 0 = x
        a = 32'h40000000;
        b = 32'h00000000;
        #1;
        check_eq(add_result, 32'h40000000, "one_plus_zero");

        // Test 7: 1.0 + 1.0 should give 2.0
        // 2.0 in Posit32: scale=1, k=0, exp=01 → 0 10 01 00...0 = 0x48000000
        // (regime "10" + exp "01" = 0b0100_1000_0000...)
        a = 32'h40000000; // 1.0
        b = 32'h40000000; // 1.0
        #1;
        $display("1.0+1.0 = 0x%08X (expect 0x48000000=2.0)", add_result);
        if (add_result === 32'h48000000) begin
            $display("PASS  one_plus_one"); pass = pass + 1;
        end else begin
            $display("FAIL  one_plus_one_msb got=0x%08X", add_result); fail = fail + 1;
        end

        // Test 8: negative decode
        a = 32'hC0000000; // -1.0 (2's complement of 0x40000000)
        #1;
        if (dec_sign !== 1'b1) begin
            $display("FAIL  decode_neg1"); fail = fail + 1;
        end else begin
            $display("PASS  decode_neg1 k=%0d", dec_k); pass = pass + 1;
        end

        // Test 9: 1.0 + (-1.0) = 0
        a = 32'h40000000; b = 32'hC0000000;
        #1;
        check_eq(add_result, 32'h00000000, "one_plus_neg_one");

        $display("=== RESULTS: PASS=%0d FAIL=%0d ===", pass, fail);
        if (fail == 0) $display("ALL PASS");
        else $display("SOME FAILURES");
        $finish;
    end
endmodule
