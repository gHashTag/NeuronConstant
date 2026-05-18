# Trinity Ring Topology — Tri-Directional Mesh Fabric

**Author:** Dmitrii Vasilev <admin@t27.ai>
**Status:** Architecture spec for TTSKY26c interconnect
**Parent:** [UNIFIED_COMPUTER_PARADIGM.md](./UNIFIED_COMPUTER_PARADIGM.md)

---

## 1. Why a Ring, Not a Star

The naive interconnect for three dies is a star (one host, two peripherals) or a fully connected `K3` graph. For a **symmetrically specialized** triad — where no die is "the host" — the right minimum-edge topology is a **tri-ring**:

```
          Phi (1×1)
         ▲     \
         │      \
   [φ→ε link]  [γ→φ link]
         │        \
         │         \
       Euler ──────► Gamma
        (8×2) [ε→γ]  (8×4)
```

Three nodes, three directional edges. Each die has exactly two cross-die ports and equal status in the fabric.

---

## 2. Sacred Properties

| Property               | Value                                         |
|------------------------|-----------------------------------------------|
| Node count             | 3 (one per Trinity organ)                     |
| Edges                  | 3 (matches ternary state cardinality)         |
| Diameter               | 1 (any peer reachable in one hop)             |
| Bisection bandwidth    | 2 links                                       |
| Fault tolerance        | Single-link failure → graceful 2-hop reroute  |
| Symmetry               | Vertex-transitive (no privileged node)        |

The tri-ring is the **smallest interconnect** that satisfies symmetric specialization with full pairwise reachability.

---

## 3. Bandwidth Budget

Per-link physical layer:
- Width: 8 bits/cycle
- Clock: 50 MHz nominal
- Bandwidth: 8 × 50 × 10⁶ = **400 Mbit/s = 50 MB/s per directional link**

Aggregate fabric:
- 3 directional links → **150 MB/s tri-ring aggregate**
- Sufficient for streaming AI inference across the pipeline Phi → Euler → Gamma

Reverse links (Gamma → Phi closing the ring, etc.) carry handshake, retry, and TMR vote traffic.

---

## 4. RTL Module — `trinity_ring_router`

One instance per die. Each instance has:
- 1 local port (toward this die's on-chip mesh)
- 2 external ports (toward the two peer dies)
- 3-way arbiter + virtual-channel buffers (escape VC + data VC)

```verilog
module trinity_ring_router #(
    parameter DIE_ID  = 2'b00,   // 00=Phi, 01=Euler, 10=Gamma
    parameter DATA_W  = 8
) (
    input  wire             clk,
    input  wire             rst_n,

    // Local port (to die's on-chip mesh)
    input  wire [DATA_W-1:0] local_in,
    input  wire              local_in_valid,
    output wire              local_in_ready,
    output wire [DATA_W-1:0] local_out,
    output wire              local_out_valid,
    input  wire              local_out_ready,

    // CW neighbor (Phi -> Euler -> Gamma -> Phi)
    input  wire [DATA_W-1:0] cw_in,
    input  wire              cw_in_valid,
    output wire              cw_in_ready,
    output wire [DATA_W-1:0] cw_out,
    output wire              cw_out_valid,
    input  wire              cw_out_ready,

    // CCW neighbor (reverse direction)
    input  wire [DATA_W-1:0] ccw_in,
    input  wire              ccw_in_valid,
    output wire              ccw_in_ready,
    output wire [DATA_W-1:0] ccw_out,
    output wire              ccw_out_valid,
    input  wire              ccw_out_ready
);
endmodule
```

Wormhole flit format (24-bit head flit on an 8-bit link, 3 cycles):

```
[7:6]  destination die ID (00=Phi, 01=Euler, 10=Gamma, 11=broadcast)
[5:4]  source die ID
[3:0]  opcode class (XCHIP_*, MEMORY, TMR, BARRIER)
[15:8] payload length in bytes
[23:16] sequence number
```

Followed by `length` body flits, then optional tail flit with CRC-8.

---

## 5. Routing Rules

Two-die paths trivially follow the directional ring. The router uses **dimension-order routing** with deadlock avoidance via two virtual channels:

| Source → Dest      | Path                       | Hops |
|--------------------|----------------------------|------|
| Phi → Euler        | direct CW                  | 1    |
| Euler → Gamma      | direct CW                  | 1    |
| Gamma → Phi        | direct CW                  | 1    |
| Phi → Gamma        | direct CCW (1 hop)         | 1    |
| Broadcast (any)    | CW + CCW simultaneously    | 1    |

Because diameter = 1, no multi-hop routing tables are required at runtime.

---

## 6. Cross-Die DMA Engine

A `trinity_unified_dma` block is attached to each router's local port. It accepts a `{src_addr, dst_addr, length}` descriptor and translates it into ring traffic:

```verilog
module trinity_unified_dma (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] src_addr,    // any die
    input  wire [31:0] dst_addr,    // any die
    input  wire [15:0] length,
    input  wire        start,
    output wire        done,

    // Local ring router interface
    output wire [7:0]  ring_tx_data,
    output wire        ring_tx_valid,
    input  wire        ring_tx_ready,
    input  wire [7:0]  ring_rx_data,
    input  wire        ring_rx_valid,
    output wire        ring_rx_ready
);
endmodule
```

Address bits `[19:16]` select the destination die per the address map in `UNIFIED_COMPUTER_PARADIGM.md` §4.

---

## 7. Tile Budget for TTSKY26c

| Module                       | Tiles per die | Dies       | Total tiles |
|------------------------------|---------------|------------|-------------|
| `trinity_ring_router`        | 2             | Phi, Euler, Gamma | 6   |
| `trinity_unified_dma`        | 1             | Phi, Euler, Gamma | 3   |
| Distributed virtual mapper   | 1             | Gamma only        | 1   |
| **Tri-ring fabric total**    |               |                   | **10** |

Well within TTSKY26c's overall budget (~120 tiles planned).

---

## 8. Verification Plan

1. **Unit tests (Cocotb)** — for `trinity_ring_router`: single-flit, multi-flit, congestion, two-source contention, deadlock smoke test.
2. **Three-router cluster sim** — instantiate three routers in a SystemVerilog testbench, drive random `{src, dst, len}` DMA descriptors, verify in-order delivery and CRC integrity.
3. **R-SI-1 compliance** — confirm no standalone `*` operators leak into router/DMA RTL.
4. **GDS hooks** — top-level pinout reserves the 8-bit CW/CCW pads on each TT submission.

---

## 9. Why This Topology Cannot Be Replaced

A star demotes two dies to peripherals — violates "symmetric specialization." A full `K3` adds a third edge nobody needs (any pair is one hop via the ring). A bus serializes traffic — kills parallel pipeline stages. The tri-ring is the **unique minimum-edge vertex-transitive graph** on three nodes. There is no better choice for Trinity.

---

## License

Apache-2.0. Sole author: Dmitrii Vasilev <admin@t27.ai>.
