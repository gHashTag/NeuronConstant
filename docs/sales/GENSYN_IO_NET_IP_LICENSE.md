# TRINITY B5 ZK JOB PROVER — IP LICENSE PROPOSAL
## DePIN AI Compute Targets: Gensyn · io.net · Akash · Render Network

---

> **INTERNAL — NOT FOR PUBLIC DISTRIBUTION**
> **CONFIDENTIAL — EYES ONLY: Dmitrii Vasilev, t27.ai leadership**
>
> This document contains non-public pricing, negotiation strategy, and proprietary IP
> descriptions. Do not forward, copy, print, or store outside of authorized channels.
> Prepared by: **Dmitrii Vasilev (sole author, admin@t27.ai)**, t27.ai
> Document version: 1.0 — June 2026
> Classification: INTERNAL COMMERCIAL STRATEGY

---

## TABLE OF CONTENTS

1. Executive Summary
2. IP Asset Overview — Trinity B5 ZK Job Prover
3. Target Dossiers
   - 3.1 Gensyn
   - 3.2 io.net
   - 3.3 Akash Network
   - 3.4 Render Network
4. Pricing Rationale & Comparable Deals
5. Negotiation Tactics
6. Revenue Projections (Year 1 / Year 2 / Year 3)
7. Risks & Mitigations
8. Timeline
9. Patent & IP Strategy
10. Cold Outreach Email Templates

---

## 1. EXECUTIVE SUMMARY

t27.ai holds sole authorship and all IP rights over the **Trinity B5 ZK Job Prover**, a
937-line specification (docs/v1.1/) that enables instant Groth16 zero-knowledge proofs of
AI compute jobs, verifiable on-chain via Ethereum precompile 0x08 (BN128 pairing check).
The IP is authored entirely by **Dmitrii Vasilev (admin@t27.ai)**.

### The Market Problem

The emerging Decentralized Physical Infrastructure Network (DePIN) compute sector —
representing billions of dollars in aggregate fully-diluted value — has a critical,
unresolved trust problem: **none of the leading platforms can cryptographically prove that
a compute job was executed honestly**.

- **Gensyn** uses a 12-hour optimistic challenge window modelled on Optimism/Arbitrum
  dispute games. This is slow, capital-inefficient, and vulnerable to economic attacks at
  scale.
- **io.net, Akash, Render Network** perform no cryptographic compute verification
  whatsoever. Trust is delegated entirely to reputation and spot-checks.
- **Bittensor SN ML subnets** require hardware attestation but lack a standardised,
  verifiable ZK layer.

### The Solution

The Trinity B5 ZK Job Prover eliminates the optimistic challenge window entirely. Any
compute job — tensor operation, ML inference batch, model fine-tuning shard — produces a
Groth16 proof in near-real-time, verifiable in one Ethereum precompile call (~180k gas).
Verification is instant, trustless, and chain-agnostic.

### Licensing Opportunity

t27.ai is offering time-limited exclusive and non-exclusive IP licenses to the four
highest-impact targets in the DePIN AI compute sector before a broader patent filing and
open licensing program commences in Q2 2027.

**Total addressable licensing revenue (conservative):**
- Year 1: $15M–$55M (upfront fees + first royalty tranches)
- Year 2: $25M–$80M
- Year 3: $35M–$120M

**Primary ask:** Outreach begins July 2026. First LOI target: October 2026.
First close target: Q1 2027.

---

## 2. IP ASSET OVERVIEW — TRINITY B5 ZK JOB PROVER

### 2.1 Specification Summary

| Parameter | Value |
|---|---|
| Specification file | docs/v1.1/ — 937 lines |
| Proof system | Groth16 (BN128 curve) |
| On-chain verifier | Ethereum precompile 0x08 (BN128 pairing check) |
| Verification cost | ~180k gas (single call) |
| Proof generation time | Near-instant (post-circuit-compile) |
| Comparison | Gensyn optimistic challenge: 12 hours |
| Hardware target | Trinity B5 ASIC (ternary compute) |
| Performance (projected, pending tape-out 2026-12-16) | ~1 GOPS @ ~50 MHz @ ~1W ternary |
| Champion BPB lock | 2.2393 (bits-per-byte, language model benchmark) |

**Important benchmark note:** All performance figures marked "projected, pending tape-out
2026-12-16" are forward-looking estimates based on design-stage simulation. t27.ai does
not represent these as measured silicon results until post-tape-out characterisation is
complete. Licensees should conduct independent technical due diligence.

### 2.2 Reward Mechanism (On-Chain Protocol Context)

The Trinity protocol tokenomics governing ZK job proof rewards are as follows:

- **Reward formula:** `floor(min(2.2393 − bpb, 1.0) / 0.01)` TRI per proof
- **Maximum reward:** 100 TRI/proof (when BPB ≤ 1.2393)
- **Proof fee:** 0.05 TRI/proof (paid by compute requester)
- **Champion BPB:** 2.2393 (locked baseline — first submitter to beat this earns full
  reward)
- **Target throughput:** 10,000 proofs/day → ~500 TRI/day gross protocol reward

This mechanism creates a strong economic incentive for DePIN platforms to adopt the
Trinity ZK layer: operators earn TRI tokens proportional to the quality of their compute
attestation. A licensee who embeds the B5 prover natively can offer their node operators
direct protocol revenue — a unique selling point vs. all competitors.

### 2.3 Technical Differentiation

| Dimension | Trinity B5 | Gensyn | io.net | Akash | Render |
|---|---|---|---|---|---|
| Proof system | Groth16 ZK | Optimistic challenge | None | None | None |
| Verification latency | ~instant (0x08 precompile) | 12 hours | N/A | N/A | N/A |
| On-chain verifiability | Yes (Ethereum-native) | Partial (dispute window) | No | No | No |
| Hardware attestation | B5 ASIC + ZK | Software-only | None | None | GPU driver |
| Ternary compute | Yes | No | No | No | No |
| BPB champion lock | 2.2393 | N/A | N/A | N/A | N/A |
| Patent status | Application in preparation | N/A | N/A | N/A | N/A |

### 2.4 IP Components Available for License

1. **Trinity B5 ZK Job Prover** — Core Groth16 circuit specification, constraint system,
   proving key generation protocol, and verifier smart contract (937-line spec)
2. **Trinity B1 Root-of-Trust (RoT)** — Hardware attestation module binding
   proof generation to authenticated silicon; available as bundle with B5
3. **BPB Champion Protocol** — Tokenomic reward mechanism for verifiable compute quality
4. **Verifier Contract Suite** — Solidity/Vyper implementations for Ethereum, L2s
   (Arbitrum, Optimism, Base), and EVM-compatible chains
5. **Circuit Compiler Toolchain** — Build pipeline converting ML operator graphs to
   Groth16 constraints

---

## 3. TARGET DOSSIERS

---

### 3.1 GENSYN

#### Company Overview

| Field | Detail |
|---|---|
| Headquarters | London, UK |
| Founded | 2020 |
| Stage | Series B (est.) |
| Core product | Decentralised ML training network |
| Key investors | a16z crypto, CoinFund, Paradigm (reported) |
| Token | GEN (planned) |
| Primary differentiator claim | Verifiable compute via optimistic challenge |

#### The Problem We Solve for Gensyn

Gensyn's technical foundation is an optimistic verification system modelled closely on
Optimistic Rollup dispute resolution. In this model:

1. A compute node submits a result hash and bond.
2. A 12-hour challenge window opens.
3. Any verifier can submit a dispute and trigger a bisection game.
4. If no challenge occurs, the result is accepted as final.

**Why this is a strategic liability for Gensyn:**

- **Capital lockup:** Node operators must post bonds for 12 hours per job. At scale
  (10,000+ concurrent jobs), this is tens of millions in locked capital.
- **Latency:** ML training pipelines require tight feedback loops. A 12-hour finality
  window is incompatible with iterative training runs.
- **Economic attack surface:** An adversary can selectively let fraudulent results pass
  through during low-challenge periods; bisection games are expensive for the challenger.
- **Regulatory exposure:** As regulators scrutinise AI compute provenance, "optimistic"
  attestation is legally weaker than cryptographic proof.
- **Competitor threat:** Any rival network offering instant ZK verification immediately
  makes Gensyn's challenge window look archaic.

The Trinity B5 ZK Job Prover eliminates all four liabilities simultaneously. Gensyn
could replace or supplement its bisection game with a single Groth16 proof per job,
cutting finality from 12 hours to ~1 block time (~12 seconds on Ethereum mainnet).

#### License Terms — Gensyn

| Component | Term |
|---|---|
| IP bundle | Trinity B5 ZK Job Prover (core) + Verifier Contract Suite |
| License type | Exclusive field-of-use (ML training verification) for 36 months, then non-exclusive |
| Upfront fee | **$5M–$15M** (negotiating range; open at $15M, BATNA $5M) |
| Royalty | **2%–5% of verifiable compute revenue** (revenue from jobs that are ZK-attested using the B5 prover) |
| Royalty floor | None in Year 1; $500k/year minimum from Year 2 |
| Sublicense rights | Prohibited without written consent |
| Source code escrow | Yes — held by neutral third party (Fenwick & West or equivalent) |
| Governing law | England & Wales (Gensyn HQ jurisdiction) |
| IP ownership | Retained by Dmitrii Vasilev / t27.ai; licensee receives implementation rights only |

**Opening position:** $15M upfront + 5% royalty on all ZK-attested compute revenue.
**Walk-away:** Below $5M upfront we decline; below 2% royalty we decline. No exclusivity
granted below $8M upfront.

**Estimated deal cycle:** 3–6 months from first outreach to signed license.
Gensyn's technical team will require 4–6 weeks for circuit-level due diligence; legal
negotiation typically 6–8 weeks for a mid-stage crypto infrastructure deal of this size.

**Strategic lever:** Gensyn's investors (a16z etc.) are acutely aware that the
optimistic-challenge model is a temporary scaffold. Positioning this license as "closing
the architectural gap before a competitor does" is the correct framing with their BD team.

---

### 3.2 IO.NET

#### Company Overview

| Field | Detail |
|---|---|
| Headquarters | San Francisco, CA |
| Founded | 2023 |
| Token | IO |
| FDV (peak 2024) | $4B+ |
| Core product | Decentralised GPU cluster marketplace |
| Primary backers | Multicoin Capital, Hack VC (reported) |
| Revenue model | Percentage fee on compute hours sold |

#### The Problem We Solve for io.net

io.net operates a GPU marketplace aggregating idle GPU capacity (data centres, consumer
GPUs, cloud overflow) and renting it to AI teams. As of this writing, **io.net performs
zero cryptographic verification of compute jobs**. A node operator can:

- Return synthetic/fabricated outputs
- Underperform on contracted GPU tier
- Collude with a buyer to fake attestation

io.net's current mitigation is reputational scoring and spot-checks — mechanisms that are
trivially gameable at scale. For io.net's B2B enterprise clients (AI labs paying
$50k–$500k/month in compute), the lack of cryptographic attestation is a material
procurement risk and increasingly a legal liability under emerging AI governance
frameworks.

**The B5 + B1 RoT bundle creates a complete trust stack for io.net:**
- B5 ZK Prover attests job execution correctness
- B1 Root-of-Trust binds the proof to authenticated hardware (prevents software-only proof
  spoofing)
- Together they enable io.net to offer "ZK-attested GPU compute" — a unique premium tier
  no competitor currently offers

At $4B+ FDV, io.net has the financial resources to make this a transformative deal. The
question is whether they move before Akash or Render does.

#### License Terms — io.net

| Component | Term |
|---|---|
| IP bundle | Trinity B5 ZK Job Prover + B1 Root-of-Trust (full bundle) |
| License type | Exclusive field-of-use (GPU compute marketplace verification) for 24 months, then non-exclusive OR full acquisition |
| **Option A — License** | |
| Upfront fee | **$10M–$30M** (open at $30M, BATNA $10M) |
| Royalty | **3% of total platform GMV** from ZK-attested compute jobs |
| Royalty floor | $1M/year from Year 2 |
| **Option B — Acquisition** | |
| Acquisition price | **$50M–$150M** for full IP portfolio transfer (B5 + B1 RoT + BPB Champion Protocol + toolchain) |
| Retention clause | Dmitrii Vasilev retained as IP advisor, 2-year consulting agreement |
| Earnout | 1% of ZK-attested compute GMV for 5 years post-close, capped at $25M total earnout |
| Governing law | California (io.net HQ jurisdiction) |

**Opening position:** Acquisition at $150M or license at $30M + 3% GMV royalty.
**BATNA:** License at $10M + 2% royalty if acquisition fails. No deal below $10M upfront.

**Strategic framing for io.net:** Position around enterprise sales expansion. Their
largest potential clients (hedge funds, pharma AI teams, defence-adjacent compute buyers)
increasingly require cryptographic compute attestation in procurement RFPs. The B5 prover
is the key that unlocks a $500M+ enterprise compute TAM that io.net currently cannot
access.

**Estimated deal cycle:** 3–6 months. io.net's BD team moves faster than Gensyn's
technical team. Acquisition path may compress to 3 months if they see competitive threat
from Akash.

---

### 3.3 AKASH NETWORK

#### Company Overview

| Field | Detail |
|---|---|
| Headquarters | Decentralised (Overclock Labs, Austin TX) |
| Founded | 2018 |
| Token | AKT |
| Market cap | $300M–$700M range (variable) |
| Core product | Decentralised cloud compute (Cosmos-based) |
| Distinguishing feature | Open-source, permissionless, Kubernetes-based |

#### The Problem We Solve for Akash

Akash is the most mature decentralised compute marketplace by deployment history, but it
faces the same fundamental verification gap as io.net: **no cryptographic proof that a
workload ran correctly on the claimed hardware**. Akash's reputation system and provider
auditing are community-driven and manual.

Akash has an additional constraint: its treasury is smaller than io.net's, and AKT's
market cap is more sensitive to competitive pressure. The strategic risk for Akash is that
io.net or a new entrant acquires the B5 prover and offers ZK-attested compute at a
premium, pulling Akash's enterprise clients away.

The Trinity B5 license for Akash is therefore primarily a **defensive play**: by
licensing the ZK layer, Akash matches any competitor who licenses it from t27.ai, and
prevents a "ZK gap" from opening in the market.

Additionally, Akash's Cosmos-based architecture means Verifier Contract deployment needs
an IBC-compatible bridge or a dedicated Akash EVM module. t27.ai's Verifier Contract
Suite supports this configuration; this is a unique implementation advantage.

#### License Terms — Akash Network

| Component | Term |
|---|---|
| IP bundle | Trinity B5 ZK Job Prover + Verifier Contract Suite (Cosmos/EVM variant) |
| License type | Non-exclusive (Akash's smaller treasury precludes exclusivity premium) |
| Upfront fee | **$5M–$15M** (open at $15M, BATNA $5M) |
| Royalty | **2%–3% of ZK-attested compute revenue** |
| Royalty floor | $250k/year from Year 2 |
| Sublicense rights | Prohibited |
| Governing law | Delaware (Overclock Labs entity) |
| IBC/EVM bridge | Implementation support included for 12 months post-signing |

**Opening position:** $15M + 3% royalty.
**Walk-away:** Below $5M upfront or below 2% royalty.

**Tactical note:** Akash is highly cost-sensitive. Lead with the competitive threat
narrative (io.net is in talks for the exclusive) before presenting pricing. The fear of
being left with no ZK verification while a competitor has exclusive access is the
primary motivator here.

**Estimated deal cycle:** 4–6 months. Akash's governance structure (on-chain governance
for protocol changes) adds overhead; however, the commercial license itself is signed by
Overclock Labs corporate entity, not on-chain.

---

### 3.4 RENDER NETWORK

#### Company Overview

| Field | Detail |
|---|---|
| Headquarters | Los Angeles, CA (OTOY Inc.) |
| Founded | 2017 (OTOY GPU rendering background) |
| Token | RENDER |
| FDV | $1B–$3B range (variable) |
| Core product | GPU rendering + AI inference marketplace |
| Distinguishing feature | OTOY's OctaneRender heritage; Solana-based token |
| Primary compute type | GPU (NVIDIA/AMD) — no CPU/ASIC attestation |

#### The Problem We Solve for Render Network

Render Network occupies a distinct niche: high-end GPU rendering and increasingly AI
inference, building on OTOY's professional rendering software heritage. Render's compute
verification is limited to GPU driver-level checks — there is no ZK proof of job
completion, and the rendering/inference output is accepted on delivery without
cryptographic attestation of the execution trace.

As Render expands from rendering into AI inference hosting (a stated strategic direction),
it enters a market where enterprise buyers increasingly require provable compute. The B5
ZK layer is a **ZK inference attestation add-on**: proof that a specific model (identified
by parameter hash) ran on a specific input and produced a specific output, without
revealing the input or output to the network.

This is particularly valuable for Render's emerging AI clients handling proprietary data
(medical imaging, financial modelling, legal document AI) where privacy + verifiability
are both required.

#### License Terms — Render Network

| Component | Term |
|---|---|
| IP bundle | Trinity B5 ZK Job Prover (inference variant) + Verifier Contract Suite (Solana SVM / EVM) |
| License type | Non-exclusive field-of-use (GPU rendering verification + AI inference) |
| Upfront fee | **$3M–$10M** (open at $10M, BATNA $3M) |
| Royalty | **1.5%–2.5% of ZK-attested inference revenue** |
| Royalty floor | $200k/year from Year 2 |
| Solana SVM support | Verifier contract ported to Solana SVM; implementation 90-day milestone |
| Governing law | California |
| Notes | Render's OTOY parent company is the contracting entity; ensure OTOY Inc. signs |

**Opening position:** $10M + 2.5% royalty.
**Walk-away:** Below $3M upfront.

**Tactical note:** Render's team cares deeply about creative professional use cases.
Lead with the privacy angle (ZK proofs for confidential AI inference on creative IP) as
well as the enterprise AI expansion narrative. Avoid leading with the ternary compute
hardware pitch — they are GPU-native and hardware-agnostic messaging works better here.

**Estimated deal cycle:** 4–6 months. OTOY's corporate structure adds legal review
overhead; however, their BD team is commercially sophisticated from years of enterprise
rendering licensing.

---

## 4. PRICING RATIONALE & COMPARABLE DEALS

### 4.1 Pricing Philosophy

t27.ai's pricing is anchored to three factors:

1. **Platform FDV / Treasury Size** — Higher-capitalized platforms pay higher upfront fees
   because (a) they can afford it and (b) the IP is more valuable to a larger network.
2. **Verification Gap Severity** — Gensyn has a partial solution (optimistic challenge);
   io.net/Akash/Render have nothing. The severity of the gap drives willingness to pay.
3. **Exclusivity Premium** — Any licensee requesting exclusivity in their field-of-use
   pays a 2–3× premium over non-exclusive pricing.

### 4.2 Comparable IP Licensing Transactions

| Deal | Type | Upfront | Royalty |
|---|---|---|---|
| ARM Holdings licensing deals (avg. per licensee) | Processor architecture IP | $5M–$50M | 1%–2% per chip |
| Qualcomm CDMA patent licensing | Wireless standards IP | $50M–$500M (large telcos) | 2%–5% of handset revenue |
| MPEG-LA H.264 patent pool | Video codec IP | Pool entry fee varies | ~$0.10–$0.20/device |
| zkSync/StarkWare IP (est. market rate for ZK circuit license) | ZK proof system | $2M–$20M | 1%–3% of protocol fee revenue |
| Ingonyama ZK ASIC accelerator licensing (est.) | ZK hardware IP | $5M–$25M | Per-proof fee |

**Key observation:** ZK proof system IP is a nascent but rapidly pricing-in market.
The ARM analogy is the closest structural comparator: the B5 prover is a proprietary
circuit architecture that any platform can embed, in the same way ARM cores are embedded
in SoCs. ARM's per-licensee upfront fees averaged $5M–$15M in early architecture
licensing years; t27.ai's pricing is consistent with this precedent.

### 4.3 Royalty Base Definitions

To prevent disputes, royalty bases are defined precisely in term sheets:

- **Verifiable compute revenue** (Gensyn): Total fees collected by the Gensyn protocol
  for compute jobs that produce a B5 ZK proof, net of on-chain gas costs.
- **Platform GMV** (io.net): Total gross value of compute transactions settled through
  the io.net platform where B5 proofs are attached, net of refunds.
- **ZK-attested compute revenue** (Akash): Subset of Akash marketplace revenue where
  provider attestation uses the licensed B5 prover, as reported in Akash's on-chain
  settlement data.
- **ZK-attested inference revenue** (Render): Revenue from inference jobs where B5 proof
  is generated and verified, as reported in OTOY's platform billing system.

---

## 5. NEGOTIATION TACTICS

### 5.1 Priority Sequencing

**Order of outreach:** io.net → Gensyn → Akash → Render

**Rationale:**
- io.net has the largest treasury, highest FDV ($4B+), and fastest BD decision cycles.
  Securing a term sheet with io.net (even non-binding) creates competitive pressure on all
  other targets.
- Gensyn's technical team will take longest to complete due diligence (circuit review);
  start them in parallel with io.net to ensure they don't create a bottleneck.
- Akash and Render are downstream targets; their willingness to pay is partly driven by
  fear that io.net/Gensyn have already licensed the IP.

### 5.2 Competitive Pressure Playbook

**Tactic 1 — The Exclusive Threat**
When in discussions with any single target, truthfully state: "We are in parallel
discussions with [competitor]. If they close an exclusive before you, your window for
field-of-use exclusivity closes." This is true as long as we are running simultaneous
outreach.

**Tactic 2 — The Patent Filing Deadline**
Communicate that provisional patent applications are being filed Q3 2026. After filing,
the IP licensing terms will be publicly disclosed and all exclusivity windows close. This
creates a real deadline.

**Tactic 3 — The TRI Token Incentive**
Highlight that early licensees can configure their node operators to earn TRI token
rewards directly via the on-chain proof reward mechanism. At 10,000 proofs/day and 100
TRI/proof max reward, this is a material yield opportunity for their operator community.
This converts a pure cost (license fee) into a revenue story.

**Tactic 4 — The Regulatory Framing**
Frame the ZK prover as a compliance tool, not just a technical feature. EU AI Act and
emerging SEC guidance on tokenised compute markets may eventually require cryptographic
attestation of AI workloads. Early licensees are "compliance-ready"; non-licensees face
retrofit costs later.

### 5.3 Anchoring & Concession Ladder

| Round | Gensyn | io.net | Akash | Render |
|---|---|---|---|---|
| Open | $15M + 5% | $30M + 3% GMV | $15M + 3% | $10M + 2.5% |
| First concession | $12M + 4% | $25M + 2.5% | $12M + 2.5% | $8M + 2% |
| Second concession | $10M + 3% | $20M + 2% | $8M + 2% | $6M + 2% |
| BATNA (walk-away) | $5M + 2% | $10M + 2% | $5M + 2% | $3M + 1.5% |

**Rule:** Never move on both price AND royalty simultaneously. Concede one dimension
per round. Prefer to protect royalty rate and give ground on upfront when treasury-
constrained counterparts push back.

### 5.4 Deal Structure Flexibility

For io.net specifically, offer three structures in the opening term sheet to demonstrate
flexibility:
1. Pure license ($10M–$30M upfront + royalty)
2. Equity + license (reduced upfront, replace royalty with 0.5–1% of IO token float)
3. Acquisition ($50M–$150M + earnout)

Present all three simultaneously and let their preference reveal their internal financial
constraints and strategic intentions.

---

## 6. REVENUE PROJECTIONS

### 6.1 Assumptions

- All four targets close licenses (base case assumes 3 out of 4 close; bear case assumes 2)
- Royalty revenue begins accruing 6 months after license signing (integration delay)
- io.net acquires (Option B) in best case; licenses only in base case
- DePIN compute GMV grows at 40% CAGR 2026–2029 (conservative vs. sector estimates)
- Royalty rates applied to t27.ai's contracted share of platform ZK-attested volume

### 6.2 Year 1 (2026–2027): Upfront Fees Dominant

| Source | Bear Case | Base Case | Bull Case |
|---|---|---|---|
| Gensyn upfront license | $0 | $10M | $15M |
| io.net upfront license | $10M | $20M | — |
| io.net acquisition | — | — | $100M |
| Akash upfront license | $0 | $8M | $12M |
| Render upfront license | $3M | $6M | $10M |
| Royalty revenue (partial year) | $0.5M | $1.5M | $3M |
| **Year 1 Total** | **$13.5M** | **$45.5M** | **$140M** |

### 6.3 Year 2 (2027–2028): Royalty Ramp

| Source | Bear Case | Base Case | Bull Case |
|---|---|---|---|
| New license fees (Bittensor SN, others) | $2M | $8M | $20M |
| Gensyn royalty (2–5% × est. $200M–$500M rev) | $2M | $8M | $20M |
| io.net royalty (3% × est. $300M–$1B GMV) | $4M | $12M | $25M |
| Akash royalty (2–3% × est. $100M–$300M rev) | $1M | $4M | $8M |
| Render royalty (1.5–2.5% × est. $50M–$200M rev) | $0.5M | $2M | $5M |
| **Year 2 Total** | **$9.5M** | **$34M** | **$78M** |

### 6.4 Year 3 (2028–2029): Mature Royalty + Expansion

| Source | Bear Case | Base Case | Bull Case |
|---|---|---|---|
| Expansion licenses (new DePIN entrants) | $3M | $10M | $30M |
| Gensyn royalty | $3M | $12M | $30M |
| io.net royalty | $6M | $18M | $40M |
| Akash royalty | $1.5M | $6M | $12M |
| Render royalty | $1M | $3M | $8M |
| **Year 3 Total** | **$14.5M** | **$49M** | **$120M** |

### 6.5 3-Year Cumulative

| Scenario | 3-Year Total |
|---|---|
| Bear | $37.5M |
| Base | $128.5M |
| Bull | $338M |

**Note on bull case:** The $338M bull case is driven primarily by the io.net acquisition
at $100M. Without acquisition, bull case 3-year total is approximately $238M.

### 6.6 TRI Protocol Revenue (Separate Income Stream)

Independent of licensing, t27.ai earns TRI token rewards directly from proof generation:

- Target: 10,000 proofs/day
- Average reward: 50 TRI/proof (mid-range estimate; full 100 TRI/proof requires BPB ≤ 1.2393)
- Fee collected: 0.05 TRI/proof
- **Gross protocol TRI income: ~500 TRI/day = ~182,500 TRI/year**
- USD value depends on TRI token price at time of accrual (not modelled here; treat as
  upside)

---

## 7. RISKS & MITIGATIONS

### 7.1 Risk Register

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Competitor builds own ZK circuit in-house | Medium | High | Speed-to-market; file provisional patent Q3 2026 before any competitor ships; our 937-line spec + circuit is already ready |
| Target raises hardware attestation requirements beyond B5 capability | Low | Medium | B1 RoT bundle addresses hardware binding; expand circuit scope per licensee if needed |
| ZK proof systems become commoditised (Risc Zero, SP1 proliferation) | Medium | Medium | Groth16 + 0x08 precompile is Ethereum-native and gas-optimal; STARK-based alternatives cost 3–10× more on-chain; our cost advantage persists |
| Token/treasury collapse at target (AKT/IO price drop) | Medium | Medium | Require upfront fee in USD stablecoin (USDC) or fiat wire, not native token; royalty can be in token but upfront must be USD-denominated |
| Due diligence reveals spec gaps or implementation bugs | Low | High | Conduct internal pre-DD circuit audit before first outreach; engage a ZK auditor (e.g., Trail of Bits, Zellic) for independent review |
| Patent application rejected or narrowed | Medium | Low–Medium | Design around claims in advance; trade secret protection for circuit implementation details even if patent fails; first-mover advantage still holds |
| Regulatory change makes DePIN compute unlawful in key jurisdiction | Very Low | Very High | Jurisdictional diversification of licensees; governing law clauses; monitor EU AI Act, SEC crypto framework |
| Tape-out delay (B5 ASIC target: 2026-12-16) | Medium | Low (for licensing) | Licensing the ZK circuit spec does not depend on tape-out; tape-out is upside for hardware bundling only |

### 7.2 Primary Mitigation: Speed-to-Market + Patent Filing

The single most important risk mitigation is executing outreach before any competitor
understands that the B5 ZK prover approach is feasible and builds their own. The 937-line
spec represents a significant head start. The path:

1. **July 2026:** Begin outreach (spec complete, pre-patent)
2. **August 2026:** File provisional US patent application covering Groth16 job prover
   circuit + 0x08 verification method
3. **October 2026:** First LOI — establishes commercial use before patent filing date
4. **Q1 2027:** First signed license — establishes revenue stream
5. **August 2027:** File PCT international application (12-month window from provisional)

Provisional patent filing establishes priority date. All outreach and licensing activity
before filing is covered by NDA; after filing, the provisional is confidential for 18
months (standard USPTO timeline).

---

## 8. TIMELINE

### 8.1 Master Timeline

| Date | Milestone | Owner |
|---|---|---|
| June 2026 | Internal doc complete; legal review of IP ownership chain | Dmitrii Vasilev |
| July 1, 2026 | Begin outreach to io.net BD team | Dmitrii Vasilev |
| July 7, 2026 | Begin outreach to Gensyn technical co-founder | Dmitrii Vasilev |
| July 14, 2026 | Begin outreach to Akash / Overclock Labs | Dmitrii Vasilev |
| July 21, 2026 | Begin outreach to Render / OTOY | Dmitrii Vasilev |
| August 1, 2026 | File provisional US patent application | IP counsel |
| August–September 2026 | Technical DD meetings; circuit walkthrough sessions | Dmitrii Vasilev + target eng teams |
| September 2026 | ZK circuit independent audit complete (Trail of Bits / Zellic) | Audit firm |
| October 2026 | First LOI signed (target: io.net) | Dmitrii Vasilev |
| October–December 2026 | License agreement negotiation and drafting | Dmitrii Vasilev + IP counsel |
| Q1 2027 (target: Feb 2027) | First license signed + upfront fee received | Dmitrii Vasilev |
| Q2 2027 | Second and third license signed | Dmitrii Vasilev |
| Q3 2027 | First royalty reporting period | Licensees |
| August 2027 | File PCT international application | IP counsel |
| Q4 2027 | Fourth license / expansion licenses to Bittensor SN etc. | Dmitrii Vasilev |

### 8.2 Critical Path Dependencies

- **Patent filing (Aug 2026)** is the hard deadline that drives outreach start (July 2026).
  Once the provisional is filed, NDAs can be lifted with potential licensees. Until then,
  NDA is mandatory on all disclosures.
- **ZK audit** must be complete before any LOI is signed. No licensee will sign without
  independent circuit audit in the post-SNARK-audit era (post-Tornado Cash circuit bug
  precedent).
- **Tape-out (Dec 2026)** is independent of licensing but enables the B1 RoT hardware
  bundle pitch to io.net and Gensyn — time this conversation for post-tape-out in 2027.

---

## 9. PATENT & IP STRATEGY

### 9.1 Core IP Assets to Protect

**Claim set 1 — Method claims:**
"A method for verifiable decentralised compute attestation comprising: (a) generating a
Groth16 zero-knowledge proof over a compute job execution trace; (b) submitting said proof
to an Ethereum-compatible blockchain for verification via the BN128 pairing check
precompile at address 0x08; (c) crediting a tokenised reward to the proving party based
on the formula [floor(min(C − bpb, 1.0) / 0.01)] where C is a champion BPB parameter
locked by protocol governance."

**Claim set 2 — System claims:**
"A system for verifiable compute attestation comprising: a ternary compute processor
executing AI workloads; a Groth16 constraint circuit mapping operator execution to
arithmetic constraints; a proving key bound to said processor's hardware attestation
module; and a verifier smart contract deployed at a deterministic address on an EVM-
compatible chain."

**Claim set 3 — Circuit architecture claims:**
Specific to the B5 circuit architecture — constraint structure, proving key generation
protocol, and the BPB reward formula binding mechanism.

### 9.2 Trade Secret Protection

Alongside patents, the following materials should be maintained as trade secrets (not
disclosed in patent applications):

- The precise constraint count and circuit depth of the B5 prover
- The key generation ceremony parameters and toxic waste disposal protocol
- Internal benchmarks beyond what is publicly disclosed
- The compiler toolchain source code (license separately or keep proprietary)

### 9.3 IP Ownership Chain

All IP is authored and owned solely by **Dmitrii Vasilev** (individual capacity) and
assigned to t27.ai (the operating entity). Before outreach:

- Confirm t27.ai corporate documents include a broad IP assignment clause
- Ensure no prior employer or contractor agreements could claim rights over any component
- Document the creation dates of all spec files (git commit history serves as timestamp
  evidence)
- Execute a formal IP assignment agreement between Dmitrii Vasilev (individual) and t27.ai

### 9.4 Patent Counsel Recommendation

Engage a US patent firm with ZK/cryptography experience. Recommended shortlist:
- Fenwick & West (Silicon Valley; strong crypto/blockchain practice)
- Cooley LLP (crypto-native; represented Coinbase, Ripple)
- Perkins Coie (strong in blockchain IP)

Budget: $15,000–$30,000 for provisional filing; $50,000–$100,000 for full national phase
applications (US + EU + UK + Singapore).

---

## 10. COLD OUTREACH EMAIL TEMPLATES

### Template A — io.net (Acquisition/License; CEO/BD)

> **Subject:** Instant ZK compute attestation for io.net — 15-min intro?
>
> Hi [Name],
>
> I'm Dmitrii Vasilev, founder of t27.ai. I've built a Groth16 ZK job prover — a
> 937-line circuit specification that produces instant, cryptographically verifiable
> proofs of AI compute jobs, verifiable via Ethereum's 0x08 precompile.
>
> io.net operates the largest decentralised GPU marketplace by FDV. The one thing your
> platform doesn't have yet is cryptographic proof of what those GPUs actually computed.
> Enterprise AI buyers — pharma, finance, defence — are starting to require this in RFPs.
>
> I'm offering a time-limited licensing window before this IP goes to patent prosecution
> and broader market. The Gensyn team is already in technical review.
>
> Would you have 15 minutes this week or next for a high-level call?
>
> Best,
> Dmitrii Vasilev
> admin@t27.ai | t27.ai

---

### Template B — Gensyn (Technical Co-Founder; ZK upgrade framing)

> **Subject:** Replacing your 12h challenge window with instant Groth16 — worth a look?
>
> Hi [Name],
>
> I'm Dmitrii Vasilev, the author of the Trinity B5 ZK Job Prover — a complete Groth16
> circuit specification (937 lines) for verifiable ML compute jobs, with an on-chain
> verifier using Ethereum's BN128 precompile (0x08).
>
> Your current architecture — optimistic challenge with a 12-hour window — is a
> technically sound scaffold, but it has known weaknesses at scale: capital lockup,
> latency, and bisection game economics. The B5 prover eliminates all three by replacing
> the challenge window with a single ZK proof per job.
>
> I'm in early licensing discussions and wanted to approach your team first given Gensyn's
> position as the only DePIN platform that takes verification seriously today.
>
> Happy to share the spec under NDA. 20-minute technical intro?
>
> Best,
> Dmitrii Vasilev
> admin@t27.ai | t27.ai

---

### Template C — Akash / Render (Defensive framing; smaller target)

> **Subject:** ZK compute attestation layer for [Akash/Render] — licensing window open
>
> Hi [Name],
>
> I'm Dmitrii Vasilev from t27.ai. I've developed the Trinity B5 ZK Job Prover: a
> complete Groth16 circuit for provable AI compute jobs, with an Ethereum-native verifier
> (precompile 0x08). It's the only production-ready ZK compute attestation layer I'm
> aware of in the DePIN space.
>
> I'm running a limited licensing process — a few of the larger DePIN platforms are
> already in technical review. I wanted to reach out to [Akash/Render] before the
> exclusive field-of-use windows close.
>
> Adding ZK attestation to [Akash/Render] opens the door to enterprise compute buyers who
> currently can't use a network without cryptographic job verification. This is a
> meaningful revenue expansion, not just a technical feature.
>
> Would 15 minutes make sense to see if there's a fit?
>
> Best,
> Dmitrii Vasilev
> admin@t27.ai | t27.ai

---

## APPENDIX A — GLOSSARY

| Term | Definition |
|---|---|
| Groth16 | A succinct non-interactive zero-knowledge proof system; produces proofs verifiable in constant time regardless of circuit size |
| BN128 | Barreto-Naehrig elliptic curve used in Groth16; natively supported by Ethereum precompile 0x08 |
| 0x08 precompile | Ethereum's built-in BN128 pairing check; costs ~180k gas; the cheapest on-chain ZK verifier available |
| Optimistic challenge | A dispute resolution mechanism where results are assumed valid unless challenged within a time window; Gensyn uses a 12-hour window |
| BPB | Bits-per-byte; a compression-based proxy metric for language model quality; lower is better |
| Champion BPB | 2.2393 — the baseline BPB locked by the Trinity protocol; provers must beat this to earn TRI rewards |
| TRI | Trinity protocol native token; earned by provers at rate floor(min(2.2393 − bpb, 1.0) / 0.01) per proof, capped at 100 TRI |
| RoT | Root-of-Trust; hardware security module that binds cryptographic operations to authenticated silicon |
| DePIN | Decentralised Physical Infrastructure Network; protocols that coordinate real-world hardware (compute, storage, bandwidth) via blockchain incentives |
| FDV | Fully Diluted Valuation; total token supply × current token price |
| GMV | Gross Merchandise Value; total transaction value flowing through a platform |
| LOI | Letter of Intent; non-binding preliminary agreement establishing deal framework |
| PCT | Patent Cooperation Treaty; enables filing a single international patent application covering 150+ member countries |

---

## APPENDIX B — DOCUMENT CONTROL

| Field | Value |
|---|---|
| Author | Dmitrii Vasilev (sole author) |
| Contact | admin@t27.ai |
| Organisation | t27.ai |
| Version | 1.0 |
| Date | June 2026 |
| Classification | INTERNAL — NOT FOR PUBLIC DISTRIBUTION |
| Distribution | Dmitrii Vasilev only |
| Review date | September 2026 (prior to first outreach) |
| Dependencies | docs/v1.1/ ZK Job Prover spec (937 lines), Trinity protocol tokenomics document |

---

*This document contains proprietary commercial strategy, non-public pricing, and
confidential IP descriptions. Unauthorised disclosure may constitute a breach of
fiduciary duty and/or applicable trade secret law. All IP described herein is the sole
property of Dmitrii Vasilev / t27.ai.*

*— Dmitrii Vasilev, admin@t27.ai*
