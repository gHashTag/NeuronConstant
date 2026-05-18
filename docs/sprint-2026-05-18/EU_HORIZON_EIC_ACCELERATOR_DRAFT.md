# EU HORIZON EUROPE — EIC ACCELERATOR (OPEN)
## Full Proposal — Part B

**Project acronym:** TRINITY-DEPIN  
**Project title:** Trinity DePIN: Hardware-Anchored Verifiable AI Inference on Open Silicon for EU Sovereign Compute  
**Applicant:** Trinity DePIN OÜ *(proposed Estonia e-Residency entity, TBD — registration in progress)*  
**Principal Investigator:** Dmitrii Vasilev  
**Requested grant:** €2,500,000  
**Requested equity investment:** up to €15,000,000 (blended finance)  
**Implementation period:** 24 months  
**TRL at start:** 5–6 | **TRL at end:** 8  
**EIC call:** EIC Accelerator Open (any technology field)  
**Submission batch:** [Target: 04/03/2026 or 06/05/2026]  

---

## 1. EXECUTIVE SUMMARY

Europe's AI ecosystem faces a structural dependency: every major AI inference workload is executed on proprietary silicon (Nvidia, AMD, Qualcomm) running inside closed, unverifiable data centres located predominantly in the United States. The EU AI Act (Regulation (EU) 2024/1689), applicable from August 2026 onwards, imposes mandatory logging and traceability obligations on providers and deployers of high-risk AI systems under Article 12. No currently available commercial AI inference platform — cloud or on-premises — provides hardware-anchored cryptographic receipts that would allow independent verification of *which model* ran, *which weights* were used, and *which computation* produced the output. This is a fundamental regulatory and sovereign-computing gap.

**Trinity DePIN** closes this gap. Trinity is an open-silicon, decentralised physical infrastructure network (DePIN) for verifiable AI inference. The system generates a hardware-signed inference receipt — anchored in real silicon geometry — that can be independently audited, satisfying Article 12 logging requirements and enabling EU regulated industries (healthcare diagnostics, financial advice, critical infrastructure, public-sector automated decision-making) to deploy AI under the AI Act with full auditability.


The EU-specific scaling path runs through **IHP GmbH** (Leibniz Institute for High Performance Microelectronics), located in Frankfurt (Oder), Germany — a European public-research foundry offering the **SG13G2** SiGe BiCMOS open process design kit (PDK). IHP is part of Germany's sovereign semiconductor research infrastructure and is directly aligned with the EU Chips Act (Regulation (EU) 2023/1781). By manufacturing the Trinity Node ASIC at IHP rather than at TSMC or GlobalFoundries, this project delivers the first **EU-fabbed verifiable AI inference chip** — a concrete contribution to European technological sovereignty.

**The ask:** €2.5M grant (24-month programme) + up to €15M equity (EIC Fund) for transition from TRL 5–6 to TRL 8 and commercial launch.

---

## 2. INNOVATION AND AMBITION

### 2.1 The Unmet Need

**Europe lacks sovereign, verifiable AI compute.** As of 2026, AI inference in EU industry is overwhelmingly served by hyperscale cloud providers (AWS, Azure, Google Cloud) running proprietary accelerators. This creates three compounding problems:

1. **Regulatory non-compliance (AI Act Article 12):** High-risk AI systems must "technically allow for the automatic recording of events (logs)" and must ensure "a level of traceability appropriate to [the system's] intended purpose" [Regulation (EU) 2024/1689, Article 12(1–2)]. Logs must be retained for a minimum of six months (Article 19). Current cloud AI APIs do not provide hardware-level evidence of model identity or execution integrity; they produce application-layer logs controlled entirely by the cloud provider — logs that cannot be independently verified. This is insufficient for regulated deployers acting under Article 26(6).

2. **Supply-chain sovereignty risk:** The EU Chips Act (Regulation (EU) 2023/1781) acknowledges that Europe's dependence on non-EU foundries creates strategic vulnerability. Its €43 billion mobilisation explicitly targets European semiconductor manufacturing capacity. Despite this, no European AI silicon product exists that combines open-source design with EU fabrication and cryptographic inference attestation.

3. **Open-silicon accountability gap:** Alternative verifiable inference approaches (zero-knowledge ML, trusted execution environments) are either computationally prohibitive at production scale or dependent on closed CPU/GPU vendor implementations (Intel SGX, Nvidia H100 confidential computing). Neither approach provides a silicon-geometric anchor — an unforgeable physical identifier tied to the specific die geometry that ran the computation.

### 2.2 The Breakthrough: Hardware-Anchored Verifiable Inference

Trinity's core technical contribution is the **hardware inference receipt**:

- A custom ASIC die (Trinity Node) contains a **silicon anchor** — a physically unclonable function (PUF)-adjacent construct derived from manufacturing-time die-level variation, recorded in the shuttle manifest as anchor `0x47C0`.  
- Each inference execution produces a **receipt struct** (defined in the Trinity v1.0.0 AI format spec) containing: model hash, weight checkpoint hash, input hash (salted), output hash, die anchor signature, and a monotonic counter.  
- Receipts are signed by the die's on-chip key material and anchored to a public ledger (Trinity testnet / mainnet), making them independently auditable by any party with access to the public format spec.  

**What has been demonstrated prior to this application (TRL 5–6):**
- Three dies (tt-trinity-phi, tt-trinity-euler, tt-trinity-gamma) submitted to the TT SKY26b shuttle; tape-out completed; anchor `0x47C0` registered.
- v1.0.0 format module specification published.
- DARPA CLARA proposal submitted on the US side (separate programme; no dual-use export conflict because all Trinity technology is fully published).
- Preliminary open-source RTL and GDS published under AGPL-3.0.

**What this grant enables (TRL 6→8):**
- Port to IHP SG13G2 (EU foundry) and tape-out submission.
- First production run of 1,000 Trinity Node units.
- EU testnet and, in Month 19–24, mainnet launch with 10,000+ nodes.

### 2.3 Beyond the State of the Art

The table below places Trinity against the most relevant alternatives. All comparisons are based on publicly documented technical capabilities.

| Approach | Provider | Hardware root | Open design | EU-fabbed | AI Act Art. 12 receipt |
|---|---|---|---|---|---|
| Confidential computing (GPU) | Nvidia H100 | TEE (closed) | No | No | No |
| Cloud AI inference logging | AWS / Azure / GCP | None (app-layer) | No | No | No |
| Zero-knowledge ML (ZKML) | Ritual, Modulus Labs | Software only | Partial | No | Partial (proof only) |
| Decentralised compute | Bittensor (TAO) | None | Partial | No | No |
| Open silicon + TEE | Intel SGX + RISC-V | TEE (closed vendor) | Partial | No | No |
| **Trinity DePIN (this project)** | **Trinity OÜ** | **Silicon PUF-anchor** | **Yes (AGPL-3.0)** | **Yes (IHP, Frankfurt-Oder)** | **Yes (v1.0.0 spec)** |

Trinity is the only approach combining: (a) open RTL published before application; (b) EU foundry fabrication; (c) a standardised, auditable receipt format aligned with AI Act Article 12 requirements.

---

## 3. MARKET AND BUSINESS MODEL

### 3.1 Market Sizing

**Total Addressable Market (TAM):** The global verifiable AI inference and AI compliance tooling market is projected to reach **€40 billion by 2030** (preliminary estimate based on Gartner 2025 AI infrastructure forecasts; [Gartner Newsroom](https://www.gartner.com/en/newsroom/press-releases)). This is driven by the convergence of mandatory AI auditing requirements (EU AI Act, anticipated US federal AI legislation, NIST AI RMF adoption) with the rapid deployment of AI in regulated sectors.

**Serviceable Addressable Market (SAM):** EU regulated industries subject to the AI Act high-risk category (Annex III: healthcare diagnostics, credit scoring, employment screening, critical infrastructure management, public-sector automated decisions) represent an estimated **€8 billion** annual spend on AI infrastructure by 2030 where Article 12 compliance logging is a hard requirement (*preliminary; based on EU Commission Impact Assessment SWD(2021) 84 final, Section 5*).

**Serviceable Obtainable Market (SOM):**

| Year | Projection (preliminary) | Key driver |
|---|---|---|
| Year 1 | €500,000 | Early adopter hardware kit sales + EU testnet |
| Year 2 | €2,500,000 | Enterprise pilot contracts (automotive, e-gov) |
| Year 3 | €8,000,000 | AI Act compliance deadline pressure (Aug 2026 transparency rules) |
| Year 4 | €16,000,000 | Mainnet, 10K nodes, SaaS ARR |
| Year 5 | €25,000,000 | Market leadership in EU verifiable inference |

### 3.2 Revenue Model

Trinity's revenue model is multi-stream:

1. **Hardware kit sales:** Trinity Node hardware (retail target: **€250 per unit**). Node operators earn $TRI token rewards by providing verifiable inference capacity to the network. Hardware margin (preliminary): ~35%.

2. **Enterprise SaaS — Compliance Pack:** Annual subscription for enterprises deploying Trinity for AI Act Article 12 compliance. Includes receipt management dashboard, TÜV/SGS-ready audit export, GDPR-compliant log storage. Pricing target: €5,000–€50,000 per year depending on inference volume. 

3. **$TRI Utility Token:** Network coordination token used to pay for inference requests, stake node capacity, and govern protocol upgrades. **Note:** $TRI is positioned strictly as a utility token. MiCA (Regulation (EU) 2023/1114) classification review will be completed before mainnet (see Section 5, M13–M18). The token offering is a **separate legal instrument** from the EIC grant and equity components. No grant or equity funds are used to acquire $TRI.

4. **Protocol licensing / white-label:** EU public-sector bodies and certified laboratories may license the Trinity receipt format and verification infrastructure under a commercial licence.

### 3.3 Customer Validation

*The following are indicative target customer segments. Formal Letters of Intent are being solicited and will be included in the full proposal submission:*

- **German automotive OEM (TBD):** AI Act Annex III, point 6 covers AI in vehicles managing critical infrastructure. OEMs face Article 12 compliance for in-vehicle AI decision systems. Potential LoI from Tier-1 supplier in Stuttgart region.
- **Estonian e-Government (TBD):** Estonia's X-Road infrastructure and digital governance leadership make it a natural early adopter of hardware-anchored AI receipts. Potential LoI from Estonian Information System Authority (RIA) or e-Residency programme.
- **French health-tech (TBD):** AI-assisted diagnostics tools fall under AI Act Annex III, point 1. Healthcare AI providers face stringent Article 12 requirements. Potential LoI from a Paris-based MedTech SME.

---

## 4. TEAM AND COMPANY

### 4.1 Principal Investigator: Dmitrii Vasilev

Dmitrii Vasilev is the architect of the Trinity DePIN protocol. He brings combined expertise in open-source hardware design, AI systems engineering, and decentralised network protocols.

- **Open-source track record:** 20+ public repositories across hardware description languages (Verilog/SystemVerilog), AI inference tooling, and protocol design.
- **Silicon experience:** Trinity dies tt-trinity-phi/euler/gamma submitted to TT SKY26b shuttle, anchor `0x47C0` registered.
- **Academic record:** Project documentation and v1.0.0 format specification published on Zenodo under DOI [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877).
- **Location:** Cape Town, South Africa. **Note on eligibility:** As an individual intending to establish an EU SME, Dmitrii Vasilev is eligible to apply to EIC Accelerator under the "natural persons willing to set up an SME" category ([EIC Accelerator programme guide, WP2026](https://eic.ec.europa.eu/eic-funding-opportunities/eic-accelerator_en)). The legal entity **Trinity DePIN OÜ** (Estonia, e-Residency path) must be incorporated before submission of the full proposal (Step 2). A Germany GmbH alternative is also under consideration to maximise alignment with the IHP Frankfurt (Oder) manufacturing partner. **Relocation to EU is confirmed as a condition of grant signature.**

### 4.2 sole authorship and IP Provenance


### 4.3 EU Advisory Board (Proposed — TBD)

The following EU expertise slots are identified for appointment before full-proposal submission:

- **IHP GmbH Director or SG13G2 process lead** (Frankfurt-Oder, Germany): fab partnership anchor and process validation oversight.
- **Fraunhofer IIS / Fraunhofer IPMS expert in silicon verification:** cryptographic hardware attestation and PUF-based identity systems. Fraunhofer IPMS has prior experience with IHP process nodes.
- **Prof. Onur Mutlu (ETH Zurich, D-INFK):** computer architecture and memory systems; has published extensively on open silicon and systems verification.

### 4.4 Proposed Team Build-out (Months 1–24)

| Role | FTE | Start month | Location |
|---|---|---|---|
| Hardware Design Engineer (IHP SG13G2) | 1.0 | M1 | Germany (Frankfurt-Oder / Berlin) |
| RTL / Verification Engineer | 1.0 | M1 | EU (remote) |
| AI Systems Engineer | 1.0 | M3 | EU (remote) |
| Business Development / Compliance | 1.0 | M6 | EU |
| Legal / MiCA / AI Act Counsel | 0.5 | M12 | EU |

### 4.5 Legal Entity

**Proposed:** Trinity DePIN OÜ (Estonia, e-Residency programme). Estonia's digital-first legal infrastructure and membership in the euro area make it the preferred vehicle. Alternative: Germany GmbH with registered office in Berlin or Frankfurt (Oder), which would directly co-locate with IHP. Final decision by end of Month 1 of the grant. **The legal entity must be established prior to submission of the full Step 2 proposal.**

---

## 5. IMPLEMENTATION PLAN AND MILESTONES (24 MONTHS)

### 5.1 Work Package Overview

| WP | Title | Months | Lead |
|---|---|---|---|
| WP1 | IHP SG13G2 Porting and Tape-Out | M1–M6 | PI + HW Engineer |
| WP2 | Trinity Node v1 Manufacturing and Integration | M7–M12 | PI + RTL Engineer |
| WP3 | EU Testnet Launch and Operator Onboarding | M7–M12 | PI + AI Systems Engineer |
| WP4 | AI Act Compliance Pack + MiCA Review | M13–M18 | BD/Compliance + Legal |
| WP5 | Mainnet Launch and Scale | M19–M24 | All team |
| WP6 | Dissemination, Open Science, Standardisation | M1–M24 | PI |

### 5.2 Milestone Schedule

**Milestone 1 (M6):** IHP SG13G2 port of Trinity Node ASIC completed; DRC/LVS clean layout verified; tape-out submission to IHP accepted.  
*Verification criterion:* Tape-in confirmation receipt from IHP pilot line.

**Milestone 2 (M12):** First batch of 1,000 Trinity Node units manufactured and tested; minimum 80% functional yield; hardware wallets provisioned with die-level anchor keys.  
*Verification criterion:* Functional test report signed by PI; IHP shipping confirmation.

**Milestone 3 (M12):** EU testnet live with minimum 50 node operators across ≥3 EU Member States; public receipt explorer operational.  
*Verification criterion:* Public testnet block explorer URL; operator geographic distribution log.

**Milestone 4 (M18):** AI Act Compliance Pack v1.0 released; independent legal opinion from EU-qualified firm on Article 12 receipt adequacy; MiCA utility-token opinion obtained from Luxembourg or Estonian financial regulator.  
*Verification criterion:* Published legal opinions (redacted where necessary); Compliance Pack documentation.

**Milestone 5 (M24):** Mainnet launch; ≥10,000 Trinity Nodes deployed across EU; independent security audit completed by Trails of Bits (or equivalent) and a EU-certified body (SGS or TÜV Rheinland); ARR ≥€1M from enterprise SaaS.  
*Verification criterion:* Audit reports; mainnet explorer showing node count; signed enterprise contracts.

### 5.3 Critical Path

The critical path runs through WP1 (IHP tape-out). IHP's SG13G2 PDK is open-source (published on GitHub under Apache-2.0), and the project team has already written an IHP26b port specification drawing from the TT SKY26b experience. IHP's pilot line operates 24/7 in a 1,500 m² cleanroom on 200-mm wafers, with typical processing time of approximately 12 weeks from tape-in to diced chips ([IHP Microelectronics — Leibniz Institute](https://monitor-industrial-ecosystems.ec.europa.eu/technology-centre/ihp-leibniz-institute-high-performance-microelectronics)). A shuttle slot is being explored via the Free Silicon Conference / IHP open shuttle programme.

---

## 6. IMPACT

### 6.1 Economic Impact

| Metric | Year 3 | Year 5 |
|---|---|---|
| Direct EU jobs (FTE) | 15 | 50 |
| Annual Recurring Revenue | €8M (preliminary) | €25M (preliminary) |
| Company valuation target | €30–50M | €100M+ |
| Hardware units in market | 5,000 | 50,000+ |

The 50 high-skill EU jobs by Year 5 are concentrated in hardware design, embedded systems, AI systems engineering, and compliance technology — all in shortage across the EU. Preferred hiring will target Germany, Estonia, France, and the Netherlands.

### 6.2 Strategic and Sovereignty Impact

**First EU-fabbed verifiable AI inference chip.** By manufacturing exclusively at IHP (Frankfurt-Oder, Germany), Trinity becomes the first commercially deployed verifiable AI ASIC produced within the EU. This directly:

- Reduces dependence on TSMC (Taiwan) and US hyperscaler AI infrastructure.
- Qualifies under EU Chips Act Open EU Foundry provisions (Article 6, Regulation (EU) 2023/1781).
- Creates an auditable alternative to Nvidia GPU-based inference, addressing supply-chain concentration risk explicitly identified in the EU Chips Act Impact Assessment.

The **GAIA-X** initiative has established principles for European cloud sovereignty. Trinity's open-silicon, EU-fabbed inference node is a natural compute primitive for GAIA-X compliant AI services — verifiable at the hardware level, with receipts storable in GAIA-X data spaces.

### 6.3 Regulatory Impact

**Direct enablement of AI Act Article 12 compliance.** The Trinity hardware receipt provides:
- Model hash (identifies which AI model ran).
- Weight checkpoint hash (identifies which training state).
- Input hash (salted — no personal data in the receipt itself, satisfying GDPR Article 25 data-minimisation principle).
- Output hash.
- Die anchor signature (unforgeable hardware identifier).
- Monotonic counter (prevents receipt replay).

This receipt structure satisfies the Article 12(2) requirements to record events relevant to traceability of system functioning, post-market monitoring (Article 72), and facilitating deployer monitoring (Article 26(5)). Trinity's Compliance Pack is designed to be submitted as a potential **EU reference architecture** to the European AI Office (established under AI Act Article 64).

### 6.4 Open Science and Public Good

All RTL, GDS, format specifications, test benches, and academic papers produced under this grant will be published under **AGPL-3.0** (software/HDL) and **CC-BY-4.0** (documentation and papers). This maintains full interoperability with the existing open-silicon ecosystem (OpenROAD, Yosys, Magic, IHP SG13G2 PDK) while ensuring that any commercial derivative must contribute back. Zenodo DOI [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) will be updated with each major release.

### 6.5 Climate Impact

A single **Trinity Node** consumes approximately **5 W** during inference operation. An equivalent Nvidia H100 GPU consumes approximately **700 W**. For workloads that are satisfied by Trinity's inference capabilities (small-to-medium language models, edge AI for high-risk systems), the energy efficiency gain is ~140×. At 10,000 deployed nodes, the total Trinity network consumes ~50 kW versus ~7 MW for a GPU-based equivalent — a reduction of approximately **6,950 kW continuous power consumption**. This contributes directly to the EU's **Climate-Neutral and Smart Cities Mission** and the REPowerEU plan's digital-efficiency targets.

---

## 7. RISKS AND MITIGATION

| Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|
| IHP SG13G2 shuttle slot unavailable or delayed | Medium | High | Primary: TT IHP shuttle programme (already in contact). Secondary: efabless IHP shuttle pathway. Tertiary: re-port to GF180MCU (GlobalFoundries 180nm, EU-friendly, FOSS PDK). Timeline contingency: 3 months buffer in WP1. |
| Die yield below 80% on first tape-out | Medium | Medium | Conservative design rules; full DRC/LVS sign-off before tape-in; second shuttle slot reserved in budget. |
| $TRI token classified as security (MiCA risk) | Low–Medium | High | Legal opinion from Luxembourg or Estonian financial regulator before mainnet. Revenue model does not depend on token appreciation; token is strictly for network coordination. Token launch delayed until favourable opinion received (M18 gate). |
| AI Act Article 12 interpretation narrower than expected | Low | Medium | Proactive engagement with European AI Office; Compliance Pack peer-reviewed by EU-qualified legal firm. Trinity receipt is designed to exceed minimum requirements. |
| Talent scarcity: IHP SG13G2 designers in EU | Medium | High | Mitigation: partnership with TU Berlin (IHP is 90 minutes away); Fraunhofer IPMS collaboration; RISC-V / open-silicon community hiring. Salary bands set at Berlin tech market rate. |
| Export control / dual-use (DARPA CLARA / US defence) | Low | High | DARPA CLARA is a separate US-side programme. Trinity technology is fully published (AGPL-3.0) before any EU grant activity. Fully open-source publication is the strongest available anti-dual-use control: there is no restricted export because there is no secret. The relevant EU dual-use regulation (Regulation (EU) 2021/821) does not apply to technology in the public domain. This analysis will be formally documented in the Ethics and Security Self-Assessment. |
| Competitor (Nvidia, Intel TEE) rapid response | Low | Medium | Trinity's competitive moat is the open-silicon + EU-fab combination, not performance alone. Regulatory alignment with AI Act is a 2–3 year lead given hardware development cycles. |

---

## 8. BUDGET

### 8.1 Grant Component — €2,500,000

| Budget line | Cost (€) | Justification |
|---|---|---|
| **WP1 — IHP SG13G2 tape-out** | 800,000 | Shuttle slot fee + mask set (SG13G2 shuttle estimated €600K–€800K based on IHP commercial rates); layout tools; tape-in preparation |
| **WP2 — Hardware manufacturing (1,000 units, prototype run)** | 200,000 | PCB, packaging, functional test, logistics |
| **Personnel — 5 FTE × 24 months** | 1,000,000 | At blended cost of ~€83K/FTE/year (Berlin/Tallinn market rate inclusive of employer contributions) |
| **Independent security audit (Trails of Bits or equivalent)** | 150,000 | Smart contract and hardware firmware audit |
| **EU certification body (SGS or TÜV Rheinland)** | 150,000 | Hardware security evaluation; Compliance Pack certification support |
| **Legal — MiCA opinion + AI Act legal review** | 100,000 | External EU-qualified legal counsel |
| **Dissemination — papers, conferences, open-source releases** | 100,000 | Publication fees, IEEE/ACM conference travel, community outreach |

*Total grant: €2,500,000 (lump-sum contribution, EIC standard terms)*

### 8.2 Equity Component — up to €15,000,000

The equity component (EIC Fund investment) is targeted primarily for Year 2–3 activities beyond the grant scope:

| Use of equity | Estimated amount | Timing |
|---|---|---|
| Series manufacturing (Trinity Node, 10,000+ units) | €5,000,000 | Year 2 |
| Mainnet infrastructure and security | €2,000,000 | Year 2–3 |
| Enterprise sales and business development (EU market) | €3,000,000 | Year 2–3 |
| Working capital and legal/regulatory | €2,000,000 | Year 2–3 |
| R&D: Trinity Node v2 (next-generation IHP process) | €3,000,000 | Year 3 |

*The equity investment will be subject to EIC Fund due diligence per standard terms. Trinity DePIN OÜ will provide audited financial statements, cap table, and FTO analysis at due diligence stage.*

---

## 9. EU STRATEGIC ALIGNMENT

### 9.1 EU Chips Act (Regulation (EU) 2023/1781)

The EU Chips Act mobilises €43 billion to strengthen European semiconductor design and manufacturing capacity ([European Chips Act — Digital Strategy](https://digital-strategy.ec.europa.eu/en/policies/european-chips-act)). Trinity DePIN directly advances Chips Act objectives:

- **Pillar 1 (Research and Innovation):** Trinity is an open-silicon research output, using and extending the IHP SG13G2 PDK — a public-research foundry technology developed with German/EU federal funding.
- **Pillar 2 (Security of Supply):** By manufacturing at IHP (EU soil, German public-research infrastructure), Trinity demonstrates a viable path for AI silicon outside US/Asia supply chains.
- **Open EU Foundry status:** IHP is a natural candidate for Open EU Foundry status under Article 6 of the Chips Act. A project that demonstrates a commercially viable product using IHP's open PDK strengthens the case for IHP's OEF designation.

### 9.2 AI Act (Regulation (EU) 2024/1689)

Trinity is designed from first principles to enable Article 12 compliance. Key alignment points:

- **Article 12 (Record-keeping):** Trinity receipt struct provides the technical mechanism for automatic event recording with appropriate traceability ([AI Act Service Desk — Article 19](https://ai-act-service-desk.ec.europa.eu/en/ai-act/article-19)).
- **Article 13 (Transparency):** The open format spec (AGPL-3.0) and published Compliance Pack documentation address instructions-for-use requirements.
- **Article 16(e) (Provider log obligations):** Trinity's hardware-rooted logs are under the deployer's control by design — the private key material for receipt signing is held on-die, not by a cloud provider.
- **Recital 71 (Traceability throughout lifetime):** Trinity receipts are immutably anchored to a public ledger and archived with monotonic counter, satisfying the lifetime traceability expectation ([AI Act Service Desk — Recital 71](https://ai-act-service-desk.ec.europa.eu/en/ai-act/recital-71)).

### 9.3 Digital Sovereignty / GAIA-X

GAIA-X ([gaia-x.eu](https://gaia-x.eu)) establishes technical and governance standards for European cloud federation. Trinity's verifiable inference receipts — produced by EU-fabbed silicon, under open-source protocol — constitute a compute trust anchor compatible with GAIA-X data space architectures. Trinity Node could serve as the reference compute primitive for GAIA-X Labelled AI services requiring hardware attestation.

### 9.4 Horizon Europe Mission: Climate-Neutral and Smart Cities

As detailed in Section 6.5, Trinity Nodes achieve approximately 140× better energy efficiency per inference than GPU-based alternatives for eligible workloads. This is directly relevant to the 100 Climate-Neutral and Smart Cities Mission, which requires cities to achieve net-zero digital infrastructure by 2030. Edge-deployed Trinity Nodes in city AI systems (traffic management, energy grid AI, public-service automation) contribute to this target.

---

## 10. ETHICS AND DATA PROTECTION

### 10.1 Ethics Summary

This project presents **low direct ethical risk**. The technology enables verifiable audit of AI inference; it does not itself perform inference on sensitive data, conduct surveillance, or process biometric information.

**No research on human subjects** is conducted in this project. All technical development is on hardware design, protocol engineering, and software tooling.

**No personal data** is processed in Trinity inference receipts. Receipts contain only cryptographic hashes (SHA-256 or Keccak-256) of inputs and outputs; no plaintext, no biometric data, no personal identifiers. This is a GDPR Article 25 data-minimisation-by-design choice. The hash scheme uses salting to prevent reverse-lookup of known inputs.

### 10.2 GDPR Compliance

- **Data controller:** Trinity DePIN OÜ (EU entity) for any enterprise customer data processed via SaaS.
- **Data processed:** Cryptographic hashes only; not personal data within the meaning of GDPR Article 4(1).
- **Data storage:** Receipts stored on public ledger (public by design); no private personal data stored on-chain.
- **Privacy impact assessment (PIA):** Will be conducted before enterprise SaaS launch (M13–M18).

### 10.3 Dual-Use and Security

Trinity technology is fully published under AGPL-3.0 before any EU grant activity commences. **Fully open-source technology is not subject to EU dual-use export controls** under Regulation (EU) 2021/821, Article 2(1) — "technology in the public domain" is explicitly excluded from control scope.

The DARPA CLARA proposal (US-side, separate programme) covers US national security use cases. There is no operational overlap with this EIC Accelerator proposal. The two programmes are legally and technically independent. No EIC grant or equity funds will be used for any activity under the DARPA programme. This will be formally attested in the project's Security Self-Assessment submitted with the full proposal.

### 10.4 Open-Source Licence and Responsible Use

The AGPL-3.0 licence ensures that all modifications and commercial deployments must contribute back to the open commons. The licence explicitly does not restrict use; however, Trinity DePIN OÜ will publish a **responsible use policy** prohibiting use of Trinity infrastructure for: (a) unlawful surveillance; (b) AI systems prohibited under AI Act Article 5; (c) violation of EU sanctions.

---

## 11. REFERENCES

1. **EU AI Act** — Regulation (EU) 2024/1689 of the European Parliament and of the Council of 13 June 2024 laying down harmonised rules on artificial intelligence. OJ L, 2024/1689, 12.7.2024. [https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32024R1689](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32024R1689)

2. **EU Chips Act** — Regulation (EU) 2023/1781 of the European Parliament and of the Council of 13 September 2023 establishing a framework of measures for strengthening Europe's semiconductor ecosystem. OJ L 229, 18.9.2023. [https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32023R1781](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32023R1781)

3. **EU Chips Act — Digital Strategy overview.** European Commission. [https://digital-strategy.ec.europa.eu/en/policies/european-chips-act](https://digital-strategy.ec.europa.eu/en/policies/european-chips-act)

4. **MiCA** — Regulation (EU) 2023/1114 of the European Parliament and of the Council of 31 May 2023 on markets in crypto-assets. OJ L 150, 9.6.2023. [https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32023R1114](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32023R1114)

5. **EIC Accelerator Guide for Applicants, WP2026.** European Innovation Council, November 2025. [https://eic.ec.europa.eu/eic-funding-opportunities/eic-accelerator_en](https://eic.ec.europa.eu/eic-funding-opportunities/eic-accelerator_en)

6. **EIC Accelerator Guide PDF, WP2026.** [https://eic.ec.europa.eu/document/download/9d96fbf3-4d85-4ad0-9483-c77ce348111d_en?filename=EIC+Accelerator+guide+for+applicants_WP26.pdf](https://eic.ec.europa.eu/document/download/9d96fbf3-4d85-4ad0-9483-c77ce348111d_en?filename=EIC+Accelerator+guide+for+applicants_WP26.pdf)

7. **AI Act Service Desk — Article 19 (Automatically generated logs).** European Union. [https://ai-act-service-desk.ec.europa.eu/en/ai-act/article-19](https://ai-act-service-desk.ec.europa.eu/en/ai-act/article-19)

8. **AI Act Service Desk — Recital 71 (Traceability).** European Union. [https://ai-act-service-desk.ec.europa.eu/en/ai-act/recital-71](https://ai-act-service-desk.ec.europa.eu/en/ai-act/recital-71)

9. **IHP Microelectronics — Leibniz Institute for High Performance Microelectronics.** European Monitor Industrial Ecosystems. Im Technologiepark 25, 15236 Frankfurt (Oder), Germany. [https://monitor-industrial-ecosystems.ec.europa.eu/technology-centre/ihp-leibniz-institute-high-performance-microelectronics](https://monitor-industrial-ecosystems.ec.europa.eu/technology-centre/ihp-leibniz-institute-high-performance-microelectronics)

10. **IHP SG13G2 PDK.** Open-source BiCMOS process design kit. [https://github.com/IHP-GmbH/IHP-Open-PDK](https://github.com/IHP-GmbH/IHP-Open-PDK)

11. **EU Dual-Use Regulation** — Regulation (EU) 2021/821 of the European Parliament and of the Council of 20 May 2021 setting up a Union regime for the control of exports, brokering, technical assistance, transit and transfer of dual-use items. OJ L 206, 11.6.2021. [https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32021R0821](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32021R0821)

12. **Trinity DePIN v1.0.0 format specification.** Zenodo DOI 10.5281/zenodo.19227877. [https://doi.org/10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

13. **TT SKY26b Shuttle (Tiny Tapeout).** [https://tinytapeout.com](https://tinytapeout.com)

14. **gHashTag/Trinity repositories.** [https://github.com/gHashTag](https://github.com/gHashTag)

15. **EU Commission Impact Assessment, AI Act.** SWD(2021) 84 final. [https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=SWD%3A2021%3A84%3AFIN](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=SWD%3A2021%3A84%3AFIN)

16. **Commission Decisions — Open EU Foundry and Integrated Production Facility designations under Chips Act.** October 2025. [https://digital-strategy.ec.europa.eu/en/library/commission-decisions-strengthening-europes-semiconductor-manufacturing-capacity-under-chips-act](https://digital-strategy.ec.europa.eu/en/library/commission-decisions-strengthening-europes-semiconductor-manufacturing-capacity-under-chips-act)

17. **GAIA-X European Cloud Federation.** [https://gaia-x.eu](https://gaia-x.eu)

18. **Gartner AI Infrastructure Forecasts 2025.** [https://www.gartner.com/en/newsroom/press-releases](https://www.gartner.com/en/newsroom/press-releases)

---

*Document version: Draft v0.1 for internal review.*  
*Prepared for EIC Accelerator Open submission — WP2026.*  
*All financial figures marked "preliminary" are estimates subject to revision in the full-proposal financial annex.*  
*All "TBD" items (LoIs, advisors, legal entity) are pre-conditions for Step 2 (full proposal) submission.*
