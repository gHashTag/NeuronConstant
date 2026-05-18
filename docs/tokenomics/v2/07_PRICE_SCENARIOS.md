# 07 — TRI Price Scenario Analysis

**Author:** Dmitrii Vasilev \<admin@t27.ai\>  
**Document:** Trinity Network Tokenomics Series · Chapter 07  
**Version:** 2.0  
**Status:** Working Draft

---

## ⚠️ MANDATORY DISCLAIMER — READ BEFORE PROCEEDING

> **THIS DOCUMENT DOES NOT CONSTITUTE INVESTMENT ADVICE.**
>
> TRI is a **utility token** designed to compensate operators of verifiable AI compute hardware
> within the Trinity Network. It is not a security, a share in any enterprise, a profit-sharing
> instrument, or a promise of financial return of any kind.
>
> **No guarantee of value.** TRI tokens may trade at zero. The price scenarios presented in this
> chapter are analytical constructs built to evaluate chip-miner unit economics under varying
> demand conditions. They are not price targets, forecasts, or solicitations to purchase TRI.
>
> **Regulatory status varies by jurisdiction.** Participation in token networks, holding utility
> tokens, or operating mining hardware may be subject to licensing, taxation, securities
> regulation, or outright prohibition in your country or region. Consult qualified legal and
> financial counsel before taking any action based on material in this document.
>
> **Past performance of comparable tokens is not indicative of future results.** Any reference to
> third-party networks (Polygon, Solana, Cardano, Bittensor, etc.) is for analytical context only
> and does not imply endorsement, partnership, or comparable outcomes.
>
> **Extreme outcome probability:** The majority of utility tokens launched since 2017 have lost
> more than 95% of peak value. The conservative scenario in this document — not the aggressive one
> — should be treated as the planning baseline for hardware-investment decisions.

---

## 1. Why Model Price Scenarios at All?

Price scenario modelling for TRI serves one purpose: **chip-miner unit economics**.

A prospective operator considering the purchase of an AI accelerator cluster — whether a set of
consumer GPUs, a rented colocation rack, or a purpose-built inference node — must estimate whether
hardware capital expenditure will be recovered before that hardware becomes obsolete. That payback
calculation requires a revenue assumption, and revenue is denominated in TRI.

The question "what will TRI be worth?" is therefore not a speculative inquiry. It is an
**engineering input** to a break-even model, identical in kind to asking "what will electricity
cost per kWh?" or "what will the datacenter PUE be?"

Because the answer is genuinely unknown, we do not give one answer. We give **five**, spanning
four orders of magnitude. An operator who can make money at the conservative scenario has a robust
business. An operator who only pencils out at the aggressive scenario is, in effect, placing a
macro bet on TRI adoption — and should budget accordingly.

### What this chapter does NOT do

- Predict TRI price
- Recommend purchasing TRI
- Assert that any scenario is probable
- Constitute a prospectus, whitepaper offering, or securities disclosure

---

## 2. Fixed Parameters

Before scenarios, establish the invariants.

| Parameter | Value | Source |
|-----------|-------|--------|
| TRI total supply | **7,625,000,000,000 (7.625 T)** | Tokenomics Ch. 01 |
| Era 0 emission | ~50% of total supply over ~4 years | Tokenomics Ch. 04 |
| Era 0 daily block reward (reference node) | See per-scenario table | Tokenomics Ch. 04 |
| Era 0 reference miner daily TRI earnings | **~2,611,000 TRI/day** | Tokenomics Ch. 04 |

The **reference miner** used throughout this chapter is a single Era 0 chip-miner slot operating
at the baseline stake weight. Actual earnings vary with stake, uptime, and network competition.
The 2,611,000 TRI/day figure is used as the unit; multiply by your actual allocation factor.

**Market capitalisation formula:**

```
Market Cap = Price per TRI × 7,625,000,000,000
```

**Miner daily revenue formula:**

```
Daily Revenue (USD) = Daily TRI Earnings × Price per TRI
                    = 2,611,000 TRI × Price per TRI
```

---

## 3. Five Price Scenarios

### Overview Table

| Scenario | TRI Price | Implied Market Cap | Reference Miner Daily Revenue |
|----------|-----------|--------------------|-------------------------------|
| Bear | $0.0001 | $762 M | $261 / day |
| Conservative | $0.001 | $7.6 B | $2,611 / day |
| Moderate | $0.01 | $76 B | $26,110 / day |
| Aggressive | $0.1 | $762 B | $261,100 / day |
| Internet-of-AI | $1.00 | $7.6 T | $2,611,000 / day |

---

### 3.1 Scenario A — Bear: $0.0001 / TRI

**Implied market cap:** $762,500,000 (~$762 M)

**Reference miner daily revenue:** 2,611,000 × $0.0001 = **$261.10 / day**

#### Narrative

This scenario represents a functioning but low-demand network: TRI is liquid, the protocol
operates, but adoption is limited to a small number of early enterprise pilots and proof-of-concept
deployments. Liquidity is thin, spreads are wide, and many chip miners are operating at or near
break-even.

At $762 M market cap, TRI would rank alongside mid-tier DePIN or infrastructure tokens with
limited real-world throughput. This is plausibly achievable within 12–24 months of mainnet launch
if adoption lags supply emission.

#### Unit Economics at Bear

Assume a chip-miner operator with the following cost structure:

| Cost Item | Monthly Estimate |
|-----------|-----------------|
| Hardware amortisation (36-month) | $800 |
| Electricity (GPU cluster, ~$0.08/kWh) | $400 |
| Colocation / bandwidth | $150 |
| **Total monthly cost** | **$1,350** |

Monthly revenue at Bear: $261/day × 30 = **$7,830 / month**

Gross margin: ($7,830 − $1,350) / $7,830 = **~83%**  
Payback period (hardware at $28,800): ~4 months

**Conclusion at Bear:** Still profitable for an efficient operator, but margin is highly sensitive
to electricity cost and hardware depreciation schedule. A 50% price drop from Bear halves revenue
to ~$130/day — still positive, but precarious.

#### Why Bear Can Persist

- Era 0 emissions are large (50% of supply in 4 years); selling pressure from miners can suppress
  price even with healthy protocol activity.
- If the broader crypto market enters a prolonged bear cycle, all token prices compress regardless
  of fundamentals.
- Regulatory overhang or exchange delisting events can cause sustained low-liquidity conditions.

---

### 3.2 Scenario B — Conservative: $0.001 / TRI

**Implied market cap:** $7,625,000,000 (~$7.6 B)

**Reference miner daily revenue:** 2,611,000 × $0.001 = **$2,611 / day**

#### Narrative

At $7.6 B market cap, TRI would be comparable to **Polygon (MATIC) in its early growth phase**.
This scenario requires genuine adoption: multiple active AI inference marketplaces using TRI for
settlement, several hundred thousand verified hardware nodes, and institutional or enterprise
procurement of verified compute.

This is the **planning baseline** recommended for hardware-investment decisions. It requires
real-world product-market fit but not macro token mania.

#### Unit Economics at Conservative

Using the same cost structure as Bear:

| Metric | Value |
|--------|-------|
| Daily revenue | $2,611 |
| Monthly revenue | $78,330 |
| Monthly cost | $1,350 |
| Gross margin | ~98% |
| Payback period (hardware at $28,800) | **<2 weeks** |

At this price, a chip-miner operator with even a modest cluster generates strong cash flows. The
risk is not day-to-day profitability but sustainability: will TRI hold $0.001 long enough to
recover CapEx fully?

#### Conditions Required

1. DePIN AI marketplace with measurable transaction volume ($50M–$500M annualised)
2. TRI listed on Tier-1 centralised exchanges with adequate market depth
3. Bittensor or comparable validator network integrating TRI for compute payment
4. Minimal regulatory enforcement action against DePIN tokens in major jurisdictions

---

### 3.3 Scenario C — Moderate: $0.01 / TRI

**Implied market cap:** $76,250,000,000 (~$76 B)

**Reference miner daily revenue:** 2,611,000 × $0.01 = **$26,110 / day**

#### Narrative

$76 B positions TRI in the range of **Solana in late 2023 / early 2024** ($70–90 B). This is not
a small network — it implies Trinity has become a significant, recognised infrastructure layer for
AI compute.

At this level, TRI would likely appear in major index products, ETF baskets, and institutional
portfolios. Stablecoin-denominated TRI pairs would have high liquidity; Oracle providers would
cover TRI price feeds natively.

#### Conditions Required

1. Verifiable hardware attestation has become a de-facto industry standard for AI compute markets
2. Multiple Fortune 500 or government procurement programs specify Trinity-verified compute
3. Annualised on-chain compute settlement exceeds $1 B
4. The broader AI infrastructure narrative drives investor demand for "AI + crypto" exposure
5. TRI emission has partially tapered (Era 0 or early Era 1), reducing supply pressure

#### Risk Factors Specific to Moderate

- At $76 B, TRI attracts regulatory scrutiny in the US, EU, and Asia that it would not face at
  smaller sizes. SEC enforcement, MiCA classification changes, or OFAC sanctions could compress
  price dramatically.
- Competition from centralised AI cloud providers (AWS, Azure, Google) intensifying.
- A major smart-contract exploit or hardware attestation bypass vulnerability would cause a
  rapid re-rating.

---

### 3.4 Scenario D — Aggressive: $0.1 / TRI

**Implied market cap:** $762,500,000,000 (~$762 B)

**Reference miner daily revenue:** 2,611,000 × $0.1 = **$261,100 / day**

#### Narrative

At $762 B, TRI would be among the top five crypto assets by market capitalisation. For context,
Bitcoin's market cap at its 2021 peak was ~$1.2 T. This scenario requires Trinity to have become
**foundational infrastructure for global AI compute** — the TCP/IP layer of verifiable inference.

This is speculative territory. Operators should not build business cases that depend on this
scenario. However, it is worth modelling because:

1. If the "Internet of AI" thesis plays out and Trinity captures even 10–20% of AI compute market
   value, numbers at this scale become plausible on a 7–10 year horizon.
2. At $0.1, the daily revenue per reference miner slot ($261K) makes even very expensive
   GPU clusters trivially profitable in days — meaning the primary limiting factor becomes
   hardware supply and network slot availability, not economics.

#### Conditions Required

1. AI inference has commoditised and DePIN has become the dominant procurement model
2. Trinity's verifiable hardware attestation is embedded in AI safety/compliance frameworks at the
   national government level (EU AI Act compliance layer, US NIST AI standards, etc.)
3. Defence and intelligence procurement of TRI-verified compute at significant scale
4. Era 0 and Era 1 emissions have largely concluded; annual inflation rate is below 2%
5. TRI is included in major sovereign wealth fund and pension fund digital-asset allocations

#### Honest Assessment

The probability of reaching $762 B is low. Most projects that required these conditions have not
met them. Model this scenario to understand optionality, not to budget for it.

---

### 3.5 Scenario E — Internet-of-AI: $1.00 / TRI

**Implied market cap:** $7,625,000,000,000 (~$7.6 T)

**Reference miner daily revenue:** 2,611,000 × $1.00 = **$2,611,000 / day**

#### Narrative

$7.6 T exceeds the current total crypto market cap and is comparable to the combined market
capitalisation of Apple, Microsoft, and NVIDIA. This is not a planning scenario — it is a
**theoretical ceiling** that defines the outer bound of the model.

For TRI to reach $1.00, it would need to represent verified AI compute infrastructure at a scale
that dwarfs today's entire AI industry. This would require:

- 10+ years of sustained network growth
- Dominance as the AI compute settlement layer globally
- Minimal competition from future token architectures that may supersede TRI
- A crypto market structural shift in which institutional and sovereign capital flows into
  infrastructure tokens at equity-like multiples

**This scenario is presented for mathematical completeness only.** Any hardware operator
or investor treating $1.00/TRI as a near-term price target is engaging in speculation, not
engineering.

At $1.00/TRI, a reference miner earns over $2.6 M per day. Daily earnings at this level are not
a feature of the token — they are a sign of global-scale adoption that cannot be assumed,
projected, or promised.

---

## 4. Comparable Token Market Caps

To provide context for the scenario levels, consider publicly available historical market
capitalisations of infrastructure and smart-contract tokens. **These figures are historical
reference points, not predictions.**

| Token | Network Type | Reference Market Cap | Approx. Period |
|-------|-------------|---------------------|----------------|
| Polygon (MATIC/POL) | L2 / DeFi infra | ~$7–8 B | 2022–2023 |
| Cardano (ADA) | L1 smart contract | ~$30 B | 2021 peak |
| Solana (SOL) | L1 high-throughput | ~$70–80 B | Late 2023 / 2024 |
| Ethereum (ETH) | L1 / smart contract base | ~$200–400 B | 2023–2024 |
| Bitcoin (BTC) | Store of value / L1 | ~$700 B–$1.3 T | 2021–2024 |

**Key observations:**

1. **$7–8 B** (Conservative scenario) is achievable for a differentiated infrastructure protocol
   with genuine traction — Polygon reached this range within ~3 years of mainnet.
2. **$30–80 B** (Moderate scenario) requires a project to be in the top 10 crypto assets by
   market cap — Cardano and Solana each achieved this, but neither sustained it through full
   market cycles without drawdowns exceeding 80%.
3. **$762 B+** (Aggressive scenario) is uncharted territory for any non-Bitcoin asset to date.
4. **$7.6 T** (Internet-of-AI) exceeds all recorded crypto market caps for any single asset.

These comparables are not analogies — they are scale references. Trinity's value proposition is
materially different from Polygon, Cardano, or Solana. Whether that difference is value-additive
or value-dilutive is unknowable at this stage.

---

## 5. Trinity vs. Comparable Networks — Different Value Proposition

### 5.1 What Trinity Does Differently

The networks cited above — Polygon, Cardano, Solana — are general-purpose smart-contract
platforms. Their value accrues through transaction fees, DeFi TVL, NFT activity, and developer
ecosystem density.

**Trinity's value proposition is narrower and more specialised:**

| Dimension | General L1/L2 Tokens | TRI |
|-----------|---------------------|-----|
| Primary utility | Smart contract execution | Payment for verifiable AI compute |
| Value driver | Developer adoption, TVL | Hardware node operators, AI inference demand |
| Attestation | Software consensus | Hardware-backed verifiable execution |
| Target buyer | DeFi/NFT users, developers | AI application developers, enterprise, defence |
| Competitive moat | Network effects, DeFi composability | Hardware attestation uniqueness, verifiable trust |

### 5.2 Why This Could Mean Higher Value Per Unit

If AI application buyers are willing to pay a **trust premium** for verifiable, tamper-evident
compute — as opposed to commodity cloud inference — TRI may command a higher utility rate per
transaction than a general-purpose gas token.

In enterprise and defence contexts, "auditable AI" is a regulatory and compliance requirement, not
a preference. This creates structural demand that is not correlated with retail token speculation.

### 5.3 Why This Could Mean Lower Value Per Unit

- The total addressable market for verifiable AI compute, while growing, is today a fraction of
  total AI spend.
- Hardware-dependent networks have higher operational costs and coordination friction than
  software-only chains.
- Enterprise procurement cycles are slow; token markets price in expectations, and if adoption
  lags promises, price compression is swift.
- Trinity competes with centralised alternatives (AWS Nitro Enclaves, Google Confidential
  Computing, Azure Confidential VMs) that do not require holding a token.

---

## 6. Demand Drivers

The following factors could increase TRI demand and, by extension, price. These are **potential
drivers**, not guarantees.

### 6.1 DePIN AI Marketplace

As the Trinity Network enables a decentralised marketplace for AI compute, every successful
transaction requires TRI. If the marketplace achieves significant volume:

- **Mechanism:** Buyers of AI inference (developers, enterprises) acquire TRI to pay for compute.
  This creates **buy-side pressure** proportional to marketplace volume.
- **Leverage:** A $1 B annualised marketplace would require significant TRI liquidity; at 10%
  velocity, this implies ~$100 M in TRI must be held or circulated continuously.

### 6.2 Bittensor Validator and Subnet Integration

Bittensor (TAO) has pioneered the concept of incentive-aligned AI subnets. If Trinity's
verifiable hardware attestation is adopted as a proof-of-hardware layer within Bittensor subnets
or similar networks:

- **Mechanism:** Validators and subnet operators requiring hardware attestation must hold or
  transact in TRI.
- **Leverage:** Bittensor ecosystem operators number in the thousands; even modest TRI requirements
  per operator create a floor demand.

### 6.3 Defence and Intelligence Contracts

Sovereign AI — the principle that national governments should control their own AI compute stack
— is a policy priority in the US, EU, UK, and several Asian nations. If Trinity achieves
certification or procurement preference in:

- US DoD "responsible AI" hardware certification programs
- EU AI Act Art. 13 transparency requirements
- NATO or Five Eyes vetted-compute frameworks

…then government procurement could represent a structural, price-insensitive demand floor for TRI.
This is a long-dated catalyst, not a near-term event.

### 6.4 AI Safety and Audit Markets

As AI regulatory frameworks mature, third-party auditors of AI systems may require verifiable
compute logs — exactly what Trinity's hardware attestation provides. Each audit engagement could
involve TRI-denominated escrow or payment.

---

## 7. Supply Pressure — Era 0 Emissions

### 7.1 The Inflation Problem

Era 0 emits approximately **50% of total TRI supply over ~4 years**. This is a **very high
emission rate**. For reference:

| Asset | Annualised Emission During Growth Phase |
|-------|----------------------------------------|
| Bitcoin | ~1.8% at current rates; was ~12.5% in early years |
| Ethereum (post-merge) | ~0.5% net (with burns) |
| Solana | ~8% in early years |
| **TRI (Era 0)** | **~12.5% per year of total supply** (50% / 4 years) |

High emission means **persistent selling pressure**: miners who receive TRI as block rewards must
periodically sell to pay electricity bills, hardware costs, and operational expenses. Even if
demand grows, price appreciation is working against a constant headwind of new supply.

### 7.2 Implications for Miner Strategy

1. **Do not assume TRI price rises during Era 0.** If demand grows proportional to supply,
   price is roughly flat in real terms. Price appreciation requires demand growth to *exceed*
   emission growth.
2. **Fiat-denominated costs are fixed; TRI-denominated revenues are variable.** When TRI price
   falls, the break-even TRI quantity required to cover costs rises. Scenario modelling should
   include a price-at-risk sensitivity.
3. **Hold/sell ratio matters.** Miners who hold all TRI assume full price risk. Miners who sell
   immediately crystallise the current-period price. Most rational operators will sell a portion
   to cover costs and hold a portion as optionality — this is a business decision, not a
   financial recommendation.

### 7.3 Post-Era-0 Supply Dynamics

After Era 0, emission rates drop significantly (per the halving schedule in Chapter 04). If
demand continues growing while supply growth slows, basic supply-demand dynamics would be
constructive for price. This is the standard "halving narrative" seen in Bitcoin cycles — but it
requires sustained demand, which is not guaranteed.

---

## 8. Honest Pessimism

### 8.1 The Base Rate for Utility Tokens

The following is a factual summary of historical utility token outcomes, not an opinion:

- Of the thousands of utility tokens launched between 2017 and 2023, **fewer than 5% have
  maintained or appreciated from their initial price over a 3-year horizon**.
- The majority lost 95–99% of peak value.
- Projects with strong technical teams, novel technology, and significant capital backing have
  failed to achieve sustainable token demand.
- "Utility" in a whitepaper does not create utility in a marketplace.

These facts do not mean TRI will fail. They mean the prior probability of success is low, and
that success requires execution that most projects have not delivered.

### 8.2 Specific Risks to TRI's Value Thesis

| Risk | Description | Mitigant |
|------|-------------|----------|
| Demand never materialises | AI inference markets don't adopt DePIN model | Strong enterprise sales pipeline required |
| Centralised competition | AWS/Azure/Google offer comparable attestation at lower friction | Hardware trust moat must be technically superior |
| Regulatory prohibition | TRI classified as security in major jurisdictions | Legal structuring, utility-first design |
| Protocol exploit | Smart contract or attestation mechanism vulnerability | Continuous audit, bug bounty |
| Market saturation | Too many DePIN tokens compete for same capital | Differentiation via defence/enterprise focus |
| Miner selling pressure | Era 0 emission overwhelms demand | Demand catalysts must outpace emission |
| Key-person risk | Project dependent on small founding team | Decentralised governance roadmap |

### 8.3 The Default Assumption

**For all hardware-investment planning: use the Conservative scenario ($0.001 / TRI) as the
base case.** If the economics do not work at $7.6 B market cap, they should not be made to
work by assuming a higher scenario. Any project that only pencils out at Moderate or Aggressive
is fundamentally a bet on token appreciation, not a hardware business.

---

## 9. Token Velocity Considerations

**Token velocity** is the rate at which TRI changes hands relative to its total market cap. High
velocity suppresses price; low velocity (holding behaviour) supports price.

### 9.1 The Velocity Problem

If TRI is used purely as a **payment rail** — buyers acquire TRI, use it for compute, and
immediately receive USD equivalents — then TRI circulates rapidly. High velocity implies that the
"monetary base" required to support a given transaction volume is small, which caps price even
with high usage.

**Example:**  
If the TRI marketplace processes $1 B/year in compute payments, and TRI turns over 52 times per
year (once per week), only ~$19 M in TRI market cap is required to support that volume —
far less than any scenario in Section 3.

### 9.2 Mechanisms to Reduce Velocity

The Trinity Network design incorporates several features that create **holding incentives**:

1. **Staking requirements for chip-miner slots** — operators must lock TRI to access mining
   allocation. This removes circulating supply from the velocity calculation.
2. **Governance rights** — TRI holders who stake gain voting power on protocol parameters;
   this creates a long-duration holding incentive for ecosystem participants.
3. **Compute escrow** — enterprise buyers may pre-purchase compute capacity via TRI escrow
   contracts; these lock TRI for weeks or months.
4. **Era 0 staking multipliers** — early stakers earn enhanced block rewards, incentivising
   lock-up over immediate sale.

### 9.3 The Velocity-Value Relationship

A simplified version of the Fisher equation applied to token economies:

```
Market Cap ≈ (Annual Transaction Volume) / Velocity
```

For TRI to support a $7.6 B market cap (Conservative scenario) at a velocity of 10, the
network would need to settle ~$76 B in annualised compute transactions. For comparison, AWS
annual revenue was ~$90 B in 2023. This is a plausible long-run target for a successful
DePIN AI compute marketplace — but it is not an early-stage expectation.

---

## 10. Mine for Math, Not for Moon

The purpose of this document is to give chip-miner operators a rigorous, quantitative framework
for making hardware investment decisions. The five scenarios in Section 3 span four orders of
magnitude — from $261/day to $2.6 M/day per reference miner slot. That is not a prediction
range; it is an acknowledgement that the future is uncertain.

**The correct approach to scenario analysis is:**

1. **Identify your cost floor.** What is the minimum daily revenue (in USD) at which your
   hardware investment recovers cost and generates acceptable return on capital?

2. **Find which TRI price corresponds to that floor.** If your floor is $500/day, you need TRI
   above ~$0.000192. If your floor is $5,000/day, you need TRI above ~$0.00192.

3. **Assess the probability of hitting that floor.** Is that TRI price consistent with Bear,
   Conservative, or higher scenarios? How probable does each scenario seem given current
   network activity, competitive landscape, and macro environment?

4. **Plan the Conservative; hope for Moderate.** Budget as though TRI reaches $0.001. Be
   pleasantly surprised if it reaches $0.01. Do not make irreversible hardware commitments
   that require $0.1 to break even.

5. **Monitor actual network metrics, not price.** On-chain transaction volume, active node
   count, staked TRI, and compute-hours settled are leading indicators of demand. Price is a
   lagging indicator. If the metrics are growing, the economics will likely follow. If the
   metrics are stagnant, no amount of market enthusiasm will sustain price long-term.

Chip mining in the Trinity Network is an infrastructure business. Infrastructure businesses
are built on contracts, throughput, and utilisation rates — not on token price speculation.
The operators who will thrive are those who control their costs, grow their hardware efficiency,
and treat TRI price variance as a risk to be managed, not a windfall to be anticipated.

**Mine for math, not for moon.**

---

## Summary Reference Table

| Scenario | Price | Market Cap | Daily Revenue | Realistic Horizon |
|----------|-------|------------|---------------|-------------------|
| Bear | $0.0001 | $762 M | $261 | Near-term; possible at launch |
| Conservative | $0.001 | $7.6 B | $2,611 | 2–3 years post-mainnet with traction |
| Moderate | $0.01 | $76 B | $26,110 | 5–7 years; top-10 crypto required |
| Aggressive | $0.1 | $762 B | $261,100 | 7–10+ years; blue-sky |
| Internet-of-AI | $1.00 | $7.6 T | $2,611,000 | Theoretical ceiling only |

**Planning baseline: Conservative ($0.001 / TRI)**

---

## ⚠️ CLOSING DISCLAIMER — REGULATORY AND FINANCIAL WARNINGS

> **No investment advice.** Nothing in this document constitutes investment advice, financial
> advice, trading advice, or any other sort of advice. The author and Trinity Network make no
> recommendations about whether to purchase, sell, or hold TRI or any other digital asset.
>
> **Utility token — not a security.** TRI is designed and intended as a utility token for
> payment of AI compute services within the Trinity Network. Whether TRI constitutes a security
> under applicable law depends on the laws and regulations of your jurisdiction and the specific
> facts and circumstances of any offering or transaction. Nothing in this document should be
> construed as a legal opinion on the regulatory classification of TRI.
>
> **No guarantee of return.** There is no guarantee that TRI will achieve any of the price
> levels described in this document. TRI may trade at zero. Token holders may lose the entire
> value of any TRI they acquire.
>
> **Regulatory variation.** Laws governing digital assets, utility tokens, DePIN networks, and
> cryptocurrency mining vary significantly across jurisdictions and change frequently. Residents
> of certain jurisdictions may be prohibited from purchasing, holding, or mining TRI. It is
> your responsibility to determine the legal status of TRI in your jurisdiction before taking
> any action.
>
> **Forward-looking statements.** This document contains forward-looking statements, including
> projections, estimates, and scenario analyses. These statements are subject to risks and
> uncertainties that could cause actual outcomes to differ materially. Forward-looking
> statements are not guarantees of future performance.
>
> **Third-party references.** References to Polygon, Cardano, Solana, Bittensor, Amazon Web
> Services, and other third-party networks and services are for analytical context only. No
> partnership, endorsement, or affiliation is implied or should be inferred.
>
> **Author:** Dmitrii Vasilev \<admin@t27.ai\>  
> **Document series:** Trinity Network Tokenomics v2.0  
> **Chapter:** 07 — Price Scenario Analysis

---

*End of Chapter 07*
