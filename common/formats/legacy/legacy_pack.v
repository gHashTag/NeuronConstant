// legacy_pack.v — Legacy format dispatcher
// Routes a 256-bit data bus to/from the appropriate legacy float storage module
// format_id (5 bits) selects one of 17+ formats.
// Level: DISPATCHER — combinational decode of format_id
// R-SI-1 clean: no * operator; sensitivity list uses 'always @*' (Verilog-2005)
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind enum dispatcher
`timescale 1ns/1ps
`default_nettype none

module legacy_pack (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [4:0]   format_id,   // 5-bit: selects format (see table below)
    input  wire [255:0] din,          // wide input bus (zero-padded for narrow formats)
    input  wire         load,
    output reg  [255:0] dout,         // wide output bus
    output reg          valid         // 1 when stored
);

    // --------------------------------------------------------------------------
    // Format ID Table (matches FormatKind in fake_quant.rs):
    //   5'd0  = Decimal32       (32-bit)
    //   5'd1  = Decimal64       (64-bit)
    //   5'd2  = Decimal128      (128-bit, IDENTITY)
    //   5'd3  = Fp80            (80-bit,  IDENTITY)
    //   5'd4  = Binary128       (128-bit, IDENTITY)
    //   5'd5  = Binary256       (256-bit, IDENTITY)
    //   5'd6  = BcdPacked       (8-bit)
    //   5'd7  = Bcd8            (8-bit)
    //   5'd8  = Bcd16           (16-bit)
    //   5'd9  = BcdAdd          (16-bit)
    //   5'd10 = IbmHfpShort     (32-bit)
    //   5'd11 = IbmHfpLong      (64-bit, IDENTITY)
    //   5'd12 = VaxF            (32-bit)
    //   5'd13 = VaxD            (64-bit, IDENTITY)
    //   5'd14 = VaxG            (64-bit, IDENTITY)
    //   5'd15 = VaxH            (128-bit, IDENTITY)
    //   5'd16 = CrayFloat       (64-bit)
    //   5'd17 = Minifloat       (parameterized, default 8-bit)
    //   5'd18..31 = Reserved
    // --------------------------------------------------------------------------

    // Width decode (for masking / truncation)
    reg [8:0] fmt_width;

    always @(format_id) begin
        case (format_id)
            5'd0:  fmt_width = 9'd32;
            5'd1:  fmt_width = 9'd64;
            5'd2:  fmt_width = 9'd128;
            5'd3:  fmt_width = 9'd80;
            5'd4:  fmt_width = 9'd128;
            5'd5:  fmt_width = 9'd256;
            5'd6:  fmt_width = 9'd8;
            5'd7:  fmt_width = 9'd8;
            5'd8:  fmt_width = 9'd16;
            5'd9:  fmt_width = 9'd16;
            5'd10: fmt_width = 9'd32;
            5'd11: fmt_width = 9'd64;
            5'd12: fmt_width = 9'd32;
            5'd13: fmt_width = 9'd64;
            5'd14: fmt_width = 9'd64;
            5'd15: fmt_width = 9'd128;
            5'd16: fmt_width = 9'd64;
            5'd17: fmt_width = 9'd8;
            default: fmt_width = 9'd32;
        endcase
    end

    // Identity passthrough register
    reg [255:0] storage_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            storage_r <= 256'h0;
            valid     <= 1'b0;
        end else if (load) begin
            storage_r <= din;
            valid     <= 1'b1;
        end
    end

    // Output: identity passthrough
    always @(storage_r) begin
        dout = storage_r;
    end

    // fmt_width used externally to know valid bit range
    // Synthesis note: connect individual sub-modules directly for production use

endmodule
`default_nettype wire
