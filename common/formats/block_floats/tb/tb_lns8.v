// SPDX-License-Identifier: MIT
// Testbench: LNS8 decode/encode
// Tests: log(1)=0 -> 1.0, log(2)=1 -> 2.0, log(4)=2 -> 4.0
`timescale 1ns/1ps
`default_nettype none

module tb_lns8;
    integer errors;

    reg  [7:0]  lns_in;
    wire [15:0] dec_out;

    lns8_decode u_dec (
        .lns8_in   (lns_in),
        .result_q8 (dec_out)
    );

    reg  [15:0] val_in;
    wire [7:0]  enc_out;
    lns8_encode u_enc (
        .val_q8   (val_in),
        .lns8_out (enc_out)
    );

    task check16;
        input [127:0] name;
        input [15:0] got;
        input [15:0] expected;
        input [15:0] tol;
        begin
            if (got >= expected - tol && got <= expected + tol) begin
                $display("  PASS %0s: got=0x%04x exp=0x%04x", name, got, expected);
            end else begin
                $display("  FAIL %0s: got=0x%04x exp=0x%04x", name, got, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        $display("=== TB LNS8 ===");

        // LNS8 format: sign=bit7, log_index=bits[6:0]
        // log_index=48 -> 2^((48-48)/16) = 2^0 = 1.0 -> Q8.8 = 0x0100
        lns_in = 8'b0_110000; // sign=0, log=48
        #10;
        check16("LNS_1.0", dec_out, 16'h0100, 16'h0020);

        // log_index=64 -> 2^((64-48)/16) = 2^1 = 2.0 -> Q8.8 = 0x0200
        lns_in = 8'b0_1000000; // sign=0, log=64
        #10;
        check16("LNS_2.0", dec_out, 16'h0200, 16'h0050);

        // log_index=80 -> 2^((80-48)/16) = 2^2 = 4.0 -> Q8.8 = 0x0400
        lns_in = 8'b0_1010000; // sign=0, log=80
        #10;
        check16("LNS_4.0", dec_out, 16'h0400, 16'h0080);

        // log_index=32 -> 2^((32-48)/16) = 2^(-1) = 0.5 -> Q8.8 = 0x0080
        lns_in = 8'b0_0100000; // sign=0, log=32
        #10;
        check16("LNS_0.5", dec_out, 16'h0080, 16'h0020);

        // negative 1.0: sign=1, log=48
        lns_in = 8'b1_0110000; // sign=1, log_idx=48 -> -1.0
        // bits: {1, 48[6:0]} = {1, 7'b0110000} = 8'hB0
        lns_in = 8'hB0;
        #10;
        check16("LNS_-1.0", dec_out, 16'hFF00, 16'h0020);

        // zero (lns_in=0x00)
        lns_in = 8'h00;
        #10;
        // log_index=0 -> 2^((0-48)/16) = 2^(-3) = 0.125 -> Q8.8 = 0x0020
        // Not exactly 0, but a small positive value
        $display("  INFO LNS_idx0: got=0x%04x (small positive)", dec_out);

        // Encode 1.0 -> expect index ~48
        val_in = 16'h0100;
        #10;
        $display("  INFO encode_1.0: lns8=0x%02x (expect ~0x30=48)", enc_out);
        if (enc_out[6:0] >= 7'd40 && enc_out[6:0] <= 7'd56) begin
            $display("  PASS encode_1.0_range");
        end else begin
            $display("  FAIL encode_1.0_range: got log_idx=%0d, expect ~48", enc_out[6:0]);
            errors = errors + 1;
        end

        // Encode 2.0 -> expect index ~64
        val_in = 16'h0200;
        #10;
        $display("  INFO encode_2.0: lns8=0x%02x (expect ~0x40=64)", enc_out);
        if (enc_out[6:0] >= 7'd56 && enc_out[6:0] <= 7'd72) begin
            $display("  PASS encode_2.0_range");
        end else begin
            $display("  FAIL encode_2.0_range: got log_idx=%0d, expect ~64", enc_out[6:0]);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: tb_lns8 all checks passed");
        else
            $display("FAIL: tb_lns8 %0d errors", errors);

        $finish;
    end
endmodule
`default_nettype wire
