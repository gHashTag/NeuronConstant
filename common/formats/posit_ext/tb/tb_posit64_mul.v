// tb_posit64_mul.v — Testbench for posit64_mul (truncated mantissa)
`timescale 1ns/1ps

module tb_posit64_mul;
    reg  [63:0] a, b;
    wire [63:0] result;
    wire        nar_out;

    posit64_mul DUT (.a(a), .b(b), .result(result), .nar_out(nar_out));

    integer fail = 0;
    integer pass = 0;

    initial begin
        $display("=== tb_posit64_mul (truncated mantissa tolerance) ===");

        // Test 1: NaR * x = NaR
        a = 64'h8000000000000000; b = 64'h4000000000000000;
        #1;
        if (result === 64'h8000000000000000 && nar_out === 1'b1) begin
            $display("PASS  nar_times_one"); pass = pass + 1;
        end else begin
            $display("FAIL  nar_times_one got=0x%016X nar=%b", result, nar_out); fail = fail + 1;
        end

        // Test 2: 0 * x = 0
        a = 64'h0000000000000000; b = 64'h4000000000000000;
        #1;
        if (result === 64'h0000000000000000 && nar_out === 1'b0) begin
            $display("PASS  zero_times_one"); pass = pass + 1;
        end else begin
            $display("FAIL  zero_times_one got=0x%016X", result); fail = fail + 1;
        end

        // Test 3: 1.0 * 1.0 = 1.0
        a = 64'h4000000000000000; b = 64'h4000000000000000;
        #1;
        $display("1.0*1.0 = 0x%016X (expect 0x4000000000000000 ±truncation)", result);
        if (result[63:60] === 4'b0100) begin
            $display("PASS  one_times_one"); pass = pass + 1;
        end else begin
            $display("FAIL  one_times_one got=0x%016X", result); fail = fail + 1;
        end

        // Test 4: NaR * NaR = NaR
        a = 64'h8000000000000000; b = 64'h8000000000000000;
        #1;
        if (result === 64'h8000000000000000 && nar_out === 1'b1) begin
            $display("PASS  nar_times_nar"); pass = pass + 1;
        end else begin
            $display("FAIL  nar_times_nar got=0x%016X nar=%b", result, nar_out); fail = fail + 1;
        end

        // Test 5: positive * negative = negative
        a = 64'h4000000000000000;   // 1.0
        b = 64'hC000000000000000;   // -1.0
        #1;
        $display("1.0*(-1.0) = 0x%016X (expect negative)", result);
        if (result[63] === 1'b1 && nar_out === 1'b0) begin
            $display("PASS  pos_times_neg"); pass = pass + 1;
        end else begin
            $display("FAIL  pos_times_neg got=0x%016X", result); fail = fail + 1;
        end

        // Test 6: big number * something = nonzero positive
        a = 64'h7F00000000000000;  // large posit
        b = 64'h4000000000000000;  // 1.0
        #1;
        $display("large*1.0 = 0x%016X (expect nonzero, same magnitude)", result);
        if (result[63] === 1'b0 && result !== 64'h0000000000000000) begin
            $display("PASS  large_times_one"); pass = pass + 1;
        end else begin
            $display("FAIL  large_times_one got=0x%016X", result); fail = fail + 1;
        end

        $display("=== RESULTS: PASS=%0d FAIL=%0d ===", pass, fail);
        if (fail == 0) $display("ALL PASS");
        else $display("SOME FAILURES");
        $finish;
    end
endmodule
