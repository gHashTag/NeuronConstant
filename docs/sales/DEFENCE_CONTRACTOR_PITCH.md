<!--
  ╔══════════════════════════════════════════════════════════════════════════╗
  ║              INTERNAL — CONFIDENTIAL — NOT FOR DISTRIBUTION             ║
  ║   Classification: Company Confidential / Business Sensitive             ║
  ║   Author: Dmitrii Vasilev (sole author, admin@t27.ai)                   ║
  ║   Organisation: t27.ai                                                  ║
  ║   Document: Defence Contractor Pitch — Trinity TRI-NET IP               ║
  ║   Revision: 1.0 — June 2025                                             ║
  ║   Distribution: Dmitrii Vasilev only until cleared for BD sharing       ║
  ╚══════════════════════════════════════════════════════════════════════════╝
-->

# INTERNAL — CONFIDENTIAL

**Document Title:** Trinity TRI-NET — Verifiable-AI Co-Processor IP Pitch for Defence Primes  
**Author:** Dmitrii Vasilev (sole author, admin@t27.ai)  
**Organisation:** t27.ai  
**Platform:** TT SKY26b  
**Revision:** 1.0 · June 2025  
**Distribution:** Internal use only — do not forward without explicit authorisation from Dmitrii Vasilev  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Technology Reference — Trinity TRI-NET Blocks](#2-technology-reference--trinity-tri-net-blocks)
3. [Target Dossiers](#3-target-dossiers)
   - 3.1 [Anduril Industries — Lattice OS + Roadrunner-M](#31-anduril-industries--lattice-os--roadrunner-m)
   - 3.2 [Skydio — X10 Remote ID Compliance](#32-skydio--x10-remote-id-compliance)
   - 3.3 [Shield AI — V-BAT Autonomous Mesh](#33-shield-ai--v-bat-autonomous-mesh)
   - 3.4 [Palantir Technologies — Foundry Trusted Compute](#34-palantir-technologies--foundry-trusted-compute)
   - 3.5 [Lockheed Martin + RTX — DARPA Prime Subcontract](#35-lockheed-martin--rtx--darpa-prime-subcontract)
4. [Procurement Cycle Reality](#4-procurement-cycle-reality)
5. [OTA Mitigation Strategy](#5-ota-mitigation-strategy)
6. [SBIR / STTR Funding Path](#6-sbir--sttr-funding-path)
7. [Cleared Facility Partnership](#7-cleared-facility-partnership)
8. [Patent and ITAR Considerations](#8-patent-and-itar-considerations)
9. [Execution Timeline](#9-execution-timeline)
10. [Cold Outreach Templates](#10-cold-outreach-templates)

---

## 1. Executive Summary

**Trinity TRI-NET** is a modular, silicon-level verifiable-AI co-processor IP stack developed by t27.ai, implemented on the Tenstorrent TT SKY26b ternary tensor fabric. It provides defence platforms with four properties that are exceptionally difficult to achieve simultaneously in commodity silicon:

| Property | What it means in the field |
|---|---|
| **Root of Trust (B1 RoT)** | Cryptographic identity anchored in hardware; no firmware patch can forge it |
| **Zero-Knowledge Provability (B5 ZK)** | Compute outputs carry machine-verifiable proofs without exposing raw data |
| **Mesh-native routing (B4)** | 8-port deterministic low-latency router for denied/degraded RF environments |
| **FAA/EASA drone identity (B8 DID)** | Remote ID broadcast compliant with 14 CFR Part 89 and EASA Delegated Reg. 2019/945, tamper-proof |

**Honest performance baseline:** ~1 GOPS @ ~50 MHz @ ~1W ternary (projected). Trinity targets edge platforms — UAVs, autonomous ground vehicles, forward-deployed compute nodes — where watt-budget and trust guarantees matter more than peak FLOPS.

**Commercial model:** IP licensing (one-time + royalty), SBIR/STTR vehicle, and subcontract research. No manufactured silicon sold directly. t27.ai retains all IP; licensor receives RTL/GDSII deliverable + integration support.

**Why now:**
- DoD Instruction 5000.02T and the Software Acquisition Pathway (SwAP) are forcing primes to demonstrate trustworthy AI on-platform rather than cloud-dependent inference.
- FAA Part 89 enforcement (producer deadline passed; operator enforcement active) creates an immediate compliance mandate for every US commercial and defence drone OEM.
- DARPA I2O (Information Innovation Office) and AFRL actively fund verifiable-AI and zero-knowledge proof acceleration under multiple active BAAs.
- CMMC 2.0 Level 2/3 requirements make hardware RoT a near-term contractual obligation for DIB participants.

**Total addressable revenue (internal estimate, 24-month horizon):**

| Tier | Target | Deal Size |
|---|---|---|
| Quick wins | Skydio, Shield AI | $1–3M each |
| Mid-tier | Anduril | $2–5M license + royalty stream |
| Strategic | Palantir | $5–10M IP license |
| DARPA prime sub | Lockheed / RTX | $5–20M subcontract |
| SBIR accelerator | Phase I + II | $2.3M non-dilutive |

**Aggregate potential (conservative):** $16–43M over 24 months, subject to procurement cycle and cleared-facility readiness.

---

## 2. Technology Reference — Trinity TRI-NET Blocks

The following block taxonomy is used throughout this document. All blocks run on TT SKY26b ternary fabric.

### Phi Layer — Identity & Communications (1×1 die)

| Block | ID | Function |
|---|---|---|
| Hardware Root of Trust | **B1 RoT** | PUF-based device identity, secure boot chain, key provisioning. Non-clonable. |
| Bandwidth Controller | **B2 BW** | Adaptive link scheduling, QoS for contested spectrum environments |
| Decentralised Identity | **B8 DID** | W3C DID + FAA Remote ID Part 89 + EASA tamper-proof drone identity broadcast |

### Euler Layer — Cryptographic Provers (8×2 die)

| Block | ID | Function |
|---|---|---|
| RPKI Validator | **B3 RPKI** | BGP origin validation; relevant for ground-station and backbone C2 links |
| ZK Job Prover | **B5 ZK** | Generates SNARK/STARK proofs over inference jobs; verifiable analytics |
| GKR Accelerator | **B6 GKR** | Hardware-accelerated GKR interactive proof protocol for ML model integrity |

### Gamma Layer — Mesh & Storage (8×4 die)

| Block | ID | Function |
|---|---|---|
| Mesh Router | **B4 Mesh** | 8-port deterministic mesh router; sub-µs switching latency; no IP stack dependency |
| Proof-of-Replication | **B7 PoRep** | Verifiable storage replication proofs; tamper-evidence for mission data logs |

### Integrated Stack: TRI-NET

TRI-NET is the full-stack integration of all nine blocks across Phi + Euler + Gamma layers, providing end-to-end verifiable autonomy: from device boot (B1) → identity broadcast (B8) → inter-node routing (B4) → inference execution (B6/B5) → mission log integrity (B7) → C2 link security (B2/B3).

---

## 3. Target Dossiers

---

### 3.1 Anduril Industries — Lattice OS + Roadrunner-M

#### Company Intelligence

- **HQ:** Costa Mesa, CA | **Valuation:** ~$28B (Series F, 2024)
- **Relevant products:** Lattice autonomous sensing mesh, Roadrunner-M loitering munition, Bolt UAV family, Ghost autonomous UAS
- **Key decision contacts (BD/tech):** Research VP Engineering and Chief Software Officer; BD through Palmer Luckey's office for unsolicited strategic pitches
- **Prime contracts:** IVAS (Army), OBSS (Air Force), Fury (Navy), multiple classified SOCOM vehicles
- **Pain points:**
  - Lattice mesh nodes currently rely on software-defined identity; no hardware RoT at edge
  - Roadrunner-M needs FAA Part 89 Remote ID compliance for domestic airspace testing
  - DoD Zero Trust Architecture mandate (DoD ZTA Strategy 2022) requires hardware-anchored identity by FY2027
  - Contested/jammed RF environments for Roadrunner expose C2 link vulnerabilities

#### Proposed Integration

**Primary blocks:** B1 RoT + B8 DID  
**Secondary blocks (upsell):** B2 Bandwidth, B4 Mesh Router

**Use case 1 — Lattice Node Identity Hardening:**  
Embed B1 RoT into each Lattice edge sensor node. Each node receives a PUF-derived identity that Lattice cloud can verify without trusting the node's firmware. Prevents adversarial node injection attacks — a documented concern in any large autonomous mesh.

**Use case 2 — Roadrunner-M Remote ID:**  
Integrate B1 + B8 DID into Roadrunner-M's avionics module. FAA Part 89 compliant broadcast during domestic range testing; EASA tamper-proof for allied-nation operations. DID anchor on TT SKY26b means identity cannot be spoofed even if the flight controller firmware is compromised.

**Use case 3 — Contested C2 (upsell):**  
B2 Bandwidth Controller + B4 Mesh Router enable Roadrunner swarm C2 that degrades gracefully under jamming. Relevant for SOCOM contested-environment testing.

#### Commercial Terms (Internal)

| Item | Value |
|---|---|
| Upfront IP license (B1 + B8) | **$2M–$5M** |
| Per-unit royalty (Roadrunner-M, Bolt, Ghost) | **$800–$1,500/unit** (negotiable on volume >1,000 units) |
| Integration support (T&M, optional) | $250K–$500K/year |
| B2 + B4 upsell license (contested-C2 package) | $1M–$2M additional |
| Total potential deal (3-year, 2K unit volume) | **$5.6M–$12M** |

#### Procurement Vehicle

- **Preferred:** OTA agreement via National Security Technology Accelerator (NSTXL) consortium — Anduril is a consortium member
- **Fallback:** FAR Part 12 Commercial Item; CLIN structure for RTL deliverable + support hours
- **Classification concern:** Lattice is likely CUI/Controlled; need facility clearance or firewall arrangement before IP delivery

#### Risk Factors

- Anduril has strong internal silicon capability (acquired Dive Technologies, building custom ASICs); they may prefer to in-house equivalent IP
- Long sales cycles despite "startup" positioning — legal/export review takes 6–9 months
- ITAR EAR99 / CCL review needed before any technical data exchange

---

### 3.2 Skydio — X10 Remote ID Compliance

#### Company Intelligence

- **HQ:** Redwood City, CA | **Valuation:** ~$2.2B (Series E, 2021; Series F rumoured)
- **Relevant products:** Skydio X10 enterprise/defence UAS, X2 legacy fleet
- **Key contacts:** VP Engineering, Head of Federal Sales (DoD/DHS programmes)
- **Prime contracts:** Army FTUAS programme (competitive), DHS CBP, multiple state/local law enforcement
- **Pain points:**
  - FAA Part 89 Remote ID enforcement — Skydio X2/X10 must demonstrate hardware-grade tamper-proof Remote ID to bid DoD Class 1/2 contracts
  - Blue UAS list compliance (DJI replacement cycle) requires demonstrable supply-chain trust and non-Chinese component attestation
  - DoD Software Modernization strategy requires hardware attestation for autonomous platforms operating in CONUS

#### Proposed Integration

**Primary blocks:** B1 RoT + B8 DID  
**Bundle name internally:** "Skydio Trust Bundle"

**Use case — Hardware-Anchored Remote ID:**  
Embed B1 + B8 DID as a companion chip (or IP block in next-gen SoC) in X10. B1 provides non-clonable hardware serial that feeds B8 DID broadcast. This creates a cryptographically verifiable Remote ID that cannot be spoofed by firmware modification — addressing both FAA Part 89 and DoD Blue UAS supply-chain attestation requirements simultaneously.

**Differentiator vs. software Remote ID:** Software Remote ID solutions (currently dominant in commercial market) can be patched or spoofed; B1 PUF identity is physically unclonable. This is a compliance and procurement differentiator Skydio can use in DoD RFPs.

**EASA value-add:** B8 supports EASA Delegated Regulation 2019/945 Class C1-C3 tamper-proof ID, opening EU allied-nation sales for Skydio.

#### Commercial Terms (Internal)

| Item | Value |
|---|---|
| IP license (B1 + B8 bundle) | **$1M–$3M** |
| Per-unit royalty (X10 + future platforms) | **$400–$700/unit** |
| EASA compliance add-on documentation | $100K flat fee |
| Integration engineering support (optional) | $150K–$300K |
| Total potential deal (3-year, 5K unit volume) | **$3.5M–$7.5M** |

#### Procurement Vehicle

- **Preferred:** Direct commercial license under FAR Part 12; straightforward for IP/software deliverable
- **Accelerant:** Skydio's existing DoD contract vehicles (GSA Schedule, SEWP V) can be used to execute a purchase order for IP licensing support services
- **SBIR bridge:** If Skydio is a Phase II SBIR recipient in relevant topic areas, a subcontract from Skydio to t27.ai is feasible with minimal FAR overhead

#### Risk Factors

- Skydio laid off ~25% of workforce in 2024; budget sensitivity is high — lead with ROI and Blue UAS qualification value
- X10 SoC is likely already taped out; next integration window is X10 successor (estimated 2026 design freeze)
- Competition from dedicated Remote ID module vendors (e.g., Iris Automation, AeroVironment's Remote ID modules)

---

### 3.3 Shield AI — V-BAT Autonomous Mesh

#### Company Intelligence

- **HQ:** San Diego, CA | **Valuation:** ~$2.8B (Series F, 2023)
- **Relevant products:** V-BAT VTOL UAS, Hivemind autonomous flight AI, Nova 2 micro-UAS
- **Key contacts:** CTO Ryan Tseng, VP Business Development
- **Prime contracts:** Navy MASC programme, SOCOM, Project Maven adjacent AI work
- **Pain points:**
  - V-BAT swarm operations (multi-ship Hivemind) require a low-latency, jam-resistant mesh backbone without reliance on a central GCS
  - Hivemind AI inference integrity — no current mechanism to prove to a remote operator that the AI model executed correctly and was not tampered with
  - Navy MASC requires demonstrated resilience in GPS-denied, comms-degraded environments

#### Proposed Integration

**Primary block:** B4 Mesh Router (8-port)  
**Secondary blocks (upsell):** B5 ZK Job Prover (Hivemind inference proofs), B1 RoT (node identity)

**Use case 1 — V-BAT Swarm Mesh Backbone:**  
Replace or augment V-BAT's inter-node communication with B4 Mesh Router. 8-port deterministic switching, sub-µs latency, no IP stack dependency means the swarm maintains connectivity and command consensus even when individual links are jammed. This directly addresses Navy MASC degraded-comms requirement.

**Use case 2 — Hivemind Inference Integrity (upsell):**  
Wrap Hivemind inference jobs with B5 ZK Job Prover. Each autonomous decision generates a compact SNARK proof. Remote operators (or post-mission analysts) can verify that the AI executed the correct model on the correct inputs — critical for Rules of Engagement accountability and mishap investigation.

#### Commercial Terms (Internal)

| Item | Value |
|---|---|
| IP license (B4 Mesh Router) | **$1M–$3M** |
| Hivemind ZK upsell (B5 ZK Job Prover) | $2M–$4M additional |
| Per-unit royalty (V-BAT + Nova 2) | **$600–$1,200/unit** |
| Integration support | $200K–$400K |
| Total potential deal (B4 only, 3-year) | **$2.5M–$6M** |
| Total potential deal (B4 + B5, 3-year) | **$5M–$12M** |

#### Procurement Vehicle

- **Preferred:** OTA agreement — Shield AI has executed multiple OTAs through AFWERX and NavalX; this is the fastest path
- **SBIR angle:** Shield AI is an active SBIR Phase II participant; subcontract vehicle available
- **Classified consideration:** V-BAT Navy MASC work is likely FOUO/CUI; firewall arrangement needed

#### Risk Factors

- Shield AI's Hivemind is a core proprietary differentiator; they may be reluctant to expose inference pipeline to third-party IP
- B4 Mesh Router competes conceptually with Silvus Technologies MIMO mesh radios already integrated in V-BAT; positioning must be complementary (crypto-routing layer, not RF layer)
- Company is pre-IPO and cost-conscious; structure deal to minimise upfront cash ask

---

### 3.4 Palantir Technologies — Foundry Trusted Compute

#### Company Intelligence

- **HQ:** Denver, CO | **Market cap:** ~$100B+ (NYSE: PLTR, as of 2025)
- **Relevant products:** Palantir Foundry (enterprise data fabric), AIP (AI Platform), Gotham (intelligence), MetaConstellation
- **Key contacts:** Chief Revenue Officer, VP Federal (Jason Rathje or successor), AI Platform product leads
- **Prime contracts:** Army TITAN, Project Maven Phase III, NHS UK, Army Vantage
- **Pain points:**
  - AIP inference outputs currently have no hardware-level provenance — Palantir cannot prove to a DoD auditor that a specific AI decision was made by a specific certified model version
  - CMMC 2.0 Level 3 and future DoD AI assurance frameworks will require verifiable computation logs
  - Foundry's federated deployment model (cloud + on-prem + edge) needs a trust anchor at the edge node layer
  - Zero Trust Architecture mandate requires hardware-rooted identity for all compute nodes touching classified data

#### Proposed Integration

**Primary block:** B5 ZK Job Prover  
**Secondary blocks:** B1 RoT (Foundry edge node identity), B6 GKR Accelerator (ML model integrity), B7 PoRep (verifiable mission log storage)

**Use case — Verifiable AIP Analytics:**  
Integrate B5 ZK Job Prover as a co-processor alongside Foundry's AIP inference pipeline. Each AIP "Transform" or AI decision batch generates a ZK proof attesting: (a) the correct model version was used, (b) the input data was unmodified, (c) the compute occurred on an authorised node (anchored by B1 RoT). The proof is compact, publicly verifiable, and can be logged to an immutable audit trail without exposing the underlying data — critical for FISA/EO 12333 compliance and future congressional oversight of AI-assisted targeting.

**GKR Accelerator value-add:** B6 hardware-accelerates the GKR interactive proof protocol, reducing proof generation overhead by an estimated 10–100× vs. software-only — making real-time verifiable inference feasible at Foundry's data throughput.

**PoRep value-add:** B7 Proof-of-Replication provides tamper-evident storage for mission logs and model artefacts — demonstrating to DCSA/NSA auditors that no post-hoc modification occurred.

#### Commercial Terms (Internal)

| Item | Value |
|---|---|
| IP license (B5 ZK Job Prover) | **$5M–$10M** |
| GKR Accelerator add-on (B6) | $2M–$4M additional |
| PoRep log integrity add-on (B7) | $1M–$2M additional |
| B1 RoT edge-node anchor | $1M–$2M additional |
| Annual IP maintenance + updates | 15–20% of license value/year |
| Total potential deal (full stack, year 1) | **$9M–$18M** |
| Total potential deal (3-year with maintenance) | **$12M–$25M** |

#### Procurement Vehicle

- **Preferred:** Direct IP license agreement; Palantir has the legal infrastructure to execute complex IP licenses quickly
- **Government vehicle:** If Palantir embeds Trinity into a GovCloud-deployed AIP instance, the procurement vehicle is Palantir's existing IDIQ (Army Vantage, TITAN) — t27.ai as a subcontractor
- **OTA path:** Palantir is a NSTXL consortium member; OTA vehicle available for R&D component

#### Risk Factors

- Palantir has deep in-house cryptography and ZK expertise (hired from academia); they may prefer to build rather than license
- Deal size requires Palantir C-suite approval; long legal review cycle (6–12 months even for cooperative counterparties)
- Foundry's modular architecture means integration is technically feasible but requires dedicated Palantir engineering resources — position as "co-development" not just "license"
- Need to establish t27.ai credibility via a published technical whitepaper or conference presentation before Palantir's technical team will engage seriously

---

### 3.5 Lockheed Martin + RTX — DARPA Prime Subcontract

#### Company Intelligence

**Lockheed Martin**
- **HQ:** Bethesda, MD | **Revenue:** ~$67B (2024)
- **Relevant divisions:** Skunk Works (advanced programmes), Space (Next-Gen OPIR), Rotary & Mission Systems (C2 systems)
- **DARPA programmes of interest:** DARPA I2O (Information Innovation Office) — specifically CASR (Configuration Agent for Security and Resiliency), DPRIVE (Data Protection in Virtual Environments), and any active ZK-proof BAAs
- **Key contacts:** VP Advanced Technology (Skunk Works), DARPA programme managers via BAA response

**RTX (Raytheon Technologies)**
- **HQ:** Arlington, VA | **Revenue:** ~$78B (2024)
- **Relevant divisions:** Raytheon Intelligence & Space, BBN Technologies (deep research arm)
- **DARPA programmes of interest:** DARPA SAFFIRE (Software Assurance), SBCCOM autonomous systems
- **Pain points (shared across both primes):**
  - Both primes face CMMC 2.0 compliance deadlines and are under pressure to demonstrate supply-chain trustworthiness in their own platforms
  - DARPA I2O is actively funding verifiable AI and ZK-proof hardware acceleration — primes win prime contracts but need subcontractor R&D depth
  - Next-gen autonomous systems (hypersonics, space, autonomous logistics) need edge AI with provable correctness
  - Export control and ITAR compliance for allied-nation deployments of autonomous platforms requires auditable compute provenance

#### Proposed Engagement Model

This is a **subcontract R&D relationship**, not a direct product sale. The model:

1. Lockheed/RTX win a DARPA I2O contract (via BAA response) that includes verifiable-AI co-processor requirements
2. t27.ai is named as a subcontractor in the prime's proposal, contributing Trinity TRI-NET as the technical solution
3. Deliverable: RTL/GDSII of relevant Trinity blocks + integration documentation + technical reports
4. t27.ai retains background IP; government receives a licence to use deliverables within the programme

**Full TRI-NET stack relevance:**
- B1 RoT: Secure boot for all autonomous platform nodes
- B2 BW: Contested-spectrum link management
- B3 RPKI: BGP security for ground station networks
- B4 Mesh: Swarm C2 backbone
- B5 ZK + B6 GKR: Verifiable AI inference for autonomous decision accountability
- B7 PoRep: Mission log integrity
- B8 DID: Platform identity for allied-interoperability

#### Target DARPA Programmes

| Programme | Office | Relevance | BAA Status |
|---|---|---|---|
| DPRIVE | I2O | Hardware ZK-proof acceleration | Ongoing |
| CASR | I2O | Security configuration agents | Monitor |
| PACT | I2O | Provably correct autonomy | Emerging |
| SBCCOM | DSO | Autonomous systems | Active |
| SAFFIRE | I2O | Software assurance | Monitor |

#### Commercial Terms (Internal)

| Item | Value |
|---|---|
| DARPA subcontract (Phase I research) | **$500K–$2M** |
| DARPA subcontract (Phase II/III development) | **$3M–$10M** |
| Follow-on production license (if platform advances) | **$5M–$20M** |
| Annual IP maintenance (production license) | 10–15% of license value |
| Total potential deal (full lifecycle) | **$8.5M–$32M** |

The $5–20M figure cited in the executive summary refers to the combined subcontract + license value across a 3–5 year programme lifecycle.

#### Procurement Vehicle

- **Primary:** DARPA BAA response — Lockheed/RTX as prime, t27.ai as named subcontractor
- **Secondary:** CLARA (Contract for Lifecycle Aerospace/Defence Research Award) — Lockheed-specific R&D partnership vehicle
- **OTA path:** Both primes execute OTAs under NSTXL, AFWERX, and NavalX consortia
- **SBIR bridge:** DoD SBIR Phase II to Phase III direct-to-programme transition (10 USC 4902)

#### Risk Factors

- DARPA BAA competition is intense; winning requires a compelling technical proposal and ideally a pre-existing programme office relationship
- Both primes have large internal R&D organisations and may prefer to develop equivalent IP internally rather than subcontract
- Subcontract terms at primes typically include aggressive IP flow-down clauses — must negotiate "background IP" carve-out explicitly in teaming agreement before proposal submission
- Security clearance gap: Skunk Works and Raytheon SCI programmes require facility and personnel clearances t27.ai does not currently hold
- RTX BBN Technologies is itself a deep research organisation; they are more likely to partner than compete if approached correctly

---

## 4. Procurement Cycle Reality

Defence procurement is not enterprise SaaS. The following table is an honest characterisation of timeline expectations.

| Phase | Description | Typical Duration |
|---|---|---|
| **Initial contact → NDA** | First outreach to executed NDA | 1–3 months |
| **NDA → Technical engagement** | NDA to first technical deep-dive meeting | 2–4 months |
| **Technical engagement → LOI** | Proof of technical merit, internal champion secured | 3–6 months |
| **LOI → Contract award** | Legal review, FAR/DFARS compliance, security review, contracting officer involvement | 6–18 months |
| **Contract award → First payment** | Mobilisation, task order issuance, accounting setup | 1–3 months |
| **Total: first outreach → first revenue** | **12–24 months** (optimistic) | up to 36 months for classified programmes |

### FAR/DFARS Compliance Checkpoints

t27.ai must be prepared to satisfy the following before any contract award:

| Requirement | Status (current) | Action needed |
|---|---|---|
| SAM.gov registration | Must verify | Register/renew at sam.gov |
| CAGE code | Must verify | Assigned upon SAM registration |
| DUNS/UEI | Must verify | UEI replaces DUNS; verify in SAM |
| CMMC Level 1 self-assessment | Not assessed | Complete self-assessment; document controls |
| CMMC Level 2 (for CUI handling) | Not assessed | Requires C3PAO assessment; ~6–9 months |
| Export Control (EAR/ITAR) | Not assessed | Classify Trinity blocks under USML/CCL; retain export counsel |
| Small Business certification | Likely eligible | Verify SBA size standards for NAICS 334413 / 541715 |
| Representation and Certifications | Not completed | Complete in SAM.gov |

### DFARS Key Clauses to Anticipate

- **DFARS 252.227-7013/7014:** Rights in Technical Data and Computer Software — negotiate "limited rights" or "restricted rights" for background IP
- **DFARS 252.204-7012:** Safeguarding Covered Defence Information — triggers CMMC obligations
- **DFARS 252.225-7048:** Export-Controlled Items — mandatory disclosure of ITAR/EAR classification
- **FAR 52.227-11:** Patent Rights under Government Contracts — Bayh-Dole applies to SBIR; retain title

---

## 5. OTA Mitigation Strategy

Other Transaction Authority (OTA) agreements under 10 USC 4021/4022 offer the fastest path to defence contracting for a company at t27.ai's stage. Key properties:

- **Not subject to FAR/DFARS** (though good practices still apply)
- **Award timeline:** 30–90 days from consortium submission to contract in some cases
- **No CMMC requirement** for prototype OTAs (though prudent to pursue anyway)
- **IP terms:** More negotiable than FAR contracts; background IP protection is standard

### Priority OTA Consortia

| Consortium | Sponsor | Relevance to Trinity |
|---|---|---|
| **NSTXL** (National Security Technology Accelerator) | OSD, Air Force | Anduril, Palantir, Shield AI members; autonomous systems focus |
| **AFWERX** Catalyst | USAF | Rapid prototyping; direct engagement with USAF programme offices |
| **NavalX** Agility Office | USN | V-BAT relevant; naval autonomous systems |
| **RCTC** (Responsive Combat Technologies Consortium) | Army | Ground autonomous platforms |
| **DEFENSEWERX** (NSIN) | OSD | Cross-service technology transition |

### OTA Action Plan

1. **Immediately:** Apply for NSTXL membership (~30-day process; no cost for small business)
2. **Q3 2025:** Apply for AFWERX Catalyst Open Topic — submit a capability brief on Trinity TRI-NET verifiable AI
3. **Q4 2025:** Identify active OTA solicitations relevant to ZK-proof hardware, mesh routing, or Remote ID through sam.gov OTA search
4. **Concurrent:** Request introductions to NSTXL consortium company BD contacts (Anduril, Shield AI) through consortium facilitator

### OTA Pricing Considerations

OTA prototype agreements are typically cost-type (cost-plus-fixed-fee or cost-plus-incentive-fee). Internal hourly rates and cost build-up must be documented. Expect:
- PI (Dmitrii Vasilev) labour rate: document fully-loaded rate
- Subcontractor/consultant costs: pass-through with fee
- ODC (Other Direct Costs): compute, tooling, materials
- Fee: 7–12% typical for prototype OTAs

---

## 6. SBIR / STTR Funding Path

SBIR/STTR is the primary non-dilutive funding mechanism for t27.ai at this stage and serves as a parallel-path accelerant to direct commercial licensing.

### Programme Overview

| Feature | SBIR Phase I | SBIR Phase II | STTR Phase I | STTR Phase II |
|---|---|---|---|---|
| Award amount | Up to $300K | Up to $2M (DoD) | Up to $300K | Up to $2M |
| Duration | 6–12 months | 24 months | 6–12 months | 24 months |
| Research partner required | No | No | Yes (university/non-profit) | Yes |
| IP ownership | Small business | Small business | Negotiated | Negotiated |
| Commercialisation requirement | Strong preference | Mandatory plan | Strong preference | Mandatory plan |

**SBIR is preferred** over STTR given PI is sole author; STTR requires a formal research institution partner which adds overhead.

### Priority SBIR Topics (2025–2026 Cycles)

Monitor the following DoD SBIR portals for relevant open topics:

| Agency | Portal | Target topic areas |
|---|---|---|
| **DARPA** | darpa.mil/work-with-us/sbir-sttr | Verifiable AI, ZK hardware, autonomous mesh |
| **Air Force** | afwerx.com / dodsbirsttr.mil | Remote ID, trusted autonomy, edge AI |
| **Navy** | navysbir.com | Swarm mesh, autonomous C2 |
| **Army** | arl.army.mil/sbir | Edge compute, verified ML |
| **NSA** | nsa.gov/sbir | Cryptographic hardware, RoT |
| **DHS S&T** | sbir.dhs.gov | UAV identity, Remote ID enforcement |

### Recommended Phase I Proposal Strategy

**Topic targeting:** Do not write a generic proposal. Identify a specific open SBIR topic number with language matching Trinity's capabilities. Topics such as:
- "Hardware root of trust for autonomous platforms"
- "Zero-knowledge proof acceleration for edge AI"
- "Tamper-proof UAV identity for contested environments"

**Proposal structure (DoD SBIR Phase I):**
1. Technical Volume (20 pages max): Clearly describe B1/B5/B8 blocks, architecture, feasibility evidence, and Phase II path
2. Cost Volume: Detailed cost build-up; PI labour is allowable and typically the dominant cost
3. Commercialisation Plan: Reference this pitch document's target list as evidence of market demand

**Key success factors:**
- Technical reviewer is a programme manager, not a procurement officer — write for technical credibility
- Cite published literature and benchmarks; "~1 GOPS @ ~50 MHz @ ~1W ternary (projected)" is honest and acceptable at Phase I feasibility stage
- Name the target customer (e.g., "Skydio has expressed interest in hardware Remote ID solutions") only if there is documented interest; otherwise, cite market evidence (FAA enforcement, CMMC mandates)

### Phase I → Phase II Transition

A successful Phase I demonstration should produce:
- Functional RTL simulation of at least one primary block (e.g., B1 RoT or B8 DID)
- Performance characterisation on TT SKY26b
- Customer letters of interest from at least one target (pursue Skydio or Shield AI for LOI during Phase I)
- Phase II proposal submitted within 90 days of Phase I completion

### Phase II → Phase III (Commercialisation)

Phase III receives no additional SBIR funding directly but enables:
- Direct-to-programme contract awards without further competition (10 USC 4902)
- SBIR Transition Programme (STP) support from DoD
- Bridge funding through SBIR/STTR Phase II Enhancement (up to $500K additional matching)

**Total non-dilutive SBIR path: $300K (Phase I) + $2M (Phase II) = $2.3M**

---

## 7. Cleared Facility Partnership

**Current status:** t27.ai and PI Dmitrii Vasilev do not hold a facility clearance (FCL) or personnel clearance (PCL). This is a hard constraint for engagement with classified programmes at Anduril (Lattice classified contracts), Shield AI (SOCOM), Lockheed Skunk Works, and any DARPA SCI programme.

### Clearance Options

**Option A: Self-clear t27.ai**
- Process: Apply for FCL through DCSA (Defence Counterintelligence and Security Agency) via a sponsoring government contracting officer
- Timeline: 12–24 months for SECRET; 18–36 months for TS/SCI
- Cost: Primarily opportunity cost + legal/compliance overhead (~$50–100K in consulting fees)
- Prerequisite: Must have a classified contract award (or pending award) to justify FCL application
- Implication: Pursue OTA/SBIR path first; use unclassified contract as FCL justification

**Option B: Partner with a cleared facility**
- Model: t27.ai licenses IP to a cleared Prime or cleared small business that performs classified integration work
- Advantages: Faster path; no clearance burden on PI
- Disadvantages: IP exposure risk; need robust background IP agreement
- Candidates: Booz Allen Hamilton (cleared small business division), SAIC, Leidos, or a cleared SBIR-active small business (e.g., Intelligent Automation Inc., Physical Optics Corporation)
- Process: Identify cleared partner through NSTXL consortium or DARPA programme office referral

**Option C: Carve out unclassified work**
- Structure proposals so that Trinity TRI-NET hardware development remains entirely unclassified (EAR99 or CCATS determination)
- Classified integration is performed by the prime using t27.ai's unclassified IP deliverable
- Avoids FCL requirement for t27.ai entirely
- This is the recommended near-term posture

### Action Items

1. **Immediately:** Retain export counsel to classify all Trinity blocks under EAR/CCATS; confirm EAR99 or applicable ECCN for RTL deliverables
2. **Q3 2025:** Identify two candidate cleared-facility partners through NSTXL consortium
3. **Q4 2025:** Execute teaming agreement with at least one cleared partner before any DARPA BAA response
4. **FY2027 (if warranted):** Pursue PI personal clearance (SECRET) if programme pipeline justifies it; engage DCSA-cleared attorney for personnel security questionnaire (SF-86) preparation

---

## 8. Patent and ITAR Considerations

**IMPORTANT DISCLAIMER: The following is a preliminary internal planning note only. It does not constitute legal advice. Dmitrii Vasilev must retain qualified patent counsel and export control counsel before taking any action described below.**

### Patent Strategy (Preliminary)

| Block | Potential patentable elements | Priority |
|---|---|---|
| B1 RoT | PUF circuit topology on ternary fabric; secure boot sequence | High |
| B5 ZK | GKR acceleration architecture; SNARK prover optimisation for ternary arithmetic | High |
| B8 DID | Hardware-anchored DID method specification; FAA Part 89 + W3C DID binding | High |
| B4 Mesh | 8-port deterministic switching architecture; latency guarantees under load | Medium |
| B6 GKR | Ternary GKR interactive proof circuit | Medium |
| B7 PoRep | PoRep adaptation for edge/constrained environments | Low |

**Recommended patent filing sequence:**
1. File provisional applications for B1 RoT, B5 ZK, and B8 DID before any public disclosure (conference presentations, whitepapers, or SBIR proposal submissions — SBIR proposals are confidential but whitepaper publication starts the clock)
2. File PCT (Patent Cooperation Treaty) applications within 12 months of provisional to preserve international rights (relevant for EASA/allied-nation commercialisation)
3. National phase entry in key jurisdictions: US, EU, Israel, UK, Australia (Five Eyes alliance + Israel as key defence tech partner)

**Government Use Licence (Bayh-Dole):** Any patents arising from SBIR-funded work are subject to a government march-in right and government use licence (free, non-exclusive). This is acceptable and expected; structure commercialisation to depend on trade secrets and integration expertise, not just patents.

### ITAR/EAR Preliminary Assessment

| Trinity Block | Likely jurisdiction | Preliminary ECCN/USML assessment |
|---|---|---|
| B1 RoT (crypto hardware) | EAR | Likely 5E002 (cryptographic technology) — requires export licence for many destinations |
| B5 ZK / B6 GKR | EAR | Possibly 5E002 or EAR99 (fundamental research exception may apply if published) |
| B8 DID (Remote ID) | EAR | Likely EAR99 or 7E004; FAA Part 89 implementation is domestic regulation |
| B4 Mesh (routing hardware) | EAR | Possibly 5E001 (telecommunications) or EAR99 |
| Full TRI-NET integrated stack for military platforms | Possible ITAR | If designed specifically for military use, USML Category XI (military electronics) or XV (spacecraft/satellite) may apply — requires DDTC commodity jurisdiction request |

**Immediate actions required:**
1. Retain export counsel with EAR/ITAR experience (recommend counsel familiar with CCL encryption controls)
2. File CCATS (Commodity Classification Automated Tracking System) requests for B1 RoT and B5 ZK before any international disclosure
3. Do NOT share any Trinity technical documentation with non-US persons (including foreign nationals at US institutions) without export authorisation
4. If any defence-specific optimisation is performed, file a DDTC commodity jurisdiction request to determine USML vs. CCL classification

**TAA (Technical Assistance Agreement):** Any technical data exchange with a foreign person (e.g., EU partner for EASA compliance work) requires a TAA from DDTC if ITAR-controlled, or an export licence if EAR-controlled. Build this into any partnership timeline.

---

## 9. Execution Timeline

The following timeline assumes SBIR as the primary near-term vehicle with parallel direct BD outreach.

### Master Timeline

```
2025 Q2–Q3 (NOW)
├── SAM.gov registration + CAGE code
├── Retain export counsel → CCATS filing for B1 RoT + B5 ZK
├── NSTXL consortium membership application
├── Identify cleared-facility partner candidates
└── Begin technical whitepaper drafting (B1 RoT + B8 DID)

2025 Q3
├── First cold outreach emails to Skydio (BD) and Shield AI (BD) — unclassified tech
├── AFWERX Catalyst Open Topic submission
├── SBIR topic monitoring — DARPA, Air Force, Navy cycles
└── Provisional patent applications: B1 RoT, B5 ZK, B8 DID

2025 Q4
├── Technical whitepaper published (arXiv or conference submission) — establishes credibility
├── Cleared-facility teaming agreement executed
├── Anduril first outreach (via NSTXL consortium introduction)
├── SBIR Phase I proposal submission (DARPA or Air Force — target Q4 2025 cycle)
└── Palantir BD outreach (via conference/warm introduction)

2026 Q1
├── SBIR Phase I anticipated award (if Q4 2025 submission) — $300K
├── Skydio / Shield AI technical engagement (proof-of-concept proposal)
└── Lockheed / RTX DARPA teaming agreement discussions

2026 Q2
├── SBIR Phase I work: B1 RoT RTL simulation, performance characterisation
└── OTA prototype submission (NSTXL or AFWERX)

2026 Q3  ← TARGET: SBIR Phase I completion + Phase II submission
├── SBIR Phase I completion
├── SBIR Phase II submission — $2M ask, 24-month RTL → tape-out programme
├── First defence pilot LOI (target: Skydio or Shield AI)
└── Anduril NDA + technical engagement

2026 Q4
├── SBIR Phase II anticipated award
├── Palantir IP license negotiation initiation
└── DARPA BAA response (with Lockheed or RTX as prime)

2027 Q1  ← TARGET: First defence pilot
├── First defence pilot kick-off (Skydio or Shield AI)
├── SBIR Phase II work: full B1 + B8 integration on TT SKY26b
└── Patent national phase entry (PCT → US + EU + IL + UK + AU)

2027 Q2–Q3
├── Pilot results → commercial license negotiation
├── Palantir ZK license execution (target $5–10M)
└── Lockheed/RTX subcontract award (DARPA programme)

2027 Q4  ← TARGET: Full contract
├── Full commercial license contracts executed (Anduril, Skydio, Shield AI)
├── DARPA subcontract programme work underway
├── Revenue run-rate: $3M–$8M
└── SBIR Phase III transition discussions
```

### Milestone Summary

| Milestone | Target Date | Vehicle |
|---|---|---|
| SAM.gov + export counsel retained | Q2/Q3 2025 | Admin |
| SBIR Phase I submission | Q3 2026 | SBIR |
| SBIR Phase I award | Q1 2026 (or Q4 2025 if earlier cycle) | SBIR |
| First defence pilot kickoff | Q1 2027 | OTA / commercial |
| SBIR Phase II submission | Q3 2026 | SBIR |
| First commercial license executed | Q2/Q3 2027 | Commercial |
| Full contract (multi-target) | Q4 2027 | Commercial + SBIR III |

---

## 10. Cold Outreach Templates

These templates are for initial outreach to BD/partnership contacts. Adjust salutation and specifics based on actual contact information researched before sending. All outreach from Dmitrii Vasilev (admin@t27.ai).

---

### Template A — Anduril Industries

**Subject:** Hardware Root of Trust + Tamper-Proof Remote ID IP for Lattice / Roadrunner-M

**To:** [VP Engineering / BD contact at Anduril]

---

Hi [Name],

I'm Dmitrii Vasilev, founder of t27.ai. I'm developing Trinity TRI-NET — a verifiable-AI co-processor IP stack on the Tenstorrent TT SKY26b ternary fabric.

Two blocks are directly relevant to Anduril's roadmap:

**B1 Hardware Root of Trust** — PUF-based, non-clonable device identity for Lattice edge nodes. Eliminates the firmware-spoofable identity layer that any software-defined mesh inherits. Directly addresses DoD ZTA hardware-anchored identity requirement (FY2027 deadline).

**B8 Decentralised Identity** — FAA Part 89 + EASA tamper-proof Remote ID for Roadrunner-M and Bolt. Hardware-level; cannot be defeated by firmware modification. W3C DID anchored on TT SKY26b silicon.

Honest performance baseline: ~1 GOPS @ ~50 MHz @ ~1W ternary (projected figures; silicon validation in progress).

I'm not looking for a meeting to pitch a deck. I'd like to share a two-page technical brief and understand whether there's an integration window in your 2026 SoC/platform roadmap. NSTXL consortium vehicle is available if that's the fastest contracting path.

Would a 20-minute technical call in the next two weeks work?

Dmitrii Vasilev  
admin@t27.ai | t27.ai

---

### Template B — Skydio

**Subject:** Hardware-Grade Remote ID for X10 — FAA Part 89 + Blue UAS Attestation

**To:** [VP Engineering or Head of Federal Sales at Skydio]

---

Hi [Name],

I'm Dmitrii Vasilev, founder of t27.ai. I work on Trinity TRI-NET, a silicon-level verifiable-AI co-processor IP stack.

I believe there's a narrow and urgent window relevant to Skydio's Blue UAS positioning:

**The problem:** Software Remote ID solutions — including leading current implementations — can be patched, spoofed, or compromised at the firmware layer. DoD procurement evaluators and the Blue UAS list review process are beginning to ask for hardware-anchored Remote ID that cannot be defeated by adversarial firmware.

**The solution:** Trinity B1 (Hardware Root of Trust) + B8 (Decentralised Identity) bundle delivers:
- FAA 14 CFR Part 89 compliant Remote ID broadcast, hardware-anchored
- EASA Delegated Regulation 2019/945 tamper-proof identity (opens EU/allied-nation markets)
- Non-clonable PUF-derived serial — survives any firmware compromise

This is IP licensing — RTL/GDSII deliverable for integration into X10's next-gen SoC. Estimated license range $1–3M depending on volume and exclusivity terms.

Happy to share a technical brief under NDA. Is there a technical contact at Skydio I should route this through?

Dmitrii Vasilev  
admin@t27.ai | t27.ai

---

### Template C — Shield AI

**Subject:** 8-Port Deterministic Mesh Router IP for V-BAT Swarm C2 (GPS-denied environments)

**To:** [CTO or VP BD at Shield AI]

---

Hi [Name],

I'm Dmitrii Vasilev, founder of t27.ai. I develop silicon-level IP for autonomous platforms — specifically a block called B4 Mesh Router: an 8-port deterministic switching fabric with sub-µs latency, no IP stack dependency, designed for GPS-denied and comms-degraded environments.

I believe this is relevant to V-BAT swarm operations under Navy MASC requirements. The core problem in multi-ship autonomous mesh operations is that conventional IP-based mesh protocols degrade non-deterministically under jamming — leading to command consensus failures. B4 provides a deterministic switching guarantee that survives link failures gracefully.

Secondary capability: B5 ZK Job Prover can wrap Hivemind inference jobs with machine-verifiable proofs — enabling post-mission audit of autonomous decisions without exposing the model or input data. Relevant for RoE accountability and mishap investigation.

I'd like to share a two-page technical brief. AFWERX or NavalX OTA vehicle is available for rapid prototyping engagement if there's mission-fit.

Can you point me to the right technical contact for autonomous mesh C2 at Shield AI?

Dmitrii Vasilev  
admin@t27.ai | t27.ai

---

### Template D — Palantir Technologies

**Subject:** ZK Job Prover IP for Verifiable AIP Analytics — CMMC / DoD AI Assurance

**To:** [VP Federal or AIP Product Lead at Palantir]

---

Hi [Name],

I'm Dmitrii Vasilev, founder of t27.ai. I'm building Trinity TRI-NET — a verifiable-AI co-processor IP stack that includes a hardware ZK Job Prover (B5) and GKR accelerator (B6) on the Tenstorrent TT SKY26b ternary fabric.

The integration hypothesis for Palantir AIP:

AIP inference outputs currently carry no hardware-level provenance. As DoD AI assurance frameworks mature and congressional scrutiny of AI-assisted decision-making increases, Palantir's customers will face a hard question: "Can you prove that specific AI decision was made by the certified model, on unmodified data, on an authorised node?" Currently, the answer requires trusting a software audit trail.

B5 ZK Job Prover generates compact SNARK proofs over AIP inference jobs — machine-verifiable, data-preserving, hardware-rooted via B1 RoT. B6 GKR accelerator makes this feasible at Foundry's data throughput (10–100× faster than software-only ZK).

I'm not pitching vaporware — honest baseline is ~1 GOPS @ ~50 MHz @ ~1W ternary (projected). The value proposition is architectural: this becomes a compliance and procurement differentiator for Palantir as verifiable-AI requirements enter DoD contracts.

I'd like to share a technical brief and understand whether there's an AIP roadmap conversation to be had. Would 30 minutes with your federal AI platform team be feasible?

Dmitrii Vasilev  
admin@t27.ai | t27.ai

---

### Template E — Lockheed Martin (Skunk Works / DARPA BD)

**Subject:** Trinity TRI-NET — Verifiable-AI Subcontractor for DARPA I2O BAA (ZK + RoT)

**To:** [VP Advanced Technology, Skunk Works or DARPA programme liaison]

---

Hi [Name],

I'm Dmitrii Vasilev, founder of t27.ai, and I'm reaching out regarding potential teaming for DARPA I2O BAA responses in the verifiable-AI and ZK-proof hardware acceleration space (DPRIVE, PACT, or related).

Trinity TRI-NET is a silicon-level verifiable-AI co-processor IP stack on TT SKY26b ternary fabric. The relevant subcontractor contribution to a DARPA proposal:

- **B5 ZK Job Prover + B6 GKR Accelerator:** Hardware-accelerated zero-knowledge proof generation for AI inference jobs. Addresses the DPRIVE programme goal of protecting data in use during ML inference, and PACT-type provably-correct autonomy requirements.
- **B1 Hardware Root of Trust:** Non-clonable device identity for all autonomous platform nodes.
- **B4 Mesh Router:** Deterministic 8-port swarm mesh backbone for denied/degraded environments.

Honest performance baseline: ~1 GOPS @ ~50 MHz @ ~1W ternary (projected).

I'm looking for a prime relationship for one or more DARPA BAA responses where t27.ai contributes the verifiable-AI co-processor R&D component. Background IP retained by t27.ai with government use licence as standard.

Is there a relevant BAA in your current pipeline, or a programme office contact you'd suggest I engage directly?

Dmitrii Vasilev  
admin@t27.ai | t27.ai

---

### Template F — RTX / BBN Technologies

**Subject:** ZK-Proof Hardware Acceleration Subcontract — DARPA Verifiable-AI Programmes

**To:** [VP R&D or BBN Technologies research lead]

---

Hi [Name],

I'm Dmitrii Vasilev, founder of t27.ai. I'm reaching out to explore subcontractor teaming with RTX / BBN for DARPA programmes requiring hardware ZK-proof acceleration and verifiable-AI co-processing.

Trinity TRI-NET (TT SKY26b ternary fabric) includes:

- **B5 ZK Job Prover:** SNARK/STARK proof generation for AI inference — enables verifiable analytics without data exposure
- **B6 GKR Accelerator:** Hardware GKR interactive proof protocol; 10–100× faster than software-only
- **B1 RoT:** PUF-based hardware root of trust; secure boot for autonomous platform nodes
- **B8 DID:** FAA/EASA tamper-proof drone identity; relevant for allied-nation autonomous systems interoperability

BBN's history in cryptographic research and DARPA programme execution makes this a natural subcontractor fit. I'd bring the RTL/IP, you'd bring the clearances, systems integration expertise, and prime contract vehicle.

Honest performance baseline: ~1 GOPS @ ~50 MHz @ ~1W ternary (projected).

Would it be useful to share a one-page technical summary? I'm targeting DARPA DPRIVE and emerging provably-correct autonomy topics.

Dmitrii Vasilev  
admin@t27.ai | t27.ai

---

## Appendix A — Internal Pricing Summary

| Target | Primary blocks | License range | Royalty | Notes |
|---|---|---|---|---|
| Anduril | B1 + B8 | $2M–$5M | $800–$1,500/unit | OTA preferred; contested-C2 upsell available |
| Skydio | B1 + B8 | $1M–$3M | $400–$700/unit | Blue UAS angle; next SoC window ~2026 |
| Shield AI | B4 | $1M–$3M | $600–$1,200/unit | OTA/SBIR; ZK upsell $2–4M additional |
| Palantir | B5 + B6 + B7 + B1 | $5M–$10M core | N/A (platform license) | Requires credibility-building whitepaper first |
| Lockheed / RTX | Full TRI-NET | $5M–$20M | N/A (subcontract) | DARPA BAA vehicle; cleared partner required |
| **SBIR (non-dilutive)** | Phase I + II | **$2.3M** | N/A | Parallel path; accelerates all above |

**Aggregate conservative potential (24 months):** $16.3M–$43.3M (excluding royalty streams)

---

## Appendix B — Key Resources and Links

- SAM.gov registration: https://sam.gov
- SBIR/STTR portal: https://www.dodsbirsttr.mil
- NSTXL consortium: https://www.nstxl.org
- AFWERX Catalyst: https://afwerx.com/divisions/catalyst/
- DARPA I2O BAAs: https://www.darpa.mil/work-with-us/opportunities (filter: I2O)
- FAA Remote ID Part 89: https://www.faa.gov/uas/getting_started/remote_id
- EASA UAS Regulation 2019/945: https://www.easa.europa.eu/en/domains/civil-drones
- CMMC 2.0 information: https://www.acq.osd.mil/cmmc/
- DCSA FCL information: https://www.dcsa.mil/is/fac/
- Bayh-Dole / SBIR IP rights: https://www.sbir.gov/about#ip

---

*End of document.*

**INTERNAL — CONFIDENTIAL — NOT FOR DISTRIBUTION**  
*Author: Dmitrii Vasilev (sole author, admin@t27.ai) · t27.ai · Revision 1.0 · June 2025*
