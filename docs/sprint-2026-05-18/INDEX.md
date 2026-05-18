# Sprint 2026-05-18 — TT SKY26b Submit Day Deliverables

This directory holds 29 technical, business, and regulatory documents written during the parallel sprint on 2026-05-18, while the Trinity Triad (`tt-trinity-{phi,euler,gamma}`) was being submitted to the Tiny Tapeout SKY26b shuttle.

## Hardware & Silicon
- `M1_HW_ROOT_OF_TRUST_SPEC.md` — hardware root-of-trust RTL spec (1417 lines)
- `M9_BITTENSOR_SUBNET_VALIDATOR_ARCH.md` — Bittensor subnet validator (1167 lines)
- `IHP26B_PORT_SPEC.md` — IHP-SG13G2 port spec (728 lines)
- `TRINITY_NODE_HW_KIT_BOM.md` — $200 BOM + mainnet plan (712 lines)
- `TRINITY_DEVKIT_PRO_ROADMAP.md` — productized SBC roadmap (TBD pending subagent)
- `TRINITY_DEVKIT_PRO_PINOUT.md` — full pinout reference (TBD)
- `COMPETITIVE_SBC_2026.md` — vs Pi AI HAT+ 2 / Jetson / Coral / Khadas (TBD)

## Software
- `SOFTWARE_STACK_PLAN.md` — Trinity Compiler + tinytrinity SDK plan (TBD)
- `TRINITY_MODEL_ZOO_30_MODELS.md` — 30-model port specifications (TBD)
- `TRINITY_PROTOCOL_V1_SPEC.md` — RFC-style wire protocol (TBD)

## Protocol & Bridge
- `FILECOIN_IPFS_INTEGRATION_SPEC.md` — Filecoin storage layer (815 lines)
- `CROSS_CHAIN_BRIDGE_SPEC.md` — LayerZero + Wormhole + L2 (1030 lines)
- `HELIUM_POC_REPLACEMENT_ARCH.md` — HW-PoC vs Helium gaming (601 lines)

## Theory & Math
- `GLAVA_37_THEOREM_CHAPTER.md` — 14 theorems, 5 conjectures (867 lines)
- `COQ_MECHANIZATION_SCAFFOLD.md` — formal mechanization roadmap (987 lines)
- `TRINITY_INTEGRATIVE_PAPER_DRAFT.md` — bioRxiv-format paper (635 lines)

## Tokenomics & Governance
- `TRI_TOKENOMICS_WHITEPAPER.md` — $TRI utility token (436 lines)
- `OSHWA_CERTIFICATION_AND_GOVERNANCE_PACK.md` — OSHWA + TriDAO (914 lines)

## Regulatory & Grants
- `DARPA_RACE_WHITEPAPER.md` — tactical-edge AI ($12M ask, 332 lines)
- `DARPA_OPTIMA_WHITEPAPER.md` — 66-format numeric zoo ($8M ask, 363 lines)
- `DARPA_AIE_M1_WHITEPAPER.md` — HW root-of-trust ($2.5M ask, 371 lines)
- `NSF_SBIR_PHASE_I_DRAFT.md` — NSF $305K Phase I (453 lines)
- `EU_HORIZON_EIC_ACCELERATOR_DRAFT.md` — €2.5M grant + €15M equity (388 lines)
- `EU_AI_ACT_COMPLIANCE_PACK.md` — Reg 2024/1689 mapping (689 lines)
- `AISI_SUBMISSION_DRAFT.md` — UK/US AISI HW-anchored evals (387 lines)
- `CLARA-DEPIN-ADDENDUM-2026-05.md` — DARPA CLARA addendum (mirrored to trinity-clara)

## Investor & Audit
- `INVESTOR_PITCH_DECK_OUTLINE.md` — 12-slide $5M seed pitch (257 lines)
- `PRESS_RELEASE_TT_SKY26B_LAUNCH.md` — EN+RU bilingual PR (99 lines)
- `SECURITY_AUDIT_RFP_PACKAGE.md` — ToB/Zellic/Spearbit RFP (529 lines)
- `REPRODUCIBILITY_PACKAGE_MANIFEST.md` — Zenodo update manifest (743 lines)

## Operator-facing
- `TRINITY_OPERATOR_ONBOARDING_RU.md` — Russian operator guide (434 lines)

## Earlier in sprint (already in main NeuronConstant docs/)
- `DEPIN_DECENTRALIZED_INTERNET_GAPS.md` — 7 gaps + 9 modules
- `DECENTRALIZED_INTERNET_USE_CASES.md` — 21 use cases
- `SUBMIT_BRIEFINGS.md` — submission briefings
- `ZENODO_UPDATE_DRAFT.md` — DOI update draft

## Hard invariants preserved across all docs
- R-SI-1: zero standalone `*` operators in synth RTL
- Anchor 0x47C0 at `{uio_out, uo_out}` after reset
- v1.0.0 AI format modules (NF4, Posit16, GF4/16/256, tri_mant_mul, sacred opcodes) — co-authored by Claude Opus 4.6, preserved
- Apache-2.0 RTL / CC-BY-4.0 docs / CC-BY-SA-4.0 GDS licensing
- Lucas POST mandatory boot check

## Owner
- PI: Dmitrii Vasilev <bayotkwolpep9c@hotmail.com>
- Co-author (v1.0.0 modules): Claude Opus 4.6 (Anthropic)
- Zenodo DOI: 10.5281/zenodo.19227877
