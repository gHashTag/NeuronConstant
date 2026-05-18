// trinity_d2d_bus.v — Cross-tile D2D bus with master FSM
// NeuronConstant canonical hardware catalog
//
// This module implements the Wire A/B/C interconnect interface between
// the three TRI-1 tiles (phi-anchor, e-engine, gamma-surface).
//
// Extracted from individual tile interconnect logic per milestone M+1.
// See: github.com/gHashTag/NeuronConstant/issues/2
//
// Protocol: see docs/interconnect.md
//
// Cross-die anchor: dot4(1,2,3,4) = 0x47C0 (TG-TRIAD-X Theorem 36.1)
// R-SI-1: zero standalone `*` operators in synthesisable RTL.
// DOI: 10.5281/zenodo.19227877
// Apache-2.0 license

// ============================================================
//  Cross-Tile Bus Signal Definitions
// ============================================================
//
//  Wire A: LOAD_MODE
//    Direction : Phi (master) → Euler (slave), Phi → Gamma (slave)
//    Signal    : ui[0] on both Euler and Gamma
//    Function  : 0 = canonical mode (0x47C0 anchor)
//                1 = packet path (token data on ui[7:1])
//
//  Wire B: SYNC_STROBE
//    Direction : Phi (master) → Euler (slave)
//    Signal    : Phi compute_strobe (ui[6]) muxed to Euler & Gamma
//    Function  : Rising edge triggers compute / LOAD_MODE pulse
//
//  Wire C: ACK (open-drain OR)
//    Direction : Euler uo[0] + Gamma uio[3] → Phi dedicated GPIO
//    Function  : Low-active open-drain ACK from compute/neuro slaves
//
//  D2D Forwarding (board trace):
//    Euler uo[7:0] → Gamma uio[4] (D2D n_rx)  via trace J1
//    Gamma uio[1]  → Phi mux input             via trace J3
//
// ============================================================
//  Timing (50 MHz, 20 ns period)
// ============================================================
//
//  Phase 1  RESET & ANCHOR:   4 cycles  =  80 ns
//  Phase 2  FRIEND/FOE:       2 cycles  =  40 ns
//  Phase 3  LUCAS POST:       6 cycles  = 120 ns
//  Phase 4  TOKEN → EULER:  3-5 cycles  =  60-100 ns
//  Phase 5  EULER → GAMMA:    2 cycles  =  40 ns
//  Phase 6  SPIKE → PHI:      2 cycles  =  40 ns
//  Per-token total:          ~15 cycles  = ~300 ns
//
// ============================================================
//  Master FSM — bus_load_mode / bus_sync_strobe generation
// ============================================================
//
//  States:
//    S_IDLE  : bus idle, waiting for compute_request
//    S_LOAD  : drive bus_load_mode=1 for LOAD_HOLD_CYCLES cycles
//    S_SYNC  : drive bus_sync_strobe=1 for SYNC_PULSE_CYCLES cycles
//    S_DONE  : single-cycle completion flag; return to IDLE
//
//  Inputs:
//    compute_request — external master requests a compute cycle
//      (held high for the duration of the request; FSM starts on
//       rising edge / high level in IDLE)
//
//  Parameters:
//    SYNC_PULSE_CYCLES — clocks bus_sync_strobe stays high (default 2,
//                        per Phase 2 friend/foe timing: 2 cycles = 40 ns)
//    LOAD_HOLD_CYCLES  — clocks bus_load_mode stays high (default 4,
//                        per Phase 1 reset timing: 4 cycles = 80 ns)
//
// ============================================================

`default_nettype none
`timescale 1ns / 1ps

module trinity_d2d_bus #(
    parameter DATA_WIDTH       = 8,
    parameter SYNC_PULSE_CYCLES = 2,
    parameter LOAD_HOLD_CYCLES  = 4
)(
    // System
    input  wire             clk,
    input  wire             rst_n,

    // Compute request from external master driver
    // Rising edge (or high level in IDLE) triggers the bus FSM
    input  wire             compute_request,

    // Wire A — LOAD_MODE (Phi master drives)
    output reg              bus_load_mode,

    // Wire B — SYNC_STROBE (Phi master drives)
    output reg              bus_sync_strobe,

    // Wire C — ACK (open-drain, slaves drive)
    input  wire             bus_ack_euler,   // Euler uo[0]
    input  wire             bus_ack_gamma,   // Gamma uio[3]
    output wire             bus_ack,         // OR of above

    // Token path (Phi → Euler)
    input  wire [6:0]       phi_token,       // 7-bit token from Phi
    output wire [6:0]       euler_token,     // forwarded to Euler ui[7:1]

    // D2D path (Euler → Gamma)
    input  wire [DATA_WIDTH-1:0] euler_result,   // Euler uo[7:0]
    output wire [DATA_WIDTH-1:0] gamma_d2d_rx,   // Gamma uio[4] (n_rx)

    // Spike return (Gamma → Phi)
    input  wire             gamma_spike_e_tx, // Gamma uio[1]
    output wire             phi_spike_in      // Phi mux input (J3)
);

    // -----------------------------------------------------------------------
    // Counter width: large enough to hold LOAD_HOLD_CYCLES and
    // SYNC_PULSE_CYCLES. We use 4 bits (max 15 cycles). If parameters are
    // larger, increase this width. Default max is 4, well within 4 bits.
    // -----------------------------------------------------------------------
    localparam CNT_W = 4;

    // -----------------------------------------------------------------------
    // FSM state encoding
    // -----------------------------------------------------------------------
    localparam [1:0]
        S_IDLE = 2'd0,
        S_LOAD = 2'd1,
        S_SYNC = 2'd2,
        S_DONE = 2'd3;

    reg [1:0]       state;
    reg [CNT_W-1:0] cnt;

    // -----------------------------------------------------------------------
    // Master FSM — produces bus_load_mode and bus_sync_strobe
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= S_IDLE;
            cnt             <= {CNT_W{1'b0}};
            bus_load_mode   <= 1'b0;
            bus_sync_strobe <= 1'b0;
        end else begin
            case (state)

                // ---------------------------------------------------------
                // IDLE: wait for compute_request assertion
                // ---------------------------------------------------------
                S_IDLE: begin
                    bus_load_mode   <= 1'b0;
                    bus_sync_strobe <= 1'b0;
                    if (compute_request) begin
                        // Phase 4: assert LOAD_MODE (Wire A) and start counter
                        bus_load_mode <= 1'b1;
                        cnt           <= {{(CNT_W-1){1'b0}}, 1'b1};
                        state         <= S_LOAD;
                    end
                end

                // ---------------------------------------------------------
                // LOAD: hold bus_load_mode for LOAD_HOLD_CYCLES cycles
                // cnt counts 1..LOAD_HOLD_CYCLES (entered at cnt=1)
                // ---------------------------------------------------------
                S_LOAD: begin
                    if (cnt >= LOAD_HOLD_CYCLES[CNT_W-1:0]) begin
                        // Transition to SYNC phase: de-assert LOAD_MODE,
                        // assert SYNC_STROBE (Wire B)
                        bus_load_mode   <= 1'b0;
                        bus_sync_strobe <= 1'b1;
                        cnt             <= {{(CNT_W-1){1'b0}}, 1'b1};
                        state           <= S_SYNC;
                    end else begin
                        cnt <= cnt + {{(CNT_W-1){1'b0}}, 1'b1};
                    end
                end

                // ---------------------------------------------------------
                // SYNC: hold bus_sync_strobe for SYNC_PULSE_CYCLES cycles
                // ---------------------------------------------------------
                S_SYNC: begin
                    if (cnt >= SYNC_PULSE_CYCLES[CNT_W-1:0]) begin
                        bus_sync_strobe <= 1'b0;
                        cnt             <= {CNT_W{1'b0}};
                        state           <= S_DONE;
                    end else begin
                        cnt <= cnt + {{(CNT_W-1){1'b0}}, 1'b1};
                    end
                end

                // ---------------------------------------------------------
                // DONE: single-cycle completion; return to IDLE
                // (compute_request may still be high — wait for it to clear
                //  before re-triggering to avoid immediate re-fire)
                // ---------------------------------------------------------
                S_DONE: begin
                    bus_load_mode   <= 1'b0;
                    bus_sync_strobe <= 1'b0;
                    if (!compute_request) begin
                        state <= S_IDLE;
                    end
                end

                default: begin
                    state           <= S_IDLE;
                    bus_load_mode   <= 1'b0;
                    bus_sync_strobe <= 1'b0;
                end

            endcase
        end
    end

    // -----------------------------------------------------------------------
    // ACK: open-drain OR (active-high: both slaves must be high → bus ACK)
    // Matches interconnect.md Wire C semantics: Euler uo[0] AND Gamma uio[3]
    // both high → triad ACK asserted.
    // -----------------------------------------------------------------------
    assign bus_ack = bus_ack_euler & bus_ack_gamma;

    // -----------------------------------------------------------------------
    // Token forwarding: Phi → Euler (combinational pass-through in bus spec)
    // -----------------------------------------------------------------------
    assign euler_token = phi_token;

    // -----------------------------------------------------------------------
    // D2D forwarding: Euler result → Gamma RX
    // -----------------------------------------------------------------------
    assign gamma_d2d_rx = euler_result;

    // -----------------------------------------------------------------------
    // Spike return: Gamma → Phi
    // -----------------------------------------------------------------------
    assign phi_spike_in = gamma_spike_e_tx;

endmodule

`default_nettype wire
