`default_nettype none
// tb_loihi_compat.v — Testbench for loihi_compat.v
// Apache-2.0
//
// Verifies all 16 Loihi-1 opcode mappings plus edge cases.
// Compatible with: iverilog -g2005
//
// NeuronConstant canonical hardware catalog
// DOI: 10.5281/zenodo.19227877 · Apache-2.0

`timescale 1ns/1ps

module tb_loihi_compat;

    // DUT inputs
    reg        opcode_valid;
    reg  [3:0] loihi_opcode;
    reg [15:0] loihi_operand_a;
    reg [15:0] loihi_operand_b;

    // DUT outputs
    wire [9:0]  tri27_opcode;
    wire [15:0] tri27_operand_a;
    wire [15:0] tri27_operand_b;
    wire        tri27_valid;
    wire        unsupported;

    // Instantiate DUT
    loihi_compat dut (
        .opcode_valid     (opcode_valid),
        .loihi_opcode     (loihi_opcode),
        .loihi_operand_a  (loihi_operand_a),
        .loihi_operand_b  (loihi_operand_b),
        .tri27_opcode     (tri27_opcode),
        .tri27_operand_a  (tri27_operand_a),
        .tri27_operand_b  (tri27_operand_b),
        .tri27_valid      (tri27_valid),
        .unsupported      (unsupported)
    );

    integer pass_count;
    integer fail_count;

    task check;
        input [63:0] test_id;
        input [9:0]  exp_opcode;
        input        exp_valid;
        input        exp_unsupported;
        begin
            #1; // let combinational settle
            if (tri27_opcode === exp_opcode &&
                tri27_valid  === exp_valid  &&
                unsupported  === exp_unsupported) begin
                $display("PASS [%0d] loihi_op=0x%0h tri27_op=0x%03h valid=%b unsup=%b",
                         test_id, loihi_opcode, tri27_opcode, tri27_valid, unsupported);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL [%0d] loihi_op=0x%0h  got: tri27_op=0x%04h valid=%b unsup=%b  exp: tri27_op=0x%04h valid=%b unsup=%b",
                         test_id, loihi_opcode,
                         tri27_opcode, tri27_valid, unsupported,
                         exp_opcode, exp_valid, exp_unsupported);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        loihi_operand_a = 16'hA5A5;
        loihi_operand_b = 16'h5A5A;
        opcode_valid    = 1'b1;

        // ---------------------------------------------------------------
        // Test 1: NOP (0x0) → TRI-27 0x000
        loihi_opcode = 4'h0;
        check(1, 10'h000, 1'b1, 1'b0);

        // Test 2: MOV (0x1) → TRI-27 0x010
        loihi_opcode = 4'h1;
        check(2, 10'h010, 1'b1, 1'b0);

        // Test 3: ADD (0x2) → TRI-27 0x020
        loihi_opcode = 4'h2;
        check(3, 10'h020, 1'b1, 1'b0);

        // Test 4: SUB (0x3) → TRI-27 0x021
        loihi_opcode = 4'h3;
        check(4, 10'h021, 1'b1, 1'b0);

        // Test 5: MUL (0x4) → TRI-27 0x030
        loihi_opcode = 4'h4;
        check(5, 10'h030, 1'b1, 1'b0);

        // Test 6: MAC (0x5) → TRI-27 0x040
        loihi_opcode = 4'h5;
        check(6, 10'h040, 1'b1, 1'b0);

        // Test 7: LIF_UPDATE (0x6) → TRI-27 0x100
        loihi_opcode = 4'h6;
        check(7, 10'h100, 1'b1, 1'b0);

        // Test 8: STDP_UPDATE (0x7) → TRI-27 0x108
        loihi_opcode = 4'h7;
        check(8, 10'h108, 1'b1, 1'b0);

        // Test 9: SPIKE_OUT (0x8) → TRI-27 0x110
        loihi_opcode = 4'h8;
        check(9, 10'h110, 1'b1, 1'b0);

        // Test 10: SET_REWARD (0x9) → TRI-27 0x180
        loihi_opcode = 4'h9;
        check(10, 10'h180, 1'b1, 1'b0);

        // Test 11: SET_LR (0xA) → TRI-27 0x188
        loihi_opcode = 4'hA;
        check(11, 10'h188, 1'b1, 1'b0);

        // Test 12: BARRIER (0xB) → TRI-27 0x1F0
        loihi_opcode = 4'hB;
        check(12, 10'h1F0, 1'b1, 1'b0);

        // Test 13: READ_TRACE (0xC) → TRI-27 0x1F8
        loihi_opcode = 4'hC;
        check(13, 10'h1F8, 1'b1, 1'b0);

        // Test 14: WRITE_WEIGHT (0xD) → TRI-27 0x200
        loihi_opcode = 4'hD;
        check(14, 10'h200, 1'b1, 1'b0);

        // Test 15: READ_WEIGHT (0xE) → TRI-27 0x208
        loihi_opcode = 4'hE;
        check(15, 10'h208, 1'b1, 1'b0);

        // Test 16: RESERVED (0xF) → unsupported=1, valid=0
        loihi_opcode = 4'hF;
        check(16, 10'h000, 1'b0, 1'b1);

        // ---------------------------------------------------------------
        // Edge case Test 17: opcode_valid=0 → tri27_valid must be 0
        opcode_valid = 1'b0;
        loihi_opcode = 4'h2; // ADD (would be valid if opcode_valid were 1)
        check(17, 10'h000, 1'b0, 1'b0);

        // ---------------------------------------------------------------
        // Summary
        $display("----------------------------------------");
        $display("Results: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("SOME TESTS FAILED");
            $finish(1);
        end
        $finish;
    end

    // Timeout guard
    initial begin
        #10000;
        $display("TIMEOUT");
        $finish(1);
    end

endmodule
`default_nettype wire
