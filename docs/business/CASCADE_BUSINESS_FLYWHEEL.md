**Author:** Dmitrii Vasilev <admin@t27.ai>
**Status:** Draft v1.0 — pending tape-out 2026-12-16
**Date:** 2025-07-15
**License:** Apache-2.0
**DOI:** 10.5281/zenodo.19227877

---

# Trinity Network — Cascade Business Flywheel

## Companion Docs

- [UNIFIED_COMPUTER_PARADIGM.md](../architecture/UNIFIED_COMPUTER_PARADIGM.md) — One Computer architectural axiom
- [BUSINESS_MODEL_V1.md](./BUSINESS_MODEL_V1.md) — Revenue model and unit economics
- [GTM_FOUR_WEDGES.md](./GTM_FOUR_WEDGES.md) — Go-to-market channels
- [COMPETITIVE_LANDSCAPE.md](./COMPETITIVE_LANDSCAPE.md) — Seven defensive moats

---

## 1. Overview

A flywheel is a self-reinforcing loop where each rotation adds momentum to the next. Trinity's business flywheel has five core links. When all links are operational, the loop compounds. When one link is weak, the flywheel stalls until that link is strengthened.

The architectural foundation is immovable: Trinity is ONE distributed computer (Phi + Euler + Gamma), bound by 2-of-3 attestation. Every link in the flywheel ultimately traces back to this hardware design choice. See [UNIFIED_COMPUTER_PARADIGM.md](../architecture/UNIFIED_COMPUTER_PARADIGM.md).

---

## 2. The Flywheel Loop

```
     +----------------------------------------------------------+
     |                                                          |
     v                                                          |
[L1] More Triads Sold                                          |
     |                                                          |
     | Each Triad contains one complete Trinity Computer         |
     | (Phi + Euler + Gamma + tri-ring fabric).                  |
     | Each purchase registers one Trinity DID on-chain.         |
     v                                                          |
[L2] Larger Network of Attested Miners                         |
     |                                                          |
     | More attested miners = higher total network ZK proof      |
     | throughput. Each proof expands the verifiable inference   |
     | capacity of the Trinity Network.                          |
     v                                                          |
[L3] Higher TRI Utility (Inference Fee Demand + Burn)         |
     |                                                          |
     | More verifiable inference capacity attracts inference     |
     | buyers. More inference transactions = more TRI fee burn.  |
     | Burn reduces circulating supply. (Subject to TRI having  |
     | positive market value — see cold-start risk below.)       |
     v                                                          |
[L4] Higher Hardware Demand                                    |
     |                                                          |
     | Higher TRI utility (burn + mining yields) increases the  |
     | expected return on Triad hardware investment. More buyers |
     | calculate that a Triad pays for itself in TRI earned.     |
     v                                                          |
[L5] More Triads Sold  ----------------------------------------+
```

The loop is self-reinforcing in both directions: a positive shock at any link propagates around the ring and amplifies. A negative shock at any link propagates similarly.

---

## 3. Three Strongest Reinforcing Links

### L1 → L2: Triad Sale to Attested Miner

**Why this link is strong:**

The transition from "Triad sold" to "attested miner live" is structurally enforced. A purchased Triad, when connected and powered, runs Lucas POST (Phi), passes boot attestation, and automatically registers a Trinity DID through `BittensorSubnetAttest.sol`. There is no optional step; the attestation is built into the TrinityNode daemon's initialization sequence.

This means every Triad sold converts mechanically to an attested miner — the conversion rate is close to 100% (accounting only for dead-on-arrival hardware). No other network link has a comparable conversion rate.

**KPI:** Attested DIDs on-chain / Triads shipped. Target: >= 90%.

**Risk:** Low. The only failure mode is hardware defects (yield risk, addressed in [RISK_MITIGATION_MATRIX.md](./RISK_MITIGATION_MATRIX.md), R1).

---

### L2 → L3: Attested Miners to TRI Utility

**Why this link is strong:**

Each attested miner submits ZK proofs (Euler GKR sumcheck) to the network. Each accepted proof is a verifiable inference unit — it represents real compute capacity that inference buyers can purchase. As the count of attested miners grows, the total verifiable inference throughput of the Trinity Network grows proportionally.

The structural mechanism: the mining pool (`MiningPool.sol`) rewards proofs. Inference buyers pay TRI for verified inference slots. A percentage of TRI paid burns. The burn is on-chain and irreversible; it does not require human decision. The link from "more miners" to "more inference supply" to "more burn" is algorithmic.

**KPI:** Monthly TRI burned / Monthly TRI mined. Target: > 1% (net deflationary pressure begins). Target date: Q4 2027 (mainnet operational).

**Risk:** Medium. This link requires inference buyers to exist and to pay in TRI. Without demand for verifiable inference, TRI fee burn is zero regardless of mining supply.

---

### L4 → L1: Hardware Demand to Triad Sales

**Why this link is strong:**

The Triad mining boost (4× vs Solo 1×) creates a direct, quantifiable economic incentive for hardware buyers. A miner calculating expected TRI yield must purchase a Triad to access 4× return, and the calculation is transparent (all parameters are on-chain). This is not a speculative narrative; it is arithmetic.

Additionally, the mining boost does not decay at the Triad tier — the 4× applies to every era's reward equally, including post-halving epochs. A Triad owner's relative economic advantage over a Solo owner is preserved across halvings.

**KPI:** Triad units sold / Solo units sold. Target: >= 2:1 ratio (Triads outnumber Solos in sales volume).

**Risk:** Low in economics; medium in execution. The risk is that TRI has no market value, making the 4× boost a 4× multiple of zero. This is the cold-start risk (L3 → L4 link weakness, described below).

---

## 4. Two Weakest Links (Cold-Start Risks)

### L3 → L4: TRI Utility to Hardware Demand (WEAKEST LINK)

**Why this link is weak:**

This is the cold-start problem. Hardware demand for mining depends on the expected return on hardware investment. Expected return depends on TRI market value. TRI market value depends on network utility. Network utility depends on inference buyers using the network. Inference buyers depend on there being enough supply (attested miners) to make the network reliable. Enough attested miners depend on hardware demand.

The loop is circular. Somewhere in this circle, a first-mover must purchase hardware before TRI has proven value. This is the bootstrapping problem that every proof-of-work network has faced. Bitcoin solved it by having Satoshi Nakamoto mine the genesis block alone; the narrative value of a perfectly fair launch attracted others. Trinity's 0% pre-mine is the same bet.

**Mitigation (see [RISK_MITIGATION_MATRIX.md](./RISK_MITIGATION_MATRIX.md), R2):**

1. **Calibrated Era 0 reward:** 1000 TRI per proof is high in absolute terms at Era 0. Early miners earn a disproportionate share of supply relative to later epochs. This is by design — it rewards first movers.
2. **Bittensor bootstrap (W1 wedge):** The Bittensor community already has active miners who understand the economic structure of halving-based mining. They do not need TRI to have existing market value; they entered Bittensor the same way.
3. **Hardware intrinsic value:** The Triad is a useful computer independent of TRI price. Defense customers (Wedge 2) buy Triads for TMR + attestation, not for TRI mining. This creates non-speculative demand that seeds the network.

**KPI:** Hardware units sold before TRI mainnet (demand-pull evidence). Target: >= 100 Triads sold to defense / enterprise buyers before TRI mainnet (Q3 2027 projected).

---

### L2 → L3: Inference Buyer Demand (SECOND WEAKEST LINK)

**Why this link is weak:**

Even with a large network of attested miners, inference fee burn only occurs if external buyers pay TRI for verified inference. The verifiable inference market (AI outputs with cryptographic compute provenance) is nascent. There are no established buyers paying for ZK-attested inference today. Trinity must create this buyer demand, not capture existing demand.

This link is weaker than L1→L2 or L4→L1 because it requires behavioral change in AI infrastructure buyers — not just a hardware purchase decision.

**Mitigation:**

1. **AI researcher segment (Wedge 4):** Academic AI researchers who need reproducible compute provenance are the most natural early adopters. They are not paying commercial inference prices; they are paying for the ZK receipt. The price of the receipt (in TRI) can be set very low initially.
2. **Defense-grade provenance (Wedge 2):** Defense contracts that require auditable AI inference are not price-sensitive on TRI. They pay for compliance, not speculation. This is demand that is structurally independent of TRI market price.
3. **Bittensor subnet routing (Wedge 1):** If Bittensor subnets require Trinity DID attestation, inference requests routed through those subnets automatically pay TRI fees. This creates inference buyer demand as a consequence of subnet governance, not market formation.

**KPI:** Monthly verifiable inference requests processed on-chain. Target: >= 10,000 by Q4 2027 (mainnet operational). This represents approximately 10 requests/hour — a minimal but provable signal.

---

## 5. Link-by-Link KPI Summary

| Link   | Description                              | Measurement                                | Target (Q4 2027)       | Risk Level |
|--------|------------------------------------------|--------------------------------------------|------------------------|------------|
| L1→L2  | Triad sale → attested miner registration | DIDs on-chain / Triads shipped             | >= 90%                 | Low        |
| L2→L3  | Attested miners → inference demand + burn | Monthly TRI burned / Monthly TRI mined    | > 1% net burn rate     | Medium     |
| L3→L4  | TRI utility → hardware demand            | Triad units sold pre-mainnet               | >= 100 defense/enterprise | High (cold-start) |
| L4→L1  | Hardware demand → Triad SKU selection    | Triad units / Solo units sold ratio        | >= 2:1                 | Low-Medium |
| L1-L5 (cycle) | Full flywheel cycle speed         | Months per flywheel revolution (T sold → T utility evidenced) | < 18 months | Overall |

---

## 6. Flywheel Accelerators and Decelerators

### Accelerators

| Accelerator                                | Link accelerated | Mechanism                                          |
|--------------------------------------------|------------------|----------------------------------------------------|
| DARPA BAA award                            | L3→L4            | Government demand validates TRI-independent hardware value |
| Bittensor subnet mandating Trinity DID     | L2→L3            | Creates captive inference buyer demand in Bittensor ecosystem |
| TRI listing on a major exchange            | L3→L4            | Price discovery enables miner ROI calculation      |
| Second tape-out (TTSKY26c) success         | L1→L2            | Increases Triad supply, reducing wait time for miners |
| High-profile AI researcher paper using Trinity | L2→L3       | Creates demand signal for ZK-attested inference      |

### Decelerators

| Decelerator                                | Link affected    | Mechanism                                          |
|--------------------------------------------|------------------|----------------------------------------------------|
| Tape-out delay beyond 2026-12-16           | L1→L2 (stall)   | No hardware = no miners = no flywheel motion        |
| TRI adverse regulatory classification      | L3→L4            | Miners cannot legally hold/trade TRI; kills ROI case |
| Bittensor governance rejection of Trinity DID | L2→L3         | No captive inference demand from largest bootstrap channel |
| Yield failure at IHP                       | L1→L2 (partial) | Too few Triads shipped to reach critical mass       |
| Competitor copies RTL + matches PUF       | L4→L1           | Hardware moat erodes (low probability; see Moat 1) |

---

## 7. Critical Mass Threshold (Projected)

Based on the flywheel structure, the Trinity Network requires a minimum number of active attested Triads to sustain self-reinforcing growth:

- **Minimum viable network:** ~100 attested Triads across >= 3 geographic regions, with at least one subnet (Bittensor SN3, SN39, or SN81) accepting Trinity DID attestation as a validator tier.
- **Self-sustaining flywheel threshold (projected):** ~500 attested Triads, >= 1,000 monthly inference requests, >= 0.5% monthly TRI burn rate.

These thresholds are estimated, not modeled. They will be calibrated against actual mainnet data when available.

---

*Apache-2.0. Sole author: Dmitrii Vasilev <admin@t27.ai>.*
