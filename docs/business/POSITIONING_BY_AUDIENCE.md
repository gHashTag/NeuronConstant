**Author:** Dmitrii Vasilev <admin@t27.ai>
**Status:** Draft v1.0 — pending tape-out 2026-12-16
**Date:** 2025-07-15
**License:** Apache-2.0
**DOI:** 10.5281/zenodo.19227877

---

# Trinity Network — Positioning by Audience

## Companion Docs

- [UNIFIED_COMPUTER_PARADIGM.md](../architecture/UNIFIED_COMPUTER_PARADIGM.md) — One Computer architectural axiom
- [UNIFIED_COMPUTER_SKUS.md](../architecture/UNIFIED_COMPUTER_SKUS.md) — SKU ladder
- [COMPETITIVE_LANDSCAPE.md](./COMPETITIVE_LANDSCAPE.md) — Moats and competitor matrix
- [GTM_FOUR_WEDGES.md](./GTM_FOUR_WEDGES.md) — Go-to-market channels

---

## 0. The Anchor

Every audience-specific pitch in this document resolves to the same core claim:

> **Trinity is one computer with three minds, bound by 2-of-3 attestation, verified by ternary completeness 3^27.**

This is not a slogan. It is a factual architectural statement derived from [UNIFIED_COMPUTER_PARADIGM.md](../architecture/UNIFIED_COMPUTER_PARADIGM.md): Phi (identity), Euler (reasoning), and Gamma (parallel compute) are three functional organs of one distributed silicon computer, not three independent products. The Triad ($1,499) is the minimum configuration that realizes the full computer.

Different audiences need different on-ramps to this claim. The six sections below provide those on-ramps.

---

## 1. Audience: Venture Capital

### Tagline

**"The Trust Hardware category — first mover, open silicon, hardware-anchored identity."**

### Pitch (English)

The AI compute market has bifurcated into raw throughput (NVIDIA, Groq, Cerebras) and software-layer trust (TEEs, SGX enclaves, zero-knowledge proofs on commodity silicon). Neither pole produces a physically unforgeable proof that a specific compute result came from a specific piece of hardware.

Trinity creates the Trust Hardware category by combining three elements that have never shipped together: (1) open-source RTL (Apache-2.0) that any party can inspect, (2) a Physical Unclonable Function identity that cannot be cloned regardless of RTL access, and (3) a ZK proof pipeline (Euler GKR sumcheck) that proves computation correctness on-chain without trusting the operator.

The product is a five-SKU hardware ladder from $99 (Trinity Solo, IoT identity) to $39,999 (Trinity Datacenter, 27 Triads for enterprise / defense). The flagship is the Trinity Triad at $1,499 — the minimum configuration that assembles the full computer, earns the 4× mining boost in the TRI network, and can mint a Trinity DID.

Tokenomics: `3^27 = 7,625,597,484,987 TRI`, 0% pre-mine, 100% mineable, 9 halvings every 4 years. No VC allocation, no founder tokens. This is a structural regulatory advantage: the fair-launch design minimizes Howey-test exposure and positions Trinity favorably under MiCA.

The market timing is specific: EU AI Act requirements for provenance of AI outputs create institutional demand for hardware attestation by 2026-2027. DARPA and defense contractors need rad-hard edge inference (TMR is built into the tri-ring fabric). DePIN ecosystems (Helium-adjacent) need geographic hardware nodes with unforgeable identity.

Trinity is pre-production. Tape-out target is 2026-12-16 (TTSKY26b silicon submitted; TTSKY26c scheduled Sep-Nov 2026). All performance figures are projected (~1 GOPS @ ~50 MHz @ ~1 W ternary per die, pending silicon). First-mover advantage in Trust Hardware is available for 12-18 months before any well-resourced competitor can respond.

Contact: admin@t27.ai. Research DOI: 10.5281/zenodo.19227877.

**Trinity is one computer with three minds, bound by 2-of-3 attestation, verified by ternary completeness 3^27.**

---

## 2. Audience: DARPA / Defense

### Tagline

**"Radiation-tolerant edge inference with silicon-level attestation — no software trust assumptions."**

### Pitch (English)

Modern edge AI deployments in contested environments require three properties that current COTS silicon does not provide simultaneously: (1) fault tolerance under ionizing radiation, (2) tamper-evident identity that cannot be spoofed by an adversary with network access, and (3) cryptographic proof that the compute result was not modified in transit or at rest.

Trinity addresses all three by construction. The Triple Modular Redundancy (TMR) voter is built into the tri-ring fabric: every safety-critical operation runs on all three dies (Phi, Euler, Gamma) in parallel, with a 2-of-3 majority vote at a dedicated voter cell (see [TMR_DEFENSE_GRADE.md](../architecture/TMR_DEFENSE_GRADE.md)). TMR is free in topology because Trinity already comprises three peer dies — no additional packaging, no board-level redundancy required.

The PUF-derived identity (Phi die, Lucas POST, 0x47C0 anchor) provides tamper-evident hardware authentication that does not depend on a software keystore. An adversary who captures a Trinity node and modifies its firmware cannot forge the PUF response. The ZK proof chain (Euler, GKR sumcheck) provides non-repudiable proof of compute provenance, verifiable on-chain without trusting the hardware operator.

The Trinity Datacenter SKU ($39,999, 27 Triads in a `3^3` arrangement) is the appropriate unit for forward-operating-base deployment. Defense-tier support contract available ($4,999 / unit / year): includes SLA, air-gap deployment support, and TMR audit reports.

RTL is Apache-2.0 (enables ITAR-clean review and modification). Silicon is IHP SG13G2 (130nm BiCMOS), not subject to advanced-node export controls. Second-source fabrication (IHP26b) planned Q1 2027 for supply chain resilience.

BAA submissions in progress. See [DARPA_I2O_BAA_PROPOSAL.md](../sales/DARPA_I2O_BAA_PROPOSAL.md) and [DEFENCE_CONTRACTOR_PITCH.md](../sales/DEFENCE_CONTRACTOR_PITCH.md) for full technical proposals.

Tape-out target 2026-12-16. Performance: ~1 GOPS @ ~50 MHz @ ~1 W ternary per die (projected, pending silicon). Full Datacenter: ~81 GOPS aggregate at ~40 W (projected under DVFS coordination).

Contact: admin@t27.ai.

**Trinity is one computer with three minds, bound by 2-of-3 attestation, verified by ternary completeness 3^27.**

---

## 3. Audience: Bittensor Community

### Tagline

**"The first hardware validator that proves its inference in silicon, not software."**

### Pitch (English)

Bittensor's validator model is economically sophisticated and technically open. Its one structural gap is attestation: a validator's hardware identity is established by software keys, not by physical silicon. Any party with the right software can simulate a validator. This creates a soft ceiling on the trust level that subnet operators can achieve.

Trinity is designed to close that gap. A Trinity Triad running as a Bittensor validator node is not just another Linux process with a key. It is a hardware computer whose identity traces to a Physical Unclonable Function, whose compute outputs are accompanied by ZK proofs (Euler GKR sumcheck), and whose attestation requires 2-of-3 agreement across three dies. The on-chain `BittensorSubnetAttest.sol` contract verifies this attestation before crediting mining rewards.

For Bittensor miners, the economics are direct: a Triad miner earns 4× TRI per attestation cycle vs a Solo miner, enforced on-chain and not configurable in software. A Cluster (3 Triads) earns 12×. The mining boost is hardware-enforced — you cannot earn it without the physical Trinity Computer.

For subnet operators (SN3, SN39, SN81 are primary targets for Q4 2026 outreach), Trinity validators offer a new trust tier: hardware-attested inference that can be required by subnet governance as a condition of participation. This differentiates high-trust subnets from commodity compute subnets.

Trinity is pre-production. Dev kits from TTSKY26b are projected Q1 2027. Testnet is targeted Q3 2026 (software simulation layer). RTL is Apache-2.0 — subnet developers can inspect and audit the silicon design.

Total TRI supply: `3^27 = 7,625,597,484,987`. 0% pre-mine, 0% team allocation, 100% mineable. Era 0: 1000 TRI per chip ZK proof. 9 halvings every 4 years — the same halving model that made Bitcoin mining economically legible.

Contact: admin@t27.ai. Discord and forum participation at [t27.ai].

**Trinity is one computer with three minds, bound by 2-of-3 attestation, verified by ternary completeness 3^27.**

---

## 4. Audience: DePIN Ecosystem (Helium-Style)

### Tagline

**"Hardware-native DePIN nodes with unforgeable geographic identity — the Helium model, with silicon-level trust."**

### Pitch (English)

Helium demonstrated that physical hardware nodes with location-verified identities can bootstrap a decentralized network with powerful token incentives. The structural weakness of the Helium model (and all software-layer DePIN networks) is identity: a Helium miner's location is verified by radio propagation math, not by the hardware itself. An adversary with enough software skill can simulate multiple virtual miners at one physical location.

Trinity takes the Helium incentive model and roots it in silicon. Each Trinity node has a PUF-derived identity that is physically bound to a specific die, fabricated once, and impossible to duplicate. The 0x47C0 anchor and Lucas POST verify the identity on every power-on. Geographic deployment of Trinity nodes creates a network of verified compute points whose identities cannot be Sybil-attacked through software.

The DePIN coverage incentive model maps naturally to the Trinity SKU ladder:

- Solo ($99): minimum viable node for IoT coverage areas. Mined at 1× rate.
- Duo ($499): DePIN node with ZK proof capability. Mined at 2×.
- Triad ($1,499): full-capability DePIN node with hardware-attested inference. Mined at 4×.

The network fee burn mechanism (a percentage of TRI inference fees burned) creates the scarcity dynamic that rewards early geographic coverage before the network saturates — the same dynamic that rewarded early Helium miners.

Mainnet is targeted H2 2027 (see [GTM_FOUR_WEDGES.md](./GTM_FOUR_WEDGES.md), Wedge 3). Testnet Q3 2026. TTSKY26b silicon returns Q4 2026 (projected). Full integration proposal at [HELIUM_INTEGRATION_PROPOSAL.md](../sales/HELIUM_INTEGRATION_PROPOSAL.md).

Contact: admin@t27.ai.

**Trinity is one computer with three minds, bound by 2-of-3 attestation, verified by ternary completeness 3^27.**

---

## 5. Audience: AI Researchers (Verifiable Inference)

### Tagline

**"The first open-silicon platform for cryptographically verifiable AI inference."**

### Pitch (English)

The reproducibility crisis in machine learning is well-documented: results reported in papers are frequently unreproducible due to undocumented hardware, software version drift, and hyperparameter ambiguity. A deeper and less discussed problem is compute provenance: there is currently no general mechanism for proving that a specific AI inference ran on specific hardware, at a specific time, and produced a specific output — without trusting the hardware operator.

Trinity addresses this by combining three components into a single open hardware platform:

1. **Euler die (8×2, ZK Job Prover, GKR sumcheck):** Produces a zero-knowledge proof for every AI inference that can be verified on-chain. The proof certifies the computation without revealing intermediate state.

2. **Phi die (1×1, PUF, 0x47C0 anchor):** Provides the hardware identity of the device that ran the inference. The PUF response is physically unforgeable; the `0x47C0` anchor is verified at boot via Lucas POST (Theorem 36.1).

3. **Gamma die (8×4, mesh, storage proof):** Stores the inference result with a storage proof that the output has not been modified.

Together, these three organs of one Trinity Computer produce what no existing platform produces: a cryptographic receipt that a specific AI computation ran on specific hardware, verifiable without trusting the operator, anchored to a physically unforgeable identity.

Applications for AI researchers:

- **Reproducibility:** Publish the on-chain ZK proof alongside the paper. Any verifier can check the proof without re-running the experiment.
- **Federated learning with honest compute:** Participants in a federated learning protocol can prove that their local training ran on certified hardware.
- **Verifiable inference APIs:** Build inference services where clients receive a hardware-attested ZK receipt alongside every API response.

Performance is modest and honest: ~1 GOPS @ ~50 MHz @ ~1 W ternary per die (projected, pending tape-out 2026-12-16). This is appropriate for edge inference of smaller models; it is not appropriate for large-scale training. The value proposition is verifiability, not raw throughput.

RTL is Apache-2.0. Academic researchers can inspect, modify, and extend the design. Research DOI: 10.5281/zenodo.19227877.

Contact: admin@t27.ai.

**Trinity is one computer with three minds, bound by 2-of-3 attestation, verified by ternary completeness 3^27.**

---

## 6. Audience: Retail Miners

### Tagline (English)

**"Mine TRI from day one. No pre-mine. No VC advantage. Pure hardware proof-of-work."**

### Pitch (English)

Trinity's token launch is structured the same way Bitcoin's was: no pre-mine, no founder allocation, no venture capital tokens. `3^27 = 7,625,597,484,987 TRI` total supply. 100% mineable. Era 0: 1000 TRI per chip ZK proof. 9 halvings every 4 years.

The first miners to run Trinity hardware have no disadvantage relative to any other participant, including the project founders. There is no early-investor tranche, no locked-up VC supply that will unlock and dilute later.

How to mine:

1. Purchase a Trinity Triad ($1,499) — the flagship SKU that delivers the full one-computer experience.
2. Run the TrinityNode validator daemon (open source, available at the t27.ai repository).
3. Submit chip ZK proofs to the network. Each accepted proof earns TRI at the Era 0 rate.
4. The 4× mining boost applies to Triad holders. A Cluster (3 Triads) earns 12×.

Dev kits are projected from TTSKY26b silicon returns (Q4 2026, subject to tape-out 2026-12-16). Early participants can follow development on the open RTL repository and contribute to testing.

Hardware is not rental; you own it. No cloud contract, no KYC required to mine. The hardware identity (PUF-derived, physically unforgeable) is generated at your first power-on — nobody can clone your miner.

Three networks at mainnet: Base L2, Bittensor EVM, Solana SPL. Mine on the network of your choice or all three.

Contact: admin@t27.ai.

---

### Retail Miner Pitch (Russian)

**Тэглайн:** "Майни TRI с первого дня. Без пре-майна. Без VC-привилегий. Чистый аппаратный Proof-of-Work."

**Питч:**

Trinity запускает токен TRI так же, как в своё время запускался Bitcoin: без пре-майна, без аллокации основателям, без венчурных токенов. Общий выпуск: `3^27 = 7 625 597 484 987 TRI`. 100% добывается майнерами. Эпоха 0: 1000 TRI за один чип ZK-доказательство. 9 халвингов каждые 4 года.

Первые майнеры Trinity не имеют никакого преимущества перед более поздними участниками — включая основателей проекта. Нет VC-токенов, которые разлокируются через год и размывают вашу долю.

**Как майнить:**

1. Купи Trinity Triad ($1 499) — флагманская конфигурация, которая собирает полноценный единый компьютер.
2. Запусти TrinityNode (открытый исходный код, репозиторий на t27.ai).
3. Отправляй ZK-доказательства в сеть. Каждое принятое доказательство приносит TRI по ставке Эпохи 0.
4. Бонус 4× за Triad действует на уровне смарт-контракта — не конфигурируется программно.

Dev-kit из TTSKY26b ожидается Q4 2026 (при успешном тейп-ауте 2026-12-16). Следи за разработкой в открытом RTL-репозитории, участвуй в тестировании.

Оборудование твоё — ты его не арендуешь. KYC не требуется для майнинга. Аппаратная идентичность (PUF, физически неклонируемая) генерируется при первом включении — никто не может скопировать твой майнер.

Три сети в mainnet: Base L2, Bittensor EVM, Solana SPL.

Контакт: admin@t27.ai.

**Trinity — это один компьютер с тремя разумами, связанными 2-of-3 аттестацией, верифицированный тернарной полнотой 3^27.**

---

## 7. Positioning Summary Matrix

| Audience              | Primary Pain                              | Trinity's Answer                          | Key Credential              |
|-----------------------|-------------------------------------------|-------------------------------------------|-----------------------------|
| Venture Capital       | Missing category in trust compute         | Trust Hardware category creation          | DOI + Apache-2.0 + fair launch |
| DARPA / Defense       | No TMR silicon + no tamper-evident identity | Tri-ring TMR + PUF + ZK provenance       | TMR_DEFENSE_GRADE.md + DARPA BAA |
| Bittensor Community   | Software-only validator identity          | Hardware-attested validator node          | BITTENSOR_PITCH.md + 4× boost |
| DePIN Ecosystem       | Sybil-vulnerable hardware nodes           | PUF-grounded unforgeable node identity    | HELIUM_INTEGRATION_PROPOSAL.md |
| AI Researchers        | No compute provenance standard            | ZK receipt per inference, open RTL        | DOI 10.5281/zenodo.19227877 |
| Retail Miners         | VC-diluted, pre-mined competitors         | 0% pre-mine, hardware Proof-of-Work       | `3^27` supply constant      |

---

*Apache-2.0. Sole author: Dmitrii Vasilev <admin@t27.ai>.*
