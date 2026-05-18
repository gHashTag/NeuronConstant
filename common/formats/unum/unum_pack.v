// =============================================================================
// unum_pack.v — Format Dispatcher (format_id selector)
// =============================================================================
// Routes a 16-bit raw input to the appropriate format decoder based on
// a 3-bit format_id selector.
//
// Format IDs:
//   3'd0 = UnumI8    (8-bit Unum Type I, lower 8 bits used)
//   3'd1 = UnumI16   (16-bit Unum Type I)
//   3'd2 = UnumII8   (8-bit Unum Type II projective, lower 8 bits)
//   3'd3 = UnumII16  (16-bit Unum Type II projective)
//   3'd4 = AfP       (Adaptive Float-Point, requires config_in)
//   3'd5 = QFormat   (Q-format, Q15 by default)
//   3'd6 = reserved
//   3'd7 = reserved
//
// Output: unified 32-bit signed decoded value (Q16.16 canonical scale)
//   - UnumI8/I16 decoded values are zero-extended/sign-extended to 32 bits
//   - UnumII8/II16 decoded Q16.16 passed through
//   - AfP decoded Q8.13 sign-extended to 32 bits
//   - QFormat raw value sign-extended to 32 bits
//
// R-SI-1: No standalone '*' — this module is pure mux logic.
// =============================================================================

`default_nettype none

module unum_pack (
    input  wire [15:0]  raw_in,       // raw 16-bit input
    input  wire [2:0]   format_id,    // format selector
    input  wire [2:0]   afp_config,   // AfP config (used when format_id=4)

    // Unified decoded output
    output wire signed [31:0] decoded_out,

    // Per-format metadata
    output wire         sign_out,
    output wire         ubit_out,     // valid for UnumI formats
    output wire         is_zero,
    output wire         is_inf,
    output wire         is_nan,
    output wire         valid_out,

    // Active format name (3-bit echo)
    output wire [2:0]   format_id_out
);

    assign format_id_out = format_id;

    // -------------------------------------------------------------------------
    // Instantiate all decoders (inputs MUXed)
    // -------------------------------------------------------------------------

    // --- UnumI8 ---
    wire        ui8_sign, ui8_ubit, ui8_valid;
    wire [1:0]  ui8_exp;
    wire [2:0]  ui8_frac;
    wire signed [7:0] ui8_decoded;
    wire        ui8_es;
    wire [2:0]  ui8_lfrac, ui8_ufrac;
    wire [1:0]  ui8_lexp, ui8_uexp;

    unum_i8 u_ui8 (
        .unum8_in    (raw_in[7:0]),
        .sign_out    (ui8_sign),
        .exp_out     (ui8_exp),
        .frac_out    (ui8_frac),
        .ubit_out    (ui8_ubit),
        .es_out      (ui8_es),
        .decoded_q43 (ui8_decoded),
        .lower_frac  (ui8_lfrac),
        .upper_frac  (ui8_ufrac),
        .lower_exp   (ui8_lexp),
        .upper_exp   (ui8_uexp),
        .valid_out   (ui8_valid)
    );

    // --- UnumI16 ---
    wire        ui16_sign, ui16_ubit, ui16_valid, ui16_zero, ui16_inf, ui16_nan;
    wire [3:0]  ui16_exp;
    wire [8:0]  ui16_frac;
    wire signed [16:0] ui16_decoded;
    wire [8:0]  ui16_lfrac, ui16_ufrac;
    wire [3:0]  ui16_lexp, ui16_uexp;

    unum_i16 u_ui16 (
        .unum16_in   (raw_in),
        .sign_out    (ui16_sign),
        .exp_out     (ui16_exp),
        .frac_out    (ui16_frac),
        .ubit_out    (ui16_ubit),
        .es_out      (),
        .decoded_q89 (ui16_decoded),
        .actual_exp  (),
        .lower_frac  (ui16_lfrac),
        .upper_frac  (ui16_ufrac),
        .lower_exp   (ui16_lexp),
        .upper_exp   (ui16_uexp),
        .is_zero     (ui16_zero),
        .is_inf      (ui16_inf),
        .is_nan      (ui16_nan),
        .valid_out   (ui16_valid)
    );

    // --- UnumII8 ---
    wire        uii8_sign, uii8_zero, uii8_inf;
    wire signed [31:0] uii8_decoded;

    unum_ii8 u_uii8 (
        .index_in    (raw_in[7:0]),
        .sign_out    (uii8_sign),
        .is_zero     (uii8_zero),
        .is_inf      (uii8_inf),
        .decoded_q1616(uii8_decoded),
        .index_out   ()
    );

    // --- UnumII16 ---
    wire        uii16_sign, uii16_zero, uii16_inf;
    wire signed [31:0] uii16_decoded;

    unum_ii16 u_uii16 (
        .index_in    (raw_in),
        .sign_out    (uii16_sign),
        .is_zero     (uii16_zero),
        .is_inf      (uii16_inf),
        .decoded_q1616(uii16_decoded),
        .index_out   ()
    );

    // --- AfP ---
    wire        afp_sign, afp_nan, afp_inf, afp_zero;
    wire signed [21:0] afp_decoded;

    afp u_afp (
        .afp_in      (raw_in),
        .config_in   (afp_config),
        .sign_out    (afp_sign),
        .exp_out     (),
        .frac_out    (),
        .exp_bits    (),
        .frac_bits   (),
        .bias        (),
        .decoded_q813(afp_decoded),
        .is_nan      (afp_nan),
        .is_inf      (afp_inf),
        .is_zero     (afp_zero)
    );

    // --- QFormat (Q15) ---
    // Q15: raw value is already the fixed-point number
    wire signed [15:0] qfmt_raw = $signed(raw_in);
    wire               qfmt_zero = ~(|raw_in);

    // -------------------------------------------------------------------------
    // Output MUX
    // -------------------------------------------------------------------------
    reg signed [31:0] decoded_r;
    reg               sign_r, ubit_r, zero_r, inf_r, nan_r, valid_r;

    always @(*) begin
        case (format_id)
            3'd0: begin  // UnumI8
                decoded_r = {{24{ui8_decoded[7]}}, ui8_decoded};
                sign_r    = ui8_sign;
                ubit_r    = ui8_ubit;
                zero_r    = (ui8_decoded == 8'sd0);
                inf_r     = 1'b0;
                nan_r     = ~ui8_valid;
                valid_r   = ui8_valid;
            end
            3'd1: begin  // UnumI16
                decoded_r = {{15{ui16_decoded[16]}}, ui16_decoded};
                sign_r    = ui16_sign;
                ubit_r    = ui16_ubit;
                zero_r    = ui16_zero;
                inf_r     = ui16_inf;
                nan_r     = ui16_nan;
                valid_r   = ui16_valid;
            end
            3'd2: begin  // UnumII8
                decoded_r = uii8_decoded;
                sign_r    = uii8_sign;
                ubit_r    = 1'b0;
                zero_r    = uii8_zero;
                inf_r     = uii8_inf;
                nan_r     = 1'b0;
                valid_r   = 1'b1;
            end
            3'd3: begin  // UnumII16
                decoded_r = uii16_decoded;
                sign_r    = uii16_sign;
                ubit_r    = 1'b0;
                zero_r    = uii16_zero;
                inf_r     = uii16_inf;
                nan_r     = 1'b0;
                valid_r   = 1'b1;
            end
            3'd4: begin  // AfP
                decoded_r = {{10{afp_decoded[21]}}, afp_decoded};
                sign_r    = afp_sign;
                ubit_r    = 1'b0;
                zero_r    = afp_zero;
                inf_r     = afp_inf;
                nan_r     = afp_nan;
                valid_r   = ~afp_nan;
            end
            3'd5: begin  // QFormat Q15
                decoded_r = {{16{qfmt_raw[15]}}, qfmt_raw};
                sign_r    = qfmt_raw[15];
                ubit_r    = 1'b0;
                zero_r    = qfmt_zero;
                inf_r     = 1'b0;
                nan_r     = 1'b0;
                valid_r   = 1'b1;
            end
            default: begin
                decoded_r = 32'sd0;
                sign_r    = 1'b0;
                ubit_r    = 1'b0;
                zero_r    = 1'b1;
                inf_r     = 1'b0;
                nan_r     = 1'b0;
                valid_r   = 1'b0;
            end
        endcase
    end

    assign decoded_out = decoded_r;
    assign sign_out    = sign_r;
    assign ubit_out    = ubit_r;
    assign is_zero     = zero_r;
    assign is_inf      = inf_r;
    assign is_nan      = nan_r;
    assign valid_out   = valid_r;

endmodule

`default_nettype wire
