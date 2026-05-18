// SPDX-License-Identifier: MIT
// muon_cwd.v — Muon optimizer with Coupled Weight Decay
//
// Wraps muon_optimizer, adds weight decay:
//   param_new = param - lr * (muon_update + wd * param)
//
// Coupled Weight Decay (CWD): only apply decay where momentum and
// gradient have same sign. Simplified here: always apply.
//
// Inputs: param (3x3 GF16), gradient (3x3 GF16), lr (GF16), wd_coeff (GF16)
// Output: param_new (3x3 GF16)
//
// R-SI-1 clean: all multiplications via gf16_mul.
// Verilog-2005, `default_nettype none.

`default_nettype none

module muon_cwd (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        step,
    // Parameter (3x3 GF16)
    input  wire [15:0] p0, p1, p2,
    input  wire [15:0] p3, p4, p5,
    input  wire [15:0] p6, p7, p8,
    // Gradient (3x3 GF16)
    input  wire [15:0] g0, g1, g2,
    input  wire [15:0] g3, g4, g5,
    input  wire [15:0] g6, g7, g8,
    // Hyperparameters
    input  wire [15:0] lr,       // learning rate GF16
    input  wire [15:0] wd_coeff, // weight decay coefficient GF16
    // Output: updated parameters
    output reg  [15:0] p0_out, p1_out, p2_out,
    output reg  [15:0] p3_out, p4_out, p5_out,
    output reg  [15:0] p6_out, p7_out, p8_out,
    output wire        done
);

    // Wire param and gradient arrays
    wire [15:0] P [0:8];
    assign P[0]=p0; assign P[1]=p1; assign P[2]=p2;
    assign P[3]=p3; assign P[4]=p4; assign P[5]=p5;
    assign P[6]=p6; assign P[7]=p7; assign P[8]=p8;

    // Muon optimizer for gradient orthogonalization
    wire muon_done;
    wire [15:0] mu [0:8];
    reg  muon_step;

    muon_optimizer u_muon (
        .clk(clk), .rst_n(rst_n), .step(muon_step),
        .g0(g0), .g1(g1), .g2(g2),
        .g3(g3), .g4(g4), .g5(g5),
        .g6(g6), .g7(g7), .g8(g8),
        .u0(mu[0]), .u1(mu[1]), .u2(mu[2]),
        .u3(mu[3]), .u4(mu[4]), .u5(mu[5]),
        .u6(mu[6]), .u7(mu[7]), .u8(mu[8]),
        .done(muon_done)
    );

    // State machine
    reg [1:0] state;
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_MUON   = 2'd1;
    localparam [1:0] S_UPDATE = 2'd2;

    // wd_term[i] = wd_coeff * P[i]
    wire [15:0] wd_term [0:8];
    // total_update[i] = mu[i] + wd_term[i]
    wire [15:0] total_update [0:8];
    // lr_scaled[i] = lr * total_update[i]
    wire [15:0] lr_scaled [0:8];
    // p_new[i] = P[i] - lr_scaled[i]  (subtract = add with negated sign)
    wire [15:0] p_new [0:8];

    genvar gi;
    generate
        for (gi = 0; gi < 9; gi = gi + 1) begin : cwd_calc
            wire ov_wd, uv_wd, ov_lr, uv_lr;
            gf16_mul u_wd (
                .a(wd_coeff), .b(P[gi]),
                .result(wd_term[gi]), .overflow(ov_wd), .underflow(uv_wd)
            );
            gf16_add u_tu (
                .a(mu[gi]), .b(wd_term[gi]),
                .result(total_update[gi])
            );
            gf16_mul u_lr (
                .a(lr), .b(total_update[gi]),
                .result(lr_scaled[gi]), .overflow(ov_lr), .underflow(uv_lr)
            );
            // Subtract: negate lr_scaled sign bit, then add
            gf16_add u_pn (
                .a(P[gi]),
                .b({~lr_scaled[gi][15], lr_scaled[gi][14:0]}),
                .result(p_new[gi])
            );
        end
    endgenerate

    reg done_reg;
    assign done = done_reg;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            muon_step  <= 1'b0;
            done_reg   <= 1'b0;
            p0_out <= 16'd0; p1_out <= 16'd0; p2_out <= 16'd0;
            p3_out <= 16'd0; p4_out <= 16'd0; p5_out <= 16'd0;
            p6_out <= 16'd0; p7_out <= 16'd0; p8_out <= 16'd0;
        end else begin
            muon_step <= 1'b0;
            done_reg  <= 1'b0;
            case (state)
                S_IDLE: begin
                    if (step) begin
                        muon_step <= 1'b1;
                        state     <= S_MUON;
                    end
                end
                S_MUON: begin
                    if (muon_done) begin
                        state <= S_UPDATE;
                    end
                end
                S_UPDATE: begin
                    p0_out <= p_new[0]; p1_out <= p_new[1]; p2_out <= p_new[2];
                    p3_out <= p_new[3]; p4_out <= p_new[4]; p5_out <= p_new[5];
                    p6_out <= p_new[6]; p7_out <= p_new[7]; p8_out <= p_new[8];
                    done_reg <= 1'b1;
                    state    <= S_IDLE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
