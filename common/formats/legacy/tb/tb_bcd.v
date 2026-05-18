// tb_bcd.v — Testbench for bcd_packed, bcd8, bcd16, bcd_add
// Known vector: BCD 1234 + 5678 = 6912 (4 digits)
`timescale 1ns/1ps
`default_nettype none

module tb_bcd;
    integer fail_count;

    // --- bcd_packed ---
    reg  [7:0]  bcdp_a, bcdp_b;
    reg         bcdp_cin;
    wire [7:0]  bcdp_sum;
    wire        bcdp_cout;

    bcd_packed u_bcdp (
        .a(bcdp_a), .b(bcdp_b), .cin(bcdp_cin),
        .sum(bcdp_sum), .cout(bcdp_cout)
    );

    // --- bcd8 ---
    reg  [7:0]  bcd8_a, bcd8_b;
    reg         bcd8_cin;
    wire [7:0]  bcd8_sum;
    wire        bcd8_cout;

    bcd8 u_bcd8 (
        .a(bcd8_a), .b(bcd8_b), .cin(bcd8_cin),
        .sum(bcd8_sum), .cout(bcd8_cout)
    );

    // --- bcd16 ---
    reg  [15:0] bcd16_a, bcd16_b;
    reg         bcd16_cin;
    wire [15:0] bcd16_sum;
    wire        bcd16_cout;

    bcd16 u_bcd16 (
        .a(bcd16_a), .b(bcd16_b), .cin(bcd16_cin),
        .sum(bcd16_sum), .cout(bcd16_cout)
    );

    // --- bcd_add (4 digits) ---
    reg  [15:0] bcdN_a, bcdN_b;
    reg         bcdN_cin;
    wire [15:0] bcdN_sum;
    wire        bcdN_cout;

    bcd_add #(.N_DIGITS(4)) u_bcdN (
        .a(bcdN_a), .b(bcdN_b), .cin(bcdN_cin),
        .sum(bcdN_sum), .cout(bcdN_cout)
    );

    task check_bcdp;
        input [7:0] a, b, expected;
        input       cin_in;
        begin
            bcdp_a = a; bcdp_b = b; bcdp_cin = cin_in;
            #2;
            if (bcdp_sum !== expected) begin
                $display("FAIL bcd_packed: %h + %h = %h (expected %h)", a, b, bcdp_sum, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_bcd16;
        input [15:0] a, b, expected;
        input        cin_in;
        begin
            bcd16_a = a; bcd16_b = b; bcd16_cin = cin_in;
            #2;
            if (bcd16_sum !== expected) begin
                $display("FAIL bcd16: %h + %h = %h (expected %h)", a, b, bcd16_sum, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_bcdN;
        input [15:0] a, b, expected;
        input        cin_in;
        begin
            bcdN_a = a; bcdN_b = b; bcdN_cin = cin_in;
            #2;
            if (bcdN_sum !== expected) begin
                $display("FAIL bcd_add: %h + %h = %h (expected %h)", a, b, bcdN_sum, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // bcd_packed: 12 + 34 = 46 (BCD)
        check_bcdp(8'h12, 8'h34, 8'h46, 1'b0);
        // bcd_packed: 99 + 01 = 00 with carry
        check_bcdp(8'h99, 8'h01, 8'h00, 1'b0);
        // bcd_packed: 55 + 55 = 10 (BCD: 110 → carry=1, sum=10)
        check_bcdp(8'h55, 8'h55, 8'h10, 1'b0);

        // bcd8: same as bcd_packed (direct)
        bcd8_a = 8'h12; bcd8_b = 8'h34; bcd8_cin = 1'b0; #2;
        if (bcd8_sum !== 8'h46) begin
            $display("FAIL bcd8: 12+34 = %h (expected 46)", bcd8_sum);
            fail_count = fail_count + 1;
        end

        // KEY VECTOR: BCD 1234 + 5678 = 6912
        // 1234 in BCD = 16'h1234, 5678 = 16'h5678
        check_bcd16(16'h1234, 16'h5678, 16'h6912, 1'b0);
        check_bcdN (16'h1234, 16'h5678, 16'h6912, 1'b0);

        // Additional: BCD 9999 + 1 = 0000 carry=1
        check_bcd16(16'h9999, 16'h0001, 16'h0000, 1'b0);

        if (fail_count == 0)
            $display("PASS bcd (packed/8/16/add) - 1234+5678=6912 verified");
        else
            $display("FAIL bcd (%0d failures)", fail_count);
        $finish;
    end
endmodule
`default_nettype wire
