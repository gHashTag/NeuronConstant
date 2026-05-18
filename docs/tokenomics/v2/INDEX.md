# Trinity TRI-NET — Tokenomics v2 (3^27) Pack

**Author:** Dmitrii Vasilev (PI, t27.ai)
**Date:** 2026-05-18
**Status:** FINAL — supply locked at 3^27 = 7,625,597,484,987 TRI

---

## Final Tokenomics Decision (LOCKED)

| Parameter | Value |
|---|---|
| **Total Supply** | **7,625,597,484,987 TRI** = **3^27** (ternary-exact) |
| **Decimals** | 18 |
| **Pre-mine** | 0% |
| **Founder allocation** | 0% |
| **Investor allocation** | 0% |
| **Treasury** | 0% |
| **Airdrop** | 0% |
| **Mineable via chip ZK proofs** | 100% |
| **Halvings** | 9, every 4 years |
| **Era 0 reward** | 1000 TRI per ZK proof |
| **Networks** | Base L2 + Bittensor EVM + Solana SPL |
| **Honest benchmark** | ~1 GOPS @ ~50 MHz @ ~1W ternary (projected, pending tape-out 2026-12-16) |

---

## Document Index

### Core Tokenomics (10 numbered specs)

| # | File | Topic | Lines |
|---|---|---|---|
| 00 | [00_MANIFESTO_FAIR_LAUNCH.md](./00_MANIFESTO_FAIR_LAUNCH.md) | Fair-launch manifesto, ethos, mining-only mandate | 475 |
| 01 | [01_TOTAL_SUPPLY_3_27.md](./01_TOTAL_SUPPLY_3_27.md) | Why 3^27 — ternary-exact justification, math, comparisons | 1068 |
| 02 | [02_EMISSION_CURVE_36_YEARS.md](./02_EMISSION_CURVE_36_YEARS.md) | 9-halving curve over 36 years, era table, supply projection | 734 |
| 03 | [03_BANK_DISTRIBUTION_27_REGISTERS.md](./03_BANK_DISTRIBUTION_27_REGISTERS.md) | 27 chip-bank distribution rationale | 699 |
| 04 | [04_SUB_UNITS_COPTIC.md](./04_SUB_UNITS_COPTIC.md) | Coptic sub-unit nomenclature, ternary fractions | 729 |
| 05 | [05_BITCOIN_COMPARISON.md](./05_BITCOIN_COMPARISON.md) | BTC vs TRI side-by-side: supply, halving, ASIC vs ZK-proof | 458 |
| 06 | [06_GLOBAL_INTERNET_CAPACITY.md](./06_GLOBAL_INTERNET_CAPACITY.md) | TRI throughput vs global ZK-proof demand projections | 843 |
| 07 | [07_PRICE_SCENARIOS.md](./07_PRICE_SCENARIOS.md) | Scenario analysis (bear / base / bull / moonshot) | 626 |
| 08 | [08_BURN_MECHANICS.md](./08_BURN_MECHANICS.md) | Burn paths (Tier-1/2/3), velocity sinks, hard-cap economics | 810 |
| 09 | [09_LEGAL_DEFENSE.md](./09_LEGAL_DEFENSE.md) | SEC/MiCA Howey-test defence, sufficiently-decentralised arguments | 643 |

### Supporting Documents

| File | Purpose | Lines |
|---|---|---|
| [TRI_TOKENOMICS_WHITEPAPER_v2.md](./TRI_TOKENOMICS_WHITEPAPER_v2.md) | Full whitepaper v2 — supersedes sprint/TRI_TOKENOMICS_WHITEPAPER.md | 449 |
| [MIGRATION_NOTES_v1_to_v2.md](./MIGRATION_NOTES_v1_to_v2.md) | Why 1B → 3^27, breaking changes vs v1 | 171 |
| [PI_REVIEW_NOTES.md](./PI_REVIEW_NOTES.md) | PI editorial notes / pending decisions | 111 |
| [TWITTER_LAUNCH_THREAD.md](./TWITTER_LAUNCH_THREAD.md) | Public announcement draft (10 tweets, fair-launch narrative) | 168 |

### Smart Contracts

Located at [../../contracts/v2/](../../contracts/v2/):

| Contract | Purpose | Lines |
|---|---|---|
| [TriToken.sol](../../contracts/v2/src/TriToken.sol) | ERC-20 with hard cap 3^27 × 10^18, no minter except MiningPool | 126 |
| [MiningPool.sol](../../contracts/v2/src/MiningPool.sol) | Era logic, halving schedule, claimReward gated by Groth16 verifier | 370 |
| [EmissionController.sol](../../contracts/v2/src/EmissionController.sol) | Era 0..8 reward table, halving math | 118 |
| [TriToken.t.sol](../../contracts/v2/test/TriToken.t.sol) | Foundry tests for hard cap, mint authority, decimals | 184 |

**Deploy targets:** Base Sepolia (testnet) → Base mainnet + Bittensor EVM + Solana SPL bridge (Q4 2026).

---

## Cross-References

- **Hardware proof system:** [docs/zk/](../../zk/) — Groth16 verifier outline + BN254 field arithmetic
- **Champion lock invariant:** BPB=2.2393, step=27000, seed=43, sha=2446855 (Theorem 36.1)
- **TT SKY26b shuttle artifacts:** phi `7056162644`, euler `7056438152`, gamma `7056692733` (Submitted 2026-05-18)
- **DePIN v1 RTL:** [docs/v1.1/](../../v1.1/) — B1-B9 module specs for next shuttle (TTSKY26c)
- **Bittensor onramp:** [docs/sales/BITTENSOR_PITCH.md](../../sales/BITTENSOR_PITCH.md)

---

## Sole Authorship

Project author: **Dmitrii Vasilev** (PI, admin@t27.ai). No co-authors. All RTL, tokenomics, contracts, and documentation authored solely by the PI.

DOI: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

---

*Trinity TRI-NET tokenomics v2 — fair launch, mineable-only, hard cap 3^27.*
