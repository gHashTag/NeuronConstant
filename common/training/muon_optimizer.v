// SPDX-License-Identifier: MIT
// muon_optimizer.v — Muon optimizer top-level
//
// Applies Newton-Schulz orthogonalization to momentum buffer,
// outputs the orthogonalized gradient update.
//
// Algorithm:
//   1. Update momentum: m = momentum*m + (1-momentum)*grad
//   2. Orthogonalize m via 5-step NS: m_orth = NS5(m)
//   3. Output: update = m_orth
//
// All arithmetic in GF16. Momentum buffer = 3x3 GF16 registers.
// momentum constant: 0.95 (GF16: 0x3CF9)
// 1-momentum: 0.05 (GF16: 0x3280 approx)
//
// R-SI-1 clean: all multiplications via gf16_mul.
// Verilog-2005, `default_nettype none.

`default_nettype none

module muon_optimizer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        step,          // pulse: start one optimizer step
    // Gradient input (3x3 GF16)
    input  wire [15:0] g0, g1, g2,
    input  wire [15:0] g3, g4, g5,
    input  wire [15:0] g6, g7, g8,
    // Orthogonalized update output (3x3 GF16)
    output wire [15:0] u0, u1, u2,
    output wire [15:0] u3, u4, u5,
    output wire [15:0] u6, u7, u8,
    output wire        done
);

    // Momentum coefficient: 0.95 GF16
    localparam [15:0] MOM     = 16'h3CF9;
    // 1 - momentum: 0.05 GF16
    localparam [15:0] ONE_MOM = 16'h3280;

    // Momentum buffer (3x3 GF16 registers)
    reg [15:0] mbuf [0:8];

    // Wires for momentum update: m_new = MOM*m + ONE_MOM*g
    wire [15:0] mom_m [0:8];
    wire [15:0] mom_g [0:8];
    wire [15:0] m_new [0:8];

    genvar gi;
    generate
        for (gi = 0; gi < 9; gi = gi + 1) begin : mom_update
            wire ov_m, uv_m, ov_g, uv_g;
            gf16_mul u_mm (
                .a(MOM),     .b(mbuf[gi]),
                .result(mom_m[gi]), .overflow(ov_m), .underflow(uv_m)
            );
            // g array (wired below)
        end
    endgenerate

    // Wire gradient array
    wire [15:0] G [0:8];
    assign G[0]=g0; assign G[1]=g1; assign G[2]=g2;
    assign G[3]=g3; assign G[4]=g4; assign G[5]=g5;
    assign G[6]=g6; assign G[7]=g7; assign G[8]=g8;

    generate
        for (gi = 0; gi < 9; gi = gi + 1) begin : mom_g_calc
            wire ov_g, uv_g;
            gf16_mul u_mg (
                .a(ONE_MOM), .b(G[gi]),
                .result(mom_g[gi]), .overflow(ov_g), .underflow(uv_g)
            );
            gf16_add u_ma (
                .a(mom_m[gi]), .b(mom_g[gi]),
                .result(m_new[gi])
            );
        end
    endgenerate

    // State machine for step
    reg [1:0] state;
    localparam [1:0] S_IDLE = 2'd0;
    localparam [1:0] S_NS   = 2'd1;
    localparam [1:0] S_DONE = 2'd2;

    // NS5 instantiation
    reg  ns_start;
    wire ns_done;
    reg  [15:0] ns_in [0:8];
    wire [15:0] ns_out [0:8];

    muon_ns_5step u_ns5 (
        .clk(clk), .rst_n(rst_n), .start(ns_start),
        .x0_in(ns_in[0]), .x1_in(ns_in[1]), .x2_in(ns_in[2]),
        .x3_in(ns_in[3]), .x4_in(ns_in[4]), .x5_in(ns_in[5]),
        .x6_in(ns_in[6]), .x7_in(ns_in[7]), .x8_in(ns_in[8]),
        .y0_out(ns_out[0]), .y1_out(ns_out[1]), .y2_out(ns_out[2]),
        .y3_out(ns_out[3]), .y4_out(ns_out[4]), .y5_out(ns_out[5]),
        .y6_out(ns_out[6]), .y7_out(ns_out[7]), .y8_out(ns_out[8]),
        .done(ns_done)
    );

    // Output registers
    reg [15:0] out_reg [0:8];
    reg        done_reg;
    assign done = done_reg;
    assign u0 = out_reg[0]; assign u1 = out_reg[1]; assign u2 = out_reg[2];
    assign u3 = out_reg[3]; assign u4 = out_reg[4]; assign u5 = out_reg[5];
    assign u6 = out_reg[6]; assign u7 = out_reg[7]; assign u8 = out_reg[8];

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_IDLE;
            ns_start <= 1'b0;
            done_reg <= 1'b0;
            for (i = 0; i < 9; i = i+1) begin
                mbuf[i]   <= 16'h0000;
                ns_in[i]  <= 16'h0000;
                out_reg[i] <= 16'h0000;
            end
        end else begin
            ns_start <= 1'b0;
            done_reg <= 1'b0;
            case (state)
                S_IDLE: begin
                    if (step) begin
                        // Update momentum buffer
                        for (i = 0; i < 9; i = i+1) begin
                            mbuf[i]  <= m_new[i];
                            ns_in[i] <= m_new[i];
                        end
                        ns_start <= 1'b1;
                        state    <= S_NS;
                    end
                end
                S_NS: begin
                    if (ns_done) begin
                        for (i = 0; i < 9; i = i+1)
                            out_reg[i] <= ns_out[i];
                        done_reg <= 1'b1;
                        state    <= S_IDLE;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
