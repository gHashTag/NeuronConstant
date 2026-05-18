# Trinity DePIN — Seed Pitch Deck Outline
## Raising $5M | Principal Investigator: Dmitrii Vasilev
### Version: May 2026 (Pre-Seed / Seed)

> **Note:** Revenue projections and market sizing figures marked *(preliminary)* are estimates subject to revision. Token-related figures are indicative only and do not constitute a securities offering.

---

## Slide 1 — Title

**Headline:** Trinity DePIN: Verifiable AI Inference on Open Silicon

**Sub-headline:** Raising $5M seed — the first hardware-anchored decentralized AI inference network

**Bullets:**
- Principal Investigator: Dmitrii Vasilev, Cape Town ZA
- Three dies taped out on Tiny Tapeout SKY26b (submission: May 18, 2026)
- Open-source, R-SI-1 audited, canonical anchor 0x47C0
- Repos: [gHashTag/tt-trinity-phi](https://github.com/gHashTag/tt-trinity-phi), [gHashTag/tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler), [gHashTag/tt-trinity-gamma](https://github.com/gHashTag/tt-trinity-gamma)
- Zenodo archive: [DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

**Suggested visual:** Three-die layout diagram (phi / euler / gamma) against a SkyWater PDK wafer photo, with 0x47C0 anchor highlighted in circuit annotation.

**Speaker notes:** Open with the core claim: Trinity is not another cloud AI wrapper. It is a physical, auditable root of trust on silicon that any engineer can read at the mask level. The tapeout deadline tonight is proof of execution velocity. This slide should convey hardware credibility in 10 seconds.

---

## Slide 2 — Problem

**Headline:** Cloud AI Is Unverifiable by Design — and Regulators Are Noticing

**Sub-headline:** Compliance theater is not compliance

**Bullets:**
- EU AI Act (effective August 2026) requires auditability of high-risk AI systems; current cloud APIs cannot produce hardware-level proof of inference path
- U.S. Executive Order 14110 mandates AI safety reporting with no enforceable attestation mechanism for inference
- Bittensor ($TAO): largest decentralized AI network; zero hardware root of trust — validators can lie
- Helium PoC: proof-of-coverage is [demonstrably gameable](https://cointelegraph.com/news/helium-hotspot-gaming-problem) by GPS spoofing
- Result: ~$200B cloud AI market with no verifiable audit trail below the software layer

**Suggested visual:** Comparison table — Cloud (AWS/Azure), Bittensor, Helium, Trinity — with checkmarks on: HW root, open-source netlist, formal theorem, regulatory log.

**Speaker notes:** The AI Act's Article 13 transparency requirements and Article 17 quality management obligations go live August 2026. A $50K enterprise fine-per-incident regime is plausible. Existing DePIN networks cannot produce a log that satisfies a hardware-level audit. This is the compliance gap Trinity was designed to fill.

---

## Slide 3 — Solution

**Headline:** Hardware-Anchored Verifiable AI: The Silicon Is the Notary

**Sub-headline:** Canonical anchor 0x47C0, immutable at the mask level, auditable by any fab

**Bullets:**
- Three open dies (phi / euler / gamma) on 130nm SkyWater — AI format modules NF4, Posit16, GF4/GF16/GF256, tri-mantissa multiply
- Canonical anchor `0x47C0` hardwired and formally proved by Theorem 36.1 (TG-TRIAD-X); refreshable at 200 kHz, 5W envelope
- R-SI-1 synthesis audit: zero unqualified `*` operators in netlist — reproducible compliance check
- M-of-N attestation: inference result signed by hardware anchor before leaving the node
- Full open-source under permissive license; PDK: SkyWater 130nm via [Tiny Tapeout](https://tinytapeout.com)

**Suggested visual:** Architecture diagram — inference request → phi/euler/gamma pipeline → 0x47C0 anchor signature → attestation output — with comparison lane showing a software-only path lacking the signature step.

**Speaker notes:** "We treat the silicon as a notary, not a computer" (Dmitrii Vasilev). The anchor is physically etched — it cannot be patched by a software update, cannot be disabled by a cloud provider, and can be independently verified by reading the open-source GDS2 layout. This is the moat.

---

## Slide 4 — Why Now

**Headline:** Three Forcing Functions Converged in 2024–2026

**Sub-headline:** Open silicon access + regulatory pressure + DePIN maturity

**Bullets:**
- **Open silicon democratized (2024+):** Tiny Tapeout [shuttle program](https://tinytapeout.com) reduced tapeout cost from ~$100K to ~$300/tile; SKY26b is the 26th shuttle — process proven
- **AI Act enforcement August 2026:** First wave of high-risk AI system audits will expose the attestation gap; enterprises will need compliant inference infrastructure
- **DePIN market:** *(preliminary)* estimated $35B by 2030 (Messari 2024); hardware-anchored segment currently $0 — greenfield
- **DARPA CLARA program:** Cryptographic Log and Attestation for Reasoning Agents — Trinity proposal submitted April 17, 2026; validates the technical direction
- **IHP SG13G2 second-source path:** European open PDK available for 2027 expansion, reducing single-fab dependency

**Suggested visual:** Timeline bar chart: 2022 (TT v1), 2024 (SKY26 opens), Aug 2026 (AI Act), Q4 2026 (Trinity dies ship), 2027 (Trinity Node 10K), 2030 (DePIN $35B*(preliminary)*).

**Speaker notes:** The window is narrow. AI Act enforcement begins August 2026; Trinity dies ship Q4 2026. Any competitor starting a tapeout today cannot ship hardware before mid-2027 at the earliest. The DARPA CLARA submission (April 17, 2026) is not a grant — it is a signal that the U.S. DoD considers hardware attestation of AI a serious unsolved problem.

---

## Slide 5 — Product

**Headline:** Three Layers: Silicon → Node Kit → Network

**Sub-headline:** Demo-able today on phi + euler + gamma

**Bullets:**
- **Trinity Triad dies** (Q4 2026): phi (nano inference), euler (GF16 acceleration), gamma (full AI format stack) — available to backers post-shuttle
- **Trinity Node kit** (Q1 2027): $200 developer board integrating all three dies; USB-C powered; runs local attestation API
- **$TRI utility token** *(not a security)*: fees for attestation requests burned on-chain; node operators earn $TRI for verified inference tasks
- **Attestation API**: REST endpoint returning inference result + hardware signature + anchor hash — drop-in for AI Act compliance logging
- **Live demo**: real-time inference attestation on the three physical dies — [gHashTag/NeuronConstant](https://github.com/gHashTag/NeuronConstant) for integration docs

**Suggested visual:** Product photo mockup of Trinity Node board (render acceptable), with inset showing API response JSON including `anchor: "0x47C0"` and hardware signature field.

**Speaker notes:** The $200 price point is deliberate — it must be accessible to the long tail of DePIN node operators, not just enterprises. Margin at $200 MSRP with estimated BOM of ~$140 is approximately 30%. The $TRI token is a utility fee instrument, not a fundraising vehicle. Token launch is post-mainnet (Q4 2026) to avoid regulatory risk.

---

## Slide 6 — Traction

**Headline:** Tape-Out Complete — Ahead of Schedule, Under Budget

**Sub-headline:** Execution evidence before any external funding

**Bullets:**
- **TT SKY26b submission:** 3 dies submitted May 18, 2026 — [gHashTag/tt-trinity-phi](https://github.com/gHashTag/tt-trinity-phi), [tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler), [tt-trinity-gamma](https://github.com/gHashTag/tt-trinity-gamma)
- **Zenodo archive:** permanent DOI [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) — 7-specification technical corpus published
- **DARPA CLARA proposal:** submitted April 17, 2026 — validates federal interest in hardware AI attestation
- **R-SI-1 compliance:** all three dies pass synthesis audit — zero unqualified `*` operators; reproducible via open netlist

**Suggested visual:** GitHub commit graph for all three repos overlaid on a project timeline; Zenodo DOI badge prominently displayed.

**Speaker notes:** Everything on this slide happened with zero institutional funding — bootstrapped via Tiny Tapeout shuttle fees (~$300–$500/tile depending on size). Three dies, seven specs, one DARPA submission, one Zenodo archive. The cost-to-tapeout ratio is an order of magnitude below conventional ASIC development. This is what lean silicon development looks like.

---

## Slide 7 — Business Model

**Headline:** Three Revenue Streams, One Defensible Moat

**Sub-headline:** Hardware margin + token utility + enterprise SaaS

**Bullets:**
- **Hardware kit sales:** Trinity Node at $200 MSRP, ~30% gross margin; target 10,000 units in 2027 → $600K gross *(preliminary)*
- **$TRI token utility fees:** attestation requests burn $TRI; node operators earn $TRI; treasury retains protocol fee — volume-driven, not speculative
- **Enterprise AI Act SaaS:** annual subscription for compliance attestation logging — target $50K/year/customer; 10 enterprise customers in Y2 → $500K ARR *(preliminary)*
- **DARPA / grant revenue:** if CLARA awarded — non-dilutive; expected range $500K–$2M *(speculative, not in base case)*
- **Y3 blended revenue projection:** $5M *(preliminary — hardware + SaaS; token revenue excluded from projection)*

**Suggested visual:** Revenue waterfall bar chart: Y1 (pilot), Y2 (~$1.5M*(preliminary)*), Y3 (~$5M*(preliminary)*) — clearly marked preliminary; three color-coded streams.

**Speaker notes:** The business model is intentionally hardware-first. Software DePIN networks have shown that pure-token models without physical anchors collapse under Sybil attacks. Hardware margin creates a floor. Enterprise SaaS creates recurring revenue. The token is the coordination layer, not the business model. All revenue projections are preliminary and should not be treated as forecasts.

---

## Slide 8 — Market & Competition

**Headline:** Trinity Is the Only Hardware-Anchored Verifiable AI Compute Network

**Sub-headline:** Competitive moat is physical, not algorithmic

**Bullets:**
- **Bittensor ($TAO):** large decentralized AI network; *no hardware root of trust*; validators are software processes that can be forged
- **Render Network (RNDR):** GPU rendering focus; not AI inference; no attestation layer; no compliance tooling
- **Akash Network:** decentralized cloud compute; no inference-specific attestation; no hardware anchor; AI Act compliance not addressed
- **Helium:** PoC gameable via GPS spoofing; coverage claims unverifiable at hardware level
- **Trinity:** open GDS2 netlist + formal theorem + immutable anchor + R-SI-1 audit = verifiable at mask level; only entrant in this category

**Suggested visual:** Competitive matrix table — rows: Bittensor, Render, Akash, Helium, Trinity — columns: HW root of trust, open netlist, formal proof, AI Act compliance log, inference-specific. Trinity is the only full row of checkmarks.

**Speaker notes:** "Hardware moat" means: a competitor cannot catch up by writing better code. They must tape out new silicon — a 12–18 month process minimum. Trinity's second-source path (IHP SG13G2, 2027) extends the moat to a second fab. The open-source strategy is intentional: it invites audit, which builds trust, which is exactly what regulated enterprise customers need.

---

## Slide 9 — Team

**Headline:** Lean, Credible, Hardware-Proven

**Sub-headline:** Execution already demonstrated — tapeout complete

**Bullets:**
- **Dmitrii Vasilev (PI):** hardware architect, Cape Town ZA; designed and submitted all three dies; author of 7-spec corpus; DARPA CLARA proposal author
- **Matt Venn (TBD, advisory):** founder of [Tiny Tapeout](https://tinytapeout.com); world-leading expert in open silicon shuttle programs
- **Onur Mutlu (TBD, advisory):** Professor of Computer Science, ETH Zürich; leading researcher in memory systems and hardware architecture
- **Open call:** seeking hardware security advisor (post-quantum credentials preferred) and DePIN ecosystem advisor

**Suggested visual:** Headshot grid with role labels; TBD advisory slots shown as open circles with role description; GitHub commit activity bar for Dmitrii as execution evidence.


---

## Slide 10 — Roadmap

**Headline:** From Silicon to Network in Four Quarters

**Sub-headline:** Hardware-first sequencing — no mainnet before dies ship

**Bullets:**
- **Q3 2026:** Testnet launch — software attestation API live; community node operator onboarding; dies in fabrication at SkyWater
- **Q4 2026:** Trinity dies ship to backers; mainnet launch; $TRI token utility launch (post-legal review); first enterprise pilot customers
- **Q1 2027:** Trinity Node $200 kit general availability; target 1,000 nodes deployed
- **2027 H2:** IHP SG13G2 second-source tapeout (European open PDK); target 10,000 Trinity Nodes; Series A readiness
- **2028+:** Protocol licensing to enterprise AI infrastructure vendors; potential DARPA CLARA milestone deliverables if awarded

**Suggested visual:** Gantt-style horizontal timeline with four swim lanes: Silicon, Software, Network, Business — color-coded milestones, Q3 2026 to Q4 2027.

**Speaker notes:** The sequencing constraint is intentional and investor-friendly: we do not launch the network until the hardware is in operators' hands. This prevents the "phantom node" problem that has plagued other DePIN projects. The IHP second-source in 2027 is critical for enterprise sales — single-fab dependency is a supply chain risk that regulated customers will flag.

---

## Slide 11 — Financials & Use of Funds

**Headline:** $5M Deploys Against Hardware, Manufacturing, and Audit — Not Overhead

**Sub-headline:** *(All figures preliminary — subject to revision upon detailed engineering cost review)*

**Bullets:**
- **$1.5M — IHP SG13G2 tape-outs (2027):** second-source fab run; European PDK; multi-project wafer + dedicated run options
- **$1.5M — Trinity Node manufacturing:** 10,000-unit production run; BOM ~$140/unit; contract manufacturing (Southeast Asia)
- **$1.0M — Audits + legal:** security audit of RTL and token contracts; legal review of $TRI utility token structure; AI Act compliance legal opinion; IP filings
- **$500K — Personnel:** 2 hardware engineers (RTL + verification), 1 firmware engineer, 1 BD/partnerships; 18-month runway
- **$500K — Operations + runway:** cloud dev infra, travel, community, 6-month operating buffer

**Revenue projections *(preliminary)*:**
- Y1: $0 (tapeout + build year)
- Y2: ~$1.5M *(preliminary)* — hardware kits + first enterprise SaaS contracts
- Y3: ~$5M *(preliminary)* — hardware scale + 50 enterprise customers + token fee volume

**Suggested visual:** Donut chart of use of funds (five segments); separate bar chart of Y1–Y3 revenue ramp with *(preliminary)* watermark on each bar.

**Speaker notes:** The largest single line item is the IHP second-source tapeout — this is the moat-extension investment. Without a second fab option, enterprise sales stall at procurement review. The 18-month personnel runway with $500K is tight; it assumes the two hardware engineers are mid-level and that the PI (Dmitrii) is not drawing a market salary in Y1. All projections are preliminary and illustrative.

---

## Slide 12 — The Ask

**Headline:** $5M Seed — Lead Investor Sought for Crypto-Native Deep Tech

**Sub-headline:** Clear milestones, hardware execution already demonstrated

**Bullets:**
- **Raise:** $5M seed; valuation TBD (recommend: comparable open-silicon DePIN projects; suggest anchor on Zenodo corpus + tapeout cost + DARPA submission as de-risking signal)
- **Use:** as itemized on Slide 11 — silicon, manufacturing, audit, team
- **Milestones unlocked:** Trinity Node GA (Q1 2027), 10K nodes (2027 H2), Series A readiness
- **Target lead investors:** [Multicoin Capital](https://multicoin.capital) (DePIN thesis), [Pantera Capital](https://panteracapital.com) (crypto infrastructure), [a16z crypto](https://a16zcrypto.com) (open-source tech), [Variant Fund](https://variant.fund) (ownership economy / DePIN)
- **Contact:** GitHub Discussions — [gHashTag/NeuronConstant](https://github.com/gHashTag/NeuronConstant) | Zenodo: [DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

**Suggested visual:** Clean "Closing Slide" layout — $5M figure large, milestone unlock timeline, four target investor logos (placeholder boxes if logos unavailable), single QR code linking to GitHub repo.

**Speaker notes:** The ask is $5M because the two largest cost items — IHP tapeout and 10K-unit manufacturing run — are not compressible without sacrificing the second-fab moat or the node count needed to demonstrate a real network. Valuation is intentionally left TBD for lead investor input; the de-risking evidence (completed tapeout, DARPA submission, open-source corpus, zero dilution to date) supports a meaningful seed premium over pre-product comparables. Trinity is not asking investors to bet on a whitepaper — the silicon is already in fabrication.

---

## Appendix: Key Links

| Resource | URL |
|---|---|
| tt-trinity-phi (GitHub) | https://github.com/gHashTag/tt-trinity-phi |
| tt-trinity-euler (GitHub) | https://github.com/gHashTag/tt-trinity-euler |
| tt-trinity-gamma (GitHub) | https://github.com/gHashTag/tt-trinity-gamma |
| NeuronConstant (discussions) | https://github.com/gHashTag/NeuronConstant |
| Zenodo archive | https://doi.org/10.5281/zenodo.19227877 |
| Tiny Tapeout | https://tinytapeout.com |
| EU AI Act text | https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689 |

---

*This document is a pitch outline for discussion purposes only. It does not constitute an offer to sell securities. $TRI token references are indicative of utility design and do not constitute a securities offering. All financial projections are preliminary estimates.*
