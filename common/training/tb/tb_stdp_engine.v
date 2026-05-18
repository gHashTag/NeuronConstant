// tb_stdp_engine.v — Testbench for stdp_engine + stdp_lut_rom
// Tests:
//   T1: pre→post (LTP, weight↑)
//   T2: post→pre (LTD, weight↓)
//   T3: R-STDP reward=+10 (enhanced LTP vs reward=0-gated check)
//   T4: R-STDP reward=-10 (inverted update → weight↓ for pre→post)
//   T5: Anti-Hebbian mode (LTP↔LTD swap)
//   T6: Eligibility decay (80 cycles without spike → trace ≈ 0)
//   T7: Boundary saturation (weight clamp at +127 / -128)
// Verilog-2005
`timescale 1ns/1ps
`default_nettype none

module tb_stdp_engine;

    // -----------------------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------------------
    parameter CLK_HALF = 5; // 100 MHz

    // -----------------------------------------------------------------------
    // DUT signals
    // -----------------------------------------------------------------------
    reg          clk;
    reg          rst_n;
    reg          pre_spike;
    reg          post_spike;
    reg  signed [7:0] reward;
    reg          anti_hebbian_mode;
    reg  [5:0]   lut_addr;
    reg  [7:0]   lut_wdata;
    reg          lut_we;
    reg  [3:0]   lr_shift;

    wire signed [7:0]  weight;
    wire [9:0]         trace_pre;
    wire [9:0]         trace_post;
    wire               update_event;

    // -----------------------------------------------------------------------
    // DUT instantiation
    // -----------------------------------------------------------------------
    stdp_engine #(
        .WEIGHT_BITS(8),
        .TRACE_BITS(10),
        .LUT_DEPTH(64)
    ) dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .pre_spike        (pre_spike),
        .post_spike       (post_spike),
        .reward           (reward),
        .anti_hebbian_mode(anti_hebbian_mode),
        .lut_addr         (lut_addr),
        .lut_wdata        (lut_wdata),
        .lut_we           (lut_we),
        .lr_shift         (lr_shift),
        .weight           (weight),
        .trace_pre        (trace_pre),
        .trace_post       (trace_post),
        .update_event     (update_event)
    );

    // -----------------------------------------------------------------------
    // Clock
    // -----------------------------------------------------------------------
    initial clk = 1'b0;
    always #CLK_HALF clk = ~clk;

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------
    task do_reset;
        begin
            rst_n             = 1'b0;
            pre_spike         = 1'b0;
            post_spike        = 1'b0;
            reward            = 8'sd10;
            anti_hebbian_mode = 1'b0;
            lut_addr          = 6'd0;
            lut_wdata         = 8'd0;
            lut_we            = 1'b0;
            lr_shift          = 4'd0; // lr = 1 (full trace update)
            @(posedge clk); #1;
            @(posedge clk); #1;
            rst_n = 1'b1;
            @(posedge clk); #1;
        end
    endtask

    task fire_pre;
        begin
            pre_spike = 1'b1;
            @(posedge clk); #1;
            pre_spike = 1'b0;
        end
    endtask

    task fire_post;
        begin
            post_spike = 1'b1;
            @(posedge clk); #1;
            post_spike = 1'b0;
        end
    endtask

    task wait_n;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1) begin
                @(posedge clk); #1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Pass/fail bookkeeping
    // -----------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    task check;
        input [255:0] label;
        input         cond;
        begin
            if (cond) begin
                $display("  PASS: %0s", label);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %0s  (weight=%0d tp=%0d tpost=%0d)",
                         label, $signed(weight), trace_pre, trace_post);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Main
    // -----------------------------------------------------------------------
    reg signed [7:0] w0, w1;

    initial begin
        pass_count = 0;
        fail_count = 0;
        $display("=== tb_stdp_engine START ===");

        // =================================================================
        // T1: LTP — pre→post ordering raises weight
        // =================================================================
        $display("\n--- T1: LTP pre->post ---");
        do_reset;
        // Fire post first (dt_post=0 after), then pre a few cycles later
        // When pre fires, post_recent=1, trace_post >= 1, LTP applies
        fire_post;
        wait_n(5);
        w0 = weight;
        fire_pre;
        wait_n(2);
        w1 = weight;
        check("T1: LTP weight increased",   w1 > w0);
        check("T1: trace_pre non-zero",     trace_pre  > 10'd0);
        check("T1: trace_post non-zero",    trace_post > 10'd0);

        // =================================================================
        // T2: LTD — post→pre ordering lowers weight
        // =================================================================
        $display("\n--- T2: LTD post->pre ---");
        do_reset;
        fire_pre;
        wait_n(5);
        w0 = weight;
        fire_post;
        wait_n(2);
        w1 = weight;
        check("T2: LTD weight decreased",   w1 < w0);
        check("T2: trace_pre non-zero",     trace_pre  > 10'd0);
        check("T2: trace_post non-zero",    trace_post > 10'd0);

        // =================================================================
        // T3: R-STDP reward=+10 → LTP (weight↑ on pre→post)
        // =================================================================
        $display("\n--- T3: R-STDP reward=+10 ---");
        do_reset;
        reward = 8'sd10;
        fire_post;
        wait_n(5);
        w0 = weight;
        fire_pre;
        wait_n(2);
        w1 = weight;
        check("T3: R-STDP +reward LTP weight up", w1 > w0);

        // =================================================================
        // T4: R-STDP reward=-10 → invert LTP → weight↓ on pre→post
        // =================================================================
        $display("\n--- T4: R-STDP reward=-10 ---");
        do_reset;
        reward = -8'sd10;
        fire_post;
        wait_n(5);
        w0 = weight;
        fire_pre;
        wait_n(2);
        w1 = weight;
        check("T4: R-STDP -reward inverts LTP weight down", w1 < w0);

        // =================================================================
        // T5: Anti-Hebbian — pre→post should depress (not potentiate)
        // =================================================================
        $display("\n--- T5: Anti-Hebbian mode ---");
        do_reset;
        reward = 8'sd10;
        anti_hebbian_mode = 1'b1;
        fire_post;
        wait_n(5);
        w0 = weight;
        fire_pre;
        wait_n(2);
        w1 = weight;
        check("T5: Anti-Hebbian pre->post depresses", w1 < w0);
        anti_hebbian_mode = 1'b0;

        // Also check anti-Hebbian post→pre potentiates
        do_reset;
        reward = 8'sd10;
        anti_hebbian_mode = 1'b1;
        fire_pre;
        wait_n(5);
        w0 = weight;
        fire_post;
        wait_n(2);
        w1 = weight;
        check("T5: Anti-Hebbian post->pre potentiates", w1 > w0);
        anti_hebbian_mode = 1'b0;

        // =================================================================
        // T6: Eligibility trace decay — 80 cycles silence → trace ~ 0
        // (DECAY_PERIOD=16, 80 cycles = 5 decays = >>5, trace=1 → 0)
        // =================================================================
        $display("\n--- T6: Eligibility decay ---");
        do_reset;
        fire_pre;
        fire_post;
        wait_n(90);
        check("T6: trace_pre decayed near 0",  trace_pre  <= 10'd1);
        check("T6: trace_post decayed near 0", trace_post <= 10'd1);

        // =================================================================
        // T7: Saturation — weight clamps at +127 and -128
        //
        // Strategy: build up a large trace_post (fire post many times),
        // then fire pre once — delta = trace_post >> 0 >> large → saturate.
        // Repeat to overcome any partial decay.
        // =================================================================
        $display("\n--- T7: Upper saturation (+127) ---");
        do_reset;
        reward = 8'sd10;
        lr_shift = 4'd0; // delta = trace_post (no shift)
        begin : blk_ltp
            integer j;
            // Fire 130 post spikes back-to-back to saturate trace_post (10-bit, max 1023)
            // trace_post will reach 130 (> 127)
            for (j = 0; j < 130; j = j + 1) begin
                fire_post;
            end
            // Fire pre once: delta_ltp_mag = min(trace_post, 127) = 127
            // weight = 0 + 127 = 127
            fire_pre;
            wait_n(2);
        end
        wait_n(2);
        check("T7: Weight upper-clamped at +127", weight == 8'sd127);

        $display("\n--- T7: Lower saturation (-128) ---");
        do_reset;
        reward = 8'sd10;
        lr_shift = 4'd0;
        begin : blk_ltd
            integer k;
            // Fire 130 pre spikes to saturate trace_pre
            for (k = 0; k < 130; k = k + 1) begin
                fire_pre;
            end
            // Fire post: delta_ltd_mag = 127, weight = 0 - 127 = -127
            // Need one more pass to reach -128
            fire_post;
            wait_n(2);
            // Now trace_pre still ~129, fire post again -> -127 - 127 = -128 (clamped)
            // Rebuild pre trace a bit
            for (k = 0; k < 5; k = k + 1) fire_pre;
            fire_post;
            wait_n(2);
        end
        wait_n(2);
        check("T7: Weight lower-clamped at -128", weight == -8'sd128);

        // =================================================================
        // Summary
        // =================================================================
        $display("\n=== RESULTS ===");
        $display("  PASS: %0d", pass_count);
        $display("  FAIL: %0d", fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end

    // Watchdog
    initial begin
        #2000000;
        $display("WATCHDOG TIMEOUT");
        $finish;
    end

endmodule
`default_nettype wire
