# 08 — Burn Mechanics

**Author:** Dmitrii Vasilev \<admin@t27.ai>  
**Document:** TRI Tokenomics v2 · Chapter 08  
**Status:** Draft  
**Last revised:** 2025

---

## Table of Contents

1. [Why Burns](#1-why-burns)
2. [Channel 1 — Inference Fee Burn](#2-channel-1--inference-fee-burn)
3. [Channel 2 — Slashing Burn](#3-channel-2--slashing-burn)
4. [Channel 3 — Governance Bond Burn](#4-channel-3--governance-bond-burn)
5. [Channel 4 — Anchor Violation Burn](#5-channel-4--anchor-violation-burn)
6. [Channel 5 — R-SI-1 Violation Burn](#6-channel-5--r-si-1-violation-burn)
7. [Burn Math](#7-burn-math)
8. [Burn Registry](#8-burn-registry)
9. [Comparative Analysis](#9-comparative-analysis)
10. [Burn-to-Zero Policy](#10-burn-to-zero-policy)

---

## 1. Why Burns

### 1.1 The Halving Problem

TRI operates on a deterministic halving emission schedule. Every Era, the block reward is cut in half. This is a supply compression mechanism on the issuance side — it slows new TRI entering circulation. However, halving alone does not reduce the existing supply. Across the full span of emission, cumulative issuance asymptotically approaches the fixed cap of **7,625,597,484,987 TRI** (3²⁷), and the network still holds every token ever minted that has not been destroyed.

An emission-only deflationary model produces diminishing supply growth, not net supply contraction. Halvings reduce the *rate* at which new tokens dilute holders; they do not shrink the float. For TRI to become net-deflationary — that is, for circulating supply to actually decrease over time — the protocol needs independent mechanisms that permanently remove tokens from existence. That is the role of burns.

### 1.2 Deflationary Pressure as a Design Goal

Burns serve three interconnected purposes in the TRI system:

**Economic:** Permanent removal of tokens from supply creates scarcity pressure that complements halving-driven emission reduction. If the burn rate exceeds new issuance, circulating supply contracts. Even when burn rate is below new issuance, it meaningfully dampens dilution and anchors long-run value accrual to network activity.

**Behavioral:** Burns are the protocol's enforcement currency. When economic penalties resolve to a burn rather than redistribution, the penalty has no beneficiary who might extract rents or lobby for looser enforcement. Burned tokens belong to no one. This removes the structural conflict of interest present in slashing-to-treasury models, where treasury administrators have an incentive (conscious or not) to set slash rates higher than optimal to maximise inflows. With burns, the protocol's deterrence is credible precisely because no one profits from triggering it.

**Alignment:** Token holders, validators, operators, and end-users all share the same burn pool — zero. Any burn event marginally benefits every remaining holder equally. This aligns all participant classes around network hygiene: reducing inference fraud, maintaining validator honesty, producing quality governance proposals, and ensuring hardware compliance are all subtly rewarded by the scarcity effect of burns triggered by those who fail these standards.

### 1.3 Five Burn Channels

TRI implements five distinct burn channels, each targeting a different failure mode or cost-center in the network:

| # | Channel | Trigger | Primary Purpose |
|---|---------|---------|-----------------|
| 1 | Inference Fee Burn | Every B5 ZK Job Prover fee | Deflationary flow tied to network usage |
| 2 | Slashing Burn | Validator misbehaviour detected | Validator honesty enforcement |
| 3 | Governance Bond Burn | Governance proposal failure | Proposal quality enforcement |
| 4 | Anchor Violation Burn | 0x47C0 hardware check failure | Hardware compliance enforcement |
| 5 | R-SI-1 Violation Burn | Standalone `*` operator in RTL | Circuit design correctness enforcement |

These channels are described in detail in sections 2 through 6, followed by aggregate burn mathematics in section 7.

### 1.4 Relationship to Era Transitions

Halving events mark Era boundaries. The current and projected emission schedule is:

| Era | Block Reward | Annual Emission (approx.) | Cumulative Issued (approx.) |
|-----|-------------|--------------------------|----------------------------|
| 0 | R₀ | ~760T × initial fraction | — |
| 1 | R₀ / 2 | Half of Era 0 | — |
| 2 | R₀ / 4 | Quarter of Era 0 | Majority of supply issued |
| N | R₀ / 2ᴺ | Negligible | Asymptotic to 3²⁷ |

By Era 2, a substantial fraction of the total supply will be in circulation. This is precisely when deflationary pressure from burns must exceed or match new issuance to transition from net-inflationary to net-deflationary. The burn mechanics described here are calibrated with Era 2 as the inflection point target (see section 7 for quantitative targets).

---

## 2. Channel 1 — Inference Fee Burn

### 2.1 Overview

Every ZK proof submitted through the B5 Job Prover pipeline carries a mandatory fee denominated in TRI. Of that fee, **30% is burned permanently**. This creates a continuous, usage-proportional deflationary flow: the more inference the network processes, the more TRI is destroyed.

This channel is the only burn sourced from productive economic activity rather than penalties. It is therefore the most predictable, most scalable, and most philosophically aligned: the protocol becomes scarcer as it becomes more useful.

### 2.2 Fee Structure

The B5 ZK Job Prover fee is set at:

```
BASE_PROVER_FEE = 0.05 TRI per proof
```

This fee is paid by the submitting party (the inference requester or aggregating relay) and is deducted atomically at proof submission. It is not a gas fee and does not vary with network congestion in the same way as transaction fees on general-purpose chains — it is a fixed protocol-level charge assessed against the job.

### 2.3 Burn Calculation

The burn portion per proof is:

```
BURN_PER_PROOF = BASE_PROVER_FEE × BURN_FRACTION
               = 0.05 TRI × 0.30
               = 0.015 TRI
```

The remaining 70% (0.035 TRI) is distributed to the Prover who submitted the valid proof.

```
PROVER_REWARD_PER_PROOF = 0.05 TRI × 0.70
                        = 0.035 TRI
```

This split was chosen to balance two competing pressures:
- **Too high a burn fraction** reduces Prover income, discouraging participation and degrading proof throughput.
- **Too low a burn fraction** makes Channel 1 insignificant against total emission.

At 30%, the burn fraction is material at scale while keeping Prover economics positive at target proof volumes.

### 2.4 Aggregate Burn Projection

Let `P` denote daily proof volume across the network. Daily burn from Channel 1:

```
DAILY_BURN_CH1 = P × 0.015 TRI
```

| Daily Proof Volume (P) | Daily Burn (TRI) | Annual Burn (TRI) |
|------------------------|------------------|--------------------|
| 1,000,000 | 15,000 | 5,475,000 |
| 10,000,000 | 150,000 | 54,750,000 |
| 100,000,000 | 1,500,000 | 547,500,000 |
| 1,000,000,000 | 15,000,000 | 5,475,000,000 |

At 1 billion daily proofs — plausible for an AI inference network at scale — annual burn from Channel 1 alone reaches 5.475 trillion TRI. This would represent substantial deflationary pressure relative to Era 2 emission levels (see section 7).

### 2.5 On-Chain Mechanics

At the protocol level, the burn is executed by the Prover fee settlement contract:

```solidity
function settleProverFee(address prover, uint256 jobId) external {
    uint256 fee = BASE_PROVER_FEE;                    // 0.05 TRI (18 dec)
    uint256 burnAmount = fee * BURN_BPS / 10_000;     // BURN_BPS = 3000
    uint256 proverReward = fee - burnAmount;

    TRI.burn(burnAmount);                              // permanent destruction
    TRI.transfer(prover, proverReward);                // 70% to prover

    emit ProverFeeBurn(jobId, prover, burnAmount);
    emit BurnRegistryEntry(CHANNEL_INFERENCE_FEE, burnAmount, block.number);
}
```

The `TRI.burn()` call routes to the token contract's `_burn()` function, which subtracts from both `balanceOf(address(0))` and `totalSupply`. There is no intermediate holding address; the tokens are removed from `totalSupply` in the same transaction as the proof settlement.

### 2.6 Fee Parameter Governance

`BASE_PROVER_FEE` and `BURN_BPS` are governance-adjustable parameters with the following constraints:

- `BASE_PROVER_FEE` floor: 0.01 TRI (below this, Prover economics collapse)
- `BASE_PROVER_FEE` ceiling: 1.00 TRI (above this, inference demand destruction)
- `BURN_BPS` floor: 1000 (10%) — below this, Channel 1 becomes negligible
- `BURN_BPS` ceiling: 5000 (50%) — above this, Prover income falls below viability threshold

Adjustments require a governance vote passing the standard supermajority threshold and are subject to a 14-day timelock before taking effect, allowing Provers to adjust operational plans.

---

## 3. Channel 2 — Slashing Burn

### 3.1 Overview

Validators who are caught engaging in provable misbehaviour have a portion or all of their staked TRI **slashed to the burn address** `0x000...dead`. Unlike Channel 1, which fires continuously, Channel 2 fires episodically — it is a deterrence mechanism, and a well-functioning network should see low Channel 2 activity as evidence that deterrence is working.

The burn address used is the canonical dead address:

```
BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD
```

This address has no known private key. Tokens transferred to it are permanently inaccessible. The use of a transfer-to-dead rather than a `_burn()` call means the tokens remain visible in `totalSupply` on the token contract, but are recorded as destroyed in the Burn Registry (see section 8). For accounting purposes, tokens at `0x000...dead` are treated as burned and excluded from circulating supply calculations.

### 3.2 Misbehaviour Classifications

Slashable offences are classified into three tiers:

**Tier 1 — Minor (5% slash):**
- Liveness failures: missed block production windows exceeding protocol tolerance
- Equivocation of low economic significance (duplicate attestations with no detected coordination)
- Repeated latency violations breaching the 95th-percentile SLA for proof verification

**Tier 2 — Major (33% slash):**
- Double-signing a block at the same height with conflicting state roots
- Voting for an invalid state transition with demonstrable cryptographic evidence
- Coordinated censorship of transactions from a specific address for more than one epoch

**Tier 3 — Terminal (100% slash):**
- Submitting a forged ZK proof (fabricating a valid-appearing proof without performing the underlying computation)
- Colluding with ≥2 other validators to revert a finalized block
- Exploiting a known vulnerability in the protocol without responsible disclosure, with evidence of financial gain

### 3.3 Evidence and Adjudication

A slash must be initiated via a **slash proposal** submitted to the Slashing Arbitration Module (SAM). The proposal must include:

1. Validator identity (public key and node ID)
2. Offence classification (Tier 1, 2, or 3)
3. Cryptographic evidence packet (signed block headers, fork proofs, proof-of-equivocation, or similar)
4. Submitter's identity and a challenge bond equal to 2% of the proposed slash amount

The SAM adjudicates the proposal in two phases:

- **Fast path (72 hours):** Automatically accepts Tier 1 and Tier 2 proposals where the evidence is self-verifying on-chain (e.g., two conflicting signed block headers at the same height can be verified by any node without human interpretation).
- **Governance path (14-day vote):** Required for Tier 3 offences and any disputed Tier 1/2 proposal where the accused validator raises a counter-challenge bond within the 72-hour window.

If the slash is upheld, the slashed stake is transferred to `0x000...dead` and the submitter receives their challenge bond back plus a **whistleblower reward** of 5% of the slashed amount, funded from treasury. If the slash is rejected, the submitter's challenge bond is itself burned (this discourages frivolous slash proposals).

### 3.4 Stake Recovery

There is no stake recovery from a burn. Once slashed to `0x000...dead`, the tokens are gone. A slashed validator may re-stake fresh TRI after a **re-entry lockout period**:

- Tier 1: 30-day lockout
- Tier 2: 180-day lockout
- Tier 3: Permanent ban (node ID and associated wallet blacklisted from validator registration)

### 3.5 Economic Deterrence Rationale

For slashing to deter misbehaviour rather than merely tax it after the fact, the expected value of misbehaving must be negative. Let:

- `G` = expected gain from the misbehavior (e.g., MEV extraction, reorg profit)
- `p` = probability of detection
- `S` = stake slashed upon detection

The deterrence condition is: `p × S > G`

At Tier 3 (100% slash), even low detection probability `p` produces a large expected loss for any stake size that makes the validator's position meaningful. This is intentional: the most severe offences — forged proofs, coordinated reorgs — are exactly those where the adversary has the most to gain, so the penalty must be correspondingly severe.

---

## 4. Channel 3 — Governance Bond Burn

### 4.1 Overview

Every on-chain governance proposal requires the submitter to post a **governance bond**. If the proposal fails to meet the minimum quorum threshold or is defeated by a supermajority against vote, the bond is burned. If the proposal passes, the bond is returned in full.

This mechanism enforces proposal quality. It imposes a real economic cost on spam proposals, low-effort submissions, and proposals designed to exhaust governance attention rather than improve the protocol.

### 4.2 Bond Sizing

The governance bond amount is dynamically sized as a function of the proposal type:

| Proposal Type | Bond (TRI) | Rationale |
|--------------|------------|-----------|
| Parameter adjustment | 500,000 TRI | Low-complexity change |
| Contract upgrade | 5,000,000 TRI | High-complexity, high-risk change |
| Treasury spend (< 1% of treasury) | 2,000,000 TRI | Moderate-stakes spend |
| Treasury spend (≥ 1% of treasury) | 10,000,000 TRI | High-stakes spend |
| Constitution amendment | 20,000,000 TRI | Highest-stakes change |
| Emergency fast-track | 50,000,000 TRI | Bypass of normal delay, highest risk |

Bond amounts are denominated in TRI at time of proposal submission and are locked in the Governance Escrow Contract for the duration of the voting period. The submitter may be any address holding sufficient TRI; bond posting does not require validator status.

### 4.3 Failure Conditions

A proposal is considered **failed** for burn purposes under the following conditions:

1. **Quorum not reached:** The total votes cast (yes + no + abstain) do not reach the minimum quorum of 15% of circulating supply within the voting period (7 days standard, 3 days for fast-track).
2. **Defeated:** Votes against exceed votes in favour after quorum is met, with a supermajority defeat defined as ≥60% no-vote share.
3. **Withdrawn after deposit period:** Submitter withdraws the proposal after it enters the deposit period but before voting begins, in circumstances where the protocol determines withdrawal is opportunistic (flagged by governance guardians).

A proposal that reaches quorum and is rejected by a simple majority (50-60% no) returns the bond — the submitter made a genuine attempt to persuade the community. Only clear-majority defeats and quorum failures trigger burn.

### 4.4 Burn Execution

Upon determination of a failed proposal, the Governance Escrow Contract calls:

```solidity
function burnFailedProposalBond(uint256 proposalId) external onlyGovernance {
    uint256 bond = proposals[proposalId].bond;
    address submitter = proposals[proposalId].submitter;

    require(isFailedProposal(proposalId), "Proposal not failed");
    require(!proposals[proposalId].bondBurned, "Bond already processed");

    proposals[proposalId].bondBurned = true;
    TRI.burn(bond);

    emit GovernanceBondBurned(proposalId, submitter, bond);
    emit BurnRegistryEntry(CHANNEL_GOVERNANCE_BOND, bond, block.number);
}
```

The burn is irreversible. No portion of a failed proposal bond is redistributed to voters, guardians, or treasury.

### 4.5 Anti-Gaming Provisions

The governance bond burn creates an asymmetric dynamic: proposers bear the full downside of failure while the network bears distributed benefit from quality signal. Several provisions prevent gaming:

- **Split proposals:** If a submitter attempts to circumvent bond sizing by splitting a large proposal into many small ones that individually qualify for lower bond tiers, governance guardians may consolidate them and apply the higher bond tier. Consolidation decisions are themselves subject to appeal.
- **Proxy proposals:** Bond must be posted by the same address that signs the proposal transaction. Proxy posting (posting bond from address A while submitter is address B) is not permitted; the smart contract enforces this.
- **Rapid resubmission:** A proposal substantially similar to one that failed within the last 30 days requires a bond of 3× the standard amount for its type.

---

## 5. Channel 4 — Anchor Violation Burn

### 5.1 Overview

TRI's AI inference network relies on a hardware attestation system built around the **0x47C0 anchor check** — a cryptographic protocol by which participating compute nodes prove that their hardware configuration matches the registered and approved profile. This check is the network's guarantee that proofs are generated on authentic, unmodified hardware capable of the ZK computation it claims to perform.

When a node fails the 0x47C0 anchor check, its **collateral is automatically burned**. There is no human intervention, no appeal window, and no grace period for a first offence. The burn is triggered by the protocol itself upon verification failure.

### 5.2 The 0x47C0 Anchor Check

The 0x47C0 anchor check operates as follows:

1. **Registration:** When a compute node joins the network, it registers a hardware profile: CPU/GPU model, firmware version, TEE (Trusted Execution Environment) attestation certificate, and a cryptographic commitment to its software stack hash.

2. **Challenge-response:** Periodically (every epoch by default, with random spot-checks between epochs), the network's Anchor Verification Contract issues a challenge to the node. The challenge is a random nonce that the node must process through a hardware-bound function that only runs correctly on the registered TEE. The response is a signed proof that can only be generated by the specific hardware configuration declared at registration.

3. **Verification:** The on-chain Anchor Verifier checks the response against the registered commitment. A mismatch indicates one of: hardware swap without re-registration, firmware modification, TEE tampering, or outright fabrication of the response.

4. **Failure action:** Upon verified failure, the Anchor Verifier immediately calls the burn function against the node's posted collateral.

### 5.3 Collateral Requirements

Nodes must post collateral proportional to their registered computational capacity:

| Node Tier | Minimum Collateral (TRI) |
|-----------|--------------------------|
| Light (CPU-only prover) | 100,000 TRI |
| Standard (single GPU cluster) | 1,000,000 TRI |
| Heavy (multi-GPU rack) | 10,000,000 TRI |
| Enterprise (dedicated inference farm) | 100,000,000 TRI |

Collateral is held in the Node Collateral Escrow, separate from any staking positions the node operator may hold.

### 5.4 Burn Mechanics on Failure

```solidity
function processAnchorFailure(bytes32 nodeId) external onlyAnchorVerifier {
    uint256 collateral = nodeCollateral[nodeId];
    address operator = nodeOperator[nodeId];

    require(collateral > 0, "No collateral to burn");

    // Immediately deregister the node
    nodeStatus[nodeId] = NodeStatus.BANNED;
    delete nodeCollateral[nodeId];

    // Burn 100% of collateral
    TRI.burn(collateral);

    emit AnchorViolationBurn(nodeId, operator, collateral);
    emit BurnRegistryEntry(CHANNEL_ANCHOR_VIOLATION, collateral, block.number);
}
```

The node is simultaneously deregistered. A banned node ID cannot re-register with the same hardware commitment hash. Re-entry requires:

1. Posting fresh collateral at the applicable tier
2. Submitting a new, clean TEE attestation
3. Passing a manual review by the Hardware Compliance Committee for Enterprise tier nodes
4. A 90-day probationary period during which spot-check frequency is doubled

### 5.5 Why 100% Collateral Burn

A partial burn — say, 50% — would price in anchor failure as a cost of doing business for operators running modified hardware configurations. At 50% burn, an operator who can increase throughput by 20% through firmware modification faces a simple break-even calculation: if their modified hardware produces 20% more proofs before detection, they may come out ahead even accounting for the penalty.

A 100% burn eliminates this calculus. There is no throughput improvement that survives total collateral loss plus forced deregistration. The penalty is structurally inescapable regardless of how long the violation goes undetected.

### 5.6 Grace Period Policy

There is deliberately no grace period for anchor violations, but there is a **false positive protection mechanism**:

- If a node fails an anchor check but believes the failure is erroneous (hardware misconfiguration, network partition during challenge-response, attestation service downtime), it may submit a **collateral freeze request** within 1 hour of the failure notice.
- The freeze request pauses the burn for 48 hours pending a deterministic re-challenge.
- If the re-challenge succeeds, the failure is voided, collateral is returned, and the node resumes operation.
- If the re-challenge also fails, the burn proceeds and the freeze request is noted as a failed appeal (which modestly increases future scrutiny of that operator's nodes).
- Each operator is entitled to one freeze request per 180-day period per node. Repeated false appeals are themselves subject to a small penalty.

---

## 6. Channel 5 — R-SI-1 Violation Burn

### 6.1 Overview

TRI's circuit compilation toolchain enforces a set of Register-Space Integrity rules (R-SI rules) that govern how RTL (Register Transfer Level) specifications submitted by circuit operators must be structured. Rule **R-SI-1** specifically prohibits the use of a **standalone `*` operator** — an unqualified wildcard that matches any signal in the register namespace without an explicit scope qualifier.

Standalone `*` creates a class of subtle, hard-to-audit circuit errors: it can silently capture unintended signals, cause non-deterministic register mappings, and produce ZK circuits whose constraints do not faithfully represent the intended computation. Because ZK proofs are only as trustworthy as the circuits they prove against, R-SI-1 violations are treated as a protocol-level integrity threat.

When a circuit operator submits RTL containing a standalone `*` operator, their **operator bond is slashed**. The slashed amount is burned.

### 6.2 The R-SI-1 Rule

Formal definition:

```
R-SI-1: A standalone `*` operator is defined as any occurrence of the token `*` 
        appearing as a signal reference operand that:
          (a) is not preceded by an explicit namespace qualifier 
              (e.g., `module::*`, `bus[7:0].*` are qualified and exempt), AND
          (b) is not used as an arithmetic multiplication operator 
              (disambiguated by context: `*` between two numeric expressions 
               is arithmetic, not a signal reference), AND
          (c) is not inside a block comment or string literal.
        
        Violation: Any occurrence matching (a) AND (b) AND NOT (c).
```

The RTL parser enforces R-SI-1 at submission time. Submissions that violate the rule are rejected, and the violation is logged against the submitting operator's identity.

### 6.3 Bond Structure

Circuit operators must post an **operator bond** prior to submitting RTL:

| Submission Type | Required Bond (TRI) |
|----------------|---------------------|
| Prototype circuit (< 1,000 gates) | 50,000 TRI |
| Standard circuit (1,000–100,000 gates) | 500,000 TRI |
| Production circuit (> 100,000 gates) | 5,000,000 TRI |
| Critical path circuit (consensus-layer) | 50,000,000 TRI |

The bond remains locked for a **circuit escrow period** of 30 days after the circuit is approved and deployed. During this period, the circuit is in a monitored state and any R-SI-1 violations discovered in post-submission audit (via formal verification tools that may catch violations the real-time parser missed) can still trigger a burn.

### 6.4 Slash and Burn on R-SI-1 Violation

**At submission time (pre-deployment):**

If the RTL parser catches a standalone `*` at submission:

```solidity
function processRSI1Violation(
    address operator,
    bytes32 submissionId,
    uint256 violationCount
) external onlyRTLParser {
    uint256 bond = operatorBonds[operator][submissionId];
    uint256 slashFraction = min(violationCount * 2000, 10000); // 20% per violation, max 100%
    uint256 slashAmount = bond * slashFraction / 10_000;

    operatorBonds[operator][submissionId] -= slashAmount;
    TRI.burn(slashAmount);

    emit RSI1ViolationBurn(submissionId, operator, violationCount, slashAmount);
    emit BurnRegistryEntry(CHANNEL_RSI1_VIOLATION, slashAmount, block.number);
}
```

Slash schedule:
- 1 violation: 20% of bond burned, submission rejected, operator may resubmit after remediation
- 2 violations: 40% of bond burned, same
- 3 violations: 60% of bond burned, operator flagged for review
- 4 violations: 80% of bond burned, operator suspended for 30 days
- 5+ violations: 100% of bond burned, operator suspended for 180 days

**Post-deployment audit violations:** If a formal verifier discovers a qualifying R-SI-1 violation in a circuit already deployed, the full remaining bond is burned regardless of violation count, and the circuit is immediately suspended pending a patch submission.

### 6.5 Rationale for Progressive Slash

The progressive slash schedule reflects a graduated assumption of intent:

- **1 violation** is most likely a programmer error. The 20% burn is a meaningful economic signal without being catastrophic — the operator can continue, having paid a real cost.
- **3+ violations** suggests systematic disregard for the rule or deliberate obfuscation. The burn becomes severe enough to deter strategic non-compliance.
- **Post-deployment violation** is treated as the most serious because at that point the circuit was reviewed, approved, and is live. A violation found post-deployment means the operator either submitted a deliberately obfuscated circuit or failed to perform adequate internal verification. In either case, the full bond is the appropriate response.

### 6.6 Toolchain Integration

The RTL parser ships with a built-in R-SI-1 linter (`rsi1-lint`) that operators can run locally before submission to catch violations prior to incurring any penalty. The linter is open source and its rule definitions are identical to the on-chain parser's. There is no excuse for submitting a violating circuit without having run the linter; the tooling to prevent violations is freely available.

---

## 7. Burn Math

### 7.1 Target Burn Rate

The target for the burn system as a whole is:

```
TARGET_ANNUAL_BURN = 5% to 15% of annual emission
```

This range is calibrated to achieve net-deflationary supply by Era 2. Below 5%, burns are too small to meaningfully counteract emission. Above 15%, the burn system begins to constrain network activity in ways that may harm adoption (Prover fees become significant transaction costs, validator slash rates create excessive risk aversion).

Formally, let:
- `E(t)` = annual emission in year `t` (TRI/year, declining with halvings)
- `B(t)` = annual burn in year `t` from all five channels combined
- `S(t)` = circulating supply at time `t`

Net supply change:

```
ΔS(t) = E(t) − B(t)
```

For net-deflationary:

```
B(t) > E(t)
```

For the softer goal of burn rate within target range:

```
0.05 × E(t) ≤ B(t) ≤ 0.15 × E(t)
```

### 7.2 Era 2 Inflection Point

By Era 2:
- The cumulative emission is substantial; most supply is in circulation
- Annual emission is at 1/4 of original block reward levels
- Network usage (and therefore Channel 1 inference fee burn) should be high if adoption has proceeded as projected

At projected Era 2 network activity levels, Channel 1 alone at 100M+ daily proofs contributes annual burn of ~547B TRI. If Era 2 annual emission is in the range of 1–5 trillion TRI, Channel 1 positions the network to achieve net-deflationary status through usage alone, with Channels 2–5 providing additional pressure.

### 7.3 Break-Even Analysis

Define the **break-even proof volume** as the daily proof count P* at which Channel 1 burn equals total annual emission:

```
P* × 0.015 × 365 = E_annual
P* = E_annual / (0.015 × 365)
P* = E_annual / 5.475
```

If Era 2 annual emission is 2 trillion TRI:

```
P* = 2,000,000,000,000 / 5.475
P* ≈ 365,296,803,653 daily proofs ≈ 365B proofs/day
```

This is a demanding target for Channel 1 alone. Combined with Channels 2–5 contributing burn during periods of network stress (large slashing events, governance contention, hardware non-compliance), the 5–15% target range becomes achievable at more moderate proof volumes.

### 7.4 Sensitivity to Parameters

Key parameter sensitivities:

| Parameter | Increase effect on B(t) | Decrease effect on B(t) |
|-----------|------------------------|------------------------|
| `BURN_BPS` (Ch1) | Linear increase | Linear decrease |
| Daily proof volume (Ch1) | Linear increase | Linear decrease |
| Slash rate / frequency (Ch2) | Direct increase | Direct decrease |
| Proposal failure rate (Ch3) | Direct increase | Direct decrease |
| Anchor violation rate (Ch4) | Direct increase | Direct decrease |
| R-SI-1 violation rate (Ch5) | Direct increase | Direct decrease |

The governance system monitors burn rates quarterly. If `B(t)` falls below 3% of `E(t)` for two consecutive quarters, a governance proposal to adjust `BURN_BPS` upward is automatically queued for community vote.

### 7.5 Burn Share by Channel (Projected Steady State)

Based on projected steady-state network activity, approximate channel contribution to total burn:

| Channel | Projected Share of Total Burn |
|---------|-------------------------------|
| 1 — Inference Fee | 85–92% |
| 2 — Slashing | 4–8% |
| 3 — Governance Bond | 1–3% |
| 4 — Anchor Violation | 1–3% |
| 5 — R-SI-1 Violation | <1% |

Channel 1 dominates because it fires on every proof. Channels 2–5 are episodic and their share reflects a well-functioning network — high Channel 2, 4, or 5 activity is a signal of network stress, not health.

---

## 8. Burn Registry

### 8.1 Purpose

All burn events across all five channels are recorded in the **Burn Registry** — a single on-chain log that provides a queryable, auditable history of every token destruction event in TRI's history. The Registry is the source of truth for burn accounting.

### 8.2 Data Structure

Each burn event is recorded as a `BurnEntry`:

```solidity
struct BurnEntry {
    uint256 entryId;        // Sequential, monotonically increasing
    uint8   channel;        // 1-5 corresponding to burn channels
    uint256 amount;         // TRI burned (18 decimal places)
    uint256 blockNumber;    // Block in which burn occurred
    uint256 timestamp;      // Unix timestamp
    bytes32 referenceId;    // Channel-specific: jobId, nodeId, proposalId, etc.
    address initiator;      // Address that triggered the burn (or address(0) for automatic)
}
```

Events are indexed by `channel`, `blockNumber`, and `referenceId`. The Registry contract exposes:

```solidity
function getEntriesByChannel(uint8 channel, uint256 fromBlock, uint256 toBlock)
    external view returns (BurnEntry[] memory);

function getTotalBurnedByChannel(uint8 channel)
    external view returns (uint256);

function getTotalBurnedAllTime()
    external view returns (uint256);

function getBurnRate(uint256 windowBlocks)
    external view returns (uint256 triPerBlock);
```

### 8.3 Queryability

The Burn Registry is designed for off-chain indexing. Events are emitted as:

```solidity
event BurnRegistryEntry(
    uint8 indexed channel,
    uint256 amount,
    uint256 indexed blockNumber
);
```

Standard indexers (The Graph, custom subgraph) can subscribe to this event and maintain real-time burn dashboards without requiring on-chain computation. The Registry's `view` functions are available for direct contract queries but are primarily used by the governance system's automatic monitoring (see section 7.4) and by the burn rate dashboard maintained by the Foundation.

### 8.4 Immutability Guarantee

The Burn Registry is a non-upgradeable contract. Its logic cannot be modified by governance vote, Foundation action, or any other mechanism. This immutability guarantee ensures that historical burn records cannot be altered, even in the event of a major protocol upgrade. New protocol versions may deploy a new Registry contract, but the old Registry's data remains permanently on-chain and queryable.

### 8.5 Integration with Supply Oracles

The Burn Registry feeds into TRI's on-chain **circulating supply oracle**:

```
CIRCULATING_SUPPLY = TOTAL_SUPPLY − BURNED_ALL_TIME − LOCKED_COLLATERAL − FOUNDATION_VESTED
```

The oracle is queried by governance contracts to correctly calculate quorum thresholds relative to actual circulating supply rather than nominal total supply. As cumulative burn grows, the quorum denominator shrinks, which gradually makes governance more sensitive — a positive feedback loop where deflationary pressure improves governance participation rates.

---

## 9. Comparative Analysis

### 9.1 Ethereum — EIP-1559 Base Fee Burn

Ethereum's burn mechanism was introduced with EIP-1559 (August 2021). Under EIP-1559, every transaction pays a **base fee** that is burned, plus an optional **priority fee** (tip) that goes to the validator. The base fee is algorithmically adjusted each block based on whether the previous block was above or below 50% capacity.

**Comparison with TRI:**

| Dimension | Ethereum (EIP-1559) | TRI Channel 1 |
|-----------|--------------------|--------------------|
| Trigger | Every transaction | Every ZK proof |
| Burn fraction | 100% of base fee | 30% of prover fee |
| Remainder | Tip to validator | 70% to Prover |
| Rate variability | High (congestion-driven) | Low (fixed fee) |
| Annual burn (2024 est.) | ~600K–1M ETH/year | Proof-volume dependent |
| Deflationary status | Net-deflationary in high activity periods | Targets net-deflationary by Era 2 |
| Fee payer | Transaction sender | Inference requester |

Ethereum's model is elegant in that the burn rate automatically increases during congestion, creating a natural market for block space. TRI's fixed-fee model trades this elegance for predictability — Provers and users know exactly what the fee and burn fraction will be, which simplifies economic planning.

Ethereum achieved net-deflationary status in several periods since EIP-1559, but reverted to net-inflationary during low-activity periods (notably post-Merge bear market phases). TRI aims for structural net-deflationary status by Era 2 regardless of activity cycles, using the multi-channel burn system to maintain burn even when Channel 1 (the usage-tied channel) is low.

### 9.2 Bittensor — No Burn Mechanism

Bittensor (TAO) does not have a native burn mechanism as of this writing. Supply is purely deflationary via emission halvings (similar to Bitcoin). There is no systematic removal of TAO from circulation; all value capture accrues through emission reduction and market-driven scarcity.

**Implications for TRI's design:**

Bittensor's model demonstrates that an AI-specific network can attract significant value without burns. However, the lack of a burn mechanism means all deflationary pressure comes from halvings — which only reduce the rate of supply increase, not the supply itself. As Bittensor's emission approaches zero in later eras, the supply is essentially fixed, but there is no force counteracting any inflationary pressure from unlocks, migrations, or token printing events.

TRI's position is that burn mechanisms provide a stronger long-run deflationary guarantee than emission-only models, because burns are tied to network activity rather than just the passage of time. A network that generates more economic activity should produce more scarcity — burns achieve this, halvings do not.

### 9.3 BNB — Manual Quarterly Burns

Binance's BNB burn operates via periodic manual buyback-and-burn events conducted by Binance. Historically, Binance committed to burning 20% of quarterly profits in BNB until 50% of the total supply is destroyed. In 2021, Binance introduced the **Auto-Burn** mechanism, which uses a formula based on BNB price and block production to calculate each quarter's burn amount, making the process more systematic but still centrally administered.

**Comparison with TRI:**

| Dimension | BNB (Auto-Burn) | TRI Burns |
|-----------|-----------------|-----------|
| Administration | Centralized (Binance-controlled) | Fully decentralized, protocol-enforced |
| Trigger | Quarterly formula | Continuous + event-driven |
| Transparency | Published formulas, off-chain execution | On-chain, auditable Registry |
| Dependence on issuer | High (requires Binance to execute) | Zero (smart contract execution) |
| Manipulation risk | Non-zero (formula inputs controlled by Binance) | Near-zero (inputs are on-chain observables) |

The BNB model's primary weakness is its dependence on a centralized actor to execute burns. If Binance's business conditions change — whether due to regulatory pressure, financial difficulty, or strategic decision — the burn program could be paused or modified without token holder consent. TRI's burns are autonomous smart contract operations; they execute regardless of any external party's preferences.

### 9.4 Summary Positioning

TRI's burn architecture sits in a design space that combines:
- **Ethereum's protocol-native automation** (no manual burns, no central executor)
- **Multi-channel scope** beyond gas fees (slashing, governance, hardware compliance, circuit integrity)
- **Penalty-as-burn philosophy** (unlike Ethereum, where penalties from validators go to other parties, not burns)

The five-channel approach means TRI's burn system is active across the full lifecycle of network operation, not just during high-fee periods.

---

## 10. Burn-to-Zero Policy

### 10.1 The Core Commitment

TRI operates under a **Burn-to-Zero Policy**: all tokens identified for burning under any of the five channels are destroyed permanently and completely. There is no mechanism — in any channel, under any circumstance — by which tokens designated for burn are instead:

- Redirected to the treasury
- Redistributed to validators or stakers
- Held in escrow pending future decision
- Converted to a different token class
- Credited to any address, including the Foundation

Burned tokens reduce `totalSupply`. They do not move to a reserve. They do not fund public goods. They cease to exist.

### 10.2 Why No Treasury Reroute

The prohibition on treasury rerouting is intentional and structural. Treasury rerouting would:

1. **Undermine the deflationary signal.** If burned tokens become treasury tokens, `totalSupply` does not decrease. The deflationary narrative rests on genuine supply reduction, not accounting sleight of hand.

2. **Create a conflict of interest in enforcement.** If the Foundation or governance treasury receives tokens from Anchor Violation burns or Slashing burns, the entities responsible for setting enforcement parameters have a financial interest in high violation rates. Burn-to-zero eliminates this conflict entirely.

3. **Introduce centralization.** A treasury that accumulates tokens from penalty events has discretionary power over those tokens. How they are spent becomes a governance battle. Burn-to-zero means there is nothing to fight over — the tokens are gone.

4. **Violate the immutability of punishment.** In a Burn-to-Zero model, a slashed validator knows with certainty what happened to their stake. It was destroyed. It did not enrich a competitor, a foundation, or a governance faction. This certainty is itself part of the deterrence value.

### 10.3 Smart Contract Enforcement

The Burn-to-Zero commitment is enforced at the smart contract level. The TRI token contract's `burn()` function irrevocably reduces `totalSupply`:

```solidity
function _burn(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: burn from zero address");
    
    _balances[account] -= amount;
    _totalSupply -= amount;
    
    emit Transfer(account, address(0), amount);
}
```

There is no `unburn()`, no `mintFromBurn()`, no privileged mint that could reverse a burn. The token contract itself is non-upgradeable in the sections governing `_burn` and `_totalSupply`. The Foundation explicitly waives any future governance power to introduce token recovery mechanisms.

### 10.4 Exception Handling

**False positive burns (see Channel 4 false positive protection):** In the single case where a burn may be queued rather than immediate (the 48-hour anchor re-challenge freeze), the tokens remain in the Node Collateral Escrow and are not yet burned. If the re-challenge succeeds, the collateral is returned from Escrow. Tokens are only transferred to the burn function upon confirmed failure. At no point are tokens that have already been passed to `_burn()` recoverable.

**Protocol bugs:** In the event that a smart contract bug causes an unintended burn, the Burn-to-Zero Policy means no recovery is possible. The tokens are gone. The protocol accepts this risk as the price of credibility. A burn mechanism that can be reversed provides weaker guarantees than one that cannot.

### 10.5 Governance Limitations

Governance may adjust:
- `BURN_BPS` (the fraction burned in Channel 1) within stated bounds
- Bond amounts for governance proposals (Channel 3)
- Slash percentages for Tier 1 and Tier 2 offences (Channel 2)
- R-SI-1 slash schedule per violation count (Channel 5)

Governance may **not**, by design and by smart contract constraint, adjust:
- The Burn-to-Zero destination (tokens always go to `address(0)`, not a governance-specified address)
- The immutability of the `_burn` function
- The Burn Registry's historical records
- The Anchor Violation burn (Channel 4) — which is autonomous and not subject to governance parameterization beyond collateral tier minimums

The separation of "governance-adjustable parameters" from "burn-to-zero commitment" is deliberate. Governance retains flexibility to tune the economic parameters of the burn system in response to network conditions; it does not retain power to redirect the burns themselves.

---

## Appendix A — Parameter Reference

| Parameter | Value | Governance-adjustable | Bounds |
|-----------|-------|----------------------|--------|
| `BASE_PROVER_FEE` | 0.05 TRI | Yes | [0.01, 1.00] TRI |
| `BURN_BPS` (Ch1) | 3000 (30%) | Yes | [1000, 5000] BPS |
| Tier 1 slash rate | 5% | Yes | [1%, 15%] |
| Tier 2 slash rate | 33% | Yes | [15%, 49%] |
| Tier 3 slash rate | 100% | No | Fixed |
| Governance quorum | 15% | Yes | [10%, 25%] |
| Re-entry lockout T1 | 30 days | Yes | [7, 90] days |
| Re-entry lockout T2 | 180 days | Yes | [90, 365] days |
| Re-entry lockout T3 | Permanent | No | Fixed |
| Anchor re-challenge window | 48 hours | Yes | [12h, 96h] |
| R-SI-1 escrow period | 30 days | Yes | [7, 90] days |
| Auto-burn governance trigger | 3% of emission for 2Q | Yes | No floor |

---

## Appendix B — Burn Channel Quick Reference

```
Channel 1 — Inference Fee Burn
  Trigger:   Every B5 ZK Job Prover proof submission
  Amount:    0.015 TRI per proof (30% of 0.05 TRI fee)
  Method:    TRI._burn() in same tx as proof settlement
  Frequency: Continuous

Channel 2 — Slashing Burn
  Trigger:   Validator misbehaviour (Tier 1/2/3)
  Amount:    5%, 33%, or 100% of staked position
  Method:    Transfer to 0x000...dead (canonical burn address)
  Frequency: Episodic

Channel 3 — Governance Bond Burn
  Trigger:   Proposal fails quorum or defeated by supermajority
  Amount:    Full bond (500K–50M TRI depending on proposal type)
  Method:    TRI._burn() in governance contract
  Frequency: Episodic

Channel 4 — Anchor Violation Burn
  Trigger:   Node fails 0x47C0 anchor check (after re-challenge if applicable)
  Amount:    100% of node collateral (100K–100M TRI by tier)
  Method:    TRI._burn() in Anchor Verifier contract
  Frequency: Automatic, event-driven

Channel 5 — R-SI-1 Violation Burn
  Trigger:   Standalone * operator detected in submitted RTL
  Amount:    20%–100% of operator bond (progressive by violation count)
  Method:    TRI._burn() in RTL Parser contract
  Frequency: Episodic
```

---

*End of Chapter 08 — Burn Mechanics*
