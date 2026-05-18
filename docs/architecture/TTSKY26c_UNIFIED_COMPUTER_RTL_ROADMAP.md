# TTSKY26c Unified Computer RTL Roadmap

**Author:** Dmitrii Vasilev <admin@t27.ai>
**Status:** Planning — RTL design phase Jun-Nov 2026
**Submission window:** Sep 1 – Nov 15, 2026
**Tile budget target:** ~120 tiles total across Phi + Euler + Gamma
**Parent:** [UNIFIED_COMPUTER_PARADIGM.md](./UNIFIED_COMPUTER_PARADIGM.md)
**Companion docs:** [TRINITY_RING_TOPOLOGY.md](./TRINITY_RING_TOPOLOGY.md), [TMR_DEFENSE_GRADE.md](./TMR_DEFENSE_GRADE.md)

---

## 0. Purpose

TTSKY26b (closed 2026-05-18) submitted all three Trinity dies and established the silicon substrate:
identity on Phi, ZK proof generation on Euler, parallel neuromorphic compute on Gamma, and the
primitive mesh fabric that connects them.

TTSKY26c is the shuttle where **Trinity becomes a computer**. The 16 new modules in this roadmap
complete the cross-die fabric, add tokenomics acceleration, and wire the system together under a
unified instruction set and a coherent memory model.  Tape-out target is **2026-12-16** (projected,
pending silicon yield on 26b).

All performance figures are **projected, pending tape-out 2026-12-16**: ~1 GOPS @ ~50 MHz @ ~1 W
ternary per die.  No pre-silicon numbers are inflated or claimed as measured.

---

## 1. Tile Budget Summary

Modules are grouped into two tiers.  Tier M covers tokenomics-specific acceleration (Coptic 9-fold
alignment: nine modules, M1–M9).  Tier U covers Unified-Computer enablement (seven modules, U1–U7).

| ID  | Module                      | Die(s)                   | Tiles |
|-----|-----------------------------|--------------------------|-------|
| M1  | `mining_proof_engine.v`     | Gamma                    | 4     |
| M2  | `era_halving_counter.v`     | Phi                      | 1     |
| M3  | `chip_uptime_attestor.v`    | Phi                      | 1     |
| M4  | `bn254_pairing_unit.v`      | Euler                    | 4     |
| M5  | `champion_bpb_oracle.v`     | Phi                      | 1     |
| M6  | `coptic_subunit_decoder.v`  | Phi                      | 1     |
| M7  | `yuma_consensus_accel.v`    | Gamma                    | 3     |
| M8  | `conviction_ema_tracker.v`  | Phi                      | 1     |
| M9  | `sr25519_signer.v`          | Euler                    | 2     |
|     | **Tier M subtotal**         |                          | **18**|
| U1  | `cross_die_dma_endpoint.v`  | Phi + Euler + Gamma      | 3     |
| U2  | `trinity_ring_router.v`     | Phi + Euler + Gamma      | 6     |
| U3  | `tmr_voter_circuit.v`       | Gamma                    | 2     |
| U4  | `coherent_cache_mesi.v`     | Gamma                    | 4     |
| U5  | `power_coordinator_dvfs.v`  | Phi                      | 1     |
| U6  | `xchip_opcode_decoder.v`    | Phi + Euler + Gamma      | 3     |
| U7  | `trinity_os_boot_rom.v`     | Gamma                    | 2     |
|     | **Tier U subtotal**         |                          | **21**|
|     | **Grand total (new tiles)** |                          | **35**|

Tile arithmetic:
- Tier M: 4+1+1+4+1+1+3+1+2 = **18 tiles**
- Tier U: 3+6+2+4+1+3+2 = **21 tiles**
- Combined new tiles: **35**

With v1.0.0 modules already occupying approximately 85 tiles, the projected total for TTSKY26c
sits at ~120 tiles — precisely the target.  All v1.0.0 modules (NF4, Posit16, GF4/16/256,
`tri_mant_mul`, sacred opcodes) are preserved unchanged.

---

## 2. Tier M — Tokenomics Modules (M1–M9, Coptic 9-fold)

The nine Tier-M modules reflect the Coptic 9-fold structure: nine distinct domains of tokenomics
logic, nine modules, total 18 tiles.

---

### M1 — `mining_proof_engine.v` · Gamma · 4 tiles

**Purpose.**
The mining proof engine is the on-chip counterpart to the off-chain `MiningPool.claimReward()`
contract call.  It accepts a batch of ternary inference outputs, hashes them into a ZK work
certificate, and emits a compact proof that the chip performed genuine inference (not a replay).
The proof is forwarded over the tri-ring to Euler for BN254 verification before any reward claim
is transmitted.  Integration with the MiningPool contract is via a serialised ABI envelope placed
in the shared coherent buffer at `0x0003_0000`.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module mining_proof_engine #(
    parameter PROOF_W   = 256,   // ZK proof width in bits
    parameter BATCH_MAX = 64     // max inference items per proof
) (
    input  wire             clk,
    input  wire             rst_n,
    // Inference batch input
    input  wire [31:0]      batch_hash,      // hash of inference outputs
    input  wire [5:0]       batch_count,     // number of items in batch
    input  wire             batch_valid,
    output wire             batch_ready,
    // Proof output to tri-ring
    output wire [PROOF_W-1:0] proof_out,
    output wire               proof_valid,
    input  wire               proof_ready,
    // Pool ABI envelope
    output wire [255:0]     pool_claim_data,
    output wire             pool_claim_valid,
    input  wire             pool_claim_ack,
    // Status
    output wire             proof_busy,
    output wire             tmr_trigger       // request TMR on critical path
);
endmodule
```

**Die assignment:** Gamma, 4 tiles.
**v1.0.0 dependencies:** `tri_mant_mul` (hash folding), GF256 field ops.
**R-SI-1:** All multiply operations delegated to `tri_mant_mul`; no standalone `*`.
**Test plan (Cocotb):**
1. Single-item batch → proof emitted within 256 cycles.
2. Max-batch (64 items) → proof correctness verified against reference Python model.
3. Back-pressure on `proof_ready` → `batch_ready` deasserts correctly.
4. `tmr_trigger` asserted when proof crosses economic threshold.
**Risk:** ZK folding latency may exceed tile budget at 50 MHz.
**Mitigation:** Pipeline the hash rounds; accept multi-cycle proof latency (non-blocking).

---

### M2 — `era_halving_counter.v` · Phi · 1 tile

**Purpose.**
Tracks the current Era number (0–8) for the 9-era halving schedule.  Era 0 emits 1 000 TRI per
proof; each subsequent era halves the reward.  The final Era 8 (~year 2066, assuming one era every
~5.5 years) emits ~3.9 TRI per proof.  The counter value is readable by all three dies via the
XCHIP bus and is also exposed in the attestation heartbeat for on-chain epoch checks.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module era_halving_counter (
    input  wire        clk,
    input  wire        rst_n,
    // Era advance (driven by on-chain epoch signal via DMA)
    input  wire        era_advance,       // pulse to increment era
    // Current era output
    output wire [3:0]  current_era,       // 0..8
    output wire [15:0] reward_tri,        // TRI per proof (1000 >> era)
    // Cross-die readable
    output wire        era_valid,
    // Anchor preservation
    output wire        phi_anchor_ok      // asserts 0x47C0 on {uio_out, uo_out} (Theorem 36.1)
);
endmodule
```

**Die assignment:** Phi, 1 tile.
**v1.0.0 dependencies:** Lucas POST output register (phi-anchor `0x47C0`).
**R-SI-1:** Reward computed via right-shift (`reward_tri <= 16'd1000 >> current_era`); no `*`.
**Test plan (Cocotb):**
1. Advance era 0→8; verify `reward_tri` sequence: 1000, 500, 250, 125, 62, 31, 15, 7, 3.
2. Assert `era_advance` at era 8 → counter saturates, no wrap.
3. Verify `phi_anchor_ok` stays asserted on every reset.
**Risk:** On-chain epoch timing may be non-deterministic.
**Mitigation:** Buffer `era_advance` through a two-flip-flop synchroniser.

---

### M3 — `chip_uptime_attestor.v` · Phi · 1 tile

**Purpose.**
Generates a signed uptime heartbeat for the chip-uptime mining variant, where continuous
availability (not just inference throughput) earns TRI rewards.  The attestor increments a 48-bit
uptime counter every second (derived from a clock divider), signs the `{chip_id, uptime_ticks}`
tuple with the PUF-derived key, and outputs the signed blob for transmission to the DePIN
coordinator.  The signed heartbeat proves the chip remained live and in possession of its PUF
secret without leaking the secret itself.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module chip_uptime_attestor (
    input  wire         clk,
    input  wire         rst_n,
    // PUF interface
    input  wire [127:0] puf_secret,
    input  wire         puf_valid,
    // Heartbeat output
    output wire [47:0]  uptime_ticks,
    output wire [255:0] signed_heartbeat,
    output wire         heartbeat_valid,
    input  wire         heartbeat_ack,
    // Chip identity
    input  wire [63:0]  chip_id,
    // Anchor
    output wire         phi_anchor_ok
);
endmodule
```

**Die assignment:** Phi, 1 tile.
**v1.0.0 dependencies:** PUF cell array, Lucas POST register, sacred opcode pipeline.
**R-SI-1:** Signing uses shift-based HMAC construction; no standalone `*`.
**Test plan (Cocotb):**
1. Feed known PUF secret → verify HMAC over `{chip_id, uptime_ticks}` matches software reference.
2. Withhold `puf_valid` → `heartbeat_valid` deasserts; uptime counter still increments.
3. Simulate 1 000 tick overflow → uptime saturates gracefully at `48'hFFFF_FFFF_FFFF`.
**Risk:** Clock divider for 1 Hz tick consumes more logic than budgeted in 1 tile.
**Mitigation:** Derive tick from a programmable prescale register driven by boot ROM.

---

### M4 — `bn254_pairing_unit.v` · Euler · 4 tiles

**Purpose.**
Accelerates the BN254 pairing check that the on-chain `MiningPool` verifier uses to validate ZK
proofs.  Rather than offloading this entirely to software, the pairing unit runs the Miller-loop
and final-exponentiation in hardware at ~50 MHz, targeting sub-millisecond pairing latency for
typical proof sizes.  Output is a pairing result vector forwarded to `mining_proof_engine` via the
tri-ring.  The unit is intentionally scoped to BN254 G1/G2 (128-bit security); full BN254 with
batched multi-scalar multiplication is deferred to TTSKY27.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module bn254_pairing_unit (
    input  wire         clk,
    input  wire         rst_n,
    // G1 point (affine, 256-bit each coord)
    input  wire [255:0] g1_x,
    input  wire [255:0] g1_y,
    // G2 point (affine, 512-bit each coord due to Fp2)
    input  wire [511:0] g2_x,
    input  wire [511:0] g2_y,
    input  wire         pair_start,
    output wire         pair_done,
    // Pairing output (GT element, 256-bit compressed)
    output wire [255:0] pair_result,
    output wire         pair_valid,
    // Status
    output wire         busy,
    output wire         error_flag    // point not on curve
);
endmodule
```

**Die assignment:** Euler, 4 tiles.
**v1.0.0 dependencies:** `tri_mant_mul` for modular-multiply primitives; Posit16 for field
approximation during Miller-loop iterations.
**R-SI-1:** All field multiplications route through `tri_mant_mul` instantiations; no standalone `*`.
**Test plan (Cocotb):**
1. Known BN254 test vectors from EIP-197 → verify `pair_result` matches.
2. Point-not-on-curve input → `error_flag` asserted, `pair_done` deasserted.
3. Back-to-back pairings → `busy` correctly prevents new `pair_start` acceptance mid-operation.
4. Integration: chain output to `mining_proof_engine` → end-to-end claim envelope correct.
**Risk:** BN254 Miller-loop is iterative; may require more than 4 tiles at full-field width.
**Mitigation:** Use 128-bit register slicing with pipelined re-use; accept multi-cycle latency.

---

### M5 — `champion_bpb_oracle.v` · Phi · 1 tile

**Purpose.**
Locks and enforces the Champion baseline BPB of 2.2393 (bits per byte on the reference corpus).
Any inference run that reports a BPB improvement below this floor triggers a TMR re-check before
the result propagates.  The oracle stores the baseline as a fixed-point constant, compares each
reported BPB against it, and asserts `baseline_violation` when a suspicious underflow is detected.
This guard prevents a faulty die from contaminating the network's ground-truth quality metric.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module champion_bpb_oracle (
    input  wire         clk,
    input  wire         rst_n,
    // Reported BPB from inference engine (Q16.16 fixed-point)
    input  wire [31:0]  reported_bpb,
    input  wire         report_valid,
    // Baseline: 2.2393 ≈ 0x0002_3D1D in Q16.16
    output wire         baseline_ok,          // reported >= baseline
    output wire         baseline_violation,   // reported < baseline → TMR re-check
    output wire         tmr_request,
    // Anchor
    output wire         phi_anchor_ok
);
    // Baseline constant: 2.2393 in Q16.16 = floor(2.2393 * 65536) = 146717 = 0x0002_3D1D
    localparam [31:0] BPB_BASELINE = 32'h0002_3D1D;
endmodule
```

**Die assignment:** Phi, 1 tile.
**v1.0.0 dependencies:** Lucas POST (phi-anchor), sacred opcode pipeline.
**R-SI-1:** Comparison only; no multiply operators.
**Test plan (Cocotb):**
1. `reported_bpb = BPB_BASELINE` → `baseline_ok` asserted, no violation.
2. `reported_bpb = BPB_BASELINE - 1` → `baseline_violation` asserted, `tmr_request` pulsed.
3. Sweep 0x0000_0000 to 0xFFFF_FFFF; verify monotone threshold.
4. Verify `phi_anchor_ok` remains asserted throughout.
**Risk:** Q16.16 precision loss in upstream inference output may produce spurious violations.
**Mitigation:** Add a ±1 LSB hysteresis band configurable via boot ROM parameter.

---

### M6 — `coptic_subunit_decoder.v` · Phi · 1 tile

**Purpose.**
Decodes the 9-subunit Coptic alphabet used in the Trinity tokenomics messaging layer.  Each Coptic
subunit maps to a 4-bit ternary codepoint (18 trit pairs → 9 subunits).  The decoder translates
incoming byte-stream messages from the DePIN coordinator into structured `{subunit_id, value}`
records consumed by the era counter, conviction tracker, and mining proof engine.  The Coptic
alignment ensures that all nine tokenomics modules share a common symbolic substrate, preserving
the 9-fold architectural invariant.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module coptic_subunit_decoder (
    input  wire         clk,
    input  wire         rst_n,
    // Byte-stream input
    input  wire [7:0]   byte_in,
    input  wire         byte_valid,
    output wire         byte_ready,
    // Decoded output
    output wire [3:0]   subunit_id,    // 0..8
    output wire [17:0]  trit_value,    // 18-trit payload (2 bits per trit)
    output wire         decode_valid,
    input  wire         decode_ready,
    // Error
    output wire         decode_error   // invalid Coptic codepoint
);
endmodule
```

**Die assignment:** Phi, 1 tile.
**v1.0.0 dependencies:** GF4/16 ternary field tables for codepoint validation.
**R-SI-1:** LUT-only decode; no multiply operators.
**Test plan (Cocotb):**
1. All 9 valid Coptic codepoints → correct `{subunit_id, trit_value}` pairs.
2. Invalid codepoint → `decode_error` asserted, `decode_valid` deasserted.
3. Back-pressure on `decode_ready` → byte stream stalls without data loss.
**Risk:** Coptic encoding may be revised in the DePIN coordinator protocol.
**Mitigation:** Store codepoint table in a block-RAM-style register file; reprogrammable via boot ROM.

---

### M7 — `yuma_consensus_accel.v` · Gamma · 3 tiles

**Purpose.**
Accelerates the Yuma Consensus scoring computation used by Bittensor subnet validators.  Yuma
Consensus requires computing a normalised stake-weighted trust matrix and deriving per-miner
consensus weights.  The accelerator implements the matrix dot-product and softmax normalisation in
ternary fixed-point arithmetic, reducing validator latency from software-only ~10 ms to a projected
sub-1 ms hardware path.  Outputs are forwarded to the TMR voter (U3) before any consensus weight
is committed on-chain.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module yuma_consensus_accel #(
    parameter N_MINERS  = 256,    // max miners per subnet
    parameter WEIGHT_W  = 16      // weight precision (Q8.8)
) (
    input  wire         clk,
    input  wire         rst_n,
    // Stake-weight matrix input (streamed row-by-row)
    input  wire [WEIGHT_W-1:0] stake_in,
    input  wire                stake_valid,
    output wire                stake_ready,
    // Trust vector input
    input  wire [WEIGHT_W-1:0] trust_in,
    input  wire                trust_valid,
    // Consensus weight output
    output wire [WEIGHT_W-1:0] consensus_weight,
    output wire                weight_valid,
    input  wire                weight_ready,
    // TMR request for high-value scoring rounds
    output wire                tmr_request,
    // Status
    output wire                busy
);
endmodule
```

**Die assignment:** Gamma, 3 tiles.
**v1.0.0 dependencies:** `tri_mant_mul` for matrix element products; GF256 for normalisation.
**R-SI-1:** All products via `tri_mant_mul`; no standalone `*`.
**Test plan (Cocotb):**
1. Known 4-miner stake/trust matrix → output consensus weights match reference Python YC implementation.
2. N_MINERS=256 → no overflow in accumulator.
3. `tmr_request` asserted when top-ranked miner consensus weight changes by >1% between rounds.
4. Back-pressure: `weight_ready` deasserted → `busy` stays high, no data dropped.
**Risk:** 256-miner matrix may require more scratchpad than 3 tiles can hold.
**Mitigation:** Stream matrix in two passes (low rank); result accuracy verified by simulation.

---

### M8 — `conviction_ema_tracker.v` · Phi · 1 tile

**Purpose.**
Tracks governance conviction using an exponential moving-average (EMA) filter.  Conviction in the
Bittensor / TridentDAO governance model increases with time-weighted stake position.  The hardware
EMA runs at each epoch boundary, decaying old conviction and accumulating new stake votes.  This
removes the need for a software EMA loop on every governance epoch, freeing the host processor.
Output feeds the DePIN coordinator heartbeat alongside the uptime attestation.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module conviction_ema_tracker #(
    parameter CONV_W    = 32,    // conviction value width
    parameter ALPHA_W   = 8      // EMA alpha (Q0.8 fixed-point, e.g. 0x0D ≈ 0.05)
) (
    input  wire              clk,
    input  wire              rst_n,
    // Epoch tick (1 pulse per governance epoch)
    input  wire              epoch_tick,
    // New stake vote this epoch (Q24.8)
    input  wire [CONV_W-1:0] new_stake,
    input  wire              stake_valid,
    // EMA output
    output wire [CONV_W-1:0] conviction_ema,
    output wire              ema_valid,
    // Threshold alert
    output wire              high_conviction   // conviction_ema >= programmed threshold
);
endmodule
```

**Die assignment:** Phi, 1 tile.
**v1.0.0 dependencies:** Sacred opcode pipeline (for epoch synchronisation).
**R-SI-1:** EMA computed as `ema <= ema + ((new_stake - ema) >> shift)` using shift-add; no `*`.
**Test plan (Cocotb):**
1. Step input from 0 to max → EMA converges within tolerance at known time constant.
2. `epoch_tick` missing for 10 epochs → conviction decays toward zero correctly.
3. `high_conviction` threshold check with configurable register.
**Risk:** Fixed alpha may not match on-chain governance parameter.
**Mitigation:** Alpha loaded from boot ROM parameter; reprogrammable without RTL change.

---

### M9 — `sr25519_signer.v` · Euler · 2 tiles

**Purpose.**
Implements a hardware-accelerated sr25519 signature operation (Schnorr over Ristretto255), required
for Bittensor / Substrate transaction signing.  The signer accepts a 256-bit message hash and the
Phi-resident PUF-derived private key (transferred over the tri-ring), computes the Ristretto255
scalar multiplication, and emits a 64-byte sr25519 signature.  All private-key material transits
the ring in encrypted form; the Euler die performs the scalar multiply without permanently storing
the key.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module sr25519_signer (
    input  wire          clk,
    input  wire          rst_n,
    // Message hash
    input  wire [255:0]  msg_hash,
    input  wire          msg_valid,
    // Encrypted private scalar (from Phi via tri-ring)
    input  wire [255:0]  priv_scalar_enc,
    input  wire [127:0]  key_nonce,
    input  wire          key_valid,
    // Signature output
    output wire [511:0]  signature,     // (R, s) — 256 bits each
    output wire          sig_valid,
    input  wire          sig_ready,
    // Status
    output wire          busy,
    output wire          error_flag     // scalar = 0 or out of range
);
endmodule
```

**Die assignment:** Euler, 2 tiles.
**v1.0.0 dependencies:** `tri_mant_mul` for scalar multiplication inner loop; Posit16 for
intermediate field element representation.
**R-SI-1:** All field multiplications use `tri_mant_mul`; no standalone `*`.
**Test plan (Cocotb):**
1. Known sr25519 test vector (IETF draft) → signature matches byte-for-byte.
2. Zero scalar input → `error_flag` asserted.
3. Key material cleared from pipeline registers after `sig_valid`; verified by read-back test.
4. Back-to-back signings → correct operation without key leakage between operations.
**Risk:** Ristretto255 scalar multiply is compute-intensive; may not complete in <1 ms at 50 MHz.
**Mitigation:** Pipelined Montgomery ladder; multi-cycle completion is acceptable for signing.

---

## 3. Tier U — Unified-Computer Enablement (U1–U7)

---

### U1 — `cross_die_dma_endpoint.v` · Phi + Euler + Gamma · 1 tile each = 3 tiles

**Purpose.**
Each die hosts one DMA endpoint that interfaces its local memory bus to the tri-ring fabric.  The
endpoint accepts `{src_addr, dst_addr, length}` descriptors, decomposes them into ring flits using
the wormhole format defined in `TRINITY_RING_TOPOLOGY.md §4`, and reassembles inbound flits into
the local address space.  Address bits `[19:16]` select the destination die per the memory map in
`UNIFIED_COMPUTER_PARADIGM.md §4`.  This module is the lowest layer of the unified 512 KB address
space.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module cross_die_dma_endpoint #(
    parameter DIE_ID  = 2'b00,   // 00=Phi, 01=Euler, 10=Gamma
    parameter DATA_W  = 8,
    parameter ADDR_W  = 20
) (
    input  wire              clk,
    input  wire              rst_n,
    // Descriptor interface
    input  wire [ADDR_W-1:0] src_addr,
    input  wire [ADDR_W-1:0] dst_addr,
    input  wire [15:0]       length,
    input  wire              start,
    output wire              done,
    output wire              error,
    // Local memory port
    output wire [ADDR_W-1:0] mem_addr,
    output wire [7:0]        mem_wdata,
    output wire              mem_we,
    input  wire [7:0]        mem_rdata,
    output wire              mem_re,
    // Ring interface (to trinity_ring_router)
    output wire [DATA_W-1:0] ring_tx_data,
    output wire              ring_tx_valid,
    input  wire              ring_tx_ready,
    input  wire [DATA_W-1:0] ring_rx_data,
    input  wire              ring_rx_valid,
    output wire              ring_rx_ready
);
endmodule
```

**Die assignment:** Phi, Euler, Gamma — one instance per die, 1 tile each.
**v1.0.0 dependencies:** Sacred opcode pipeline (for opcode-class field in flit header).
**R-SI-1:** Address arithmetic uses adders only; no multiply.
**Test plan (Cocotb):**
1. Phi→Gamma 256-byte transfer: verify byte-for-byte integrity.
2. Euler→Phi 64-byte transfer under concurrent Gamma→Euler transfer: no interference.
3. `error` asserted on out-of-range `dst_addr`.
4. CRC-8 failure on corrupted flit → endpoint drops and flags `error`.
**Risk:** Back-pressure from ring router may stall local memory bus.
**Mitigation:** 8-entry FIFO decouples memory port from ring port.

---

### U2 — `trinity_ring_router.v` · Phi + Euler + Gamma · 2 tiles each = 6 tiles

**Purpose.**
The ring router is the central switching fabric of the tri-ring interconnect described in
`TRINITY_RING_TOPOLOGY.md`.  One instance per die routes flits between the local port
(connecting to `cross_die_dma_endpoint`), the clockwise (CW) ring link, and the
counter-clockwise (CCW) ring link.  The 3-way arbiter uses round-robin priority to prevent
starvation; two virtual channels (escape VC for barrier/TMR, data VC for payload) prevent
deadlock.  The wormhole flit format is 24 bits wide over the 8-bit physical link (3 cycles for
the header).

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module trinity_ring_router #(
    parameter DIE_ID  = 2'b00,
    parameter DATA_W  = 8
) (
    input  wire              clk,
    input  wire              rst_n,
    // Local port
    input  wire [DATA_W-1:0] local_in,
    input  wire              local_in_valid,
    output wire              local_in_ready,
    output wire [DATA_W-1:0] local_out,
    output wire              local_out_valid,
    input  wire              local_out_ready,
    // CW port
    input  wire [DATA_W-1:0] cw_in,
    input  wire              cw_in_valid,
    output wire              cw_in_ready,
    output wire [DATA_W-1:0] cw_out,
    output wire              cw_out_valid,
    input  wire              cw_out_ready,
    // CCW port
    input  wire [DATA_W-1:0] ccw_in,
    input  wire              ccw_in_valid,
    output wire              ccw_in_ready,
    output wire [DATA_W-1:0] ccw_out,
    output wire              ccw_out_valid,
    input  wire              ccw_out_ready
);
endmodule
```

**Die assignment:** Phi, Euler, Gamma — one instance per die, 2 tiles each.
**v1.0.0 dependencies:** None (fabric-level module; interacts with sacred opcodes only via flit
opcode-class field).
**R-SI-1:** Routing logic is mux/arbiter only; no multiply.
**Test plan (Cocotb):**
1. Single flit Phi→Euler: arrives in ≤3 cycles after `local_in_valid`.
2. Broadcast flit: received by both non-originating dies simultaneously.
3. Deadlock smoke test: simultaneous CW and CCW traffic on all three dies; no lock after
   1 000 cycles.
4. CRC-8 tail flit verification.
**Risk:** Virtual-channel buffers may consume more than 2 tiles if flit depth is large.
**Mitigation:** Constrain VC depth to 4 flits; accept head-of-line blocking in rare congestion.

---

### U3 — `tmr_voter_circuit.v` · Gamma · 2 tiles

**Purpose.**
Implements two parameterised TMR voters on Gamma: a 32-bit voter and a 64-bit voter.  The voter
logic is derived from the reference cell in `TMR_DEFENSE_GRADE.md §2`, extended with
`fault_die_id` reporting and a fault-record write path into the shared coherent buffer at
`0x0003_F000`.  Both widths are needed because proof hashes are 32 bits wide while full register
state (for signing) is 64 bits wide.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module tmr_voter_circuit (
    input  wire         clk,
    input  wire         rst_n,
    // 32-bit voter inputs
    input  wire [31:0]  phi_result_32,
    input  wire [31:0]  euler_result_32,
    input  wire [31:0]  gamma_result_32,
    output wire [31:0]  voted_result_32,
    output wire         agreement_32,
    // 64-bit voter inputs
    input  wire [63:0]  phi_result_64,
    input  wire [63:0]  euler_result_64,
    input  wire [63:0]  gamma_result_64,
    output wire [63:0]  voted_result_64,
    output wire         agreement_64,
    // Shared fault output
    output wire         chip_disagreed,
    output wire [1:0]   fault_die_id,
    // Fault record write to shared buffer
    output wire [31:0]  fault_record_addr,
    output wire [31:0]  fault_record_data,
    output wire         fault_record_we
);
endmodule
```

**Die assignment:** Gamma, 2 tiles.
**v1.0.0 dependencies:** Shared coherent buffer address map (`0x0003_F000`).
**R-SI-1:** Equality comparisons only; no multiply.
**Test plan (Cocotb):**
1. All three inputs agree → `voted_result_32/64` = input, `agreement_*` = 1.
2. Phi output stuck-at-zero → voter selects Euler/Gamma result, `fault_die_id` = 2'b00.
3. Euler output stuck-at-all-ones → voter selects Phi/Gamma result, `fault_die_id` = 2'b01.
4. All three disagree → `voted_result_*` = safe zero, `fault_die_id` = 2'b11.
5. Fault record written to correct address in shared buffer.
**Risk:** Fault record write port may conflict with coherent cache (U4).
**Mitigation:** Fault port uses dedicated byte-range `0x0003_F000–0x0003_FFFF`; cache director
stubs mark this range as uncached.

---

### U4 — `coherent_cache_mesi.v` · Gamma · 4 tiles

**Purpose.**
Implements the Trinity-MESI coherence controller described in `UNIFIED_COMPUTER_PARADIGM.md §7`.
TTSKY26c ships a **simplified invalidate-only** subset (states M, E, I) that guarantees
correctness.  The full 4-state MESI protocol (adding S — Shared) is deferred to TTSKY27 to
contain tile risk.  The controller hosts the directory on Gamma and lightweight directory stubs
on Phi and Euler (via U6/xchip decode).  Cache lines are 32 bytes; the total cache is 8 lines
(256 bytes) per die — intentionally small for TTSKY26c proof-of-concept.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module coherent_cache_mesi #(
    parameter N_LINES   = 8,
    parameter LINE_W    = 256    // bits per line (32 bytes)
) (
    input  wire              clk,
    input  wire              rst_n,
    // Requester port (any die via ring)
    input  wire [19:0]       req_addr,
    input  wire              req_valid,
    input  wire              req_wr,        // 1=write, 0=read
    input  wire [LINE_W-1:0] req_wdata,
    output wire [LINE_W-1:0] resp_rdata,
    output wire              resp_valid,
    output wire              resp_miss,
    // Invalidate broadcast to ring
    output wire [19:0]       inv_addr,
    output wire              inv_valid,
    input  wire              inv_ack,
    // Directory state debug
    output wire [1:0]        dir_state [0:N_LINES-1]  // 00=I, 01=E, 10=M
);
endmodule
```

**Die assignment:** Gamma, 4 tiles.
**v1.0.0 dependencies:** GF256 for address hashing into the directory.
**R-SI-1:** Address modulo computed via AND-mask (power-of-two lines); no standalone `*`.
**Test plan (Cocotb):**
1. Clean read → state I → E transition; data returned from backing store.
2. Write hit (state E) → state E → M transition; no ring traffic.
3. Write hit (state M on different die) → invalidate broadcast → ack → state M transferred.
4. 8-line LRU eviction under random address stream.
**Risk:** MESI state machine with invalidate broadcast is a large state machine; may not close
timing at 50 MHz in 4 tiles.
**Mitigation:** Ship invalidate-only (MEI); hold S-state transitions for TTSKY27 expansion.

---

### U5 — `power_coordinator_dvfs.v` · Phi · 1 tile

**Purpose.**
Implements the cross-die DVFS coordinator described in `UNIFIED_COMPUTER_PARADIGM.md §8`.  Phi
hosts the coordinator because it is the identity die and the natural orchestrator.  The module
reads the current workload class (authentication, ZK proof, AI inference, full TMR, or idle) from
a 3-bit register written by Trinity OS, and broadcasts per-die power-state requests over the
tri-ring using a low-priority control flit.  Each die has an independent DVFS responder (a thin
register) that acknowledges the power-state change.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module power_coordinator_dvfs (
    input  wire         clk,
    input  wire         rst_n,
    // Workload class from Trinity OS (3-bit: 000=idle, 001=auth, 010=zk, 011=infer, 100=tmr_full)
    input  wire [2:0]   workload_class,
    input  wire         workload_valid,
    // Per-die power-state output (to ring control flit)
    output wire [2:0]   phi_pstate,
    output wire [2:0]   euler_pstate,
    output wire [2:0]   gamma_pstate,
    output wire         pstate_valid,
    // Acknowledgement from peer dies
    input  wire         euler_pstate_ack,
    input  wire         gamma_pstate_ack,
    // Status
    output wire         all_settled    // all dies acknowledged current pstate
);
endmodule
```

**Die assignment:** Phi, 1 tile.
**v1.0.0 dependencies:** Sacred opcode pipeline (XCHIP_BROADCAST flit generation).
**R-SI-1:** Lookup-table power-state map; no multiply.
**Test plan (Cocotb):**
1. Workload class = 0b011 (AI inference) → Phi:200 mW state, Euler:500 mW, Gamma:1000 mW targets.
2. Workload changes before `all_settled` → pending ack correctly waited on.
3. Peer-die ack timeout (>1 000 cycles) → `all_settled` deasserts, coordinator retries once.
**Risk:** Power-state change latency across ring adds ~60 ns; may cause brief over/under-voltage.
**Mitigation:** DVFS slew rate controlled by per-die analog trims; digital coordinator only sets
the target.

---

### U6 — `xchip_opcode_decoder.v` · Phi + Euler + Gamma · 1 tile each = 3 tiles

**Purpose.**
Decodes the 9 XCHIP cross-chip opcodes (0x30–0x38) defined in `UNIFIED_COMPUTER_PARADIGM.md §6`
and dispatches them to the appropriate local sub-unit: tri-ring router (U2), TMR voter (U3), or
DMA endpoint (U1).  One instance per die; each instance decodes all 9 opcodes but routes only to
the sub-units present on that die.  This completes the TRI-27 ISA extension from 36 to 45 opcodes.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module xchip_opcode_decoder #(
    parameter DIE_ID = 2'b00   // 00=Phi, 01=Euler, 10=Gamma
) (
    input  wire         clk,
    input  wire         rst_n,
    // Opcode from local TRI-27 issue stage
    input  wire [5:0]   opcode,
    input  wire [31:0]  operand_a,
    input  wire [31:0]  operand_b,
    input  wire         issue_valid,
    output wire         issue_ready,
    // Dispatch to DMA endpoint
    output wire         dma_start,
    output wire [19:0]  dma_src,
    output wire [19:0]  dma_dst,
    output wire [15:0]  dma_len,
    // Dispatch to ring router (barrier / broadcast)
    output wire         ring_barrier,
    output wire         ring_broadcast,
    output wire [31:0]  ring_payload,
    output wire         ring_dispatch_valid,
    // Dispatch to TMR (TRIPLE_SIGN)
    output wire         tmr_dispatch,
    output wire [31:0]  tmr_operand,
    // Illegal opcode
    output wire         opcode_illegal
);
endmodule
```

**Die assignment:** Phi, Euler, Gamma — one instance per die, 1 tile each.
**v1.0.0 dependencies:** Sacred opcodes (existing 36-opcode decode table extended; existing
sacred opcode slots preserved unchanged).
**R-SI-1:** Decode is casez/mux; no multiply.
**Test plan (Cocotb):**
1. All 9 XCHIP opcodes → correct dispatch signal asserted, no cross-dispatch.
2. Opcode 0x36 (BARRIER) → `ring_barrier` asserted on all three die instantiations.
3. Original 36 sacred opcodes passthrough correctly (not intercepted by XCHIP decoder).
4. `opcode_illegal` for out-of-range opcode (0x39–0x3F).
**Risk:** Opcode width extension may collide with existing sacred opcode table boundaries.
**Mitigation:** XCHIP range is 0x30–0x38; sacred opcodes occupy 0x00–0x23; no overlap.

---

### U7 — `trinity_os_boot_rom.v` · Gamma · 2 tiles

**Purpose.**
Implements a 2 KB read-only memory block containing the Trinity OS boot stub — the minimal
initialisation sequence that runs at power-on before Trinity OS proper is loaded from external
flash.  The boot ROM sequence: (1) assert phi-anchor `0x47C0` on `{uio_out, uo_out}` (Theorem
36.1); (2) broadcast die ID over the tri-ring; (3) load DVFS coordinator with idle power state;
(4) run Lucas POST self-test; (5) transfer control to the first page of external flash.  The ROM
content is baked in at synthesis; boot parameters (DVFS table, EMA alpha, BPB baseline) are
in a separate writable register file on Phi.

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module trinity_os_boot_rom #(
    parameter ROM_DEPTH = 512,   // 512 × 32-bit words = 2 KB
    parameter DIE_ID    = 2'b10  // default: Gamma (hosts the master copy)
) (
    input  wire         clk,
    input  wire         rst_n,
    // Instruction fetch port
    input  wire [8:0]   rom_addr,   // word address
    output wire [31:0]  rom_data,
    output wire         rom_valid,
    // Boot sequence status
    output wire         boot_done,
    output wire         lucas_post_pass,
    output wire         phi_anchor_ok,
    // Control to power coordinator
    output wire [2:0]   boot_workload_class,
    output wire         boot_workload_valid
);
endmodule
```

**Die assignment:** Gamma, 2 tiles.
**v1.0.0 dependencies:** Lucas POST module (existing v1.0.0); phi-anchor register.
**R-SI-1:** ROM is read-only combinational; no multiply.
**Test plan (Cocotb):**
1. Reset → boot sequence completes; `boot_done` asserts within 512 cycles.
2. `lucas_post_pass` asserts; `phi_anchor_ok` = 1 from cycle 1.
3. ROM word readout at all 512 addresses; no X propagation.
4. `boot_workload_class` = 0b000 (idle) on first valid DVFS output.
**Risk:** ROM content may require updates post-tapeout for field parameterisation.
**Mitigation:** Boot ROM is synthesis-time constant; parameters live in the separate writable
register file on Phi (reprogrammable via JTAG or I²C boot interface).

---

## 4. RTL Development Timeline

| Month    | Milestone                                                              | Primary modules   |
|----------|------------------------------------------------------------------------|-------------------|
| Jun 2026 | Mesh fabric foundation: DMA endpoint and ring router RTL + Cocotb unit tests | U1, U2       |
| Jul 2026 | Reliability layer: TMR voter + coherent cache MVP (MEI states)         | U3, U4            |
| Aug 2026 | Tokenomics acceleration: all 9 Tier-M modules RTL + unit tests         | M1–M9             |
| Sep 2026 | DVFS coordinator, ISA extension, boot ROM; submission window opens     | U5, U6, U7        |
| Oct 2026 | Cross-module integration sim, R-SI-1 full audit, gate-level test       | all modules       |
| Nov 15   | TTSKY26c submission deadline; final GDS push                           | —                 |

### Dependency graph

```
Jun: U1 ──►──────────────────────────────────────►──┐
Jun: U2 ──►── Jul: U3 ──►── Aug: M1,M7 (TMR path)  │
             Jul: U4 ──►── Sep: U7 (boot ROM init)   │
Jun: U1,U2 ──►── Sep: U6 (XCHIP decode final wiring)─┤
                  Sep: U5 (DVFS, depends on U6)       │
                           Oct: Integration ──►── Nov: submit
```

Critical path: U1 → U2 → U3 → M1 (proof engine needs TMR trigger); plan U3 completion by
end of July to leave 4 weeks of M1 validation before Aug freeze.

---

## 5. Verification Strategy

### 5.1 Unit tests (Cocotb, per-module)

Each module has a dedicated Cocotb testbench under `tests/cocotb/<module_name>/`.  Minimum
target: **≥ 90% line coverage** on every module, verified with `verilator --coverage` or equivalent.
Test scenarios for each module are listed in Section 2 above.

### 5.2 Cross-module integration test (Phi + Euler + Gamma simulated together)

A top-level SystemVerilog testbench instantiates all three dies with their U1/U2 endpoints
interconnected.  A random DMA stress test drives 10 000 random `{src, dst, len}` descriptors
across all three die pairs and verifies:
- In-order delivery with correct data payload.
- TMR voter agreement on 1 000 synthetic signing operations (sr25519 + BN254).
- DVFS coordinator settles within 5 workload transitions without deadlock.

### 5.3 Stuck-at fault injection for TMR voter (U3)

Cocotb scenarios inject single-stuck-at-0 and single-stuck-at-1 faults on each die's result
bus entering the voter.  Assertions verify:
- Voted result is always the majority (correct) value.
- `fault_die_id` identifies the injected die.
- Fault record written to `0x0003_F000` with correct `{timestamp, fault_die_id, op_class}`.

### 5.4 DVFS power-state simulation (U5)

A cycle-accurate power model (Cocotb + annotated switching activity) validates that the
DVFS coordinator drives the correct per-die power-state targets for each workload class,
and that `all_settled` deasserts correctly on peer-die timeout.

### 5.5 Coq formal verification — critical paths

Three modules are targeted for formal proof using Coq + a Verilog extraction pass:

| Module             | Property to verify                                           |
|--------------------|--------------------------------------------------------------|
| `champion_bpb_oracle` | `reported_bpb >= BPB_BASELINE → baseline_ok = 1` (always)  |
| `tmr_voter_circuit`   | Voter output = majority for all 3^2 = 9 input agreement patterns |
| `era_halving_counter` | `current_era` monotone non-decreasing; saturates at 8      |

Proofs will be committed alongside RTL under `formal/coq/`.

### 5.6 R-SI-1 lint enforcement via CI

A custom Verilator lint pass runs on every PR, grepping for standalone `*` operator tokens
outside of comments and string literals.  Any RTL file containing an unguarded `*` fails CI.
The lint script is at `scripts/rsi1_lint.sh`.  All 16 new modules in this roadmap are designed
from the outset to pass R-SI-1 without exceptions.

---

## 6. Risks and Mitigations

| Risk                               | Likelihood | Impact | Mitigation                                                                                                            |
|------------------------------------|------------|--------|-----------------------------------------------------------------------------------------------------------------------|
| Tile-budget overrun                | Medium     | High   | Fallback ordering: drop M8 (`conviction_ema_tracker`) first (pure optimisation, not safety-critical), then M3 (`chip_uptime_attestor`), then M9 (`sr25519_signer`) — defer to TTSKY27. Core U-tier and proof engine preserved in all scenarios. |
| MESI coherence complexity          | High       | Medium | Ship invalidate-only MEI in TTSKY26c; add Shared state and full MESI in TTSKY27. Correctness preserved; only read-sharing performance deferred. |
| Tape-out 2026-12-16 collision      | Low        | High   | If TTSKY26b yield analysis reveals critical errata requiring re-spin, TTSKY26c schedule pushes to accommodate. Sep–Nov submission window provides ~3-week buffer before hard tape-out. |
| PUF binding across dies            | Medium     | Medium | Cross-die PUF identity synthesis is a coordination challenge: each die's PUF ring oscillator is independent. Deferred to TTSKY27; TTSKY26c uses per-die PUF independently (no cross-die PUF binding in 26c). |
| BN254 pairing latency too high     | Medium     | Medium | Accept multi-cycle completion; `pair_done` signal gates MiningPool claim. Latency is additive to software path, not on the critical consensus path. |
| sr25519 key material side-channel  | Low        | High   | Private scalar transits ring encrypted; pipeline registers cleared after each signing; formal security analysis planned for TTSKY27. |
| Yuma matrix scratchpad overflow    | Medium     | Medium | Stream matrix in two passes; simulation validates convergence; fallback: reduce N_MINERS to 128 in TTSKY26c. |

---

## 7. Open Questions for PI Review

1. **sr25519 deploy targets** — Should `sr25519_signer.v` target Bittensor Subtensor signing only,
   or also sign EVM-compatible transactions (secp256k1 comparison path)?  The Ristretto255
   implementation is incompatible with secp256k1; a separate EVM signer would be an additional
   module.

2. **MockChipRegistry graduation** — Does MockChipRegistry stay on testnet for TTSKY26c
   evaluation, or is there a plan to graduate it to Bittensor mainnet before tape-out?  The
   answer affects whether `mining_proof_engine.v` needs to emit full mainnet-compatible ABI or
   can target a testnet-simplified format.

3. **BN254 full pairing assignment** — TTSKY26c ships a scoped BN254 pairing unit (Miller loop
   + final exponentiation, no batched MSM).  Full BN254 with batched multi-scalar multiplication
   is slated for TTSKY27.  Confirm this split is correct; if TTSKY26c needs full batched MSM,
   tile budget must be revisited (estimated +4 tiles on Euler, requiring M8/M9 deferral).

4. **Trinity OS boot ROM content freeze** — When does Trinity OS define a stable boot sequence
   that can be baked into `trinity_os_boot_rom.v`?  The RTL can be synthesised with a placeholder
   NOP sequence, but the actual boot ROM content must be frozen before GDS sign-off in November.

5. **Formal verification scope** — Should the Coq proofs be part of the TTSKY26c submission
   package, or are they a companion release on GitHub alongside the RTL?  The proofs are not
   required for GDS submission, but they strengthen the DARPA / defense pitch.

---

## 8. Preserved v1.0.0 Invariants

All existing v1.0.0 modules are **unchanged** in TTSKY26c.  The following invariants are non-negotiable
and enforced in CI:

| Invariant                         | Enforcement                                                         |
|-----------------------------------|---------------------------------------------------------------------|
| `tri_mant_mul` module interface   | No changes to port list or parameter names.                         |
| NF4 / Posit16 modules             | No changes; new modules depend on them but do not modify them.      |
| GF4 / GF16 / GF256 modules        | No changes.                                                         |
| Sacred opcode table (0x00–0x23)   | Preserved; XCHIP opcodes occupy 0x30–0x38, no overlap.             |
| Phi-anchor `0x47C0` on `{uio_out, uo_out}` (Theorem 36.1) | Asserted from cycle 0 of reset; `phi_anchor_ok` wire present in every Phi-resident new module. |
| R-SI-1 (zero standalone `*`)      | Enforced by CI lint script `scripts/rsi1_lint.sh` on all RTL files. |

---

## 9. File Manifest

All new modules will be committed under `rtl/ttsky26c/` in the following structure:

```
rtl/ttsky26c/
├── tier_m/
│   ├── mining_proof_engine.v
│   ├── era_halving_counter.v
│   ├── chip_uptime_attestor.v
│   ├── bn254_pairing_unit.v
│   ├── champion_bpb_oracle.v
│   ├── coptic_subunit_decoder.v
│   ├── yuma_consensus_accel.v
│   ├── conviction_ema_tracker.v
│   └── sr25519_signer.v
└── tier_u/
    ├── cross_die_dma_endpoint.v
    ├── trinity_ring_router.v
    ├── tmr_voter_circuit.v
    ├── coherent_cache_mesi.v
    ├── power_coordinator_dvfs.v
    ├── xchip_opcode_decoder.v
    └── trinity_os_boot_rom.v

tests/cocotb/
├── mining_proof_engine/
├── era_halving_counter/
├── chip_uptime_attestor/
├── bn254_pairing_unit/
├── champion_bpb_oracle/
├── coptic_subunit_decoder/
├── yuma_consensus_accel/
├── conviction_ema_tracker/
├── sr25519_signer/
├── cross_die_dma_endpoint/
├── trinity_ring_router/
├── tmr_voter_circuit/
├── coherent_cache_mesi/
├── power_coordinator_dvfs/
├── xchip_opcode_decoder/
├── trinity_os_boot_rom/
└── integration/
    └── tri_die_stress_test/

formal/coq/
├── champion_bpb_oracle_proof.v
├── tmr_voter_proof.v
└── era_halving_counter_proof.v

scripts/
└── rsi1_lint.sh
```

---

## 10. Honest Performance Projections

All performance figures below are **projected, pending tape-out 2026-12-16**.  Real silicon
numbers will be published on first silicon return from fab.

| Metric                                      | Projected value                         |
|---------------------------------------------|-----------------------------------------|
| Per-die ternary throughput                  | ~1 GOPS @ ~50 MHz @ ~1 W               |
| Aggregate Trinity triad throughput          | ~3 GOPS sustained (lower under TMR)    |
| Average system power (DVFS-coordinated)     | ~1.5 W                                 |
| Full TMR mode power                         | ~3.0 W                                 |
| Cross-die DMA latency (U1 + U2)             | ~60 ns per hop (3 hops × 20 ns)        |
| Unified address space                       | 512 KB                                  |
| BN254 pairing latency (M4, projected)       | <1 ms at 50 MHz (pending simulation)   |
| sr25519 signing latency (M9, projected)     | <2 ms at 50 MHz (pipelined ladder)     |
| Yuma Consensus scoring (M7, projected)      | <1 ms for 256-miner matrix at 50 MHz   |

---

## License

Copyright 2026 Dmitrii Vasilev <admin@t27.ai>

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
in compliance with the License.  You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License
is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
or implied.  See the License for the specific language governing permissions and limitations under
the License.

Sole author: Dmitrii Vasilev <admin@t27.ai>
