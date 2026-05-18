// SPDX-License-Identifier: MIT
// muon_ns_5step.v — 5-iteration Newton-Schulz orthogonalization for 3x3 GF16 matrix
//
// State machine: IDLE -> STEP1 -> STEP2 -> STEP3 -> STEP4 -> STEP5 -> DONE
// Each STEP takes 1 clock cycle (combinational NS iteration).
// Latency: 5 clock cycles from start to done.
//
// Reference: Keller Jordan arXiv:2604.01472 — Muon optimizer
//
// R-SI-1 clean: all multiplications via gf16_mul (in muon_ns_iter).
// Verilog-2005, `default_nettype none.

`default_nettype none

module muon_ns_5step (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    // Input 3x3 matrix (row-major)
    input  wire [15:0] x0_in, x1_in, x2_in,
    input  wire [15:0] x3_in, x4_in, x5_in,
    input  wire [15:0] x6_in, x7_in, x8_in,
    // Output 3x3 matrix
    output reg  [15:0] y0_out, y1_out, y2_out,
    output reg  [15:0] y3_out, y4_out, y5_out,
    output reg  [15:0] y6_out, y7_out, y8_out,
    output reg         done
);

    // State encoding
    localparam [2:0] IDLE  = 3'd0;
    localparam [2:0] STEP1 = 3'd1;
    localparam [2:0] STEP2 = 3'd2;
    localparam [2:0] STEP3 = 3'd3;
    localparam [2:0] STEP4 = 3'd4;
    localparam [2:0] STEP5 = 3'd5;
    localparam [2:0] DONE  = 3'd6;

    reg [2:0] state;

    // Current matrix registers
    reg [15:0] cur0, cur1, cur2;
    reg [15:0] cur3, cur4, cur5;
    reg [15:0] cur6, cur7, cur8;

    // NS iteration output wires
    wire [15:0] ns_y0, ns_y1, ns_y2;
    wire [15:0] ns_y3, ns_y4, ns_y5;
    wire [15:0] ns_y6, ns_y7, ns_y8;

    // Instantiate one NS iteration unit (combinational)
    muon_ns_iter u_ns (
        .x0(cur0), .x1(cur1), .x2(cur2),
        .x3(cur3), .x4(cur4), .x5(cur5),
        .x6(cur6), .x7(cur7), .x8(cur8),
        .y0(ns_y0), .y1(ns_y1), .y2(ns_y2),
        .y3(ns_y3), .y4(ns_y4), .y5(ns_y5),
        .y6(ns_y6), .y7(ns_y7), .y8(ns_y8)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done  <= 1'b0;
            cur0 <= 16'd0; cur1 <= 16'd0; cur2 <= 16'd0;
            cur3 <= 16'd0; cur4 <= 16'd0; cur5 <= 16'd0;
            cur6 <= 16'd0; cur7 <= 16'd0; cur8 <= 16'd0;
            y0_out <= 16'd0; y1_out <= 16'd0; y2_out <= 16'd0;
            y3_out <= 16'd0; y4_out <= 16'd0; y5_out <= 16'd0;
            y6_out <= 16'd0; y7_out <= 16'd0; y8_out <= 16'd0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        // Load input matrix
                        cur0 <= x0_in; cur1 <= x1_in; cur2 <= x2_in;
                        cur3 <= x3_in; cur4 <= x4_in; cur5 <= x5_in;
                        cur6 <= x6_in; cur7 <= x7_in; cur8 <= x8_in;
                        state <= STEP1;
                    end
                end

                STEP1: begin
                    // Apply NS iteration: capture result
                    cur0 <= ns_y0; cur1 <= ns_y1; cur2 <= ns_y2;
                    cur3 <= ns_y3; cur4 <= ns_y4; cur5 <= ns_y5;
                    cur6 <= ns_y6; cur7 <= ns_y7; cur8 <= ns_y8;
                    state <= STEP2;
                end

                STEP2: begin
                    cur0 <= ns_y0; cur1 <= ns_y1; cur2 <= ns_y2;
                    cur3 <= ns_y3; cur4 <= ns_y4; cur5 <= ns_y5;
                    cur6 <= ns_y6; cur7 <= ns_y7; cur8 <= ns_y8;
                    state <= STEP3;
                end

                STEP3: begin
                    cur0 <= ns_y0; cur1 <= ns_y1; cur2 <= ns_y2;
                    cur3 <= ns_y3; cur4 <= ns_y4; cur5 <= ns_y5;
                    cur6 <= ns_y6; cur7 <= ns_y7; cur8 <= ns_y8;
                    state <= STEP4;
                end

                STEP4: begin
                    cur0 <= ns_y0; cur1 <= ns_y1; cur2 <= ns_y2;
                    cur3 <= ns_y3; cur4 <= ns_y4; cur5 <= ns_y5;
                    cur6 <= ns_y6; cur7 <= ns_y7; cur8 <= ns_y8;
                    state <= STEP5;
                end

                STEP5: begin
                    // Final iteration — capture output
                    y0_out <= ns_y0; y1_out <= ns_y1; y2_out <= ns_y2;
                    y3_out <= ns_y3; y4_out <= ns_y4; y5_out <= ns_y5;
                    y6_out <= ns_y6; y7_out <= ns_y7; y8_out <= ns_y8;
                    done  <= 1'b1;
                    state <= DONE;
                end

                DONE: begin
                    done  <= 1'b0;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
