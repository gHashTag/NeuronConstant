# Trinity TRI-NET × Helium Network
## Integration & Partnership Proposal

**Author:** Dmitrii Vasilev (sole author, admin@t27.ai), t27.ai  
**Document status:** Public-facing proposal draft  
**Target:** Nova Labs / Helium Foundation / Helium Mobile  
**Date:** 2025  

---

> *This document is authored solely by Dmitrii Vasilev. All projections and benchmarks are honest estimates based on current hardware development status.*

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Helium's Known Gaps](#2-heliums-known-gaps)
3. [Trinity Solution Overview](#3-trinity-solution-overview)
4. [Engagement Scenarios](#4-engagement-scenarios)
   - [H1 — IP License Deal](#h1--ip-license-deal)
   - [H2 — Co-Marketing Module](#h2--co-marketing-module)
   - [H3 — Acquisition by Nova Labs](#h3--acquisition-by-nova-labs)
5. [Technical Integration Paths](#5-technical-integration-paths)
6. [Revenue Model](#6-revenue-model)
7. [Timeline](#7-timeline)
8. [Honest Reality Check](#8-honest-reality-check)
9. [Comparison with Helium's Existing PoC Mechanism](#9-comparison-with-heliums-existing-poc-mechanism)
10. [Call to Action](#10-call-to-action)

---

## 1. Executive Summary

Helium Network is one of the most ambitious decentralized wireless infrastructure projects in existence. With over 100,000 active hotspots globally, a live 5G network, a T-Mobile roaming partnership, and a fully on-chain reward economy running on Solana, Helium has achieved what many considered impossible: a community-built, economically self-sustaining wireless network.

Yet Helium's growth to its next phase — enterprise IoT contracts, large-scale 5G data offload, and institutional-grade reliability — is constrained by a single unresolved problem: **trusted hardware attestation at the edge**.

The question every enterprise buyer and every skeptical network auditor eventually asks is: *"How do I know that hotspot is real, that it is where it says it is, and that it is actually serving coverage — not simulating it?"* Helium's existing Proof-of-Coverage (PoC) mechanism provides a probabilistic, economic answer. What it cannot provide is a *cryptographic, hardware-rooted* answer.

**Trinity TRI-NET**, developed by Dmitrii Vasilev at t27.ai, is a verifiable AI hardware platform built on a novel ternary compute architecture. Trinity's two most immediately applicable modules are:

- **B1 — Hardware Root of Trust (HW RoT):** An on-chip, hardware-enforced identity and attestation layer that signs all device claims with keys that cannot be extracted or spoofed in software.
- **B2 — Proof-of-Bandwidth Attestation:** A module that cryptographically attests to real data throughput, generating tamper-resistant proofs of actual coverage delivery — not self-reported metrics.

Together, these modules transform a Helium hotspot from a *self-asserted* node into a *cryptographically verifiable* node. Every coverage claim, every bandwidth event, every location assertion becomes a signed, on-chain-publishable proof anchored to physical silicon — not software that can be emulated, virtualized, or spoofed.

This proposal outlines three partnership paths — a focused IP licensing arrangement, a co-marketed hardware add-on module for existing hotspot operators, and a full acquisition scenario — each calibrated to Helium's current strategic priorities and go-to-market reality. All scenarios are presented with honest technical benchmarks, realistic timelines, and honest risk acknowledgment.

The goal is not to replace what Helium has built. It is to harden it.

---

## 2. Helium's Known Gaps

### 2.1 The Sybil Problem: A Decade of Cat and Mouse

Helium's PoC mechanism was a genuine breakthrough. By requiring hotspots to witness each other's beacons and by randomizing challenger selection, it made large-scale network simulation costly and detectable. In the early network (2019–2022), PoC was effective enough. The economic incentives were modest, and sophisticated gaming required infrastructure investment that reduced profitability.

That changed as HNT appreciation made hotspot rewards meaningful. By 2021–2022, "gaming farms" — clusters of collocated hotspots configured to falsely witness one another — became one of the dominant forms of reward fraud on the network. Estimates from community analysts and the Helium Foundation's own denylist processes suggest that at peak periods, a non-trivial fraction of reward-eligible hotspots were engaged in some form of gaming behavior, from modest location spoofing to fully synthetic witness rings.

Nova Labs, DeWi Alliance, and the Helium Foundation have invested significant engineering effort into detection heuristics: density-based reward scaling, the denylist, geographic clustering analysis, and the migration to oracle-based PoC validation (PoC v10+). These measures substantially reduced the most egregious gaming. They did not eliminate it, and they cannot eliminate it structurally, because they remain software-layer defenses against a fundamentally software-layer attack.

**The root cause is architectural**: Helium's trust model is economic, not cryptographic at the hardware level. A hotspot manufacturer can produce devices with standard cryptographic identities (ECC keypairs in secure elements), but there is no standard mechanism for a hotspot to prove:

1. It is running an unmodified firmware stack.
2. Its location claim reflects a physical measurement, not a software assertion.
3. Its reported wireless activity reflects real RF interactions, not simulated traffic.
4. The device itself has not been cloned, virtualized, or had its keys extracted to a farm server.

This is not a criticism of Helium's engineering choices — these are hard, unsolved problems in distributed systems. It is an accurate description of the attack surface that remains.

### 2.2 Enterprise IoT: The Trust Threshold Problem

Helium IoT (previously LoRaWAN-based, now increasingly multi-protocol) has achieved impressive sensor coverage in many urban markets. The network's open, permissionless model is its greatest strength for grassroots deployment and its greatest obstacle for enterprise procurement.

Enterprise IoT buyers — logistics companies, utilities, smart city operators, healthcare infrastructure providers — operate under compliance frameworks (ISO 27001, SOC 2, FedRAMP adjacent, sector-specific regulations) that require demonstrable chain of custody for data and verifiable device identity. When a procurement officer at a major utility asks "Can you certify the integrity of the network nodes handling our sensor data?", the honest answer today is: *not in a way that satisfies a formal audit*.

This is not a fatal objection for consumer-grade IoT applications. It is a disqualifying objection for the enterprise contracts that represent Helium's most significant untapped revenue potential.

### 2.3 5G and T-Mobile: The Reliability Expectations Gap

The T-Mobile roaming partnership represents Helium's most significant commercial validation. It also raises the stakes considerably. T-Mobile's network SLAs and the expectations of their subscribers set a reliability and accountability bar that differs qualitatively from a token-incentivized IoT network.

As Helium Mobile scales its MVNO/MNO operations and as 5G data offload volumes grow, the pressure to demonstrate that hotspot coverage metrics reflect real, reliable infrastructure increases. Gaming a beacon in an IoT context means some sensor packets don't route correctly. Gaming 5G coverage metrics means a paying mobile subscriber gets a degraded experience — with contractual and regulatory consequences.

The infrastructure that underlies Helium's T-Mobile relationship needs to be more auditable, not less, as the network matures.

### 2.4 The Missing Trusted Execution Environment

For Helium to support enterprise AI inference workloads — an increasingly discussed use case as edge AI demand grows — hotspot nodes need a trusted execution environment (TEE) where computations can be verified. Today's hotspot hardware (various ARM-based SBCs, CBRS radios) has no standardized TEE, no attestable compute substrate, and no mechanism for an enterprise customer to verify that an inference result was produced by a specific model on a specific, unmodified device.

This closes off an entire category of potential revenue: verified edge AI inference as a service running on top of existing Helium coverage infrastructure.

---

## 3. Trinity Solution Overview

### 3.1 What Trinity TRI-NET Is

Trinity TRI-NET is a hardware-first verifiable compute platform built around a novel ternary (base-3) logic architecture. The core TT SKY26b shuttle chip implements ternary processing at silicon level, achieving an approximate performance profile of:

> **~1 GOPS @ ~50 MHz @ ~1W (ternary operations, projected)**

These are honest projected benchmarks based on current design status — not marketing figures. The ternary architecture is not positioned as a general-purpose compute replacement for binary silicon. It is positioned for specific workloads where the ternary instruction set provides architectural advantages: compressed model inference, entropy-efficient signing operations, and hardware-enforced state machines for attestation protocols.

The TRI-NET platform is not a single chip. It is a modular hardware architecture organized into functional blocks (B-modules) that can be licensed, integrated, or deployed independently depending on the partner's needs.

### 3.2 B1 — Hardware Root of Trust

The B1 module implements a hardware root of trust with the following properties:

**Identity Anchoring:** Each B1 chip instance is provisioned with a device identity at manufacturing time. The private key associated with this identity is generated on-chip, never exported, and physically protected against side-channel extraction by the ternary architecture's non-standard voltage and timing signatures (which defeat standard power analysis attacks calibrated for binary CMOS).

**Attestation Signing:** All device assertions — location claims, bandwidth reports, uptime proofs, firmware version attestations — are signed by the B1 module's hardware key. Software running on the host processor cannot forge or modify these signatures.

**Firmware Integrity Measurement:** B1 implements a measured boot chain. Each boot phase is measured and the cumulative measurement is included in attestation signatures. A hotspot running modified firmware produces attestations that are cryptographically distinguishable from a hotspot running certified firmware — even if the attacker controls the host OS.

**Anti-Clone Protection:** The B1 identity cannot be cloned to another device. A farm of virtual hotspots sharing a single B1 identity would produce signatures that are detectable as single-device (identical hardware fingerprints, identical measurement chains). A farm trying to use multiple B1 chips would require procuring and provisioning multiple physical chips — restoring the economic cost that made early gaming unprofitable.

### 3.3 B2 — Proof-of-Bandwidth Attestation

The B2 module addresses the specific challenge of attesting to real wireless activity:

**Hardware-Level Traffic Witnessing:** B2 sits in the data path between the hotspot's radio hardware and its processing stack. It observes actual packet flows at hardware level — not through software instrumentation that can be spoofed. It generates signed throughput proofs that include packet count, timing, signal characteristics, and radio parameter metadata.

**Zero-Knowledge Bandwidth Proofs:** B2 is designed to generate bandwidth attestations in a ZK-compatible format. The full packet contents are not disclosed in the proof — only the cryptographic summary of activity, the signing timestamp, and the hardware attestation signature. This preserves user privacy while providing verifiable coverage proof.

**Location Binding:** B2 attestations can incorporate GPS-derived or RF-derived location data, signed at the hardware level. A spoofed GPS signal would require physical presence of a GPS simulator — a meaningfully higher attack cost than a software location override.

**Solana-Compatible Proof Format:** B2 proofs are designed for on-chain publication to Solana. Each proof is a compact, verifiable data structure that can be submitted as a Solana transaction, stored in a program account, and verified by on-chain logic or off-chain oracles without requiring the full packet-level data.

### 3.4 B8 — Decentralized Identity and Personhood

The B8 module extends the B1 identity layer with a Decentralized Identifier (DID) framework:

**W3C DID Compliance:** B8 generates device DIDs conformant with the W3C DID specification, making Trinity-attested devices interoperable with the broader decentralized identity ecosystem (Veramo, Spruce, etc.).

**Personhood Attestation for Hotspot Operators:** Beyond device identity, B8 can bind a hotspot's hardware identity to its operator's DID — providing a cryptographic link between a physical device and a verified human operator. This is relevant for Helium's sybil resistance at the operator level: not just "is this a real device?" but "is this operated by a distinct real entity?"

**Verifiable Credential Issuance:** B8 supports the issuance of Verifiable Credentials (VCs) — for example, a credential attesting that a device has maintained certified uptime for a given period, or that it has served a minimum data volume. These VCs can be presented to enterprise customers as machine-readable compliance evidence.

### 3.5 TT SKY26b Shuttle Chip

The TT SKY26b is the current silicon instantiation of Trinity's ternary compute substrate. It is a shuttle chip — meaning it occupies a shared wafer run for development and early validation purposes. Key characteristics:

- Ternary logic at silicon level (not emulated on binary substrate)
- Approximate performance: ~1 GOPS at ~50 MHz in ternary operations (projected)
- Power envelope: approximately 1W under load (projected)
- Physical form factor suitable for embedded integration in hotspot hardware
- Designed for future integration into standard hotspot PCB designs

The shuttle form factor is honestly appropriate for the current stage of development. It represents a real, working silicon implementation — not a simulation or FPGA emulation — but it is a development vehicle, not a production-optimized chip. A production-optimized variant would be part of any licensing or integration roadmap.

---

## 4. Engagement Scenarios

Three distinct partnership structures are proposed, ordered from lowest integration depth to highest. Each scenario is designed to be independently viable; they are not sequential steps. Helium and Nova Labs should select the scenario that matches their current strategic and operational capacity.

---

### H1 — IP License Deal

#### Overview

Nova Labs licenses the B1 Hardware Root of Trust and B2 Proof-of-Bandwidth Attestation module IP from t27.ai. Nova Labs integrates these modules into next-generation Helium hotspot hardware designs developed and manufactured through their existing supply chain. Trinity provides the IP, specification documentation, reference HDL, and integration engineering support. Nova Labs owns the manufacturing relationship, the hotspot product, and the go-to-market.

This scenario requires the lowest organizational integration and the shortest path to market for Nova Labs. It is also the scenario most consistent with Nova Labs' historical approach: define the hardware specification, certify reference designs, and let the ecosystem build.

#### Value Proposition for Nova Labs

- Helium gains a credible answer to the sybil/trusted hardware question without building attestation silicon from scratch
- B1+B2 IP becomes part of the certified hotspot hardware specification for next-generation devices
- PoC v11+ (or successor) can incorporate B1/B2 attestations as a higher-trust proof tier, potentially enabling differentiated reward rates for attested vs. unattested hotspots
- Enterprise sales team gains a concrete, auditable answer to the "how do you certify your network?" question
- T-Mobile partnership gets a stronger long-term foundation as CBRS and 5G offload volumes grow

#### Value Proposition for t27.ai

- IP licensing revenue (upfront fee + royalties on HNT-related revenue from attested hotspot tiers)
- Credibility validation: Trinity silicon running in a live, 100,000+ node network is the most powerful commercial reference possible
- Preserved autonomy: t27.ai remains an independent entity, continuing TRI-NET development for other verticals

#### Commercial Structure

- Upfront IP license fee (range: low-to-mid six figures USD, depending on scope)
- Per-unit royalty on certified hotspot hardware incorporating B1/B2 (range: low single-digit percentage of hardware BOM cost)
- Optional: Revenue-sharing on incremental HNT rewards attributable to the attested hotspot tier
- Support and integration engineering: time-and-materials or fixed-fee milestone structure

No exact figures are provided in this public document. Full commercial terms are available under NDA.

#### What This Is Not

This scenario does not give Nova Labs exclusivity on Trinity IP across all markets. Exclusivity within the Helium ecosystem (defined as Helium-branded hotspot hardware and Helium Network PoC applications) can be negotiated for a defined period. Trinity retains rights to license B1/B2 to other decentralized wireless networks, enterprise IoT platforms, and non-competing verticals.

---

### H2 — Co-Marketing Module

#### Overview

Trinity develops and markets the **DevKit Pro** — a hardware add-on module incorporating B1+B2 functionality, designed to attach to existing Helium hotspot hardware via standard interfaces (USB, PCIe M.2, or GPIO depending on hotspot model). Helium/Nova Labs co-markets the DevKit Pro as an official upgrade path for existing hotspot operators, providing a second revenue stream: verified edge AI inference.

This scenario does not require Nova Labs to redesign hotspot hardware. It works with the installed base. It creates a new economic incentive for hotspot operators — not just coverage rewards, but AI inference revenue — while simultaneously improving the network's trust posture.

#### The Second Revenue Stream Narrative

Hotspot operators today earn HNT rewards for coverage and data transfer. The DevKit Pro pitch to operators is:

> *"Your hotspot is already running 24/7. Add the DevKit Pro module and your hotspot becomes a verified AI inference node. Enterprises and developers pay to run inference tasks on your device. Your B1 chip signs every inference result, making it verifiable. You earn inference revenue in addition to your existing HNT rewards."*

This narrative is aligned with broader trends in the DePIN (Decentralized Physical Infrastructure Network) ecosystem, where multi-revenue-stream nodes are increasingly valued by operators.

#### Technical Add-On Design

The DevKit Pro module would include:
- TT SKY26b ternary compute element (for inference workloads)
- B1 Hardware Root of Trust (for device identity and attestation signing)
- B2 Bandwidth Attestation logic (for PoC trust upgrade)
- B8 DID module (for operator identity binding)
- Local flash storage for model weights (operator-loaded or protocol-assigned)
- Power draw designed to stay within existing hotspot power budget (target: under 3W added load)

#### Value Proposition for Helium Ecosystem

- Existing hotspot operators gain a hardware upgrade path with tangible economic upside
- Network gains verified attestation capability without full hardware generation turnover
- Nova Labs gains a revenue share opportunity from DevKit Pro sales and/or inference marketplace transaction fees
- Helium Mobile and IoT divisions gain an auditable trust layer deployable on the existing installed base
- New demand signal: enterprises and AI inference consumers start routing workloads to Helium-adjacent infrastructure

#### Value Proposition for t27.ai

- Direct hardware product revenue (DevKit Pro sales)
- Marketplace/inference transaction revenue share
- Large-scale real-world deployment proving ternary inference viability
- Co-marketing validation from Helium brand association

#### Commercial Structure

- DevKit Pro hardware sales (range: low-to-mid three figures USD per unit, depending on production volume)
- Revenue sharing on inference marketplace transactions routed through DevKit Pro nodes
- Co-marketing agreement: joint press releases, Helium ecosystem promotion, DevKit Pro listing in Nova Labs official upgrade catalog
- Nova Labs optional equity stake in t27.ai's inference marketplace operation in exchange for go-to-market commitment

#### Operator Economics (Illustrative)

A hotspot operator with consistent coverage and a DevKit Pro module could expect:

- Existing HNT coverage/data rewards: unchanged (potentially improved if attested hotspots receive reward bonuses)
- Inference revenue: variable, dependent on demand. Even modest inference demand — a few thousand inference calls per day — at competitive per-inference pricing represents meaningful additional monthly revenue for an operator running a well-connected node.

Specific revenue projections depend on inference market pricing dynamics that cannot be predicted with precision today. This is stated honestly: the inference revenue stream is a realistic opportunity, not a guaranteed income figure.

---

### H3 — Acquisition by Nova Labs

#### Overview

Nova Labs acquires t27.ai and integrates Trinity TRI-NET as the foundational hardware attestation and AI inference layer of the **Helium AI Network** strategy. Dmitrii Vasilev joins Nova Labs as a principal engineer or VP-level role leading the hardware attestation and edge AI product line. The full TRI-NET technology stack — B1 through B8 modules, the TT SKY26b silicon design, and the ternary compute roadmap — becomes part of Helium's core infrastructure technology portfolio.

This scenario represents the deepest integration and the highest strategic upside for both parties — and the highest execution complexity.

#### Strategic Rationale

Nova Labs is not just a hotspot company. Its long-term positioning in the DePIN ecosystem depends on owning defensible technology moats. Spectrum access (via CBRS) is one moat. Economic incentive design (HNT tokenomics) is another. A third moat — verifiable hardware attestation at scale — is currently absent and represents a significant competitive vulnerability as other DePIN networks mature.

Acquiring Trinity gives Nova Labs:

1. **Proprietary silicon IP** — a unique hardware differentiation that competitors cannot simply replicate by copying open-source software
2. **A credible AI narrative** — ternary inference at the edge is a genuine technical differentiator as edge AI demand grows, and it comes with a concrete chip design, not a whitepaper
3. **The engineering capability** to develop next-generation verified hotspot hardware in-house, reducing dependence on third-party certified hardware manufacturers
4. **B8 DID/personhood infrastructure** — a foundational layer for Helium Mobile's user identity and anti-fraud stack

#### What Acquisition Includes

- Full transfer of t27.ai IP: TRI-NET architecture, B1/B2/B8 module designs, TT SKY26b HDL and shuttle results, ternary compute toolchain
- Dmitrii Vasilev joining Nova Labs full-time
- Ongoing R&D capability for production-optimized Trinity silicon (next chip generation targeting higher GOPS, lower power)
- Trinity's existing partnerships, development relationships, and any pilot deployments at time of acquisition

#### Commercial Structure

- Acquisition price: range not disclosed in this public document. Full financial terms under NDA. Structure likely includes upfront cash/equity component plus milestone-based earnout tied to product integration achievements (e.g., B1+B2 integration in certified hotspot hardware within defined timeframe, inference marketplace launch, attested hotspot tier activation)
- Earnout milestones aligned with Nova Labs' roadmap priorities: incentive structure ensures Trinity IP delivers measurable value before full consideration is paid

#### Risks and Honest Assessment

This scenario is the highest-complexity and longest-timeline path. Key risks:

- **Integration complexity:** Merging a single-PI hardware research project into a larger engineering organization requires careful IP transfer, knowledge documentation, and role definition. Underestimating this complexity is a common acquisition failure mode.
- **Chip maturity:** The TT SKY26b is a shuttle chip. A production deployment at Helium scale requires a production-optimized chip. The timeline to production silicon is real and should be factored into acquisition valuation and earnout structure.
- **Organizational fit:** Dmitrii Vasilev is the sole deep expert on Trinity's architecture. Retention and knowledge transfer planning are critical due diligence items.
- **DePIN market timing:** Helium's current strategic focus is on T-Mobile partnership execution and Helium Mobile growth. An acquisition that distracts from those priorities is net-negative regardless of the technology's merit.

These risks are stated because they are real. An acquisition that proceeds with clear eyes on these factors has a much higher probability of success than one driven by enthusiasm for the technology alone.

---

## 5. Technical Integration Paths

### 5.1 H1 IP License — Technical Integration

#### Chip Placement

In the H1 scenario, B1+B2 IP is integrated by Nova Labs' hardware partners (e.g., RAK Wireless, Bobcat, or a new reference design manufacturer) into next-generation hotspot PCBs. The B1 module sits as a secure element companion to the hotspot's main application processor — analogous to the role played by existing secure elements (ATECC608 or similar) in current certified hotspot designs, but with significantly expanded attestation capability and the ternary compute substrate.

Recommended placement:
- B1: Standalone IC on main PCB, connected to application processor via SPI or I2C. Serves as hardware keystore and attestation engine.
- B2: Integrated with or adjacent to the radio subsystem. For LoRa hotspots: inline with SX1303/SX1250 chipset data path. For CBRS/5G hotspots: inline with the small cell radio unit's backhaul interface.

#### Signing Flow

1. Hotspot performs PoC activity (beacon transmission, witness reception, data transfer)
2. B2 module observes RF activity at hardware level, generates timestamped activity record
3. B1 module signs the activity record with device private key, appends firmware measurement hash
4. Signed attestation is serialized into compact proof structure
5. Application processor packages proof for on-chain submission

#### On-Chain Proof Publishing to Solana

Helium's migration to Solana provides a natural publication layer. B1+B2 attestation proofs are published as:

- **Option A (Direct):** Helium PoC oracle accepts B1+B2 signed proofs as a higher-trust proof tier in the existing oracle architecture. Oracles verify the hardware signature before forwarding to on-chain reward calculation.
- **Option B (Program Account):** A Helium-deployed Solana program accepts signed attestation proofs directly from hotspots via their Solana keypair. Proofs stored in program-derived accounts (PDAs), queryable by the PoC oracle and by enterprise customers.
- **Option C (IBC Bridge / Wormhole):** If future Helium architecture incorporates cross-chain elements, B1+B2 proofs can be routed via Wormhole or similar cross-chain messaging to non-Solana verification layers.

Option A requires the least architectural change and is recommended for initial integration. Options B and C become relevant as enterprise customers require direct on-chain proof access.

### 5.2 H2 Co-Marketing Module — Technical Integration

#### DevKit Pro Attachment Interface

The DevKit Pro module must be compatible with the hardware interfaces available on existing, deployed hotspots. Given the diversity of the Helium hotspot ecosystem, a tiered interface strategy is required:

- **Tier 1 (USB-C):** Universal compatibility. Lowest bandwidth, sufficient for attestation data volumes. Works with any hotspot that exposes a USB host port.
- **Tier 2 (M.2 2242/2280):** Higher bandwidth, lower latency, better for AI inference workloads. Compatible with hotspot designs that include an M.2 slot (several enterprise-grade hotspot models).
- **Tier 3 (GPIO/SPI):** Deepest integration for custom builds and future hotspot designs incorporating DevKit Pro as a design element from inception.

For the initial co-marketing launch, Tier 1 (USB-C) is recommended for maximum installed-base compatibility, with Tier 2 support added for the subset of hotspots where it is applicable.

#### Signing and Inference Flow

**Attestation path:**
1. DevKit Pro B1 module enrolls as companion identity to the hotspot's existing Helium identity keypair
2. All PoC-relevant events that the host hotspot reports are co-signed by the B1 companion key
3. The PoC oracle (or a companion oracle) recognizes B1 co-signed proofs as attested-tier, enabling differentiated reward treatment

**Inference path:**
1. Inference request arrives via Helium Data Credits / AI inference marketplace protocol (new or existing)
2. Request is routed to the DevKit Pro's TT SKY26b ternary compute element
3. Inference executes in the Trinity TEE
4. Result is signed by B1 hardware key, creating a verifiable inference attestation
5. Signed result returned to requester; attestation published on-chain for auditability

#### On-Chain Proof Publishing for H2

The H2 scenario introduces a new proof type: inference attestation. Publication options:

- A new Solana program (deployed by t27.ai or jointly with Nova Labs) accepts inference attestations, linking them to hotspot identity, operator DID (B8), and reward accounting
- Existing Helium reward oracles can be extended to recognize and reward verified inference service provision
- Enterprise customers can query the Solana program for auditable inference receipts (relevant for compliance-sensitive applications)

### 5.3 H3 Acquisition — Technical Integration

In the H3 scenario, integration planning is driven by Nova Labs' internal engineering roadmap. The technical paths described in H1 and H2 both become available and are executed with full internal resource commitment rather than arms-length IP licensing.

Additional technical priorities under H3:

**Next-generation hotspot chip design:**
Nova Labs' hardware team, augmented by Dmitrii Vasilev, initiates design of a production-optimized Trinity SoC that integrates B1+B2+B8 with a CBRS radio management subsystem and Solana signing accelerator. Target: single-chip solution for the Helium 2027 hotspot generation.

**Helium AI Network protocol design:**
B8 DID infrastructure becomes the foundation for a Helium AI Network protocol: a standardized framework for requesting, routing, executing, and verifying AI inference across the Helium hotspot fleet. This protocol would be published as an open standard, positioning Helium as the infrastructure layer for decentralized edge AI — not just decentralized wireless coverage.

**Oracle integration:**
Trinity attestation data feeds directly into Helium's Solana-based oracle infrastructure. The oracle architecture is extended to differentiate reward tiers based on attestation quality: unattested (existing), software-attested (current certified hardware), and hardware-attested (Trinity B1+B2). This creates a natural upgrade incentive across the hotspot operator community.

---

## 6. Revenue Model

Revenue projections are presented as ranges rather than point estimates. The precise figures depend on HNT market conditions, hotspot deployment velocity, enterprise adoption timelines, and factors that cannot be predicted with precision at this stage. All ranges are intended to be realistic, not optimistic.

### H1 IP License Revenue Model

| Revenue Stream | Range |
|---|---|
| Upfront IP license fee | Low-to-mid six figures USD |
| Per-unit royalty (certified hotspot hardware) | Low single-digit % of hardware BOM |
| Attested-tier reward share (optional) | Subject to separate negotiation |
| Integration engineering support | Time-and-materials or fixed milestone |

**Scale dependency:** Royalty revenue is meaningful only at volume. At 10,000 new certified hotspot units incorporating B1+B2 IP, per-unit royalties at the low end of the range represent modest revenue. At 100,000+ units — consistent with Helium's current base and growth trajectory — royalty revenue becomes a significant recurring income stream. The upfront fee provides immediate value regardless of deployment scale.

### H2 Co-Marketing Module Revenue Model

| Revenue Stream | Range |
|---|---|
| DevKit Pro hardware unit sales | Low-to-mid three figures USD per unit |
| Inference marketplace transaction fees | Low single-digit % of gross inference revenue |
| Nova Labs co-marketing revenue share | Subject to separate negotiation |
| Enterprise inference SLA subscriptions | Mid-four to low-five figures USD/year per enterprise |

**Scale dependency:** The DevKit Pro business is viable at relatively modest adoption rates within the Helium operator community. Even a small fraction of the 100,000+ hotspot operator base purchasing DevKit Pro modules represents a meaningful hardware revenue event. Inference revenue grows with AI workload demand — a factor that is directionally very positive but impossible to precisely predict.

### H3 Acquisition Revenue Model

In the acquisition scenario, t27.ai's revenue streams are absorbed into Nova Labs' consolidated financials. The value creation model shifts from licensing/product revenue to:

- Strategic value: hardware differentiation enabling Helium to win enterprise IoT contracts that are currently not closeable
- Network economics: attested hotspot tier enables premium reward mechanics and data credit pricing
- AI inference marketplace: new revenue stream for the Helium ecosystem and for Nova Labs as marketplace operator
- Defensible IP: proprietary silicon IP protects Helium's competitive position against DePIN competitors

An acquisition valuation range is not disclosed in this public document. It reflects the combined value of the IP, the team, the demonstrated traction (see Section 8 on Bittensor pilot), and the strategic option value of the ternary compute roadmap.

---

## 7. Timeline

### H1 — IP License Deal

| Phase | Duration | Milestones |
|---|---|---|
| Term sheet and NDA | Month 1–2 | Signed NDA, preliminary commercial terms agreed |
| Technical due diligence | Month 2–4 | Nova Labs hardware team reviews B1/B2 IP, TT SKY26b results, integration feasibility |
| License agreement execution | Month 4–5 | Final terms signed, IP transfer package delivered |
| Reference design integration | Month 5–9 | Nova Labs or partner manufacturer integrates B1+B2 IP into reference hotspot design |
| Certified hotspot prototype | Month 9–12 | First certified hotspot with B1+B2 integration, Helium PoC oracle extended for attested-tier |
| **Pilot deployment** | **Month 12** | Small-scale attested hotspot deployment, on-chain proof publication live |

Total timeline: **6–12 months** from first substantive discussions to initial pilot deployment.

### H2 — Co-Marketing Module

| Phase | Duration | Milestones |
|---|---|---|
| Partnership agreement | Month 1–3 | Co-marketing terms agreed, DevKit Pro spec finalized |
| DevKit Pro engineering | Month 3–8 | PCB design, firmware, Solana integration, USB/M.2 interface validation |
| Alpha hardware | Month 8–10 | Alpha DevKit Pro units, tested against top 3 hotspot models by installed base |
| Helium ecosystem review | Month 10–12 | Nova Labs / Helium Foundation technical review, co-marketing materials prepared |
| Public launch | Month 12–15 | DevKit Pro publicly available, Nova Labs co-marketing active |
| Inference marketplace beta | Month 15–18 | First enterprise inference customers, on-chain inference attestation live |

Total timeline: **12–18 months** from agreement to full deployment.

### H3 — Acquisition

| Phase | Duration | Milestones |
|---|---|---|
| Initial discussions and NDA | Month 1–2 | Signed NDA, strategic intent confirmed |
| Technical due diligence | Month 2–5 | Full IP audit, chip design review, codebase review, team assessment |
| Financial due diligence | Month 3–5 | Valuation modeling, earnout structure negotiation |
| Legal and regulatory | Month 5–8 | Acquisition agreement, IP transfer, employment agreements |
| Close | Month 8–10 | Transaction closed, Dmitrii Vasilev joins Nova Labs |
| Integration and first product | Month 10–18 | First Nova Labs product incorporating Trinity IP (H1 or H2 path, now executed internally) |

Total timeline: **12–18 months** from first discussions to close and initial product integration, consistent with standard deep-tech acquisition due diligence timelines.

---

## 8. Honest Reality Check

### 8.1 What Helium Will Actually Ask

Nova Labs and the Helium Foundation are pragmatic organizations. They have shipped real hardware, deployed a real network, navigated a complex migration from a proprietary blockchain to Solana, and managed the operational complexity of a 100,000+ node distributed infrastructure. They are not impressed by whitepapers. They are impressed by:

1. **Working silicon.** Does this chip actually exist and function? The TT SKY26b shuttle is a real chip. Demonstrating it physically — showing signed attestations from actual hardware — is the baseline credibility requirement.

2. **A proof of traction.** A single pilot deployment in a related DePIN context is worth more in a Nova Labs due diligence conversation than any amount of speculative analysis. This is why the Bittensor pilot is critical.

3. **An honest answer to 'what does it cost?'** Nova Labs has run hotspot manufacturing programs. They understand BOM sensitivity. A B1+B2 module that adds significant cost per unit will face significant headwinds in a commodity hardware market. The ternary architecture's low power envelope (~1W projected) is favorable from a cost perspective; the shuttle chip economics need to be translated into production cost projections before the conversation gets serious.

4. **An honest answer to 'what does your team look like?'** A sole-PI project is a concentrated key-person risk. Nova Labs will ask about this. The honest answer is: yes, Trinity is currently a sole-PI project. The acquisition scenario (H3) directly addresses this. The licensing scenarios (H1, H2) require a credible plan for support engineering capacity that doesn't depend entirely on one person.

### 8.2 The Bittensor Pilot as Traction Proof

The recommended pre-Helium engagement strategy is to close a Bittensor pilot first. Bittensor's subnet architecture is a natural first deployment context for Trinity's verifiable AI inference:

- Bittensor miners are already incentivized to run inference workloads
- A subnet specifically designed for verified edge inference (using B1+B2 attestation) maps directly onto Bittensor's economic model
- Bittensor's technical community will subject the attestation claims to rigorous scrutiny — passing that scrutiny is the most credible third-party validation available
- A live Bittensor subnet with real TAO rewards flowing to Trinity-attested nodes is a concrete proof of traction that Nova Labs can evaluate

When t27.ai approaches Nova Labs with "we have a live Bittensor subnet with X attested nodes, Y inference requests processed, Z on-chain attestation proofs published", the conversation is categorically different from approaching with "we have a chip design and a proposal."

The Helium proposal presented here is designed to be introduced after the Bittensor traction milestone is achieved, not before.

### 8.3 Technical Maturity Honest Assessment

| Component | Status |
|---|---|
| TT SKY26b ternary silicon | Shuttle chip — real, physical, tested |
| B1 RoT module | Designed; shuttle-level validation in progress |
| B2 Bandwidth Attestation | Protocol designed; implementation ongoing |
| B8 DID | Specification complete; implementation planned |
| Solana proof publication | Protocol designed; not yet implemented end-to-end |
| Production-optimized chip | Not yet initiated; requires partnership/funding |
| DevKit Pro hardware | Concept stage; PCB design pending funding |

This table is honest. Trinity is an early-stage hardware project with real silicon and real IP, not a mature product. The proposal scenarios are calibrated to this reality: H1 (IP license) is executable soonest because it leverages existing IP without requiring production hardware. H2 and H3 require additional development investment.

### 8.4 Why Helium Needs This, Not Just Wants It

The distinction between "nice to have" and "need to have" determines whether a partnership discussion becomes a signed agreement. The honest framing:

**Helium needs hardware attestation for enterprise IoT contracts.** Not eventually — now. The enterprise IoT TAM is large, the technology exists to serve it, and the missing piece is a credible trust story. Software-layer PoC heuristics do not satisfy enterprise procurement requirements. Hardware attestation does.

**Helium needs a credible sybil defense for the T-Mobile relationship.** As CBRS offload volumes grow, the incentive to game 5G coverage metrics grows proportionally. The T-Mobile relationship is Helium's most important commercial asset. Protecting it with hardware-level attestation is prudent risk management, not optional feature development.

**Helium needs an AI inference narrative.** The DePIN space is increasingly competitive. Render Network, Akash, and others are building GPU compute marketplaces. Helium's differentiation is coverage — but if hotspot hardware can also run verified AI inference, Helium becomes a multi-revenue DePIN node, not just a coverage node. That differentiation is meaningful for operator retention and network growth.

These are real strategic needs, not manufactured justifications for a partnership.

---

## 9. Comparison with Helium's Existing PoC Mechanism

### 9.1 How Helium PoC Currently Works

Helium's Proof-of-Coverage (PoC) mechanism is a probabilistic wireless coverage verification system. In its current form (post-Solana migration, oracle-based):

1. A selected hotspot (the "beaconer") transmits an RF beacon at a randomized interval
2. Nearby hotspots (the "witnesses") receive the beacon and report the receipt to the PoC oracle
3. The oracle validates witness reports (checking plausibility based on geography, signal strength, timing) and submits valid coverage events on-chain
4. Hotspots earn HNT rewards proportional to their verified coverage activity

The mechanism is elegant and largely effective. Its weaknesses are:

- It relies on software-reported witness data — which can be spoofed by a coordinated set of collocated hotspots
- Geographic plausibility checks help but can be defeated by sophisticated attackers who spoof both location and signal characteristics consistently
- Firmware integrity is not verifiable — a hotspot running modified firmware that generates plausible-looking witness reports is indistinguishable from a legitimate hotspot
- The oracle has no way to distinguish real RF propagation from simulated RF propagation if the simulation is sufficiently convincing

### 9.2 What Trinity Adds — Not Replaces

Trinity's B1+B2 integration is explicitly designed to complement, not replace, the existing PoC architecture. The value proposition is:

| Layer | Helium PoC | Trinity B1+B2 Addition |
|---|---|---|
| Coverage verification | Probabilistic RF witness chain | Hardware-signed RF activity at silicon level |
| Device identity | Software keypair (ECC in secure element) | Hardware-rooted identity, anti-clone, tamper-evident |
| Location verification | GPS + plausibility heuristics | Hardware-signed GPS measurements, tamper-evident |
| Firmware integrity | Certified firmware hash (software assertion) | Measured boot, hardware-attested firmware state |
| Sybil resistance | Economic (density scaling, denylist) | Cryptographic (unique hardware identity per device) |
| Enterprise auditability | None (probabilistic only) | On-chain cryptographic proofs, ZK-format available |

The existing PoC oracle infrastructure continues to operate. The B1+B2 attestations are an additional input to the oracle — a higher-confidence signal that enables the oracle to assign a higher trust score to attested hotspots. Unattested hotspots continue to earn rewards under the existing mechanism. Attested hotspots are eligible for a higher reward tier (the specific reward differential is a tokenomics design decision for the Helium Foundation, not determined by Trinity).

### 9.3 The Migration Path

A phased adoption model minimizes disruption:

**Phase 1 (0–12 months):** PoC oracle extended to accept and log B1+B2 attestation proofs from pioneer attested hotspots. No reward differential yet — purely additive data collection.

**Phase 2 (12–24 months):** Helium Foundation governance vote to establish attested-tier reward multiplier. Hotspot operators have clear economic incentive to upgrade.

**Phase 3 (24+ months):** New certified hotspot hardware incorporates B1+B2 as standard. Attested tier becomes the expected baseline for new deployments. Legacy unattested hotspots grandfathered at existing reward rates.

This migration path is designed to avoid adversarial dynamics with the existing operator community. Operators are rewarded for upgrading; they are not penalized for not upgrading. The network's trust posture improves progressively as the attested tier grows.

### 9.4 What Happens to Gaming Under This Model

A hotspot operator attempting to game the PoC system with Trinity-attested hardware faces a categorically different adversary:

- Cloning a B1 identity requires physical extraction of an on-chip key from silicon — an attack that requires specialized lab equipment, destroys the original chip, and is economically viable only at chip prices far above any plausible reward differential
- Spoofing B2 bandwidth attestations requires sitting in the hardware data path — not achievable without physical hardware modification, which produces a detectable firmware measurement deviation
- Virtualizing multiple hotspots behind a single B1 chip is detectable by hardware fingerprint consistency (single-device attestation pattern across multiple claimed hotspot identities)

This does not eliminate all gaming — sophisticated hardware attacks are theoretically possible. It changes the economics decisively. The current gaming attacks are pure software operations executable at scale with low marginal cost. Hardware-level attacks require per-device physical effort, destroying the economies of scale that make gaming profitable.

---

## 10. Call to Action

Trinity TRI-NET represents a focused technical solution to Helium's most persistent structural vulnerability. The technology is real, the integration path is defined, and the business case is grounded in Helium's actual strategic needs — not in abstract technology enthusiasm.

The right first step is a direct technical conversation. Not a sales call — a working session between engineers who understand both the Helium PoC architecture and Trinity's attestation layer, evaluating integration feasibility with reference to actual hardware and actual code.

### What We Are Asking For

1. **A technical meeting** with Nova Labs' hardware or protocol engineering team to review the TT SKY26b shuttle results and B1+B2 module specifications
2. **An NDA** enabling discussion of confidential commercial terms under any of the three scenarios
3. **A timeline discussion** aligned with Nova Labs' current product roadmap — specifically, which hotspot hardware generation is the right integration target

We are not asking for a commitment. We are asking for an honest technical evaluation by people qualified to evaluate it.

### Contact

**Dmitrii Vasilev**  
Sole Author and Principal Investigator, Trinity TRI-NET  
t27.ai  
**Email:** admin@t27.ai  

All three engagement scenarios — H1 IP License, H2 Co-Marketing Module, H3 Acquisition — are open for discussion. The appropriate scenario depends on Nova Labs' current priorities and organizational capacity. There is no preference on our side for any particular structure, only for the one that creates the most durable value for both parties and for the Helium network.

The Helium network has proven that decentralized wireless infrastructure can work at scale. Trinity wants to help prove that it can also be trusted at scale.

---

## Appendix A: Glossary

**B1 — Hardware Root of Trust (HW RoT):** Trinity module implementing hardware-enforced device identity and attestation signing.

**B2 — Proof-of-Bandwidth Attestation:** Trinity module generating hardware-signed proofs of real wireless activity.

**B8 — DID/Personhood Module:** Trinity module implementing W3C-compliant Decentralized Identifiers and Verifiable Credentials.

**BOM:** Bill of Materials — the component cost of manufacturing a hardware unit.

**CBRS:** Citizens Broadband Radio Service — the 3.5 GHz spectrum band used by Helium 5G hotspots.

**DePIN:** Decentralized Physical Infrastructure Network — the category of crypto-economic networks incentivizing deployment of real-world infrastructure.

**DID:** Decentralized Identifier — W3C standard for self-sovereign digital identity.

**HNT:** Helium Network Token — the native token of the Helium Network.

**IBC:** Inter-Blockchain Communication — cross-chain messaging protocol.

**PoC:** Proof-of-Coverage — Helium's mechanism for verifying that hotspots provide real wireless coverage.

**TEE:** Trusted Execution Environment — a secure area of a processor where code and data can be protected from the rest of the system.

**TT SKY26b:** The current shuttle chip instantiation of Trinity's ternary compute substrate.

**Ternary:** Base-3 logic, as opposed to the binary (base-2) logic of conventional digital computing. Trinity's ternary architecture uses three voltage/current states per logic element.

**ZK / Zero-Knowledge Proof:** A cryptographic proof that demonstrates a statement is true without revealing the underlying data.

---

## Appendix B: About t27.ai and Trinity TRI-NET

t27.ai is a hardware research and development company focused on ternary compute architecture and verifiable AI infrastructure. Trinity TRI-NET is the company's primary technology platform, encompassing the TT SKY26b ternary compute shuttle chip and a modular suite of hardware attestation and AI inference components.

The company is currently in the early-stage hardware development phase. The TT SKY26b represents the first physical silicon instantiation of the Trinity architecture. Development is led by Dmitrii Vasilev as sole principal investigator and engineer.

t27.ai is not affiliated with any existing DePIN network, blockchain project, or hardware manufacturer. All partnership discussions are conducted on an arms-length basis. The scenarios described in this proposal are genuine commercial proposals, not promotional materials.

---

*Document authored solely by Dmitrii Vasilev, admin@t27.ai, t27.ai. No AI co-authorship. All technical benchmarks are honest projected figures based on current hardware development status. All commercial terms presented as ranges; exact figures available under NDA.*

*© 2025 Dmitrii Vasilev / t27.ai. All rights reserved. This document may be shared with Nova Labs, Helium Foundation, and Helium Mobile personnel for the purpose of evaluating a potential partnership. It may not be redistributed further without written permission from admin@t27.ai.*
