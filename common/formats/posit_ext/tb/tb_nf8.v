// tb_nf8.v — Testbench for nf8 encode/decode round-trip
// Tests all 256 decode entries and verifies encode round-trip
`timescale 1ns/1ps

module tb_nf8;
    reg  [7:0]  in_idx;
    wire [15:0] lut_out;
    wire [7:0]  enc_idx;
    reg  [15:0] enc_in;

    // Note: both decode and encode share the same nf8 module
    // For round-trip test: decode index i → get value → encode value → check idx==i
    wire [7:0]  enc_idx_rt;  // round-trip encode result
    wire [15:0] dummy_dec;

    nf8 DUT_dec (.in_idx(in_idx), .lut_out(lut_out), .enc_in(lut_out), .enc_idx(enc_idx_rt));

    integer fail = 0;
    integer pass = 0;
    integer i;

    initial begin
        $display("=== tb_nf8: encode/decode round-trip for all 256 entries ===");

        for (i = 0; i < 256; i = i + 1) begin
            in_idx = i[7:0];
            #2; // combinational settle time
            // Check round-trip: encode(decode(i)) should return i
            if (enc_idx_rt === in_idx) begin
                pass = pass + 1;
            end else begin
                $display("FAIL  idx=0x%02X decoded=0x%04X re-encoded=0x%02X",
                         in_idx, lut_out, enc_idx_rt);
                fail = fail + 1;
            end
        end

        $display("Round-trip test: %0d/256 passed", pass);

        // Spot checks: known values
        // Index 0x7F should be slightly negative (just below 0)
        in_idx = 8'h7F; #2;
        $display("idx=0x7F: decoded=0x%04X (expect negative, small)", lut_out);
        if (lut_out[15] === 1'b1) begin // sign bit of int16
            $display("PASS  idx_7F_negative"); pass = pass + 1;
        end else begin
            $display("FAIL  idx_7F_negative got=0x%04X", lut_out); fail = fail + 1;
        end

        // Index 0x80 should be slightly positive
        in_idx = 8'h80; #2;
        $display("idx=0x80: decoded=0x%04X (expect positive, small)", lut_out);
        if (lut_out[15] === 1'b0) begin
            $display("PASS  idx_80_positive"); pass = pass + 1;
        end else begin
            $display("FAIL  idx_80_positive got=0x%04X", lut_out); fail = fail + 1;
        end

        // Index 0xFF should be the most positive (+1.0 = 0x7FFF)
        in_idx = 8'hFF; #2;
        $display("idx=0xFF: decoded=0x%04X (expect 0x7FFF = max positive)", lut_out);
        if (lut_out === 16'h7FFF) begin
            $display("PASS  idx_FF_max"); pass = pass + 1;
        end else begin
            $display("FAIL  idx_FF_max got=0x%04X", lut_out); fail = fail + 1;
        end

        // Index 0x00 should be the most negative (-1.0 ≈ 0x8001)
        in_idx = 8'h00; #2;
        $display("idx=0x00: decoded=0x%04X (expect 0x8001 = min negative)", lut_out);
        if (lut_out[15] === 1'b1) begin
            $display("PASS  idx_00_min_neg"); pass = pass + 1;
        end else begin
            $display("FAIL  idx_00_min_neg got=0x%04X", lut_out); fail = fail + 1;
        end

        $display("=== RESULTS: PASS=%0d FAIL=%0d ===", pass, fail);
        if (fail == 0) $display("ALL PASS");
        else $display("SOME FAILURES");
        $finish;
    end
endmodule
