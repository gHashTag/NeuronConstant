# 02 — Emission Curve: 36-Year Halving Schedule with 9 Halvings

**Author:** Dmitrii Vasilev \<admin@t27.ai\>  
**Document version:** 1.0  
**Date:** 2025  
**Series:** Triton (TRI) Tokenomics — Paper 02 of N

---

## Table of Contents

1. [Why a Halving Emission Curve](#1-why-a-halving-emission-curve)
2. [Complete Era Table: 10 Eras, 9 Halvings](#2-complete-era-table-10-eras-9-halvings)
3. [Mathematical Convergence to 7.625 Trillion TRI](#3-mathematical-convergence-to-7625-trillion-tri)
4. [Why 4-Year Halving Periods](#4-why-4-year-halving-periods)
5. [Era 0 Economics: 2026–2030](#5-era-0-economics-20262030)
6. [Per-Chip Miner Economics in Era 0](#6-per-chip-miner-economics-in-era-0)
7. [Price Scenarios for Chip Operators](#7-price-scenarios-for-chip-operators)
8. [Why Exactly 9 Halvings: Ternary Field Alignment GF(3^k)](#8-why-exactly-9-halvings-ternary-field-alignment-gf3k)
9. [Asymptotic Tail and Permanently Locked Supply](#9-asymptotic-tail-and-permanently-locked-supply)
10. [Comparison with Bitcoin, Ethereum, and Bittensor](#10-comparison-with-bitcoin-ethereum-and-bittensor)
11. [Reference Appendix: Block-by-Block Mathematics](#11-reference-appendix-block-by-block-mathematics)

---

## 1. Why a Halving Emission Curve

### 1.1 The Core Argument

Token emission governs how a cryptocurrency enters circulation over time. The simplest schedules — fixed perpetual issuance (like early Ethereum) or a one-time mint — either create perpetual inflation or front-load value to early insiders. A halving schedule threads the needle between these extremes: it starts generously enough to incentivize early miners, then decays geometrically toward a hard cap, aligning long-term incentives for all participants.

Triton (TRI) adopts a halving schedule derived from Bitcoin's design philosophy but adapted to its own proving mechanism, ternary algebraic structure, and 36-year time horizon. The emission curve is not an arbitrary parameter; it is derived from the protocol's cryptographic foundations (see Section 8).

### 1.2 Three Core Goals

**Goal 1 — Deflationary issuance.** New supply should never outpace adoption and demand growth. A schedule that halves every four years ensures the rate of new supply entering circulation falls monotonically, matching the natural maturation trajectory of any protocol that grows from niche to infrastructure.

**Goal 2 — Durable miner incentive.** Miners (in TRI's case, ZK-proof operators) require economic incentive not only at genesis but across decades. Era 0's 1,000 TRI per proof is calibrated to be commercially attractive even at low TRI prices. Later eras rely on price appreciation to sustain miner revenue, which creates a self-reinforcing dynamic: continued mining sustains network security, which sustains protocol value, which sustains miner revenue.

**Goal 3 — Predictable supply.** Participants — miners, developers, investors, protocol integrators — must be able to compute, at any point in time, exactly how much TRI exists and how much remains to be issued. The halving schedule provides this certainty. There are no governance votes to change the emission rate, no difficulty-bomb circumventions, no treasury discretion over issuance.

### 1.3 Bitcoin-Derived Lineage

Bitcoin's halving curve is the most battle-tested emission model in existence: 15+ years of operation, multiple halving events, and consistent miner participation across orders-of-magnitude price changes. TRI borrows the core structural insight — each epoch releases exactly half the remaining pre-allocated supply — while departing from Bitcoin in three ways:

1. **Mechanism:** TRI rewards ZK proofs over a distributed proving network rather than proof-of-work hash computation.
2. **Duration:** 9 halvings over 36 years versus Bitcoin's 33 halvings over ~130 years.
3. **Residual:** TRI permanently locks ~0.098% of supply after Era 9 rather than asymptoting to zero at effectively infinite time.

The shorter, sharper schedule reflects the reality that ZK-proving hardware has a faster maturation cycle than ASIC mining hardware, and that the protocol's primary value — verifiable computation — is intended to be commercially dominant within a 20-year window, not a 100-year one.

### 1.4 Deflationary vs. Disinflationary

Technically, the halving schedule is *disinflationary* during active emission (the annual inflation rate falls over time) and deflationary after Era 9 (total supply is capped, and any burned or lost tokens reduce circulating supply permanently). This is the same classification that applies to Bitcoin. The distinction matters for economic modeling: a hard cap does not guarantee deflation in circulation if tokens are not burned or lost, but it does guarantee that no further inflation is possible from new issuance.

---

## 2. Complete Era Table: 10 Eras, 9 Halvings

Each "Era" spans exactly 4 years. There are 10 Eras (Era 0 through Era 9), connected by 9 halving events at years 4, 8, 12, 16, 20, 24, 28, 32, and 36.

**Total Supply:** 7,625,597,484,987 TRI = 3^27

### 2.1 Full Emission Table

| Era | Period    | Reward (TRI/proof) | Supply Released (TRI)  | Cumulative Supply (TRI) | Cumulative % |
|-----|-----------|--------------------|------------------------|--------------------------|--------------|
| 0   | 2026–2030 | 1,000.000000       | 3,812,798,742,494      | 3,812,798,742,494        | 50.0000%     |
| 1   | 2030–2034 | 500.000000         | 1,906,399,371,247      | 5,719,198,113,740        | 75.0000%     |
| 2   | 2034–2038 | 250.000000         | 953,199,685,623        | 6,672,397,799,364        | 87.5000%     |
| 3   | 2038–2042 | 125.000000         | 476,599,842,812        | 7,148,997,642,175        | 93.7500%     |
| 4   | 2042–2046 | 62.500000          | 238,299,921,406        | 7,387,297,563,581        | 96.8750%     |
| 5   | 2046–2050 | 31.250000          | 119,149,960,703        | 7,506,447,524,284        | 98.4375%     |
| 6   | 2050–2054 | 15.625000          | 59,574,980,351         | 7,566,022,504,636        | 99.2188%     |
| 7   | 2054–2058 | 7.812500           | 29,787,490,176         | 7,595,809,994,811        | 99.6094%     |
| 8   | 2058–2062 | 3.906250           | 14,893,745,088         | 7,610,703,739,899        | 99.8047%     |
| 9   | 2062–2066 | 1.953125           | 7,446,872,544          | 7,618,150,612,443        | 99.9023%     |

**Permanently locked after Era 9:** 7,446,872,544 TRI (0.0977% of total supply)

### 2.2 Emission Notes

- **Rounding:** Each era's supply is exactly `3^27 / 2^(k+1)` for Era k. Because 3^27 is odd and not divisible by 2^10, the last bit of precision distributes across eras as integer rounding. The table above uses ceiling on Era 0 and floors throughout, preserving the total.
- **Proofs per era:** Every era issues exactly 3,812,798,742 proofs regardless of era. The reward per proof changes, but the total proof count per era is invariant: `(3^27 / 2^(k+1)) / (1000 / 2^k) = 3^27 / 2000`, fixed across all eras.
- **Halving events occur at year boundaries:** 2030, 2034, 2038, 2042, 2046, 2050, 2054, 2058, 2062. The final emission concludes in 2066.

### 2.3 Annual Inflation Rate by Era

| Era | New Supply as % of Circulating at Start of Era |
|-----|------------------------------------------------|
| 0   | — (genesis; no prior circulating supply)       |
| 1   | 50.00% over 4 years ≈ 10.67% annualized        |
| 2   | 16.67% over 4 years ≈ 3.93% annualized         |
| 3   | 7.14% over 4 years ≈ 1.74% annualized          |
| 4   | 3.23% over 4 years ≈ 0.80% annualized          |
| 5   | 1.59% over 4 years ≈ 0.40% annualized          |
| 6   | 0.79% over 4 years ≈ 0.20% annualized          |
| 7   | 0.39% over 4 years ≈ 0.10% annualized          |
| 8   | 0.20% over 4 years ≈ 0.05% annualized          |
| 9   | 0.10% over 4 years ≈ 0.02% annualized          |

By Era 5 (2046–2050), annualized issuance falls below 0.4%, entering the range of what monetary economists typically classify as "sound money" territory (comparable to gold's approximately 1.7% annual production-to-stock ratio, which itself falls over time).

---

## 3. Mathematical Convergence to 7.625 Trillion TRI

### 3.1 Geometric Series Derivation

Let S = 3^27 = 7,625,597,484,987 (total supply).

The supply released in Era k (for k = 0, 1, …, 9) is:

```
supply(k) = S / 2^(k+1)
```

The sum of all 10 eras is a finite geometric series:

```
∑(k=0 to 9) S / 2^(k+1)
  = S · ∑(k=0 to 9) (1/2)^(k+1)
  = S · (1/2) · ∑(j=0 to 9) (1/2)^j
  = S · (1/2) · (1 - (1/2)^10) / (1 - 1/2)
  = S · (1 - 1/1024)
  = S · (1023/1024)
```

Substituting S = 7,625,597,484,987:

```
Total mined = 7,625,597,484,987 × 1023/1024
            = 7,618,150,612,443 TRI
```

Permanently locked remainder:

```
Locked = S - Total mined
       = 7,625,597,484,987 × (1/1024)
       = 7,446,872,543.93 ≈ 7,446,872,544 TRI
```

### 3.2 Infinite Series Interpretation

The halving schedule is the 10-term truncation of the infinite geometric series:

```
S · ∑(k=0 to ∞) (1/2)^(k+1) = S · 1 = S
```

The infinite series converges exactly to total supply. TRI stops after 10 terms (9 halvings), locking the tail. This is a deliberate design choice: the series does not need to run forever because the final-era reward of 1.953125 TRI/proof reaches a precision floor that is economically impractical to subdivide further given the ternary structure of the protocol.

### 3.3 Why 3^27?

The total supply is not an arbitrary number. It is the 27th power of 3:

```
3^27 = 7,625,597,484,987
```

This choice is derived from the ternary algebraic structure of Triton's ZK proof system. The proving circuit operates over fields of characteristic 3; the 27th power corresponds to the product of field sizes GF(3^1) through GF(3^9) inclusive:

```
∏(k=1 to 9) 3^k = 3^(1+2+3+...+9) = 3^45
```

Note: while the product of GF(3^k) sizes for k=1..9 is 3^45, the supply is pinned to 3^27 = (3^9)^3, reflecting the cube of the maximal single-field size in the proving schedule. The three-level nesting — three ternary levels — encodes the triadic symmetry central to the protocol's algebraic design.

### 3.4 Precision and Integer Arithmetic

All reward computations in the Triton protocol use integer arithmetic in units of the smallest denomination. TRI has 6 decimal places:

```
1 TRI = 1,000,000 micro-TRI (μTRI)
```

The smallest reward in Era 9 is:

```
1.953125 TRI = 1,953,125 μTRI
```

This value is exactly representable in binary (1.953125 = 125/64 = 2^−6 × 125), so all era rewards from 1000 down to 1.953125 are exact binary fractions, eliminating rounding error in on-chain reward computation.

---

## 4. Why 4-Year Halving Periods

### 4.1 Network Maturity Cycles

Four years is the canonical "generation" for distributed network infrastructure for several converging reasons:

**Hardware refresh cycles.** ZK-proving hardware (custom ASICs, FPGAs, and GPU clusters purpose-built for proof generation) has a commercial lifecycle of approximately 3–5 years. A 4-year era means each major hardware generation experiences one full era before the reward halves. Miners can amortize capital expenditure over the era, model ROI with known reward schedules, and plan hardware refresh on the halving boundary.

**Protocol upgrade cycles.** Major cryptographic protocol upgrades — new proof systems, circuit optimizations, verifier contract changes — have historically occurred on 2–4 year cycles across comparable ZK infrastructure projects. The 4-year halving boundary creates a natural coordination point for major protocol upgrades that might change proof efficiency.

**Market adoption cycles.** Enterprise and institutional adoption of new cryptographic infrastructure typically follows a 4–5 year arc from early-adopter trial to mainstream deployment. Each era's reward schedule is calibrated to incentivize the miner cohort relevant to that adoption stage: early adopters in Era 0 (high reward, high risk), growth-phase operators in Eras 1–3, mature infrastructure operators in Eras 4–6, and maintenance-tier operators in Eras 7–9.

### 4.2 Bitcoin's Precedent

Bitcoin's 4-year halving cycle (210,000 blocks × 10 minutes ≈ 4 years) was not arbitrary. Satoshi Nakamoto's design reflected an intuition about economic cycles and the time required for a new monetary network to gain sufficient adoption to sustain security without block reward. This intuition has been empirically validated across four halving events (2012, 2016, 2020, 2024). TRI inherits this empirical validation.

### 4.3 Deviation Analysis

**Why not 2-year halvings?** Too aggressive. A 2-year schedule would compress 9 halvings into 18 years (ending 2044), leaving 22 years of zero new issuance. This front-loads too much supply to early miners and creates an extremely rapid transition from high-reward to low-reward regimes that would destabilize miner economics.

**Why not 8-year halvings?** Too slow. An 8-year schedule extends emission to 2098 — 72 years. Hardware generations would span two eras, diluting the incentive signal that halvings provide. The economic urgency created by an upcoming halving (proven by Bitcoin's "halving cycle" price dynamics) diminishes at longer intervals.

**Why not variable periods?** Variable halving periods (tied to proof count, like Bitcoin's difficulty adjustment) would couple the emission schedule to network participation in a way that creates circular incentives. Fixed calendar periods allow independent modeling of miner ROI, protocol adoption forecasts, and treasury planning.

### 4.4 Relationship to Ternary Field Levels

The 4-year period also has a ternary interpretation. The Triton proving schedule is organized around 9 field levels GF(3^1) through GF(3^9). There are 9 halvings. Each halving transitions the network from one field-level regime to the next. The 4-year cadence was chosen so that the entire emission schedule spans 36 years = 4 × 9, a product that decomposes as 4 × 3^2 — maintaining a ternary structure in the temporal dimension.

---

## 5. Era 0 Economics: 2026–2030

### 5.1 Overview

Era 0 is the genesis era. It releases exactly 50% of total supply — 3,812,798,742,494 TRI — over four years (2026–2030) at a reward of 1,000 TRI per ZK proof submitted and verified on-chain.

The launch of Era 0 marks the transition from Triton's testnet and proving-key generation phase to mainnet operation. From block 0, every valid ZK proof earns 1,000 TRI, credited to the proof submitter's wallet.

### 5.2 Target Proof Rate

The Era 0 supply of 3,812,798,742,494 TRI must be distributed across the era's duration:

```
Era 0 duration: 4 years × 365.25 days/year = 1,461 days

Required daily proof rate (to fill era):
  3,812,798,742,494 TRI ÷ 1,000 TRI/proof ÷ 1,461 days
  = 2,609,719 proofs/day
  ≈ 2.61 million proofs/day
```

At 2,611 proofs per chip per day (the design throughput of the reference Triton proving chip), this requires:

```
2,609,719 proofs/day ÷ 2,611 proofs/chip/day ≈ 999,509 chips
```

The network design target is therefore approximately **1,000 active proving chips** operating throughout Era 0. This is the Era 0 network capacity parameter.

### 5.3 Network Capacity at Scale

A 1,000-chip proving network operating at reference throughput produces:

| Metric                    | Value                       |
|---------------------------|-----------------------------|
| Chips                     | 1,000                       |
| Proofs/chip/day           | 2,611                       |
| Proofs/day (network)      | 2,611,000                   |
| TRI/day (network)         | 2,611,000,000 (2.611B TRI)  |
| TRI/year (network)        | ~953.8B TRI                 |
| Days to exhaust Era 0     | ~1,460 days ≈ 4.00 years    |

The near-perfect alignment between Era 0 duration (1,461 days) and the proof rate required to exhaust Era 0 supply (~1,460 days at 1,000 chips) is intentional. The Era 0 reward was set to 1,000 TRI/proof specifically so that a 1,000-chip reference network fills the era at exactly its rated throughput.

### 5.4 Proof-of-ZK: What Counts as a Valid Proof

A "ZK proof" in the Triton context is a zero-knowledge succinct non-interactive argument (zkSNARK or zkSTARK, depending on the proving circuit version) that attests to a valid computation over the ternary field GF(3^k) specified by the current era. Era 0 uses GF(3^1) — the simplest ternary arithmetic circuit. Each proof requires:

1. A well-formed circuit input (witness) satisfying the Era 0 constraint system.
2. A valid proof string verifiable by the on-chain verifier contract.
3. A unique nullifier preventing replay of the same computation.

The on-chain verifier runs in O(log n) in proof size, making verification cheap relative to proving. Proof generation is the computational bottleneck and the source of economic value.

### 5.5 Era 0 Total Supply Distribution

```
Era 0 supply:      3,812,798,742,494 TRI
  = 50.0000% of total supply
  = 3.8128 trillion TRI

At Era 0 end (2030):
  Circulating:     3,812,798,742,494 TRI
  Yet to be mined: 3,812,798,742,493 TRI (eras 1–9 + locked)
```

The protocol enters Era 1 (2030) with exactly half its supply in circulation.

---

## 6. Per-Chip Miner Economics in Era 0

### 6.1 Reference Chip Specifications

The Triton reference proving chip is designed around the following throughput characteristics:

| Parameter                     | Value         |
|-------------------------------|---------------|
| Proofs per chip per day       | 2,611         |
| Proofs per chip per hour      | ~108.8        |
| Proofs per chip per second    | ~0.03022      |
| TRI earned per chip per day   | 2,611,000     |
| TRI earned per chip per year  | ~953,665,150  |

The 2,611 proofs/day figure is the design throughput of the reference chip at Era 0's GF(3^1) circuit. Circuit complexity scales across eras: Era 1 uses GF(3^2), Era 2 uses GF(3^3), and so on (see Section 8). Higher GF levels require more computation per proof, but the reward halving is calibrated to maintain approximately constant chip utilization economics across eras when adjusted for hardware improvements.

### 6.2 Daily and Annual Revenue per Chip (Era 0)

Revenue per chip depends on TRI price:

| TRI Price  | TRI/chip/day | USD/chip/day | USD/chip/year  |
|------------|--------------|--------------|----------------|
| $0.0001    | 2,611,000    | $261.10      | $95,367        |
| $0.001     | 2,611,000    | $2,611.00    | $953,668       |
| $0.010     | 2,611,000    | $26,110.00   | $9,536,678     |

### 6.3 Network of 1,000 Chips: Daily Aggregate

| TRI Price  | TRI/day (1,000 chips) | USD/day       | USD/year      |
|------------|------------------------|---------------|---------------|
| $0.0001    | 2,611,000,000          | $261,100      | $95,367,150   |
| $0.001     | 2,611,000,000          | $2,611,000    | $953,671,500  |
| $0.010     | 2,611,000,000          | $26,110,000   | $9,536,715,000 |

### 6.4 Economic Logic

The economics follow a clean scaling law:

- At $0.0001/TRI, a single chip generates ~$261/day. This is the **minimum viable price** at which operating a reference chip breaks even against reasonable power, colocation, and amortized hardware costs (assuming chip cost ~$50,000–$100,000 and a 2-year payback target).
- At $0.001/TRI, per-chip daily revenue ($2,611) covers hardware amortization and operating costs with substantial margin. This is the **commercially attractive** price threshold for large-scale operators.
- At $0.010/TRI, per-chip annual revenue exceeds $9.5M, comparable to top-tier ASIC mining farms per unit in peak Bitcoin cycles. This price level would attract institutional-scale capital.

The halving in Era 1 (reward: 500 TRI/proof) halves per-chip TRI revenue. For miner economics to remain constant in USD terms, the TRI price must approximately double between Era 0 and Era 1. This is the fundamental economic pressure mechanism of the halving schedule: each halving resets the economic relationship between miners and the market, incentivizing price discovery and adoption.

### 6.5 Miner Revenue Across Eras

Assuming constant USD revenue (price doubles each halving cycle — illustrative, not a forecast):

| Era | Reward/proof | TRI/chip/day | Required price for $261/day/chip |
|-----|--------------|--------------|----------------------------------|
| 0   | 1,000.000    | 2,611,000    | $0.0001000                       |
| 1   | 500.000      | 1,305,500    | $0.0002000                       |
| 2   | 250.000      | 652,750      | $0.0004000                       |
| 3   | 125.000      | 326,375      | $0.0008000                       |
| 4   | 62.500       | 163,188      | $0.0016000                       |
| 5   | 31.250       | 81,594       | $0.0032000                       |
| 6   | 15.625       | 40,797       | $0.0064000                       |
| 7   | 7.8125       | 20,398       | $0.0128000                       |
| 8   | 3.90625      | 10,199       | $0.0256000                       |
| 9   | 1.953125     | 5,100        | $0.0512000                       |

The constant-USD scenario would require TRI to reach ~$0.05/token by Era 9 (2062) to sustain the same per-chip dollar revenue as Era 0 at $0.0001/TRI. For reference, Bitcoin's price increased by more than 10^6× between its genesis block and 2024. A 512× increase over 40 years would require far more modest adoption.

---

## 7. Price Scenarios for Chip Operators

### 7.1 Scenario Definitions

Three price scenarios are analyzed for Era 0 economics. These are not forecasts; they bracket a plausible range from minimal adoption to substantial protocol deployment.

**Scenario A — Minimal Adoption ($0.0001/TRI)**  
TRI is used primarily within closed enterprise deployments. Liquidity is thin. Price reflects utility value of ZK proofs to a small set of early adopters. Market cap at full Era 0 circulation: ~$381M.

**Scenario B — Growth Phase ($0.001/TRI)**  
TRI has achieved integration in multiple ZK-verification use cases (cross-chain bridges, identity attestation, compliance proofs). Price reflects growing demand with improving liquidity. Market cap at full Era 0 circulation: ~$3.81B.

**Scenario C — Mainstream Deployment ($0.01/TRI)**  
TRI is a leading ZK proof token with integration in major blockchain ecosystems, used for privacy-preserving computation at scale. Market cap at full Era 0 circulation: ~$38.1B.

### 7.2 Chip Operator P&L: Era 0 (per chip)

Assumptions: chip CAPEX $75,000, power consumption 500W, electricity $0.08/kWh, colocation overhead $200/month.

```
Operating cost per chip per day:
  Power:  0.5 kW × 24 h × $0.08/kWh = $0.96/day
  Colo:   $200/month ÷ 30 = $6.67/day
  Total opex: ~$7.63/day

Annual opex: ~$2,785/chip/year
CAPEX amortized over 4 years: $75,000 ÷ 4 = $18,750/chip/year
Total annual cost: ~$21,535/chip/year
```

| Scenario | Revenue/chip/year | Cost/chip/year | Net P&L/chip/year | ROI    |
|----------|-------------------|-----------------|---------------------|--------|
| A: $0.0001/TRI | $95,367    | $21,535         | +$73,832            | +343%  |
| B: $0.001/TRI  | $953,668   | $21,535         | +$932,133           | +4,328% |
| C: $0.01/TRI   | $9,536,678 | $21,535         | +$9,515,143         | +44,182% |

Even at the minimal $0.0001/TRI scenario, chip operators earn a substantial return on their capital. This is deliberate: Era 0 economics must be attractive enough to seed the network before TRI has established market liquidity.

### 7.3 Break-Even Analysis

The break-even TRI price (revenue = total cost) for a single chip in Era 0:

```
Break-even = $21,535/year ÷ 953,665,150 TRI/year
           ≈ $0.0000000226/TRI
           = $2.26 × 10^-8 per TRI
```

This is approximately 4,400× below the Scenario A price of $0.0001. The Era 0 reward structure provides an extremely wide safety margin for early chip operators, reflecting the elevated risk of operating in a protocol's genesis era.

### 7.4 Era 1 Break-Even Adjustment

In Era 1 (reward halved to 500 TRI/proof), the TRI price required to maintain the same USD revenue doubles. All chip operators entering Era 1 face a step-function revenue reduction unless TRI price has approximately doubled. This creates a market-tested selection mechanism:

- Operators who correctly modeled TRI price appreciation and entered in Era 0 at low hardware cost are well-positioned.
- Operators who entered late in Era 0 at high hardware cost must depend on Era 1 price appreciation.
- Operators who cannot sustain Era 1 economics exit, reducing proof supply, which (if demand for proofs remains constant) increases per-proof scarcity and supports price.

---

## 8. Why Exactly 9 Halvings: Ternary Field Alignment GF(3^k)

### 8.1 The Algebraic Argument

The number 9 is not chosen for aesthetic reasons or Bitcoin imitation. It is derived directly from the algebraic structure of Triton's ZK proof system.

Triton's proving circuits operate over finite fields of characteristic 3. The fundamental fields are:

```
GF(3^1):  3 elements   — Era 0
GF(3^2):  9 elements   — Era 1
GF(3^3):  27 elements  — Era 2
GF(3^4):  81 elements  — Era 3
GF(3^5):  243 elements — Era 4
GF(3^6):  729 elements — Era 5
GF(3^7):  2,187 elements — Era 6
GF(3^8):  6,561 elements — Era 7
GF(3^9):  19,683 elements — Era 8 (and Era 9 concluding)
```

There are exactly 9 non-trivial proper extensions of GF(3) through GF(3^9) — that is, there are exactly 9 distinct Galois fields of characteristic 3 with degree 1 through 9. The 9 halvings traverse exactly these 9 field levels.

### 8.2 Why Not 7 Halvings?

Seven halvings would terminate at GF(3^7) with degree 7. This leaves GF(3^8) and GF(3^9) unused — a structural incompleteness. The proving system is designed to utilize all nine field extensions; terminating emission at 7 halvings would mean the final two circuit levels (corresponding to the most complex, most computationally intensive proofs) receive no emission reward. This would economically disincentivize operation of the highest-complexity circuits, which are precisely the circuits needed for the protocol's most valuable use cases (large-scale privacy-preserving computation, recursive proof composition).

### 8.3 Why Not 10 Halvings?

Ten halvings would require a field GF(3^10), which has degree 10. There is no algebraic reason this field cannot exist — it is a valid Galois field — but it does not appear in the 9-level ternary field tower that defines the Triton circuit hierarchy. Adding a 10th halving would require either:
- Adding a 10th circuit level GF(3^10) to the proving system (a substantial protocol change with no cryptographic motivation), or
- Running a 10th halving at the GF(3^9) circuit level (inconsistent with the field-era alignment).

Neither is desirable. The clean alignment between 9 halvings and 9 field levels is a protocol invariant that should not be broken for purely tokenomic reasons.

### 8.4 Why Not k Halvings for Some Other k?

For any k ≠ 9, the emission schedule and the field tower would be misaligned. The Triton protocol is built around the completeness of GF(3^1) through GF(3^9). Nine halvings is the unique value of k for which:

1. Every field level GF(3^m) for m = 1, …, 9 is associated with an active emission era.
2. The total emission follows a clean geometric series with ratio 1/2.
3. The residual (locked supply) equals exactly S/2^10 = S/1024, a precise power-of-two fraction.

### 8.5 GF(3^k) Field Sizes and Era Rewards

| k | GF(3^k) size | Era | Reward (TRI/proof) | Ratio GF size / Era reward |
|---|--------------|-----|--------------------|---------------------------|
| 1 | 3            | 0   | 1,000.000000       | 0.003                     |
| 2 | 9            | 1   | 500.000000         | 0.018                     |
| 3 | 27           | 2   | 250.000000         | 0.108                     |
| 4 | 81           | 3   | 125.000000         | 0.648                     |
| 5 | 243          | 4   | 62.500000          | 3.888                     |
| 6 | 729          | 5   | 31.250000          | 23.328                    |
| 7 | 2,187        | 6   | 15.625000          | 139.968                   |
| 8 | 6,561        | 7   | 7.812500           | 839.808                   |
| 9 | 19,683       | 8   | 3.906250           | 5,038.848                 |
| 9 | 19,683       | 9   | 1.953125           | 10,077.696                |

The ratio of GF field size to era reward scales as (3/2)^k, encoding both the ternary expansion of the field and the binary decay of the reward. This cross-dimensional scaling is the algebraic signature of the Triton emission design.

---

## 9. Asymptotic Tail and Permanently Locked Supply

### 9.1 The Locked Remainder

After Era 9 concludes in 2066, the following supply is permanently locked (cannot be mined, minted, or released by any protocol mechanism):

```
Locked = 3^27 / 2^10
       = 7,625,597,484,987 / 1024
       = 7,446,872,543.93...
       ≈ 7,446,872,544 TRI
```

As a percentage of total supply: **0.0977%** (~0.098%).

### 9.2 What "Permanently Locked" Means

The locked supply is not held by any address. It is not a founder reserve, treasury allocation, or multisig wallet. It is simply supply that the emission schedule never reaches — the fractional remainder of the geometric series that would require an 11th halving (Era 10) to access.

Because no minting mechanism exists beyond the proof-reward schedule, and because there is no Era 10, these tokens are inaccessible by construction. The Triton protocol has no admin key, no mint function, and no governance path to change the emission schedule post-launch.

### 9.3 Economic Significance of the Lock

7.45 billion locked TRI represents approximately 0.1% of total supply. For context:

- Bitcoin has approximately 1.9 million BTC (out of 21 million) considered permanently lost as of 2024 — approximately 9% of supply, due to lost keys and early mining.
- Ethereum regularly burns tokens via EIP-1559, reducing circulating supply dynamically.
- TRI's locked amount is a known, fixed, protocol-level constant — not a statistical estimate of loss.

The locked supply provides a minor deflationary pressure: economic models of TRI's terminal value should use 7,618,150,612,443 TRI as the "practical maximum supply" rather than 7,625,597,484,987, with the difference (7,446,872,544 TRI) permanently absent from circulation.

### 9.4 Why Not Run Emission Past Era 9?

Several arguments favor stopping at Era 9 rather than continuing indefinitely:

1. **Algebraic completeness.** As established in Section 8, GF(3^9) is the highest field level in the Triton circuit hierarchy. Running additional eras would require either additional field levels (protocol change) or continued emission at the GF(3^9) reward rate indefinitely (perpetual inflation, abandoning the hard cap).

2. **Economic simplicity.** A hard cap at a known date (2066) allows all market participants to model the terminal supply precisely. Perpetual emission (even at very low rates) introduces infinite-horizon uncertainty.

3. **Historical validation.** Bitcoin's design relies on transaction fees replacing block rewards as the long-term miner incentive. By 2066, Triton's proving fee market (users paying per-proof fees to operators) should be sufficient to incentivize continued network operation without token emission.

4. **Practical reward floor.** Era 9's reward of 1.953125 TRI/proof is already in the range where, at any price above $0.001/TRI, per-proof revenue is under $0.002. Further halving would yield sub-$0.001 rewards that are below practical gas/fee thresholds for on-chain reward claims. Era 9 represents a natural economic floor.

### 9.5 Terminal State (Post-2066)

After 2066, the Triton network operates as follows:

- **Circulating supply:** Fixed at 7,618,150,612,443 TRI (minus any losses/burns).
- **Miner incentive:** Proof submission fees paid by proof requesters (analogous to Bitcoin transaction fees).
- **Fee market:** Governed by supply and demand for proofs, decoupled from token issuance.
- **Inflation rate:** Zero (no new TRI is created).

---

## 10. Comparison with Bitcoin, Ethereum, and Bittensor

### 10.1 Design Philosophy Comparison

| Protocol   | Emission Model     | Halvings | Duration    | Hard Cap?        | Proof Mechanism    |
|------------|-------------------|----------|-------------|------------------|--------------------|
| Bitcoin    | Halving schedule  | 33       | ~130 years  | Yes (21M BTC)    | Proof-of-Work      |
| Ethereum   | No halving        | 0        | Perpetual   | No (EIP-1559 burn offset) | Proof-of-Stake |
| Bittensor  | Halving schedule  | N/A      | ~4-year cycle | Yes (21M TAO)  | Proof-of-Intelligence |
| TRI        | Halving schedule  | 9        | 36 years    | Yes (3^27 TRI)   | ZK Proof           |

### 10.2 Bitcoin: 33 Halvings vs. TRI: 9 Halvings

**Bitcoin's schedule:**
- Block reward: 50 BTC → 25 → 12.5 → 6.25 → 3.125 → … (halves every 210,000 blocks ≈ 4 years)
- 33 halvings across approximately 130 years
- Terminal supply: 20,999,999.9769 BTC (rounds to 21M)
- Residual locked by design: ~2,100,000 satoshis ≈ 0.021 BTC

**Key differences:**

*Duration.* Bitcoin runs for ~130 years; TRI runs for 36 years. This reflects TRI's position as a second-generation protocol: it can adopt a shorter emission window because (a) the ZK-proving infrastructure matures faster than PoW mining, and (b) fee markets are expected to sustain security within a 40-year window.

*Number of halvings.* Bitcoin's 33 halvings are driven by the choice of 210,000 blocks and a 10-minute block time. TRI's 9 halvings are algebraically constrained by the 9-level ternary field hierarchy. Neither number is arbitrary; each is determined by the protocol's core technical parameters.

*Reward granularity.* Bitcoin's smallest reward (after 33 halvings) is 1 satoshi = 10^-8 BTC. TRI's smallest reward is 1.953125 TRI = 1,953,125 μTRI. Both protocols stop emission when the reward reaches a practical floor.

*Fraction mined.* Bitcoin: 99.9999999% mined (nearly all). TRI: 99.9023% mined (0.0977% locked). Bitcoin's much higher fraction is due to 33 halvings vs. TRI's 10 terms: (1 - 1/2^33) vs. (1 - 1/2^10).

### 10.3 Ethereum: No Halving

Ethereum began with a fixed issuance of 2 ETH per block (later changed via EIPs), has no halving schedule, and no hard cap. Post-Merge (2022), ETH issuance is ~0.6% annually (staking rewards), partially offset by EIP-1559 fee burns that can make net supply deflationary during high-demand periods.

**Ethereum's tradeoffs vs. TRI's halving:**

- *Flexibility:* Ethereum's issuance is governable — the community can vote to change it. TRI's schedule is immutable. Flexibility is good for protocol adaptation; immutability is better for monetary credibility.
- *Predictability:* TRI's total supply is exactly known at genesis. Ethereum's net supply in 2066 is unknowable today (depends on future governance decisions and burn dynamics).
- *Miner/validator incentive:* Ethereum validators earn staking rewards that do not diminish over time (as a % rate). TRI miners earn diminishing rewards that require price appreciation to sustain. Ethereum's model is more forgiving; TRI's model is more demand-signal responsive.

The Triton team chose the halving model over Ethereum's approach because the ZK-proving market resembles Bitcoin mining more than Ethereum staking: operators make large, lumpy capital investments in custom hardware, not liquid staking deposits, and need the hard supply cap for long-term capital planning.

### 10.4 Bittensor (TAO): 4-Year Cycles

Bittensor's TAO token has a 21M hard cap (identical to Bitcoin) and a halving-style schedule aligned to 4-year blocks. It is the most comparable protocol to TRI in design philosophy: a token issued to reward compute-intensive proof work (machine intelligence in TAO's case, ZK proofs in TRI's).

**Similarities with TRI:**
- 4-year emission periods
- Hard supply cap
- Compute-as-mining model
- Halving as the core emission mechanic

**Differences:**
- TAO has 21M tokens (small, like BTC); TRI has 7.625T tokens (large).
- TAO's halving count is not algebraically constrained; TRI's 9 halvings are field-theoretically derived.
- TAO uses proof-of-intelligence (ML model quality); TRI uses zero-knowledge proofs (cryptographic soundness).
- TRI has a 36-year fixed horizon; TAO's schedule extends ~100+ years.

The Bittensor comparison is instructive for validators and miners already familiar with that ecosystem: TRI's economic dynamics in Era 0 are similar to TAO's early halving cycles, with the primary difference being TRI's algebraic connection to ternary ZK fields.

---

## 11. Reference Appendix: Block-by-Block Mathematics

### 11.1 Era Boundary Definitions

Each era is bounded by a block height range. Unlike Bitcoin's block-height-triggered halvings, Triton halvings are **calendar-triggered** — they occur at predefined timestamps (UTC midnight, January 1 of the halving year). This ensures predictable dates independent of proof submission rates.

| Halving # | Trigger Date     | Reward Before  | Reward After  |
|-----------|------------------|----------------|---------------|
| 1         | 2030-01-01 00:00 | 1,000.000000   | 500.000000    |
| 2         | 2034-01-01 00:00 | 500.000000     | 250.000000    |
| 3         | 2038-01-01 00:00 | 250.000000     | 125.000000    |
| 4         | 2042-01-01 00:00 | 125.000000     | 62.500000     |
| 5         | 2046-01-01 00:00 | 62.500000      | 31.250000     |
| 6         | 2050-01-01 00:00 | 31.250000      | 15.625000     |
| 7         | 2054-01-01 00:00 | 15.625000      | 7.812500      |
| 8         | 2058-01-01 00:00 | 7.812500       | 3.906250      |
| 9         | 2062-01-01 00:00 | 3.906250       | 1.953125      |

### 11.2 Proof Rate Target Per Era

Each era must issue its target supply at the era's reward rate. The proof rate required to exactly fill each era (distributed evenly across the era's duration) is:

| Era | Days    | TRI to issue           | TRI/proof    | Proofs needed       | Proofs/day needed  |
|-----|---------|------------------------|--------------|----------------------|--------------------|
| 0   | 1,461   | 3,812,798,742,494      | 1,000.000000 | 3,812,798,742        | 2,609,718          |
| 1   | 1,461   | 1,906,399,371,247      | 500.000000   | 3,812,798,742        | 2,609,718          |
| 2   | 1,461   | 953,199,685,623        | 250.000000   | 3,812,798,742        | 2,609,718          |
| 3   | 1,461   | 476,599,842,812        | 125.000000   | 3,812,798,742        | 2,609,718          |
| 4   | 1,461   | 238,299,921,406        | 62.500000    | 3,812,798,742        | 2,609,718          |
| 5   | 1,461   | 119,149,960,703        | 31.250000    | 3,812,798,742        | 2,609,718          |
| 6   | 1,461   | 59,574,980,351         | 15.625000    | 3,812,798,742        | 2,609,718          |
| 7   | 1,461   | 29,787,490,176         | 7.812500     | 3,812,798,742        | 2,609,718          |
| 8   | 1,461   | 14,893,745,088         | 3.906250     | 3,812,798,742        | 2,609,718          |
| 9   | 1,461   | 7,446,872,544          | 1.953125     | 3,812,798,742        | 2,609,718          |

**Key invariant:** Every era requires exactly 3,812,798,742 total proofs, regardless of era. The era reward changes; the required proof count does not. This means the network must sustain the same proof throughput indefinitely (in proofs-per-day terms) to fill each era on schedule.

This invariance is a consequence of the halving structure: reward halves, supply halves, their ratio (proofs needed) is constant.

### 11.3 Proof Rate per Chip by Era

As circuit complexity scales with field degree, proofs per chip per day decreases across eras. The reference chip produces 2,611 proofs/day at GF(3^1). For higher field degrees:

| Era | GF level | Relative complexity | Proofs/chip/day (reference) | Chips needed (target rate) |
|-----|----------|---------------------|-----------------------------|---------------------------|
| 0   | GF(3^1)  | 1×                  | 2,611                       | 1,000                     |
| 1   | GF(3^2)  | ~3×                 | ~870                        | ~3,000                    |
| 2   | GF(3^3)  | ~9×                 | ~290                        | ~9,000                    |
| 3   | GF(3^4)  | ~27×                | ~97                         | ~27,000                   |
| 4   | GF(3^5)  | ~81×                | ~32                         | ~81,000                   |
| 5   | GF(3^6)  | ~243×               | ~11                         | ~243,000                  |
| 6   | GF(3^7)  | ~729×               | ~3.6                        | ~729,000                  |
| 7   | GF(3^8)  | ~2,187×             | ~1.2                        | ~2,187,000                |
| 8   | GF(3^9)  | ~6,561×             | ~0.4                        | ~6,561,000                |
| 9   | GF(3^9)  | ~6,561×             | ~0.4                        | ~6,561,000                |

Note: The chip count projections for later eras assume hardware improvements do not outpace complexity scaling. In practice, hardware gains (faster ternary ASICs, improved proof algorithms) are expected to more than compensate, keeping the required chip count within economically feasible range. These projections represent worst-case (no hardware improvement) scenarios.

### 11.4 Cumulative Emission Formula

At any point t within Era k (where t is measured in days from the start of Era k), the cumulative TRI emitted is:

```
E(k, t) = ∑(j=0 to k-1) [S / 2^(j+1)]  +  [S / 2^(k+1)] × (t / 1461)

where:
  S = 7,625,597,484,987 (total supply)
  k = current era (0–9)
  t = days elapsed in current era (0–1461)
  1461 = days in 4-year era (including one leap year)
```

Simplifying the prefix sum:

```
∑(j=0 to k-1) S / 2^(j+1) = S × (1 - 1/2^k)
```

Therefore:

```
E(k, t) = S × [(1 - 1/2^k) + (1/2^(k+1)) × (t/1461)]
         = S × [1 - 1/2^k + t/(1461 × 2^(k+1))]
```

This formula gives the exact circulating supply at any point in the emission schedule.

### 11.5 Verification Checksums

The following values should be used for protocol-level verification:

| Parameter                          | Value                              |
|------------------------------------|------------------------------------|
| Total supply (3^27)                | 7,625,597,484,987 TRI              |
| Era 0 supply (S/2)                 | 3,812,798,742,494 TRI              |
| Era 9 supply (S/1024)              | 7,446,872,544 TRI                  |
| Total mined (10 eras)              | 7,618,150,612,443 TRI              |
| Permanently locked                 | 7,446,872,544 TRI                  |
| Fraction mined                     | 1023/1024 = 0.999023437500         |
| Fraction locked                    | 1/1024 = 0.000976562500            |
| Proofs per era (invariant)         | 3,812,798,742                      |
| Total proofs across all 10 eras    | 38,127,987,420                     |
| Era 0 reward (μTRI)                | 1,000,000,000 μTRI                 |
| Era 9 reward (μTRI)                | 1,953,125 μTRI                     |

### 11.6 Integer Overflow Considerations

Protocol implementors must use 64-bit unsigned integers or arbitrary-precision arithmetic for supply accounting. The maximum values:

```
Max supply: 7,625,597,484,987 TRI = 7,625,597,484,987,000,000 μTRI
  = 7.626 × 10^18 μTRI

64-bit unsigned max: 2^64 - 1 = 18,446,744,073,709,551,615
  ≈ 1.844 × 10^19

Safety margin: ~2.42× before overflow
```

The protocol fits within a 64-bit unsigned integer with a comfortable margin when denominated in μTRI (6 decimal places). Denominating in units smaller than μTRI (e.g., nano-TRI) would risk overflow and is not recommended.

### 11.7 Emission Rate Derivatives

The instantaneous emission rate (TRI per second) at the start of each era, assuming the target proof rate is met:

| Era | TRI/proof    | Proofs/day target | TRI/day target    | TRI/second (avg) |
|-----|-------------|-------------------|-------------------|------------------|
| 0   | 1,000       | 2,609,718         | 2,609,718,000,000 | 30,206,458       |
| 1   | 500         | 2,609,718         | 1,304,859,000,000 | 15,103,229       |
| 2   | 250         | 2,609,718         | 652,429,500,000   | 7,551,614        |
| 3   | 125         | 2,609,718         | 326,214,750,000   | 3,775,807        |
| 4   | 62.5        | 2,609,718         | 163,107,375,000   | 1,887,904        |
| 5   | 31.25       | 2,609,718         | 81,553,687,500    | 943,952          |
| 6   | 15.625      | 2,609,718         | 40,776,843,750    | 471,976          |
| 7   | 7.8125      | 2,609,718         | 20,388,421,875    | 235,978          |
| 8   | 3.90625     | 2,609,718         | 10,194,210,938    | 117,989          |
| 9   | 1.953125    | 2,609,718         | 5,097,105,469     | 58,995           |

The emission rate halves each era, consistent with the supply schedule. By Era 9, the network is issuing approximately 59,000 TRI per second — still substantial, but 512× slower than Era 0.

---

*Document: 02_EMISSION_CURVE_36_YEARS.md*  
*Author: Dmitrii Vasilev \<admin@t27.ai\>*  
*Part of the Triton (TRI) Tokenomics series.*  
*No AI co-authorship.*
