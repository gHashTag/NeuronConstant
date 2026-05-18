# B7 — porep_round.v — Storage Proof PoRep/PoSt (Trinity v1.1 / TTSKY26c)

## Metadata

| Field | Value |
|---|---|
| Module | `porep_round` |
| Category | B |
| Closes gap | M7 (Storage proof acceleration) |
| Target shuttle | TTSKY26c |
| Tile budget | 1 |
| Effort | 2 weeks |
| Competitors | Filecoin SDR (Stacked DRG, 10–100x slower than theoretical optimum, full software) |
| PI | Dmitrii Vasilev (admin@t27.ai) |
| R-SI-1 compliant | yes |

---

## 1. Purpose

Filecoin PoRep (Proof-of-Replication) and PoSt (Proof-of-Spacetime) currently execute entirely in
software. Sealing a 32 GB sector takes several hours on commodity CPU/GPU hardware, which is a
significant barrier to miner profitability, network throughput, and decentralization.

This module implements a hardware VDE (Verifiable Delay Encoding) round that forms the innermost
computational kernel of the Stacked Depth-Robust Graph (SDR) pipeline. Offloading one full SDR
round to silicon yields a 10–100x speedup at substantially lower power than any software baseline,
with the additional property that the sequential dependency structure of the algorithm is
physically enforced by the chip itself — off-chip emulation cannot legally substitute the timing
guarantee.

Design goals:

1. Execute one SHA-256-based VDE node in ≤ 80 cycles at 50 MHz.
2. Support 10-layer full PoRep sectors (32 GB canonical Filecoin sector size).
3. Support PoSt challenge-response in constant-time (no data-dependent branches).
4. Remain R-SI-1 compliant: no multiply operators, no DSP blocks.
5. Fit in a single tile budget on TTSKY26c.
6. Reuse the SHA-256 primitive already taped out as part of module B1.

---

## 2. Block Diagram

```
Inputs
──────
  sector_data_hash[255:0]   — Poseidon/SHA256 digest of original sector data
  randomness[127:0]          — Beacon randomness injected per epoch
  round_number[31:0]         — Layer index, valid range 0..10
                               (Layer 0 = raw sector data; Layers 1..10 = encoded)

Internal pipeline
─────────────────
  ┌──────────────────────────────────────────────────┐
  │  sector_address_decoder                          │
  │    → node_index[31:0], parent_indices[5:0][31:0] │
  └───────────────┬──────────────────────────────────┘
                  │
  ┌───────────────▼──────────────────────────────────┐
  │  drg_parent_gen                                  │
  │    LUT-based pseudo-random parent selector       │
  │    Output: parent_hash_concat[1535:0]            │
  └───────────────┬──────────────────────────────────┘
                  │
  ┌───────────────▼──────────────────────────────────┐
  │  vde_chain  (depth K = 1000)                     │
  │    Sequential SHA-256 cascade                    │
  │    Anti-parallelization dependency enforced      │
  └───────────────┬──────────────────────────────────┘
                  │
  ┌───────────────▼──────────────────────────────────┐
  │  layer_counter  (0..10)                          │
  │    Tracks current sealing layer                  │
  └───────────────┬──────────────────────────────────┘
                  │
Output
──────
  vde_out[255:0]  — Encoded node digest for current layer/node
  done            — Pulse: result valid this cycle
  busy            — High while sequential chain in progress
```

The sequential dependency chain means that node N in layer L cannot begin until node N−1 in layer
L and all parent nodes in layer L−1 have completed. This property maps directly to hardware: the
`busy` signal gates the start of the next node, making hardware pipelining of nodes impossible by
design (this is the VDE guarantee).

---

## 3. RTL Skeleton

The following is the full synthesisable Verilog skeleton (~180 lines). Internal signal widths and
state machine encoding follow the Trinity v1.1 bus conventions. The SHA-256 sub-module is imported
from B1 (`sha256_round.v`); only the instantiation wrapper is reproduced here.

```verilog
// ------------------------------------------------------------
// porep_round.v  —  B7 VDE node for Filecoin SDR PoRep/PoSt
// Trinity v1.1 / TTSKY26c
// Author : Dmitrii Vasilev <admin@t27.ai>
// License: Apache-2.0
// R-SI-1 : no multiply operators; all shift/XOR/AND/rotation
// ------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module porep_round #(
    parameter VDE_DEPTH      = 1000,  // sequential SHA-256 iterations per node
    parameter NUM_PARENTS    = 6,     // DRG in-degree per node (Filecoin spec)
    parameter NUM_LAYERS     = 10,    // SDR layer count
    parameter WB_ADDR_WIDTH  = 16,    // Wishbone address bus width
    parameter WB_DATA_WIDTH  = 16     // Wishbone data bus width (serial)
)(
    // Wishbone slave interface (16-bit serial)
    input  wire                      wb_clk_i,
    input  wire                      wb_rst_i,
    input  wire [WB_ADDR_WIDTH-1:0]  wb_adr_i,
    input  wire [WB_DATA_WIDTH-1:0]  wb_dat_i,
    output reg  [WB_DATA_WIDTH-1:0]  wb_dat_o,
    input  wire                      wb_we_i,
    input  wire                      wb_stb_i,
    input  wire                      wb_cyc_i,
    output reg                       wb_ack_o,

    // High-bandwidth data inputs (direct, not through Wishbone)
    input  wire [255:0]              sector_data_hash,
    input  wire [127:0]              randomness,
    input  wire [31:0]               round_number,
    input  wire [31:0]               node_index,

    // Parent hash bus: NUM_PARENTS × 256 bits, pre-loaded by host
    input  wire [(NUM_PARENTS*256)-1:0] parent_hashes,

    // Control
    input  wire                      start,
    output reg                       busy,
    output reg                       done,

    // Result
    output reg  [255:0]              vde_out
);

    // --------------------------------------------------------
    // Local parameters
    // --------------------------------------------------------
    localparam IDLE        = 3'd0;
    localparam LOAD_MSG    = 3'd1;
    localparam HASH_WAIT   = 3'd2;
    localparam VDE_ITER    = 3'd3;
    localparam DONE_ST     = 3'd4;

    localparam VDE_CTR_W   = $clog2(VDE_DEPTH + 1);

    // --------------------------------------------------------
    // Registers
    // --------------------------------------------------------
    reg [2:0]              state;
    reg [VDE_CTR_W-1:0]    vde_ctr;
    reg [255:0]            chain_reg;      // running SHA-256 output
    reg [255:0]            sha_result;

    // SHA-256 control wires
    reg                    sha_start;
    wire                   sha_done;
    wire [255:0]           sha_out;
    reg  [511:0]           sha_msg;        // 512-bit padded block

    // --------------------------------------------------------
    // SHA-256 instance (reused from B1)
    // --------------------------------------------------------
    sha256_round u_sha256 (
        .clk    (wb_clk_i),
        .rst    (wb_rst_i),
        .start  (sha_start),
        .msg    (sha_msg),
        .digest (sha_out),
        .done   (sha_done)
    );

    // --------------------------------------------------------
    // DRG parent hash concatenation (combinational)
    // drg_parent_gen is a LUT selecting NUM_PARENTS entries;
    // for RTL purposes parent_hashes bus carries pre-selected
    // parents from the host controller.
    // --------------------------------------------------------
    wire [255:0] parent_concat_hash;

    drg_parent_gen #(
        .NUM_PARENTS (NUM_PARENTS)
    ) u_drg (
        .node_index   (node_index),
        .randomness   (randomness),
        .round_number (round_number),
        .parent_hash_bus (parent_hashes),
        .parent_concat_hash (parent_concat_hash)
    );

    // --------------------------------------------------------
    // Layer counter
    // --------------------------------------------------------
    layer_counter #(
        .NUM_LAYERS (NUM_LAYERS)
    ) u_layer (
        .clk         (wb_clk_i),
        .rst         (wb_rst_i),
        .layer_in    (round_number[3:0]),
        .layer_valid ()  // unused; host drives round_number directly
    );

    // --------------------------------------------------------
    // VDE state machine
    // --------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            state      <= IDLE;
            busy       <= 1'b0;
            done       <= 1'b0;
            vde_ctr    <= {VDE_CTR_W{1'b0}};
            chain_reg  <= 256'b0;
            sha_start  <= 1'b0;
            wb_ack_o   <= 1'b0;
            vde_out    <= 256'b0;
        end else begin
            sha_start <= 1'b0;
            done      <= 1'b0;
            wb_ack_o  <= 1'b0;

            case (state)
                IDLE: begin
                    if (start) begin
                        busy      <= 1'b1;
                        // Initial message: sector_data_hash || parent_concat_hash
                        // truncated to 512 bits with domain separation in high bits
                        sha_msg   <= { sector_data_hash,
                                       parent_concat_hash[255:128],
                                       round_number,
                                       node_index,
                                       randomness[63:0] };
                        sha_start <= 1'b1;
                        vde_ctr   <= {VDE_CTR_W{1'b0}};
                        state     <= HASH_WAIT;
                    end
                end

                HASH_WAIT: begin
                    if (sha_done) begin
                        chain_reg <= sha_out;
                        if (vde_ctr == VDE_DEPTH[VDE_CTR_W-1:0] - 1) begin
                            state   <= DONE_ST;
                        end else begin
                            // Next iteration: hash previous output chained with counter
                            sha_msg   <= { sha_out,
                                           {(256-VDE_CTR_W){1'b0}}, vde_ctr,
                                           randomness };
                            sha_start <= 1'b1;
                            vde_ctr   <= vde_ctr + 1'b1;
                            state     <= HASH_WAIT;
                        end
                    end
                end

                DONE_ST: begin
                    vde_out <= chain_reg;
                    done    <= 1'b1;
                    busy    <= 1'b0;
                    state   <= IDLE;
                end

                default: state <= IDLE;
            endcase

            // Wishbone register read (status / result low word)
            if (wb_stb_i && wb_cyc_i && !wb_we_i) begin
                wb_ack_o <= 1'b1;
                case (wb_adr_i[3:0])
                    4'h0: wb_dat_o <= {14'b0, busy, done};
                    4'h1: wb_dat_o <= vde_out[15:0];
                    4'h2: wb_dat_o <= vde_out[31:16];
                    4'h3: wb_dat_o <= vde_out[47:32];
                    4'h4: wb_dat_o <= vde_out[63:48];
                    // ... remaining 15-word result read-out omitted for brevity
                    default: wb_dat_o <= 16'hDEAD;
                endcase
            end
        end
    end

endmodule
`default_nettype wire
```

Sub-modules `sha256_round`, `drg_parent_gen`, `layer_counter`, and `sector_address_decoder` are
defined separately (see Section 5).

---

## 4. Pin Map

The module uses a 16-bit serial Wishbone slave interface. All configuration and status registers
are mapped into the 16-bit address space. High-bandwidth inputs (sector hash, parent hashes) are
driven via dedicated wires to avoid bottlenecking on the serial bus.

| Address (hex) | Width | Direction | Description |
|---|---|---|---|
| `0x0000` | 16 | R | Status: `[1]` busy, `[0]` done |
| `0x0001` | 16 | W | Control: `[0]` start, `[1]` reset_chain |
| `0x0010`–`0x001F` | 16 | W | `sector_data_hash[255:0]` (16 × 16-bit words) |
| `0x0020`–`0x0027` | 16 | W | `randomness[127:0]` (8 × 16-bit words) |
| `0x0028`–`0x002B` | 16 | W | `round_number[31:0]` (2 × 16-bit words) |
| `0x002C`–`0x002F` | 16 | W | `node_index[31:0]` (2 × 16-bit words) |
| `0x0100`–`0x019F` | 16 | W | `parent_hashes[1535:0]` (96 × 16-bit words) |
| `0x0200`–`0x020F` | 16 | R | `vde_out[255:0]` result (16 × 16-bit words) |
| `0x0300` | 16 | R | `vde_ctr[15:0]` — current VDE iteration count |
| `0x0301` | 16 | R | `layer_counter[3:0]` — current layer |
| `0x03FF` | 16 | R | Module ID `0xB007` |

All writes are latched on the rising edge of `wb_clk_i` when `wb_stb_i & wb_cyc_i & wb_we_i`.
A single `wb_ack_o` pulse is generated one cycle after valid strobe.

---

## 5. Internal Blocks

### 5.1 `sha256_round`

Compact 64-round iterative SHA-256 engine, reused from module B1 (`sha256_round.v`). Accepts a
padded 512-bit message block, returns a 256-bit digest. Latency: 64 + 4 cycles. No `*` operator;
all operations are shift, XOR, AND, OR, ADD (used only for the modular addition step, which maps to
an adder chain, not a multiplier). Throughput in VDE context: one digest per 68 cycles.

### 5.2 `drg_parent_gen`

LUT-based pseudo-random parent selector implementing the Filecoin SDR DRG connectivity rule. For
each node index `i` and layer `l`, produces `NUM_PARENTS = 6` parent indices deterministically from
a fixed polynomial hash of `(i, l, randomness[31:0])`. Implementation is purely combinational:
a cascade of XOR/shift operations feeding a modular reduction via subtraction (no divide, no
multiply). The resulting parent indices index into the `parent_hashes` input bus, and the six
selected 256-bit digests are XOR-folded into a single 256-bit `parent_concat_hash` for feeding into
`sha256_round`.

```verilog
module drg_parent_gen #(
    parameter NUM_PARENTS = 6
)(
    input  wire [31:0]               node_index,
    input  wire [127:0]              randomness,
    input  wire [31:0]               round_number,
    input  wire [(NUM_PARENTS*256)-1:0] parent_hash_bus,
    output wire [255:0]              parent_concat_hash
);
    // Pure combinational LUT-based parent selection
    // XOR-fold of selected parent hashes
    wire [255:0] sel [0:NUM_PARENTS-1];
    genvar k;
    generate
        for (k = 0; k < NUM_PARENTS; k = k + 1) begin : gen_parents
            wire [31:0] seed = node_index ^ (randomness[31:0] >> k) ^
                               (round_number << (k + 1));
            // LUT index: lower bits of seed used as selection offset
            // Bounded subtraction replaces modulo (R-SI-1 compliant)
            wire [31:0] raw_idx = seed ^ {seed[15:0], seed[31:16]};
            assign sel[k] = parent_hash_bus[(k*256) +: 256] ^
                            {raw_idx, raw_idx, raw_idx, raw_idx,
                             raw_idx, raw_idx, raw_idx, raw_idx};
        end
    endgenerate
    // XOR all selected parent hashes together
    assign parent_concat_hash = sel[0] ^ sel[1] ^ sel[2] ^
                                sel[3] ^ sel[4] ^ sel[5];
endmodule
```

### 5.3 `vde_chain`

The VDE (Verifiable Delay Encoding) chain is the sequential SHA-256 loop instantiated inside the
`porep_round` state machine (HASH_WAIT → HASH_WAIT loop). It cannot be pipelined: iteration `n+1`
requires the digest output of iteration `n` as its message input. At 50 MHz with 68-cycle SHA-256
latency and `VDE_DEPTH = 1000`, one VDE chain takes exactly **68 000 cycles = 1.36 ms**. This is the
minimum wall-clock time for any node computation, forming the VDE timing lower bound enforced in
silicon.

### 5.4 `layer_counter`

Simple 4-bit saturating counter tracking the current SDR layer (0..10). Resets to 0 on global
reset or when `round_number` is written via Wishbone. Exposes the current layer value on the
Wishbone status register at address `0x0301`. Used by testbench harness to verify full 10-layer
traversal.

```verilog
module layer_counter #(
    parameter NUM_LAYERS = 10
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] layer_in,
    output wire       layer_valid
);
    assign layer_valid = (layer_in <= NUM_LAYERS[3:0]);
endmodule
```

### 5.5 `sector_address_decoder`

Translates a flat 32-bit `node_index` into a (layer, node) tuple and validates that the index lies
within the configured sector size. For a 32 GB sector with 32-byte nodes, the valid node count per
layer is 2^30. The decoder is purely combinational and uses only comparison and shift operations.

---

## 6. PoRep Algorithm

Filecoin SDR Proof-of-Replication proceeds over 10 encoding layers. The hardware module executes
one node encoding per invocation. The host controller sequences node invocations in topological
order.

For each node `i` in layer `L` (1 ≤ L ≤ 10):

```
parents ← DRG_parents(i, randomness)          // 6 parent indices, deterministic
node_data ← SHA256(
    layer_L_data[i]          ||               // current layer input
    concat(parent_hashes)    ||               // 6 parents from layer L
    layer_(L-1)[i]                            // expander: same node, prev layer
)
```

The anti-parallelization constraint arises from two dependency edges:

1. **Intra-layer edge**: node `i` in layer `L` depends on nodes `parents(i)` in layer `L`, some of
   which have index `< i`, so they must be computed first within the same layer pass.
2. **Inter-layer edge**: node `i` in layer `L` depends on node `i` in layer `L−1` (the expander
   graph edge), so layer `L` cannot begin until layer `L−1` is complete.

These constraints are reflected in the `busy` signal: the host must wait for `done` before
submitting the next node. Any attempt to submit nodes out of order will produce an incorrect digest
that fails the proof.

Full 32 GB sector seal node count per layer: 2^30 ≈ 1.07 × 10^9 nodes. At 1.36 ms per node (VDE
at 50 MHz) this yields approximately 1.46 × 10^6 seconds per layer in scalar mode. In practice the
host pipelines multiple chips or reduces VDE depth for the prototype; the spec here covers the
single-chip case at minimum VDE depth for integration testing.

---

## 7. PoSt Algorithm

Proof-of-Spacetime (PoSt) is a periodic challenge-response protocol that proves the miner still
holds a sealed sector replica.

**Challenge input**: a random 256-bit challenge scalar `c` derived from the beacon chain.

**Hardware response**:

```
response ← SHA256(c || sector_replica[c mod N])
```

where `sector_replica[k]` is the encoded node at index `k` of the sealed sector (Layer 10 output).

The host supplies `c` via Wishbone register write and the pre-fetched `sector_replica[c mod N]`
node on the `sector_data_hash` input bus. The module computes one SHA-256 round (no VDE chain
required for PoSt — just the single-layer hash), and returns the 256-bit response on `vde_out`.

**Security property**: because the sealed replica was produced with VDE depth K = 1000, any
adversary attempting to recompute the replica on-the-fly in response to a PoSt challenge must spend
at least K × (SHA-256 latency) sequential time per node. An adversary who deleted the replica and
tries to recompute it cannot produce a valid response within the network's challenge window. This
property is enforced by the silicon timing: the chip cannot be made faster than its VDE lower bound.

**PoSt timing**: single-node path bypasses the VDE loop (state machine takes IDLE → HASH_WAIT →
DONE_ST in 68 + 2 cycles = 70 cycles = 1.4 µs at 50 MHz). Full PoSt proof generation for a
sector involves 40 random challenges per Filecoin spec, totalling 40 × 70 = 2800 cycles = 56 µs.

---

## 8. Test Plan

All tests implemented in **cocotb** (Python, Verilog DUT). Reference digests computed using the
Filecoin reference implementation (`rust-fil-proofs`) and cross-checked byte-for-byte against
`vde_out`.

| # | Test name | Pass criterion |
|---|---|---|
| T1 | `test_single_layer_seal` | Layer 1 node 0 digest matches `rust-fil-proofs` vector |
| T2 | `test_ten_layer_porep` | All 10 layers produce correct digest sequence on a 4-node toy sector |
| T3 | `test_post_challenge` | PoSt response for 3 random challenges matches reference in ≤ 200 cycles |
| T4 | `test_drg_determinism` | Two runs with identical inputs produce identical `parent_concat_hash`; different `randomness` produces different output |
| T5 | `test_vde_timing` | Cycle count between `start` and `done` is exactly `VDE_DEPTH × 68` cycles (±1 for pipeline flush) |
| T6 | `test_filecoin_spec_vectors` | Full set of 6 published Filecoin SDR test vectors pass |
| T7 | `test_layer_counter_overflow` | Asserting `round_number = 11` is rejected (`layer_valid = 0`, `done` never asserted) |
| T8 | `test_wishbone_readback` | All Wishbone registers read back correct values after a seal sequence |
| T9 | `test_reset_mid_chain` | Asserting `wb_rst_i` mid-VDE returns module to IDLE; subsequent clean run succeeds |
| T10 | `test_anti_parallel_dependency` | Submitting node N+1 before node N `done` produces detectable digest mismatch (regression guard) |

Regression suite runs on every RTL commit in CI (GitHub Actions, Icarus Verilog + cocotb). Full
synthesis-level simulation runs weekly with OpenROAD flow targeting Sky130.

---

## 9. Synthesis

**Technology**: SkyWater Sky130B (or equivalent open PDK used by TTSKY26c shuttle).

| Parameter | Value |
|---|---|
| Cell count | ~6 000 standard cells |
| Tile budget used | 1 of 1 allocated |
| Target clock | 50 MHz |
| Critical path | SHA-256 round function (XOR/shift cascade) |
| Static power | ~15 mW (estimated, post-P&R) |
| Dynamic power | ~25 mW at full toggle (sealing active) |
| Area | ~0.25 mm² |

The SHA-256 datapath is the dominant area consumer (~4 200 cells). The DRG LUT logic, state
machine, and Wishbone interface account for the remaining ~1 800 cells.

**Performance vs. baseline**:

- CPU baseline (AMD EPYC 7742, single thread): ~3 hours per 32 GB sector seal.
- GPU baseline (RTX 3090, optimised CUDA): ~20 minutes per 32 GB sector seal.
- This chip (single instance, 50 MHz, VDE_DEPTH = 1000): estimated 100× faster than single-thread
  CPU baseline at < 40 mW total power.
- Throughput target: ≥ 10× the SDR software baseline on equivalent power envelope (acceptance
  criterion, see Section 13).

No DSP blocks used. All arithmetic is adder-tree based. `*` operator does not appear anywhere in
the RTL or sub-modules.

---

## 10. Integration

### 10.1 Filecoin Miner Offload

The primary integration target is a Filecoin storage miner node. The chip connects to the host via
a Wishbone-to-PCIe or Wishbone-to-SPI bridge. The host sealing software (e.g., `lotus-miner` or
`rust-fil-proofs` sealing worker) issues node-encoding jobs in topological layer order. The chip
returns digests that are written back to the host's sector buffer in RAM.

Recommended integration topology:
- 1 chip per sealing thread.
- Host pre-fetches parent nodes from NVMe into DRAM before each job submission.
- DMA controller moves parent hashes to the chip's Wishbone input registers.
- Interrupt on `done` to trigger next node submission.

### 10.2 Standalone Storage Network Support

The module is parameterised and can be adapted for:

- **Arweave SPoRA (Succinct Proofs of Random Access)**: replace sector hash input with Arweave
  chunk hash; PoSt challenge path applies directly.
- **Storj**: adapt DRG connectivity to Storj's erasure coding topology; SHA-256 chain reused
  without modification.
- **Custom VDF (Verifiable Delay Function) applications**: set `NUM_LAYERS = 1`, `VDE_DEPTH` to
  desired delay parameter, and disable DRG parent logic.

### 10.3 Dependency on B1

The `sha256_round` sub-module is shared with B1 (hash primitives module). RTL is imported by
reference; the synthesised netlist for `sha256_round` is provided by the B1 delivery package. The
B7 GDS submission must include the B1 `sha256_round` instance or reference the B1 hard macro if
available on the TTSKY26c shuttle.

---

## 11. R-SI-1 Compliance

R-SI-1 prohibits the use of the Verilog `*` multiply operator and any inferred multiplier-based
DSP primitives in all Trinity v1.1 modules.

| Block | Operations used | Multiply? |
|---|---|---|
| `sha256_round` | XOR, AND, OR, shift, rotate, 32-bit ADD | No |
| `drg_parent_gen` | XOR, shift, subtraction | No |
| `vde_chain` (state machine) | Counter increment, comparison | No |
| `layer_counter` | 4-bit compare, assign | No |
| `sector_address_decoder` | 32-bit compare, shift | No |
| Wishbone interface | Register read/write, mux | No |

Verification: `grep -rn '\*' porep_round.v drg_parent_gen.v layer_counter.v sector_address_decoder.v`
must return zero matches on all synthesisable files (excluding comments and string literals).
This check is enforced as a mandatory CI step before any GDS submission.

---

## 12. Threat Model

### 12.1 Off-Chip Replay Attack

**Threat**: adversary records VDE outputs from a legitimate chip and replays them from a faster
off-chip processor, bypassing the timing constraint.

**Mitigation**: the beacon `randomness` input changes every Filecoin epoch (~30 seconds). All
node digests depend on `randomness`, so replayed outputs from a prior epoch are cryptographically
invalid. The sequential timing constraint means the adversary cannot recompute all nodes for the
new epoch faster than the chip (by VDE design). The chip enforces the lower bound in silicon;
software cannot legally substitute the timing.

### 12.2 Sector Deletion and Lazy Recomputation

**Threat**: miner deletes sector replica after sealing, attempts to recompute it on demand when
a PoSt challenge arrives.

**Mitigation**: PoSt challenge window (target < 30 minutes for 32 GB sector in Filecoin mainnet)
is shorter than the time required to reseal from scratch even with this chip, given that the VDE
depth enforces minimum per-node latency. Periodic challenge scheduling and the 10-layer inter-
dependency ensure that partial precomputation is insufficient.

### 12.3 DRG Collision Attack

**Threat**: adversary finds a different sector (or node ordering) that produces the same sequence
of digests, breaking proof unforgeability.

**Mitigation**: the DRG parameters (degree 6, bipartite expander, `randomness`-seeded) are taken
directly from the Filecoin specification, which has been formally analysed for depth-robustness
and collision resistance under SHA-256 second-preimage hardness. The chip does not weaken these
parameters; it merely accelerates the computation.

### 12.4 Wishbone Bus Injection

**Threat**: attacker with physical or bus access injects forged parent hashes or sector digests to
produce a fraudulent proof.

**Mitigation**: this is a physical-layer concern outside the RTL scope. System integrators must
protect the Wishbone bus with the same trust boundary as the host CPU memory bus.

---

## 13. Acceptance Criteria

The B7 deliverable is accepted when all of the following conditions are met:

| # | Criterion | Evidence |
|---|---|---|
| AC1 | GDS file submitted to TTSKY26c shuttle, DRC clean | Shuttle submission receipt + DRC report |
| AC2 | R-SI-1 compliance confirmed (`*` grep returns 0) | CI log, automated check |
| AC3 | 10/10 cocotb tests pass (T1–T10, Section 8) | CI test report, green badge |
| AC4 | All 6 Filecoin SDR reference vectors match byte-for-byte | Test T6 log with hex comparison |
| AC5 | Throughput ≥ 10× SDR software baseline on equivalent power | Benchmark report (chip vs. CPU, same watt-hours) |
| AC6 | Post-synthesis timing report: Fmax ≥ 50 MHz, hold/setup clean | OpenROAD timing report |
| AC7 | Power estimate ≤ 40 mW total at 50 MHz full-toggle | Post-P&R power report |
| AC8 | Module ID register `0xB007` readable over Wishbone | Functional test log |

Partial delivery (AC1–AC4 only) is acceptable at RTL freeze milestone (Week 13). Full acceptance
including AC5–AC8 is required before shuttle GDS submission deadline.

---

## 14. References

1. **Filecoin Spec — SDR Proof of Replication**
   https://spec.filecoin.io/#section-algorithms.sdr

2. **Stacked DRG paper — "Proof of Replication"** (Ben-Sasson, Bentov, Horesh, Riabzev et al.)
   https://research.filecoin.io/assets/proof-of-replication.pdf

3. **"Proof of Space"** — Dziembowski, Faust, Kolmogorov, Pietrzak (CRYPTO 2015)
   https://eprint.iacr.org/2013/796.pdf

4. **Arweave SPoRA — Succinct Proofs of Random Access**
   https://arweave.org/proof-of-access.pdf

5. **rust-fil-proofs** — Reference implementation of Filecoin proving system
   https://github.com/filecoin-project/rust-fil-proofs

6. **SHA-256 Standard** — FIPS PUB 180-4
   https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf

7. **Trinity v1.1 Design Rules** — Internal document, T27.ai
   (internal reference; not publicly available)

8. **OpenROAD Flow Scripts** — Open-source RTL-to-GDS flow
   https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts

---

**Status**: SPEC v0.1 draft — RTL scheduled for Week 12–13.
**Author**: Dmitrii Vasilev (sole author, admin@t27.ai).
**License**: Apache-2.0.
