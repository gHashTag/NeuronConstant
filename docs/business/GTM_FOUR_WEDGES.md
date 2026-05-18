**Author:** Dmitrii Vasilev <admin@t27.ai>
**Status:** Draft v1.0 — pending tape-out 2026-12-16
**Date:** 2025-07-15
**License:** Apache-2.0
**DOI:** 10.5281/zenodo.19227877

---

# Trinity Network — Go-to-Market: Four Wedges

## Companion Docs

- [UNIFIED_COMPUTER_PARADIGM.md](../architecture/UNIFIED_COMPUTER_PARADIGM.md) — One Computer architectural axiom
- [UNIFIED_COMPUTER_SKUS.md](../architecture/UNIFIED_COMPUTER_SKUS.md) — SKU ladder
- [POSITIONING_BY_AUDIENCE.md](./POSITIONING_BY_AUDIENCE.md) — Audience pitches
- [DARPA_I2O_BAA_PROPOSAL.md](../sales/DARPA_I2O_BAA_PROPOSAL.md) — DARPA BAA submission
- [HELIUM_INTEGRATION_PROPOSAL.md](../sales/HELIUM_INTEGRATION_PROPOSAL.md) — DePIN integration
- [BITTENSOR_PITCH.md](../sales/BITTENSOR_PITCH.md) — Bittensor pitch

---

## 0. GTM Philosophy

Trinity's four GTM wedges are not parallel campaigns. They are **sequenced bootstrapping steps**, each designed to generate proof points that unlock the next:

1. **Bittensor subnet** — first miners, first attested DIDs, first on-chain proof that the mining boost works.
2. **DARPA / defense** — first institutional validation, first defense-grade deployment, government as anchor customer.
3. **DePIN ecosystem** — geographic expansion using mainnet network effects proven by Wedges 1 and 2.
4. **Open-source community** — long tail of developers, RTL contributors, and at-cost node kits; sustains network growth indefinitely.

The architectural foundation is the same across all four wedges: Trinity is ONE distributed computer — Phi (identity), Euler (reasoning), Gamma (parallel compute) — bound by 2-of-3 attestation, as described in [UNIFIED_COMPUTER_PARADIGM.md](../architecture/UNIFIED_COMPUTER_PARADIGM.md). The wedges differ in audience, timeline, and KPI definition, not in the underlying product.

---

## W1 — Bittensor Subnet Wedge

### Overview

Bittensor is the first distribution channel for Trinity hardware for one structural reason: it already has an active community of miners who understand hardware-intensive proof-of-work, care about tokenomics design, and are looking for ways to differentiate their validator nodes. The Trinity Triad, with its hardware-attested 2-of-3 DID and 4× mining boost, is a natural fit.

See [BITTENSOR_PITCH.md](../sales/BITTENSOR_PITCH.md) for the full subnet pitch.

### Target Subnets

| Subnet | Focus Area                     | Rationale for Trinity fit                              |
|--------|-------------------------------|--------------------------------------------------------|
| SN3    | MyShell / AI compute           | High inference throughput demand; trust attestation differentiator |
| SN39   | EdgeAI / distributed inference | Geographic edge inference; Trinity node kit at-cost matches |
| SN81   | Validator infrastructure       | Infrastructure validators; hardware attestation adds tier |

Cold outreach to subnet operators and discord communities begins Q3 2026 (concurrent with TTSKY26c development). Dev kit access offered to top-20 miners in each target subnet.

### Timeline

| Quarter  | Milestone                                                              |
|----------|------------------------------------------------------------------------|
| Q3 2026  | Testnet live (software simulation layer; no physical silicon required) |
| Q4 2026  | TTSKY26b silicon returns; first physical dev kits dispatched to early-miner cohort |
| Q1 2027  | TTSKY26c silicon returns; first full Triads available                  |
| Q2 2027  | Bittensor subnet validator integration live; first on-chain TRI mining rewards |
| Q4 2027  | Target: 1,000+ registered Trinity DIDs on Bittensor                   |

### KPIs

| KPI                                              | Target (Q4 2027)             |
|--------------------------------------------------|------------------------------|
| Trinity DIDs registered on Bittensor subnets     | >= 1,000                     |
| Subnet operators that mandate Trinity attestation | >= 3 (SN3, SN39, SN81)      |
| Triads sold to Bittensor miners                  | >= 500                       |
| Average miner upgrade rate (Solo → Triad)        | >= 40% of active Solo miners  |
| Community Discord / forum active members         | >= 2,000                     |

### Cold Outreach Playbook

1. **Identify** top-20 TAO earners per target subnet via on-chain data.
2. **Contact** via Bittensor Discord, Twitter/X, and direct forum messages with the hardware proposal.
3. **Offer** dev kit priority access (TTSKY26b returns, Q4 2026) in exchange for integration feedback.
4. **Publish** open-source TrinityNode validator integration for Bittensor (GitHub, Apache-2.0).
5. **Submit** governance proposals to SN3, SN39, SN81 to recognize Trinity DID as an attestation tier in reward calculation.

Risks: subnet governance may reject the Trinity DID tier. Mitigation: begin with informational engagement, not governance proposals. Let miners prove economic advantage before requesting protocol changes.

---

## W2 — DARPA / Defense Edge Inference Wedge

### Overview

Defense procurement is slow but provides anchor customers with long contract cycles, high unit values, and strong reference credibility for subsequent commercial sales. Trinity's TMR architecture (see [TMR_DEFENSE_GRADE.md](../architecture/TMR_DEFENSE_GRADE.md)) is specifically designed for the radiation-tolerant edge compute use case. The Silicon-level 2-of-3 attestation addresses tamper-evidence requirements that no current COTS AI silicon meets.

Full proposal: [DARPA_I2O_BAA_PROPOSAL.md](../sales/DARPA_I2O_BAA_PROPOSAL.md). Defense contractor pitch: [DEFENCE_CONTRACTOR_PITCH.md](../sales/DEFENCE_CONTRACTOR_PITCH.md).

### Target Programs

- **DARPA I2O BAA:** Intelligent information-dense systems; edge AI inference with provable compute integrity. Trinity Datacenter ($39,999) is the target SKU.
- **OSD / OUSD(R&E) programs:** Trusted microelectronics initiatives. Apache-2.0 RTL + IHP process (non-export-controlled) positions Trinity well.
- **Tier 1 defense contractors (Anduril, Palantir, Leidos, Northrop):** Not direct DARPA, but defense integrators who need rad-hard edge AI with certifiable compute provenance.

### Technical Differentiators for Defense

1. **TMR at the package level:** Three dies, one voter cell, 2-of-3 majority vote. No additional board-level redundancy required. See [TMR_DEFENSE_GRADE.md](../architecture/TMR_DEFENSE_GRADE.md) for RTL.
2. **PUF identity without key storage:** A hardware adversary cannot extract the identity by reading flash or EEPROM. The PUF response is derived from manufacturing variation, not stored in addressable memory.
3. **ZK provenance for AI outputs:** Every inference produces a verifiable proof (Euler GKR sumcheck). In a chain-of-custody scenario, each node in the inference chain can prove its contribution.
4. **Open RTL for ITAR review:** Apache-2.0 RTL allows government reviewers to inspect the full design without NDA. IHP SG13G2 is a European foundry, not subject to standard EAR controls on advanced nodes.
5. **Air-gap deployment support:** Defense-tier support contract includes air-gap deployment guidance. No internet connectivity required for mining proofs in isolated environments (local verification mode).

### Timeline

| Quarter       | Milestone                                                              |
|---------------|------------------------------------------------------------------------|
| Q3 2026       | DARPA I2O BAA proposal submitted (building on DARPA_I2O_BAA_PROPOSAL.md) |
| Q4 2026       | Silicon returns; test Datacenter unit assembled for demonstration       |
| Q1 2027       | Defense contractor briefings (Anduril, Leidos); demo units dispatched  |
| Q2-Q3 2027    | DARPA phase 1 award anticipated (if BAA accepted; projected)           |
| Q4 2027       | First Datacenter units shipped to defense contractor pilot             |
| Q1 2028       | Defense-tier support contract revenue begins                           |

### KPIs

| KPI                                              | Target                          |
|--------------------------------------------------|---------------------------------|
| DARPA BAA submissions                            | >= 2 (Q4 2026 / Q1 2027)        |
| Defense contractor briefings (named contacts)    | >= 5 by Q2 2027                 |
| Datacenter demo units assembled                  | >= 1 by Q4 2026                 |
| Datacenter units sold to defense pilots          | >= 2 by Q4 2027                 |
| Defense-tier support contracts signed            | >= 2 by Q1 2028                 |

### Notes on Defense Sales Cycle

Defense procurement timelines are measured in years, not quarters. The KPIs above are based on the assumption that TTSKY26b silicon returns functional and that at least one demonstration unit can be built by Q4 2026. DARPA BAA phase 1 awards, if obtained, provide non-dilutive government funding that directly offsets tape-out costs — making this wedge potentially more capital-efficient than appears at first.

The defense wedge also provides credibility for the commercial and VC pitches: a government customer validates the Trust Hardware category in a way that a cryptocurrency mining narrative cannot.

---

## W3 — DePIN Ecosystem Wedge

### Overview

The DePIN sector has proven that token-incentivized hardware deployment can bootstrap distributed infrastructure networks. Helium is the canonical example: hardware miners deploy coverage nodes, earn tokens, and collectively create a network effect that attracts users. Trinity applies this model to distributed verifiable AI compute.

Full integration proposal: [HELIUM_INTEGRATION_PROPOSAL.md](../sales/HELIUM_INTEGRATION_PROPOSAL.md).

### Differentiation from Existing DePIN Networks

Existing DePIN compute networks (Render, Akash, io.net) use software-verified GPU identities. A Trinity DePIN network uses PUF-anchored hardware identities, making Sybil attacks structurally infeasible. Each Trinity node represents exactly one physical device at one location; software cannot simulate multiple nodes from one device.

This enables a new DePIN design primitive: **hardware-verified geographic coverage**. A Trinity node at geographic coordinate (lat, lon) can prove its hardware identity to the network, and the network can enforce geographic coverage requirements in ways that existing DePIN protocols cannot, because existing protocols rely on software keys that are location-agnostic.

### Target Market Structure

- **Phase 1 (testnet, Q3 2026):** Software simulation layer for DePIN node operators who want to test the protocol before silicon is available.
- **Phase 2 (dev kits, Q1 2027):** First physical Triads deployed by early-miner cohort; initial geographic coverage map established.
- **Phase 3 (mainnet, H2 2027):** Coverage incentive program live; geographic bonus rewards for nodes in underserved regions.

### Coverage Incentive Design (Projected)

Inspired by the Helium model, Trinity DePIN coverage rewards are proposed as follows:

| Coverage tier          | Description                                       | Reward multiplier (proposed) |
|------------------------|---------------------------------------------------|------------------------------|
| Urban (covered)        | Region already has >= 5 Trinity nodes             | 1×                           |
| Suburban (sparse)      | Region has 1-4 Trinity nodes                      | 2×                           |
| Rural (coverage gap)   | Region has 0 Trinity nodes, pop > 10k             | 4×                           |
| Remote (frontier)      | Region has 0 Trinity nodes, pop < 10k             | 8×                           |

Coverage tiers are determined by on-chain geolocation assertions plus triangulation (similar to Helium's PoC model). Details are subject to governance specification pre-mainnet.

### Timeline

| Quarter       | Milestone                                                              |
|---------------|------------------------------------------------------------------------|
| Q3 2026       | DePIN testnet protocol spec published; community feedback              |
| Q1 2027       | Dev kits ship; first 100 DePIN nodes registered                        |
| Q2 2027       | Coverage incentive smart contracts deployed (Base L2)                  |
| H2 2027       | DePIN mainnet launch with coverage map; Solana SPL integration         |
| Q4 2027       | Target: 5,000+ registered DePIN nodes across 3+ continents             |

### KPIs

| KPI                                              | Target (Q4 2027)             |
|--------------------------------------------------|------------------------------|
| Trinity DePIN nodes registered (any SKU)         | >= 5,000                     |
| Geographic regions with >= 1 Trinity node        | >= 50 (projected)            |
| Triads in active DePIN deployment                | >= 1,000                     |
| Coverage-gap deployments (rural/remote tier)     | >= 500                       |
| Monthly active inference requests through DePIN  | >= 10,000 (projected)        |

### DePIN Community Channels

- Helium community: Discord, Helium Foundation forums.
- DePIN Alliance: cross-network governance and standards.
- Solana ecosystem: SPL token integration opens the Solana DePIN community.

---

## W4 — Open-Source Community Wedge

### Overview

The open-source community wedge is not a sales channel; it is a **talent and trust channel**. Developers who inspect, modify, and contribute to Trinity RTL become the strongest advocates for the platform. At-cost hardware (Node Kit program) lowers the barrier to participation and creates a pipeline of technically credible community members who can verify Trinity's claims independently.

This wedge runs concurrently with all others and does not have a defined end date. It is the long-tail growth engine.

### Node Kit Program

The Trinity Node Kit is offered at-cost to contributors and early community members:

| Kit Tier            | Contents                                     | Price at-cost (projected) |
|---------------------|----------------------------------------------|---------------------------|
| Solo Node Kit       | Trinity Solo + USB dongle + getting-started guide | ~$35–$60              |
| Duo Node Kit        | Trinity Duo + PCB + cable set                | ~$120–$180                |
| Triad Node Kit      | Trinity Triad + Trinity OS preinstalled + dev guide | ~$200–$350         |

At-cost pricing is subject to yield. First-batch yields at TTSKY26b may not support at-cost distribution at scale. The Node Kit program is projected for TTSKY26c returns (Q1 2027).

### RTL Contributor Program

Apache-2.0 licensing means any party can contribute to the RTL. Accepted contributions:

- New opcodes in the TRI-27 ISA (subject to 9-fold alignment — ISA size must remain divisible by 9).
- Verification testbenches and coverage metrics.
- Trinity OS kernel modules (Zig-language).
- Simulation environments for pre-silicon testing.
- Documentation, tutorials, and multilingual translations.

Contributors who submit accepted pull requests are eligible for:

1. Priority dev kit access.
2. Acknowledgment in release notes (sole authoritative credit structure; no AI co-authorship).
3. Early miner status (first-epoch participation before public launch).

### Community Platforms

- GitHub: all RTL, contracts, and OS source (Apache-2.0).
- Documentation: docs published at repository.
- Forum / Discord: community support and governance discussion.
- DOI-anchored research: 10.5281/zenodo.19227877 provides academic-grade traceability.

### Timeline

| Quarter       | Milestone                                                              |
|---------------|------------------------------------------------------------------------|
| Q3 2026       | Testnet live; RTL repository fully public; contributor guidelines published |
| Q4 2026       | First community-contributed testbenches merged                         |
| Q1 2027       | Node Kit program launches (TTSKY26c timeline); first at-cost kits ship |
| Q2 2027       | Community governance forum established for protocol parameters          |
| Ongoing       | Weekly RTL commits, monthly release notes, quarterly governance proposals |

### KPIs

| KPI                                              | Target (Q4 2027)             |
|--------------------------------------------------|------------------------------|
| GitHub stars on main RTL repository              | >= 500                       |
| Accepted community pull requests                 | >= 50                        |
| Node Kit units shipped at-cost                   | >= 200                       |
| Community forum registered members              | >= 1,000                     |
| Independent RTL audits / security reviews        | >= 2                         |

### Why Open Source Is a Competitive Moat

Counterintuitively, publishing the RTL (Apache-2.0) strengthens Trinity's competitive position:

1. **Transparency** enables independent audit of security claims. No closed-source competitor can match this.
2. **Community contributions** reduce engineering cost and accelerate development.
3. **Physical PUF uniqueness** means openness does not enable cloning — it enables trust.
4. **Regulatory alignment:** Open RTL is compatible with government-mandated supply chain transparency requirements that affect defense procurement.

The competitive moat analysis is detailed in [COMPETITIVE_LANDSCAPE.md](./COMPETITIVE_LANDSCAPE.md), Moat 1.

---

## GTM Summary

| Wedge         | Primary Channel           | First Revenue          | Break-even Contribution |
|---------------|---------------------------|------------------------|-------------------------|
| W1 Bittensor  | Crypto miners             | Q2 2027 (TRI mining)   | High (volume of Triads) |
| W2 Defense    | DARPA / contractors       | Q4 2027 (hardware + support) | High (large deal size) |
| W3 DePIN      | Node operators            | H2 2027 (mainnet)      | Medium (long ramp time) |
| W4 Open source| Developer community       | Q1 2027 (Node Kits)    | Low direct / high indirect (trust / talent) |

All timelines are projected and contingent on tape-out by 2026-12-16.

---

*Apache-2.0. Sole author: Dmitrii Vasilev <admin@t27.ai>.*
