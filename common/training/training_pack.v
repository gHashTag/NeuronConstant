// SPDX-License-Identifier: MIT
// training_pack.v — top-level opcode dispatcher for training modules
//
// Opcode (3-bit):
//   3'b000 = ADAMW         — AdamW optimizer step (single param)
//   3'b001 = MUON          — Muon optimizer step (3x3 matrix)
//   3'b010 = MUONCWD       — Muon + Coupled Weight Decay
//   3'b011 = PHILR_LOOKUP  — φ-LR ROM lookup (step_idx -> lr)
//   3'b100 = PHILR_DECAY   — φ-LR warmup + decay
//   3'b101 = JEPA_EMA      — T-JEPA EMA update (single param)
//   3'b110 = JEPA_EMA_ARR  — T-JEPA EMA array (9 params)
//
// Inputs/outputs are multiplexed based on opcode.
// Modules are always instantiated; opcode gates outputs.
//
// R-SI-1 clean: all multiplications in sub-modules via gf16_mul.
// Verilog-2005, `default_nettype none.

`default_nettype none

module training_pack (
    input  wire        clk,
    input  wire        rst_n,

    // Control
    input  wire [2:0]  opcode,
    input  wire        trigger,      // start pulse

    // ---- AdamW / scalar optimizer ----
    input  wire [15:0] adamw_grad,
    input  wire [15:0] adamw_lr,
    output wire [15:0] adamw_param_out,
    output wire        adamw_done,

    // ---- Muon / Muon-CWD: 3x3 gradient matrix ----
    input  wire [15:0] mat_g0,  mat_g1,  mat_g2,
    input  wire [15:0] mat_g3,  mat_g4,  mat_g5,
    input  wire [15:0] mat_g6,  mat_g7,  mat_g8,

    // ---- Muon-CWD additional: params + hyperparams ----
    input  wire [15:0] cwd_p0,  cwd_p1,  cwd_p2,
    input  wire [15:0] cwd_p3,  cwd_p4,  cwd_p5,
    input  wire [15:0] cwd_p6,  cwd_p7,  cwd_p8,
    input  wire [15:0] cwd_lr,
    input  wire [15:0] cwd_wd,

    // Muon output (3x3 update)
    output wire [15:0] muon_u0, muon_u1, muon_u2,
    output wire [15:0] muon_u3, muon_u4, muon_u5,
    output wire [15:0] muon_u6, muon_u7, muon_u8,
    output wire        muon_done,

    // Muon-CWD output
    output wire [15:0] cwd_p0_out, cwd_p1_out, cwd_p2_out,
    output wire [15:0] cwd_p3_out, cwd_p4_out, cwd_p5_out,
    output wire [15:0] cwd_p6_out, cwd_p7_out, cwd_p8_out,
    output wire        cwd_done,

    // ---- φ-LR lookup ----
    input  wire [5:0]  philr_step_idx,
    output wire [15:0] philr_lr_val,

    // ---- φ-LR warmup ----
    input  wire [15:0] philr_step_cnt,
    input  wire [15:0] philr_max_lr,
    input  wire [5:0]  philr_warmup_steps,
    output wire [15:0] philr_warmup_lr,

    // ---- JEPA EMA single ----
    input  wire [15:0] ema_target_in,
    input  wire [15:0] ema_online_in,
    input  wire [15:0] ema_decay_in,
    output wire [15:0] ema_target_out,

    // ---- JEPA EMA array (9 params) ----
    input  wire [143:0] ema_arr_online,    // 9 x 16 bits
    input  wire [15:0]  ema_arr_decay,
    output wire [143:0] ema_arr_target,
    output wire         ema_arr_done,

    // Combined done signal
    output reg  done_out
);

    // --- Opcode constants ---
    localparam [2:0] OP_ADAMW       = 3'b000;
    localparam [2:0] OP_MUON        = 3'b001;
    localparam [2:0] OP_MUONCWD     = 3'b010;
    localparam [2:0] OP_PHILR_LKP   = 3'b011;
    localparam [2:0] OP_PHILR_DECAY = 3'b100;
    localparam [2:0] OP_JEPA_EMA    = 3'b101;
    localparam [2:0] OP_JEPA_ARR    = 3'b110;

    // Gate triggers per opcode
    wire trig_adamw = trigger && (opcode == OP_ADAMW);
    wire trig_muon  = trigger && (opcode == OP_MUON);
    wire trig_cwd   = trigger && (opcode == OP_MUONCWD);
    wire trig_ema_arr = trigger && (opcode == OP_JEPA_ARR);

    // ---- AdamW instance ----
    adamw_optimizer u_adamw (
        .clk(clk), .rst_n(rst_n), .step(trig_adamw),
        .grad(adamw_grad), .lr(adamw_lr),
        .param(adamw_param_out),
        .done(adamw_done)
    );

    // ---- Muon instance ----
    muon_optimizer u_muon (
        .clk(clk), .rst_n(rst_n), .step(trig_muon),
        .g0(mat_g0), .g1(mat_g1), .g2(mat_g2),
        .g3(mat_g3), .g4(mat_g4), .g5(mat_g5),
        .g6(mat_g6), .g7(mat_g7), .g8(mat_g8),
        .u0(muon_u0), .u1(muon_u1), .u2(muon_u2),
        .u3(muon_u3), .u4(muon_u4), .u5(muon_u5),
        .u6(muon_u6), .u7(muon_u7), .u8(muon_u8),
        .done(muon_done)
    );

    // ---- Muon-CWD instance ----
    muon_cwd u_muon_cwd (
        .clk(clk), .rst_n(rst_n), .step(trig_cwd),
        .p0(cwd_p0), .p1(cwd_p1), .p2(cwd_p2),
        .p3(cwd_p3), .p4(cwd_p4), .p5(cwd_p5),
        .p6(cwd_p6), .p7(cwd_p7), .p8(cwd_p8),
        .g0(mat_g0), .g1(mat_g1), .g2(mat_g2),
        .g3(mat_g3), .g4(mat_g4), .g5(mat_g5),
        .g6(mat_g6), .g7(mat_g7), .g8(mat_g8),
        .lr(cwd_lr), .wd_coeff(cwd_wd),
        .p0_out(cwd_p0_out), .p1_out(cwd_p1_out), .p2_out(cwd_p2_out),
        .p3_out(cwd_p3_out), .p4_out(cwd_p4_out), .p5_out(cwd_p5_out),
        .p6_out(cwd_p6_out), .p7_out(cwd_p7_out), .p8_out(cwd_p8_out),
        .done(cwd_done)
    );

    // ---- φ-LR ROM instance ----
    phi_lr_rom u_philr_rom (
        .step_idx(philr_step_idx),
        .lr_val(philr_lr_val)
    );

    // ---- φ-LR warmup instance ----
    phi_lr_warmup u_philr_warm (
        .step_cnt(philr_step_cnt),
        .max_lr(philr_max_lr),
        .warmup_steps(philr_warmup_steps),
        .lr_out(philr_warmup_lr)
    );

    // ---- JEPA EMA single instance ----
    jepa_ema u_ema (
        .target(ema_target_in),
        .online(ema_online_in),
        .decay(ema_decay_in),
        .target_new(ema_target_out)
    );

    // ---- JEPA EMA array instance ----
    jepa_ema_array #(.N_PARAMS(9)) u_ema_arr (
        .clk(clk), .rst_n(rst_n), .update(trig_ema_arr),
        .online_flat(ema_arr_online),
        .decay(ema_arr_decay),
        .target_flat(ema_arr_target),
        .done(ema_arr_done)
    );

    // Combined done
    always @(*) begin
        case (opcode)
            OP_ADAMW:       done_out = adamw_done;
            OP_MUON:        done_out = muon_done;
            OP_MUONCWD:     done_out = cwd_done;
            OP_PHILR_LKP:   done_out = trigger;  // combinational: instant
            OP_PHILR_DECAY: done_out = trigger;  // combinational: instant
            OP_JEPA_EMA:    done_out = trigger;  // combinational: instant
            OP_JEPA_ARR:    done_out = ema_arr_done;
            default:        done_out = 1'b0;
        endcase
    end

endmodule

`default_nettype wire
