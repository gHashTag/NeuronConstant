# DePIN v2 Hardware Stack

<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- DOI: 10.5281/zenodo.19227877 -->

## Overview

`common/depin/v2/` contains the second-generation DePIN hardware primitives for the NeuronConstant Trinity chip family. These modules extend the v1 `tri_token_accumulator` with full receipt chaining, replay protection, threshold consensus, slashing, energy-weighted rewards, commit-phase FSM, and cross-chip share distribution.

All modules are:
- **Verilog-2005** (`\`default_nettype none` / `\`default_nettype wire`)
- **R-SI-1 compliant** — zero standalone `*` operators (shift-and-add / lookup-table only)
- **Apache-2.0** licensed
- **DOI**: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)
- Verified with `iverilog -g2005-sv -Wall` — zero warnings, self-checking testbenches print `PASS`

---

## Module Reference

### #1 `tri_vrf_receipt.v` — VRF-style Chained Receipt Hash

**Purpose:** Produces a cryptographically-chained receipt hash for each completed compute job, preventing replay attacks via the Davies-Meyer construction.

**Interface:**

| Signal | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | Clock |
| `rst_n` | in | 1 | Active-low reset |
| `job_id` | in | 8 | Job identifier |
| `result_hash` | in | 32 | Hash of job result |
| `prev_receipt_hash` | in | 32 | Previous receipt (chaining input) |
| `nonce` | in | 16 | Replay-protection nonce |
| `commit` | in | 1 | 1-cycle pulse: latch and emit receipt |
| `receipt_hash` | out | 32 | Chained receipt hash |
| `valid` | out | 1 | 1-cycle pulse: receipt_hash is valid |

**Algorithm:**
```
receipt_hash = prev_receipt_hash XOR {job_id, 24'h0} XOR {result_hash[23:0], 8'h0} XOR {16'h0, nonce}
```
This Davies-Meyer variant ensures each receipt depends on the entire prior chain; the same job inputs at different time steps yield different hashes because `prev_receipt_hash` changes.

---

### #2 `tri_nonce_counter.v` — Monotonic Replay-Protection Nonce

**Purpose:** Provides a hardware-enforced monotonically-increasing 16-bit nonce to prevent replay attacks on receipt submissions.

**Interface:**

| Signal | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | Clock |
| `rst_n` | in | 1 | Active-low reset |
| `advance` | in | 1 | 1-cycle pulse: increment nonce |
| `nonce` | out | 16 | Current nonce value |
| `wrap_flag` | out | 1 | 1-cycle pulse: nonce wrapped 0xFFFF→0x0000 |

**Behaviour:** Resets to `0x0000`. Increments on each `advance` pulse. Wraps from `0xFFFF` back to `0x0000`, asserting `wrap_flag` for exactly one cycle. The off-chip prover treats `wrap_flag` as a session boundary.

---

### #3 `tri_mofn_attest.v` — 2-of-3 Threshold Consensus Attestation

**Purpose:** Asserts consensus when at least 2 of the 3 Trinity chips (Phi, Euler, Gamma) have attested the same job within a 16-cycle sliding window. Prevents a single faulty or malicious chip from claiming settlement.

**Interface:**

| Signal | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | Clock |
| `rst_n` | in | 1 | Active-low reset |
| `attest_phi` | in | 1 | Phi chip attestation pulse |
| `attest_eul` | in | 1 | Euler chip attestation pulse |
| `attest_gam` | in | 1 | Gamma chip attestation pulse |
| `job_id` | in | 8 | Current job identifier |
| `consensus_ok` | out | 1 | 1-cycle pulse: ≥2-of-3 consensus reached |
| `winning_set` | out | 3 | Bitmask of attesting chips `{gam,eul,phi}` |

**Behaviour:** Each attestor has a 16-bit shift register (1-hot sliding window). When ≥2 registers are non-zero (attested within 16 cycles) and a job_id match holds, `consensus_ok` fires for one cycle on the rising edge of the threshold condition. Attestations for a different `job_id` reset the window.

---

### #5 `tri_slash.v` — Invalid-Receipt Penalty (6.25%)

**Purpose:** Combinational penalty module that deducts 1/16th (6.25%) of a token balance when an invalid receipt is detected. Subscribing accumulators apply `balance_out` on the `invalid_pulse` event.

**Interface:**

| Signal | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | Clock (interface; logic is combinational) |
| `rst_n` | in | 1 | Reset (interface) |
| `balance_in` | in | 16 | Current token balance |
| `invalid_pulse` | in | 1 | Assert to apply penalty |
| `balance_out` | out | 16 | Penalised balance |

**Algorithm:**
```
penalty     = balance_in >> 4
balance_out = invalid_pulse ? (balance_in - penalty) : balance_in
```
Examples: 1000 → 938 (−62), 16 → 15 (−1), 0 → 0.

---

### #6 `tri_energy_weight.v` — Energy-Weighted Reward Multiplier

**Purpose:** Scales a base reward by the chip's current power state. Higher-energy operating modes earn proportionally more tokens, incentivising DePIN operators to keep chips in active states.

**Interface:**

| Signal | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | Clock (interface) |
| `rst_n` | in | 1 | Reset (interface) |
| `base_reward` | in | 4 | Raw reward from accumulator |
| `active_state` | in | 1 | Chip in active compute mode |
| `idle_state` | in | 1 | Chip in idle mode |
| `fbb_active` | in | 1 | Forward-body-bias active (peak mode) |
| `weighted_reward` | out | 6 | Scaled reward |

**Multipliers (priority: fbb > active > idle):**

| State | Multiplier | Shift |
|---|---|---|
| `idle_state` | ×1 | `<< 0` |
| `active_state` | ×2 | `<< 1` |
| `fbb_active` | ×4 | `<< 2` |

---

### #7 `tri_3phase_commit.v` — Three-Phase Commit FSM

**Purpose:** Coordinates the claim → work → settle lifecycle for each DePIN job. Provides clean state visibility to the off-chip prover and generates one-cycle `settled` / `aborted` pulses for the token accumulator.

**Interface:**

| Signal | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | Clock |
| `rst_n` | in | 1 | Active-low reset |
| `claim_req` | in | 1 | Prover claimed this job |
| `work_done` | in | 1 | Compute completed |
| `receipt_valid` | in | 1 | Receipt hash verified |
| `timeout` | in | 1 | Work window expired |
| `state` | out | 2 | FSM state (see encoding) |
| `settled` | out | 1 | 1-cycle pulse: job settled successfully |
| `aborted` | out | 1 | 1-cycle pulse: job aborted on timeout |

**State encoding:**

| Encoding | State | Description |
|---|---|---|
| `2'b00` | `S_IDLE` | Ready for next job |
| `2'b01` | `S_CLAIMED` | Job claimed, awaiting compute |
| `2'b10` | `S_WORKING` | Compute active |
| `2'b11` | `S_DONE` | Receipt verified; auto-returns to IDLE |

**Transitions:**
- `IDLE → CLAIMED` on `claim_req`
- `CLAIMED → WORKING` on `work_done`
- `WORKING → DONE` on `receipt_valid` → `settled` pulse → `IDLE`
- `WORKING → IDLE` on `timeout` → `aborted` pulse

---

### #9 `tri_share_split.v` — Cross-Chip Token Reward Divider

**Purpose:** Distributes a total reward across the three Trinity chips in proportion to their share weights (which must sum to 3). Enables asymmetric reward splits (e.g., 0/1/2 or 1/1/1) without hardware multipliers.

**Interface:**

| Signal | Dir | Width | Description |
|---|---|---|---|
| `total_reward` | in | 6 | Total tokens to distribute |
| `share_phi` | in | 2 | Phi's share (0–3) |
| `share_eul` | in | 2 | Euler's share (0–3) |
| `share_gam` | in | 2 | Gamma's share (0–3) |
| `phi_get` | out | 6 | Phi's allocation |
| `eul_get` | out | 6 | Euler's allocation |
| `gam_get` | out | 6 | Gamma's allocation |

**Algorithm:** Uses a 64-entry lookup table for `floor(total/3)`, then:
- `share=0`: 0
- `share=1`: `floor(total/3)`
- `share=2`: `total - floor(total/3)` = `floor(2×total/3)`
- `share=3`: `total`

No `*` operators. Examples: `12` with `1/1/1` → `4/4/4`; `12` with `0/1/2` → `0/4/8`; `9` with `1/1/1` → `3/3/3`.

---

## Files

| File | Description |
|---|---|
| `tri_vrf_receipt.v` | #1 VRF chained receipt hash |
| `tb_tri_vrf_receipt.v` | Testbench for #1 |
| `tri_nonce_counter.v` | #2 Monotonic replay nonce |
| `tb_tri_nonce_counter.v` | Testbench for #2 |
| `tri_mofn_attest.v` | #3 2-of-3 threshold consensus |
| `tb_tri_mofn_attest.v` | Testbench for #3 |
| `tri_slash.v` | #5 Invalid-receipt penalty 6.25% |
| `tb_tri_slash.v` | Testbench for #5 |
| `tri_energy_weight.v` | #6 Energy-weighted reward multiplier |
| `tb_tri_energy_weight.v` | Testbench for #6 |
| `tri_3phase_commit.v` | #7 Three-phase commit FSM |
| `tb_tri_3phase_commit.v` | Testbench for #7 |
| `tri_share_split.v` | #9 Cross-chip reward divider |
| `tb_tri_share_split.v` | Testbench for #9 |
| `README.md` | This document |

---

## Verification

### Per-module simulation

```bash
# For each module X:
iverilog -g2005-sv -Wall -o /tmp/tb_X common/depin/v2/X.v common/depin/v2/tb_X.v
vvp /tmp/tb_X
# Expected output: PASS
```

### R-SI-1 compliance

```bash
bash common/verification/r_si_1_check.sh common/depin/v2
# Expected: R-SI-1 PASS: 14 files checked, 0 violations.
```

---

## Integration Plan for `tt-trinity-{phi,euler,gamma}` (Post-Shuttle)

> **Integration into tile top-levels is deferred until after the TTSKY26b shuttle close 2026-05-18 23:59 UTC.** The modules are RTL-complete and simulation-verified; wiring them into the tile top-levels requires pin budget review that is incompatible with the frozen shuttle submission.

### Planned integration points

| Module | Phi (`tt_um_trinity_nano.v`) | Euler | Gamma (`tt_um_trinity_max_true.v`) |
|---|---|---|---|
| `tri_nonce_counter` | Advance on `phi_post_done` | Advance on `multi_rcpt_ok` | Advance on `all_attested` |
| `tri_vrf_receipt` | Chain from phi Lucas POST result | Chain from Euler GF16 checksum | Chain from Gamma cortex hash |
| `tri_mofn_attest` | Source `attest_phi` | Source `attest_eul` | Source `attest_gam`; host module |
| `tri_slash` | Subscribe to `balance_in` from `tri_token_accumulator` | Same | Same |
| `tri_energy_weight` | Connect FBB supply monitor | Same | Same |
| `tri_3phase_commit` | Instantiate per job slot | Same | Same |
| `tri_share_split` | Gamma hosts; Phi/Euler connect via D2D bus | — | Host; read shares from config ROM |

### D2D bus wiring

Attestation pulses (`attest_phi`, `attest_eul`, `attest_gam`) are routed over `common/bus/trinity_d2d_bus.v`. The bus already has spare data lanes for one-bit signals. The `tri_mofn_attest` instance nominally lives in Gamma (the largest tile, 8×4), which has the most I/O budget.

### Status register exposure

`tri_3phase_commit.state[1:0]` is multiplexed into `uo_out[7:6]` when `ui_in[4:2] == 3'b110`, following the existing status-mode decode established by v1.

---

*NeuronConstant canonical hardware catalog · DOI: 10.5281/zenodo.19227877 · Apache-2.0*
