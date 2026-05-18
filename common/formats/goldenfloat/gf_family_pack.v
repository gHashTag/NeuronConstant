// SPDX-License-Identifier: MIT
// gf_family_pack — GoldenFloat format-id dispatcher (R-SI-1 keystone)
//
// Top-level multiplexor: routes format-agnostic GF multiply to the
// appropriate per-width multiplier based on format_id.
//
// format_id encoding (3-bit):
//   3'd0 = GF4   (4-bit)
//   3'd1 = GF8   (8-bit)
//   3'd2 = GF12  (12-bit)
//   3'd3 = GF16  (16-bit, PRIMARY)
//   3'd4 = GF20  (20-bit)
//   3'd5 = GF24  (24-bit)
//   3'd6 = GF32  (32-bit)
//   3'd7 = reserved (NaN output)
//
// Operands a, b are passed in 32-bit holders (zero-extended / right-aligned).
// Result is 32-bit holder.
//
// R-SI-1: ZERO standalone * operators — all multiply via gf_generic_mul.
// Verilog-2005, default_nettype none/wire.

`default_nettype none

module gf_family_pack (
    input  wire [2:0]  format_id,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] result,
    output reg         overflow,
    output reg         underflow
);

    // --- GF4 ---
    wire [3:0]  gf4_result;
    wire        gf4_ovf, gf4_unf;
    gf4_mul u_gf4 (
        .a         (a[3:0]),
        .b         (b[3:0]),
        .result    (gf4_result),
        .overflow  (gf4_ovf),
        .underflow (gf4_unf)
    );

    // --- GF8 ---
    wire [7:0]  gf8_result;
    wire        gf8_ovf, gf8_unf;
    gf8_mul u_gf8 (
        .a         (a[7:0]),
        .b         (b[7:0]),
        .result    (gf8_result),
        .overflow  (gf8_ovf),
        .underflow (gf8_unf)
    );

    // --- GF12 ---
    wire [11:0] gf12_result;
    wire        gf12_ovf, gf12_unf;
    gf12_mul u_gf12 (
        .a         (a[11:0]),
        .b         (b[11:0]),
        .result    (gf12_result),
        .overflow  (gf12_ovf),
        .underflow (gf12_unf)
    );

    // --- GF16 PRIMARY ---
    wire [15:0] gf16_result;
    wire        gf16_ovf, gf16_unf;
    gf16_mul u_gf16 (
        .a         (a[15:0]),
        .b         (b[15:0]),
        .result    (gf16_result),
        .overflow  (gf16_ovf),
        .underflow (gf16_unf)
    );

    // --- GF20 ---
    wire [19:0] gf20_result;
    wire        gf20_ovf, gf20_unf;
    gf20_mul u_gf20 (
        .a         (a[19:0]),
        .b         (b[19:0]),
        .result    (gf20_result),
        .overflow  (gf20_ovf),
        .underflow (gf20_unf)
    );

    // --- GF24 ---
    wire [23:0] gf24_result;
    wire        gf24_ovf, gf24_unf;
    gf24_mul u_gf24 (
        .a         (a[23:0]),
        .b         (b[23:0]),
        .result    (gf24_result),
        .overflow  (gf24_ovf),
        .underflow (gf24_unf)
    );

    // --- GF32 ---
    wire [31:0] gf32_result;
    wire        gf32_ovf, gf32_unf;
    gf32_mul u_gf32 (
        .a         (a),
        .b         (b),
        .result    (gf32_result),
        .overflow  (gf32_ovf),
        .underflow (gf32_unf)
    );

    // --- Mux ---
    always @(*) begin
        case (format_id)
            3'd0: begin result = {28'd0, gf4_result};  overflow = gf4_ovf;  underflow = gf4_unf;  end
            3'd1: begin result = {24'd0, gf8_result};  overflow = gf8_ovf;  underflow = gf8_unf;  end
            3'd2: begin result = {20'd0, gf12_result}; overflow = gf12_ovf; underflow = gf12_unf; end
            3'd3: begin result = {16'd0, gf16_result}; overflow = gf16_ovf; underflow = gf16_unf; end
            3'd4: begin result = {12'd0, gf20_result}; overflow = gf20_ovf; underflow = gf20_unf; end
            3'd5: begin result = {8'd0,  gf24_result}; overflow = gf24_ovf; underflow = gf24_unf; end
            3'd6: begin result = gf32_result;           overflow = gf32_ovf; underflow = gf32_unf; end
            default: begin
                // format_id=7: reserved → NaN (GF32 NaN encoding)
                result    = 32'hFFE00001;
                overflow  = 1'b0;
                underflow = 1'b0;
            end
        endcase
    end

endmodule

`default_nettype wire
