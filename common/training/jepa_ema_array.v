// SPDX-License-Identifier: MIT
// jepa_ema_array.v — Parallel T-JEPA EMA update for N parameters
//
// Parameterized array of EMA units.
// Each cycle updates one or more parameters (parameter N_PARAMS).
// For each parameter i:
//   target[i] = decay * target[i] + (1 - decay) * online[i]
//
// For hardware efficiency, we process all N_PARAMS in parallel
// (combinational, no serialization needed for small N).
//
// Default N_PARAMS=9 for 3x3 weight matrix.
// decay: shared across all parameters.
//
// R-SI-1 clean: all multiplications via gf16_mul (inside jepa_ema).
// Verilog-2005, `default_nettype none.

`default_nettype none

module jepa_ema_array #(
    parameter N_PARAMS = 9
) (
    input  wire clk,
    input  wire rst_n,
    input  wire update,                        // pulse: trigger EMA update
    input  wire [16*N_PARAMS-1:0] online_flat, // packed online params
    input  wire [15:0]             decay,       // shared decay GF16
    output reg  [16*N_PARAMS-1:0] target_flat,  // packed target params (registered)
    output reg                     done
);

    // Unpack online params
    wire [15:0] online_arr [0:N_PARAMS-1];
    wire [15:0] target_arr [0:N_PARAMS-1];
    wire [15:0] tnew_arr   [0:N_PARAMS-1];

    genvar gi;
    generate
        for (gi = 0; gi < N_PARAMS; gi = gi + 1) begin : unpack_online
            assign online_arr[gi] = online_flat[gi*16 +: 16];
        end
        for (gi = 0; gi < N_PARAMS; gi = gi + 1) begin : unpack_target
            assign target_arr[gi] = target_flat[gi*16 +: 16];
        end
    endgenerate

    // Instantiate N_PARAMS EMA units (combinational)
    generate
        for (gi = 0; gi < N_PARAMS; gi = gi + 1) begin : ema_units
            jepa_ema u_ema (
                .target(target_arr[gi]),
                .online(online_arr[gi]),
                .decay(decay),
                .target_new(tnew_arr[gi])
            );
        end
    endgenerate

    // Register outputs on update pulse
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            target_flat <= {(16*N_PARAMS){1'b0}};
            done        <= 1'b0;
        end else begin
            done <= 1'b0;
            if (update) begin
                for (i = 0; i < N_PARAMS; i = i + 1) begin
                    target_flat[i*16 +: 16] <= tnew_arr[i];
                end
                done <= 1'b1;
            end
        end
    end

endmodule

`default_nettype wire
