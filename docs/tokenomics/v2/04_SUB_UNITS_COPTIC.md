# 04 — TRI Sub-Units: Coptic-Named Denominations

**Author:** Dmitrii Vasilev <admin@t27.ai>  
**Document:** Tokenomics Series — Part 04  
**Status:** Draft v1.0  
**Last Updated:** 2025

---

## Table of Contents

1. [Why Sub-Units Matter](#1-why-sub-units-matter)
2. [Full Prefix Table](#2-full-prefix-table)
3. [Use-Case Mapping per Sub-Unit](#3-use-case-mapping-per-sub-unit)
4. [Wallet UI Suggestions](#4-wallet-ui-suggestions)
5. [ERC-20 Implementation Note](#5-erc-20-implementation-note)
6. [Connection to Chip Architecture: B-Module Mapping](#6-connection-to-chip-architecture-b-module-mapping)
7. [Cultural and Aesthetic Justification](#7-cultural-and-aesthetic-justification)
8. [Conversion Table Examples](#8-conversion-table-examples)
9. [Marketing Copy](#9-marketing-copy)

---

## 1. Why Sub-Units Matter

### 1.1 The Bitcoin Satoshi Parallel

When Bitcoin was first conceived, its designers made a foundational engineering choice: one BTC is divisible into 100,000,000 satoshis (10⁻⁸ BTC). This decision, seemingly trivial at launch when BTC was worth fractions of a cent, became critically important once the coin's value grew by orders of magnitude. A cup of coffee that once cost 0.01 BTC now requires a transaction denominated in thousands of satoshis. The satoshi denomination preserved Bitcoin's usability as a medium of exchange even as its store-of-value properties pushed the base-unit price into ranges impractical for everyday transactions.

TRI faces an analogous design requirement — but more acute in its urgency. Bitcoin's primary utility was peer-to-peer value transfer between humans. TRI's primary utility is machine-to-machine micropayment within AI inference pipelines, distributed compute networks, and IoT sensor meshes. In these contexts, a transaction may represent the cost of:

- Computing a single attention head in a transformer layer.
- Transmitting one kilobyte of compressed sensor data.
- Issuing a cryptographic commitment for a single proof step.
- Fetching a cached embedding vector from a distributed store.

These operations routinely cost fractions of a billionth of a TRI. Without a named sub-unit system, developers, auditors, and users face unwieldy scientific-notation amounts in logs and interfaces: `0.000000000000004 TRI`. This is hostile to human reasoning, prone to off-by-one errors in decimal counting, and practically unusable in user-facing copy.

The sub-unit naming convention resolves this by giving each power-of-1000 step in TRI's 18-decimal range a distinct, pronounceable, semantically meaningful name.

### 1.2 The Micro-Transaction Usability Problem

AI inference workloads generate payment events at rates that have no precedent in human-centric financial systems. A single inference request to a large language model may itself be decomposed into hundreds of sub-tasks — tokenization, embedding lookup, attention computation across multiple layers, sampling — each potentially billed to a different provider node in a decentralized inference network. A user who purchases "one inference" from the network's perspective is actually settling dozens of micro-payments in a single atomic transaction.

For this to work cleanly, the unit of account must be fine-grained enough that:

1. No individual micro-payment rounds to zero.
2. Aggregated micro-payments sum to the correct user-visible total without cumulative rounding error.
3. Developers reading logs can immediately parse the magnitude of a payment without mental arithmetic.

TRI's 18-decimal precision (matching Ethereum's wei/ether convention) satisfies condition (1) and (2) at the smart-contract level. The Coptic-prefixed sub-unit naming system satisfies condition (3) at the human interface level.

### 1.3 Naming as Engineering Infrastructure

A sub-unit name is not merely cosmetic. It functions as a shared coordinate in the space of magnitudes. When an engineer writes:

```
fee = 5 beta-TRI
```

every reader immediately knows the fee is in the micro-range (10⁻⁶ TRI). When a billing dashboard displays:

```
Monthly inference spend: 3.7 alpha-TRI
```

the user understands they are spending in the milli-range and can compare across billing cycles without converting. This cognitive load reduction is itself an economic good — it reduces the probability of mis-specified fees, under-priced API calls, and audit errors.

### 1.4 Precedent Across the Ecosystem

Sub-unit naming is standard practice in mature blockchain ecosystems:

| Blockchain | Base Unit | Smallest Unit | Naming |
|------------|-----------|---------------|--------|
| Ethereum   | ETH       | wei           | wei / gwei / szabo / finney |
| Bitcoin    | BTC       | satoshi       | satoshi / bit / mBTC |
| Solana     | SOL       | lamport       | lamport (named after Leslie Lamport) |
| Cardano    | ADA       | lovelace      | lovelace (named after Ada Lovelace) |
| **TRI**    | **TRI**   | **zeta-TRI**  | **Coptic/Greek alphabetic series** |

TRI's naming scheme differs from predecessors in one key respect: rather than selecting arbitrary honorifics, the names are drawn from a single alphabetic sequence — the Greek/Coptic letter series — giving the full denomination table a mnemonic structure. A developer need only learn that denominations descend alphabetically from alpha (milli) through zeta (atto/wei) to know the rough ordering of any TRI sub-unit they encounter.

---

## 2. Full Prefix Table

### 2.1 Master Denomination Table

The following table defines all seven named denominations of TRI. The base unit (TRI itself) occupies the 10⁰ position. Each subsequent sub-unit represents a 1000× reduction, following SI prefix conventions at the pico (10⁻¹²), femto (10⁻¹⁵), and atto (10⁻¹⁸) ranges. The naming series uses the first six letters of the Greek/Coptic alphabet as prefixes to TRI.

| Denomination  | Symbol   | Power of TRI | Decimal Value (TRI) | SI Equivalent | Indivisible Units (zeta-TRI) |
|---------------|----------|--------------|----------------------|---------------|-------------------------------|
| TRI           | TRI      | 10⁰          | 1.000000000000000000 | —             | 10¹⁸                          |
| alpha-TRI     | αTRI     | 10⁻³         | 0.001000000000000000 | milli         | 10¹⁵                          |
| beta-TRI      | βTRI     | 10⁻⁶         | 0.000001000000000000 | micro         | 10¹²                          |
| gamma-TRI     | γTRI     | 10⁻⁹         | 0.000000001000000000 | nano          | 10⁹                           |
| delta-TRI     | δTRI     | 10⁻¹²        | 0.000000000001000000 | pico          | 10⁶                           |
| epsilon-TRI   | εTRI     | 10⁻¹⁵        | 0.000000000000001000 | femto         | 10³                           |
| zeta-TRI      | ζTRI     | 10⁻¹⁸        | 0.000000000000000001 | atto          | 1 (atomic unit)               |

### 2.2 Denomination Definitions

#### TRI — Base Unit (10⁰)

The base TRI is the human-scale unit of account. It is used for:

- Staking and governance (amounts expressed in whole TRI).
- Large commercial transactions (enterprise API subscriptions, node operator bonds).
- Exchange-listed trading pairs (TRI/USDC, TRI/ETH).
- Treasury management and protocol revenue reporting.

**One TRI** represents a meaningful quantity of compute or AI service value. At target network pricing, 1 TRI is expected to represent approximately one full LLM inference session of moderate length, or one hour of shared GPU rental at consumer-tier pricing.

#### alpha-TRI — Milli Denomination (10⁻³)

The alpha-TRI (αTRI) is the **milli-TRI**, equivalent to one thousandth of a base TRI. The Greek letter alpha (α) is the first letter of both the Greek and Coptic alphabets, symbolizing the first step below the base unit — the threshold at which transactions become granular enough for individual AI API calls.

**One alpha-TRI** is the natural unit for:

- Single AI inference requests (one prompt/response cycle with a small model).
- Per-request API billing in developer-tier integrations.
- Small retail payments for AI-assisted services.

#### beta-TRI — Micro Denomination (10⁻⁶)

The beta-TRI (βTRI) is the **micro-TRI**, equivalent to one millionth of a base TRI. Beta (β) is the second letter of the Greek alphabet. At this scale, individual LLM token computations become individually priceable.

**One beta-TRI** is the natural unit for:

- Per-token billing in large language model inference.
- Per-query vector database lookups.
- Short computation tasks: embedding a single sentence, running a classifier on one document.

The beta-TRI is expected to be the most commonly encountered sub-unit in developer tooling, SDK logs, and API billing dashboards.

#### gamma-TRI — Nano Denomination (10⁻⁹)

The gamma-TRI (γTRI) is the **nano-TRI**, equivalent to one billionth of a base TRI. Gamma (γ) is the third letter of the Greek alphabet, and in physics commonly denotes electromagnetic radiation — fitting for a denomination associated with high-frequency, high-throughput data transmission.

**One gamma-TRI** is the natural unit for:

- Per-byte bandwidth payments in decentralized storage and CDN networks.
- Per-packet routing fees in decentralized network infrastructure.
- Real-time streaming data subscriptions (audio, video, sensor feeds).

#### delta-TRI — Pico Denomination (10⁻¹²)

The delta-TRI (δTRI) is the **pico-TRI**, equivalent to one trillionth of a base TRI. Delta (δ) in mathematics denotes an infinitesimally small change — apt for the minute incremental costs of IoT sensor operations.

**One delta-TRI** is the natural unit for:

- IoT sensor reading submissions (temperature, pressure, location ping).
- Per-event micropayments in edge computing networks.
- Single function invocations in serverless distributed compute.

#### epsilon-TRI — Femto Denomination (10⁻¹⁵)

The epsilon-TRI (εTRI) is the **femto-TRI**, equivalent to one quadrillionth of a base TRI. Epsilon (ε) in mathematics denotes an arbitrarily small positive quantity, and in physics is associated with permittivity — fitting for atomic-scale computational operations.

**One epsilon-TRI** is the natural unit for:

- Individual cryptographic hash computations.
- Single ZK proof step verifications.
- Atomic cache operations in distributed memory systems.

This denomination is rarely encountered in user-facing contexts but is important for protocol-level fee accounting where millions of atomic operations are aggregated before settlement.

#### zeta-TRI — Atto Denomination / Wei Equivalent (10⁻¹⁸)

The zeta-TRI (ζTRI) is the **smallest indivisible unit of TRI**. It is analogous to the wei in Ethereum's denomination system and to the satoshi in Bitcoin's. Zeta (ζ) is the sixth letter of the Greek alphabet and in physics denotes the Riemann zeta function — a symbol of infinite series and fundamental mathematical structure, reflecting the foundational nature of this atomic unit.

**The zeta-TRI cannot be subdivided.** All on-chain balances and transaction amounts are ultimately expressed as integer multiples of zeta-TRI. All other denominations are display conventions layered on top of this integer representation.

The zeta-TRI is used by:

- Smart contract developers reading raw `uint256` balances.
- Protocol engineers designing fee arithmetic.
- Auditors verifying exact on-chain amounts.

---

## 3. Use-Case Mapping per Sub-Unit

### 3.1 Overview

Each sub-unit inhabits a distinct operational regime within the TRI ecosystem. The following mapping connects each denomination to the economic layer it primarily serves.

### 3.2 TRI (Base Unit) — Governance and Staking Layer

The base TRI is the unit of the **governance economy**: staking, validator bonding, protocol fee collection, treasury disbursements, and exchange-listed liquidity. It is human-readable, exchange-priced, and subject to the same price discovery mechanisms as any major cryptocurrency.

Typical transactions:
- Node operator posts a 10,000 TRI validator bond.
- DAO treasury allocates 50,000 TRI to a development grant.
- User purchases a 12-month enterprise API subscription for 1,200 TRI.
- Liquidity provider deposits 500 TRI into a TRI/USDC pool.

### 3.3 alpha-TRI — Consumer AI Services Layer

The alpha-TRI is the unit of the **consumer AI economy**: retail-facing AI applications, per-session billing, and developer sandbox quotas.

Typical transactions:
- User runs one image generation: 2.5 alpha-TRI.
- Developer tests an API integration: monthly allowance of 100 alpha-TRI.
- AI-powered document summarization service charges 0.8 alpha-TRI per document.
- Subscription to an AI assistant: 300 alpha-TRI/month.

### 3.4 beta-TRI — LLM Token Economy Layer

The beta-TRI is the unit of the **token economy**: the granular per-token billing layer where inference costs are measured and settled at the level of individual model computations.

Typical transactions:
- 1,000-token LLM prompt costs 1 beta-TRI.
- Embedding a 512-dimensional vector: 0.2 beta-TRI.
- RAG pipeline lookup (retrieve + rerank): 3 beta-TRI.
- Fine-tuning one gradient step on a small model: 50 beta-TRI.

The beta-TRI economy is projected to account for the majority of transaction volume on the TRI network by count (number of settlement events), even if TRI and alpha-TRI dominate by total value transferred.

### 3.5 gamma-TRI — Network Infrastructure Layer

The gamma-TRI is the unit of the **network economy**: bandwidth, routing, CDN, and decentralized storage operations.

Typical transactions:
- Transfer 1 KB of inference payload across the P2P network: 5 gamma-TRI.
- Store 1 MB of model weights in decentralized storage for 1 hour: 10 gamma-TRI.
- Stream a real-time sensor feed for 1 second: 2 gamma-TRI.
- Route a gossip protocol message through 3 relay nodes: 1 gamma-TRI.

### 3.6 delta-TRI — Edge and IoT Layer

The delta-TRI is the unit of the **edge economy**: IoT devices, embedded sensors, and edge inference nodes that operate at extremely low per-event costs.

Typical transactions:
- Submit one GPS location reading: 1 delta-TRI.
- Register one heartbeat from a health-monitoring wearable: 0.5 delta-TRI.
- Submit one temperature reading from a smart building sensor: 2 delta-TRI.
- Execute one function call in a serverless edge compute environment: 5 delta-TRI.

### 3.7 epsilon-TRI — ZK Proof and Cryptographic Layer

The epsilon-TRI is the unit of the **proof economy**: the cost of individual cryptographic operations within the TRI proof system, particularly within the B-module architecture.

Typical transactions:
- Verify one hash preimage in a proof circuit: 1 epsilon-TRI.
- Commit one Merkle tree leaf: 2 epsilon-TRI.
- Execute one constraint in a ZK-SNARK circuit: 0.3 epsilon-TRI.

In practice, epsilon-TRI costs are aggregated across thousands of operations before any settlement occurs. A user submitting a ZK proof to the network pays a fee in beta-TRI or gamma-TRI that represents the summed epsilon-TRI costs of all underlying cryptographic operations.

### 3.8 zeta-TRI — Protocol and Audit Layer

The zeta-TRI is not a transaction denomination in the economic sense — it is a **precision layer** used exclusively by protocol software and auditors. No user-facing interface should present balances in zeta-TRI except in technical debugging modes.

Its importance is structural: every other denomination is a human-readable shorthand for an exact integer count of zeta-TRI. Contract arithmetic is always performed in zeta-TRI to prevent rounding errors.

---

## 4. Wallet UI Suggestions

### 4.1 Auto-Display Philosophy

A wallet displaying TRI balances faces a UX design challenge: the same underlying integer balance (expressed in zeta-TRI) might most naturally be expressed in very different denominations depending on context and magnitude. Displaying 0.000000425 TRI is less readable than displaying 425 beta-TRI, but displaying 0.5 TRI is more readable than displaying 500 alpha-TRI.

The guiding principle for wallet UI design should be:

> **Always display the balance in the highest denomination where the displayed number is between 1 and 999.**

This mirrors how humans naturally express physical measurements: 500 millilitres rather than 0.5 litres and 500,000 microlitres.

### 4.2 Auto-Display Algorithm

```
function selectDisplayUnit(zeta_amount: BigInt) -> (value: Decimal, unit: string):
    thresholds = [
        (10^18, "TRI"),
        (10^15, "alpha-TRI"),
        (10^12, "beta-TRI"),
        (10^9,  "gamma-TRI"),
        (10^6,  "delta-TRI"),
        (10^3,  "epsilon-TRI"),
        (1,     "zeta-TRI"),
    ]
    for (threshold, name) in thresholds:
        if zeta_amount >= threshold:
            return (zeta_amount / threshold, name)
    return (zeta_amount, "zeta-TRI")
```

Under this algorithm:

| zeta-TRI Amount | Display Output          |
|-----------------|-------------------------|
| 4,250,000,000,000 | 4.25 beta-TRI          |
| 500,000,000,000,000 | 500 alpha-TRI        |
| 1,000,000,000,000,000,000 | 1 TRI           |
| 750,000           | 750 epsilon-TRI         |
| 42                | 42 zeta-TRI             |

### 4.3 Context-Aware Display

Wallets should also adapt display units to the transaction context:

- **Governance interface:** Always display in TRI regardless of amount (users expect whole-number stakes).
- **Developer console:** Always display in beta-TRI with full precision (engineers need exact token counts).
- **IoT dashboard:** Always display in delta-TRI (sensor operators think in per-reading costs).
- **Network metrics panel:** Display in gamma-TRI (bandwidth costs are naturally expressed per kilobyte).

### 4.4 Multi-Unit Transaction Summary

For transactions that aggregate costs across multiple operational layers, wallets should provide an expandable breakdown:

```
Total transaction cost: 3.2 alpha-TRI
  ├── Inference fee:      2.4 alpha-TRI  (750 beta-TRI)
  ├── Network fee:        0.7 alpha-TRI  (700,000 gamma-TRI)
  └── Proof verification: 0.1 alpha-TRI  (100,000,000 epsilon-TRI)
```

The top-level summary uses the most natural denomination for the total; the breakdown provides additional context in each layer's native unit.

### 4.5 Symbol Rendering

Wallet UIs should support both ASCII and Unicode symbol rendering:

| Denomination  | Full Name    | ASCII Symbol | Unicode Symbol |
|---------------|--------------|--------------|----------------|
| TRI           | TRI          | TRI          | TRI            |
| alpha-TRI     | alpha-TRI    | aTRI         | αTRI           |
| beta-TRI      | beta-TRI     | bTRI         | βTRI           |
| gamma-TRI     | gamma-TRI    | gTRI         | γTRI           |
| delta-TRI     | delta-TRI    | dTRI         | δTRI           |
| epsilon-TRI   | epsilon-TRI  | eTRI         | εTRI           |
| zeta-TRI      | zeta-TRI     | zTRI         | ζTRI           |

---

## 5. ERC-20 Implementation Note

### 5.1 Sub-Units Are Display-Only

A critical architectural point: **sub-units are entirely display-layer conventions. The TRI smart contract has no knowledge of alpha-TRI, beta-TRI, or any other named denomination.** The contract operates exclusively in its internal integer representation, which corresponds to what is here called zeta-TRI.

This is identical to how Ethereum's ERC-20 standard handles decimals. The `IERC20` interface and its standard implementations (`ERC20.sol` in OpenZeppelin) store all balances as `uint256` integers. The `decimals()` function returns a `uint8` value (conventionally 18 for most tokens) that is purely advisory — it tells off-chain software how to interpret the raw integer when displaying a human-readable balance.

### 5.2 Contract Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TRI is ERC20 {
    // decimals() returns 18 by default in OpenZeppelin ERC20
    // This means 1 TRI (human-readable) = 1 * 10^18 internal units
    // Internal units = zeta-TRI in the naming convention
    
    constructor(uint256 initialSupply) ERC20("Trinity Intelligence", "TRI") {
        // initialSupply should be expressed in zeta-TRI (raw units)
        // Example: 1,000,000 TRI = 1_000_000 * 10**18 zeta-TRI
        _mint(msg.sender, initialSupply);
    }
    
    // No sub-unit logic needed here — all denomination handling
    // is performed by wallets, SDKs, and frontends off-chain.
}
```

### 5.3 Off-Chain SDK Denomination Handling

The TRI SDK provides helper utilities for denomination conversion:

```typescript
import { TRI } from "@t27/tri-sdk";

// Convert from human-readable to raw (zeta-TRI)
const rawAmount = TRI.toZeta("3.7", "alpha");  // Returns BigInt
// rawAmount = 3_700_000_000_000_000n  (3.7 * 10^15)

// Convert from raw to human-readable
const display = TRI.fromZeta(rawAmount, "beta");  // Returns string
// display = "3700000 beta-TRI"

// Auto-select best denomination
const autoDisplay = TRI.autoDisplay(rawAmount);
// autoDisplay = "3.7 alpha-TRI"
```

### 5.4 Precision and Rounding Rules

Because all contract arithmetic operates in integer zeta-TRI:

- **Addition and subtraction** are exact (no rounding).
- **Multiplication** (e.g., computing fees as a percentage of a transfer) may produce results that must be rounded to the nearest zeta-TRI. The protocol mandates **floor rounding** (truncation) for fee calculations to prevent fee over-charging.
- **Division** (e.g., splitting a payment among multiple nodes) must be implemented with explicit remainder handling. The contract distributes remainders to the first eligible recipient or burns them, depending on context.

No rounding is performed at the display layer — denomination conversion is exact because each denomination is an exact power of 10³ relative to zeta-TRI.

---

## 6. Connection to Chip Architecture: B-Module Mapping

### 6.1 Overview

The TRI denomination hierarchy maps structurally to the B-module (proof module) architecture of the Trinity chip design. Each denomination tier corresponds to a distinct proof type processed by a different computational layer within the B-module stack.

This is not an arbitrary correspondence. The B-module architecture was designed with the payment system in mind: the granularity of a proof type determines the natural economic unit at which the corresponding computation should be priced.

### 6.2 B-Module Layer to Denomination Mapping

| B-Module Layer | Proof Type                  | Associated Denomination | Economic Rationale |
|----------------|-----------------------------|-------------------------|--------------------|
| B0 — Macro     | Aggregate state transition  | TRI (base)              | Full block proofs; priced at base-unit scale |
| B1 — Session   | Inference session proof     | alpha-TRI               | Per-session ZK attestation; milli-TRI range |
| B2 — Token     | Per-token computation proof | beta-TRI                | Per-LLM-token arithmetic; micro-TRI range |
| B3 — Packet    | Network packet proof        | gamma-TRI               | Per-packet routing attestation; nano-TRI range |
| B4 — Event     | Edge event proof            | delta-TRI               | Per-IoT event attestation; pico-TRI range |
| B5 — Atomic    | Single constraint proof     | epsilon-TRI             | Single ZK constraint; femto-TRI range |
| B6 — Hash      | Hash preimage witness       | zeta-TRI                | Atomic hash step; atto-TRI range |

### 6.3 Proof Cost Aggregation

The B-module architecture processes proofs hierarchically. Lower-level proofs (B5, B6) are aggregated into higher-level proofs (B3, B4) before being submitted to the chain. This aggregation mirrors the denomination hierarchy: epsilon-TRI costs are summed within a gamma-TRI settlement; gamma-TRI costs are summed within an alpha-TRI invoice.

This design ensures that:

1. **On-chain storage is minimized:** Only aggregated proofs at the B0–B2 level are stored on-chain; lower-level proofs are ephemeral.
2. **Fee granularity is preserved:** Even though only the aggregate fee is settled on-chain, the fee calculation is traceable to individual epsilon-TRI and zeta-TRI costs for auditing.
3. **Scaling is natural:** As the network grows and individual operation costs decrease (due to more efficient proving algorithms), the denomination hierarchy absorbs the change — lower-cost operations migrate from epsilon-TRI pricing to zeta-TRI pricing without requiring changes to higher-level fee structures.

### 6.4 Hardware Alignment

Each Trinity chip contains dedicated silicon for each B-module layer. The denomination mapping means that the economic cost of a computation is directly proportional to the hardware resources it consumes:

- A B6 hash operation (one zeta-TRI) uses a single hash accelerator cycle.
- A B5 atomic constraint (one epsilon-TRI) uses a single constraint evaluation unit cycle.
- A B4 edge event proof (one delta-TRI) uses a full event aggregation pipeline.
- A B3 packet proof (one gamma-TRI) uses the packet processing subsystem.

This hardware-economic alignment prevents the incentive misalignment common in general-purpose blockchains, where the gas cost of an operation is a rough proxy for its computational cost but not a precise reflection of hardware resource consumption. In TRI, the mapping is direct by design.

---

## 7. Cultural and Aesthetic Justification

### 7.1 The Greek-Coptic Alphabet as Naming Foundation

The choice of Greek/Coptic letter names for TRI sub-units is deliberate and multi-layered. It is simultaneously a tribute to mathematical heritage, an alignment with the project's ternary-Pythagorean philosophical foundation, and a practical mnemonic device.

### 7.2 Pythagorean Mathematics and the Greek Tradition

The Pythagorean school of ancient Greece established the primacy of number in understanding the cosmos. The Pythagorean theorem, the discovery of irrational numbers, and the mystical significance attributed to the number three (the first odd prime, the first number that contains a beginning, middle, and end) are all part of a tradition that directly informs TRI's ternary mathematical architecture.

Using Greek letter names for TRI's sub-units is a deliberate invocation of this tradition. When a developer writes `5 beta-TRI`, they are using a notation whose alphabet was used by Euclid to write the *Elements*, by Pythagoras to describe harmonic ratios, and by Einstein to write field equations. The continuity is not merely aesthetic — it connects TRI's computational mathematics to the deep historical thread of abstract mathematical reasoning.

### 7.3 The Coptic Connection

Coptic is the final stage of the ancient Egyptian language, written in a modified Greek alphabet. It represents the convergence of two ancient intellectual traditions: Egyptian mathematics (which contributed early concepts in arithmetic, geometry, and algebra) and Greek philosophical mathematics. Coptic script was the liturgical and scholarly language of early Christian Egypt and remained in use in Coptic Orthodox services to the present day.

The inclusion of Coptic in the naming framework reflects:

- **Cultural synthesis:** TRI is a global protocol; its naming draws from the meeting point of African and European mathematical traditions.
- **Continuity:** Coptic's survival from ancient Egyptian through to the modern era parallels TRI's design philosophy of building systems with long-term architectural integrity.
- **Alphabetic completeness:** The Coptic alphabet extends the Greek alphabet with several letters derived from Demotic Egyptian script. The full Greek-Coptic sequence provides more than enough named letters to cover all denomination tiers, with room for future expansion.

### 7.4 Ternary Alignment

TRI's underlying chip architecture is ternary (base-3) rather than binary. The Greek and Coptic mathematical traditions have deep ternary resonances:

- The Pythagorean tetractys, the triangular arrangement of the first four integers, was considered sacred by the Pythagorean school and encodes the primacy of triangular number structures.
- The Trinity itself (the theological concept from which TRI takes its name) is a ternary structure — three in one.
- Greek philosophical triads (thesis-antithesis-synthesis, body-mind-spirit, past-present-future) are present throughout Hellenistic thought.

Naming the TRI denomination hierarchy with Greek letters grounds it in this ternary intellectual tradition. The sequence alpha through zeta (six letters for six sub-unit tiers below the base) mirrors the six-edge structure of a tetrahedron — the simplest three-dimensional solid and a shape deeply significant in Pythagorean geometry.

### 7.5 Aesthetics in Technical Communication

There is an underappreciated argument for investing in the aesthetics of technical naming. Systems that are named well are used better. The names must be:

- **Pronounceable:** All Greek letter names are well-known to any technically educated person globally.
- **Orderable:** The alphabetic sequence provides immediate intuition about relative magnitude.
- **Distinctive:** No two denominations share a similar sound, preventing confusion in verbal communication.
- **Culturally resonant:** The Greek tradition is associated with intellectual rigor, precision, and foundational mathematics — values that TRI seeks to embody.

Compare to the Ethereum naming scheme (wei, gwei, szabo, finney, ether): while evocative, these names do not convey magnitude ordering. A developer who knows "gwei" does not automatically know whether szabo is larger or smaller. TRI's alphabetic scheme resolves this: alpha > beta > gamma > delta > epsilon > zeta, always decreasing in magnitude.

---

## 8. Conversion Table Examples

### 8.1 Reference Conversion Table

| From \ To     | TRI         | α-TRI     | β-TRI      | γ-TRI       | δ-TRI        | ε-TRI         | ζ-TRI         |
|---------------|-------------|-----------|------------|-------------|--------------|---------------|----------------|
| **1 TRI**     | 1           | 10³       | 10⁶        | 10⁹         | 10¹²         | 10¹⁵          | 10¹⁸           |
| **1 α-TRI**   | 10⁻³        | 1         | 10³        | 10⁶         | 10⁹          | 10¹²          | 10¹⁵           |
| **1 β-TRI**   | 10⁻⁶        | 10⁻³      | 1          | 10³         | 10⁶          | 10⁹           | 10¹²           |
| **1 γ-TRI**   | 10⁻⁹        | 10⁻⁶      | 10⁻³       | 1           | 10³          | 10⁶           | 10⁹            |
| **1 δ-TRI**   | 10⁻¹²       | 10⁻⁹      | 10⁻⁶       | 10⁻³        | 1            | 10³           | 10⁶            |
| **1 ε-TRI**   | 10⁻¹⁵       | 10⁻¹²     | 10⁻⁹       | 10⁻⁶        | 10⁻³         | 1             | 10³            |
| **1 ζ-TRI**   | 10⁻¹⁸       | 10⁻¹⁵     | 10⁻¹²      | 10⁻⁹        | 10⁻⁶         | 10⁻³          | 1              |

### 8.2 Worked Conversion Examples

**Example 1:** A user has 0.0024 TRI. What is this in alpha-TRI?

```
0.0024 TRI × (1 alpha-TRI / 0.001 TRI) = 2.4 alpha-TRI
```

Display: **2.4 alpha-TRI** (preferred over 0.0024 TRI or 2,400 beta-TRI).

---

**Example 2:** An API call costs 350 beta-TRI. What is this in zeta-TRI?

```
350 beta-TRI × (10^12 zeta-TRI / 1 beta-TRI) = 350,000,000,000,000 zeta-TRI
= 3.5 × 10^14 zeta-TRI
```

On-chain storage: **350000000000000** (raw uint256 integer).

---

**Example 3:** A node operator earns 0.000000007 TRI per packet routed. Express in gamma-TRI.

```
0.000000007 TRI × (10^9 gamma-TRI / 1 TRI) = 7 gamma-TRI
```

Display: **7 gamma-TRI per packet** (far clearer than 7 × 10⁻⁹ TRI).

---

**Example 4:** Monthly inference costs for a power user: 4,200,000 beta-TRI. Express in alpha-TRI and TRI.

```
4,200,000 beta-TRI ÷ 1,000 = 4,200 alpha-TRI
4,200 alpha-TRI ÷ 1,000 = 4.2 TRI
```

Invoice line item: **4.2 TRI** (base unit appropriate for a monthly statement).

---

**Example 5:** An IoT device submits 50,000 sensor readings per day, each costing 2 delta-TRI. Daily cost?

```
50,000 × 2 delta-TRI = 100,000 delta-TRI
100,000 delta-TRI ÷ 1,000 = 100 epsilon-TRI
```

Daily device cost: **100 epsilon-TRI** (auto-display selects epsilon over delta because 100,000 > 999 delta but 100 fits cleanly in epsilon).

---

**Example 6:** A smart contract batch-settles 1,000,000 proof verifications, each costing 500 epsilon-TRI. Total fee?

```
1,000,000 × 500 epsilon-TRI = 500,000,000 epsilon-TRI
= 500,000 delta-TRI
= 500 gamma-TRI
= 0.5 beta-TRI
```

Settlement fee: **0.5 beta-TRI** (auto-display; 0.5 beta-TRI is cleaner than 500 gamma-TRI for a billing receipt).

---

### 8.3 Common Operation Reference Card

```
┌─────────────────────────────────────────────────────────────────────┐
│              TRI DENOMINATION QUICK REFERENCE                       │
│                                                                     │
│  1 TRI        = 10^18 zeta-TRI    Base unit / staking / exchange   │
│  1 alpha-TRI  = 10^15 zeta-TRI    AI inference session             │
│  1 beta-TRI   = 10^12 zeta-TRI    LLM per-token call               │
│  1 gamma-TRI  = 10^9  zeta-TRI    Per-byte network transfer         │
│  1 delta-TRI  = 10^6  zeta-TRI    IoT sensor event                 │
│  1 epsilon-TRI= 10^3  zeta-TRI    ZK proof constraint               │
│  1 zeta-TRI   = 1     zeta-TRI    Atomic indivisible unit           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 9. Marketing Copy

### 9.1 Headline Statements

---

**"AI inference for one beta-TRI."**

One beta-TRI — a millionth of a TRI — covers a full per-token LLM computation on the Trinity network. Not an estimate. Not a rounding. One exact, traceable, cryptographically attested unit of AI work. This is the promise of TRI: the smallest meaningful computation, priced to the smallest meaningful denomination.

---

**"Your IoT fleet, running on delta-TRI."**

A thousand sensors. A million daily readings. Each one settled for two delta-TRI — two trillionths of a TRI. The Trinity network makes machine-scale micropayments real: no minimum transaction threshold, no batching delay, no rounding to zero. Every reading, every device, every moment — accounted for.

---

**"From zeta to TRI: 18 decimal places of precision, seven names for clarity."**

TRI doesn't truncate. It doesn't round. It holds every computation to the atto scale — the same precision as Ethereum's wei, the same rigor as the ISO 80000 unit system. And it gives every magnitude a name, so developers, analysts, and users can always speak the same language: alpha, beta, gamma, delta, epsilon, zeta. Six letters. Six scales. One token.

---

### 9.2 Product Copy by Sub-Unit

#### TRI — Enterprise and Governance

> **Own your stake in the AI infrastructure layer.**  
> TRI is the governance token, the staking asset, and the settlement currency for the Trinity network. Whether you're running a validator node, funding a developer grant through the DAO, or taking a position on the future of decentralized AI — TRI is denominated at the scale that matters for institutions and power users. Stake in TRI. Earn in TRI. Govern in TRI.

---

#### alpha-TRI — Developer APIs

> **Build AI products without worrying about decimal math.**  
> The alpha-TRI is the developer unit: one thousandth of a TRI, priced at the scale of individual AI API calls. Integrate TRI payment rails into your app in an afternoon. Set per-user spending limits in alpha-TRI. Read per-call costs in alpha-TRI. Your billing dashboard will never show a number with more than three significant figures. We did the math so you don't have to.

---

#### beta-TRI — LLM Inference

> **Per-token billing, finally on-chain.**  
> The beta-TRI is the unit of the LLM economy. Every token your users generate is priced, attributed, and settled in beta-TRI — on-chain, auditable, and exact. No more opaque API credit systems. No more "you used X credits this month." With beta-TRI pricing, you see exactly what each token costs, which model generated it, and which node in the network processed it. AI billing, made transparent.

---

#### gamma-TRI — Decentralized Network

> **Pay for bytes, not bundles.**  
> Decentralized AI requires decentralized bandwidth. With gamma-TRI pricing on the Trinity network, you pay for exactly the data you transfer — per byte, per packet, per route. No subscription. No overage fee. Just a direct price signal for every bit of network capacity you consume. Infrastructure economics, made honest.

---

#### delta-TRI — IoT and Edge

> **Your sensor grid, on a budget measured in trillionths.**  
> The delta-TRI makes it economically viable to put every sensor, every actuator, every edge device on the payment network. At pico-TRI scale, the cost of one IoT reading is smaller than the cost of a single millisecond of human attention. That's not a limitation — it's a superpower. When everything can transact, everything can be governed by price signals. The edge economy starts here.

---

#### epsilon-TRI — ZK Proofs

> **Cryptographic truth, priced to the constraint.**  
> The epsilon-TRI is the unit of verifiable computation. Every constraint in a ZK circuit, every step in a proof chain, carries an epsilon-TRI cost — a direct reflection of the hardware resources consumed by the Trinity chip's B-module. When you pay for a verified computation on TRI, you're not paying for trust. You're paying for math. And math, it turns out, is very cheap.

---

#### zeta-TRI — Developers and Auditors

> **One. That's it. That's the unit.**  
> The zeta-TRI is the indivisible atom of the TRI economy. There is nothing smaller. Every balance on the TRI network, from a validator's 10,000 TRI bond to a single IoT sensor reading, is an exact integer count of zeta-TRI. No rounding. No approximation. If you're building on TRI, you build on zeta-TRI. Everything else is a display convention.

---

### 9.3 Social Media Taglines

```
One beta-TRI = one LLM token. Priced exact. Settled on-chain. No rounding.

alpha, beta, gamma, delta, epsilon, zeta — six scales, one token, infinite precision.

When your IoT fleet pays in delta-TRI, every sensor reading is an on-chain event. 
The edge economy is here.

TRI: 18 decimals of precision, seven Greek names for clarity, one ternary 
architecture underneath.

From the Pythagorean triad to the Trinity chip — the mathematics of three 
runs through everything we build.
```

### 9.4 Whitepaper Abstract Excerpt

> The TRI denomination system defines seven named units spanning 18 orders of magnitude, from the base TRI (10⁰) to the indivisible zeta-TRI (10⁻¹⁸). Each denomination tier is named using the Greek/Coptic alphabetic prefix series (alpha through zeta), providing a mnemonic ordering that maps directly to SI femto-to-milli prefixes. Sub-units are display-layer conventions over the ERC-20 standard's 18-decimal integer representation; no on-chain changes are required to implement the denomination system. Each denomination tier aligns with a distinct layer of the Trinity chip's B-module proof architecture, ensuring that the economic cost of a computation reflects its hardware resource consumption at every scale.

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| **TRI** | The base unit of the Trinity network's native token. Equal to 10¹⁸ zeta-TRI. |
| **alpha-TRI (αTRI)** | Milli-TRI. 10⁻³ TRI. 10¹⁵ zeta-TRI. Natural unit for per-session AI inference billing. |
| **beta-TRI (βTRI)** | Micro-TRI. 10⁻⁶ TRI. 10¹² zeta-TRI. Natural unit for per-token LLM billing. |
| **gamma-TRI (γTRI)** | Nano-TRI. 10⁻⁹ TRI. 10⁹ zeta-TRI. Natural unit for per-byte network billing. |
| **delta-TRI (δTRI)** | Pico-TRI. 10⁻¹² TRI. 10⁶ zeta-TRI. Natural unit for IoT event billing. |
| **epsilon-TRI (εTRI)** | Femto-TRI. 10⁻¹⁵ TRI. 10³ zeta-TRI. Natural unit for ZK proof constraint billing. |
| **zeta-TRI (ζTRI)** | Atto-TRI. 10⁻¹⁸ TRI. 1 zeta-TRI. Smallest indivisible unit; equivalent to Ethereum's wei. |
| **B-module** | The proof-processing hardware subsystem within the Trinity chip architecture. |
| **decimals()** | ERC-20 function returning the number of decimal places (18 for TRI); advisory only. |
| **floor rounding** | Truncation toward zero; used in TRI fee calculations to prevent over-charging. |

---

## Appendix B: Denomination Design Decisions — Not Taken

Two alternative naming schemes were evaluated and rejected during the TRI denomination design process.

### B.1 SI Prefix Names

Using standard SI prefix names (milli-TRI, micro-TRI, nano-TRI, etc.) was considered. This approach was rejected because:

1. The SI names do not convey ordering as clearly as alphabetic names — "nano" and "pico" are of similar length and sound, making verbal confusion possible.
2. SI names are borrowed from physics, not from any tradition with particular resonance to TRI's intellectual heritage.
3. The Greek/Coptic alphabet provides a natural extension path: if TRI ever required sub-zeta precision (unlikely given the 18-decimal standard), the Coptic extension of the alphabet provides additional letters beyond zeta.

### B.2 Named Honorific System

Using honorific names (e.g., naming denominations after mathematicians, physicists, or cryptographers) was considered, following the Ethereum precedent (szabo, finney, wei). This was rejected because:

1. Honorifics require knowledge of the honoree to understand the system — a developer who does not know who Szabo is cannot infer the magnitude of a "szabo." Greek letter names are universally recognized by technically educated audiences.
2. Honorifics are culturally asymmetric — honoring figures from specific national or cultural backgrounds would be a political statement. The Greek/Coptic tradition is broader and more universally shared.
3. Alphabetic ordering provides a built-in mnemonic (alpha is always larger than beta, beta larger than gamma, etc.) that honorific names cannot provide.

---

*Document ends.*

*Author: Dmitrii Vasilev <admin@t27.ai>*
