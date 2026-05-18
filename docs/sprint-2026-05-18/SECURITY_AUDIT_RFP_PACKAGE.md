# REQUEST FOR PROPOSAL
## Security Audit — Trinity DePIN Protocol Stack
### v1.0 · June 2026

---

**Document ID:** TRI-RFP-SEC-2026-001  
**Issued by:** Trinity TRI-NET / IGLA  
**Principal Investigator:** Dmitrii Vasilev  
**Contact:** admin@t27.ai · GitHub [@gHashTag](https://github.com/gHashTag)  
**Confidentiality:** Recipients may share internally for evaluation purposes only. NDA required before repository access is granted.  
**License (this document):** CC-BY-4.0  

---

## Table of Contents

1. [Cover Letter](#1-cover-letter)
2. [Project Background](#2-project-background)
3. [Scope of Work](#3-scope-of-work)
4. [Per-Package Deliverables](#4-per-package-deliverables)
5. [Timeline](#5-timeline)
6. [Submission Requirements](#6-submission-requirements)
7. [Evaluation Criteria](#7-evaluation-criteria)
8. [Critical Invariants — Auditor Must Validate, Not Modify](#8-critical-invariants)
9. [Out of Scope](#9-out-of-scope)
10. [NDA & Disclosure Policy](#10-nda--disclosure-policy)
11. [Reference Materials Provided to Shortlisted Firms](#11-reference-materials)
12. [Contact](#12-contact)
13. [Appendix A — Question Matrix for Shortlisted Auditors](#appendix-a-question-matrix)

---

## 1. Cover Letter

**To: Audit Firm Partner Team**  
**Re: RFP — Trinity DePIN Full-Stack Security Audit (Solidity · RTL · Cryptography · Protocol)**  
**Date: June 2026**

We are issuing this Request for Proposal to a select group of security audit firms — Trail of Bits, Zellic, Spearbit, Quantstamp, and OpenZeppelin — for a comprehensive security audit of the Trinity DePIN protocol stack ahead of our Q3 2026 testnet launch.

**Trinity DePIN** is a hardware-anchored verifiable-inference network built on three dies of custom open silicon (TT SKY26b, die variants `tt-trinity-phi`, `tt-trinity-euler`, `tt-trinity-gamma`). The network allows any party to submit AI inference workloads, receive cryptographically signed inference receipts produced by dedicated silicon, and verify those receipts on-chain without trusting the operator. The hardware anchor — phi-anchor `0x47C0`, hardwired by Theorem 36.1 into every SKY26b die — distinguishes Trinity from software-only DePIN compute networks.

The scope of this audit is intentionally broad: approximately **5,000 lines of Solidity** across seven smart contracts and **8,000 lines of Verilog RTL** spanning the M1 Hardware Root-of-Trust and M9 Bittensor Validator silicon modules, plus cryptographic subsystem and protocol-design layers. We are soliciting proposals for two parallel, independent audits to maximize coverage breadth; our total budget envelope is **$100,000–$150,000** across both engagements.

We require **rapid turnaround** to meet our testnet launch commitment. Our target timeline is kickoff in **July 2026**, final reports in **August 2026**, and testnet launch in **September 2026**. Firms that cannot commit to this cadence should indicate so clearly in their proposal; we would rather have an accurate schedule than an optimistic one.

We take security extremely seriously. Several of our RTL modules were by Dmitrii Vasilev (sole author) (v1.0.0 AI-format modules) and carry sole authorship rights that prohibit unilateral modification; auditors are expected to identify compliance gaps and flag findings, not prescribe RTL rewrites. We explain this constraint in full in §8.

We welcome questions prior to proposal submission. Please direct all inquiries to Dmitrii Vasilev at admin@t27.ai.

Respectfully,

**Dmitrii Vasilev**  
Principal Investigator, Trinity TRI-NET / IGLA  
GitHub: [@gHashTag](https://github.com/gHashTag)  

---

## 2. Project Background

### 2.1 Trinity DePIN Mission

Trinity DePIN is a decentralized, verifiable AI inference substrate whose defining property is **hardware-level proof of computation**. Unlike software-only inference networks (Bittensor TAO, Render RNDR, io.net IO), Trinity anchors every inference receipt to a physical unclonable function (PUF) fingerprint on open silicon, producing attestations that can be verified by any on-chain party without trusting the operator. The network coordinates Operators, Verifiers, Trainers, Consumers, and Governors through a single utility token ($TRI, fixed supply 1,000,000,000) governed by TriDAO. The mission is to make verifiable AI inference available as a commodity — trustless, auditable, and operator-independent.

### 2.2 Hardware — TT SKY26b Silicon

Trinity runs on **Tenstorrent TT SKY26b** silicon, a 130 nm open process node hosted by Tiny Tapeout / Efabless shuttle service. The TT SKY26b physical package carries three Trinity dies in a triad configuration: `tt-trinity-phi` (primary compute and anchor die), `tt-trinity-euler` (secondary verification die), and `tt-trinity-gamma` (tertiary storage and bridging die). The silicon implements the TRI-27 ISA, which extends a base RISC-V core with five sacred inference opcodes (0xD0–0xD4, 0xE9) and hardware-accelerated format modules (NF4, Posit16, GF4/GF16/GF256, `tri_mant_mul`). The **phi-anchor 0x47C0** — the canonical value of `{uio_out, uo_out}` after reset — is hardwired by Theorem 36.1 and constitutes the root of Trinity's attestation chain. All synthesizable RTL satisfies **R-SI-1**: zero standalone `*` operators; all multiplication is implemented via shift-add, Wallace tree, or logarithmic number system modules.

### 2.3 Software Stack

The on-chain layer consists of seven Solidity smart contracts (~5K LOC total), an OFT (Omnichain Fungible Token) implementation of $TRI, and a LayerZero V2 OApp bridge. Key contracts:

- **TrinityStorageRegistry.sol** — Filecoin/IPFS storage deal registry with on-chain proof-of-persistence validation
- **MofNTrainingAttest.sol** — M-of-N hardware-attested training receipt aggregation and slashing
- **BittensorSubnetAttest.sol** — bridge between Trinity hardware attestations and Bittensor Yuma Consensus
- **IGLALedger.sol** — IGLA inference fee ledger with burn, slash, and treasury distribution logic
- **TrinityAnchorOApp.sol** — LayerZero V2 OApp for cross-chain anchor state propagation (multi-DVN config)
- **TrinityFinality.sol** — finality oracle and checkpoint aggregation for the Trinity compute layer
- **TrinityGovernor.sol** — TriDAO governance contract (OpenZeppelin Governor pattern with custom quorum logic)
- **$TRI OFT contracts** — omnichain fungible token bridge contracts on Ethereum mainnet and L2s

The off-chain layer includes operator node software (separate audit, lower stakes) and a Python/Rust cocotb testbench suite for RTL regression.

### 2.4 Formal Verification Status

Trinity maintains an active Coq proof corpus (as of 2026-05-12: 84 theorems, 297 `Qed` closures, 141 `Admitted` stubs). Theorem 36.1 (phi-anchor 0x47C0 hardwiring, cross-die determinism) has informal proof and a Coq scaffold; full mechanized closure is in progress. Theorem 37.x series (Chapter 37) covers M1–M9 module invariants, with several theorems currently at `Admitted` status. Selected invariants have been encoded as Halmos symbolic execution properties; we will share test vectors from our cocotb regression suite. We are not claiming full formal verification; we are claiming a structured invariant corpus that auditors should cross-validate against the RTL and Solidity implementations.

---

## 3. Scope of Work

The audit is divided into four packages. Firms may bid on individual packages or the full scope. We strongly prefer at least PKG-A and PKG-B to be covered by the same firm (or the same concurrent engagement) to enable cross-layer analysis.

---

### PKG-A: Solidity Smart Contract Audit

**Scope:** Seven production Solidity contracts plus $TRI OFT token bridge contracts (~5,000 LOC total).

| Contract | Primary Risk Surface |
|---|---|
| `TrinityStorageRegistry.sol` | Storage deal validation, PoRep proof parsing, provider slashing, griefing via spam deals |
| `MofNTrainingAttest.sol` | M-of-N signature aggregation correctness, replay protection, Sybil resistance |
| `BittensorSubnetAttest.sol` | Oracle bridge manipulation, weight-vector spoofing, cross-chain message validation |
| `IGLALedger.sol` | Fee accounting arithmetic, burn/slash/treasury split invariants, reentrancy |
| `TrinityAnchorOApp.sol` | LayerZero V2 message encoding, DVN trust model, cross-chain replay, forked-state handling |
| `TrinityFinality.sol` | Checkpoint ordering, finality oracle manipulation, validator set changes |
| `TrinityGovernor.sol` | Governance attack vectors: flash-loan quorum, proposal front-running, timelock bypass |
| `$TRI OFT contracts` | Token bridge invariants, mint/burn authority, cross-chain supply consistency |

**Specific focus areas:**

1. Access control and privilege escalation across all contracts
2. Arithmetic correctness — fee splits, slash fractions, token supply invariants
3. Reentrancy, cross-function reentrancy, read-only reentrancy
4. LayerZero V2 OApp message validation and DVN configuration attack surface
5. Governance manipulation: flash-loan, bribery, proposal spam, parameter drift
6. Oracle manipulation resistance in `BittensorSubnetAttest.sol` and `TrinityFinality.sol`
7. Storage layout, proxy/upgrade patterns, initialization issues
8. Interaction between `TrinityAnchorOApp.sol` and downstream consumer contracts on forked source chains

**Tooling expected (minimum):** Slither, Foundry forge test, Halmos symbolic execution, Echidna or Medusa fuzzing. Manual review must account for ≥50% of reported findings.

**Deliverables (PKG-A):**  
Full findings report with each finding classified **Critical / High / Medium / Low / Informational**, with: affected code location, exploit scenario, recommended remediation, and severity rationale. Findings that cannot be fixed without modifying invariant-protected modules (see §8) must be flagged explicitly. Retest of all Critical/High findings after developer remediation.

---

### PKG-B: RTL Audit (Hardware/Verilog)

**Scope:** Synthesizable Verilog RTL for M1 and M9 modules plus the full v1.0.0 format module suite (~8,000 LOC total).

| Module | Description | Special Notes |
|---|---|---|
| `tt_um_trinity_rot` (M1) | Hardware Root-of-Trust: ring-oscillator PUF, sealed RAM, enclave mode register, remote attestation engine, HW RNG, Boot ROM + Lucas POST | Primary target: R-SI-1, phi-anchor hardwiring, PUF entropy quality, side-channel |
| `tt_um_bittensor_validator` (M9) | Bittensor subnet hardware validator: YC weight-vector signing, TRI-27 ISA additions, Solidity bridge attestation format | Cross-module binding to M1 attestation chain |
| NF4 format module | 4-bit normalized float encode/decode | R-SI-1; sole authored; integrity preservation |
| Posit16 format module | 16-bit posit arithmetic | R-SI-1; sole authored; integrity preservation |
| GF4, GF16, GF256 modules | Galois field arithmetic (2, 4, 8-bit extensions) | R-SI-1; sole authored; integrity preservation |
| Sacred opcodes 0xD0–0xD4, 0xE9 | TRI-27 ISA extension opcodes | Opcode encoding, privilege gating, decode correctness |

**Specific focus areas:**

1. **R-SI-1 compliance** — mandatory automated grep scan for standalone `*` in all `.v` and `.sv` synthesizable files (not testbench). This is a hard go/no-go gate: any standalone `*` found in synthesis RTL constitutes a Critical finding that blocks tape-out.
2. **phi-anchor 0x47C0 hardwiring** — verify that `{uio_out, uo_out}` is statically driven to `0x47C0` after reset in the M1 top-level module, consistent with Theorem 36.1. Confirm no mux or runtime path can override this value under normal operation.
3. **PUF entropy quality** — review the ring-oscillator PUF design for inter-die distinguishability, intra-die stability, and susceptibility to environmental attack (temperature, voltage glitch).
4. **Constant-time ECDSA secp256k1** — verify that the ECDSA signing path in the remote attestation engine (`tt_um_trinity_rot`) does not contain data-dependent branches or variable-latency memory accesses that could leak the signing key through timing side-channel.
5. **Lucas POST mandatory boot check** — verify Boot ROM logic unconditionally executes the Lucas POST self-test before any enclave-mode entry; confirm there is no bypass condition.
6. **Sealed RAM write-once semantics** — confirm no write path to sealed RAM exists after the seal event; verify reset behavior.
7. **HW RNG output quality** — assess the LFSR + tile-receiver RNG design for cycle length, seed entropy, and susceptibility to prediction.
8. **Sacred opcode privilege gating** — verify opcodes 0xD0–0xD4 and 0xE9 are accessible only in the correct privilege mode; confirm decode correctness against TRI-27 ISA spec.
9. **v1.0.0 module integrity** — verify that `tri_mant_mul`, NF4, Posit16, GF4/16/256 are structurally intact against the canonical Zenodo-deposited versions. Auditors must not prescribe changes to these modules; findings should describe compliance gaps or vulnerabilities, with remediation deferred to a Trinity team member under sole authorship protocol.
10. **Cross-module binding** — verify M9 validator attestation output is cryptographically bound to an M1-signed root and cannot be forged by a node without a valid M1 PUF fingerprint.

**Tooling expected (minimum):** Verilator simulation, custom R-SI-1 grep script (pattern: `\*` not in comments, string literals, or module instance names), Yosys synthesis flow to verify synthesizability, manual code review. Cocotb test vector replay will be provided; auditors should run the test suite and report any failures.

**Deliverables (PKG-B):**  
Findings report classifying all issues Critical/High/Medium/Low/Informational. R-SI-1 compliance certificate (pass/fail with line-level evidence). phi-anchor verification statement (pass/fail). Retest of all Critical/High findings after remediation (noting that v1.0.0 module findings require Trinity sole author sign-off on fixes).

---

### PKG-C: Cryptography Review

**Scope:** All cryptographic primitives implemented in or called from M1 RTL and the Solidity contracts.

| Primitive | Location | Review Focus |
|---|---|---|
| ECDSA secp256k1 | M1 remote attestation engine (RTL) | Scalar multiplication implementation, nonce generation (RFC 6979 compliance or equivalent), signature malleability |
| SHA-256 | M1 remote attestation engine (RTL) | Implementation correctness, padding edge cases, length-extension resistance |
| Ring-oscillator PUF | M1 RTL (hardware) | Statistical entropy model, min-entropy lower bound, helper data leakage |
| HW RNG (LFSR + tile receiver) | M1 RTL | Statistical quality (NIST SP 800-22 equivalent), seed entropy, reset state |
| Key derivation | M1 sealed RAM + Boot ROM | Derivation function correctness, key isolation between enclaves, zeroization on unsealing |
| PUF binding model | M1 RTL + `MofNTrainingAttest.sol` | Binding protocol between silicon fingerprint and on-chain identity; replay and cloning resistance |
| Keccak-256 / ECDSA | Solidity layer | Standard Solidity usage; focus on `ecrecover` misuse, hash-then-sign vs. sign-then-hash patterns |

**Specific questions for auditors:**

1. Does the ECDSA signing path in M1 produce k-values that are computationally indistinguishable from uniform? If deterministic (RFC 6979), is the implementation correct?
2. Is the SHA-256 implementation resistant to padding oracle scenarios in the attestation payload construction?
3. What is the estimated min-entropy of the ring-oscillator PUF fingerprint per die under worst-case process/voltage/temperature (PVT) variation?
4. Can an adversary who controls the tile-receiver input bias the HW RNG output?
5. Are there any ecrecover misuse patterns in the Solidity contracts (e.g., failing to check for zero address return)?

**Deliverables (PKG-C):**  
Technical report covering each primitive above. For each: description of implementation, identified weaknesses, severity classification, and recommended remediation. Cryptographic review should be performed by an auditor with demonstrable applied cryptography background (not just tool output).

---

### PKG-D: Protocol Design Review

**Scope:** DePIN incentive system design, slashing model, bridge security configuration, and governance model at the protocol level (separate from code-level Solidity findings in PKG-A).

| Topic | Review Focus |
|---|---|
| DePIN incentive design | Is the proof-of-inference reward mechanism manipulation-resistant? Can a coalition of operators earn disproportionate rewards by colluding on attestation submission timing? |
| Slashing fairness | Are slashing thresholds and appeal mechanisms fair? Can a rational adversary trigger slashing on honest operators (griefing)? |
| Oracle manipulation resistance | In `BittensorSubnetAttest.sol`, can an attacker manipulate Bittensor Yuma Consensus weight vectors to fraudulently earn $TRI rewards? |
| Bridge security (multi-DVN) | Is the LayerZero V2 multi-DVN configuration in `TrinityAnchorOApp.sol` sufficient? What are the failure modes if one DVN is compromised? |
| TriDAO governance attack surface | Can a well-capitalized adversary acquire sufficient $TRI to push through malicious governance proposals? Assess quorum thresholds and timelock delays. |
| $TRI cross-chain supply integrity | Under what conditions could the OFT bridge create or destroy $TRI supply? Assess for bridge invariant violations. |
| Bittensor integration trust model | Does Trinity's hardware attestation genuinely constrain Yuma Consensus manipulation, or does it create only a soft barrier? |

**Deliverables (PKG-D):**  
Protocol review report with findings classified by severity. Findings should include economic attack cost estimates where quantifiable. Auditors are explicitly asked to identify scenarios where rational-actor behavior diverges from protocol designer intent.

---

## 4. Per-Package Deliverables

The following table defines mandatory deliverables and their deadlines for all packages. Deadlines are relative to the kickoff date (target: 1 July 2026).

| Deliverable | Packages | Deadline | Notes |
|---|---|---|---|
| **Kickoff meeting** — scope confirmation, repository access, Q&A with Trinity engineers | All | Kickoff + 3 days | Slack shared channel to be established |
| **Weekly status reports** | All | Weekly | Brief written update; outstanding findings list |
| **Draft findings report** | All | Kickoff + 4 weeks (≈ 29 July 2026) | All findings submitted; severity classifications proposed |
| **Developer response period** | All | Draft + 2 weeks | Trinity team reviews, disputes severity, submits fixes |
| **Retest of Critical and High findings** | PKG-A, PKG-B, PKG-C | Draft + 5 weeks (≈ 5 August 2026) | Auditors verify fixes; update finding status |
| **Final report** | All | Draft + 6 weeks (≈ 12 August 2026) | Closed/open/acknowledged status for each finding; signed by lead auditor |
| **Public summary** | All | Final + 1 week (≈ 19 August 2026) | After our written approval; suitable for Zenodo deposit and external publication |
| **On-call support** | All | 30 days post-final | Auditor available to answer follow-up questions; scope: clarification only, not new findings |

**R-SI-1 compliance certificate** (PKG-B only) and **phi-anchor verification statement** (PKG-B only) are additional deliverables due with the Final Report.

---

## 5. Timeline

| Milestone | Target Date |
|---|---|
| RFP issued to shortlist | 9 June 2026 |
| **Proposal responses due from firms** | **4 July 2026** |
| Shortlist interviews (1 hour each, video call) | 7–11 July 2026 |
| Engagement selection and NDA execution | 14 July 2026 |
| Repository access granted; kickoff meeting | 15 July 2026 |
| Draft findings reports due | 12 August 2026 |
| Developer remediation complete | 19 August 2026 |
| Final reports due | 26 August 2026 |
| Public summaries published (Zenodo) | 2 September 2026 |
| **Trinity DePIN testnet launch** | **September 2026** |

We are targeting **two parallel, independent engagements** from separate firms covering different packages, to maximize coverage. We expect one firm to cover PKG-A + PKG-D and one firm to cover PKG-B + PKG-C, though we are open to alternative configurations if a firm has demonstrably strong capability across all four packages.

---

## 6. Submission Requirements

Proposals must include all of the following. Incomplete proposals will not be evaluated.

### 6.1 Firm Experience

Provide a concise table of relevant prior engagements covering at least the following categories. Entries with public reports preferred.

| Category | Required | Preferred |
|---|---|---|
| Smart contract audit (EVM, Solidity ≥ 0.8) | Minimum 10 engagements | Experience with LayerZero OApp, cross-chain bridges |
| RTL / hardware security audit | Not required for PKG-A/PKG-D | Required for PKG-B/PKG-C bids |
| DePIN protocol review | Preferred | Prior work with Bittensor, Filecoin, Helium, Render, or similar |
| Bridge security | Required for PKG-A/PKG-D | LayerZero V2 or Axelar specifically |
| Applied cryptography audit | Required for PKG-C | ECDSA, PUF systems, or hardware RNG |
| Formal verification support | Optional | Coq, Lean, or Halmos experience valued |

Firms are encouraged to reference their public audit portfolio pages:
- Trail of Bits: [https://github.com/trailofbits/publications](https://github.com/trailofbits/publications)
- Zellic: [https://www.zellic.io](https://www.zellic.io)
- Spearbit / Cantina: [https://cantina.xyz/solutions/spearbit](https://cantina.xyz/solutions/spearbit)
- Quantstamp: [https://certificate.quantstamp.com](https://certificate.quantstamp.com)
- OpenZeppelin: [https://www.openzeppelin.com/security-audits](https://www.openzeppelin.com/security-audits)

### 6.2 Team Composition

Proposals must name the proposed team. We will not accept anonymous or pool-based staffing commitments for an engagement of this complexity.

Required information per team member:

| Field | Details |
|---|---|
| Name | Full name (not pseudonym) |
| Role | Lead Auditor / Senior Auditor / Supporting Auditor |
| Relevant experience | Summary (3–5 bullet points); link to public work if available |
| Availability | Confirm availability for the July–August 2026 window |

Minimum team structure: **1 named Lead Auditor** + **2–3 Supporting Auditors**. For PKG-B/PKG-C, at least one team member must have demonstrable RTL or hardware security experience.

### 6.3 Methodology

Describe your methodology explicitly. Generic statements ("we do manual review and automated analysis") are insufficient. We expect:

**For PKG-A (Solidity):**
- Which static analysis tools will be run (Slither, Aderyn, etc.) and at what configuration
- Which fuzzing tools will be used (Echidna, Medusa, Foundry invariant fuzz) and for how many corpus iterations
- Whether Halmos or equivalent symbolic execution will be applied and to which contracts
- Manual review process: how are findings triaged? How are false positives from tools filtered?
- How do you handle cross-contract interaction analysis?

**For PKG-B (RTL):**
- Describe your R-SI-1 grep methodology: exact regex or script used
- How will you verify phi-anchor 0x47C0 hardwiring? (Netlist analysis, Yosys synthesis, or RTL trace?)
- What Verilator simulation harness will be used?
- Will you run our cocotb regression test suite? If not, why not?
- Approach to constant-time property verification for the ECDSA path

**For PKG-C (Cryptography):**
- Describe your approach to PUF min-entropy estimation
- How do you verify RFC 6979 compliance in an RTL implementation?
- Tools used for side-channel analysis (if any)

**For PKG-D (Protocol):**
- Economic modeling approach for slashing and incentive analysis
- Threat modeling framework used (STRIDE, custom, etc.)
- How do you assess bridge DVN configuration adequacy?

### 6.4 Sample Report

Provide at least one sample report from a prior engagement of comparable complexity. Reports may be redacted but must demonstrate: finding classification system, finding write-up quality, methodology documentation, and retest results format. Preference given to reports involving: cross-chain bridges, hardware security, or DePIN protocols.

### 6.5 Fixed-Price Proposal with Milestones

Proposals must be **fixed-price** (no time-and-materials). Provide:

- Total price for each package bid upon (PKG-A, PKG-B, PKG-C, PKG-D)
- Payment milestones tied to deliverable schedule (suggested: 30% at kickoff, 40% at draft report, 30% at final report)
- Price for retest of each finding-fix round beyond the one included in base scope
- Any exclusions or assumptions that would alter the fixed price

Our **total budget envelope is $100,000–$150,000** across both parallel engagements. Proposals substantially above this range will not be competitive; we ask firms to scope honestly and exclude packages where they cannot provide quality coverage within this envelope.

### 6.6 Liability Terms

State your standard liability terms. We expect: **liability cap at $1,000,000** (one million USD) or the engagement fee, whichever is greater, for direct damages arising from audit negligence. We will not accept proposals that disclaim all liability for missed Critical findings in production systems.

---

## 7. Evaluation Criteria

Proposals will be scored by a panel of three Trinity TRI-NET team members plus one independent technical advisor. Scoring is weighted as follows:

| Criterion | Weight | Description |
|---|---|---|
| **Experience** | 30% | Depth and relevance of prior engagements; RTL experience weighted heavily for PKG-B/C bids |
| **Methodology rigor** | 25% | Specificity and adequacy of proposed methodology; toolchain coverage; manual review depth |
| **Team seniority** | 20% | Named lead auditor track record; supporting auditor qualifications |
| **Price** | 15% | Value for scope; milestone structure; retest pricing |
| **Timeline match** | 10% | Credible commitment to July–August 2026 schedule; bandwidth confirmation |

Firms will be notified of shortlisting by 11 July 2026 and invited to a 60-minute video interview. Shortlisted firms will be granted read-only repository access under NDA for due-diligence purposes.

---

## 8. Critical Invariants

**The following invariants MUST be validated by auditors. Auditors MUST NOT prescribe changes to modules or properties protected by these invariants. Findings must describe compliance gaps or vulnerabilities; remediation of protected modules requires Trinity team action under the sole authorship protocol described below.**

### INV-1: R-SI-1 — Zero Standalone `*` in Synthesizable RTL

**Description:** No standalone multiplication operator (`*`) may appear in any synthesizable `.v` or `.sv` file in the Trinity RTL codebase. All multiplication must be implemented via explicit shift-add sequences, Wallace tree instantiations, or logarithmic number system (LNS) modules.

**Why it matters:** R-SI-1 is a hard tapeout gate. Synthesis tools on the SKY26b process node do not have adequate standard-cell multiplier coverage; a standalone `*` in synthesis may either silently produce incorrect silicon or fail synthesis entirely. This constraint is verified by a CI workflow (`R-SI-1 no-star check`) on every commit.

**Auditor requirement:** Run an automated scan (exact grep/regex) across all synthesis-eligible RTL files. Report any violation as a **Critical finding**. If zero violations found, issue the R-SI-1 Compliance Certificate.

**Modification protection:** R-SI-1 is an architectural constraint, not a bug. Auditors must not suggest "replacing the constraint with a standard multiplier" as a remediation.

### INV-2: phi-anchor 0x47C0 Hardwiring (Theorem 36.1)

**Description:** At the M1 top-level module (`tt_um_trinity_rot`), the combined output `{uio_out, uo_out}` must be statically driven to `0x47C0` after reset, with no runtime mux or conditional path that can override this value during normal operation.

**Why it matters:** Theorem 36.1 (Glava 36, Trinity TRI-NET PhD Theorem Book) proves cross-die determinism: the phi-anchor value is the root of every hardware attestation payload. If this value is not hardwired at the silicon level, attestation payloads can be forged by a malicious operator, breaking the entire hardware-attestation security model.

**Auditor requirement:** Verify via RTL trace and/or post-synthesis netlist inspection that no condition exists under which `{uio_out, uo_out} ≠ 0x47C0` after reset assertion. Report any violation as **Critical**. Issue the phi-anchor Verification Statement with pass/fail result.

**Modification protection:** The value `0x47C0` is not a magic number subject to change; it is a formally proven invariant. Auditors must not suggest parameterizing this value.


**Description:** The following RTL modules were by Dmitrii Vasilev (sole author) under the v1.0.0 AI-format module specification: `tri_mant_mul`, NF4 encode/decode, Posit16 arithmetic, GF4/GF16/GF256 field arithmetic. These modules are preserved verbatim as canonical on-chain artifacts (Zenodo DOI: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)) and constitute a core technical moat of the Trinity network.

**Auditor requirement:** Verify structural integrity of these modules against the Zenodo-deposited canonical versions (hash comparison). Flag any divergence as a finding. If vulnerabilities are identified within these modules, describe them clearly with severity classification. **Do not prescribe RTL-level rewrites.** Remediation paths for these modules require Trinity team action in consultation with the sole authorship protocol; auditors should recommend that any fix be re-deposited on Zenodo with an updated version number.

**Modification protection:** Unilateral modification of v1.0.0 modules by an auditor (e.g., refactoring to add a `*` operator, or restructuring internal logic) is explicitly out of scope and would constitute a violation of sole authorship rights.

### INV-4: Apache-2.0 / CC-BY-4.0 Licensing

**Description:** All Trinity RTL source is licensed under Apache-2.0. All Trinity documentation, theorem chapters, and formal proof artifacts are licensed under CC-BY-4.0.

**Auditor requirement:** Verify that SPDX license headers are present and correct in all audited source files. Flag missing or incorrect headers as **Informational** findings.

**Modification protection:** License terms must not be changed by auditors.

### INV-5: Lucas POST Mandatory Boot Check

**Description:** The Boot ROM in `tt_um_trinity_rot` must unconditionally execute the Lucas POST self-test sequence before any enclave-mode entry is permitted. There must be no branch, bypass flag, or debug mode that skips this check.

**Auditor requirement:** Verify via Boot ROM RTL trace that the Lucas POST is in the mandatory execution path. Any bypass condition is a **High** or **Critical** finding depending on exploitability.

---

## 9. Out of Scope

The following are explicitly excluded from this RFP. Firms should not include findings, commentary, or scope items related to these areas:

| Excluded Item | Reason |
|---|---|
| $TRI token economics (emission schedule, halving, treasury allocation) | Separate review being conducted by a token-economy specialist firm |
| Off-chain operator node software (Python/Rust daemon) | Separate lower-stakes audit; not required for testnet launch |
| UI/UX of any frontend applications | Not a security audit item |
| Marketing claims or whitepaper assertions | Not a security audit item |
| Bittensor network protocol internals (TAO, subtensor, dTAO) | Out of Trinity's control; known risks documented in M9 spec |
| Ethereum core protocol | Not auditable by a single firm engagement |
| Tiny Tapeout / Efabless shuttle infrastructure | Third-party; auditors may note risks but cannot audit upstream systems |

---

## 10. NDA & Disclosure Policy

### 10.1 NDA

Trinity TRI-NET will execute a mutual NDA with all firms receiving repository access. The NDA will cover:
- Trinity source code, architecture documents, and unpublished theorem book chapters
- Finding details during the embargo period
- Financial terms of the engagement

Standard NDA terms (90-day post-engagement tail). We will provide our NDA template; we are open to reasonable redlines.

### 10.2 Disclosure Policy

Trinity TRI-NET is committed to transparent security practices. Our disclosure policy:

1. **Public publication mandatory.** The final audit report for each package MUST be publicly published. Our target venue is **Zenodo** (open-access repository, DOI assignment). We will not engage with firms that require permanent confidentiality of final reports.

2. **Publication timeline.** Final report must be published within **90 days of remediation completion** (i.e., within 90 days of the date all Critical and High findings are either fixed or formally acknowledged with accepted risk).

3. **Critical finding embargo.** For any Critical finding, we will observe a **90-day coordinated disclosure embargo** from the date of Trinity's written acknowledgment of the finding. During this period, the finding will not be published and will not be shared with third parties. After 90 days (or after the fix is deployed and verified, whichever comes first), the finding will be included in the public report.

4. **No bug bounty conflict.** If a finding has been independently submitted to a bug bounty program (Immunefi or similar) during the embargo period, Trinity will notify the auditor and coordinate disclosure. Trinity does not operate a pre-launch bug bounty on audited contracts; this policy is prospective.

5. **Auditor attribution.** All published reports will credit the auditing firm and named lead auditor. Firms that prefer attribution at the firm level only may request this.

---

## 11. Reference Materials

The following materials will be provided to shortlisted firms upon NDA execution. Preliminary public materials are linked below.

### 11.1 GitHub Repositories

| Repository | Contents |
|---|---|
| [github.com/gHashTag/tt-trinity-phi](https://github.com/gHashTag/tt-trinity-phi) | phi die RTL, TRI-27 ISA, M1 RoT, v1.0.0 format modules |
| [github.com/gHashTag/tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler) | euler die RTL, M9 validator module |
| [github.com/gHashTag/tt-trinity-gamma](https://github.com/gHashTag/tt-trinity-gamma) | gamma die RTL, storage bridge module |
| [github.com/gHashTag/NeuronConstant](https://github.com/gHashTag/NeuronConstant) | Coq proof corpus, theorem book chapters, invariant specs |
| [github.com/gHashTag/trinity-clara](https://github.com/gHashTag/trinity-clara) | Solidity contracts (all PKG-A targets), Foundry test suite |

### 11.2 Specification Documents

The following specification documents are available in the `/tmp/depin_gaps/` document corpus and will be provided as PDFs to shortlisted firms:

| Document | Contents |
|---|---|
| `M1_HW_ROOT_OF_TRUST_SPEC.md` | Full M1 architecture, port definitions, PUF design, Boot ROM, R-SI-1 compliance proof, threat model |
| `M9_BITTENSOR_SUBNET_VALIDATOR_ARCH.md` | M9 architecture, TRI-27 ISA additions, Solidity bridge format, trust model, reward economics |
| `IHP26B_PORT_SPEC.md` | SKY26b/IHP26b process port specification and pinout constraints |
| `FILECOIN_IPFS_INTEGRATION_SPEC.md` | TrinityStorageRegistry.sol design rationale and Filecoin deal flow |
| `TRINITY_INTEGRATIVE_PAPER_DRAFT.md` | Full system architecture paper (pre-publication draft) |
| `TRI_TOKENOMICS_WHITEPAPER.md` | $TRI token design (FYI only — token economics audit out of scope) |
| `GLAVA_37_THEOREM_CHAPTER.md` | Theorem 37.x series — M1–M9 module invariants with Coq scaffolds |

### 11.3 Formal Verification Artifacts

- Theorem 36.1 informal proof + Coq scaffold (phi-anchor hardwiring cross-die determinism)
- Theorem 37.x Coq corpus (84 theorems, 297 `Qed`, 141 `Admitted` as of 2026-05-12)
- Halmos symbolic execution properties for selected IGLALedger.sol and TrinityFinality.sol invariants

### 11.4 Test Vectors

- cocotb regression test suite (M1, M9, v1.0.0 modules) — pass/fail expected outputs
- Foundry invariant fuzz corpus for PKG-A contracts
- R-SI-1 CI check script (reference implementation of the grep scan)

### 11.5 Zenodo Deposits

- Canonical v1.0.0 module deposit: [https://doi.org/10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) — auditors should use this as the reference for v1.0.0 module integrity verification

---

## 12. Contact

All questions and proposals should be directed to:

**Dmitrii Vasilev**  
Principal Investigator, Trinity TRI-NET / IGLA  
Email: admin@t27.ai  
GitHub: [@gHashTag](https://github.com/gHashTag)  

**Proposal deadline: 4 July 2026, 23:59 UTC**

Proposals received after this deadline will not be considered. Proposals must be submitted as a single PDF or Markdown document via email to the address above with subject line: `[RFP RESPONSE] <Firm Name> — Trinity DePIN Security Audit 2026`.

Clarification questions may be submitted by **27 June 2026**. We will respond to all questions and, where answers are non-confidential, circulate them to all firms in the shortlist.

---

## Appendix A: Question Matrix for Shortlisted Auditors

The following 12 questions will be asked at the shortlist interview stage. Firms are encouraged to prepare responses in advance and may include written pre-answers in their proposal.

| # | Question |
|---|---|
| **Q1** | Have you previously audited hardware produced on a Tenstorrent TT-shuttle / Efabless / Tiny Tapeout silicon process? If yes, describe the engagement. If no, describe your approach to establishing a hardware audit methodology for a new process node. |
| **Q2** | Describe your experience with the **LayerZero V2 OApp pattern**, specifically: multi-DVN configuration, message encoding, and cross-chain replay protection. Have you issued findings against LayerZero V2 contracts in prior engagements? |
| **Q3** | What is your approach to **verifying constant-time properties in RTL**? Specifically, how would you confirm that the ECDSA secp256k1 scalar multiplication in `tt_um_trinity_rot` does not have data-dependent execution time? Do you use simulation-based timing analysis, formal methods, or both? |
| **Q4** | How familiar is your team with **Coq** as a formal verification tool? Would your team be able to cross-validate RTL and Solidity properties against Coq lemmas in the Trinity theorem corpus (e.g., confirming that an RTL implementation satisfies the statement of Theorem 37.1)? |
| **Q5** | Can you confirm bandwidth to **start within 30 days** of contract execution (i.e., by 15 July 2026) and deliver draft findings by 12 August 2026? If not, what is your earliest available start date and realistic draft delivery date? |
| **Q6** | What is your pricing model for **retests after finding-fix rounds**? Is one retest included in your base price? What is the cost of additional retest rounds? |
| **Q7** | Describe your experience auditing **DePIN protocols** (decentralized physical infrastructure networks). Have you audited Helium, Hivemapper, Filecoin, Render, Bittensor, or similar protocols? What unique risks did you identify that standard DeFi audit methodology would have missed? |
| **Q8** | How do you handle audit findings in code that is **under active sole authorship restriction** (i.e., where the client has explicitly stated that unilateral modification by the auditor is not permitted)? How do you structure remediation recommendations in such cases? |
| **Q9** | Describe your process for **R-SI-1 style constraint verification** — i.e., verifying that a specific syntactic pattern (standalone `*`) is absent from all synthesizable RTL files. Include the exact grep/regex or tooling you would use. |
| **Q10** | Have you ever issued a **Critical finding that was disputed by the client** and ultimately accepted as a known risk rather than remediated? How was that handled in the final published report? |
| **Q11** | What are your standard terms for **public report publication**? Do you support Zenodo deposit with DOI assignment? What is the minimum embargo period you require before a report can be published? |
| **Q12** | Describe any **conflicts of interest** your firm has with Trinity TRI-NET, IGLA, NeuronConstant, Tenstorrent, LayerZero Labs, Bittensor, or Filecoin Foundation. If none, confirm in writing. |

---

*End of RFP document. Version 1.0. Issued June 2026.*  
*License: CC-BY-4.0. SPDX-License-Identifier: CC-BY-4.0*  
*Document ID: TRI-RFP-SEC-2026-001*
