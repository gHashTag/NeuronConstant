// tb_tapered.v — Testbench for tapered_fp (WIDTH=16 and WIDTH=32)
`timescale 1ns/1ps

module tb_tapered;
    // TaperedFP16
    reg  [15:0] tfp16_in;
    wire        t16_dec_sign;
    wire signed [7:0] t16_dec_k;
    wire [28:0] t16_dec_mant;
    wire        t16_dec_zero, t16_dec_nar;

    reg         t16_enc_sign;
    reg  signed [7:0] t16_enc_k;
    reg  [28:0] t16_enc_mant;
    reg         t16_enc_zero, t16_enc_nar;
    wire [15:0] t16_enc_out;

    tapered_fp #(.WIDTH(16)) DUT16 (
        .tfp_in(tfp16_in),
        .dec_sign(t16_dec_sign), .dec_k(t16_dec_k), .dec_mant(t16_dec_mant),
        .dec_zero(t16_dec_zero), .dec_nar(t16_dec_nar),
        .enc_sign(t16_enc_sign), .enc_k(t16_enc_k), .enc_mant(t16_enc_mant),
        .enc_zero(t16_enc_zero), .enc_nar(t16_enc_nar),
        .tfp_out(t16_enc_out)
    );

    // TaperedFP32
    reg  [31:0] tfp32_in;
    wire        t32_dec_sign;
    wire signed [7:0] t32_dec_k;
    wire [28:0] t32_dec_mant;
    wire        t32_dec_zero, t32_dec_nar;

    reg         t32_enc_sign;
    reg  signed [7:0] t32_enc_k;
    reg  [28:0] t32_enc_mant;
    reg         t32_enc_zero, t32_enc_nar;
    wire [31:0] t32_enc_out;

    tapered_fp #(.WIDTH(32)) DUT32 (
        .tfp_in(tfp32_in),
        .dec_sign(t32_dec_sign), .dec_k(t32_dec_k), .dec_mant(t32_dec_mant),
        .dec_zero(t32_dec_zero), .dec_nar(t32_dec_nar),
        .enc_sign(t32_enc_sign), .enc_k(t32_enc_k), .enc_mant(t32_enc_mant),
        .enc_zero(t32_enc_zero), .enc_nar(t32_enc_nar),
        .tfp_out(t32_enc_out)
    );

    integer fail = 0;
    integer pass = 0;

    initial begin
        $display("=== tb_tapered ===");

        // --- TaperedFP16 tests ---

        // Test 1: Zero decode
        tfp16_in = 16'h0000;
        #1;
        if (t16_dec_zero === 1'b1) begin
            $display("PASS  tfp16_zero_decode"); pass = pass + 1;
        end else begin
            $display("FAIL  tfp16_zero_decode"); fail = fail + 1;
        end

        // Test 2: NaR decode
        tfp16_in = 16'h8000;
        #1;
        if (t16_dec_nar === 1'b1) begin
            $display("PASS  tfp16_nar_decode"); pass = pass + 1;
        end else begin
            $display("FAIL  tfp16_nar_decode"); fail = fail + 1;
        end

        // Test 3: 1.0 decode = 0x4000 (same as Posit: k=0, mant=0)
        tfp16_in = 16'h4000;
        #1;
        $display("TFP16 decode 0x4000: sign=%b k=%0d zero=%b nar=%b",
                 t16_dec_sign, t16_dec_k, t16_dec_zero, t16_dec_nar);
        if (t16_dec_sign === 1'b0 && t16_dec_zero === 1'b0 && t16_dec_nar === 1'b0) begin
            $display("PASS  tfp16_1p0_decode"); pass = pass + 1;
        end else begin
            $display("FAIL  tfp16_1p0_decode"); fail = fail + 1;
        end

        // Test 4: NaR encode
        t16_enc_sign = 1'b0; t16_enc_k = 8'sd0; t16_enc_mant = 29'b0;
        t16_enc_zero = 1'b0; t16_enc_nar = 1'b1;
        #1;
        if (t16_enc_out === 16'h8000) begin
            $display("PASS  tfp16_nar_encode"); pass = pass + 1;
        end else begin
            $display("FAIL  tfp16_nar_encode got=0x%04X", t16_enc_out); fail = fail + 1;
        end

        // Test 5: Zero encode
        t16_enc_zero = 1'b1; t16_enc_nar = 1'b0;
        #1;
        if (t16_enc_out === 16'h0000) begin
            $display("PASS  tfp16_zero_encode"); pass = pass + 1;
        end else begin
            $display("FAIL  tfp16_zero_encode got=0x%04X", t16_enc_out); fail = fail + 1;
        end

        // Test 6: Encode k=0, sign=0, mant=0 → should produce 0x4000 (1.0)
        t16_enc_zero = 1'b0; t16_enc_nar = 1'b0;
        t16_enc_sign = 1'b0; t16_enc_k = 8'sd0; t16_enc_mant = 29'b0;
        #1;
        $display("Encode k=0,sign=0,mant=0 → 0x%04X (expect 0x4000)", t16_enc_out);
        if (t16_enc_out === 16'h4000) begin
            $display("PASS  tfp16_1p0_encode"); pass = pass + 1;
        end else begin
            $display("FAIL  tfp16_1p0_encode got=0x%04X", t16_enc_out); fail = fail + 1;
        end

        // Test 7: Negative sign encode
        t16_enc_sign = 1'b1; t16_enc_k = 8'sd0; t16_enc_mant = 29'b0;
        t16_enc_zero = 1'b0; t16_enc_nar = 1'b0;
        #1;
        $display("Encode k=0,sign=1 → 0x%04X (expect negative = 0xC000)", t16_enc_out);
        if (t16_enc_out[15] === 1'b1) begin
            $display("PASS  tfp16_neg_encode"); pass = pass + 1;
        end else begin
            $display("FAIL  tfp16_neg_encode got=0x%04X", t16_enc_out); fail = fail + 1;
        end

        // --- TaperedFP32 tests ---

        // Test 8: Zero decode
        tfp32_in = 32'h00000000;
        #1;
        if (t32_dec_zero === 1'b1) begin
            $display("PASS  tfp32_zero_decode"); pass = pass + 1;
        end else begin
            $display("FAIL  tfp32_zero_decode"); fail = fail + 1;
        end

        // Test 9: 1.0 decode = 0x40000000
        tfp32_in = 32'h40000000;
        #1;
        $display("TFP32 decode 0x40000000: sign=%b k=%0d nar=%b",
                 t32_dec_sign, t32_dec_k, t32_dec_nar);
        if (t32_dec_sign === 1'b0 && t32_dec_zero === 1'b0) begin
            $display("PASS  tfp32_1p0_decode"); pass = pass + 1;
        end else begin
            $display("FAIL  tfp32_1p0_decode"); fail = fail + 1;
        end

        $display("=== RESULTS: PASS=%0d FAIL=%0d ===", pass, fail);
        if (fail == 0) $display("ALL PASS");
        else $display("SOME FAILURES");
        $finish;
    end
endmodule
