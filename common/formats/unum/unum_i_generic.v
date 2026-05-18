// =============================================================================
// unum_i_generic.v — Unum Type I Generic Decoder/Encoder
// =============================================================================
// Gustafson, J. "The End of Error: Unum Computing"
// CRC Press, 2015. ISBN 978-1-4822-3986-7
//
// Unum Type I is a variable-width float extended with a u-bit (uncertainty bit).
// For RTL fixed-width implementation:
//   - EXP_BITS   : exponent field width
//   - FRAC_BITS  : fraction field width
//   - ES_META    : exponent size meta field bits (encodes actual exp width)
//   - FS_META    : fraction size meta field bits (encodes actual frac width)
//
// Total bit width = 1(sign) + EXP_BITS + FRAC_BITS + 1(ubit) + ES_META + FS_META
//
// Bit layout (MSB -> LSB):
//   [TOTAL-1]          = sign
//   [TOTAL-2 : FRAC_BITS+1+ES_META+FS_META] = exponent (EXP_BITS wide)
//   [FRAC_BITS+ES_META+FS_META : 1+ES_META+FS_META] = fraction (FRAC_BITS wide)
//   [ES_META+FS_META]  = ubit
//   [ES_META+FS_META-1 : FS_META] = es (ES_META bits)
//   [FS_META-1 : 0]    = fs (FS_META bits)
//
// R-SI-1: No standalone '*' operator — shift-add only for arithmetic.
// =============================================================================

`default_nettype none

module unum_i_generic #(
    parameter EXP_BITS  = 4,   // max exponent field width
    parameter FRAC_BITS = 9,   // max fraction field width
    parameter ES_META   = 1,   // bits to encode exponent size
    parameter FS_META   = 1    // bits to encode fraction size
) (
    // Raw unum input
    input  wire [TOTAL_BITS-1:0] unum_in,

    // Decoded outputs
    output wire                   sign_out,
    output wire [EXP_BITS-1:0]    exp_out,
    output wire [FRAC_BITS-1:0]   frac_out,
    output wire                   ubit_out,    // 0=exact, 1=inexact (open interval)
    output wire [ES_META-1:0]     es_out,      // actual exponent size used
    output wire [FS_META-1:0]     fs_out,      // actual fraction size used

    // Bounds output (ubit=1 means value is in open interval)
    // lower_bound and upper_bound are same as decoded when ubit=0
    // When ubit=1: lower_bound = decoded value, upper_bound = next representable
    output wire [FRAC_BITS-1:0]   lower_frac,
    output wire [FRAC_BITS-1:0]   upper_frac,
    output wire [EXP_BITS-1:0]    lower_exp,
    output wire [EXP_BITS-1:0]    upper_exp,

    // Validity
    output wire                   valid_out    // 0 if NaN/special
);

    // Total bits calculation
    localparam TOTAL_BITS = 1 + EXP_BITS + FRAC_BITS + 1 + ES_META + FS_META;

    // -------------------------------------------------------------------------
    // Field extraction
    // -------------------------------------------------------------------------
    // Sign: MSB
    assign sign_out = unum_in[TOTAL_BITS-1];

    // Exponent: next EXP_BITS bits
    assign exp_out  = unum_in[TOTAL_BITS-2 : FRAC_BITS+1+ES_META+FS_META];

    // Fraction
    assign frac_out = unum_in[FRAC_BITS+ES_META+FS_META : 1+ES_META+FS_META];

    // Ubit
    assign ubit_out = unum_in[ES_META+FS_META];

    // Exponent size meta
    generate
        if (ES_META > 0) begin : gen_es
            assign es_out = unum_in[ES_META+FS_META-1 : FS_META];
        end else begin : gen_es_zero
            assign es_out = 1'b0;
        end
    endgenerate

    // Fraction size meta
    generate
        if (FS_META > 0) begin : gen_fs
            assign fs_out = unum_in[FS_META-1 : 0];
        end else begin : gen_fs_zero
            assign fs_out = 1'b0;
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Validity: NaN = sign=1, exp=all-ones, frac=all-ones, ubit=1
    // -------------------------------------------------------------------------
    wire exp_all_ones  = (exp_out  == {EXP_BITS{1'b1}});
    wire frac_all_ones = (frac_out == {FRAC_BITS{1'b1}});
    assign valid_out   = ~(sign_out & exp_all_ones & frac_all_ones & ubit_out);

    // -------------------------------------------------------------------------
    // Bounds: when ubit=1 the value represents an open interval
    // upper = lower + 1 ULP (unit in the last place of frac)
    // Implemented with shift-add: upper_frac = lower_frac + 1 (carry propagates)
    // -------------------------------------------------------------------------
    assign lower_frac = frac_out;
    assign lower_exp  = exp_out;

    // upper_frac = frac_out + ubit (shift-add: add 1 when ubit=1)
    wire [FRAC_BITS:0] frac_plus_one;
    // R-SI-1 compliant: use addition, not multiplication
    assign frac_plus_one = {1'b0, frac_out} + {{FRAC_BITS{1'b0}}, ubit_out};

    assign upper_frac = frac_plus_one[FRAC_BITS-1:0];
    // Carry into exponent
    assign upper_exp  = exp_out + {{(EXP_BITS-1){1'b0}}, frac_plus_one[FRAC_BITS]};

endmodule

`default_nettype wire
