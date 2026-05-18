// SPDX-License-Identifier: MIT
// tb_training_pack.v — Testbench for training_pack dispatcher
//
// Tests each opcode dispatches correctly and produces valid output.
// PASS criteria: each opcode returns non-garbage result.

`default_nettype none
`timescale 1ns/1ps

module tb_training_pack;

    reg clk, rst_n, trigger;
    reg [2:0] opcode;

    // AdamW
    reg  [15:0] adamw_grad, adamw_lr;
    wire [15:0] adamw_param_out;
    wire        adamw_done;

    // Muon matrix
    reg  [15:0] mat_g0, mat_g1, mat_g2, mat_g3, mat_g4, mat_g5, mat_g6, mat_g7, mat_g8;
    reg  [15:0] cwd_p0, cwd_p1, cwd_p2, cwd_p3, cwd_p4, cwd_p5, cwd_p6, cwd_p7, cwd_p8;
    reg  [15:0] cwd_lr, cwd_wd;
    wire [15:0] muon_u0, muon_u1, muon_u2, muon_u3, muon_u4, muon_u5, muon_u6, muon_u7, muon_u8;
    wire        muon_done;
    wire [15:0] cwd_p0_out, cwd_p1_out, cwd_p2_out, cwd_p3_out, cwd_p4_out;
    wire [15:0] cwd_p5_out, cwd_p6_out, cwd_p7_out, cwd_p8_out;
    wire        cwd_done;

    // phi-LR
    reg  [5:0]  philr_step_idx;
    wire [15:0] philr_lr_val;
    reg  [15:0] philr_step_cnt, philr_max_lr;
    reg  [5:0]  philr_warmup_steps;
    wire [15:0] philr_warmup_lr;

    // JEPA EMA
    reg  [15:0] ema_target_in, ema_online_in, ema_decay_in;
    wire [15:0] ema_target_out;
    reg  [143:0] ema_arr_online;
    reg  [15:0]  ema_arr_decay;
    wire [143:0] ema_arr_target;
    wire         ema_arr_done;

    wire done_out;

    training_pack dut (
        .clk(clk), .rst_n(rst_n), .opcode(opcode), .trigger(trigger),
        .adamw_grad(adamw_grad), .adamw_lr(adamw_lr),
        .adamw_param_out(adamw_param_out), .adamw_done(adamw_done),
        .mat_g0(mat_g0), .mat_g1(mat_g1), .mat_g2(mat_g2),
        .mat_g3(mat_g3), .mat_g4(mat_g4), .mat_g5(mat_g5),
        .mat_g6(mat_g6), .mat_g7(mat_g7), .mat_g8(mat_g8),
        .cwd_p0(cwd_p0), .cwd_p1(cwd_p1), .cwd_p2(cwd_p2),
        .cwd_p3(cwd_p3), .cwd_p4(cwd_p4), .cwd_p5(cwd_p5),
        .cwd_p6(cwd_p6), .cwd_p7(cwd_p7), .cwd_p8(cwd_p8),
        .cwd_lr(cwd_lr), .cwd_wd(cwd_wd),
        .muon_u0(muon_u0), .muon_u1(muon_u1), .muon_u2(muon_u2),
        .muon_u3(muon_u3), .muon_u4(muon_u4), .muon_u5(muon_u5),
        .muon_u6(muon_u6), .muon_u7(muon_u7), .muon_u8(muon_u8),
        .muon_done(muon_done),
        .cwd_p0_out(cwd_p0_out), .cwd_p1_out(cwd_p1_out), .cwd_p2_out(cwd_p2_out),
        .cwd_p3_out(cwd_p3_out), .cwd_p4_out(cwd_p4_out), .cwd_p5_out(cwd_p5_out),
        .cwd_p6_out(cwd_p6_out), .cwd_p7_out(cwd_p7_out), .cwd_p8_out(cwd_p8_out),
        .cwd_done(cwd_done),
        .philr_step_idx(philr_step_idx), .philr_lr_val(philr_lr_val),
        .philr_step_cnt(philr_step_cnt), .philr_max_lr(philr_max_lr),
        .philr_warmup_steps(philr_warmup_steps), .philr_warmup_lr(philr_warmup_lr),
        .ema_target_in(ema_target_in), .ema_online_in(ema_online_in),
        .ema_decay_in(ema_decay_in), .ema_target_out(ema_target_out),
        .ema_arr_online(ema_arr_online), .ema_arr_decay(ema_arr_decay),
        .ema_arr_target(ema_arr_target), .ema_arr_done(ema_arr_done),
        .done_out(done_out)
    );

    always #5 clk = ~clk;

    integer pass_count, fail_count, timeout;

    initial begin
        clk = 0; rst_n = 0; trigger = 0; opcode = 0;
        pass_count = 0; fail_count = 0;

        // Initialize all inputs
        adamw_grad = 16'h3C00; adamw_lr = 16'h3714;
        mat_g0 = 16'h3E00; mat_g1 = 16'h0000; mat_g2 = 16'h0000;
        mat_g3 = 16'h0000; mat_g4 = 16'h3E00; mat_g5 = 16'h0000;
        mat_g6 = 16'h0000; mat_g7 = 16'h0000; mat_g8 = 16'h3E00;
        cwd_p0 = 16'h3E00; cwd_p1 = 16'h3E00; cwd_p2 = 16'h3E00;
        cwd_p3 = 16'h3E00; cwd_p4 = 16'h3E00; cwd_p5 = 16'h3E00;
        cwd_p6 = 16'h3E00; cwd_p7 = 16'h3E00; cwd_p8 = 16'h3E00;
        cwd_lr = 16'h3714; cwd_wd = 16'h3714;
        philr_step_idx = 6'd0;
        philr_step_cnt = 16'd10; philr_max_lr = 16'h39C7;
        philr_warmup_steps = 6'd27;
        ema_target_in = 16'h0000; ema_online_in = 16'h3E00;
        ema_decay_in  = 16'h3DFE;
        ema_arr_online = {9{16'h3E00}};
        ema_arr_decay  = 16'h3DFE;

        $display("=== tb_training_pack: opcode dispatcher test ===");

        #12 rst_n = 1;
        #10;

        // Test OP_PHILR_LOOKUP (combinational, instant)
        $display("Test OP_PHILR_LOOKUP (3'b011)");
        opcode = 3'b011; philr_step_idx = 6'd26; trigger = 1;
        @(posedge clk); #1; trigger = 0;
        if (philr_lr_val != 16'h0000) begin
            $display("  PASS: phi_lr_val = 0x%04X (non-zero)", philr_lr_val);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: phi_lr_val = 0");
            fail_count = fail_count + 1;
        end
        #20;

        // Test OP_PHILR_DECAY (combinational)
        $display("Test OP_PHILR_DECAY (3'b100)");
        opcode = 3'b100; trigger = 1;
        @(posedge clk); #1; trigger = 0;
        if (philr_warmup_lr != 16'h0000) begin
            $display("  PASS: philr_warmup_lr = 0x%04X (non-zero)", philr_warmup_lr);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: philr_warmup_lr = 0");
            fail_count = fail_count + 1;
        end
        #20;

        // Test OP_JEPA_EMA (combinational)
        $display("Test OP_JEPA_EMA (3'b101)");
        opcode = 3'b101; trigger = 1;
        @(posedge clk); #1; trigger = 0;
        if (ema_target_out != 16'h0000) begin
            $display("  PASS: ema_target_out = 0x%04X (non-zero)", ema_target_out);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: ema_target_out = 0");
            fail_count = fail_count + 1;
        end
        #20;

        // Test OP_ADAMW
        $display("Test OP_ADAMW (3'b000)");
        opcode = 3'b000; trigger = 1;
        @(posedge clk); #1; trigger = 0;
        timeout = 0;
        while (!adamw_done && timeout < 30) begin
            @(posedge clk); #1; timeout = timeout + 1;
        end
        if (adamw_done) begin
            $display("  PASS: AdamW done, param = 0x%04X", adamw_param_out);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: AdamW timed out");
            fail_count = fail_count + 1;
        end
        #20;

        // Test OP_MUON
        $display("Test OP_MUON (3'b001)");
        opcode = 3'b001; trigger = 1;
        @(posedge clk); #1; trigger = 0;
        timeout = 0;
        while (!muon_done && timeout < 50) begin
            @(posedge clk); #1; timeout = timeout + 1;
        end
        if (muon_done) begin
            $display("  PASS: Muon done, u0 = 0x%04X", muon_u0);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: Muon timed out");
            fail_count = fail_count + 1;
        end
        #20;

        // Test OP_JEPA_ARR
        $display("Test OP_JEPA_ARR (3'b110)");
        opcode = 3'b110; trigger = 1;
        @(posedge clk); #1; trigger = 0;
        timeout = 0;
        while (!ema_arr_done && timeout < 10) begin
            @(posedge clk); #1; timeout = timeout + 1;
        end
        if (ema_arr_done) begin
            $display("  PASS: EMA array done");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: EMA array timed out");
            fail_count = fail_count + 1;
        end

        $display("=== Results: PASS=%0d FAIL=%0d ===", pass_count, fail_count);
        if (fail_count == 0) $display("*** ALL PASS ***");
        $finish;
    end

endmodule

`default_nettype wire
