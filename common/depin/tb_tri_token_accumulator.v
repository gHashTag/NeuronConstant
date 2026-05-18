// SPDX-License-Identifier: Apache-2.0
//
// tb_tri_token_accumulator.v — Self-checking testbench for tri_token_accumulator
//
// Part of the NeuronConstant canonical hardware catalog.
// DOI: 10.5281/zenodo.19227877
//
// Copyright 2024 gHashTag / Dmitrii Vasilev
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// R-SI-1: zero standalone `*` operators.
// Verilog-2005 compliant.

`default_nettype none
`timescale 1ns/1ps

module tb_tri_token_accumulator;

    // DUT parameters
    localparam WIDTH       = 16;
    localparam REWARD_BITS = 2;

    // DUT signals
    reg                   clk;
    reg                   rst_n;
    reg                   attest_pulse;
    reg  [REWARD_BITS-1:0] reward_amount;
    wire [WIDTH-1:0]      token_balance;
    wire                  overflow_flag;

    // Error counter
    integer errors;

    // Instantiate DUT
    tri_token_accumulator #(
        .WIDTH(WIDTH),
        .REWARD_BITS(REWARD_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .attest_pulse(attest_pulse),
        .reward_amount(reward_amount),
        .token_balance(token_balance),
        .overflow_flag(overflow_flag)
    );

    // Clock: 10 ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Task: apply one attest pulse
    task apply_pulse;
        input [REWARD_BITS-1:0] rwd;
        begin
            @(negedge clk);
            attest_pulse  = 1'b1;
            reward_amount = rwd;
            @(posedge clk); #1;
            attest_pulse  = 1'b0;
        end
    endtask

    // Task: check value
    task check_eq;
        input [WIDTH-1:0] actual;
        input [WIDTH-1:0] expected;
        input [63:0]      test_id;
        begin
            if (actual !== expected) begin
                $display("FAIL test %0d: got %0d, expected %0d", test_id, actual, expected);
                errors = errors + 1;
            end
        end
    endtask

    integer i;

    initial begin
        errors        = 0;
        rst_n         = 1'b0;
        attest_pulse  = 1'b0;
        reward_amount = {REWARD_BITS{1'b0}};

        // ----------------------------------------------------------------
        // TEST 1: Reset zeros the balance
        // ----------------------------------------------------------------
        repeat (3) @(posedge clk);
        #1;
        check_eq(token_balance, 16'd0, 1);
        if (overflow_flag !== 1'b0) begin
            $display("FAIL test 1b: overflow_flag should be 0 after reset");
            errors = errors + 1;
        end

        // Deassert reset
        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk); #1;

        // ----------------------------------------------------------------
        // TEST 2: 5 pulses with reward=1 → balance = 5
        // ----------------------------------------------------------------
        for (i = 0; i < 5; i = i + 1) begin
            apply_pulse(2'd1);
        end
        @(posedge clk); #1;
        check_eq(token_balance, 16'd5, 2);

        // ----------------------------------------------------------------
        // TEST 3: 5 more pulses with reward=4 (saturated to 3 bits → 2'b11=3,
        //         but REWARD_BITS=2 max=3; spec says reward=4 meaning
        //         maximum reward=3 for 2-bit field, however spec says reward=4
        //         so we use WIDTH=16, REWARD_BITS=3 variant interpretation.
        //         Per spec: "1-4 tokens per attest" with REWARD_BITS=2,
        //         reward=4 = 2'b00 wraps. Use REWARD_BITS=3 DUT instance below.)
        // ----------------------------------------------------------------
        // Spec says: 5 pulses reward=4 → balance=20.
        // With REWARD_BITS=2, reward=4 overflows to 0.
        // So for this test we use a separate DUT with REWARD_BITS=3.
        // ----------------------------------------------------------------

        // Reset and move to reward=4 test using a wider instance
        @(negedge clk); rst_n = 1'b0;
        @(posedge clk); #1;
        check_eq(token_balance, 16'd0, 3);
        @(negedge clk); rst_n = 1'b1;

        // ----------------------------------------------------------------
        // TEST 4: Saturation at MAX (65535) → overflow_flag asserted
        // ----------------------------------------------------------------
        // Load balance near MAX using reward=3 (max for 2-bit field)
        // 21845 * 3 = 65535. Apply 21845 pulses is impractical; instead
        // we test saturation with the wider testbench instance below.
        // ----------------------------------------------------------------

        $display("2-bit DUT sub-tests done. errors so far: %0d", errors);
    end

    // ================================================================
    // Second DUT with REWARD_BITS=3 for reward=4 and saturation tests
    // ================================================================
    reg                    clk2;
    reg                    rst_n2;
    reg                    ap2;
    reg  [2:0]             rwd2;
    wire [WIDTH-1:0]       bal2;
    wire                   ovf2;

    tri_token_accumulator #(
        .WIDTH(WIDTH),
        .REWARD_BITS(3)
    ) dut2 (
        .clk(clk2),
        .rst_n(rst_n2),
        .attest_pulse(ap2),
        .reward_amount(rwd2),
        .token_balance(bal2),
        .overflow_flag(ovf2)
    );

    initial clk2 = 1'b0;
    always #5 clk2 = ~clk2;

    integer j;

    initial begin
        rst_n2 = 1'b0;
        ap2    = 1'b0;
        rwd2   = 3'd0;

        // ----------------------------------------------------------------
        // TEST 2b: 5 pulses reward=1 → balance=5 (sanity on dut2)
        // ----------------------------------------------------------------
        repeat (3) @(posedge clk2);
        #1;
        if (bal2 !== 16'd0) begin
            $display("FAIL test 2b-reset: bal2=%0d expected 0", bal2);
        end
        @(negedge clk2); rst_n2 = 1'b1;

        for (j = 0; j < 5; j = j + 1) begin
            @(negedge clk2);
            ap2  = 1'b1;
            rwd2 = 3'd1;
            @(posedge clk2); #1;
            ap2  = 1'b0;
        end
        @(posedge clk2); #1;
        if (bal2 !== 16'd5) begin
            $display("FAIL test 2b: bal2=%0d expected 5", bal2);
            errors = errors + 1;
        end

        // ----------------------------------------------------------------
        // TEST 3: 5 pulses reward=4 → balance=25 (5 added to previous 5... )
        // Re-reset first for clean slate
        // ----------------------------------------------------------------
        @(negedge clk2); rst_n2 = 1'b0;
        @(posedge clk2); #1;
        @(negedge clk2); rst_n2 = 1'b1;

        for (j = 0; j < 5; j = j + 1) begin
            @(negedge clk2);
            ap2  = 1'b1;
            rwd2 = 3'd4;
            @(posedge clk2); #1;
            ap2  = 1'b0;
        end
        @(posedge clk2); #1;
        if (bal2 !== 16'd20) begin
            $display("FAIL test 3: bal2=%0d expected 20", bal2);
            errors = errors + 1;
        end else begin
            $display("PASS test 3: 5 pulses reward=4 -> balance=20");
        end

        // ----------------------------------------------------------------
        // TEST 4: Saturation at MAX (65535) → overflow_flag asserted
        // ----------------------------------------------------------------
        // Preload to 65530 by pulsing reward=1 65530 times is too slow;
        // use a small helper: load via 10922 pulses of reward=6 = 65532,
        // then 1 pulse of reward=3 → 65535.
        // 65530 via 6553 pulses of 10 exceeds 3-bit; use reset + forced
        // approach: 65535 / 7 = 9362 r1 → 9362 * 7 = 65534, +1 = 65535.
        // Simplest: 65535 pulses of reward=1 but that's slow.
        // Instead: we use a special narrow WIDTH=8 instance for saturation.
        // ----------------------------------------------------------------

        $display("dut2 tests done (reward=4 saturation uses dut3). errors: %0d", errors);
    end

    // ================================================================
    // Third DUT WIDTH=8, REWARD_BITS=3 — saturation tests
    // ================================================================
    reg                    clk3;
    reg                    rst_n3;
    reg                    ap3;
    reg  [2:0]             rwd3;
    wire [7:0]             bal3;
    wire                   ovf3;

    tri_token_accumulator #(
        .WIDTH(8),
        .REWARD_BITS(3)
    ) dut3 (
        .clk(clk3),
        .rst_n(rst_n3),
        .attest_pulse(ap3),
        .reward_amount(rwd3),
        .token_balance(bal3),
        .overflow_flag(ovf3)
    );

    initial clk3 = 1'b0;
    always #5 clk3 = ~clk3;

    integer k;

    initial begin
        rst_n3 = 1'b0;
        ap3    = 1'b0;
        rwd3   = 3'd0;

        repeat (3) @(posedge clk3);
        #1;
        // check reset
        if (bal3 !== 8'd0) begin
            $display("FAIL test 4-reset: bal3=%0d expected 0", bal3);
            errors = errors + 1;
        end
        @(negedge clk3); rst_n3 = 1'b1;

        // Fill to 255: 51 * 5 = 255 exactly
        for (k = 0; k < 51; k = k + 1) begin
            @(negedge clk3);
            ap3  = 1'b1;
            rwd3 = 3'd5;
            @(posedge clk3); #1;
            ap3  = 1'b0;
        end
        @(posedge clk3); #1;

        if (bal3 !== 8'd255) begin
            $display("FAIL test 4a: bal3=%0d expected 255 (MAX)", bal3);
            errors = errors + 1;
        end else begin
            $display("PASS test 4a: balance saturated at MAX=255");
        end

        // overflow_flag must be asserted
        if (ovf3 !== 1'b1) begin
            $display("FAIL test 4b: overflow_flag=%0b expected 1", ovf3);
            errors = errors + 1;
        end else begin
            $display("PASS test 4b: overflow_flag asserted at MAX");
        end

        // ----------------------------------------------------------------
        // TEST 5: attest_pulse ignored when overflow_flag set
        // ----------------------------------------------------------------
        @(negedge clk3);
        ap3  = 1'b1;
        rwd3 = 3'd1;
        @(posedge clk3); #1;
        ap3  = 1'b0;
        @(posedge clk3); #1;

        if (bal3 !== 8'd255) begin
            $display("FAIL test 5: bal3=%0d expected still 255 after overflow pulse", bal3);
            errors = errors + 1;
        end else begin
            $display("PASS test 5: attest_pulse ignored when overflow_flag set");
        end

        // ----------------------------------------------------------------
        // FINAL RESULT
        // ----------------------------------------------------------------
        #20;
        if (errors == 0) begin
            $display("PASS");
        end else begin
            $display("FAIL: %0d error(s)", errors);
            $finish(1);
        end
        $finish;
    end

endmodule

`default_nettype wire
