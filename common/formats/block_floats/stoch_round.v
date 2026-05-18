// SPDX-License-Identifier: MIT
// Stochastic Rounding with LFSR-16 RNG
// Sacred opcode: 0xE9 (OP_STOCH_ROUND), Wave-42, t27 reference
// Input: WIDE bits (e.g. 32-bit fixed-point)
// Output: NARROW bits (e.g. 8-bit) with Bernoulli rounding
// LFSR-16: Galois LFSR, poly x^16+x^15+x^13+x^4+1 (taps 16,15,13,4)
// Probability = fractional part / 2^drop_bits => if LFSR < threshold, round up
// R-SI-1 compliant
// Author: Dmitrii Vasilev (gHashTag)
`default_nettype none

// LFSR-16: Galois feedback polynomial 0xB400 (x^16+x^15+x^13+x^4+1)
module lfsr16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] seed,        // initial seed (must be non-zero)
    input  wire        advance,     // pulse to advance one step
    output reg  [15:0] lfsr_out
);
    wire feedback = lfsr_out[0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_out <= (seed == 16'h0000) ? 16'hACE1 : seed;
        end else if (advance) begin
            // Galois LFSR: shift right, XOR taps if LSB=1
            lfsr_out <= {1'b0, lfsr_out[15:1]} ^ (feedback ? 16'hB400 : 16'h0000);
        end
    end
endmodule

// Stochastic rounding: WIDE-bit -> NARROW-bit
// Parameters:
//   WIDE   = input bit width (default 32)
//   NARROW = output bit width (default 8)
// drop_bits = WIDE - NARROW bits are dropped
// threshold = dropped_frac portion = val[WIDE-NARROW-1:0]
// Round up if lfsr_val < threshold (probability proportional to fractional part)
module stoch_round #(
    parameter WIDE   = 32,
    parameter NARROW = 8
) (
    input  wire              clk,
    input  wire              rst_n,
    input  wire [WIDE-1:0]   val_in,     // unsigned wide input
    input  wire [15:0]       seed,       // LFSR seed
    output reg  [NARROW-1:0] val_out,    // narrowed output
    output wire [15:0]       lfsr_dbg    // debug: current LFSR state
);
    localparam DROP = WIDE - NARROW;

    // LFSR instance
    wire        lfsr_adv;
    wire [15:0] lfsr_val;

    // Advance LFSR every cycle
    assign lfsr_adv = 1'b1;

    lfsr16 u_lfsr (
        .clk      (clk),
        .rst_n    (rst_n),
        .seed     (seed),
        .advance  (lfsr_adv),
        .lfsr_out (lfsr_val)
    );
    assign lfsr_dbg = lfsr_val;

    // Fractional part (dropped bits): val_in[DROP-1:0]
    // Threshold = frac_part scaled to 16 bits for comparison with LFSR
    // threshold_16 = frac_part << (16 - DROP) if DROP <= 16
    //              = frac_part >> (DROP - 16) if DROP > 16
    wire [15:0] frac_part;
    generate
        if (DROP >= 16)
            assign frac_part = val_in[DROP-1 -: 16];
        else
            assign frac_part = {{(16-DROP){1'b0}}, val_in[DROP-1:0]};
    endgenerate

    // Round: base = val_in[WIDE-1:DROP], round_up if lfsr < frac_part
    wire [NARROW-1:0] base_val = val_in[WIDE-1:DROP];
    wire              round_up = (lfsr_val < frac_part);

    // Add round_up (with saturation at NARROW-bit max)
    wire [NARROW:0] rounded = {1'b0, base_val} + {{NARROW{1'b0}}, round_up};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            val_out <= {NARROW{1'b0}};
        else
            val_out <= rounded[NARROW] ? {NARROW{1'b1}} : rounded[NARROW-1:0];
    end
endmodule

// Stochastic rounding combinational (no register, LFSR state passed in)
module stoch_round_comb #(
    parameter WIDE   = 32,
    parameter NARROW = 8
) (
    input  wire [WIDE-1:0]   val_in,
    input  wire [15:0]       lfsr_val,   // current LFSR value
    output wire [NARROW-1:0] val_out
);
    localparam DROP = WIDE - NARROW;

    wire [15:0] frac_part;
    generate
        if (DROP >= 16)
            assign frac_part = val_in[DROP-1 -: 16];
        else
            assign frac_part = {{(16-DROP){1'b0}}, val_in[DROP-1:0]};
    endgenerate

    wire [NARROW-1:0] base_val = val_in[WIDE-1:DROP];
    wire              round_up = (lfsr_val < frac_part);
    wire [NARROW:0]   rounded  = {1'b0, base_val} + {{NARROW{1'b0}}, round_up};

    assign val_out = rounded[NARROW] ? {NARROW{1'b1}} : rounded[NARROW-1:0];
endmodule
`default_nettype wire
