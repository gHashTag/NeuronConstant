// decimal32.v — IEEE 754-2008 Decimal32 BID encoding
// Format: 1S + 5E (combination) + 20T (trailing significand)
// Level: SUPPORTED (extract sign/exp/coefficient); arithmetic TODO faithful
// Origin: trios-trainer-igla/src/fake_quant.rs FormatKind::Decimal32
`timescale 1ns/1ps
`default_nettype none

module decimal32 (
    input  wire        clk,
    input  wire        rst_n,
    // Storage interface
    input  wire [31:0] din,
    input  wire        load,
    output wire [31:0] dout,
    // Decode fields
    output wire        sign,
    output wire [7:0]  biased_exp,   // 8-bit combination decoded
    output wire [19:0] trailing_sig  // 20-bit trailing significand (T)
);

    // ---------------------------------------------------------------------------
    // Storage register (identity passthrough for arithmetic — TODO faithful)
    // ---------------------------------------------------------------------------
    reg [31:0] storage_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            storage_r <= 32'h0;
        else if (load)
            storage_r <= din;
    end

    assign dout = storage_r;

    // ---------------------------------------------------------------------------
    // BID-encoding field extraction (IEEE 754-2008 §3.5.2)
    // Combination field [30:26]:
    //   if [30:29] == 2'b11 → short exponent in [28:21], T in [20:0] (implicit msd=8 or 9)
    //   else                → exponent in [29:22], T in [21:0] (implicit msd=0..7)
    // We expose a simplified 8-bit exp for interop use.
    // ---------------------------------------------------------------------------
    wire [4:0] combo = storage_r[30:26];
    wire       inf_nan = (combo[4:3] == 2'b11) && (combo[2:1] == 2'b11);

    assign sign = storage_r[31];

    // Simplified: expose raw combination bits as biased_exp[7:3] and leading sig bit
    assign biased_exp    = {3'b0, combo};       // placeholder decode
    assign trailing_sig  = storage_r[19:0];     // lower 20 bits of T

    // TODO: implement faithful BID exponent/significand reconstruction (Phase 2)

endmodule
`default_nettype wire
