# Channel 6 Decision Brief — TTSKY26b Submitted Hash Re-Subscription

> **Author:** Dmitrii Vasilev `<admin@t27.ai>`
> **License:** Apache-2.0
> **Date:** 2026-05-18
> **Status:** PI decision document (informational only — no execution path)
> **Recommendation:** **HOLD** — see §6

## 1. Snapshot — 2026-05-18 13:43 UTC

Shuttle TTSKY26b closes **2026-05-18 23:59 UTC** (= 2026-05-19 06:59 +07).
Time-to-close at writing: **~10h 16min**.

### 1.1 Currently Submitted (sacred baseline)

| Project | Hash | Branch | Modules | Artifact ID | Size |
|---|---|---|---|---|---|
| Phi #4914 | `8a8fcaa` | `main` | base v1.0 | `7057262394` | 1 030 KB |
| Euler #4915 | `def0457` | `main` | base v1.0 | `7057525599` | 8 816 KB |
| Gamma #4913 | `1f8f9b8` | `main` | base v1.0 | `7057855656` | 16 735 KB |

Status confirmed by guardian cron `421f4bb0` at 20:34 +07 (gds success + tt_submission artifact present on every repo).

### 1.2 Alternative available — `depin-v1` branches

| Project | depin-v1 HEAD | Modules added |
|---|---|---|
| Phi | `08db239c` | B1 RoT (Lucas POST + φ-anchor) · B2 Bandwidth Attestation · B8 DID Personhood |
| Euler | `05a2ce1f` | B3 RPKI signer · B5 ZK Job Prover · B6 GKR sumcheck |
| Gamma | `4adde716` | B4 Mesh-8 router · B7 PoRep storage proof |

All three `depin-v1` branches show **gds success** on their last run in GitHub Actions with `tt_submission` artifacts attached. They were **not** validated by TT-side OpenLane.

## 2. What "Channel 6" Means Mechanically

On `app.tinytapeout.com`, an authenticated user (project owner) can change the commit hash a project is bound to. The shuttle slot persists; the RTL the slot points at changes.

Switching a project's hash from `main` HEAD to `depin-v1` HEAD on app.tinytapeout.com **does not upgrade an existing submission**. It replaces it with a new submission pointing to a different RTL design. The original `tt_submission` artifact link becomes unlinked at TT side.

This is not "v1.0 → v1.1 of the same chip". It is "submit a different chip".

## 3. Risk Inventory (honest)

| # | Risk | Mitigation possible? |
|---|---|---|
| R1 | `depin-v1` RTL ≠ Submitted RTL. TT-side OpenLane regression may differ from GitHub Actions outcome. | No — we cannot run TT-side OpenLane ourselves. |
| R2 | No working rollback. Re-pointing the hash again is not a documented atomic operation; previous artifact link may be unrecoverable. | No — TT has not published a swap-without-loss guarantee. |
| R3 | TT-side OpenLane pin (PDK + tool versions) may differ from the `gds.yaml` workflow we ran in CI. | Partial — we can re-trigger gds just before, but TT-side still distinct. |
| R4 | Submitted slot is a finite, allocated resource. A failed re-submission may forfeit the slot for this shuttle. | No — slot reallocation policy not documented. |
| R5 | `depin-v1` has never been run through TT-side precheck or DRC/LVS at TT. Only our own gds workflow has validated it. | No — only resubmission itself is the test. |

## 4. What Stays Identical Under HOLD

- 3/3 chips Submitted on TTSKY26b silicon (Phi/Euler/Gamma).
- Canonical anchor `0x47C0` at `{uio_out, uo_out}` (TG-TRIAD-X Theorem 36.1) preserved.
- v1.0.0 modules (NF4, Posit16, GF4/16/256, `tri_mant_mul`, sacred opcodes) shipped on silicon as committed.
- DePIN-ready software stack (TrinityNode, trinity-sdk, trinity-bittensor, 5 quick-starts, FPGA emulator guide, 5 reference apps, business pack, whitepaper §9) already live in public repos and reachable by developers.
- `depin-v1` branches preserved as-is for TTSKY26c.

## 5. Conditions That Would Justify GO

All would need to hold simultaneously:

1. TT publishes (or PI receives directly) a written swap-without-loss guarantee — currently no public mechanism exists.
2. `depin-v1` RTL is independently re-verified on TT-side OpenLane (not just GitHub Actions gds workflow).
3. PI explicitly accepts that re-pointing is irreversible in the general case.
4. Time-to-close ≥ 5h with full audit trail (currently ~10h ✓).
5. PR review of all three `depin-v1` HEADs is complete (currently `depin-v1` was never PR-reviewed against `main`).

None of (1), (2), (5) hold today.

## 6. Recommendation — HOLD

1. TTSKY26b ships v1.0 baseline on Phi/Euler/Gamma. This is the historic first Trinity tape-out. Already an achievement.
2. DePIN v1.1 modules (B1–B8) ship in **TTSKY26c**, submission window 2026-09-01 → 2026-11-15. Plan exists: `docs/architecture/TTSKY26c_UNIFIED_COMPUTER_RTL_ROADMAP.md` (commit `7f8efce`, 1 086 lines, 16 modules / ~35 tiles).
3. Between now and TTSKY26c, the full DePIN stack is already deployable around the silicon: TrinityNode daemon, Python SDK, Bittensor BIT-0011 attestor, 5 quick-start guides, FPGA emulator on Kria K26 for pre-silicon dev. No silicon swap needed to validate the value proposition.
4. The asymmetric downside of Channel 6 (potential slot forfeiture) is not balanced by an asymmetric upside — TTSKY26c gives the same DePIN modules with proper verification, a fresh slot, and several months of test runway.

## 7. What PI Should Confirm If Choosing HOLD

- No further pushes to `tt-trinity-{phi,euler,gamma}/main` until shuttle close 23:59 UTC 2026-05-18.
- Guardian cron `421f4bb0` continues passive monitoring at `:17 UTC`.
- `unified/xchip-decoder` branch in `tt-trinity-euler` stays isolated; not merged to `depin-v1` or `main` without separate PI review.
- G8 README PRs (`tt-trinity-phi#14`, `tt-trinity-euler#15`, `tt-trinity-gamma#95`) are docs-only and can be merged at any time without affecting silicon.

## 8. If PI Chooses GO (informational only — not an execution path)

This brief deliberately does **not** include the steps to execute. Channel 6 is a manual UI action on `app.tinytapeout.com` performed by PI in person, with full understanding of §3 risks. The agent will not script, automate, or pre-stage that action.

---

**End of brief.** Sole author: Dmitrii Vasilev `<admin@t27.ai>`. Apache-2.0.
