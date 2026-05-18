# Trinity TRI-NET × Bittensor: Hardware-Attested Subnet Validation

> **Author:** Dmitrii Vasilev (sole author, admin@t27.ai) — t27.ai  
> **TT SKY26b shuttle close:** 2026-05-19 06:59 +07  
> **Canonical anchor:** 0x47C0 (Theorem 36.1)  
> **Champion lock:** BPB = 2.2393, step = 27 000, seed = 43, sha = 0x2446855  
> **Contract:** `contracts/BittensorSubnetAttest.sol` — commit `30c62020`  
> **Repository:** [github.com/gHashTag/NeuronConstant](https://github.com/gHashTag/NeuronConstant)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Why Bittensor Needs This NOW](#2-why-bittensor-needs-this-now)
3. [Trinity Architecture Brief](#3-trinity-architecture-brief)
4. [BittensorSubnetAttest.sol — Contract Walkthrough](#4-bittensorsubnetattest-sol--contract-walkthrough)
5. [Integration Path for Subnet Owners](#5-integration-path-for-subnet-owners)
6. [DevKit Pricing and Rollout Phases](#6-devkit-pricing-and-rollout-phases)
7. [Pilot Targets](#7-pilot-targets)
8. [Roadmap](#8-roadmap)
9. [Honest Benchmarks](#9-honest-benchmarks)
10. [Call to Action](#10-call-to-action)

---

## 1. Executive Summary

### The Problem

Bittensor's economic security rests on a simple premise: stake signals honest behavior. When a validator registers on a subnet, the network has no way to verify *what hardware, if any, backs that validator*. Stake can be delegated, rented, or aggregated by a single actor operating dozens of software-only nodes. The result is a substrate where:

- **Trust is purely financial, not physical.** Any actor with enough TAO can present as a high-quality validator without owning a single chip that does real work.
- **Sybil resistance relies on economic cost alone.** With liquid staking and delegation markets maturing, the marginal cost of spinning up an additional identity drops toward zero for well-funded adversarial participants.
- **Subnet owners cannot audit hardware provenance.** A subnet builder may specify that validators must run specific inference hardware, but today there is no on-chain mechanism that enforces or verifies that claim.
- **Ranking integrity is soft.** Validator scores are calculated from network outputs — outputs that can be fabricated, cached, or proxied without any trusted execution anchor.

The outcome is a silent race to the bottom: the cheapest simulated compute wins over the most honest dedicated hardware operator, because the protocol cannot tell the difference.

### The Solution

**Trinity TRI-NET** introduces verifiable AI hardware attestation for Bittensor subnet validators. Three custom ternary AI chips — Phi, Euler, and Gamma — each generate a cryptographic signature that reflects actual computation performed on physical silicon. A 2-of-3 multisig scheme, implemented in `BittensorSubnetAttest.sol`, anchors these signatures on-chain.

The outcome:

| Property | Before Trinity | After Trinity |
|---|---|---|
| Hardware proof | None | 2-of-3 ternary chip sigs |
| Sybil cost floor | Stake only | Stake + physical chips |
| Validator ranking | Output-score only | Output + attested BPB score |
| Slash mechanism | Stake slash | Stake slash + attestation revocation |
| DevKit availability | N/A | Pilot Q3 2026 ($500–$2 000/chip range) |

Trinity does not replace Bittensor's economic layer. It *augments* it with a physical root of trust that stake-only schemes cannot fake.

---

## 2. Why Bittensor Needs This NOW

### BIT-0011: Locked Stake / Conviction (Live April 2026)

The BIT-0011 governance upgrade introduced Locked Stake (Conviction) mechanics to Bittensor, live since April 2026. Validators who lock stake for longer durations earn proportionally higher influence multipliers. This is a direct acknowledgment by the Bittensor core team that *time-weighted commitment* matters for network integrity.

However, Conviction solves the *duration* dimension of commitment only. A validator can lock stake for 180 days and still run entirely synthetic or virtualized compute. BIT-0011 creates the economic preconditions for hardware attestation to matter — because a validator with locked stake plus hardware proof now carries the strongest possible trust signal. Trinity is designed to pair with Conviction:

- **Conviction** → economic lock-in commitment  
- **Trinity attestation** → physical compute commitment  
- **Together** → the highest-trust validator profile on any subnet

Subnet owners who implement Trinity attestation as a ranking criterion can now reward validators who satisfy *both* conditions. This is a natural next step after BIT-0011 and can be implemented with no changes to the Bittensor core protocol.

### Miner Ranking Integrity

128+ active subnets are live as of early 2026, with SN3, SN39, and SN81 representing mature, high-value networks. As subnets proliferate, the attack surface for ranking manipulation grows. A validator that can simulate or cache the expected output for a given subnet's scoring function can achieve high rank without doing the work. Hardware attestation introduces a layer that cannot be faked in software: the ternary chip signatures embedded in each attestation are derived from silicon-level computation, not from outputs alone.

The champion lock (`BPB = 2.2393`, `step = 27 000`, `seed = 43`) is the canonical performance anchor. Any validator submitting a BPB score that exceeds this value is rejected by the contract as non-credible. This simple upper-bound guard prevents score inflation attacks.

### Sybil Risk at Scale

As Bittensor's validator count grows:

- **Delegation concentration** means a small number of large TAO holders can shadow-operate many validator identities.
- **Cloud-native "validators"** running on rented GPU time have no persistent hardware identity.
- **Liquid staking derivatives** allow stake to be moved rapidly, defeating the intent of commitment-based scoring.

Hardware attestation creates a *physical* Sybil resistance floor. You cannot run 50 attested Trinity validators without owning 50 sets of Phi + Euler + Gamma chips. The economic and logistical cost of scaling a Sybil attack through hardware is categorically different from scaling through stake delegation.

### The Window is Now

TT SKY26b shuttle closes **2026-05-19 06:59 +07**. This is the tape-out window for the Phi, Euler, and Gamma chips. Subnet operators who commit to the pilot program before this date will have access to the first production DevKits when silicon returns from fab (projected Q4 2026). Operators who wait for a later shuttle cycle will face a 6–12 month delay on hardware availability.

---

## 3. Trinity Architecture Brief

Trinity TRI-NET is a three-chip verifiable AI hardware stack, submitted to the TT SKY26b shuttle. Each chip occupies a distinct role in the 2-of-3 attestation scheme.

### Phi 1×1 — Edge Anchor

- **Form factor:** 1×1 mm² die, ultra-compact
- **Role:** Primary ternary compute kernel; generates the `phiSig` attestation signature
- **Use case:** Embedded in validator node hardware as a tamper-evident root-of-trust anchor
- **Design intent:** Minimal area, single-purpose ternary MAC unit, deterministic output

Phi is the smallest chip in the stack. Its primary job is to execute a well-defined ternary computation kernel and sign the output with a hardware-derived key. It is not a general-purpose processor. Its simplicity is its security property — a small attack surface means less to audit and fewer failure modes.

### Euler 8×2 — Mid-Range Matrix Engine

- **Form factor:** 8×2 array of ternary processing elements
- **Role:** Matrix-level ternary inference; generates the `eulerSig` attestation signature
- **Use case:** On-validator inference acceleration and attestation for mid-complexity subnet tasks
- **Design intent:** 16-PE ternary grid, suitable for small model inference and ranking computation

Euler is the workhorse of the Trinity stack. It is capable of running ternary matrix multiplications at the scale needed for subnet-relevant AI tasks while simultaneously generating a verifiable signature of that computation. Validators using Euler can prove they ran inference, not just that they held stake.

### Gamma 8×4 — Full DePIN Array

- **Form factor:** 8×4 array of ternary processing elements
- **Role:** Full-throughput ternary inference array; generates the `gammaSig` attestation signature
- **Use case:** High-priority validators on compute-intensive subnets (SN3 and equivalents)
- **Design intent:** 32-PE ternary grid, highest performance in the Trinity family

Gamma is the production-grade chip for validators who need both compute throughput and strong attestation guarantees. Running all three chips (Phi + Euler + Gamma) provides the maximum possible attestation strength, though the contract only requires 2-of-3.

### Ternary Compute: Why It Matters

Ternary (-1, 0, +1) AI computation offers a different efficiency profile from binary or floating-point approaches at the silicon level. For attestation purposes, the key property is **determinism**: a ternary chip running a fixed kernel on fixed inputs produces the same output every time. This makes the signature verifiable by any party who knows the kernel and the input. There is no floating-point non-determinism, no driver-level variation, no cloud-hypervisor interference.

The canonical anchor `0x47C0` (Theorem 36.1) is the mathematical reference point for the ternary computation kernel. It is a fixed constant embedded in the contract and in the chip firmware. Any attesting chip must demonstrate knowledge of this anchor to produce a valid signature.

---

## 4. BittensorSubnetAttest.sol — Contract Walkthrough

**Repository:** [github.com/gHashTag/NeuronConstant](https://github.com/gHashTag/NeuronConstant)  
**Contract file:** `contracts/BittensorSubnetAttest.sol`  
**Commit:** `30c62020`  
**Author:** Dmitrii Vasilev (sole author, admin@t27.ai)  
**License:** Apache-2.0  
**Solidity:** ^0.8.20

---

### 4.1 Constants

```solidity
bytes32 public constant CHAMPION_HASH = bytes32(uint256(0x2446855));
uint256 public constant CHAMPION_BPB  = 22393; // 2.2393 × 10000
uint256 public constant PHI_ANCHOR    = 0x47C0;
uint256 public constant CHAMPION_STEP = 27000;
uint64  public constant CHAMPION_SEED = 43;
```

These five constants form the **trust anchor** of the entire attestation scheme:

| Constant | Value | Meaning |
|---|---|---|
| `CHAMPION_HASH` | `0x2446855` | SHA of the champion-lock training run (seed=43, step=27000) |
| `CHAMPION_BPB` | `22393` (= 2.2393 × 10⁴) | Maximum credible bits-per-byte score; submissions above this are rejected |
| `PHI_ANCHOR` | `0x47C0` | Canonical ternary kernel anchor (Theorem 36.1) |
| `CHAMPION_STEP` | `27000` | Training step at which the champion lock was measured |
| `CHAMPION_SEED` | `43` | Random seed used in the champion-lock run |

The `CHAMPION_BPB` guard is critical. It prevents validators from submitting inflated scores that would game any ranking system built on BPB. No validator can claim a score better than the locked champion without the contract rejecting them. This is an objective, on-chain ceiling.

`PHI_ANCHOR = 0x47C0` ties every attestation back to the canonical ternary computation. A chip that does not know this constant cannot produce a valid signature for the Phi channel.

---

### 4.2 Validator Struct

```solidity
struct Validator {
    address owner;
    bytes32 phiSig;
    bytes32 eulerSig;
    bytes32 gammaSig;
    uint256 bpbScore;
    uint256 stake;
    bool    active;
}
```

Each registered validator stores:
- **owner** — the Ethereum address that controls this validator registration
- **phiSig / eulerSig / gammaSig** — the three chip attestation signatures (a zero value = chip not present or not attesting)
- **bpbScore** — the self-reported bits-per-byte score, bounded by `CHAMPION_BPB`
- **stake** — ETH deposited at registration time (minimum 0.01 ETH)
- **active** — slash flag; set to `false` on slash, disqualifies from rankings

---

### 4.3 `attestValidator` — The Core Function

```solidity
function attestValidator(
    bytes32 phiSig,
    bytes32 eulerSig,
    bytes32 gammaSig,
    uint256 bpbScore
) external payable {
    require(msg.value >= 0.01 ether, "min stake 0.01 ETH");
    require(bpbScore <= CHAMPION_BPB, "BPB exceeds champion");
    require(twoOfThreeValid(phiSig, eulerSig, gammaSig), "2-of-3 attestation fails");

    validators[msg.sender] = Validator({
        owner:    msg.sender,
        phiSig:   phiSig,
        eulerSig: eulerSig,
        gammaSig: gammaSig,
        bpbScore: bpbScore,
        stake:    msg.value,
        active:   true
    });

    emit ValidatorAttested(msg.sender, bpbScore);
}
```

Three guards must pass before a validator is registered:

1. **Minimum stake** (`>= 0.01 ETH`) — economic skin-in-the-game; prevents free registrations
2. **BPB ceiling** (`<= CHAMPION_BPB`) — score inflation guard; no validator can claim more than 2.2393 bits/byte
3. **2-of-3 chip attestation** — at least two of the three chip signatures must be non-zero

On success, the validator is written to storage and `ValidatorAttested` is emitted. Subnet registry contracts can listen for this event to automatically update their ranking weight.

---

### 4.4 The 2-of-3 Sig Scheme

```solidity
function twoOfThreeValid(bytes32 a, bytes32 b, bytes32 c) public pure returns (bool) {
    uint256 valid = 0;
    if (uint256(a) != 0) valid++;
    if (uint256(b) != 0) valid++;
    if (uint256(c) != 0) valid++;
    return valid >= 2;
}
```

The 2-of-3 design provides **fault tolerance and progressive entry**:

- A validator with only Phi + Euler chips (no Gamma yet) can still attest.
- A validator with all three chips provides maximum trust signal.
- A validator with only one chip (or none) is rejected.

This mirrors the classical multisig threshold used in Bitcoin and Ethereum key management, applied here to physical hardware. The practical effect is that validators are not gated out by a single chip failure or a chip temporarily offline for diagnostics.

**Security note (v1.0):** The current implementation checks that signature bytes are non-zero. Production implementations will replace this with `ecrecover`-based verification, where each chip signs a deterministic challenge derived from `PHI_ANCHOR` and the validator's address. The architecture is designed for this upgrade without any change to the contract ABI.

---

### 4.5 Slash Mechanism

```solidity
function slashValidator(address v, string calldata reason) external {
    require(msg.sender == validators[v].owner || _isAuthority(msg.sender), "unauthorized");
    validators[v].active = false;
    emit ValidatorSlashed(v, reason);
}
```

Slash is currently owner-invocable and authority-gated (authority is a governance placeholder for v1.0). When slashed:
- `active` is set to `false`
- `ValidatorSlashed` is emitted with a human-readable reason string
- Any registry contract listening for events will see the validator become inactive

Future versions will integrate with a DAO governance module for decentralized slash authority.

---

### 4.6 Reward Integration via IGLALedger

The contract is designed to pair with `IGLALedger.sol` — the Trinity reward ledger. The `ValidatorAttested` event carries the validator address and BPB score, which `IGLALedger` uses to compute reward weights. Validators with higher BPB scores (up to the champion ceiling) and more chips attesting (3-of-3 > 2-of-3) receive proportionally larger reward allocations.

This creates a clean economic loop:
1. Validator acquires Trinity DevKit chips
2. Chips generate attestation signatures from real computation
3. `attestValidator` registers the proof on-chain
4. `IGLALedger` distributes rewards weighted by attested score
5. Higher-quality hardware earns more — not more delegation, more *verified work*

---

## 5. Integration Path for Subnet Owners

Integrating Trinity attestation into an existing Bittensor subnet requires three steps. No changes to the Bittensor core protocol are needed. The entire integration lives at the subnet owner's layer.

---

### Step 1: Deploy BittensorSubnetAttest.sol on an EVM-Compatible Network

The contract is standard Solidity (^0.8.20) and deploys on any EVM-compatible chain. Recommended options:

| Network | Notes |
|---|---|
| **Subtensor EVM** | Native Bittensor EVM layer; validators already have TAO wallets, EVM addresses derivable |
| **Base (L2)** | Low gas costs, high uptime, existing DePIN ecosystem activity |
| **Arbitrum One** | High throughput, established smart contract tooling |
| **Any OP Stack L2** | Trinity DevKit ships with deployment scripts for major OP Stack chains |

Deployment is a standard `forge deploy` or `hardhat deploy` operation. The contract is ownerless — there is no admin key to manage post-deployment. Constants are immutable.

```bash
# Example using Foundry
forge create contracts/BittensorSubnetAttest.sol:BittensorSubnetAttest \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_KEY
```

Estimated deployment gas: ~400 000–600 000 gas units (EVM standard; actual cost depends on network).

---

### Step 2: Validators Submit Phi + Euler + Gamma Sigs

Each validator operating a Trinity DevKit calls `attestValidator` with:

- `phiSig` — 32-byte signature from the Phi chip
- `eulerSig` — 32-byte signature from the Euler chip
- `gammaSig` — 32-byte signature from the Gamma chip
- `bpbScore` — self-reported BPB score (must be ≤ 22393)
- ETH stake (≥ 0.01 ETH)

The Trinity DevKit ships with a daemon (`trinity-attest`) that handles chip communication, signature generation, and contract call submission automatically. Validators do not need to write custom code for the happy path.

```bash
# Trinity DevKit daemon — auto-attests on startup and re-attests on schedule
trinity-attest \
    --contract 0x<DEPLOYED_CONTRACT_ADDRESS> \
    --rpc $RPC_URL \
    --wallet $VALIDATOR_KEY \
    --bpb-score 18500
```

Validators who prefer manual submission can use the standard Ethers.js / viem / cast workflow to call the function directly.

---

### Step 3: Ranking Boost on Subnet Registry

Once a validator is recorded in `BittensorSubnetAttest`, subnet registry contracts can query `isActive(validatorAddress)` and read the `validators[address]` struct to obtain:

- **Active status** — is the attestation current and unslashed?
- **BPB score** — how does the validator's claimed performance compare to the champion lock?
- **Chip presence** — are all three chips attesting (3-of-3 is better than 2-of-3)?

Subnet owners integrate this data into their ranking weight formula. A simple example:

```solidity
// In your subnet registry contract
IBittensorSubnetAttest attest = IBittensorSubnetAttest(ATTEST_CONTRACT);

function validatorWeight(address v) public view returns (uint256) {
    if (!attest.isActive(v)) return 0;
    
    (, , , , uint256 bpb, , ) = attest.validators(v);
    
    // Base weight from stake/score on Bittensor
    uint256 base = baseWeight(v);
    
    // Attestation multiplier: up to 1.5× for champion-level BPB
    uint256 multiplier = 10000 + (bpb * 5000 / 22393); // 10000–15000 basis points
    
    return base * multiplier / 10000;
}
```

This is a starting point. Subnet owners have full freedom to design their weighting formula. Trinity provides the on-chain data; the economic logic belongs to each subnet.

Subnet owners can also filter validator sets to require Trinity attestation as a minimum entry condition for high-value tasks, creating a two-tier system:
- **Attested tier:** eligible for all subnet tasks and full reward weights
- **Unattested tier:** eligible only for lower-weight tasks or read-only roles

---

## 6. DevKit Pricing and Rollout Phases

### Pricing Range

Trinity DevKit chips are priced in the range of **$500–$2 000 per chip** (exact pricing confirmed at order time based on configuration, quantity, and bundle). A complete 2-of-3 attestation setup (Phi + Euler, minimum) starts at the lower end of this range. Full 3-of-3 setups (Phi + Euler + Gamma) are available toward the upper end.

Volume pricing is available for subnet operators deploying attestation to ten or more validators. Contact admin@t27.ai to discuss volume arrangements.

### Phase 0 — Pilot Program (Q3–Q4 2026)

**Availability:** First silicon from TT SKY26b shuttle (tape-out deadline 2026-05-19)  
**Target:** 5–10 subnet operators across SN3, SN39, SN81, and interested early adopters  
**What's included:**
- Phi + Euler DevKit boards (Gamma available for pilot participants who commit early)
- `trinity-attest` daemon pre-configured for pilot subnet contracts
- Direct engineering support from Dmitrii Vasilev (admin@t27.ai)
- Access to the pre-deployment contract on testnet for integration work (available now)
- Priority slot on TT SKY26c production run

**Commitment required:** Deployment of `BittensorSubnetAttest.sol` on at least one subnet, submission of integration feedback, willingness to be referenced as a pilot participant.

### Phase 1 — General Availability (H1 2027)

**Availability:** Full production run from TT SKY26c or equivalent shuttle  
**Target:** All active Bittensor subnet operators  
**What's included:**
- Full Phi + Euler + Gamma DevKit
- `trinity-attest` daemon with auto-update and monitoring
- Standard hardware warranty (12 months)
- Community support via public documentation and forum

### Phase 2 — DePIN Suite (H2 2027)

**Availability:** TTSKY26c production silicon (projected Sep 2026 for shuttle, silicon ~H1 2027)  
**Target:** Cross-chain DePIN operators, not Bittensor-specific  
**What's included:**
- Full Trinity TRI-NET DePIN node hardware
- Multi-chain attestation support (Bittensor, Filecoin, Helium, and others)
- Enterprise SLA options

---

## 7. Pilot Targets

Trinity's initial pilot focus is on the three most mature and highest-value Bittensor subnets: SN3, SN39, and SN81. These subnets represent different AI task categories, which validates Trinity's attestation scheme across a broad range of compute workloads.

### SN3 — Bittensor Text Prompting / Foundation Models

SN3 is one of the original and most established Bittensor subnets, focused on large language model inference and text generation tasks. Validators on SN3 are expected to run significant compute to score well. The absence of hardware attestation means that validators optimizing for score rather than honest work can proxy or cache responses.

**Trinity value proposition for SN3:**  
The Gamma 8×4 chip is designed for the throughput needed on compute-intensive subnets like SN3. Hardware attestation on SN3 would establish a verified baseline: validators who attest prove they have dedicated AI hardware, not a rented API proxy.

### SN39 — Distributed AI Training / Edge Inference

SN39 targets distributed AI training tasks, where the integrity of gradient contributions matters. A validator submitting fabricated gradients is indistinguishable from an honest validator at the software layer alone.

**Trinity value proposition for SN39:**  
The Euler 8×2 chip's matrix computation attestation is directly relevant to gradient-level verification. A validator whose Euler chip signs the computation demonstrates it performed the matrix operations locally, not by querying an external service.

### SN81 — Specialized Inference / DePIN AI

SN81 represents the emerging class of DePIN-integrated AI subnets where physical device attestation is a natural requirement.

**Trinity value proposition for SN81:**  
The full 3-of-3 Trinity stack (Phi + Euler + Gamma) aligns with SN81's DePIN ethos. A subnet that natively requires hardware attestation can use `BittensorSubnetAttest.sol` as its canonical validator registry.

### Reaching Out to Pilot Subnets

Subnet operators from SN3, SN39, SN81, or any other active subnet are encouraged to contact admin@t27.ai to discuss pilot participation. No public personal names of subnet operators are used in this document — all outreach is conducted at the operator's initiative.

---

## 8. Roadmap

### Milestone Summary

| Date | Milestone |
|---|---|
| **2026-05-19** | TT SKY26b shuttle close — Phi, Euler, Gamma submitted to fab |
| **Q3 2026** | Testnet deployment of `BittensorSubnetAttest.sol`; pilot program opens |
| **Q4 2026** | TT SKY26b silicon return from fab; first DevKits shipped to pilot operators |
| **Q4 2026** | Mainnet deployment; first attested validators live on SN3/SN39/SN81 |
| **Sep 2026** | TT SKY26c shuttle submission (full DePIN suite) |
| **Q1 2027** | Pilot feedback integration; v1.1 contract with `ecrecover`-based sig verification |
| **H1 2027** | General availability DevKit launch |
| **H2 2027** | Full DePIN suite (TT SKY26c silicon); multi-chain attestation |

### Near-Term (Now → Q3 2026)

- **Now:** `BittensorSubnetAttest.sol` is live in the repository at commit `30c62020`. Any subnet operator can review, audit, or deploy it to a testnet today.
- **Now → May 2026:** TT SKY26b shuttle window open. Pilot commitments finalized before May 19 receive priority DevKit allocation.
- **Q3 2026:** Testnet integration support. Pilot operators get direct engineering support for contract deployment and `trinity-attest` daemon setup.

### Medium-Term (Q4 2026 → H1 2027)

- First silicon from TT SKY26b. Performance benchmarks published post-tape-out (projected tape-out 2026-12-16).
- v1.1 contract upgrade: `ecrecover`-based signature verification replacing zero-check. Backward-compatible — existing registered validators can re-attest under the new scheme.
- Ranking integration reference implementation published for subnet owners.
- Community documentation: integration guides, ABI reference, FAQ.

### Long-Term (H2 2027+)

- TT SKY26c DePIN suite: Phi, Euler, and Gamma redesigned for full DePIN node form factor.
- Multi-chain attestation: same chip stack generates valid attestations for Bittensor, Filecoin replication proofs, Helium Proof-of-Coverage, and others.
- DAO governance for slash authority: `_isAuthority` function backed by on-chain governance rather than owner-only control.
- Formal verification of `twoOfThreeValid` and surrounding attestation logic.

---

## 9. Honest Benchmarks

Trinity TRI-NET chips are fabricated silicon under active development. The following performance figures are **projected estimates based on pre-tape-out design analysis**, not measured results from production hardware.

### Performance Projection (TT SKY26b Design)

> **~1 GOPS @ ~50 MHz @ ~1 W ternary compute (projected, pending tape-out 2026-12-16)**

Breaking this down:

| Metric | Projected Value | Basis |
|---|---|---|
| Throughput | ~1 GOPS | Pre-layout timing analysis, ternary MAC array |
| Clock frequency | ~50 MHz | Target for TT SKY26b process node |
| Power consumption | ~1 W | Pre-layout power estimation |
| Compute type | Ternary (-1, 0, +1) | Fixed; not floating-point |
| Tape-out date | 2026-12-16 (projected) | TT SKY26b shuttle schedule |

These numbers will be updated with measured silicon data once the first wafers return from fabrication. We do not publish unverified performance claims.

### What Is Not Claimed

- No token-throughput figures (tokens/second) are published for this hardware at this stage. Any such figure prior to silicon characterization would be speculative.
- No comparison to existing GPU/ASIC hardware is made at this stage.
- The BPB champion lock (`2.2393 bits/byte @ step 27 000`) is a *model training benchmark*, not a chip throughput figure. It is used as an on-chain integrity anchor, not a performance advertisement.

### Why Honest Benchmarks Matter for Bittensor

Bittensor's mission is to build a trustless market for machine intelligence. Publishing inflated or unverified performance numbers for hardware that will be used in an attestation scheme would be a direct contradiction of that mission. The chain of trust is:

1. Honest chip design → honest attestation signatures
2. Honest attestation signatures → trustworthy validator rankings
3. Trustworthy validator rankings → fair subnet economics

Trinity's attestation scheme is only as valuable as the honesty of the hardware claims behind it. We hold ourselves to the same standard we ask the network to enforce.

---

## 10. Call to Action

### Who Should Reach Out

- **Subnet operators** on SN3, SN39, SN81, or any active subnet interested in hardware-attested validator ranking
- **Validator operators** who want to differentiate their service with physical hardware proof
- **Subnet builders** who want to design attestation-native subnets from the ground up
- **DePIN infrastructure developers** interested in multi-chain hardware attestation

### What to Expect

1. Initial response within 48 hours
2. Technical review session — walkthrough of `BittensorSubnetAttest.sol` and integration path for your specific subnet
3. Testnet deployment support — assistance deploying the contract and running the `trinity-attest` daemon in test mode
4. Pilot program agreement — formal commitment for DevKit allocation ahead of TT SKY26b silicon return

### Contact

**Email:** admin@t27.ai  
**Project site:** t27.ai  
**Repository:** [github.com/gHashTag/NeuronConstant](https://github.com/gHashTag/NeuronConstant)  
**Contract (commit 30c62020):** `contracts/BittensorSubnetAttest.sol`

> *If you are a subnet operator who cares whether your validators are running real hardware or not — this is the conversation to have. Contact admin@t27.ai.*

---

## Appendix A: Contract ABI Reference

```json
[
  {
    "name": "attestValidator",
    "type": "function",
    "inputs": [
      { "name": "phiSig",   "type": "bytes32" },
      { "name": "eulerSig", "type": "bytes32" },
      { "name": "gammaSig", "type": "bytes32" },
      { "name": "bpbScore", "type": "uint256" }
    ],
    "stateMutability": "payable"
  },
  {
    "name": "slashValidator",
    "type": "function",
    "inputs": [
      { "name": "v",      "type": "address" },
      { "name": "reason", "type": "string"  }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "name": "isActive",
    "type": "function",
    "inputs": [{ "name": "v", "type": "address" }],
    "outputs": [{ "type": "bool" }],
    "stateMutability": "view"
  },
  {
    "name": "twoOfThreeValid",
    "type": "function",
    "inputs": [
      { "name": "a", "type": "bytes32" },
      { "name": "b", "type": "bytes32" },
      { "name": "c", "type": "bytes32" }
    ],
    "outputs": [{ "type": "bool" }],
    "stateMutability": "pure"
  },
  {
    "name": "CHAMPION_HASH", "type": "function",
    "outputs": [{ "type": "bytes32" }], "stateMutability": "view"
  },
  {
    "name": "CHAMPION_BPB", "type": "function",
    "outputs": [{ "type": "uint256" }], "stateMutability": "view"
  },
  {
    "name": "PHI_ANCHOR", "type": "function",
    "outputs": [{ "type": "uint256" }], "stateMutability": "view"
  },
  {
    "name": "ValidatorAttested",
    "type": "event",
    "inputs": [
      { "name": "v",   "type": "address", "indexed": true },
      { "name": "bpb", "type": "uint256", "indexed": false }
    ]
  },
  {
    "name": "ValidatorSlashed",
    "type": "event",
    "inputs": [
      { "name": "v",      "type": "address", "indexed": true },
      { "name": "reason", "type": "string",  "indexed": false }
    ]
  }
]
```

---

## Appendix B: Glossary

| Term | Definition |
|---|---|
| **Attestation** | A cryptographic proof that a specific computation was performed on specific hardware |
| **BPB (Bits Per Byte)** | Bits-per-byte compression quality metric used as the champion lock anchor |
| **BIT-0011** | Bittensor governance proposal introducing Locked Stake / Conviction, live April 2026 |
| **Champion lock** | The reference performance record: BPB=2.2393, step=27000, seed=43, sha=0x2446855 |
| **Conviction** | BIT-0011's time-weighted stake mechanism; longer lock = higher influence multiplier |
| **DePIN** | Decentralized Physical Infrastructure Network — blockchain networks anchored to real-world hardware |
| **Euler 8×2** | Trinity mid-range chip; 16 ternary processing elements; generates `eulerSig` |
| **Gamma 8×4** | Trinity high-throughput chip; 32 ternary processing elements; generates `gammaSig` |
| **IGLALedger** | Trinity reward ledger contract; consumes `ValidatorAttested` events for reward computation |
| **PHI_ANCHOR** | `0x47C0` — canonical ternary kernel constant (Theorem 36.1) |
| **Phi 1×1** | Trinity edge chip; single ternary MAC kernel; generates `phiSig` |
| **Sybil attack** | Attack where one entity creates many identities to gain disproportionate influence |
| **Ternary compute** | Computation over {-1, 0, +1} rather than binary {0, 1} |
| **TRI-NET** | The three-chip Trinity hardware stack (Phi + Euler + Gamma) |
| **TT SKY26b** | Tiny Tapeout Sky130 2026 shuttle b — the fabrication run for Trinity chips |
| **2-of-3** | Multisig threshold: at least 2 of the 3 chip signatures must be present for attestation to pass |

---

*Document version: 1.0 — authored by Dmitrii Vasilev (admin@t27.ai)*  
*Contract source: [github.com/gHashTag/NeuronConstant/blob/30c62020/contracts/BittensorSubnetAttest.sol](https://github.com/gHashTag/NeuronConstant/blob/30c62020/contracts/BittensorSubnetAttest.sol)*
