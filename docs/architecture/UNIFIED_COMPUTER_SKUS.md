# Trinity Computer — Product SKUs and Sales Narrative

**Author:** Dmitrii Vasilev <admin@t27.ai>
**Status:** Sales narrative / pricing skeleton
**Parent:** [UNIFIED_COMPUTER_PARADIGM.md](./UNIFIED_COMPUTER_PARADIGM.md)
**Companion sales material:** [docs/sales/](../sales/)

---

## 1. Narrative Shift — Old vs New

| Old framing                                  | New framing                                                |
|----------------------------------------------|------------------------------------------------------------|
| "Trinity makes three chips."                 | "Trinity is one computer with three organs."               |
| "Phi $99, Euler $499, Gamma $999"            | "Trinity Triad $1499 — everything included."               |
| "AI accelerator for use case X."             | "Verifiable AI computer with built-in trust."              |
| "Compete with NVIDIA on TFLOPS."             | "New category — Trust Hardware."                           |
| "Three SKUs (one per die)."                  | "Five SKUs by capability tier (Solo / Duo / Triad / Cluster / Datacenter)." |

The shift is not branding cosmetics — it follows directly from the architecture: the three dies are functional units of one computer, not independent products.

---

## 2. SKU Ladder

| SKU                       | Composition                                  | Price (USD) | Primary buyer                                   |
|---------------------------|----------------------------------------------|-------------|--------------------------------------------------|
| **Trinity Solo**          | Phi only (1×1)                               | $99         | IoT, identity tokens, DID provisioning           |
| **Trinity Duo**           | Phi + Euler (1×1 + 8×2)                      | $499        | DePIN node, light validator                      |
| **Trinity Triad** *flagship* | Phi + Euler + Gamma + tri-ring fabric    | $1,499      | Full validator, AI inference, defense edge       |
| **Trinity Cluster**       | 3× Triads (= 9 dies)                         | $4,999      | Subnet operator, regional infra                   |
| **Trinity Datacenter**    | 27× Triads (= 81 dies, = `3^4`)              | $39,999     | Enterprise, DARPA, defense contractor            |

Each SKU is shipped as **one Trinity Computer**. Customers do not select dies individually.

### Pricing logic
- **Triad** is priced lower than the naive sum (`$99 + $499 + $999 = $1,597`) by ~6% to anchor the bundle as the default purchase.
- **Cluster** carries a ~10% bulk discount over 3× Triad ($1499 × 3 = $4,497 → $4,999 includes mounting + interconnect).
- **Datacenter** ships in a `3^3` triadic arrangement honoring the sacred-mathematics principle, with full Trinity OS preinstalled.

---

## 3. Why Customers Pay More for a Triad Than for Three Parts

The Triad price ($1,499) appears to be a small premium over the sum of cheapest possible per-die acquisition. The premium pays for:

1. **Pre-bonded interconnect** — tri-ring fabric routed and tested at factory.
2. **Boot-time attestation** — the three dies share one PUF-derived identity at first power-on.
3. **Trinity OS preinstalled** — kernel + HAL + scheduler tuned for cross-die latency.
4. **Mining bonus eligibility** — see §5; a registered Triad mines at 4× the per-die rate.
5. **Warranty as a unit** — if any one die fails inside a Triad, the unit is replaced; not user-debuggable at the die boundary.

A customer who buys three dies separately gets **three chips**. A customer who buys a Triad gets **a computer**. The former cannot mint a unified Trinity DID. The latter can.

---

## 4. Buyer Persona Mapping

| SKU         | Persona                              | Pain solved                                              |
|-------------|--------------------------------------|----------------------------------------------------------|
| Solo        | IoT / identity-token engineer        | Need a low-cost provable identity primitive.             |
| Duo         | DePIN miner, hobbyist validator      | Want to participate in Trinity emission with modest CapEx. |
| Triad       | Bittensor validator, AI integrator   | Need verifiable inference and a full-strength validator.  |
| Cluster     | Regional subnet operator             | Want to run multiple validator slots with one purchase.   |
| Datacenter  | DARPA, Anduril, defense contractor   | Need rad-hardened edge compute with attested compute path. |

See companion sales decks:
- [docs/sales/DARPA_I2O_BAA_PROPOSAL.md](../sales/DARPA_I2O_BAA_PROPOSAL.md)
- [docs/sales/DEFENCE_CONTRACTOR_PITCH.md](../sales/DEFENCE_CONTRACTOR_PITCH.md)
- [docs/sales/BITTENSOR_PITCH.md](../sales/BITTENSOR_PITCH.md)
- [docs/sales/HELIUM_INTEGRATION_PROPOSAL.md](../sales/HELIUM_INTEGRATION_PROPOSAL.md)
- [docs/sales/GENSYN_IO_NET_IP_LICENSE.md](../sales/GENSYN_IO_NET_IP_LICENSE.md)

---

## 5. Tokenomics Coupling — Triad Mining Boost

Trinity's emission schedule is fixed at total supply `3^27 = 7,625,597,484,987 TRI`, 0% pre-mine, 100% mineable. The **shape of the boost** is a function of how many organs a miner runs:

| Configuration             | Reward multiplier | Rationale                                                          |
|---------------------------|-------------------|--------------------------------------------------------------------|
| Solo (Phi only)           | 1×                | Identity work — lowest compute contribution.                       |
| Duo (Phi + Euler)         | 2×                | Linear scaling — proof generation added.                           |
| Triad (full Trinity)      | 4×                | TMR-attested compute path; full Trinity DID.                       |
| Cluster (3 Triads)        | 12× (3× linear)   | Linear in Triad count.                                              |
| Datacenter (27 Triads)    | ~100× (sqrt-ish)  | Bulk operator, sublinear to prevent centralization.                 |

The Triad multiplier exceeds linear scaling **only at the Triad boundary** — this is the incentive that makes a buyer choose the bundle over three parts. The Cluster multiplier returns to linear; the Datacenter multiplier sublinearizes via a square-root law to discourage extreme concentration.

This boost structure is enforced on-chain by `MiningPool.sol` reading the Trinity DID attestation from `BittensorSubnetAttest.sol`, which can only mint a Triad-level DID when 2-of-3 attestation succeeds.

---

## 6. Tagline Set

Short-form, in order of recommended use:

- **"One Trinity. Three minds. Mathematical truth."**
- "Verifiable compute. By construction."
- "The Bitcoin moment for ternary AI silicon."
- "Trust at the substrate level."
- "Identity. Reasoning. Action. Bound by 2-of-3."

For Russian-speaking customers:
- **"Одна Trinity. Три ума. Математическая истина."**

---

## 7. Roadmap Anchors

| Tape-out / quarter | Deliverable for customers                                                   |
|--------------------|------------------------------------------------------------------------------|
| TTSKY26b (now)     | Phi / Euler / Gamma silicon submitted; dev kits Q1 2027.                     |
| TTSKY26c (Sep–Nov 2026) | Tri-ring fabric, TMR voter, Trinity OS bootstrap. **Triad shippable.**  |
| TTSKY27 (2027)     | Cluster bridges, BN254 pairing, production-fab path. **Cluster / DC shippable.** |
| 2028+              | Mesh-of-meshes scaling to `3^4 = 81` dies per Datacenter rack.               |

Tape-out target for the underlying silicon: **2026-12-16**.

---

## 8. Competitive Positioning One-Pager

```
NVIDIA   — TFLOPS at any cost. No silicon-level trust.
Helium   — Geographic incentives, no compute attestation.
Bittensor— Validator economics, no rad-hard hardware path.
TPU/AWS  — Closed silicon, no public RTL, no verifiable compute.

Trinity  — Open RTL, verifiable compute, ternary substrate,
           2-of-3 attestation at the silicon-package level.
           One computer. Three organs. Mathematical truth.
```

---

## License

Apache-2.0. Sole author: Dmitrii Vasilev <admin@t27.ai>.
