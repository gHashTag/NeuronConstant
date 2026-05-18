`default_nettype none
// loihi_compat.v — Loihi-1 opcode → TRI-27 ISA translator (combinational shim)
// Apache-2.0
//
// Translates Intel Loihi-1 4-bit opcodes to the canonical TRI-27 10-bit ISA
// in a single combinational stage (1 cycle, zero runtime latency).
//
// Note: tri27_opcode is 10-bit to accommodate the weight-RAM opcodes at
// addresses 0x200/0x208 (bit 9 set). The downstream dispatch bus uses 10
// bits; the alu9_decoder 4-bit opcode field occupies bits [3:0] of the
// lower half of this space.
//
// TRI-27 is the canonical ISA. This module is a compatibility shim only;
// it does NOT alter TRI-27 semantics or any v1.0.0 modules.
//
// R-SI-1 CLEAN: no standalone multiply operator. Multiplication is routed to
// gf16_mul instances at the execution layer.
//
// Loihi-1 opcode map (4-bit):
//   0x0  NOP            → TRI-27 0x000
//   0x1  MOV            → TRI-27 0x010
//   0x2  ADD            → TRI-27 0x020 (GF16 add)
//   0x3  SUB            → TRI-27 0x021 (GF16 sub)
//   0x4  MUL            → TRI-27 0x030 (gf16_mul, R-SI-1 safe)
//   0x5  MAC            → TRI-27 0x040 (GF16 dot-accumulate)
//   0x6  LIF_UPDATE     → TRI-27 0x100 (cortical_column step)
//   0x7  STDP_UPDATE    → TRI-27 0x108 (stdp_engine call)
//   0x8  SPIKE_OUT      → TRI-27 0x110 (spike route via D2D)
//   0x9  SET_REWARD     → TRI-27 0x180 (R-STDP reward register)
//   0xA  SET_LR         → TRI-27 0x188 (lr shift register)
//   0xB  BARRIER        → TRI-27 0x1F0 (3-phase commit barrier)
//   0xC  READ_TRACE     → TRI-27 0x1F8 (eligibility readout)
//   0xD  WRITE_WEIGHT   → TRI-27 0x200 (weight RAM write)
//   0xE  READ_WEIGHT    → TRI-27 0x208 (weight RAM read)
//   0xF  RESERVED       → unsupported=1 (no silent corruption)
//
// NeuronConstant canonical hardware catalog
// DOI: 10.5281/zenodo.19227877 · Apache-2.0

module loihi_compat (
    input  wire        opcode_valid,
    input  wire [3:0]  loihi_opcode,
    input  wire [15:0] loihi_operand_a,
    input  wire [15:0] loihi_operand_b,

    output reg  [9:0]  tri27_opcode,
    output reg  [15:0] tri27_operand_a,
    output reg  [15:0] tri27_operand_b,
    output reg         tri27_valid,
    output reg         unsupported
);

    // Opcode constants — TRI-27 ISA (10-bit to cover weight-RAM range)
    localparam [9:0] T27_NOP          = 10'h000;
    localparam [9:0] T27_MOV          = 10'h010;
    localparam [9:0] T27_ADD          = 10'h020;
    localparam [9:0] T27_SUB          = 10'h021;
    localparam [9:0] T27_MUL          = 10'h030;
    localparam [9:0] T27_MAC          = 10'h040;
    localparam [9:0] T27_LIF_UPDATE   = 10'h100;
    localparam [9:0] T27_STDP_UPDATE  = 10'h108;
    localparam [9:0] T27_SPIKE_OUT    = 10'h110;
    localparam [9:0] T27_SET_REWARD   = 10'h180;
    localparam [9:0] T27_SET_LR       = 10'h188;
    localparam [9:0] T27_BARRIER      = 10'h1F0;
    localparam [9:0] T27_READ_TRACE   = 10'h1F8;
    localparam [9:0] T27_WRITE_WEIGHT = 10'h200;
    localparam [9:0] T27_READ_WEIGHT  = 10'h208;

    always @(loihi_opcode or loihi_operand_a or loihi_operand_b or opcode_valid) begin
        // Default outputs
        tri27_opcode    = T27_NOP;
        tri27_operand_a = loihi_operand_a;
        tri27_operand_b = loihi_operand_b;
        tri27_valid     = 1'b0;
        unsupported     = 1'b0;

        if (opcode_valid) begin
            case (loihi_opcode)
                4'h0: begin
                    tri27_opcode = T27_NOP;
                    tri27_valid  = 1'b1;
                end
                4'h1: begin
                    tri27_opcode = T27_MOV;
                    tri27_valid  = 1'b1;
                end
                4'h2: begin
                    tri27_opcode = T27_ADD;
                    tri27_valid  = 1'b1;
                end
                4'h3: begin
                    tri27_opcode = T27_SUB;
                    tri27_valid  = 1'b1;
                end
                4'h4: begin
                    tri27_opcode = T27_MUL;
                    tri27_valid  = 1'b1;
                end
                4'h5: begin
                    tri27_opcode = T27_MAC;
                    tri27_valid  = 1'b1;
                end
                4'h6: begin
                    tri27_opcode = T27_LIF_UPDATE;
                    tri27_valid  = 1'b1;
                end
                4'h7: begin
                    tri27_opcode = T27_STDP_UPDATE;
                    tri27_valid  = 1'b1;
                end
                4'h8: begin
                    tri27_opcode = T27_SPIKE_OUT;
                    tri27_valid  = 1'b1;
                end
                4'h9: begin
                    tri27_opcode = T27_SET_REWARD;
                    tri27_valid  = 1'b1;
                end
                4'hA: begin
                    tri27_opcode = T27_SET_LR;
                    tri27_valid  = 1'b1;
                end
                4'hB: begin
                    tri27_opcode = T27_BARRIER;
                    tri27_valid  = 1'b1;
                end
                4'hC: begin
                    tri27_opcode = T27_READ_TRACE;
                    tri27_valid  = 1'b1;
                end
                4'hD: begin
                    tri27_opcode = T27_WRITE_WEIGHT;
                    tri27_valid  = 1'b1;
                end
                4'hE: begin
                    tri27_opcode = T27_READ_WEIGHT;
                    tri27_valid  = 1'b1;
                end
                4'hF: begin
                    tri27_opcode    = T27_NOP;
                    tri27_valid     = 1'b0;
                    unsupported     = 1'b1;
                end
                default: begin
                    tri27_opcode    = T27_NOP;
                    tri27_valid     = 1'b0;
                    unsupported     = 1'b1;
                end
            endcase
        end
    end

endmodule
`default_nettype wire
