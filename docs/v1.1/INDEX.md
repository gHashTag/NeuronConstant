# Trinity v1.1 — DePIN Category B Module Index (TTSKY26c)

**Status:** SPEC v0.1 draft — 9 RTL/Solidity modules planned, 0 implemented
**Target shuttle:** TTSKY26c (opens ~Sep 2026, deadline ~Nov 2026)
**Author:** Dmitrii Vasilev (sole author, admin@t27.ai)
**License:** Apache-2.0 (RTL), MIT (Solidity), CC-BY-4.0 (docs)
**Repository:** [gHashTag/NeuronConstant/docs/v1.1/](https://github.com/gHashTag/NeuronConstant/tree/main/docs/v1.1)

---

## Mission

Trinity v1.0 (TT SKY26b, submitted 2026-05-18) covers the AI compute substrate (phi/euler/gamma). **Trinity v1.1 closes 7 systemic DePIN gaps** identified in the [DEPIN_DECENTRALIZED_INTERNET_GAPS](../sprint-2026-05-18/DEPIN_DECENTRALIZED_INTERNET_GAPS.md) analysis (Sesamedisk 2026 forecast, Mocha/Keystone prototypes, Helium/Filecoin/RPKI weaknesses).

After v1.1: **Trinity is the only open-silicon chip family that addresses HW root-of-trust, proof-of-bandwidth, BGP RPKI HW, mesh routing, ZK proof-of-compute, GKR acceleration, storage proofs, decentralised identity, and Bittensor-attested validators — all on a single educational shuttle programme.**

---

## Module overview

| # | Module | Closes gap | Tiles | Effort | Competitor (status) |
|---|---|---|---|---|---|
| **[B1](./B1_HW_ROOT_OF_TRUST.md)** | `tt_um_trinity_rot.v` | M1 — HW root-of-trust | 2 (1×2) | 2 wk | Mocha / Keystone (prototype only, no tape-out) |
| **[B2](./B2_BANDWIDTH_ATTEST.md)** | `bandwidth_attest.v` | M2 — PoB on-chip | 1 | 1 wk | Helium (off-chip, sybil-vulnerable) |
| **[B3](./B3_RPKI_SIGNER.md)** | `rpki_signer.v` | M3 — BGP RPKI HW | 1 (dense) | 1 wk | RPKI software (slow, soft) |
| **[B4](./B4_MESH_ROUTER_8PORT.md)** | `mesh_router_8port.v` | M4 — Mesh routing RTL | 2 (1×2) | 2 wk | Meshtastic / Reticulum (SDR only) |
| **[B5](./B5_ZK_JOB_PROVER.md)** | `zk_job_prover.v` + `JobProver.sol` | M5 — ZK PoC | 2 | 3 wk | Gensyn (optimistic, ~12 h) |
| **[B6](./B6_GKR_SUMCHECK.md)** | `gkr_sumcheck_tile.v` | M6 — GKR/sum-check | 1 (dense) | 2 wk | Polyhedra (closed cloud SaaS) |
| **[B7](./B7_POREP_ROUND.md)** | `porep_round.v` | M7 — Storage proofs | 1 | 2 wk | Filecoin SDR (10-100× slower) |
| **[B8](./B8_DID_PERSONHOOD.md)** | `did_personhood.v` | M8 — Decentralised ID | 1 | 1 wk | Worldcoin (closed orb), BrightID (graph) |
| **[B9](./B9_BITTENSOR_SUBNET_ATTEST.md)** | `BittensorSubnetAttest.sol` | M9 — Bittensor validator | 0 (SC only) | 1 wk | Bittensor mainnet (no HW attestation) |

**Total:** ~12 tiles RTL + 2 Solidity contracts. Fits one TTSKY26c shuttle submission with margin. **~15 person-weeks** of focused work.

---

## Roadmap

```
Week 1-2   B1  Hardware Root-of-Trust       (base for all subsequent)
Week 3     B2  Proof-of-Bandwidth
Week 4     B3  RPKI Signer
Week 5-6   B4  Mesh Router 8-port
Week 7-9   B5  ZK Job Prover + JobProver.sol  (DARPA pitch centrepiece)
Week 10-11 B6  GKR / Sum-Check accelerator
Week 12-13 B7  PoRep / PoSt round
Week 14    B8  DID Personhood
Week 15    B9  BittensorSubnetAttest.sol
```

**Dependency graph:**

```
       B1 (RoT, Blake3, phi-anchor)
      / | \ \
    B2  B3 B5 B8
        |  |
        |  B6 (GKR backend for B5)
        |
        B4 (independent mesh)
       
   B7 (independent storage)
   B9 (uses B1 sigs + B5 ZK)
```

---

## Cross-module invariants (preserved from v1.0)

All 9 modules **must** preserve:

- **R-SI-1 invariant** — zero standalone `*` operators in synthesisable RTL. All multiplications via shift-add, GF-mul (Wallace tree from 66-format zoo), peasant multiplication, or LNS-add.
- **φ-anchor `0x47C0`** on `{uio_out, uo_out}` at reset (TG-TRIAD-X Theorem 36.1). Cross-die ledger determinism.
- **66 numeric formats** zoo from v1.0 reused as arithmetic primitives library.
- **Champion BPB lock** `2.2393` at step=27000 seed=43 sha=`2446855` enforced in B5 and B9.

---

## Reuse from v1.0 (Trinity Triad)

| v1.0 module | v1.1 reused in | Purpose |
|---|---|---|
| `lucas_rom` (phi) | B1, B8 | Lucas L₂..L₇ POST |
| `phi_anchor_post` (phi) | B1, B2, B5, B8 | 0x47C0 invariant verify |
| `hwrng_lfsr` (phi) | B2, B3, B4 | LFSR randomness / nonce |
| `sacred_constants_rom` (phi) | B1, B5 | Coptic gematria seeds |
| `tri_mant_mul` (euler) | B3, B5, B6 | R-SI-1 mantissa multiplication |
| `gf16_mul`, `gf256_mul` (euler) | B3, B5, B6 | GF arithmetic primitives |
| `bpb_counter` (euler) | B5, B9 | BPB lower-bound guard |
| `vsa_matmul_8x8` (euler) | B6 | Polynomial evaluation backbone |
| `phi_distance_oracle` (gamma) | B4 | Shortest-path routing |
| `blake3_compact` (across) | B1, B2, B6, B8 | Hash primitive |
| IGLALedger.sol (NeuronConstant) | B5, B9 | Champion lock + rewards |

---

## Risk register

| Risk | Mitigation |
|---|---|
| Tile budget exceeds 12 | Split: B1-B5 → TTSKY26c, B6-B9 → TTSKY27a |
| Groth16 prover (B5) too large for 2 tiles | Witness gen only on-chip, verifier off-chip via precompile 0x08 |
| ECDSA P-256 (B3) too dense for 1 tile | Expand to 1×2 |
| 8-port crossbar (B4) congestion in OpenLane | Manual floorplan, pre-placed ports |
| BN254 GF(p) arithmetic novel | Reuse existing 66-format zoo (gf256/gf16 helpers) |
| Trusted setup ceremony for Groth16 (B5) | Public ceremony, ≥3 participants, ceremony transcripts on IPFS |
| Sybil attack on B8 DID | PUF uniqueness per silicon + biometric binding (optional) |
| Bittensor bridge complexity (B9) | Start with Ethereum L2 deployment, bridge in v1.2 |

---

## Strategic value after category B completion

1. **Trinity v1.1 = the only open-silicon chip family** covering all 7 systemic DePIN gaps for 2026
2. **TTSKY26c submission = second shuttle revision** → production credibility
3. **DARPA RACE / OPTIMA / AIE pitches** get concrete module deliverables for the $10M ask range
4. **Bittensor subnet validator (B9)** = real revenue stream via TRI token rewards
5. **NIST zero-trust mandate** (forecast 2026-2027) — Trinity is the reference open-silicon implementation
6. **DePIN AI marketplace (B5)** = instant ZK verification competitive vs Gensyn's 12h optimistic challenge

---

## Acceptance criteria for category B sprint completion

- [ ] All 9 spec docs published in `docs/v1.1/` (this milestone — done today)
- [ ] All 9 RTL/Solidity skeletons compile in Yosys / Verilator
- [ ] All 9 modules pass R-SI-1 invariant audit (no standalone `*`)
- [ ] cocotb test count ≥ 100 across all modules (target average 11/module)
- [ ] GDS synthesis green for at least B1-B5 in TTSKY26c submission
- [ ] Foundry tests green for JobProver.sol and BittensorSubnetAttest.sol
- [ ] Zenodo DOI `10.5281/zenodo.19227877` updated with v1.1 manifest
- [ ] DARPA RACE whitepaper updated with concrete module specs
- [ ] Reference implementation pushed to `gHashTag/NeuronConstant/rtl/v1.1/`

---

## Next sprint (post-tape-out, Q1 2027 silicon arrival)

- v1.2: integration with Bittensor mainnet, real validator deployment
- v1.3: post-quantum signatures (Dilithium / Falcon) replacing ECDSA P-256
- v1.4: FHE-friendly arithmetic helpers (CKKS bootstrapping primitives)

---

## References

- [DEPIN_DECENTRALIZED_INTERNET_GAPS.md](../sprint-2026-05-18/DEPIN_DECENTRALIZED_INTERNET_GAPS.md) — 7 gaps + 9 modules analysis
- [DECENTRALIZED_INTERNET_USE_CASES.md](../sprint-2026-05-18/DECENTRALIZED_INTERNET_USE_CASES.md) — 21 use-case matrix
- [FINAL_SPRINT_REPORT.md](../sprint-2026-05-18/FINAL_SPRINT_REPORT.md) — v1.0 TT SKY26b submission record
- [Sesamedisk 2026 DePIN forecast](https://sesamedisk.com/) — zero-trust mandate prediction
- [Tiny Tapeout shuttle calendar](https://tinytapeout.com/) — TTSKY26c schedule

---

**Author:** Dmitrii Vasilev (sole author) — admin@t27.ai
**Date:** 2026-05-18
**Version:** v0.1 draft (specs only; RTL implementation pending category B sprint Sep-Nov 2026)
**License:** Apache-2.0 (RTL), MIT (Solidity), CC-BY-4.0 (documentation)
