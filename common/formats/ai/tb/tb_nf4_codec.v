// tb_nf4_codec.v — NF4 encode/decode round-trip for all 16 entries
`timescale 1ns/1ps
`default_nettype none

module tb_nf4_codec;

    reg  [3:0] dec_idx;
    wire [7:0] dec_val;
    reg  [7:0] enc_in;
    wire [3:0] enc_idx;
    integer    fail_count;
    integer    i;

    nf4_codec dut (
        .dec_idx(dec_idx),
        .dec_val(dec_val),
        .enc_in (enc_in),
        .enc_idx(enc_idx)
    );

    // Expected decode values (int8 / 2's complement)
    reg [7:0] expected_dec [0:15];

    initial begin
        expected_dec[0]  = 8'sh81; // -127
        expected_dec[1]  = 8'shA8; // -88
        expected_dec[2]  = 8'shBD; // -67
        expected_dec[3]  = 8'shCE; // -50
        expected_dec[4]  = 8'shDC; // -36
        expected_dec[5]  = 8'shE9; // -23
        expected_dec[6]  = 8'shF4; // -12
        expected_dec[7]  = 8'sh00; //   0
        expected_dec[8]  = 8'sh0A; //  10
        expected_dec[9]  = 8'sh14; //  20
        expected_dec[10] = 8'sh1F; //  31
        expected_dec[11] = 8'sh2B; //  43
        expected_dec[12] = 8'sh38; //  56
        expected_dec[13] = 8'sh47; //  71
        expected_dec[14] = 8'sh5C; //  92
        expected_dec[15] = 8'sh7F; // 127
    end

    initial begin
        fail_count = 0;

        // Test 1: decode all 16 entries
        for (i = 0; i < 16; i = i + 1) begin
            dec_idx = i[3:0];
            #1;
            if (dec_val !== expected_dec[i]) begin
                $display("FAIL decode[%0d]: expected=%0d got=%0d",
                          i, $signed(expected_dec[i]), $signed(dec_val));
                fail_count = fail_count + 1;
            end
        end

        // Test 2: encode round-trip — encode the decoded value and check we get same index back
        for (i = 0; i < 16; i = i + 1) begin
            enc_in = expected_dec[i];
            #1;
            if (enc_idx !== i[3:0]) begin
                $display("FAIL encode roundtrip[%0d]: val=%0d got_idx=%0d",
                          i, $signed(expected_dec[i]), enc_idx);
                fail_count = fail_count + 1;
            end
        end

        if (fail_count == 0)
            $display("PASS");
        else
            $display("FAIL (%0d errors)", fail_count);

        $finish;
    end

endmodule
`default_nettype wire
