# Trinity TRI-NET — Sales & Outreach Pack

**Sole author**: Dmitrii Vasilev (`admin@t27.ai`)
**Repo**: github.com/gHashTag/NeuronConstant
**Date**: 2026-05-18
**Status**: TT SKY26b shuttle Submitted (Phi/Euler/Gamma triad); DePIN v1 specs complete (`docs/v1.1/`)

This folder collects pitch documents for the 9 buyer categories identified for Trinity TRI-NET hardware and IP. Public-facing documents use ranges only; internal documents include concrete pricing and outreach playbooks.

## Documents

| # | File | Audience | Type | Lines | Size |
|---|---|---|---|---|---|
| — | INDEX.md | — | — | — | — |
| 1 | [BUYER_MATRIX_PRIORITIZATION.md](./BUYER_MATRIX_PRIORITIZATION.md) | Internal master | INTERNAL | 783 | 39 KB |
| 2 | [BITTENSOR_PITCH.md](./BITTENSOR_PITCH.md) | Bittensor subnet operators | Public | 652 | 33 KB |
| 3 | [DARPA_I2O_BAA_PROPOSAL.md](./DARPA_I2O_BAA_PROPOSAL.md) | DARPA I2O HR001126S0001 | Public proposal | 694 | 52 KB |
| 4 | [HELIUM_INTEGRATION_PROPOSAL.md](./HELIUM_INTEGRATION_PROPOSAL.md) | Helium / Nova Labs | Public | 649 | 52 KB |
| 5 | [GENSYN_IO_NET_IP_LICENSE.md](./GENSYN_IO_NET_IP_LICENSE.md) | Gensyn, io.net, Akash, Render | INTERNAL | 832 | 38 KB |
| 6 | [DEFENCE_CONTRACTOR_PITCH.md](./DEFENCE_CONTRACTOR_PITCH.md) | Anduril, Skydio, Shield AI, Palantir, Lockheed, RTX | INTERNAL | 898 | 51 KB |

**Total**: 4,508 lines / ~265 KB across 6 documents.

## Tier mapping

- **Tier A — act now (1-3 mo cycle)**: Bittensor, DARPA I2O, Gensyn/io.net
- **Tier B — high interest (3-12 mo)**: Helium, Defence contractors, Edge AI OEMs
- **Tier C — case-study driven**: covered in BUYER_MATRIX_PRIORITIZATION.md (regulators, FDA SaMD, Web3 identity)

## Cross-references

- DePIN v1.1 module specs: [`docs/v1.1/`](../v1.1/INDEX.md) (B1-B9, 9 modules)
- Live B9 contract: [`contracts/BittensorSubnetAttest.sol`](../../contracts/BittensorSubnetAttest.sol) (commit `30c62020`)
- Foundry tests: [`test/BittensorSubnetAttest.t.sol`](../../test/BittensorSubnetAttest.t.sol)
- TT SKY26b submissions: app.tinytapeout.com/shuttles/ttsky26b (Phi #4914, Euler #4915, Gamma #4913)
- Zenodo DOI: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

## Honest benchmarks

All documents use: "~1 GOPS @ ~50 MHz @ ~1 W ternary (projected, pending tape-out 2026-12-16)". No "63 tok/s/W" or any unverified efficiency claim appears in this pack.

## Confidentiality

- Public documents (BITTENSOR, DARPA, HELIUM): safe to share externally. Ranges only.
- INTERNAL documents (BUYER_MATRIX, GENSYN, DEFENCE): concrete pricing, do not share without PI approval.

---
*Sole author: Dmitrii Vasilev (`admin@t27.ai`)*
