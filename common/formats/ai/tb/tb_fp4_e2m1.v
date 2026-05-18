// tb_fp4_e2m1.v — FP4-E2M1 encode/decode round-trip
`timescale 1ns/1ps
`default_nettype none

module tb_fp4_e2m1;

    reg  [3:0] dec_fp4;
    wire [7:0] dec_s8;
    reg  [7:0] enc_s8;
    wire [3:0] enc_fp4;
    integer    fail_count;
    integer    i;

    fp4_e2m1 dut (
        .dec_fp4(dec_fp4),
        .dec_s8 (dec_s8),
        .enc_s8 (enc_s8),
        .enc_fp4(enc_fp4)
    );

    // Expected decode (×16 scaled int8)
    reg [7:0] expected_dec [0:15];

    initial begin
        expected_dec[0]  = 8'd0;    // +0
        expected_dec[1]  = 8'd0;    // +subnormal → 0
        expected_dec[2]  = 8'd16;   // +1.0
        expected_dec[3]  = 8'd24;   // +1.5
        expected_dec[4]  = 8'd32;   // +2.0
        expected_dec[5]  = 8'd48;   // +3.0
        expected_dec[6]  = 8'd64;   // +4.0
        expected_dec[7]  = 8'd96;   // +6.0
        expected_dec[8]  = 8'd0;    // -0 → 0
        expected_dec[9]  = 8'd0;    // -sub → 0
        expected_dec[10] = 8'(-16); // -1.0
        expected_dec[11] = 8'(-24); // -1.5
        expected_dec[12] = 8'(-32); // -2.0
        expected_dec[13] = 8'(-48); // -3.0
        expected_dec[14] = 8'(-64); // -4.0
        expected_dec[15] = 8'(-96); // -6.0
    end

    initial begin
        fail_count = 0;

        // Decode check
        for (i = 0; i < 16; i = i + 1) begin
            dec_fp4 = i[3:0];
            #1;
            if ($signed(dec_s8) !== $signed(expected_dec[i])) begin
                $display("FAIL dec[%0d]: expected=%0d got=%0d",
                          i, $signed(expected_dec[i]), $signed(dec_s8));
                fail_count = fail_count + 1;
            end
        end

        // Encode round-trip: positive values (indices 2..7 have unique non-zero decode)
        // index 2: value=16 → enc should give 4'b0010
        enc_s8 = 8'd16; #1;
        if (enc_fp4 !== 4'b0010) begin
            $display("FAIL enc 16 → expected 0010 got %b", enc_fp4); fail_count = fail_count + 1;
        end
        // index 4: value=32 → 4'b0100
        enc_s8 = 8'd32; #1;
        if (enc_fp4 !== 4'b0100) begin
            $display("FAIL enc 32 → expected 0100 got %b", enc_fp4); fail_count = fail_count + 1;
        end
        // index 7: value=96 → 4'b0111
        enc_s8 = 8'd96; #1;
        if (enc_fp4 !== 4'b0111) begin
            $display("FAIL enc 96 → expected 0111 got %b", enc_fp4); fail_count = fail_count + 1;
        end
        // negative: -16 → 4'b1010
        enc_s8 = 8'(-16); #1;
        if (enc_fp4 !== 4'b1010) begin
            $display("FAIL enc -16 → expected 1010 got %b", enc_fp4); fail_count = fail_count + 1;
        end

        if (fail_count == 0)
            $display("PASS");
        else
            $display("FAIL (%0d errors)", fail_count);

        $finish;
    end

endmodule
`default_nettype wire
