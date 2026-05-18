# BUYER MATRIX & PRIORITIZATION
## Trinity TRI-NET TT SKY26b / TTSKY26c — Master Sales Strategy

**CLASSIFICATION: INTERNAL — NOT FOR DISTRIBUTION**
**Author:** Dmitrii Vasilev (sole author, admin@t27.ai), t27.ai
**Last Updated:** 2026-05-14
**Horizon:** May 2026 – Q4 2027

---

## TABLE OF CONTENTS

1. [Executive Summary — 4-Phase Kill-Chain](#1-executive-summary)
2. [Tier A — Act Now (1–3 Month Cycle)](#2-tier-a)
   - 2.1 Bittensor Subnet Operators
   - 2.2 DARPA I2O Office-Wide BAA
   - 2.3 Gensyn / io.net IP License
3. [Tier B — Strategic Pipeline (3–12 Month Cycle)](#3-tier-b)
   - 3.1 Helium Network
   - 3.2 Defence Contractors (Anduril / Skydio / Shield AI)
   - 3.3 Edge AI OEMs (Pi / Hailo / Coral)
4. [Tier C — Case-Study Driven (12–24+ Month Cycle)](#4-tier-c)
   - 4.1 Financial Regulators / Banks (EU AI Act 2026)
   - 4.2 Healthcare AI (FDA SaMD)
   - 4.3 Web3 Identity (Worldcoin Alternative via B8 DID)
5. [Prioritization Matrix Table](#5-prioritization-matrix)
6. [6-Month Kill-Chain — Phase Playbook](#6-kill-chain)
7. [Resource Allocation & Hire Pattern](#7-resource-allocation)
8. [Honest Reality Check](#8-reality-check)
9. [Reference Index — Pitch Doc Locations](#9-reference-index)

---

## 1. EXECUTIVE SUMMARY

### Situation

Trinity TRI-NET (TT SKY26b) is a DePIN-optimized silicon platform integrating hardware attestation, B-module inference, and on-chain verification. The tape-out closes **2026-05-19 06:59 +07** (SKY26b shuttle). The next iteration, **TTSKY26c**, is expected **September 2026** with full DePIN B-module support. Physical chip arrival is forecast **Q4 2026 (~December)**.

This document structures the entire commercial attack surface into three buyer tiers, a scored priority matrix, and a 4-phase kill-chain. It is designed for a solo PI operating with zero sales headcount until late 2026.

### 4-Phase Kill-Chain Summary

| Phase | Window | Primary Objective | Expected Output |
|-------|--------|------------------|-----------------|
| **Phase 1** | May–Jun 2026 | Tape-out closure + federal money + crypto-pilot | DARPA LOI, 3 Bittensor validators, 1 Gensyn meeting |
| **Phase 2** | Jul–Aug 2026 | Network expansion + first revenue signal | 10 validators live, Helium intro meeting, term sheet drafts |
| **Phase 3** | Sep–Dec 2026 | TTSKY26c + defence + OEM | Full B-module demo, 2 NDAs with defence, 1 OEM PoC |
| **Phase 4** | 2027 | Capital event or strategic acquisition or token launch | Series A / strategic / TGE |

### Critical Dates to Lock In Calendar

- `2026-05-19 06:59 +07` — SKY26b shuttle HARD CLOSE. No missed tape-out.
- `2026-06-15` (target) — DARPA I2O BAA submission window (verify FedBizOpps)
- `2026-07-01` — First Bittensor validator milestone review
- `2026-09-01` — TTSKY26c submission target
- `2026-Q4` — Chip arrival; first silicon demos to OEMs and defence
- `2027-Q1` — Series A or strategic M&A process kick-off

---

## 2. TIER A — ACT NOW (1–3 MONTH CYCLE)

> Tier A buyers have the shortest conviction-to-close cycle, most immediate budget availability, and strongest product-market fit with current TT SKY26b capabilities. All three should be in active motion **this week**.

---

### 2.1 Bittensor Subnet Operators

**Priority Rank: #1 — Market-Ready Today**

#### Why This Wins First

Bittensor subnet operators are already spending real money ($500–$2K per chip equivalent) on inference hardware. The TAM for Trinity attestation across 1,000 validators is **$640K–$2.5M**. This is not a pilot — validators have budget, deployment timelines, and direct on-chain accountability. Trinity's hardware attestation closes the trust gap that software-only approaches (TEEs, TLS) cannot.

#### Buyer Profile

| Attribute | Detail |
|-----------|--------|
| Decision-maker | Subnet owner / lead validator operator |
| Budget source | Subnet TAO emissions / validator staking rewards |
| Purchase trigger | Compliance with metagraph scoring criteria, competitive differentiation |
| Typical org size | 1–5 engineers, occasionally DAO-governed |
| Procurement cycle | 2–6 weeks once demo is live |

#### TAM Model

```
Conservative:  200 validators × $800/chip  = $160K ARR
Base case:     500 validators × $1,000/chip = $500K ARR
Bull case:     1,000 validators × $2,000/chip = $2M ARR
```

This does not include recurring attestation SaaS fees, which could add 15–30% on top.

#### Specific Targets (Research Updated Weekly)

1. **Subnet 1 (Text Prompting)** — largest by volume; validator operators include institutional stakers
2. **Subnet 3 (Mycelium / Temporal) & Subnet 9 (Pretrain)** — compute-intensive, cost-sensitive
3. **Taoshi (Subnet 8)** — financial inference, compliance-motivated buyers
4. **Macrocosmos (Subnet 9, Apex)** — DePIN-native, technically sophisticated
5. **Corcel** — cross-subnet aggregator, single relationship unlocks many validators

#### Kill Actions (This Week)

- [ ] Post technical attestation explainer on Bittensor Discord (TensorBot / #validator-chat)
- [ ] Reach out to top-5 subnet owners via Discord DM with 2-sentence hook + pilot offer
- [ ] Publish 1-page integration spec: "Trinity attestation for Bittensor validators"
- [ ] Offer: **first 10 validators get free hardware + 3-month technical onboarding at cost**
- [ ] Set up simple public dashboard showing validator attestation status (trust signal)

#### Risks

- Bittensor governance is messy; metagraph changes can alter validator economics overnight
- Competition from software-only attestation (cheaper, already deployed)
- Validators are price-sensitive; need to demonstrate TAO emission uplift via higher trust scores

#### Success Metric (Phase 1 close): 3 validators running Trinity attestation by 2026-07-01

---

### 2.2 DARPA I2O Office-Wide BAA

**Priority Rank: #2 — Federal Money, Highest Single-Check Potential**

#### Why This Wins Second

DARPA Information Innovation Office (I2O) runs persistent Broad Agency Announcements that accept proposals on a rolling basis. Grant range: **$2M–$10M** for hardware-accelerated AI security primitives. Trinity's DePIN attestation stack maps directly to I2O program areas: distributed trust, AI assurance, hardware-rooted security.

This is not a fast close — but a submitted proposal in June 2026 can yield Phase I award by Q4 2026, coinciding perfectly with chip arrival.

#### Buyer Profile

| Attribute | Detail |
|-----------|--------|
| Decision-maker | Program Manager (PM) at I2O; BAA Coordinator |
| Budget source | Congressional appropriations, not discretionary |
| Purchase trigger | Alignment with active program area + white-paper resonance |
| Procurement cycle | 90–180 days from submission to Phase I award |
| Award type | Cost-plus contract (SBIR Phase I/II) or direct BAA contract |

#### Target Programs (Priority Order)

1. **I2O Office-Wide BAA (HR001123S0045 or current successor)** — broadest acceptance, least restrictive
2. **AISS (AI Security for Sensitive Systems)** — if active, perfect fit
3. **GARD (Guaranteeing AI Robustness Against Deception)** — hardware attestation angle
4. **SBIR Phase I via DARPA** — lower bar, $250K, proof-of-concept framing

#### Proposal Framing

> "Trinity TRI-NET provides the first silicon-rooted, cryptographically verifiable attestation layer for distributed AI inference nodes. Unlike software TEEs, the Trinity B-module produces hardware-bound proofs that cannot be spoofed by OS-level compromise, VM escape, or supply-chain substitution. This enables DARPA to fund the first field-deployable 'zero-trust inference fabric' for contested-environment AI."

Key technical hooks for reviewers:
- Hardware root of trust (vs. software-only TEE)
- Post-quantum signature compatibility (flag this even if partial)
- Open-standard proof format (ZK-friendly attestation receipts)
- DePIN as a model for resilient, decentralized inference in denied environments

#### Action Plan

| Week | Action |
|------|--------|
| Week 1 (now) | Pull current I2O BAA text from SAM.gov / FedConnect |
| Week 2 | Draft 2-page white paper aligned to I2O program language |
| Week 3 | Request PM call via DARPA BAA inquiry mechanism (no cold email — use formal channel) |
| Week 4 | Submit full technical volume + cost estimate |
| Jun 15 target | Full proposal submitted |

#### Budget Realism

- Phase I SBIR: $250K–$500K (fast, low-friction, 6-month period)
- Phase II SBIR: $1.5M–$2M (follow-on, 2-year)
- Direct BAA contract: $2M–$10M (requires more credibility/partners)

**Recommendation:** Start with SBIR Phase I framing. Faster. Builds track record. Phase II unlocks larger contracts.

#### Risks

- Requires US entity or formal US partnership (verify t27.ai corporate structure)
- DARPA PMs rotate; need to find current I2O PM with matching program area
- Highly competitive; success rates are ~10–15% for first-time proposers

#### Success Metric (Phase 1 close): Full proposal submitted by 2026-06-15

---

### 2.3 Gensyn / io.net IP License

**Priority Rank: #3 — Highest Deal Value Potential in Tier A**

#### Why This Wins Third

Gensyn and io.net are the two largest decentralized compute platforms actively solving the "how do you verify a node ran the job correctly" problem. Trinity's hardware attestation is a direct answer. IP licensing (vs. chip sales) can unlock **$5M–$50M** deal structures: upfront license fee + per-proof royalty + equity/token component.

This is a sophisticated B2B deal requiring relationship-building, but the buyer motivation is strong — both companies have raised significant capital and need to solve verification at scale to IPO or token-launch credibly.

#### Buyer Profiles

**Gensyn**
- Raised ~$43M Series A (2023); building ML compute verification
- CEO: Ben Fielding; CTO: Harry Grieve
- Core problem: "how do you know a GPU actually ran a training job?"
- Trinity fit: hardware attestation at the chip level closes their verification gap

**io.net**
- $30M raised; GPU network for AI/ML workloads
- CEO: Ahmad Shadid (note: verify current leadership after 2024 controversies)
- Core problem: GPU provenance and job completion verification
- Trinity fit: B-module attestation as trust layer for io.net's supplier network

#### Deal Structure Options

| Structure | Upfront | Recurring | Equity/Token | Notes |
|-----------|---------|-----------|--------------|-------|
| Full IP license | $5–15M | $0 | Optional | Cleanest; buyer owns implementation |
| Technology access license | $500K–2M | $0.01–0.10/proof | Optional | Preferred; scales with their growth |
| Joint venture / co-development | $1–5M | Rev share | 2–5% | Longest negotiation |
| Acquisition (strategic M&A) | $20–50M+ | N/A | 100% exit | Phase 4 path |

**Recommended approach:** Technology access license with per-proof royalty. Aligns incentives. Scales automatically.

#### Cold Outreach Strategy

Do NOT cold email via generic channels. Approach:

1. **Twitter/X technical post** — publish a thread on "hardware attestation for decentralized compute" tagging relevant researchers (not founders directly). Let signal come inbound.
2. **Mutual investors/advisors** — identify shared angels or VCs between t27.ai and Gensyn/io.net; warm intro is 10× more effective
3. **Conference presence** — DePIN Summit, ETH global, NVIDIA GTC side events
4. **Technical pre-print** — arXiv paper on Trinity attestation methodology creates credibility that cold emails cannot

#### Kill Actions (Next 30 Days)

- [ ] Identify 3 mutual connections between t27.ai and Gensyn via LinkedIn
- [ ] Draft 1-page technical brief: "How Trinity closes the verification gap in decentralized ML"
- [ ] Post technical Twitter thread with attestation proof-of-concept
- [ ] Target: one Gensyn engineering contact meeting within 45 days

#### Risks

- Both companies may build in-house solutions (not likely at this stage but possible)
- io.net credibility issues post-2024; evaluate carefully before prioritizing
- IP licensing deals require clean IP chain — ensure all Trinity IP is properly documented and assigned to t27.ai

#### Success Metric (Phase 1 close): 1 NDA signed with either Gensyn or io.net by 2026-07-15

---

## 3. TIER B — STRATEGIC PIPELINE (3–12 MONTH CYCLE)

> Tier B buyers have strong product fit but longer procurement cycles, more stakeholders, or require additional proof points (silicon arrival, case studies, regulatory triggers). Begin relationship-building now; expect closes in H2 2026 or H1 2027.

---

### 3.1 Helium Network

**Priority Rank: #4**

#### Overview

Helium is the largest deployed DePIN network globally (1M+ hotspots). The Helium Foundation controls network parameters and has historically funded hardware suppliers. Trinity's attestation layer provides what Helium has never had: cryptographic proof of device location, uptime, and honest coverage reporting. This directly addresses Helium's ongoing "gaming" problem.

#### Revenue Scenarios

| Scenario | Description | Deal Size |
|----------|-------------|-----------|
| **H1 — Protocol integration** | Trinity attestation becomes optional layer for Helium hotspot operators | $5M–$15M protocol integration fee + royalties |
| **H2 — Foundation grant** | Helium Foundation co-funds Trinity integration as R&D initiative | $500K–$2M |
| **H3 — Hardware mandate** | Helium mandates Trinity-class attestation for all new hotspots post-2027 | $50M–$200M TAM (200K new hotspots × $250/unit) |

**Realistic near-term:** H2 (Foundation grant) is achievable in 6–9 months. H1 requires more negotiation. H3 is 2027+ and depends on Helium protocol governance vote.

#### Key Contacts

- Helium Foundation: foundation@helium.com (public)
- Nova Labs (now Helium-acquired): technical leadership
- Target entry: Helium Discord #hardware-integrations channel

#### Kill Actions (Phase 2: Jul–Aug)

- [ ] Join Helium Improvement Proposal (HIP) discussion on hotspot attestation
- [ ] Draft HIP proposal co-authored with a known community member
- [ ] Request Foundation intro via shared DePIN ecosystem contacts
- [ ] Present at Helium community call

#### Success Metric: First Foundation meeting by 2026-08-01

---

### 3.2 Defence Contractors — Anduril / Skydio / Shield AI

**Priority Rank: #5**

#### Overview

These three companies represent the new-generation defence primes with genuine AI/edge hardware procurement. Unlike traditional primes (Lockheed, Raytheon), they move fast, understand DePIN-style distributed architectures, and have procurement teams that can sign NDAs in days rather than months.

| Company | Product Focus | Trinity Use Case | Deal Size | Cycle |
|---------|--------------|-----------------|-----------|-------|
| **Anduril** | Autonomous systems, Lattice OS | Edge AI attestation for drone/sensor nodes | $2–10M | 12–18 mo |
| **Skydio** | Autonomous drones | On-device inference attestation, secure flight logs | $1–5M | 12–24 mo |
| **Shield AI** | Autonomous pilots (HERON) | Hardware-rooted AI decision logging | $1–3M | 18–24 mo |

#### Entry Strategy

Defence procurement is relationship-gated. Approaches:

1. **SBIR/STTR co-submission** — propose as technology partner on a DARPA SBIR; Anduril or Shield AI may be prime contractor
2. **AFWERX and DIU pathways** — Defence Innovation Unit runs "Commercial Solutions Opening" (CSO) — faster than FAR procurement
3. **Conference: AUSA / DoDIIS / SOFWERX** — targeted trade shows where these buyers actively scout

#### Risks

- ITAR/EAR export control: Trinity silicon may require licensing if sold to US defence contractors (verify with counsel)
- Foreign PI sensitivity: Dmitrii Vasilev's background may complicate security clearance pathway for some programmes
- Long diligence cycles even with fast-movers like Anduril

#### Kill Actions (Phase 3: Sep–Oct)

- [ ] Identify Anduril's Lattice OS integration team via LinkedIn
- [ ] Submit DIU Commercial Solutions Opening (CSO) application
- [ ] Prepare 2-page capability brief framed for contested-environment AI integrity
- [ ] Legal review: ITAR classification of Trinity B-module

#### Success Metric: 2 NDAs signed with defence contractors by 2026-12-31

---

### 3.3 Edge AI OEMs — Raspberry Pi / Hailo / Coral (Google)

**Priority Rank: #6**

#### Overview

Edge AI OEM partnerships serve two purposes: (a) distribution leverage — embedding Trinity attestation into millions of devices; (b) reference design revenue — OEM pays for integration engineering and per-unit royalty.

| OEM | Scale | Revenue Model | Realistic Size | Timeline |
|-----|-------|--------------|----------------|----------|
| **Raspberry Pi** | 60M+ units sold; new Pi AI HAT | Reference design + per-unit royalty | $100K–$500K | 9–12 mo |
| **Hailo** | ~2M chips shipped; AI-8 series | Co-marketing + integration | $200K–$800K | 9–18 mo |
| **Coral (Google)** | Embedded in Google ecosystem | Google partnership pathway | $500K–$1M (if adopted) | 12–24 mo |

#### Entry Strategy

- Hailo: direct BD contact (they are small enough to reach); target VP of Business Development
- Raspberry Pi: approach via Cambridge, UK; they are more accessible than perceived
- Coral: requires Google partnership programme; longer path but highest scale

#### Kill Actions (Phase 3: Oct–Nov)

- [ ] Draft "Trinity Attestation HAT" reference design spec for Raspberry Pi
- [ ] Contact Hailo's BD via LinkedIn with technical brief post-silicon-arrival
- [ ] Target: 1 OEM PoC agreement by 2026-12-31

---

## 4. TIER C — CASE-STUDY DRIVEN (12–24+ MONTH CYCLE)

> Tier C buyers are high-value but require regulatory triggers, external proof points, or market maturity that does not exist yet. Begin seeding narratives and relationship-building now, but do not invest sales bandwidth until Phase 3 or Phase 4.

---

### 4.1 Financial Regulators / Banks — EU AI Act 2026 Compliance

**Priority Rank: #7**

#### Overview

The EU AI Act classifies certain AI systems as "high risk" and mandates auditability, traceability, and robustness requirements effective **August 2026** (for GPAI model providers) and **August 2027** (for high-risk system deployers). Banks deploying AI for credit scoring, fraud detection, and AML are in scope.

Trinity's hardware attestation provides a tamper-evident audit trail for AI inference — exactly what Article 9 (Risk Management) and Article 17 (Quality Management) require.

#### Target Buyer Types

- **Tier 1 EU banks**: BNP Paribas, Deutsche Bank, ING — AI compliance officers
- **Fintech compliance platforms**: Behavox, NICE Actimize — resell Trinity as a compliance module
- **EU AI Act compliance consultancies**: EY, Deloitte, KPMG AI practices — channel partners

#### Deal Size: $500K–$5M per enterprise bank deployment

#### Why This Is Tier C (Not B)

- Banks are the slowest procurement cycles on earth (18–36 months)
- Compliance timelines are uncertain; enforcement delayed historically
- Banks need vendor track record and third-party audits Trinity does not yet have
- **Seed now (Q3 2026)**: publish EU AI Act compliance white paper; speak at RegTech conferences

---

### 4.2 Healthcare AI — FDA Software as a Medical Device (SaMD)

**Priority Rank: #8**

#### Overview

FDA's SaMD guidance (Q-Submission pathway, 510(k), De Novo) increasingly requires AI model traceability and auditability. Trinity's attestation layer could become a mandatory component in SaMD deployment stacks for Class II/III devices.

#### Target Buyers

- AI-native medical device companies: Viz.ai, Aidoc, Subtle Medical
- Hospital networks deploying AI diagnostics: Mayo Clinic, Cleveland Clinic AI labs
- Medtech primes: Siemens Healthineers, Philips Healthcare

#### Deal Size: $200K–$2M per SaMD deployment; potential for FDA-mandated inclusion in standards

#### Why This Is Tier C

- FDA SaMD landscape is extremely slow and heavily regulated
- Trinity needs clinical validation partnerships before any FDA pathway
- **Minimum viable seed (2026)**: co-author a white paper with a university medical AI lab

---

### 4.3 Web3 Identity — Worldcoin Alternative via B8 DID

**Priority Rank: #9**

#### Overview

Worldcoin's approach to human identity verification (iris scan → World ID) is facing regulatory backlash globally. Trinity's B8 DID module offers a hardware-bound decentralized identity alternative without biometric centralization. As Worldcoin bans accelerate in EU/UK/India, a credible alternative emerges.

#### Market Opportunity

- Global DID market: $5B+ by 2030 (various estimates)
- Immediate opportunity: EU Digital Identity Wallet (eIDAS 2.0) standards opening
- Web3 ecosystem: 50M+ wallets needing sybil-resistant identity

#### Target Partners

- **ENS / Ethereum Name Service** — DID integration
- **Lens Protocol** — decentralized social identity
- **EU eIDAS 2.0 pilot consortia** — government-funded, grants available
- **Gitcoin Passport** — already doing hardware-based sybil resistance work

#### Why This Is Tier C

- Requires TTSKY26c B8 DID module to be production-ready (Sep 2026+)
- Market is fragmented; standards are not settled
- **Seed now**: publish B8 DID technical spec; engage ENS / Gitcoin community

---

## 5. PRIORITIZATION MATRIX

> Scoring methodology: Cycle speed (1–5), Deal size (1–5), Fit with current capability (1–5), Solo PI execution feasibility (1–5). Max score = 20. Weighted: Fit × 2, Cycle × 1.5, others × 1.

| Rank | Target | Cycle | Deal Size | Fit (now) | Complexity | Weighted Score | ⭐ |
|------|--------|-------|-----------|-----------|------------|----------------|---|
| 1 | Bittensor subnet operators | 1–3 mo | $640K–$2.5M | ★★★★★ | Low | **18.5/20** | ⭐⭐⭐⭐⭐ |
| 2 | DARPA I2O BAA | 3–6 mo | $250K–$10M | ★★★★☆ | Medium | **16.0/20** | ⭐⭐⭐⭐½ |
| 3 | Gensyn/io.net IP License | 2–4 mo | $5M–$50M | ★★★★☆ | Medium | **15.5/20** | ⭐⭐⭐⭐½ |
| 4 | Helium Network | 6–9 mo | $500K–$200M | ★★★★☆ | Medium-High | **13.5/20** | ⭐⭐⭐⭐ |
| 5 | Defence (Anduril/Skydio/Shield AI) | 12–24 mo | $1M–$10M each | ★★★☆☆ | High | **11.0/20** | ⭐⭐⭐½ |
| 6 | Edge AI OEMs (Pi/Hailo/Coral) | 9–18 mo | $100K–$1M | ★★★☆☆ | Medium | **10.5/20** | ⭐⭐⭐ |
| 7 | Financial Regulators / Banks | 18–36 mo | $500K–$5M | ★★☆☆☆ | Very High | **7.5/20** | ⭐⭐ |
| 8 | Healthcare AI / FDA SaMD | 24–36 mo | $200K–$2M | ★★☆☆☆ | Very High | **6.5/20** | ⭐⭐ |
| 9 | Web3 Identity / B8 DID | 12–24 mo | $1M–$10M | ★★★☆☆ | High | **9.0/20** | ⭐⭐½ |

### Score Interpretation

- **18–20**: Activate immediately, weekly cadence
- **14–17**: Active pipeline, monthly cadence
- **10–13**: Seeding phase, quarterly check-in
- **<10**: Monitor only, no active bandwidth until Phase 4

---

## 6. 6-MONTH KILL-CHAIN — PHASE PLAYBOOK

### Phase 1: May–June 2026
**"Secure the tape-out. Start the money pipeline."**

**North Star:** Don't miss the shuttle. Start two revenue streams in parallel.

#### Week-by-Week

| Week | Priority | Action | Owner | Done? |
|------|----------|--------|-------|-------|
| W1 (May 13–19) | **CRITICAL** | Verify TT SKY26b tape-out files submitted by 2026-05-19 06:59 +07 | Dmitrii | [ ] |
| W1 | Tier A | Post Bittensor attestation explainer; DM top-5 subnet owners | Dmitrii | [ ] |
| W2 | Tier A | Pull DARPA I2O current BAA from SAM.gov; draft white paper outline | Dmitrii | [ ] |
| W2 | Tier A | Draft Trinity-Gensyn 1-page technical brief | Dmitrii | [ ] |
| W3 | Tier A | DARPA: request PM meeting via official channel | Dmitrii | [ ] |
| W3 | Tier A | Bittensor: schedule first validator pilot call | Dmitrii | [ ] |
| W4 | Tier A | Gensyn/io.net: identify warm intro path via mutual investors | Dmitrii | [ ] |
| W5 | Tier A | Submit DARPA SBIR Phase I outline (pre-submission inquiry) | Dmitrii | [ ] |
| W6 | Tier A | First Bittensor validator running Trinity attestation (pilot) | Dmitrii | [ ] |
| W6 | Tier A | Gensyn/io.net: first engineering contact meeting | Dmitrii | [ ] |
| W7–8 | Tier A | DARPA: full proposal draft complete + submitted | Dmitrii | [ ] |
| W8 | Tier B | Helium: identify community advocate; draft HIP | Dmitrii | [ ] |

**Phase 1 Hard Deliverables:**
- [ ] SKY26b tape-out confirmed submitted
- [ ] DARPA BAA proposal submitted
- [ ] 1+ Bittensor validator running attestation pilot
- [ ] 1 NDA or meeting booked with Gensyn or io.net

---

### Phase 2: July–August 2026
**"Validate the DePIN use case. Start enterprise conversations."**

**North Star:** Reach 10 live validators. Create the first revenue-confirming signal.

#### Key Actions

| Action | Target Date | Success Indicator |
|--------|-------------|-------------------|
| Scale Bittensor pilots from 3 to 10 active validators | Jul 15 | 10 validators live on-chain |
| Publish public attestation dashboard | Jul 1 | Dashboard URL shared in Bittensor Discord |
| First Helium Foundation meeting | Aug 1 | Calendar invite confirmed |
| Gensyn: move from intro to term sheet discussion | Aug 15 | NDA signed |
| DARPA: respond to any reviewer questions | Jul–Aug | Maintain proposal activity |
| Defence: identify Anduril/Shield AI contact targets | Aug 31 | 3 LinkedIn connections with BD/technical staff |
| Produce first Trinity attestation case study | Aug 31 | Public blog post or PDF |

**Phase 2 Hard Deliverables:**
- [ ] 10 Bittensor validators using Trinity attestation
- [ ] Helium Foundation intro meeting held
- [ ] 1 term sheet discussion in progress (Gensyn or io.net)
- [ ] First public case study published

---

### Phase 3: September–December 2026
**"Submit TTSKY26c. Close enterprise pilots. Receive first silicon."**

**North Star:** TTSKY26c submission with full B-modules. First silicon in hand. First enterprise PoC.

#### Key Actions

| Action | Target Date | Success Indicator |
|--------|-------------|-------------------|
| Submit TTSKY26c to shuttle | Sep 1 | Submission confirmed |
| B-module documentation complete | Sep 15 | Public spec + datasheet |
| First defence pitch (Anduril priority) | Oct 1 | Meeting held; NDA under review |
| OEM negotiations (Hailo priority) | Oct–Nov | LOI or PoC agreement |
| DARPA Phase I award decision | Oct–Nov (if submitted Jun) | Award or pass decision |
| Chip arrival (SKY26b) | Dec 2026 | Physical silicon received |
| First silicon demo to OEM / defence contact | Dec 31 | Demo held; feedback documented |
| EU AI Act compliance white paper published | Nov 30 | White paper live; presented at 1 RegTech event |
| B8 DID technical spec published | Oct 31 | Spec published; Gitcoin/ENS engagement started |

**Phase 3 Hard Deliverables:**
- [ ] TTSKY26c submitted
- [ ] 2 defence contractor NDAs signed
- [ ] 1 OEM PoC agreement
- [ ] Physical SKY26b silicon received
- [ ] First silicon demo executed

---

### Phase 4: 2027
**"Capital event, scale, or exit."**

This phase is conditional on Phase 1–3 outcomes. Three plausible paths:

#### Path A: Series A Fundraise

**Trigger:** 50+ validators live, DARPA Phase II in progress, 1 enterprise PoC delivering revenue
- Target: $8M–$20M Series A
- Lead investors: Paradigm, a16z crypto, Lux Capital (defence-adjacent), Andreessen Horowitz Bio (if healthcare angle)
- Narrative: "The trust layer for distributed AI — hardware-rooted, crypto-native, defence-ready"

#### Path B: Strategic Acquisition

**Trigger:** Gensyn or io.net IP license deal signed; interest from Nvidia, Qualcomm, or Arm
- Target valuation: $30M–$100M depending on revenue multiple and silicon differentiation
- Process: hire M&A advisor (Lazard, Qatalyst for tech M&A) in Q1 2027
- Note: acquisition of a solo PI company with a novel chip is unusual — requires clear IP assignment and no side-door dependencies

#### Path C: Token / TGE

**Trigger:** Bittensor validator adoption reaching 100+; DePIN token model proven by Helium/io.net
- TGE structure: Trinity attestation credits as utility token; validators stake for priority access
- Legal: Cayman Foundation + Singapore wrapper (standard DePIN structure)
- Note: most complex path; requires 6 months of legal/tokenomics work; do not start before Series A is decided against

**Phase 4 Recommendation:** Pursue Path A as primary. Keep Path C optionality alive via Bittensor validator community growth. Path B is opportunistic — do not engineer for it.

---

## 7. RESOURCE ALLOCATION & HIRE PATTERN

### Current State: Solo PI Bottleneck

As sole author and PI, Dmitrii Vasilev is simultaneously:
- Silicon architect / tape-out owner
- Sales lead for all 9 buyer categories
- Grant writer (DARPA)
- Community manager (Bittensor/Helium)
- IP documentation owner (Gensyn licensing prerequisite)

This is **not sustainable past Phase 2**. The bottleneck will show up in missed meetings, slow proposal response times, and shallow relationship development.

### Bandwidth Allocation Recommendation (Now)

| Activity | Hours/Week | Priority |
|----------|-----------|----------|
| Tape-out (hardware) | 20h | **Non-negotiable until May 19** |
| Bittensor community + pilots | 8h | Tier A |
| DARPA proposal writing | 10h | Tier A |
| Gensyn/io.net outreach | 4h | Tier A |
| Everything else (Tier B/C) | 4h | Seeding only |
| **Total** | **46h** | **— over capacity —** |

**Immediate action:** Defer all Tier B/C active work until Phase 2. Zero hours on defence, OEMs, or Web3 identity until DARPA and Bittensor have traction.

### Hire Pattern — Phase-Gated

**Phase 1 (now):** No hire. Use fractional resources only:
- **Grant writer / SBIR specialist** (contractor): $3–5K for DARPA proposal polish. High ROI.
- **Technical writer** (contractor): $1–2K for Bittensor integration docs and white papers

**Phase 2 (Jul–Aug 2026):** First hire trigger — if Bittensor pilots succeed and DARPA proposal is through:
- **Hire #1: Business Development / Partner Manager**
  - Profile: 3–5 years enterprise B2B, ideally hardware + crypto crossover
  - Focus: Helium relationship, Gensyn negotiation, OEM intro meetings
  - Salary range: $90K–$130K + equity; or revenue-share contractor if budget constrained
  - Location: Remote (US preferred for DARPA interactions)

**Phase 3 (Sep–Dec 2026):** Second hire trigger — if silicon arrives and defence pitch gains traction:
- **Hire #2: Defence / Federal Sales Specialist**
  - Profile: Ex-DARPA, DIU, or prime contractor BD; US citizen with clearance eligibility
  - Focus: Anduril / Shield AI relationship; SBIR Phase II; DIU CSO applications
  - Salary range: $130K–$180K + equity
  - Note: This hire unlocks the highest-value but most gated revenue stream

**Phase 4 (2027):** Third hire — Finance / Investor Relations for Series A process

### What NOT to Hire

- Do not hire a general-purpose sales rep — Trinity requires deep technical selling
- Do not hire a marketing generalist — owned media (Twitter/arXiv) outperforms at this stage
- Do not hire a dedicated regulatory/compliance person until a bank or healthcare deal is imminent

---

## 8. HONEST REALITY CHECK

> This section deliberately separates signal from noise. The matrix scores above are based on fit, not probability. Here is the unvarnished view.

### Deals Most Likely to Close (2026)

**High Confidence (>60% probability):**

| Deal | Why Likely |
|------|------------|
| Bittensor validator pilots (3–10 validators) | Product-market fit is real; budget is small; community is reachable; no procurement committee |
| DARPA SBIR Phase I (if submitted) | SBIR is designed for solo PIs / early companies; $250K is low enough to win without connections; proposal quality is the gating factor |

**Medium Confidence (30–60%):**

| Deal | Why Medium |
|------|------------|
| Gensyn NDA / technical partnership | Strong fit; but Gensyn may be building in-house; deal depends on warm intro quality |
| Helium Foundation grant | Foundation has funded hardware R&D before; but governance is unpredictable; requires community buy-in |
| 1 Edge AI OEM PoC | Hailo is most reachable; but depends on chip delivery and quality |

### Stretch Goals (10–30%)

| Deal | What Would Have to Go Right |
|------|---------------------------|
| DARPA direct BAA contract ($2M+) | Requires Phase I win + PM relationship + Phase II submission; 18-month path |
| io.net IP licensing | io.net credibility and focus uncertain post-2024; leadership change risk |
| Anduril NDA | Requires ITAR clearance, US entity, and warm intro into a notoriously closed BD process |

### Moonshots (<10% in 2026, possible in 2027+)

| Deal | Why Moonshot |
|------|-------------|
| Bank / EU AI Act compliance deal | Banks are 36-month procurement cycles minimum; no track record yet |
| FDA SaMD integration | Requires clinical partners, FDA Q-sub meetings, and years of validation data |
| Strategic acquisition ($30M+) | Possible only after Series A credibility + revenue traction; not before |
| Worldcoin-replacement at scale | Market is fragmented; B8 DID not yet production-ready; standards race still open |

### Failure Modes to Watch

1. **Tape-out quality issues** — if SKY26b silicon has yield or functionality problems, every downstream deal is delayed 6–9 months. Contingency: have TTSKY26c scope ready to accelerate.
2. **DARPA proposal rejected** — do not treat federal money as certain. Contingency: resubmit to NSF SBIR; approach In-Q-Tel as alternative intelligence-adjacent funder.
3. **Bittensor network governance change** — a metagraph update could eliminate the economic incentive for hardware attestation. Contingency: ensure Trinity value proposition is protocol-agnostic.
4. **Gensyn/io.net raises and builds in-house** — if either company hires a chip team, the IP licensing window closes. Contingency: publish Trinity attestation as open standard + charge for certification, not the IP itself.
5. **Solo PI burnout** — the biggest operational risk. No deal closes if the PI is incapacitated. Contingency: hire BD contractor in Phase 2 even if budget is tight.

### The One Honest Sentence

> Of the $640M+ TAM theoretically addressable by this matrix, a realistic 2026 outcome is **$300K–$1M in total revenue** (Bittensor pilots + DARPA Phase I), with the $5M–$50M deals (Gensyn, Helium, defence) maturing in 2027 if Phase 1–2 execute cleanly.

---

## 9. REFERENCE INDEX — PITCH DOCUMENT LOCATIONS

> All pitch documents live under `docs/sales/` in the t27.ai repository. This index is the authoritative map.

### Master Documents

| Document | Location | Status | Last Updated |
|----------|----------|--------|-------------|
| This document (Buyer Matrix) | `docs/sales/BUYER_MATRIX_PRIORITIZATION.md` | ✅ Active | 2026-05-14 |
| Trinity TRI-NET Overview | `docs/sales/TRINITY_OVERVIEW.md` | Maintain | — |
| IP Asset Register | `docs/legal/IP_ASSET_REGISTER.md` | Critical for licensing | — |
| Corporate Structure (ITAR check) | `docs/legal/CORPORATE_STRUCTURE.md` | Required before defence | — |

### Tier A Pitch Packs

| Document | Location | Target | Notes |
|----------|----------|--------|-------|
| Bittensor Integration Spec | `docs/sales/tierA/BITTENSOR_INTEGRATION_SPEC.md` | Subnet operators | 1-page + technical appendix |
| Bittensor Pilot Offer Letter | `docs/sales/tierA/BITTENSOR_PILOT_OFFER.md` | Top-5 subnet owners | Free pilot terms |
| DARPA I2O White Paper | `docs/sales/tierA/DARPA_I2O_WHITE_PAPER.md` | I2O Program Manager | 2 pages; SBIR Phase I framing |
| DARPA SBIR Phase I Proposal | `docs/sales/tierA/DARPA_SBIR_PHASE1_PROPOSAL.md` | DARPA BAA office | Full proposal; to be drafted |
| Gensyn/io.net Technical Brief | `docs/sales/tierA/GENSYN_IONET_TECHNICAL_BRIEF.md` | Engineering leads | 1-page; attestation gap analysis |
| Gensyn/io.net IP License Term Sheet | `docs/sales/tierA/GENSYN_LICENSE_TERM_SHEET.md` | BD/legal leads | Draft only; not shared until NDA |

### Tier B Pitch Packs

| Document | Location | Target | Notes |
|----------|----------|--------|-------|
| Helium HIP Draft | `docs/sales/tierB/HELIUM_HIP_DRAFT.md` | Helium community + Foundation | Co-author with community member |
| Helium Foundation Grant Brief | `docs/sales/tierB/HELIUM_FOUNDATION_BRIEF.md` | Foundation team | H2 scenario framing |
| Defence Capability Brief | `docs/sales/tierB/DEFENCE_CAPABILITY_BRIEF.md` | Anduril / Shield AI BD | 2-page; contested-environment framing |
| DIU CSO Application | `docs/sales/tierB/DIU_CSO_APPLICATION.md` | Defence Innovation Unit | To be drafted Phase 3 |
| Hailo Integration Proposal | `docs/sales/tierB/HAILO_INTEGRATION_PROPOSAL.md` | Hailo BD | Post-silicon-arrival |
| Raspberry Pi Reference Design | `docs/sales/tierB/RASPI_REFERENCE_DESIGN.md` | Pi commercial team | Technical spec + market case |

### Tier C Seed Documents

| Document | Location | Target | Notes |
|----------|----------|--------|-------|
| EU AI Act Compliance Brief | `docs/sales/tierC/EU_AI_ACT_BRIEF.md` | Banks / compliance officers | Publish Q3 2026 |
| B8 DID Technical Specification | `docs/sales/tierC/B8_DID_SPEC.md` | ENS / Gitcoin / eIDAS pilots | Publish Oct 2026 |
| FDA SaMD Positioning Paper | `docs/sales/tierC/FDA_SAMD_POSITIONING.md` | Medical AI companies | Low priority until Phase 4 |

### Supporting Assets

| Asset | Location | Purpose |
|-------|----------|---------|
| Trinity Attestation Case Study (v1) | `docs/sales/assets/CASE_STUDY_V1.md` | Social proof for all tiers |
| Public Attestation Dashboard Spec | `docs/engineering/ATTESTATION_DASHBOARD_SPEC.md` | Trust signal for Bittensor |
| arXiv Pre-Print Draft | `docs/research/TRINITY_ATTESTATION_PREPRINT.md` | Credibility for Gensyn/DARPA |
| Investor One-Pager | `docs/sales/assets/INVESTOR_ONE_PAGER.md` | Phase 4 fundraise |

---

## APPENDIX A — KEY DATES CALENDAR

```
2026-05-19 06:59 +07  ██ TT SKY26b TAPE-OUT CLOSE (HARD DEADLINE)
2026-06-15            ▶ DARPA BAA proposal submitted (target)
2026-07-01            ▶ Bittensor Pilot Review: 3 validators live
2026-07-15            ▶ Gensyn/io.net: NDA signed (target)
2026-08-01            ▶ Helium Foundation: first meeting
2026-08-15            ▶ Gensyn/io.net: term sheet discussion
2026-08-31            ▶ Bittensor: 10 validators live; case study published
2026-09-01            ▶ TTSKY26c shuttle submission (target)
2026-10-01            ▶ Defence pitch: Anduril priority
2026-10-31            ▶ B8 DID spec published
2026-Q4 (~Dec)        ██ SKY26b silicon arrives
2026-12-31            ▶ 2 defence NDAs; 1 OEM PoC; first silicon demo
2027-Q1               ▶ Series A process kick-off (if milestones met)
```

---

## APPENDIX B — SCORING METHODOLOGY DETAIL

Weighted score formula:
```
Score = (Fit × 2) + (Cycle_Speed × 1.5) + Deal_Size_Score + (1 / Complexity_Score)
```

Where:
- **Fit**: 1–5, current product capability alignment with buyer need
- **Cycle_Speed**: 5 = closes in <3 months; 1 = closes in >24 months
- **Deal_Size_Score**: 1–5, $100K = 1; $1M = 2; $5M = 3; $20M = 4; $50M+ = 5
- **Complexity_Score**: 1 (low) to 5 (very high), inverse weight

This methodology intentionally rewards deals that can close fast with current capability over large but speculative future deals.

---

*Document classification: INTERNAL — NOT FOR DISTRIBUTION*
*Author: Dmitrii Vasilev (sole author, admin@t27.ai), t27.ai*
*Next review: 2026-07-01 (Phase 2 kick-off)*
