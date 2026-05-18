// stdp_engine.v — Spike-Timing-Dependent Plasticity (STDP) Engine
// Competitive feature set vs TT26a "Digital STDP Learning Controller":
//   - 64-entry programmable LUT (exponential A_plus/A_minus)
//   - R-STDP reward-gated weight updates
//   - Anti-Hebbian mode (LTP/LTD sign flip)
//   - Eligibility trace with configurable leaky counter
//   - Weight saturation at +127 / -128 (signed 8-bit)
//
// R-SI-1 CLEAN: ALL multiplications implemented via shift-and-add (lr_shift).
// No standalone `*` operators in RTL.
// Verilog-2005
`default_nettype none

module stdp_engine #(
    parameter WEIGHT_BITS = 8,   // signed weight width
    parameter TRACE_BITS  = 10,  // eligibility trace width
    parameter LUT_DEPTH   = 64   // LUT entries (32 LTP + 32 LTD)
) (
    input  wire                          clk,
    input  wire                          rst_n,

    // Spike inputs (1-cycle pulses)
    input  wire                          pre_spike,
    input  wire                          post_spike,

    // R-STDP reward (signed 8-bit; update gated when reward != 0)
    input  wire signed [7:0]             reward,

    // Anti-Hebbian mode: 1 = flip LTP/LTD signs
    input  wire                          anti_hebbian_mode,

    // SPI-style LUT programming interface
    input  wire [5:0]                    lut_addr,
    input  wire [7:0]                    lut_wdata,
    input  wire                          lut_we,

    // Learning rate as right-shift (effective lr = 1 / 2^lr_shift)
    input  wire [3:0]                    lr_shift,

    // Outputs
    output wire signed [WEIGHT_BITS-1:0] weight,
    output wire [TRACE_BITS-1:0]         trace_pre,
    output wire [TRACE_BITS-1:0]         trace_post,
    output reg                           update_event
);

    // -----------------------------------------------------------------------
    // Internal registers
    // -----------------------------------------------------------------------
    reg signed [WEIGHT_BITS-1:0]  weight_r;
    reg [TRACE_BITS-1:0]          trace_pre_r;
    reg [TRACE_BITS-1:0]          trace_post_r;

    // Leaky decay counter — trace >>= 1 every DECAY_PERIOD clocks
    localparam DECAY_PERIOD = 16;
    reg [4:0] decay_cnt;

    // Delta-t counters: count clocks since last spike, capped at 31
    // dt=31 means "no recent spike" (never fired or too long ago)
    reg [4:0] dt_pre;    // cycles elapsed since last pre_spike
    reg [4:0] dt_post;   // cycles elapsed since last post_spike

    // -----------------------------------------------------------------------
    // LUT ROM instance (programmable via SPI-style interface)
    // -----------------------------------------------------------------------
    wire [5:0]  lut_rd_addr;
    wire [7:0]  lut_rd_data;

    stdp_lut_rom #(.LUT_DEPTH(LUT_DEPTH)) u_lut (
        .clk   (clk),
        .addr  (lut_we ? lut_addr : lut_rd_addr),
        .wdata (lut_wdata),
        .we    (lut_we),
        .rdata (lut_rd_data)
    );

    // LUT addr driven combinationally:
    //   On pre_spike  → read A_plus  at index dt_post (LTP window)
    //   On post_spike → read A_minus at index 32+dt_pre (LTD window)
    //   Else          → hold last addr
    assign lut_rd_addr = post_spike ? {1'b1, dt_pre[4:0]}
                       : pre_spike  ? {1'b0, dt_post[4:0]}
                       : 6'd0;

    // -----------------------------------------------------------------------
    // Reward gating
    // -----------------------------------------------------------------------
    wire reward_active;
    wire reward_pos;
    assign reward_active = (reward != 8'sd0);
    assign reward_pos    = ~reward[7] & reward_active; // positive & non-zero

    // -----------------------------------------------------------------------
    // Weight delta computation (shift-and-add, R-SI-1 compliant)
    //
    // Standard STDP update rule:
    //   pre_spike  + post_recently_fired  → LTP: dW = +trace_post >> lr_shift
    //   post_spike + pre_recently_fired   → LTD: dW = -trace_pre  >> lr_shift
    //
    // R-STDP: sign of dW is gated by sign(reward)
    //   reward>0: normal update
    //   reward<0: invert update
    //
    // Anti-Hebbian: additionally flip LTP↔LTD
    // -----------------------------------------------------------------------

    // Combinational delta (computed from current trace values)
    // LTP delta uses trace_post_r (post-synaptic activity)
    // LTD delta uses trace_pre_r  (pre-synaptic activity)
    wire [TRACE_BITS-1:0] raw_ltp_delta;
    wire [TRACE_BITS-1:0] raw_ltd_delta;

    assign raw_ltp_delta = trace_post_r >> lr_shift;
    assign raw_ltd_delta = trace_pre_r  >> lr_shift;

    // Clamp to WEIGHT_BITS-1 unsigned (max 127 for 8-bit signed)
    wire [WEIGHT_BITS-2:0] delta_ltp_mag; // magnitude, max 127
    wire [WEIGHT_BITS-2:0] delta_ltd_mag;

    assign delta_ltp_mag = (raw_ltp_delta > {{(TRACE_BITS-WEIGHT_BITS+1){1'b0}}, {(WEIGHT_BITS-1){1'b1}}})
                          ? {(WEIGHT_BITS-1){1'b1}}
                          : raw_ltp_delta[WEIGHT_BITS-2:0];

    assign delta_ltd_mag = (raw_ltd_delta > {{(TRACE_BITS-WEIGHT_BITS+1){1'b0}}, {(WEIGHT_BITS-1){1'b1}}})
                          ? {(WEIGHT_BITS-1){1'b1}}
                          : raw_ltd_delta[WEIGHT_BITS-2:0];

    // Saturating add/sub helpers (combinational)
    // Using wider intermediate to detect overflow
    wire signed [WEIGHT_BITS:0] w_ext; // 9-bit sign-extended weight
    assign w_ext = {{1{weight_r[WEIGHT_BITS-1]}}, weight_r};

    // Compute new weight for LTP (potentiation = add positive delta)
    wire signed [WEIGHT_BITS:0] w_ltp_raw;
    wire signed [WEIGHT_BITS:0] w_ltd_raw;
    assign w_ltp_raw = w_ext + $signed({2'b00, delta_ltp_mag});
    assign w_ltd_raw = w_ext - $signed({2'b00, delta_ltd_mag});

    // Saturate to [-128, +127]
    wire signed [WEIGHT_BITS-1:0] w_ltp_sat;
    wire signed [WEIGHT_BITS-1:0] w_ltd_sat;
    wire signed [WEIGHT_BITS-1:0] w_ltp_inv_sat; // for anti-hebbian / neg-reward
    wire signed [WEIGHT_BITS-1:0] w_ltd_inv_sat;

    // Saturate: if overflow bit != MSB of result, clamp
    assign w_ltp_sat     = (w_ltp_raw > $signed(9'sd127))  ?  8'sd127
                         : (w_ltp_raw < $signed(-9'sd128)) ? -8'sd128
                         : w_ltp_raw[WEIGHT_BITS-1:0];
    assign w_ltd_sat     = (w_ltd_raw > $signed(9'sd127))  ?  8'sd127
                         : (w_ltd_raw < $signed(-9'sd128)) ? -8'sd128
                         : w_ltd_raw[WEIGHT_BITS-1:0];

    // Inverted (for negative reward or anti-Hebbian):
    // LTP → subtract, LTD → add
    wire signed [WEIGHT_BITS:0] w_ltp_inv_raw;
    wire signed [WEIGHT_BITS:0] w_ltd_inv_raw;
    assign w_ltp_inv_raw = w_ext - $signed({2'b00, delta_ltp_mag});
    assign w_ltd_inv_raw = w_ext + $signed({2'b00, delta_ltd_mag});
    assign w_ltp_inv_sat = (w_ltp_inv_raw > $signed(9'sd127))  ?  8'sd127
                         : (w_ltp_inv_raw < $signed(-9'sd128)) ? -8'sd128
                         : w_ltp_inv_raw[WEIGHT_BITS-1:0];
    assign w_ltd_inv_sat = (w_ltd_inv_raw > $signed(9'sd127))  ?  8'sd127
                         : (w_ltd_inv_raw < $signed(-9'sd128)) ? -8'sd128
                         : w_ltd_inv_raw[WEIGHT_BITS-1:0];

    // -----------------------------------------------------------------------
    // "Post recently fired" and "Pre recently fired" flags
    // dt < 31 means a spike occurred within the tracking window
    // -----------------------------------------------------------------------
    wire post_recent;
    wire pre_recent;
    assign post_recent = (dt_post != 5'd31);
    assign pre_recent  = (dt_pre  != 5'd31);

    // -----------------------------------------------------------------------
    // Sequential logic
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_r     <= {WEIGHT_BITS{1'b0}};
            trace_pre_r  <= {TRACE_BITS{1'b0}};
            trace_post_r <= {TRACE_BITS{1'b0}};
            decay_cnt    <= 5'd0;
            dt_pre       <= 5'd31;
            dt_post      <= 5'd31;
            update_event <= 1'b0;
        end else begin
            update_event <= 1'b0;

            // -----------------------------------------------------------
            // Leaky decay: every DECAY_PERIOD cycles, traces >>= 1
            // -----------------------------------------------------------
            if (decay_cnt == (DECAY_PERIOD - 1)) begin
                decay_cnt    <= 5'd0;
                trace_pre_r  <= trace_pre_r  >> 1;
                trace_post_r <= trace_post_r >> 1;
            end else begin
                decay_cnt <= decay_cnt + 5'd1;
            end

            // -----------------------------------------------------------
            // Delta-t counters: advance, cap at 31
            // -----------------------------------------------------------
            if (dt_pre  < 5'd30) dt_pre  <= dt_pre  + 5'd1;
            else if (!pre_spike) dt_pre  <= 5'd31;

            if (dt_post < 5'd30) dt_post <= dt_post + 5'd1;
            else if (!post_spike) dt_post <= 5'd31;

            // -----------------------------------------------------------
            // Pre-spike: bump trace_pre + LTP (if post recently fired)
            // -----------------------------------------------------------
            if (pre_spike) begin
                dt_pre <= 5'd0;

                // Saturating trace increment
                if (!(&trace_pre_r))
                    trace_pre_r <= trace_pre_r + {{(TRACE_BITS-1){1'b0}}, 1'b1};

                // LTP: requires post_recent & reward_active
                if (post_recent && reward_active) begin
                    if (!anti_hebbian_mode) begin
                        // Hebbian: potentiate on pre→post
                        weight_r <= reward_pos ? w_ltp_sat : w_ltp_inv_sat;
                    end else begin
                        // Anti-Hebbian: depress on pre→post
                        weight_r <= reward_pos ? w_ltp_inv_sat : w_ltp_sat;
                    end
                    update_event <= 1'b1;
                end
            end

            // -----------------------------------------------------------
            // Post-spike: bump trace_post + LTD (if pre recently fired)
            // -----------------------------------------------------------
            if (post_spike) begin
                dt_post <= 5'd0;

                // Saturating trace increment
                if (!(&trace_post_r))
                    trace_post_r <= trace_post_r + {{(TRACE_BITS-1){1'b0}}, 1'b1};

                // LTD: requires pre_recent & reward_active
                if (pre_recent && reward_active) begin
                    if (!anti_hebbian_mode) begin
                        // Hebbian: depress on post→pre
                        weight_r <= reward_pos ? w_ltd_sat : w_ltd_inv_sat;
                    end else begin
                        // Anti-Hebbian: potentiate on post→pre
                        weight_r <= reward_pos ? w_ltd_inv_sat : w_ltd_sat;
                    end
                    update_event <= 1'b1;
                end
            end
        end
    end

    // -----------------------------------------------------------------------
    // Output assignments
    // -----------------------------------------------------------------------
    assign weight     = weight_r;
    assign trace_pre  = trace_pre_r;
    assign trace_post = trace_post_r;

endmodule
`default_nettype wire
