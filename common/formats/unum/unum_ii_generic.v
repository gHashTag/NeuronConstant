// =============================================================================
// unum_ii_generic.v — Unum Type II Generic (Projective Real Line)
// =============================================================================
// Gustafson, J. "A Radical Approach to Computation with Real Numbers"
// SuperComputing 2016. Type II Unums (later evolved into Posits).
//
// Unum Type II maps 2^NBITS unsigned integers to the projective real line:
//   index 0         → 0 (or -∞/+∞ depending on convention)
//   index 2^(N-1)   → ±∞ (projective infinity, "the one infinity")
//
// Decode formula:
//   For N-bit index i in [0 .. 2^N - 1]:
//   normalized = i / 2^(N-1) - 1           ∈ [-1, +1)
//   value = tan(normalized × π/2)
//   → index = 0          → tan(-π/2)  = -∞
//   → index = 2^(N-1)/2  → tan(-π/4)  = -1
//   → index = 2^(N-1)    → tan(0)     =  0
//   → index = 3×2^(N-1)/2 → tan(π/4) = +1
//   → index = 2^N - 1   → tan(π/2 - ε) ≈ +∞
//
// For RTL:
//   - Output is a signed Q16.16 fixed-point approximation
//   - Exact computation requires pre-computed LUT or piece-wise linear approx
//   - This module provides the INTERFACE and decode logic shell
//   - Concrete instances (unum_ii8, unum_ii16) provide the LUT/approx
//
// R-SI-1: No standalone '*' — shift-add only.
// =============================================================================

`default_nettype none

module unum_ii_generic #(
    parameter NBITS     = 8,          // index width (8→256 entries, 16→65536)
    parameter OUT_FRAC  = 16          // fractional bits in Q(16).OUT_FRAC output
) (
    input  wire [NBITS-1:0]        index_in,   // unsigned projective index

    // Decoded outputs
    output wire                     sign_out,   // 0=positive/zero, 1=negative
    output wire                     is_zero,    // index maps to 0
    output wire                     is_inf,     // index = 2^(N-1) (projective ∞)

    // Normalized angle: index / 2^(NBITS-1) - 1, as signed Q2.(NBITS-1) fixed
    // angle ∈ [-1, +1) in units of π/2
    output wire signed [NBITS:0]   angle_norm,  // signed, scale = 2^(NBITS-1)

    // Q16.OUT_FRAC decoded value placeholder
    // NOTE: Concrete implementation in unum_ii8/unum_ii16 via LUT/PWL
    output wire signed [31:0]      decoded_q1616,

    // Index metadata
    output wire [NBITS-1:0]         index_out   // passthrough
);

    localparam HALF = (1 << (NBITS-1));  // 2^(NBITS-1)

    // -------------------------------------------------------------------------
    // Special cases
    // -------------------------------------------------------------------------
    assign is_zero = (index_in == {NBITS{1'b0}});
    // Projective infinity at index = HALF (2^(N-1))
    assign is_inf  = (index_in == HALF[NBITS-1:0]);

    // -------------------------------------------------------------------------
    // Sign: positive half is index >= HALF, negative half is index < HALF
    // Convention: index in [HALF, 2^N-1] → positive (0 to +∞)
    //             index in [0, HALF-1]   → negative (-∞ to 0)
    // Note: index=0 and index=HALF are boundaries (0 and ∞)
    // -------------------------------------------------------------------------
    assign sign_out = ~index_in[NBITS-1];  // MSB=0 → negative half

    // -------------------------------------------------------------------------
    // Normalized angle: maps [0 .. 2^N-1] → [-1 .. +1) in Q(1).(NBITS-1)
    // angle = index - 2^(NBITS-1)  as signed
    // Shift: divide by 2^(NBITS-1) is implied by the Q format
    // -------------------------------------------------------------------------
    assign angle_norm = $signed({1'b0, index_in}) - $signed({1'b0, HALF[NBITS-1:0]});

    // -------------------------------------------------------------------------
    // Decoded value placeholder
    // Real implementations provide LUT (unum_ii8) or PWL (unum_ii16)
    // Here: stub returning 0 — override in concrete modules
    // -------------------------------------------------------------------------
    assign decoded_q1616 = 32'sd0;

    assign index_out = index_in;

endmodule

`default_nettype wire
