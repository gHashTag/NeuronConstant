# Triple Modular Redundancy — Defense-Grade Reliability

**Author:** Dmitrii Vasilev <admin@t27.ai>
**Status:** Architecture spec for TTSKY26c reliability layer
**Parent:** [UNIFIED_COMPUTER_PARADIGM.md](./UNIFIED_COMPUTER_PARADIGM.md)

---

## 1. The Principle

A safety-critical instruction executes on **all three Trinity dies in parallel**, and the result is decided by **2-of-3 majority vote** at a dedicated voter cell. This is classical Triple Modular Redundancy (TMR), proven for decades in aerospace and defense electronics — applied here at the **silicon-package level**, not at board level.

Because Trinity already comprises three peer dies bound by a coherent fabric, TMR is **free in topology** — no extra dies, no extra packaging, only a small voter and a coordinated dispatch path.

---

## 2. Voter Cell — RTL

```verilog
// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
module tmr_voter #(
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] phi_result,
    input  wire [WIDTH-1:0] euler_result,
    input  wire [WIDTH-1:0] gamma_result,
    output wire [WIDTH-1:0] voted_result,
    output wire             agreement,        // all three agree
    output wire             chip_disagreed,   // at least one disagrees
    output wire [1:0]       fault_die_id     // 00 Phi, 01 Euler, 10 Gamma, 11 all-disagree
);
    wire pe = (phi_result   == euler_result);
    wire pg = (phi_result   == gamma_result);
    wire eg = (euler_result == gamma_result);

    assign voted_result   = pe ? phi_result   :
                            pg ? phi_result   :
                            eg ? euler_result :
                                 {WIDTH{1'b0}};   // all three disagree -> safe zero
    assign agreement      = pe & pg & eg;
    assign chip_disagreed = ~agreement;
    assign fault_die_id   = (~agreement & pe) ? 2'b10 :   // gamma is the odd one
                            (~agreement & pg) ? 2'b01 :   // euler is the odd one
                            (~agreement & eg) ? 2'b00 :   // phi is the odd one
                                                2'b11;
endmodule
```

Compliant with R-SI-1: zero standalone `*` operators.

---

## 3. What Runs Under TMR

TMR is **selective**, not blanket. Triple compute triples power; we only pay it where integrity matters.

| Operation class                                | TMR mandatory? | Notes                                                    |
|------------------------------------------------|----------------|----------------------------------------------------------|
| Cryptographic signing (DID, validator, attest) | **Yes**        | A single-die fault must never produce a signed artifact. |
| Champion BPB lock check at 2.2393              | **Yes**        | Baseline drift would corrupt the network's ground truth. |
| Phi-anchor `0x47C0` reaffirmation              | **Yes**        | Theorem 36.1 compliance is non-negotiable.               |
| MiningPool reward eligibility decision         | **Yes**        | On-chain economic effects.                                |
| Yuma Consensus validator scoring               | **Yes**        | Bittensor subnet integrity.                              |
| Routine AI inference (ternary MAC)             | No (default)   | Performance-critical; one-die compute suffices.          |
| Storage proof verification                     | Optional       | TMR on demand for high-value claims.                     |
| ZK proof generation                            | No             | Already cryptographically self-verifying.                |

Toggle via the `XCHIP_TRIPLE_SIGN` opcode (`0x37`) — single cycle, dispatches an instruction to all three dies, gates the result on `agreement = 1`.

---

## 4. Power Cost

Per [UNIFIED_COMPUTER_PARADIGM.md](./UNIFIED_COMPUTER_PARADIGM.md) §8:

- **Selective TMR** average draw: ~1.5 W system (operations are short, three-way activation is intermittent).
- **Full TMR mode** (every cycle on all three dies): ~3.0 W. Used only for sustained defense-grade operations.

DARPA / Anduril / aerospace customers care more about correctness under radiation than about idle power — for them, full-TMR mode is the headline feature.

---

## 5. Fault Reporting

When `chip_disagreed = 1`, the voter writes a fault record to the **shared coherent buffer** at `0x0003_F000`:

```
struct trinity_fault_record {
    uint32_t timestamp;
    uint32_t phi_result;
    uint32_t euler_result;
    uint32_t gamma_result;
    uint8_t  fault_die_id;       // 00/01/10/11
    uint8_t  op_class;
    uint16_t sequence;
};
```

Trinity OS (see paradigm doc §12) drains this buffer, attributes the fault, and may:
- Down-rank the disagreeing die in the next scheduling window.
- Emit a `tmr_fault` Bittensor metric for subnet validators.
- Trigger a re-execution under full TMR for confirmation.

---

## 6. Use-Case Narratives

### 6.1 DARPA Radiation-Hardened Edge Compute
Standard rad-hard silicon costs $1k–$10k per die at low volume. A Trinity Triad provides functional rad-hardness via TMR using **commodity 130 nm SkyWater silicon at ~$1.5k per triad**. The cost asymmetry is the pitch.

### 6.2 Anduril Defense-Grade Inference
Edge AI on weapons platforms must produce auditable, verifiable inference under electromagnetic and radiation stress. Trinity's TMR voter + ZK proof from Euler delivers both: integrity (TMR) and verifiability (ZK).

### 6.3 Bittensor Validator Scoring
A Yuma Consensus validator running on a Trinity Triad scores miners with **2-of-3 attestation**, eliminating single-validator gaming and reducing subnet variance. See [docs/sales/BITTENSOR_PITCH.md](../sales/BITTENSOR_PITCH.md).

### 6.4 Crypto Signing for High-Value Wallets
Hardware wallets currently rely on one secure element. A Trinity-backed signer requires 2-of-3 agreement across physically distinct dies — a fault injection on any single die fails the signature.

---

## 7. Verification Plan

1. **Voter unit tests** — exhaustive over 3-way input combinations for `WIDTH = 8, 32, 64`.
2. **Stuck-at fault injection** — Cocotb scenarios that force one die's output to a fixed value and assert the voter routes around it.
3. **Power harness** — measure full-TMR vs single-die cycle counts on the SKY26c gate-level netlist.
4. **R-SI-1 audit** — confirm no `*` operators in the voter or its dispatch logic.

---

## 8. Tile Budget for TTSKY26c

| Module                          | Tiles | Die    |
|---------------------------------|-------|--------|
| `tmr_voter` (32-bit + 64-bit)   | 2     | Gamma  |
| TMR dispatch / op-class decoder | 1     | Phi    |
| TMR fault buffer interface      | 1     | Gamma  |
| **TMR layer total**             | **4** |        |

Combined with the tri-ring fabric (10 tiles) and unified-cache controller (16 tiles), the **Unified Computer enablement layer** fits in roughly **30 tiles distributed across the triad**, consistent with §11 of the paradigm doc.

---

## 9. Honest Limits

- TMR cannot defeat a coordinated multi-die attack with shared design flaws. We mitigate via **physical PUF divergence**: each die contributes uncorrelated entropy.
- TMR triples leakage power during long sustained operations. We mitigate via **selective application**.
- A voter is itself a single point of failure. We mitigate via **distributed redundant voters** — every die hosts a voter and uses majority-of-voters as a meta-check (planned for TTSKY27).

---

## License

Apache-2.0. Sole author: Dmitrii Vasilev <admin@t27.ai>.
