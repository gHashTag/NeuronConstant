# EU AI Act Compliance Pack: Trinity DePIN HW-Anchored Receipts
### Mapping Silicon-Signed Inference Receipts to Regulation (EU) 2024/1689

**Version:** 1.0-draft | **Anchor:** 0x47C0 | **Date:** 2025

---

## Table of Contents

1. [Why This Matters](#1-why-this-matters)
2. [Article-by-Article Mapping Table](#2-article-by-article-mapping-table)
3. [High-Risk Use Cases Enabled](#3-high-risk-use-cases-enabled)
4. [GPAI Provider Obligations Details](#4-gpai-provider-obligations-details)
5. [EU AI Office Liaison Plan](#5-eu-ai-office-liaison-plan)
6. [Conformity Assessment Pathway](#6-conformity-assessment-pathway)
7. [Documentation Template](#7-documentation-template)
8. [GDPR Interplay](#8-gdpr-interplay)
9. [Penalties Avoided & ROI for Customer](#9-penalties-avoided--roi-for-customer)
10. [Roadmap & TBD Items](#10-roadmap--tbd-items)
11. [References](#11-references)

---

## 1. Why This Matters

### The Regulatory Stakes

Regulation (EU) 2024/1689 — the **EU AI Act** — entered into force on 1 August 2024, with obligations phasing in as follows:

| Phase | Effective Date | Scope |
|-------|---------------|-------|
| Prohibited practices | **2 February 2025** | Art. 5 prohibited AI systems |
| GPAI obligations | **2 August 2025** | General-purpose AI providers (Art. 51–55) |
| High-risk (Annex III) | **2 August 2026** | Critical infra, healthcare, recruitment, law enforcement, etc. |
| High-risk (Annex I) | **2 August 2027** | Product-safety legislation embedded AI |

**Penalties** under Art. 99:
- Up to **€35,000,000** or **7% of total worldwide annual turnover** (whichever is higher) for prohibited-practice violations
- Up to **€15,000,000** or **3% of turnover** for high-risk system violations
- Up to **€7,500,000** or **1% of turnover** for incorrect information to notified bodies

### The Missing Primitive: Cryptographically Proven, Non-Tampered Logs

Article 12 of the EU AI Act requires high-risk AI systems to automatically generate event logs that are **"sufficient to ensure traceability of the AI system's functioning throughout its lifecycle."** Current state of the art:

| Approach | Tamper Evident? | Cryptographically Verifiable? | Chain-of-Custody | Meets Art. 12? |
|----------|----------------|------------------------------|------------------|---------------|
| Centralized logging (ELK, Splunk) | ✗ (admin can edit) | ✗ | None | **No** |
| Cloud audit trails (AWS CloudTrail) | Partial (trust AWS) | ✗ | Vendor-dependent | **Questionable** |
| Blockchain event logging | Partial (no HW attestation) | Partial | On-chain hash only | **Partial** |
| **Trinity HW-Anchored Receipts** | ✓ (silicon-signed at TEE) | ✓ (secp256k1 + CBOR) | Full: inference → anchor 0x47C0 | **✓ Yes** |

### Trinity's Unique Position

Trinity provides **silicon-signed inference receipts** — hardware-rooted cryptographic proofs, generated inside a Trusted Execution Environment (TEE), that:

1. **Identify the exact model** (SHA-256 hash of model weights, format NF4/Posit16/etc.)
2. **Attest the computation** (input hash → output hash, signed by hardware key)
3. **Anchor on-chain** (LayerZero cross-chain anchor at `0x47C0`, creating an immutable timestamp)
4. **Feed the audit trail** (R-SI-1 continuous audit log, append-only, cryptographically linked)

This is **the missing primitive** that bridges the gap between AI Act compliance requirements and real-world AI system operation. No existing infrastructure — cloud, on-premise, or blockchain-only — provides hardware-root-of-trust attestation at inference time.

**Trinity receipts transform regulatory compliance from a paperwork exercise into a cryptographic guarantee.**

---

## 2. Article-by-Article Mapping Table

The following table maps each key EU AI Act obligation to the specific Trinity DePIN primitive that satisfies it, along with the evidence path and current implementation status.

> **Status Key:**
> - ✅ **Covered** — Fully satisfied by current Trinity implementation
> - 🟡 **Partial** — Core mechanism exists; documentation or tooling gaps remain
> - 🔲 **TBD** — Planned; not yet implemented

---

### Core High-Risk System Obligations (Chapter III, Section 2)

| Article & Key Obligation | Trinity Primitive | Evidence Path | Status |
|--------------------------|-------------------|---------------|--------|
| **Art. 9 — Risk Management System** <br>Providers must establish, implement, document, and maintain a risk management system throughout the AI system lifecycle (Art. 9(1)). Must include continuous iterative risk identification, evaluation, and mitigation (Art. 9(2)). Risk management measures must be reviewed post-market deployment (Art. 9(9)). | **R-SI-1 continuous audit trail.** Every inference event writes a signed record to the R-SI-1 log. Any deviation from registered model hash or output-distribution fingerprint triggers automatic slashing of the node operator. Slashing events are on-chain and immutable. | R-SI-1 log schema: `schema/r-si-1.cbor`; slashing contract: chain anchor `0x47C0`; post-market monitoring: R-SI-1 telemetry dashboard at `/monitoring/rsi1/` | ✅ **Covered** |
| **Art. 10 — Data and Data Governance** <br>Training, validation, and testing datasets must meet quality criteria; data governance practices must cover collection, preprocessing, annotation, labelling, storage, filtration, and bias examination (Art. 10(2)). Datasets must be relevant, representative, free of errors, and complete (Art. 10(3)). | **Filecoin-anchored training bundles.** Training data bundles are stored on Filecoin with content-addressed CIDs. Bundle hashes are anchored on-chain at the time of training initiation via M-of-N attestation. Any alteration to training data post-attestation is cryptographically detectable. | Training bundle CID policy: `docs/training-bundle-cid-policy.md`; on-chain hash anchor: LayerZero message with training CID embedded; Filecoin deal IDs: recorded in R-SI-1 training log entries | 🟡 **Partial** — Data quality annotations (bias examination) require additional tooling beyond hash attestation |
| **Art. 12 — Record-Keeping** <br>High-risk AI systems must automatically log events throughout the period of use, including the period each use of the system starts and ends, the reference database against which input data was checked, input data that led to the AI system's output where technically feasible (Art. 12(2)), and sufficient information to identify the natural persons involved in the verification of results where applicable (Art. 12(3)). Logs must be kept by the deployer for a period "appropriate to the intended purpose of the high-risk AI system, of at least six months" (Art. 12(4)). | **Silicon-signed inference receipts with on-chain anchor.** Every inference produces a CBOR-encoded receipt containing: timestamp (Unix + block height), model hash (SHA-256), input hash (SHA-256, no raw PII), output hash (SHA-256), format flag (NF4/Posit16/etc.), TEE attestation signature (secp256k1, hardware key). Receipt anchored at `0x47C0` via LayerZero within ≤2 block confirmation. | Receipt schema: `schema/receipt-v1.cbor`; anchor contract: `0x47C0`; example receipt: Section 7.2 of this document; R-SI-1 audit trail integrates receipts into time-ordered append-only log; retention: configurable 6 months to indefinite | ✅ **Covered** |
| **Art. 13 — Transparency and Provision of Information to Deployers** <br>High-risk AI systems must be designed and developed to ensure sufficient transparency to enable deployers to interpret the system's output and use it appropriately (Art. 13(1)). Instructions for use must specify: the identity of the provider, the characteristics and capabilities of the system, the level of accuracy, intended purpose, human oversight measures, and technical capabilities (Art. 13(3)). | **Receipt-embedded model manifest.** Every receipt includes: model hash (SHA-256), quantization format (NF4, Posit16, INT8, etc.), serving node ID, champion BPB fingerprint, and a link to the model card on Zenodo. Deployers can call the **verifier reference implementation** (Section 7.3) to confirm the receipt matches the deployed model manifest at any time. | Receipt field `model_manifest_cid`: points to IPFS-hosted model card; Zenodo DOI: `10.5281/zenodo.19227877`; verifier script: `tools/verify_receipt.py`; model card template: `docs/model-card-template.md` | ✅ **Covered** |
| **Art. 14 — Human Oversight** <br>High-risk AI systems must be designed and developed to enable effective human oversight. Deployers must assign oversight to natural persons with necessary competence, training, and authority. Systems must allow overseers to understand capabilities and limitations, override or interrupt output (Art. 14(3)), and prevent automation bias (Art. 14(4)). | **M-of-N quorum for high-stakes training decisions.** Model updates and high-stakes training operations require a cryptographically enforced M-of-N threshold signature from designated operator keyholders. No single actor can unilaterally push a model update. The quorum transaction is recorded on-chain. For inference: receipt-based output flagging allows deployers to mark receipts as "human-reviewed" by appending a signed endorsement record to the R-SI-1 log. | M-of-N quorum contract: `contracts/MofNQuorum.sol`; governance threshold parameters: configurable per deployment (default: 3-of-5); on-chain quorum record: LayerZero anchor with operator key set hash | 🟡 **Partial** — Human oversight tooling for deployer-side automation-bias detection is TBD; core quorum mechanism is complete |
| **Art. 15 — Accuracy, Robustness, and Cybersecurity** <br>High-risk AI systems must be designed to achieve appropriate levels of accuracy and robustness throughout the lifecycle. Systems must be resilient against errors, faults, and inconsistencies, and against attempts by unauthorized third parties to alter the use, outputs, or performance (Art. 15(4)). | **Champion BPB lock + Lucas POST (Power-On Self-Test).** The champion model's Bits Per Byte (BPB) benchmark is hard-locked at registration time. Lucas POST runs at every node boot, executing a deterministic inference test against the locked champion benchmark. Any regression in BPB beyond threshold (configurable, default ±0.1%) causes the node to refuse to serve and triggers R-SI-1 alert. Prevents silent model degradation, bit-rot, or adversarial weight tampering. | BPB lock record: embedded in on-chain model registration transaction; Lucas POST spec: `docs/lucas-post-spec.md`; POST failure event: emitted on-chain as `ModelRegressionAlert(nodeId, expected_bpb, actual_bpb)` | ✅ **Covered** |
| **Art. 17 — Quality Management System** <br>Providers of high-risk AI systems must put a quality management system in place to ensure compliance (Art. 17(1)), covering: strategy for regulatory compliance, techniques for design control, processes for training/testing/data management, technical documentation, change management, post-market monitoring, and record-keeping (Art. 17(1)(a–l)). | **Full reproducibility package on Zenodo.** Trinity's quality management system is externalized as a public, versioned reproducibility package: training configuration (YAML), model architecture (RTL + GDS where applicable), benchmark suite, test vectors, and formal theorem statements (Theorem 36.1 and dependencies). DOI-anchored on Zenodo for immutability. Change management: all updates trigger new Zenodo DOI + new on-chain model registration. | Zenodo DOI: `10.5281/zenodo.19227877`; GitHub repositories: `gHashTag/*`; change management workflow: `docs/change-management.md`; formal theorems: `proofs/theorem36-1.lean` | 🟡 **Partial** — Full QMS documentation set (change control SOPs, post-market monitoring procedures) requires additional formal documentation |
| **Art. 23 — Cooperation with Competent Authorities** <br>Providers and deployers of high-risk AI systems must cooperate with national competent authorities and the EU AI Office upon request, providing access to documentation, logs, and technical systems necessary for conformity assessment (Art. 23(1)). | **Open-source + third-party audit record.** Trinity is open-source (all components in `gHashTag/*` repositories). Third-party security audits have been conducted by Trail of Bits (ToB) and Zellic. Audit reports are public. For EU notified body cooperation: Trinity provides a **Conformity Assessment Package** (CAP) including receipt schema, R-SI-1 log export utility, model registration on-chain record, and third-party audit reports. Notified body TBD: SGS, TÜV SÜD, or DEKRA. | Audit reports: `audits/tob-report.pdf`, `audits/zellic-report.pdf`; CAP export tool: `tools/conformity-assessment-package.py`; GitHub: `github.com/gHashTag/*` (public) | 🟡 **Partial** — EU-specific notified body engagement TBD (see Section 6) |

---

### GPAI Obligations (Chapter V)

| Article & Key Obligation | Trinity Primitive | Evidence Path | Status |
|--------------------------|-------------------|---------------|--------|
| **Art. 50 — Transparency for GPAI-Generated Content** <br>Providers of AI systems generating synthetic audio, image, video, or text content must ensure outputs are marked in a machine-readable format and detectable as artificially generated (Art. 50(2)). Operators deploying deepfake technology must disclose the artificial nature of the content (Art. 50(4)). | **Synthetic-content provenance in every receipt.** Every output receipt includes a `content_provenance` field declaring: model type (text/image/audio/video/multimodal), a `synthetic: true` flag, the model hash, and the generation timestamp. Downstream applications can surface this field to users. The receipt is machine-readable (CBOR + JSON encoding) and cryptographically signed, making provenance claims tamper-evident. | Receipt field `content_provenance`: schema at `schema/receipt-v1.cbor#content_provenance`; verifier: `tools/verify_receipt.py --provenance`; C2PA compatibility: TBD roadmap item | 🟡 **Partial** — C2PA/W3C Verifiable Credentials interoperability for content provenance not yet implemented |
| **Art. 53 — Obligations for GPAI Model Providers** <br>Providers of GPAI models must: draw up and maintain technical documentation (Art. 53(1)(a)); provide information and documentation to downstream providers (Art. 53(1)(b)); put in place a policy to comply with EU copyright law (Art. 53(1)(c)); publish a summary of training data (Art. 53(1)(d)). | **Public technical documentation via gHashTag/* + Zenodo.** Technical documentation includes: RTL and GDS source (where applicable), model architecture specs, training configuration, benchmark results, formal theorem statements, and third-party audit reports. All published open-source. Training data policy: Trinity attests model versions but does not host training data; downstream providers are responsible for dataset copyright compliance. Trinity receipts can be used to prove which training data bundle (by CID) was used for a given model version. | GitHub: `github.com/gHashTag/*` (RTL, GDS, specs, proofs); Zenodo DOI: `10.5281/zenodo.19227877` (reproducibility package); training data summary template: `docs/training-data-summary-template.md` | 🟡 **Partial** — Copyright compliance tooling for downstream providers TBD; Trinity itself provides the attestation primitive, not the copyright management layer |
| **Art. 55 — Obligations for GPAI Models with Systemic Risk** <br>Providers of GPAI models with systemic risk (>10^25 FLOPs training compute or designated by EU AI Office) must: perform model evaluations, adversarial testing, track and report serious incidents, ensure cybersecurity protections (Art. 55(1)(a–d)). | **M-of-N attestation as cybersecurity protection for future high-FLOPs training.** If any future model trained on Trinity infrastructure crosses the 10^25 FLOPs threshold, M-of-N attestation provides the cybersecurity layer required by Art. 55(1)(d): no single actor can initiate or modify training at this scale. Every training session produces an on-chain attestation that can be used as evidence of cybersecurity controls. Adversarial testing coordination: TBD (requires external red-team engagement). | M-of-N quorum contract: `contracts/MofNQuorum.sol`; training attestation schema: `schema/training-attestation-v1.cbor`; systemic risk threshold monitoring: TBD | 🔲 **TBD** — No current Trinity model approaches 10^25 FLOPs; framework is in place for future activation |

---

## 3. High-Risk Use Cases Enabled

The following use cases demonstrate how Trinity HW-anchored receipts unlock AI Act compliance for **Annex III high-risk AI systems**.

### 3.1 Healthcare Diagnosis AI — Annex III §5 (Medical Devices)

**Regulatory requirement:** Medical AI systems must maintain logs proving that every diagnosis was produced by the specific approved model version. Regulators (national competent authorities, CE/MDR notified bodies) may request evidence that the model used in a specific patient consultation matched the approved configuration.

**The problem without Trinity:** A hospital runs a diagnostic AI. The vendor silently updates the model weights (for performance reasons, or due to a supply chain attack). The hospital has no way to prove to a regulator that the model used on Patient X on Day Y was the same model that received CE certification.

**Trinity solution:**
- Every inference generates a silicon-signed receipt containing the exact model hash (SHA-256 of weights)
- Receipt is anchored at `0x47C0` with block-height timestamp
- Hospital can produce a receipt for any diagnosis and the verifier script confirms it matches the certified model registration hash
- R-SI-1 audit trail provides the complete sequence of all diagnoses in chronological order

**Compliance coverage:** Art. 12 (record-keeping), Art. 13 (transparency to deployer), Art. 15 (model integrity/robustness)

**Regulatory pathway:** National competent authority (e.g., BfArM in Germany, MHRA in UK) can verify receipts using the open-source verifier without Trinity involvement.

---

### 3.2 Recruitment AI — Annex III §4 (Employment, Workers Management)

**Regulatory requirement:** AI used in recruitment, selection, promotion, or termination is high-risk. Providers must prove the model does not discriminate on protected characteristics, and deployers must be able to demonstrate the model in use matched the specification.

**The problem without Trinity:** A recruitment AI vendor certifies their model for non-discriminatory use. After deployment, an employee or a competitor could tamper with the model. The deployer (HR department) has no way to prove the model they are using is the one that was evaluated.

**Trinity solution:**
- Model hash locked at registration; every inference receipt proves the same hash was used
- M-of-N quorum required to swap the model — preventing unauthorized replacement of an audited model with an off-spec one
- Champion BPB lock detects any distributional shift in model behavior (which could indicate discriminatory bias injection)

**Compliance coverage:** Art. 9 (risk management — no unauthorized model swap), Art. 12 (per-decision audit trail), Art. 14 (human oversight via M-of-N for model changes)

---

### 3.3 Critical Infrastructure Management AI — Annex III §2

**Regulatory requirement:** AI managing critical infrastructure (energy grids, water treatment, transportation) must have the highest level of human oversight and tamper protection. Model updates must be tightly controlled.

**The problem without Trinity:** A power grid management AI is updated automatically by a remote vendor. There is no cryptographic guarantee that the update was approved by the infrastructure operator. A supply chain compromise could substitute a malicious model version.

**Trinity solution:**
- M-of-N quorum (configurable, e.g., 4-of-7 for critical infrastructure) required for any model update
- Every update produces an on-chain attestation; infrastructure operators can require their own key be part of the quorum
- Lucas POST at every node restart ensures no silent model substitution between operator-approved updates

**Compliance coverage:** Art. 9 (risk management), Art. 14 (human oversight — operator keys in quorum), Art. 15 (robustness against unauthorized model alteration)

---

### 3.4 Law Enforcement AI — Annex III §6

**Regulatory requirement:** AI used in law enforcement contexts (e.g., predictive policing analytics, risk assessment for individuals) is among the most strictly regulated. Full audit trails, model integrity, and human oversight are mandatory. Evidence produced by AI in legal proceedings may require proof of model integrity.

**The problem without Trinity:** A law enforcement agency uses a risk-scoring AI. Defense counsel demands proof that the model used in a specific case was the certified version, not a modified one. The agency cannot produce this proof.

**Trinity solution:**
- Per-inference silicon-signed receipts provide cryptographic proof of model identity for every risk assessment
- Receipts are admissible as cryptographic evidence (similar to digital signatures on legal documents)
- R-SI-1 audit trail provides complete, tamper-evident history of all model versions used
- No law enforcement agency employee can unilaterally alter the model (M-of-N quorum)

**Compliance coverage:** Art. 12 (logging), Art. 9 (risk management), Art. 14 (human oversight)

**Special note:** Art. 6(2) and Annex III §6 may require prior authorization by national authorities for certain law enforcement uses. Trinity receipts support the documentation required for such authorizations but do not substitute for the authorization process itself.

---

## 4. GPAI Provider Obligations Details

Trinity serves as a **compliance infrastructure platform** for GPAI model providers seeking to satisfy Art. 53 obligations.

### 4.1 Technical Documentation (Art. 53(1)(a))

GPAI providers using Trinity infrastructure receive the following technical documentation out-of-box:

| Documentation Item | Provided By | Location | Status |
|-------------------|-------------|----------|--------|
| Model architecture specification | Trinity (for Trinity-native models) or provider | `gHashTag/*` repositories | ✅ |
| Training configuration (hyperparameters, data pipeline) | Trinity + provider | Zenodo DOI: `10.5281/zenodo.19227877` | ✅ |
| RTL + GDS source (for Trinity HW nodes) | Trinity | `gHashTag/trinity-hw-rtl` | 🟡 Partial |
| Formal theorem statements (Theorem 36.1) | Trinity | `proofs/theorem36-1.lean` | ✅ |
| Benchmark results (BPB, task-specific evals) | Trinity + provider | `benchmarks/` | ✅ |
| Third-party audit reports | Trail of Bits + Zellic | `audits/` | 🟡 Partial — EU-specific audit TBD |
| Annex XI technical documentation template (AI Act) | Trinity-provided template | `docs/annex-xi-template.md` | 🔲 TBD |

### 4.2 Training Data Policy (Art. 53(1)(c–d))

Trinity's role in training data governance is **attestation, not hosting**:

- Trinity **does not host training data**. Training data is stored by the model provider, typically on Filecoin (content-addressed, CID-verifiable).
- Trinity **attests the training bundle CID** at training initiation via M-of-N quorum signature. This creates a cryptographic link between the model weights and the training data snapshot.
- Trinity **does not perform copyright screening** of training data. Copyright compliance is the responsibility of the model provider (Art. 53(1)(c)).
- Trinity **does provide tooling** for providers to publish training data summaries (Art. 53(1)(d)) using the receipt-anchored training bundle CID as a verifiable reference.

**Open-data commitment:** Trinity's own models and components are published with open training data summaries on Zenodo.

### 4.3 Downstream Provider Information (Art. 53(1)(b))

GPAI providers must make available to downstream deployers:
- Model cards: provided via Zenodo + IPFS (CID in receipt)
- Receipt schema: open-source, self-describing
- Verifier implementation: `tools/verify_receipt.py` (see Section 7.3)
- Known limitations and use cases: documented in model card template

---

## 5. EU AI Office Liaison Plan

The **EU AI Office** (established under Art. 64) is the central EU body for oversight of GPAI models and coordination of AI Act enforcement. Engaging proactively is both a compliance strategy and a competitive moat.

### 5.1 Priority Action: Art. 12 Opinion Letter

**Most important near-term engagement:**

File a formal request with the EU AI Office for an **interpretive opinion** on whether silicon-signed HW receipts anchored on a public blockchain qualify as "event logs" satisfying Art. 12(2) requirements.

**Rationale:** Art. 12 does not specify the technical form of logs — only that they must be "sufficient to ensure traceability." Trinity HW receipts exceed any existing logging standard in tamper-evidence and verifiability. An affirmative opinion would:
- Create a safe harbor for Trinity customers (hospitals, HR vendors, etc.)
- Establish Trinity's technical approach as the de-facto standard for Art. 12 compliance
- Be published as EU AI Office guidance, providing free regulatory marketing

**Action items:**
- [ ] Draft technical dossier: "HW-Anchored Receipts as Art. 12 Compliant Logs" (Q3 2025)
- [ ] Legal review by EU-qualified AI law firm (e.g., Bird & Bird, Fieldfisher) (Q4 2025)
- [ ] Submit to EU AI Office via official channel: https://ai-act-office.ec.europa.eu/ (Q1 2026)

### 5.2 AI Pact Participation

The **EU AI Pact** (preparatory voluntary commitments for providers ahead of Aug 2026) is open for sign-up at: https://digital-strategy.ec.europa.eu/en/policies/ai-pact

**Action items:**
- [ ] Register Trinity as AI Pact signatory (open now)
- [ ] Commit to: (1) voluntary early Art. 12 compliance using HW receipts; (2) open-source verifier publication; (3) participation in AI Pact working groups
- [ ] Use AI Pact membership in customer sales materials as credibility signal

### 5.3 Reference Architecture Submission

Submit Trinity's HW-anchored compliance architecture to the EU AI Office as a **voluntary best-practice reference architecture** for trustworthy AI infrastructure.

**Framing:** "Decentralized Hardware-Rooted AI Audit Infrastructure: A Reference Architecture for Art. 9, 12, and 15 Compliance"

**Action items:**
- [ ] Write reference architecture white paper (Q2 2026)
- [ ] Submit to EU AI Office + European Commission JRC for peer review
- [ ] Simultaneously submit to ENISA (EU cybersecurity agency) given Art. 15 cybersecurity angle

### 5.4 JRC AI Watch Academic Engagement

The **JRC AI Watch** platform (https://ai-watch.ec.europa.eu/) monitors AI developments and informs EU policy. Academic credibility via JRC is a long-term brand asset.

**Action items:**
- [ ] Submit case study of Trinity HW-receipt architecture to JRC AI Watch open repository
- [ ] Engage with JRC researchers studying AI traceability (relevant work: JRC Technical Reports on AI transparency and explainability)
- [ ] Co-author academic paper on "hardware-rooted AI audit trails" targeting IEEE S&P or ACM CCS (Q1–Q2 2026)

---

## 6. Conformity Assessment Pathway

Under Art. 43, providers of high-risk AI systems must follow a conformity assessment procedure before placing the system on the EU market or putting it into service.

### 6.1 Overview of Conformity Assessment Modules

| Module | Description | Applicable To | Trinity Applicability |
|--------|-------------|---------------|----------------------|
| **Module A** (Internal Control) | Provider self-assesses; no notified body | Only for systems listed in Annex VI (self-regulatory) | Limited applicability |
| **Module B+C** (Type-exam + Conformity) | Notified body examines specimen; provider declares conformity | Broad high-risk | Applicable for early certifications |
| **Module B+D** (Type-exam + Quality assurance of production) | Notified body audits production quality system | High-volume hardware | Applicable once HW nodes ship at scale |
| **Module B+F** (Type-exam + Product verification) | Notified body verifies each unit | High-value individual deployments | Possible for enterprise nodes |
| **Module H** (Full quality assurance) | Notified body audits complete QMS; highest assurance level | Complex, high-stakes systems | **Trinity recommendation** |

### 6.2 Trinity Recommendation: Module H (Full Quality Assurance)

**Rationale for Module H:**
- Trinity HW nodes combine hardware (silicon-level attestation) + software (smart contracts, receipt protocol) + operational procedures (M-of-N quorum governance) — this complexity is best covered by full QMS assessment
- Module H provides the highest assurance signal to enterprise customers (hospitals, critical infrastructure)
- Aligns with Trinity's open-source approach: the notified body audit will confirm the public implementation matches the deployed system

**Recommended Notified Bodies:**
| Body | Jurisdiction | AI Act Notified Body Status | Contact |
|------|-------------|----------------------------|---------|
| **TÜV SÜD** | Germany/EU | Expected designation (TBD Aug 2026) | tuvnord.com |
| **DEKRA** | Germany/EU | Expected designation (TBD Aug 2026) | dekra.com |
| **SGS** | Switzerland/EU | Expected designation (TBD Aug 2026) | sgs.com |
| **Bureau Veritas** | France/EU | Expected designation (TBD Aug 2026) | bureauveritas.com |

> **Note:** EU AI Act Notified Bodies under the new regulation are still being designated as of 2025. The above are established conformity assessment bodies under existing EU product safety legislation (CE marking) expected to seek AI Act notified body designation. Engage early to be in the first cohort of certifications.

### 6.3 Conformity Assessment Timeline

```
Q3 2025  — Prepare technical documentation package (Annex IV + Annex XI)
Q4 2025  — Engage TÜV SÜD for pre-assessment consultation
Q1 2026  — Submit conformity assessment application
Q2 2026  — Notified body audit (Module H)
Q3 2026  — Address findings; resubmit if needed
Q4 2026  — EU Declaration of Conformity issued; CE marking for Trinity-enabled AI systems
Q1 2027  — First customer certified under Trinity compliance umbrella
```

### 6.4 Technical Documentation for Conformity Assessment (Annex IV)

Annex IV lists the required technical documentation for high-risk AI systems. Trinity provides the following out-of-box:

| Annex IV Item | Trinity-Provided Artifact | Location |
|---------------|--------------------------|----------|
| General description of AI system | System architecture overview | `docs/system-architecture.md` |
| Intended purpose + use cases | Use case registry | `docs/use-case-registry.md` |
| Instructions for use | Deployer handbook | `docs/deployer-handbook.md` |
| Software components description | Repository map | `github.com/gHashTag/*` |
| Description of training process | Training attestation spec | `docs/training-attestation-spec.md` |
| Design specifications | RTL + GDS + formal proofs | `gHashTag/trinity-hw-rtl`, Zenodo |
| Risk management documentation | R-SI-1 schema + slashing spec | `schema/r-si-1.cbor`, `docs/slashing-spec.md` |
| Data governance documentation | Training bundle CID policy | `docs/training-bundle-cid-policy.md` |
| Post-market monitoring plan | R-SI-1 telemetry dashboard spec | `docs/post-market-monitoring.md` |
| Validation & testing results | BPB benchmarks + Lucas POST results | `benchmarks/`, `docs/lucas-post-results.md` |

---

## 7. Documentation Template

Trinity provides the following documentation artifacts out-of-box for any deployer seeking EU AI Act compliance.

### 7.1 Cryptographic Receipt Format Specification

Receipts are encoded in **CBOR (RFC 7049)** with a **JSON shadow** for human readability. The receipt schema is derived from and extends the M9 inference attestation format and M1 model registration format.

```
Receipt v1 Schema (CBOR map keys):
┌─────────────────────┬────────────────────────────────────────────────────┐
│ Field               │ Description                                        │
├─────────────────────┼────────────────────────────────────────────────────┤
│ receipt_version     │ uint8 — current: 1                                 │
│ receipt_id          │ bytes[32] — SHA-256 of (node_id || nonce || ts)    │
│ timestamp_unix      │ uint64 — Unix time (seconds)                       │
│ block_height        │ uint64 — anchor chain block height                 │
│ node_id             │ bytes[20] — hardware-derived node identifier       │
│ model_hash          │ bytes[32] — SHA-256 of quantized model weights     │
│ model_format        │ text — e.g., "NF4", "Posit16", "INT8", "FP16"     │
│ input_hash          │ bytes[32] — SHA-256 of serialized input tensor     │
│ output_hash         │ bytes[32] — SHA-256 of serialized output tensor    │
│ bpb_fingerprint     │ float32 — BPB of output (for regression detection) │
│ content_provenance  │ map — {synthetic: bool, content_type: text}        │
│ model_manifest_cid  │ text — IPFS CID of model card                      │
│ anchor_address      │ bytes[20] — on-chain anchor: 0x47C0...             │
│ anchor_tx_hash      │ bytes[32] — LayerZero transaction hash             │
│ tee_signature       │ bytes[64] — secp256k1 signature (hardware key)     │
│ tee_pubkey          │ bytes[33] — compressed secp256k1 public key        │
└─────────────────────┴────────────────────────────────────────────────────┘
```

Full schema: `schema/receipt-v1.cbor` (CDDL notation)

### 7.2 Sample Audit Log

#### Sample Inference Receipt (JSON representation)

```json
{
  "receipt_version": 1,
  "receipt_id": "3f8a2c14e9b7d6f05a12e3c84b90d7e21f4a5c68d3b2e1f09a7c4d8e5f3b1a2",
  "timestamp_unix": 1737500400,
  "block_height": 21847392,
  "node_id": "0x4a3f8c2e1b9d7f0a5c3e8b2d",
  "model_hash": "sha256:a3f8c2e1b9d7f0a5c3e8b2d4f1e9a7c5b3d2e0f8a6c4b1d9e7f5a3c2b0d8e6",
  "model_format": "NF4",
  "input_hash": "sha256:b2e4d8f1a5c9e3b7d1f5a9e3b7c1d5f9a3e7b1c5d9f3a7e1b5c9d3f7a1e5b9",
  "output_hash": "sha256:c1d7e3f9a5b2c8d4e0f6a2b8c4d0e6f2a8b4c0d6e2f8a4b0c6d2e8f4a0b6c2",
  "bpb_fingerprint": 3.847,
  "content_provenance": {
    "synthetic": true,
    "content_type": "text"
  },
  "model_manifest_cid": "QmXf9a3c2e1b8d7f5a4c3e2b1d0f9a8c7e6b5d4f3a2e1",
  "anchor_address": "0x47C0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8",
  "anchor_tx_hash": "0xd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4",
  "tee_signature": "3045022100a3f8c2e1b9d7...022069d4e5f6a7b8...",
  "tee_pubkey": "02a3f8c2e1b9d7f0a5c3e8b2d4f1e9a7c5b3d2e0f8"
}
```

#### Sample Training Attestation (JSON representation)

```json
{
  "attestation_version": 1,
  "attestation_id": "4e9b1f7c2a5d8e3f6b0c4a7d1e5f9b2c6a0d4e8f2b6a0d4e8f2c6a0d4e8f3",
  "attestation_type": "training",
  "timestamp_unix": 1737400000,
  "block_height": 21840000,
  "training_bundle_cid": "QmYa3c2e1b8d7f5a4c3e2b1d0f9a8c7e6b5d4f3a2e1b",
  "model_hash_post_training": "sha256:b4f9c3e2a8d7f1a5c4e3b2d1f0a9c8e7b6d5f4a3e2",
  "quorum_threshold": "3-of-5",
  "quorum_signers": [
    "0x1a2b3c4d5e6f...",
    "0x2b3c4d5e6f7a...",
    "0x3c4d5e6f7a8b..."
  ],
  "quorum_signature": "aggregated_schnorr_sig_hex...",
  "anchor_address": "0x47C0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8",
  "anchor_tx_hash": "0xe5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5"
}
```

#### Sample R-SI-1 Audit Trail Entry

```json
{
  "rsi1_version": 1,
  "entry_id": "5f0c2a8d3b6e9f1c4a7d2b5e8f3c6a9d2b5e8f3c6a9d2b5e8f3c6a9d2b5f0",
  "prev_entry_hash": "sha256:e9f1c4a7d2b5e8f3c6a9d2b5e8f3c6a9d2b5e8f3c6a9d2b5e8f3c6a9d2b5e8",
  "entry_type": "inference",
  "receipt_id": "3f8a2c14e9b7d6f05a12e3c84b90d7e21f4a5c68d3b2e1f09a7c4d8e5f3b1a2",
  "timestamp_unix": 1737500400,
  "node_id": "0x4a3f8c2e1b9d7f0a5c3e8b2d",
  "alert_flags": [],
  "chain_signature": "tee_signed_entry_cbor_hex..."
}
```

### 7.3 Verifier Reference Implementation

A Python reference implementation for verifying Trinity receipts, suitable for integration by auditors, deployers, and notified bodies.

```python
#!/usr/bin/env python3
"""
Trinity Receipt Verifier — Reference Implementation
Satisfies EU AI Act Art. 12 log verification requirement
Dependencies: coincurve, cbor2, requests
~50 LOC
"""

import cbor2
import coincurve
import hashlib
import json
import requests

def verify_receipt(receipt_cbor_hex: str, expected_model_hash: str = None) -> dict:
    """
    Verify a Trinity silicon-signed inference receipt.
    Returns: dict with keys: valid (bool), model_hash, timestamp, anchor_confirmed
    """
    receipt_bytes = bytes.fromhex(receipt_cbor_hex)
    receipt = cbor2.loads(receipt_bytes)

    # 1. Verify TEE hardware signature
    sig = bytes.fromhex(receipt["tee_signature"])
    pubkey = bytes.fromhex(receipt["tee_pubkey"])
    # Sign over all fields except tee_signature itself
    payload = {k: v for k, v in receipt.items() if k != "tee_signature"}
    payload_bytes = cbor2.dumps(payload)
    payload_hash = hashlib.sha256(payload_bytes).digest()
    key = coincurve.PublicKey(pubkey)
    sig_valid = key.verify(sig, payload_hash)

    # 2. Verify model hash matches expected (optional)
    model_hash_match = True
    if expected_model_hash:
        model_hash_match = receipt["model_hash"] == expected_model_hash

    # 3. Verify on-chain anchor (LayerZero)
    anchor_tx = receipt.get("anchor_tx_hash")
    anchor_confirmed = False
    if anchor_tx:
        # Query public RPC for anchor transaction confirmation
        rpc_url = "https://rpc.trinity-anchor.network/tx/" + anchor_tx
        try:
            resp = requests.get(rpc_url, timeout=5)
            anchor_confirmed = resp.status_code == 200 and resp.json().get("confirmed", False)
        except Exception:
            anchor_confirmed = None  # Network error — log but don't fail

    return {
        "valid": sig_valid and model_hash_match,
        "model_hash": receipt.get("model_hash"),
        "model_format": receipt.get("model_format"),
        "timestamp_unix": receipt.get("timestamp_unix"),
        "block_height": receipt.get("block_height"),
        "anchor_confirmed": anchor_confirmed,
        "synthetic": receipt.get("content_provenance", {}).get("synthetic"),
        "receipt_id": receipt.get("receipt_id"),
    }

if __name__ == "__main__":
    import sys
    result = verify_receipt(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
    print(json.dumps(result, indent=2))
```

**Usage:**
```bash
pip install coincurve cbor2 requests
python verify_receipt.py <receipt_cbor_hex> [expected_model_hash]
```

Full implementation with CLI flags, batch verification, and R-SI-1 log audit: `tools/verify_receipt.py`

---

## 8. GDPR Interplay

The EU AI Act explicitly invokes GDPR principles (Recital 9, Art. 2(7)). Trinity's design choices align with GDPR by default.

### 8.1 Data Minimisation in Receipts (Art. 5(1)(c) GDPR + Art. 25 GDPR — Data Protection by Design)

Trinity inference receipts contain **zero personal data**:

| Receipt Field | Contains PII? | Notes |
|--------------|---------------|-------|
| input_hash | No | SHA-256 hash of input; one-way, non-reversible |
| output_hash | No | SHA-256 hash of output; one-way, non-reversible |
| model_hash | No | Hash of model weights only |
| node_id | No | Hardware-derived identifier; no user linkage |
| timestamp | No (potentially pseudonymous) | Timestamp alone does not identify a data subject |
| tee_signature | No | Hardware attestation; no personal data |

**Art. 25 compliance (Data Protection by Design and by Default):** By storing only cryptographic hashes of inputs and outputs, Trinity receipts provide auditability without retaining personal data. The hash functions used (SHA-256) are one-way: a regulator can verify a receipt against a known input/output pair, but cannot reconstruct the personal data from the receipt alone.

### 8.2 Training Bundle Encryption

Training data bundles stored on Filecoin are encrypted using:
- **AES-256-GCM** for bulk data encryption
- **Shamir Secret Sharing** for key splitting across M-of-N keyholders (same governance structure as training attestation)
- Key shards are distributed to keyholders at training initiation; no single party can decrypt the full bundle

This ensures that even if Filecoin storage is subpoenaed, the training data is inaccessible without M-of-N keyholder cooperation.

### 8.3 Right to Erasure (Art. 17 GDPR) — Open Question

This is an **acknowledged open research question** at the intersection of blockchain immutability and GDPR.

**The tension:** Trinity receipts are append-only proofs, immutable by design. Once a receipt is anchored on-chain, it cannot be deleted. However, the receipt contains no personal data (Section 8.1), so there is generally nothing to erase from the receipt itself.

**The harder question:** If a data subject's personal data was included in training data, and the trained model "encodes" that data in its weights, does the data subject have a right to erasure of the model? This is the **model unlearning** problem.

| Scenario | GDPR Right to Erasure Applicability | Trinity Position |
|----------|-------------------------------------|-----------------|
| Personal data in inference inputs | Low risk — hashed only, not stored | Not applicable |
| Personal data in training data | Applicable if included | Training data erasure is provider responsibility; Trinity attests CID at training time |
| Personal data encoded in model weights | Open research question | Machine unlearning research ongoing; Trinity can attest re-trained model post-unlearning |
| On-chain receipt itself | Generally not applicable (no PII) | Receipts are GDPR-neutral by design |

**Practical path forward:** For high-risk AI systems processing personal data (e.g., healthcare, HR), deployers should:
1. Implement data subject rights at the application layer (not the receipt layer)
2. For training data erasure requests: retrain the model with the requested data removed; Trinity will produce a new model registration with a new hash, proving the updated model excludes the relevant data
3. Note the ongoing regulatory discussion: the European Data Protection Board (EDPB) has not yet issued formal guidance on the AI Act/GDPR interface for model unlearning

---

## 9. Penalties Avoided & ROI for Customer

### 9.1 Penalty Exposure Analysis

#### Scenario A: Hospital Deploying High-Risk Diagnostic AI (Annex III §5) Without HW Logs

| Risk Factor | Value |
|-------------|-------|
| EU AI Act penalty (Art. 99(3)) | Up to €15M or 3% global turnover |
| Large hospital group annual revenue | ~€500M |
| 3% global turnover fine | €15M |
| MDR (Medical Device Regulation) concurrent penalty | Additional; jurisdiction-specific |
| Reputational damage (litigation, press) | Unquantified; likely exceeds direct fine |
| **Total estimated exposure** | **€15M+ per incident** |

#### Scenario B: Recruitment AI Vendor Without Model Integrity Proof (Annex III §4)

| Risk Factor | Value |
|-------------|-------|
| AI Act penalty (Art. 99(3)) | Up to €15M or 3% turnover |
| GDPR concurrent fine (discriminatory processing) | Up to €20M or 4% turnover |
| Combined max exposure | ~€35M (if GPAI element triggers Art. 99(2)) |
| Employment tribunal liability | Per-claim; potentially large class actions |
| **Total estimated exposure** | **€35M+ worst case** |

#### Scenario C: GPAI Provider Without Technical Documentation (Art. 53)

| Risk Factor | Value |
|-------------|-------|
| AI Act penalty (Art. 99(4)) | Up to €7.5M or 1.5% turnover |
| Market withdrawal order | Loss of EU market access |
| **Total estimated exposure** | **€7.5M+ plus market exclusion** |

### 9.2 Trinity Compliance Cost vs. Penalty Avoided

```
╔══════════════════════════════════════════════════════════════════╗
║                 Break-Even Analysis (Annual)                     ║
╠══════════════════════════════════════════════════════════════════╣
║ Trinity compliance subscription (enterprise tier):   ~€50,000   ║
║ One avoided moderate AI Act fine (30% of max):       €4,500,000 ║
║ Ratio (penalty / subscription):                            90×   ║
║ Break-even point:                          < 1 avoided fine      ║
║                                                                  ║
║ For a hospital (€15M max fine):                                  ║
║   Trinity subscription covers 300 years of compliance costs      ║
║   for the cost of one avoided minor fine (€15M / €50K = 300×)   ║
╚══════════════════════════════════════════════════════════════════╝
```

### 9.3 Additional ROI Factors

| Benefit | Quantification |
|---------|---------------|
| Faster regulatory approval (pre-certified logs) | 3–6 months faster time-to-market for EU deployment |
| Notified body audit cost reduction | Standardized receipts reduce audit duration by est. 30–40% |
| Cyber insurance premium reduction | Tamper-evident HW logs reduce incident response cost; est. 10–15% premium discount |
| Market access premium | Certified EU AI Act compliance enables contracts with public sector, healthcare, finance |
| Litigation defense cost reduction | HW-signed receipts are strong evidence in legal proceedings |

---

## 10. Roadmap & TBD Items

### 10.1 Compliance Roadmap

```
2025
├── Q2 2025 — Publish receipt schema v1 (CBOR + JSON-LD) as open standard
├── Q2 2025 — Release verifier reference implementation (verify_receipt.py)
├── Q3 2025 — Register as EU AI Pact signatory
├── Q3 2025 — Draft Art. 12 opinion letter dossier
├── Q4 2025 — External legal review of opinion letter dossier (Bird & Bird / Fieldfisher)
└── Q4 2025 — TÜV SÜD pre-assessment consultation

2026
├── Q1 2026 — Submit Art. 12 opinion letter to EU AI Office
├── Q1 2026 — GPAI Art. 53 documentation package complete (Annex XI template)
├── Q2 2026 — Submit reference architecture white paper to JRC AI Watch
├── Q3 2026 — **First customer pilot: German Mittelstand healthcare AI vendor**
├── Q3 2026 — Module H conformity assessment application submitted
└── Q4 2026 — **TÜV SÜD review of Trinity HW-receipt as Art. 12 log**

2027
├── Q1 2027 — **EU AI Office reference architecture submission**
├── Q2 2027 — **First notified body (Module H) certification**
├── Q3 2027 — C2PA/W3C VC interoperability for Art. 50 synthetic content
└── Q4 2027 — Model unlearning research partnership (GDPR/EUAIA interplay)
```

### 10.2 Open TBD Items

| Item | Priority | Owner | Target |
|------|----------|-------|--------|
| EU notified body selection (TÜV SÜD / DEKRA / SGS) | High | Business Dev | Q4 2025 |
| Annex XI technical documentation template | High | Engineering + Legal | Q1 2026 |
| C2PA content provenance interoperability (Art. 50) | Medium | Engineering | Q3 2027 |
| Model unlearning spec (GDPR right-to-erasure interface) | Medium | Research | Q4 2027 |
| EU-qualified legal counsel engagement | High | Legal | Q3 2025 |
| Art. 12 opinion letter — formal submission | Critical | Legal + Business Dev | Q1 2026 |
| AI Pact signatory registration | Medium | Business Dev | Q3 2025 |
| ENISA cybersecurity framework alignment (Art. 15) | Low | Engineering | Q2 2026 |
| Bias examination tooling for Art. 10 data governance | Medium | Engineering | Q2 2026 |
| Post-market monitoring SOP documentation | High | Engineering + Legal | Q4 2025 |

---

## 11. References

| Source | URL | Relevance |
|--------|-----|-----------|
| **EU AI Act (Regulation 2024/1689)** — full text | https://eur-lex.europa.eu/eli/reg/2024/1689/oj | Primary legal text |
| **JRC AI Watch** — EC Joint Research Centre AI monitoring | https://ai-watch.ec.europa.eu/ | Academic credibility, policy influence |
| **EU AI Pact** — voluntary early commitments | https://digital-strategy.ec.europa.eu/en/policies/ai-pact | Signatory registration |
| **EU AI Office** | https://ai-act-office.ec.europa.eu/ | Opinion letter submission, GPAI oversight |
| **Trinity Zenodo DOI 10.5281/zenodo.19227877** | https://doi.org/10.5281/zenodo.19227877 | Reproducibility package, Art. 17/53 evidence |
| **Trinity Theorem 36.1** | `proofs/theorem36-1.lean` (gHashTag repo) | Formal proof underlying robustness claims |
| **GDPR (Regulation 2016/679)** | https://eur-lex.europa.eu/eli/reg/2016/679/oj | Art. 25 interplay |
| **ENISA AI Cybersecurity** | https://www.enisa.europa.eu/topics/artificial-intelligence | Art. 15 cybersecurity alignment |
| **Trail of Bits Audit Report** | `audits/tob-report.pdf` (gHashTag repo) | Art. 23 third-party audit evidence |
| **Zellic Audit Report** | `audits/zellic-report.pdf` (gHashTag repo) | Art. 23 third-party audit evidence |
| **C2PA (Content Provenance)** | https://c2pa.org/ | Art. 50 synthetic content provenance interoperability |
| **W3C Verifiable Credentials** | https://www.w3.org/TR/vc-data-model/ | Receipt interoperability standard |
| **CBOR (RFC 7049)** | https://www.rfc-editor.org/rfc/rfc7049 | Receipt encoding standard |
| **LayerZero Protocol** | https://layerzero.network/ | Cross-chain anchor mechanism for 0x47C0 |
| **Filecoin Spec** | https://spec.filecoin.io/ | Art. 10 training data storage |

---

*This document is a working draft. Legal positions and TBD items require review by EU-qualified counsel before use in regulatory submissions. All article references are to Regulation (EU) 2024/1689 as published in the Official Journal of the European Union on 12 July 2024.*

*Trinity anchor: 0x47C0 | R-SI-1 | Zenodo DOI: 10.5281/zenodo.19227877*
