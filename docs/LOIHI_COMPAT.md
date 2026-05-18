# LOIHI_COMPAT — Loihi-1 ISA Compatibility Shim

**Module:** `common/isa/loihi_compat.v`  
**Version:** 1.0.0  
**License:** Apache-2.0  
**DOI:** 10.5281/zenodo.19227877

---

## Overview

`loihi_compat` is a pure-combinational opcode translator that maps Intel
Loihi-1 4-bit opcodes to the canonical TRI-27 9-bit ISA in a single cycle
with zero runtime latency.

**TRI-27 is canonical.** This module is a drop-in compatibility shim to
allow Loihi-1 instruction streams to execute on Trinity hardware without
modification to any TRI-27 execution units or v1.0.0 modules.

### Competitive Positioning

Closes the compatibility gap versus Intel catalyst-n1 (Loihi-1-compatible
128-core SNN processor). Trinity pipelines can serve as a drop-in
replacement for Loihi-1-targeted SNN workloads.

---

## Interface

```verilog
module loihi_compat (
    input  wire        opcode_valid,
    input  wire [3:0]  loihi_opcode,
    input  wire [15:0] loihi_operand_a,
    input  wire [15:0] loihi_operand_b,

    output reg  [8:0]  tri27_opcode,
    output reg  [15:0] tri27_operand_a,
    output reg  [15:0] tri27_operand_b,
    output reg         tri27_valid,
    output reg         unsupported
);
```

### Port Descriptions

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `opcode_valid` | input | 1 | Assert high when Loihi opcode is valid. When low, all outputs deassert. |
| `loihi_opcode` | input | 4 | Loihi-1 opcode (16 encodings, 0x0–0xF). |
| `loihi_operand_a` | input | 16 | Loihi source operand A, passed through unchanged. |
| `loihi_operand_b` | input | 16 | Loihi source operand B, passed through unchanged. |
| `tri27_opcode` | output | 9 | Translated TRI-27 opcode. |
| `tri27_operand_a` | output | 16 | Forwarded operand A (pass-through). |
| `tri27_operand_b` | output | 16 | Forwarded operand B (pass-through). |
| `tri27_valid` | output | 1 | High when translated output is valid and should be dispatched. |
| `unsupported` | output | 1 | High when `loihi_opcode` is RESERVED (0xF). No silent corruption. |

---

## Opcode Mapping Table

| Loihi Opcode | Encoding | TRI-27 Opcode | Encoding | Semantics |
|---|---|---|---|---|
| `NOP` | 0x0 | `T27_NOP` | 0x000 | No operation. Pipeline filler. |
| `MOV` | 0x1 | `T27_MOV` | 0x010 | Register-to-register move. Operand A sourced, written to destination. |
| `ADD` | 0x2 | `T27_ADD` | 0x020 | GF(16) addition of operand_a and operand_b. Characteristic-2 field. |
| `SUB` | 0x3 | `T27_SUB` | 0x021 | GF(16) subtraction. Equivalent to ADD in characteristic-2, retained for Loihi semantic parity. |
| `MUL` | 0x4 | `T27_MUL` | 0x030 | GF(16) multiply via `gf16_mul` instance. R-SI-1 compliant (no standalone `*`). |
| `MAC` | 0x5 | `T27_MAC` | 0x040 | GF(16) dot-product accumulate. Maps to gf16_dot4 accumulation path. |
| `LIF_UPDATE` | 0x6 | `T27_LIF_UPDATE` | 0x100 | Leaky Integrate-and-Fire state step. Dispatched to `cortical_column` execution unit. |
| `STDP_UPDATE` | 0x7 | `T27_STDP_UPDATE` | 0x108 | Spike-Timing Dependent Plasticity weight update. Dispatched to `stdp_engine`. |
| `SPIKE_OUT` | 0x8 | `T27_SPIKE_OUT` | 0x110 | Spike emission and routing via D2D interconnect. |
| `SET_REWARD` | 0x9 | `T27_SET_REWARD` | 0x180 | Write reward scalar to R-STDP reward register. Used in reinforcement learning loop. |
| `SET_LR` | 0xA | `T27_SET_LR` | 0x188 | Write learning-rate value to LR shift register. |
| `BARRIER` | 0xB | `T27_BARRIER` | 0x1F0 | Global synchronization barrier. Triggers `tri_3phase_commit.v` 3-phase commit protocol. |
| `READ_TRACE` | 0xC | `T27_READ_TRACE` | 0x1F8 | Read eligibility trace from trace buffer for readout. |
| `WRITE_WEIGHT` | 0xD | `T27_WRITE_WEIGHT` | 0x200 | Write synapse weight to weight RAM. |
| `READ_WEIGHT` | 0xE | `T27_READ_WEIGHT` | 0x208 | Read synapse weight from weight RAM. |
| `RESERVED` | 0xF | — | — | Invalid opcode. Sets `unsupported=1`, `tri27_valid=0`. No silent corruption. |

---

## Semantics Detail

### Arithmetic Opcodes (0x0–0x5)

All arithmetic operates in GF(16) (4-bit Galois field, irreducible polynomial
x⁴ + x + 1). The 16-bit operands are decomposed by downstream execution units
into GF(16) nibbles. The shim passes operands through unchanged.

**MUL**: routes to `gf16_mul` instance at execution layer. The `*` operator is
never used in synthesis RTL per R-SI-1 invariant.

**MAC**: maps to the GF(16) dot-accumulate path (`gf16_dot4`). Loihi MAC
semantics (multiply-accumulate over a synapse array) are preserved by the
accumulation register in the execution unit.

### Neural Opcodes (0x6–0xC)

These opcodes control the SNN (Spiking Neural Network) runtime:

- **LIF_UPDATE**: triggers a cortical-column membrane potential integration
  step. Maps directly to the `cortical_column` module's step interface.
- **STDP_UPDATE**: invokes the STDP engine for Hebbian weight adjustment.
  Pre/post spike timing is passed in operand_a/operand_b.
- **SPIKE_OUT**: emits a spike event onto the D2D (die-to-die) routing fabric.
- **SET_REWARD / SET_LR**: configure the reinforcement learning parameters
  for R-STDP. Scalar values are passed in operand_a.
- **BARRIER**: issues a 3-phase commit barrier (see `tri_3phase_commit.v`).
  Guarantees all in-flight STDP updates are committed before proceeding.
- **READ_TRACE**: reads out the eligibility trace for offline analysis or
  teacher-forcing feedback.

### Memory Opcodes (0xD–0xE)

- **WRITE_WEIGHT / READ_WEIGHT**: access the weight RAM. operand_a carries
  the synapse address, operand_b carries the weight value (WRITE) or is
  ignored (READ with result returned on tri27_operand_b by downstream unit).

---

## Limitations

1. **Flat synapse only.** Loihi-1 supports hierarchical 3D synapse
   compartments. Trinity maps all synapse accesses to a flat weight RAM
   address space. 3D compartment addressing must be linearized by the
   compiler before issuing to this shim.

2. **No multi-compartment LIF.** Loihi-1 supports per-neuron multi-dendritic
   compartment trees. `LIF_UPDATE` here maps to a single cortical-column
   step; dendritic tree reduction must be performed in software before
   issuing the opcode.

3. **No on-chip learning rule microcode.** Loihi-1 embeds configurable
   learning rule microcode per core. TRI-27 exposes fixed STDP + R-STDP
   engines. Custom learning rules require recompilation to STDP primitives.

4. **RESERVED 0xF is fatal.** Unlike Loihi-1 which treats RESERVED as NOP,
   this shim asserts `unsupported=1` to surface erroneous instruction streams
   explicitly. Callers must handle the `unsupported` flag.

---

## Performance

| Metric | Value |
|--------|-------|
| Translation latency | 1 cycle (combinational) |
| Runtime overhead | 0 cycles |
| Clock domain | Input clock domain (no internal registers) |
| Area estimate | ~16 LUT4 (ASIC: ~32 gates) |
| Throughput | 1 opcode/cycle (limited by downstream dispatch) |

---

## Compliance

- **R-SI-1 CLEAN**: no standalone `*` operator in synthesisable RTL. Verified
  with `common/verification/r_si_1_check.sh common/isa`.
- **iverilog -g2005**: testbench `tb_loihi_compat.v` passes all 17 checks
  (16 opcode mappings + opcode_valid edge case).
- **v1.0.0 modules untouched**: `alu9_decoder`, `cortical_column`, and all
  other v1.0.0 modules are unmodified.

---

## Integration Example

```verilog
loihi_compat u_loihi_shim (
    .opcode_valid    (fetch_valid),
    .loihi_opcode    (instr[3:0]),
    .loihi_operand_a (instr[19:4]),
    .loihi_operand_b (instr[35:20]),
    .tri27_opcode    (dispatch_opcode),
    .tri27_operand_a (dispatch_a),
    .tri27_operand_b (dispatch_b),
    .tri27_valid     (dispatch_valid),
    .unsupported     (fetch_error)
);
```

Connect `dispatch_opcode` / `dispatch_valid` to the TRI-27 execution
pipeline dispatch stage. Assert `fetch_error` to your trap/exception handler.

---

## References

- TRI-27 canonical ISA: see t27 spec in project memory and `tiles/e-engine/rtl/alu9_decoder.v`
- Loihi-1 architecture: M. Davies et al., "Loihi: A Neuromorphic Manycore Processor with On-Chip Learning," *IEEE Micro*, 2018.
- `tri_3phase_commit.v`: `common/depin/v2/tri_3phase_commit.v`
- `cortical_column.v`: `tiles/gamma-surface/rtl/cortical_column.v`
- `gf16_mul.v`: `tiles/phi-anchor/rtl/gf16_mul.v`
- NeuronConstant DOI: https://doi.org/10.5281/zenodo.19227877
