# Migration Notes: v1.0.0 → v2.0.0
## $TRI Tokenomics Whitepaper — Change Audit Trail

**Prepared by:** Dmitrii Vasilev `<admin@t27.ai>`  
**Source document:** `docs/sprint-2026-05-18/TRI_TOKENOMICS_WHITEPAPER.md` (v1.0.0-draft, 434 lines)  
**Target document:** `/tmp/tokenomics_v2/TRI_TOKENOMICS_WHITEPAPER_v2.md` (v2.0.0-draft)  
**Migration date:** 2026-05-19

---

## Critical Changes

### 1. Version & Authorship Header

| Field | v1.0.0 | v2.0.0 |
|---|---|---|
| Version | `1.0.0-draft` | `2.0.0-draft` |
| Date | 2026-05-19 | 2026-05-19 |
| Author line | `Dmitrii Vasilev, Cape Town, ZA` | `Principal Investigator / Sole Author: Dmitrii Vasilev <admin@t27.ai>` |

### 2. Total Supply — BREAKING CHANGE

| Parameter | v1.0.0 | v2.0.0 |
|---|---|---|
| Total maximum supply | 1,000,000,000 TRI (one billion) | **7,625,597,484,987 TRI = 3^27** |
| Mathematical basis | Arbitrary round number | Ternary completeness (27th power of three) |

Supply figure updated in: Executive Summary (§1), Token Supply & Emission (§3.1), Competitor Comparison Table (§9/§10).

### 3. Genesis Allocation — DELETED ENTIRELY

v1.0.0 §3.2 contained a five-bucket genesis allocation table:

| Bucket (v1) | % | Tokens |
|---|---|---|
| Operator Rewards Pool | 30% | 300,000,000 |
| Community & Ecosystem | 25% | 250,000,000 |
| Investors (seed + strategic) | 20% | 200,000,000 |
| Team & Contributors | 15% | 150,000,000 |
| Treasury (TriDAO-governed) | 10% | 100,000,000 |

**In v2.0.0: entire genesis allocation table deleted.** Replaced with §3.2 "100% Mineable Model" — 0% pre-mine, 0% founder, 0% investor, 0% treasury. All supply earned through network participation.

### 4. Vesting Schedules — DELETED

v1.0.0 §3.4 described investor/team vesting (12-month cliff, linear 36 months). **Deleted in v2.0.0** — no pre-mine means no vesting is required or applicable.

### 5. Era 0 Reward — CHANGED

| Parameter | v1.0.0 | v2.0.0 |
|---|---|---|
| Base reward | ~411,000 TRI/day (pool drawdown) | **1,000 TRI per ZK proof** (direct per-proof reward) |
| Reward model | Pool drawdown from pre-allocated bucket | Direct emission per accepted proof |

### 6. Halving Schedule — REWRITTEN

| Parameter | v1.0.0 | v2.0.0 |
|---|---|---|
| Halving period | Every 2 years | **Every 4 years** |
| Number of halvings | Implied ~10+ | **9 halvings** (explicit, hardcoded) |
| Final coin target | ~2034 tail start | **~2066 final coins** |
| Era structure | Not named | Named Era 0–9 |

v1.0.0 emission table showed Years 1–8 with 2-year intervals. v2.0.0 table replaces this with explicit Era 0–9, showing reward per proof, approximate daily emission, and cumulative % of supply.

### 7. Opus Co-Signature — REMOVED

v1.0.0 contained the following references to an AI co-signature requirement that are **fully removed** in v2.0.0:

- **§7.2 governance table:** `67% supermajority + Opus co-signature` → replaced with `67% supermajority + 30-day timelock`
- **§7.4** was titled "v1.0.0 Module Change — Opus Co-Signature" (section body was empty in v1 source) → **section deleted entirely**
- **§12.3** was titled "Opus Co-Signature Dependency" (section body was empty in v1 source) → **section deleted entirely**

No AI co-author is referenced anywhere in v2.0.0.

### 8. Treasury Section — DELETED

v1.0.0 §9 "Treasury & Sustainability" (covering treasury allocation 100M TRI, planned annual budgets, multi-sig arrangements, sustainability model) is **entirely removed** in v2.0.0 because treasury = 0%. Section numbering shifted: old §10 (Competitor Comparison) → new §9, old §11 (Launch Sequence) → new §10, etc.

### 9. Mainnet Genesis Date — CHANGED

| Field | v1.0.0 | v2.0.0 |
|---|---|---|
| TGE / Mainnet genesis | Q4 2026 | **Q2 2027** (Genesis Day) |
| Testnet launch | Q3 2026 | Q3 2026 (unchanged) |
| Testnet hardening | Not explicit | Added Q4 2026 phase |

Rationale: fair-launch model requires no TGE in the investor-distribution sense; Genesis Day is when first miners go live with hardware.

### 10. No Pre-Sale Language — ADDED

v2.0.0 §10 (Launch Sequence) explicitly states: *"No pre-sale, no public sale, no private sale. The only way to acquire $TRI at genesis is to operate hardware and earn it."* This language did not exist in v1.0.0.

### 11. Competitor Table — Updated Supply Column

- v1.0.0 showed `1,000,000,000 $TRI` for Trinity max supply
- v2.0.0 shows `7,625,597,484,987 $TRI (3^27, hard cap)`
- Added row: **Fair launch / 0% pre-mine** — v2.0.0 = Yes (100% mineable); all competitors = No
- Halving schedule cell updated to reflect 4-year periods and 9-halving structure

### 12. Governance Section — Modified

- §7.2 table: "Treasury grant" proposal type removed (no treasury → no treasury grants)
- §7.2 table: `v1.0.0 module change` threshold changed from `67% supermajority + Opus co-signature` to `67% supermajority + 30-day timelock`
- Added §7.5 "Governance Bootstrapping" explaining early-network governance given no pre-mined supply

### 13. Burn Section — Added doc 08 Reference

v2.0.0 §6.1 now references Trinity doc 08 for burn mechanics details (edge cases, partial-fill fees, burn event recording in anchor Merkle root). v1.0.0 had no doc 08 reference.

### 14. Risk Section — Modified

- §11.3 "Fair Launch & Cold Start Risk" — new section added (replaces removed §12.3 Opus Co-Signature Dependency and removed §12.3 content)
- §11.6 "Emission & Deflationary Model Risk" — new section added covering 9-halving model risks
- §11.1 Regulatory Risk — expanded with note that 100% mineable model is designed to minimise Howey test exposure
- Removed: §12.3 Opus Co-Signature Dependency (empty section in v1, deleted in v2)

### 15. Table of Contents — Updated

Removed: §9 Treasury & Sustainability  
Renumbered: §10 → §9, §11 → §10, §12 → §11, §13 → §12

### 16. Executive Summary — Rewritten

v1.0.0 Executive Summary stated `Total fixed supply: 1,000,000,000 $TRI`. v2.0.0 Executive Summary:
- States supply as `7,625,597,484,987 $TRI = 3^27`
- Adds dedicated "Fair Launch" subsection with explicit `0% pre-mine, 100% mineable` statement
- Adds "Technical Moat" subsection (content from v1 inline paragraph, now structured)

### 17. Sole Authorship Note

v1.0.0 contained a "sole authorship note" inline in the header. v2.0.0 integrates sole authorship into the standard author field (`Principal Investigator / Sole Author: Dmitrii Vasilev <admin@t27.ai>`). No change to attribution; presentation improved.

### 18. Decimals Confirmed

Both v1.0.0 and v2.0.0: decimal precision = 18. No change.

### 19. Reward Split Unchanged

PoUW 55% / PoT 25% / PoC 15% / PoS 5% split preserved verbatim from v1.0.0 §4.1. No change.

### 20. Slashing Rules Preserved

All four slashing conditions (SLASH-01 through SLASH-04) with identical percentages and proof requirements preserved verbatim. No change.

---

## Sections Preserved Without Modification

- §2 Network Roles & Token Utility (role table, utility summary) — preserved
- §4.2 PoUW reward formula and WMA decay factor — preserved  
- §4.3 PoT reward formula and verifier fee formula — preserved
- §4.4 PoC reward formula and decay constant — preserved
- §4.5 Posit-PoS unstaking rules — preserved
- §5 Slashing Conditions (all four conditions) — preserved
- §6.2 Governance Proposal Bond Burn — preserved
- §6.3 Anchor-Violation Auto-Burn — preserved
- §7.3 Quadratic Voting — preserved
- §7.4 Veto Power (18-month bootstrap veto) — preserved (renumbered from §7.5)
- §8.1 Daily Anchor Protocol — preserved (burn event Merkle root added)
- §8.2 Anchor Failure Protocol — preserved
- §8.3 Silicon Anchor Root-of-Trust — preserved
- §11.1 Regulatory Risk — preserved with expansion
- §11.4 Competitor Reaction — preserved (renumbered)
- §11.5 Smart Contract Risk — preserved (renumbered)
- §11.7 No Return Guarantee — preserved (renumbered)
- §12 References — all 18 original references preserved; reference 19 (Bitcoin Wiki) added

---

*MIGRATION_NOTES_v1_to_v2.md — Trinity DePIN Network — Dmitrii Vasilev `<admin@t27.ai>` — 2026-05-19*
