// tb_decimal32.v — Testbench for decimal32: field extraction + round-trip
`timescale 1ns/1ps
`default_nettype none

module tb_decimal32;
    reg        clk, rst_n, load;
    reg [31:0] din;
    wire [31:0] dout;
    wire        sign;
    wire [7:0]  biased_exp;
    wire [19:0] trailing_sig;

    decimal32 dut (
        .clk(clk), .rst_n(rst_n), .din(din), .load(load),
        .dout(dout), .sign(sign), .biased_exp(biased_exp), .trailing_sig(trailing_sig)
    );

    integer fail_count;

    always #5 clk = ~clk;

    task check_roundtrip;
        input [31:0] val;
        begin
            din = val; load = 1'b1; @(posedge clk); #1; load = 1'b0;
            if (dout !== val) begin
                $display("FAIL decimal32 round-trip: in=%h out=%h", val, dout);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        clk = 0; rst_n = 0; load = 0; din = 0; fail_count = 0;
        #12; rst_n = 1;

        // Test vectors
        check_roundtrip(32'h00000000);   // +0
        check_roundtrip(32'h22300000);   // decimal32 1.0 (BID)
        check_roundtrip(32'hA2300000);   // decimal32 -1.0
        check_roundtrip(32'h77F8967F);   // max finite
        check_roundtrip(32'hDEADBEEF);   // arbitrary pattern

        // Sign extraction check for negative
        din = 32'hA2300000; load = 1'b1; @(posedge clk); #1; load = 1'b0;
        if (sign !== 1'b1) begin
            $display("FAIL decimal32 sign: expected 1 got %b", sign);
            fail_count = fail_count + 1;
        end

        if (fail_count == 0)
            $display("PASS decimal32 (%0d tests)", 5+1);
        else
            $display("FAIL decimal32 (%0d failures)", fail_count);
        $finish;
    end
endmodule
`default_nettype wire
