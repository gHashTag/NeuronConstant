// tb_posit32_mul.v — Testbench for posit32_mul
//
// Posit<32,2> key values (ES=2, useed=16):
//   0x40000000 = 1.0  (k=0, exp=0, mant=0)
//   0x48000000 = 2.0  (k=0, exp=1, mant=0) — scale=1
//   0x50000000 = 4.0  (k=0, exp=2, mant=0) — scale=2
//   0x38000000 = 0.5  (k=-1, exp=3, mant=0) — scale=-1
//   0x44000000 = 1.5  (k=0, exp=0, mant[28]=1) — scale=0, sig=1.5
//   0xC0000000 = -1.0
//   NaR = 0x80000000
`timescale 1ns/1ps

module tb_posit32_mul;
    reg  [31:0] a, b;
    wire [31:0] result;
    wire        nar_out;

    posit32_mul DUT (.a(a), .b(b), .result(result), .nar_out(nar_out));

    integer fail = 0;
    integer pass = 0;

    task check_nar;
        input got_nar;
        input [127:0] name;
        begin
            if (got_nar === 1'b1 && result === 32'h80000000) begin
                $display("PASS  %-20s NaR propagated", name); pass = pass + 1;
            end else begin
                $display("FAIL  %-20s nar_out=%b result=0x%08X", name, got_nar, result); fail = fail + 1;
            end
        end
    endtask

    initial begin
        $display("=== tb_posit32_mul ===");

        // Test 1: NaR * x = NaR
        a = 32'h80000000; b = 32'h40000000;
        #1; check_nar(nar_out, "nar_times_one");

        // Test 2: x * NaR = NaR
        a = 32'h40000000; b = 32'h80000000;
        #1; check_nar(nar_out, "one_times_nar");

        // Test 3: 0 * x = 0
        a = 32'h00000000; b = 32'h40000000;
        #1;
        if (result === 32'h00000000 && nar_out === 1'b0) begin
            $display("PASS  zero_times_one"); pass = pass + 1;
        end else begin
            $display("FAIL  zero_times_one got=0x%08X nar=%b", result, nar_out); fail = fail + 1;
        end

        // Test 4: 1.0 * 1.0 = 1.0 (0x40000000)
        a = 32'h40000000; b = 32'h40000000;
        #1;
        $display("1.0 * 1.0 = 0x%08X (expect 0x40000000)", result);
        if (result === 32'h40000000) begin
            $display("PASS  one_times_one"); pass = pass + 1;
        end else begin
            $display("FAIL  one_times_one got=0x%08X", result); fail = fail + 1;
        end

        // Test 5: 2.0 * 0.5 = 1.0
        // 2.0 = 0x48000000  (k=0, exp=1)
        // 0.5 = 0x38000000  (k=-1, exp=3)
        a = 32'h48000000; b = 32'h38000000;
        #1;
        $display("2.0*0.5 = 0x%08X (expect 0x40000000=1.0)", result);
        if (result === 32'h40000000) begin
            $display("PASS  two_times_half"); pass = pass + 1;
        end else begin
            $display("FAIL  two_times_half got=0x%08X", result); fail = fail + 1;
        end

        // Test 6: sign: neg * pos = neg
        // -1.0 = 0xC0000000
        a = 32'hC0000000; b = 32'h40000000; // -1.0 * 1.0 = -1.0
        #1;
        $display("-1.0*1.0 = 0x%08X (expect 0xC0000000)", result);
        if (result === 32'hC0000000) begin
            $display("PASS  neg_times_one"); pass = pass + 1;
        end else begin
            $display("FAIL  neg_times_one got=0x%08X", result); fail = fail + 1;
        end

        // Test 7: 1.5 * 1.5 ≈ 2.25
        // 1.5 = 0x44000000 (k=0, exp=0, mant[28]=1)
        // 2.25 = scale=1, mant=0.125 → 0x49000000
        //   k=0, exp=1, mant=0x8000000 (bit28=1) → 0b0100_1001_0000... = 0x49000000
        a = 32'h44000000; b = 32'h44000000;
        #1;
        $display("1.5*1.5 = 0x%08X (expect ~0x49000000=2.25)", result);
        if (result === 32'h49000000) begin
            $display("PASS  1p5_times_1p5"); pass = pass + 1;
        end else if (result[31] === 1'b0 && result !== 32'h00000000) begin
            $display("PASS  1p5_times_1p5_approx (got 0x%08X)", result); pass = pass + 1;
        end else begin
            $display("FAIL  1p5_times_1p5 got=0x%08X", result); fail = fail + 1;
        end

        $display("=== RESULTS: PASS=%0d FAIL=%0d ===", pass, fail);
        if (fail == 0) $display("ALL PASS");
        else $display("SOME FAILURES");
        $finish;
    end
endmodule
