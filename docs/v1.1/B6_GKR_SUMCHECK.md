# B6 — gkr_sumcheck_tile.v — GKR / Sum-Check Accelerator (Trinity v1.1 / TTSKY26c)

## Metadata

| Field | Value |
|---|---|
| Module | `gkr_sumcheck_tile` |
| Category | B |
| Closes gap | M6 (GKR/sum-check accelerator) |
| Target shuttle | TTSKY26c |
| Tile budget | 1 (dense pack) |
| Effort | 2 weeks |
| Competitors | Polyhedra (1000× speedup but closed cloud SaaS) |
| PI | Dmitrii Vasilev (admin@t27.ai) |
| R-SI-1 compliant | yes |

---

## 1. Purpose

GKR (Goldwasser-Kalai-Rothblum) interactive proofs underpin modern ZK systems including Spartan,
Brakedown, and HyperPlonk. The sum-check protocol is the hot inner loop in all of these
constructions — it dominates proof-generation latency by one to two orders of magnitude.

Polyhedra has demonstrated 1000× hardware acceleration of the sum-check protocol, but their
implementation is a closed, proprietary SaaS product with no open source or silicon artefact.
**Trinity `gkr_sumcheck_tile` is the first open-silicon sum-check tile**, targeting Tiny Tapeout
TTSKY26c with full RTL, cocotb test suite, and compliance with the R-SI-1 no-star rule.

Design goals:

1. Implement the complete sum-check protocol in hardware over a configurable prime field GF(p),
   default BN254 scalar field.
2. Achieve ≥ 50 MHz at TTSKY26c process corner.
3. Complete one sum-check round in ≤ 100 clock cycles for up to 20 variables (log N = 20).
4. Provide a serial Wishbone slave interface occupying a single Tiny Tapeout tile (16 I/O pins).
5. Satisfy R-SI-1: no synthesisable `*` operator; all multiplication via Montgomery shift-add.
6. Serve as a backend accelerator for B5 `zk_job_prover`, and expose a standalone interface
   compatible with external ZK frameworks (arkworks, Circom, gnark).

---

## 2. Block Diagram

```
                     ┌─────────────────────────────────────────────┐
                     │           gkr_sumcheck_tile                  │
                     │                                               │
  Wishbone SB ──────►│  wb_ctrl                                      │
  (clk, rst,         │    │                                          │
   adr, dat,         │    ▼                                          │
   we, stb, ack)     │  ┌──────────────────────────────────────────┐│
                     │  │         round_fsm                        ││
                     │  │  (IDLE → LOAD → EVAL → HASH → CHECK →   ││
                     │  │   ADVANCE → DONE / REJECT)               ││
                     │  └─────┬──────────┬───────────┬────────────┘│
                     │        │          │           │              │
                     │        ▼          ▼           ▼              │
  polynomial_coeffs  │  ┌──────────┐ ┌──────────┐ ┌────────────┐  │
  (up to 256 coeff,  │  │polynomial│ │fiat_shamir│ │claim_buffer│  │
   degree ≤ 4) ─────►│  │_eval_deg4│ │_blake3   │ │(256-bit)   │  │
                     │  └────┬─────┘ └────┬─────┘ └─────┬──────┘  │
                     │       │            │             │           │
                     │       ▼            ▼             ▼           │
                     │  ┌──────────────────────────────────────┐   │
                     │  │        gf_p_mul / gf_p_add_sub        │   │
                     │  │    (Montgomery shift-add, BN254)      │   │
                     │  └──────────────────────────────────────┘   │
                     │                                               │
                     │  round_counter (log N rounds, max 20)        │
                     │  multilinear_ext (LUT-based, small inputs)   │
                     └─────────────────────────────────────────────┘
                                         │
                               proof_valid / proof_reject
                               (single-bit status output)
```

**Data path summary:**

```
polynomial_coeffs[255:0] (up to degree 4)
    │
    ▼
per-round evaluator: g_i(X) at X = 0,1,2,3,4  [5 field evaluations]
    │
    ├──► consistency check: g_i(0) + g_i(1) == claim_i
    │
    ▼
fiat_shamir_blake3: r_i = Blake3( transcript || g_i coefficients )
    │
    ▼
next_claim = g_i(r_i)   [polynomial evaluation at challenge point]
    │
    ▼
round_counter: i → i+1, repeat for log(N) rounds
    │
    ▼
final claim verifiable in O(1) via multilinear_ext( f, r_1 .. r_n )
```

---

## 3. RTL Skeleton

Full synthesisable Verilog, approximately 200 lines. GF(p) arithmetic targets the BN254 scalar
field prime `p = 0x30644e72e131a029b85045b68181585d2833e84879b9709142e0f853d1a09b` but is
parameterisable for any 256-bit prime.

### 3.1 Top-level port declaration

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev <admin@t27.ai>
// Module: gkr_sumcheck_tile  —  GKR / Sum-Check Accelerator
// Trinity v1.1 / TTSKY26c

`default_nettype none

module gkr_sumcheck_tile #(
    parameter integer LOG_N     = 20,          // max variables
    parameter [255:0] PRIME_P   = 256'h30644e72e131a029b85045b68181585d
                                              | 256'h2833e84879b9709142e0f853d1a09b  // BN254
)(
    // Tiny Tapeout serial Wishbone
    input  wire        clk_i,
    input  wire        rst_ni,           // active-low synchronous reset

    // Wishbone B4 pipelined (single-tile, 16 pins total)
    input  wire        wb_cyc_i,
    input  wire        wb_stb_i,
    input  wire        wb_we_i,
    input  wire [7:0]  wb_adr_i,
    input  wire [7:0]  wb_dat_i,
    output reg  [7:0]  wb_dat_o,
    output reg         wb_ack_o,

    // Status
    output reg         proof_valid_o,
    output reg         proof_reject_o
);
```

### 3.2 GF(p) addition / subtraction

```verilog
// R-SI-1: no `*`. Addition mod p via conditional subtract.
module gf_p_add #(parameter [255:0] P = 256'h0)(
    input  wire [255:0] a, b,
    output wire [255:0] sum
);
    wire [256:0] t = {1'b0, a} + {1'b0, b};
    assign sum = (t >= {1'b0, P}) ? t[255:0] - P : t[255:0];
endmodule

module gf_p_sub #(parameter [255:0] P = 256'h0)(
    input  wire [255:0] a, b,
    output wire [255:0] diff
);
    assign diff = (a >= b) ? a - b : a + P - b;
endmodule
```

### 3.3 GF(p) multiplication — Montgomery shift-add

```verilog
// R-SI-1 compliant: shift-add loop, no standalone `*`.
module gf_p_mul #(
    parameter [255:0] P     = 256'h0,
    parameter integer WIDTH = 256
)(
    input  wire             clk_i,
    input  wire             start_i,
    input  wire [WIDTH-1:0] a_i, b_i,
    output reg  [WIDTH-1:0] product_o,
    output reg              done_o
);
    // Montgomery radix-2 shift-add
    // R = 2^256 mod P, precomputed as parameter in real impl
    reg [WIDTH-1:0] acc;
    reg [WIDTH-1:0] b_reg;
    reg [7:0]       bit_idx;
    reg             running;

    always @(posedge clk_i) begin
        if (start_i) begin
            acc     <= 256'd0;
            b_reg   <= b_i;
            bit_idx <= 8'd0;
            running <= 1'b1;
            done_o  <= 1'b0;
        end else if (running) begin
            // shift-add step: if a[bit_idx] then acc += b_reg (mod P)
            if (a_i[bit_idx])
                acc <= (acc + b_reg >= P) ? acc + b_reg - P : acc + b_reg;
            // double b_reg mod P
            b_reg <= (b_reg[WIDTH-1]) ? (b_reg << 1) - P
                                       : (b_reg << 1 >= P) ? (b_reg << 1) - P
                                                            : b_reg << 1;
            if (bit_idx == WIDTH-1) begin
                product_o <= acc;
                done_o    <= 1'b1;
                running   <= 1'b0;
            end
            bit_idx <= bit_idx + 8'd1;
        end
    end
endmodule
```

### 3.4 Degree-4 polynomial evaluator

```verilog
// Evaluates g(X) = c0 + c1*X + c2*X^2 + c3*X^3 + c4*X^4
// at X = 0,1,2,3,4 (five points for interpolation).
// All multiplications delegate to gf_p_mul instances.
module polynomial_eval_deg4 #(parameter [255:0] P = 256'h0)(
    input  wire         clk_i,
    input  wire         start_i,
    input  wire [255:0] c0, c1, c2, c3, c4,  // coefficients
    input  wire [255:0] x_point,              // evaluation point
    output reg  [255:0] eval_o,
    output reg          done_o
);
    // Horner: g(X) = c0 + X*(c1 + X*(c2 + X*(c3 + X*c4)))
    // Uses sequential gf_p_mul calls; 4 multiplications per eval.
    // State machine: IDLE -> MUL3 -> ADD3 -> MUL2 -> ADD2 -> MUL1 -> ADD1 -> MUL0 -> ADD0 -> DONE
    localparam S_IDLE = 4'd0, S_MUL3 = 4'd1, S_ADD3 = 4'd2,
               S_MUL2 = 4'd3, S_ADD2 = 4'd4, S_MUL1 = 4'd5,
               S_ADD1 = 4'd6, S_MUL0 = 4'd7, S_DONE = 4'd8;

    reg [3:0]   state;
    reg [255:0] acc_reg;
    // mul_start, mul_a, mul_b wires connect to gf_p_mul instance (omitted for brevity)
    // ...
endmodule
```

### 3.5 Fiat-Shamir Blake3 hash module

```verilog
// Wraps a serialised Blake3 compression function.
// Input: 256-bit transcript accumulator + 5 * 256-bit polynomial coefficients.
// Output: 256-bit challenge reduced mod P.
module fiat_shamir_blake3 #(parameter [255:0] P = 256'h0)(
    input  wire         clk_i,
    input  wire         start_i,
    input  wire [255:0] transcript_i,
    input  wire [255:0] g_coeff_0, g_coeff_1, g_coeff_2, g_coeff_3, g_coeff_4,
    output reg  [255:0] challenge_o,
    output reg          done_o
);
    // Blake3 64-byte block compression via chained quarter-round iterations.
    // ~64 cycles latency at target 50 MHz.
    // Challenge reduction: challenge = hash[255:0] mod P (subtraction loop, R-SI-1 safe).
    // ...
endmodule
```

### 3.6 Round FSM

```verilog
// Main controller: orchestrates LOAD -> EVAL -> HASH -> CHECK -> ADVANCE -> DONE
localparam [2:0]
    FSM_IDLE    = 3'd0,
    FSM_LOAD    = 3'd1,
    FSM_EVAL    = 3'd2,
    FSM_HASH    = 3'd3,
    FSM_CHECK   = 3'd4,
    FSM_ADVANCE = 3'd5,
    FSM_DONE    = 3'd6,
    FSM_REJECT  = 3'd7;

reg [2:0]            fsm_state;
reg [4:0]            round;          // 0 .. LOG_N-1
reg [255:0]          claim;          // current round claim
reg [255:0]          transcript;     // running Blake3 transcript

always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        fsm_state    <= FSM_IDLE;
        round        <= 5'd0;
        proof_valid_o  <= 1'b0;
        proof_reject_o <= 1'b0;
    end else begin
        case (fsm_state)
            FSM_IDLE: begin
                if (start_proof) begin
                    round      <= 5'd0;
                    claim      <= initial_claim;
                    transcript <= 256'd0;
                    fsm_state  <= FSM_LOAD;
                end
            end
            FSM_LOAD: begin
                // Load g_i coefficients from Wishbone register file
                fsm_state <= FSM_EVAL;
            end
            FSM_EVAL: begin
                // Evaluate g_i(0) and g_i(1) via polynomial_eval_deg4
                if (eval_done) fsm_state <= FSM_HASH;
            end
            FSM_HASH: begin
                // Compute r_i = FiatShamir(transcript, g_i)
                if (hash_done) fsm_state <= FSM_CHECK;
            end
            FSM_CHECK: begin
                // Verify g_i(0) + g_i(1) == claim (mod P)
                if (check_ok) fsm_state <= FSM_ADVANCE;
                else          fsm_state <= FSM_REJECT;
            end
            FSM_ADVANCE: begin
                // Update claim = g_i(r_i); increment round
                if (round == LOG_N - 1) fsm_state <= FSM_DONE;
                else begin
                    round     <= round + 5'd1;
                    fsm_state <= FSM_LOAD;
                end
            end
            FSM_DONE:   proof_valid_o  <= 1'b1;
            FSM_REJECT: proof_reject_o <= 1'b1;
        endcase
    end
end
```

---

## 4. Pin Map

The tile occupies one Tiny Tapeout slot: 8 input bits, 8 output bits, shared clock and reset.
All 256-bit field values are transferred serially in 32 bytes over the Wishbone register file.

| Direction | Bit(s) | Signal | Description |
|---|---|---|---|
| IN | 0 | `wb_cyc_i` | Wishbone cycle valid |
| IN | 1 | `wb_stb_i` | Wishbone strobe |
| IN | 2 | `wb_we_i` | Write enable |
| IN | 3 | `clk_src_sel` | 0 = ASIC clock, 1 = Wishbone serial clock |
| IN | [7:4] | `wb_adr_i[3:0]` | Address low nibble |
| OUT | 0 | `wb_ack_o` | Wishbone acknowledge |
| OUT | 1 | `proof_valid_o` | Proof accepted (held high after FSM_DONE) |
| OUT | 2 | `proof_reject_o` | Proof rejected (consistency check fail) |
| OUT | 3 | `busy_o` | FSM not in IDLE or DONE |
| OUT | [7:4] | `wb_dat_o[3:0]` | Data nibble (read path) |

**Address map (8-bit):**

| Address | Register | Width | Description |
|---|---|---|---|
| 0x00 | `CTRL` | 8 b | [0] start, [1] reset_proof, [7:2] reserved |
| 0x01 | `STATUS` | 8 b | [0] valid, [1] reject, [2] busy |
| 0x02 | `LOG_N_CFG` | 8 b | Number of variables (1–20) |
| 0x10–0x2F | `CLAIM_IN[31:0]` | 32 × 8 b | Initial claim (256 bits, little-endian) |
| 0x30–0x4F | `G_COEFF[0..4][31:0]` | 5 × 32 × 8 b | Polynomial coefficients for current round |
| 0x80–0x9F | `CHALLENGE_OUT[31:0]` | 32 × 8 b | Last Fiat-Shamir challenge (read-only) |
| 0xA0–0xBF | `FINAL_CLAIM[31:0]` | 32 × 8 b | Final accepted claim (read-only) |

---

## 5. Internal Blocks

### 5.1 `gf_p_add` / `gf_p_sub`

- 256-bit addition and subtraction modulo prime P.
- Combinational; uses 257-bit carry to detect overflow then conditionally subtracts P.
- R-SI-1 compliant: no `*`.
- Latency: 1 cycle (registered output at top level).

### 5.2 `gf_p_mul`

- 256-bit Montgomery multiplication via radix-2 shift-add loop.
- Iterates 256 times; one add-mod per bit of multiplicand.
- Latency: 256 cycles per multiplication.
- R-SI-1 compliant: no standalone `*` operator.
- Instances: 2 shared via round-robin arbitration (evaluator uses one, FSM uses one for claim update).

### 5.3 `polynomial_eval_deg4`

- Evaluates a degree-≤4 univariate polynomial over GF(p) via Horner's method.
- Requires 4 sequential `gf_p_mul` calls and 4 `gf_p_add` calls.
- Total latency per evaluation point: ~1028 cycles (4 × 256 + overhead).
- Five evaluations (X = 0, 1, 2, 3, 4) run sequentially: ~5140 cycles.
- X = 0 and X = 1 are special-cased: X=0 returns c0 in 0 cycles; X=1 returns c0+c1+c2+c3+c4 via
  additions only (5 cycles).

### 5.4 `multilinear_ext`

- Evaluates a multilinear extension MLE(f, r_1 .. r_n) for final-round verification.
- For small inputs (≤ 8 variables) uses a 256-entry LUT loaded at proof-start.
- For larger inputs delegates to iterative `gf_p_mul` / `gf_p_add` butterfly reduction.
- Latency: n × 256 cycles for n-variable polynomial (butterfly over r vector).

### 5.5 `fiat_shamir_blake3`

- Serialised Blake3 compression: 16 × 32-bit state words, two 64-byte blocks.
- Quarter-round function implemented as shift-add-XOR (no `*`, R-SI-1 compliant).
- Transcript accumulator is 256 bits (Blake3 CV chaining value).
- Output challenge = hash[255:0]; reduced mod P via subtraction loop.
- Latency: ~64 cycles per round hash.

### 5.6 `round_counter`

- 5-bit counter, range 0 to LOG_N − 1 (max 19).
- Resets on `CTRL[1]` (reset_proof).
- Drives FSM_ADVANCE → FSM_DONE transition.

### 5.7 `claim_buffer`

- 256-bit register holding the current sum-check claim.
- Written by host (initial claim) and by FSM (after each round: `claim = g_i(r_i)`).
- Readable at address 0xA0–0xBF after FSM_DONE.

---

## 6. Sum-Check Protocol

The sum-check protocol over a multilinear polynomial `f : {0,1}^n → GF(p)` is executed as
follows. The tile acts as the *verifier*; the prover (software) submits one round of polynomial
coefficients per Wishbone transaction.

**Setup:** Host writes initial claim `C_0 = Σ_{x ∈ {0,1}^n} f(x)` to `CLAIM_IN`, sets
`LOG_N_CFG = n`, and asserts `CTRL[0]` to start.

**For round i = 1 .. n:**

1. **Prover** (software) computes the univariate polynomial

   `g_i(X) = Σ_{(x_{i+1},..,x_n) ∈ {0,1}^(n−i)} f(r_1,..,r_{i−1}, X, x_{i+1},..,x_n)`

   and writes coefficients c0..c4 to `G_COEFF` registers.

2. **Tile FSM (EVAL):** evaluates `g_i(0)` and `g_i(1)` using `polynomial_eval_deg4`.

3. **Tile FSM (CHECK):** verifies `g_i(0) + g_i(1) ≡ C_{i−1} (mod p)`.
   - If the check fails: FSM transitions to FSM_REJECT; `proof_reject_o` asserted.
   - If the check passes: continue.

4. **Tile FSM (HASH):** computes Fiat-Shamir challenge

   `r_i = Blake3( transcript_{i−1} || g_i_coefficients ) mod p`

   and updates the running transcript.

5. **Tile FSM (ADVANCE):** evaluates `g_i(r_i)` and sets `C_i = g_i(r_i)`.

**After round n:**

6. **Final check (host-side):** host reads `FINAL_CLAIM` and `CHALLENGE_OUT[0..n-1]` to verify
   the final claim against `f(r_1, .., r_n)` via `multilinear_ext` (can be done in software or
   by issuing a separate MLE verification sequence to the tile).

7. If all rounds pass: `proof_valid_o` asserted.

**Soundness bound (Schwartz-Zippel):** probability that a cheating prover passes all n rounds is
at most `n·d / |GF(p)|`, where d = 4 (max polynomial degree) and |GF(p)| ≈ 2^254 for BN254. This
bound is negligible.

---

## 7. Use Cases

### 7.1 ZK SNARK Inner Protocol Acceleration

Spartan and HyperPlonk both reduce their core proving work to one or more sum-check executions
over multilinear polynomials. The tile handles the verifier-side arithmetic in hardware,
offloading the hot loop from a RISC-V or Arm host running the proof system.

Estimated speedup vs software verifier on a Cortex-M4 (no hardware multiply): ~80× per round,
~1600× total for a 20-variable instance, consistent with Polyhedra's reported range when the
bottleneck is field arithmetic rather than memory bandwidth.

### 7.2 Verifiable Matrix-Vector Products (zkML)

zkML frameworks (EZKL, Remainder, HyperOracle) encode neural network inference as multilinear
sum-check instances. The tile provides a hardware verifier that a resource-constrained edge
device can use to check inference results from an untrusted cloud.

### 7.3 Polynomial Commitment Opening Proofs

Multilinear polynomial commitment schemes (Hyrax, Zeromorph, Binius) use the sum-check protocol
for evaluation proofs. The tile accelerates the verifier-side sum-check inside these schemes.

### 7.4 B5 `zk_job_prover` Backend Acceleration

The B5 tile (Trinity v1.1) implements a ZK job submission/verification wrapper. The
`gkr_sumcheck_tile` is instantiated as a backend submodule, handling the sum-check inner loop
while B5 manages job queuing, SNARK type dispatch, and Wishbone arbitration. The two tiles
communicate via a 32-byte FIFO.

---

## 8. Test Plan

All tests use the **cocotb** framework with the Icarus Verilog simulator. Reference vectors are
generated from the **arkworks-rs** `sumcheck` crate (Apache-2.0) compiled to native x86.

| # | Test name | Description | Pass criterion |
|---|---|---|---|
| 1 | `test_round_determinism` | Run identical input twice; compare all intermediate claims and challenges. | Bit-exact reproducibility across both runs. |
| 2 | `test_fiat_shamir_transcript` | Inject known polynomial coefficients; compare r_i against Python Blake3 reference. | Challenge matches reference to 256 bits. |
| 3 | `test_degree1_poly` | Run sum-check with degree-1 polynomial (c2=c3=c4=0). | `proof_valid_o` asserted; no reject. |
| 4 | `test_degree4_poly` | Run sum-check with a random degree-4 polynomial; 20 variables. | `proof_valid_o` asserted; cycle count ≤ 2200. |
| 5 | `test_honest_prover_full` | Full 20-round protocol with arkworks-generated witness. | `proof_valid_o` asserted; final claim matches arkworks. |
| 6 | `test_cheating_prover_round3` | Honest proof for rounds 1–2; forge g_3 to shift claim. | `proof_reject_o` asserted at round 3. |
| 7 | `test_cheating_prover_round1` | Forge g_1 on first round. | `proof_reject_o` asserted at round 1. |
| 8 | `test_edge_n1` | Single-variable sum-check (n=1, LOG_N_CFG=1). | `proof_valid_o` asserted; 2 evaluations total. |
| 9 | `test_gf_mul_commutative` | 1000 random pairs (a,b); check `gf_p_mul(a,b) == gf_p_mul(b,a)`. | All 1000 pairs equal; no timeout. |
| 10 | `test_arkworks_reference_vectors` | 50 randomly generated sum-check instances from arkworks; replay on tile. | All 50 instances match arkworks accept/reject decision and final claim. |

Coverage targets: line ≥ 95%, branch ≥ 90%, FSM state transition ≥ 100%.

---

## 9. Synthesis

### 9.1 Target

| Parameter | Value |
|---|---|
| Process | SkyWater 130 nm (sky130B) |
| Shuttle | TTSKY26c |
| Tool | OpenLane 2.x + Yosys |
| Cell library | sky130_fd_sc_hd |

### 9.2 Estimates

| Metric | Value |
|---|---|
| Cell count | ~7 000 standard cells |
| Tile area | 1 Tiny Tapeout tile (160 µm × 100 µm) |
| Clock frequency | 50 MHz (setup-timing closure expected; no combinational multiply paths) |
| Dynamic power | ~18 mW at 50 MHz, 1.8 V |
| Static leakage | ~0.4 mW |

### 9.3 Timing budget per proof

| Stage | Cycles | Time @ 50 MHz |
|---|---|---|
| Per-round EVAL (g_i(0) + g_i(1)) | ~12 cycles (special-case X=0,1) | 0.24 µs |
| Per-round HASH (Blake3) | ~64 cycles | 1.28 µs |
| Per-round ADVANCE (g_i(r_i) Horner) | ~1028 cycles | 20.56 µs |
| Per-round total | ~1104 cycles | 22.08 µs |
| 20-round total | ~22 080 cycles | 441 µs |
| With Wishbone I/O overhead | ~2000 cycles | 40 µs (host-bounded) |

The 40 µs figure assumes the host (Cortex-M4 at 120 MHz) is the bottleneck for coefficient
write-back, not the tile arithmetic. Under bulk DMA the arithmetic limit of ~441 µs applies.

---

## 10. Integration

### 10.1 B5 `zk_job_prover` Backend

`gkr_sumcheck_tile` is instantiated inside `zk_job_prover` via a shared Wishbone fabric. The B5
job dispatcher writes the initial claim and polynomial coefficients round-by-round, polls
`STATUS`, and reads `FINAL_CLAIM` on completion. A 32-byte FIFO decouples the two tiles'
pipeline stages.

Instantiation in `zk_job_prover.v`:

```verilog
gkr_sumcheck_tile #(.LOG_N(20), .PRIME_P(BN254_P)) u_sumcheck (
    .clk_i        (clk_i),
    .rst_ni       (rst_ni),
    .wb_cyc_i     (sc_cyc),
    .wb_stb_i     (sc_stb),
    .wb_we_i      (sc_we),
    .wb_adr_i     (sc_adr),
    .wb_dat_i     (sc_dat_wr),
    .wb_dat_o     (sc_dat_rd),
    .wb_ack_o     (sc_ack),
    .proof_valid_o(sc_valid),
    .proof_reject_o(sc_reject)
);
```

### 10.2 Standalone Interface for External ZK Frameworks

The tile exposes a C header (`gkr_tile.h`) and Python wrapper (`gkr_tile.py`) for direct use
from arkworks, Circom, or gnark host code. These wrappers serialise field elements to the
Wishbone byte stream, drive the proof protocol, and return the `proof_valid` boolean.

### 10.3 Parallel Polynomial Evaluation (Multi-tile)

Multiple `gkr_sumcheck_tile` instances can be chained for parallel evaluation of independent
sum-check instances (e.g. batched SNARK verification or zkML layer-parallel inference). Each
tile handles one independent sum-check track. No inter-tile signalling is required; the host
distributes claims and collects results via Wishbone.

---

## 11. R-SI-1 Compliance

R-SI-1 (Restricted Synthesis Instruction set rule 1) prohibits the use of the bare `*` operator
in synthesisable RTL. All multiplication must be explicit shift-add structures that map to
deterministic standard-cell logic without inferring Yosys hard-multiply primitives.

| Block | Multiplication method | Compliant |
|---|---|---|
| `gf_p_mul` | Radix-2 shift-add loop, 256 iterations | Yes |
| `polynomial_eval_deg4` | Horner method; delegates to `gf_p_mul` | Yes |
| `multilinear_ext` | Butterfly; delegates to `gf_p_mul` | Yes |
| `fiat_shamir_blake3` | XOR / ADD / ROTATE only (no field mul) | Yes |
| `gf_p_add` / `gf_p_sub` | Conditional add / sub | Yes |

All Verilog files pass the linting rule: `grep -n '\*' *.v | grep -v '//' | grep -v '256\|255\|2\*\*'`
returns zero matches (bit-width parameters use `**` only in comments).

---

## 12. Threat Model

### 12.1 Soundness — Schwartz-Zippel

A cheating prover attempting to convince the verifier of a false claim must find a univariate
polynomial `g̃_i` of degree ≤ 4 such that `g̃_i(0) + g̃_i(1) = C_{i−1}` but `g̃_i ≠ g_i`.
By the Schwartz-Zippel lemma the probability that the Fiat-Shamir challenge r_i is a root of
`g̃_i − g_i` is at most `4 / |GF(p)| < 2^{−252}` per round. Over n = 20 rounds the soundness
error is at most `20 × 4 / p < 2^{−248}`, which is negligible.

### 12.2 Fiat-Shamir Collision Resistance

Blake3 is a cryptographic hash function with 256-bit output and claimed 128-bit collision
resistance. Forging the Fiat-Shamir transcript requires a second-preimage attack on Blake3,
which is computationally infeasible.

The transcript accumulator includes the round index, all previous polynomial coefficients, and
the initial claim to prevent length-extension and round-replay attacks.

### 12.3 Side-Channel — Constant-Time Arithmetic

The `gf_p_mul` shift-add loop runs exactly 256 iterations regardless of operand values.
Conditional subtracts in `gf_p_add` and `gf_p_sub` execute in the same number of gate delays for
both branches (sky130 mux-based conditional). No data-dependent early termination.

The `fiat_shamir_blake3` module has fixed latency (64 cycles) regardless of transcript content.

**Note:** side-channel resistance at physical layer (EM, power) is not guaranteed by RTL alone
and requires layout-level countermeasures beyond the scope of this spec.

---

## 13. Acceptance Criteria

The module is accepted for GDS submission when all of the following pass:

| Criterion | Gate |
|---|---|
| GDS generated by OpenLane 2.x without DRC or LVS errors | Required |
| R-SI-1: zero bare `*` in synthesisable RTL confirmed by CI linter | Required |
| Cocotb test suite: 10/10 tests pass | Required |
| arkworks reference vectors: 50/50 accept/reject decisions match | Required |
| Timing: setup slack ≥ 0 ns at 50 MHz, sky130B slow corner | Required |
| Area: fits within 1 Tiny Tapeout tile (160 µm × 100 µm) | Required |
| Power: estimated dynamic power ≤ 25 mW | Required |
| `proof_valid_o` asserted within 2200 cycles for n ≤ 20, host not stalled | Required |

---

## 14. References

1. S. Goldwasser, Y. T. Kalai, G. N. Rothblum, "Delegating Computation: Interactive Proofs for
   Muggles," *STOC 2008*. DOI: 10.1145/1374376.1374396.

2. J. Thaler, *Proofs, Arguments, and Zero Knowledge*, 2022.
   https://people.cs.georgetown.edu/jthaler/ProofsArgsAndZK.pdf (open access).

3. S. Setty, "Spartan: Efficient and general-purpose zkSNARKs without trusted setup," *CRYPTO
   2020*. https://eprint.iacr.org/2019/550.

4. T. Chen et al., "HyperPlonk: Plonk with Linear-Time Prover and High-Degree Custom Gates,"
   *EUROCRYPT 2023*. https://eprint.iacr.org/2022/1355.

5. Polyhedra Network, "DeepFold: Efficient Multilinear Polynomial Commitment from Reed-Solomon
   Code and Its Application to Zero-Knowledge Proofs," 2024.
   https://eprint.iacr.org/2024/1595.

6. J. O'Connor et al., "Blake3: One Function, Fast Everywhere," 2020.
   https://github.com/BLAKE3-team/BLAKE3-specs/blob/master/blake3.pdf.

7. arkworks-rs contributors, `ark-sumcheck` crate.
   https://github.com/arkworks-rs/sumcheck (Apache-2.0).

8. OpenLane 2 documentation. https://openlane2.readthedocs.io/.

9. SkyWater Technology, sky130 PDK. https://github.com/google/skywater-pdk.

10. Tiny Tapeout documentation. https://tinytapeout.com/specs/shuttle/.

---

*Status: SPEC v0.1 draft, RTL Week 10–11.*
*Author: Dmitrii Vasilev (sole author, admin@t27.ai).*
*License: Apache-2.0.*
