# NeuronConstant DevKit — Quick-Start Guides

<!--
Author: Dmitrii Vasilev <admin@t27.ai>
License: Apache-2.0
Status: pre-silicon (tape-out 2026-12-16)
-->

> All guides target the pre-silicon mock backend.  
> Real hardware: tape-out 2026-12-16.  
> Performance target (projected, pending tape-out): ~1 GOPS @ ~50 MHz @ ~1 W ternary.

---

## Guides

| Guide | Description |
|-------|-------------|
| [QUICKSTART_5_MIN.md](./QUICKSTART_5_MIN.md) | From zero to first Trinity attestation in 5 minutes — install `trinity-node` + `trinity-sdk`, run the mock daemon, produce your first proof, and verify chip identity at anchor `0x47C0`. |
| [BITTENSOR_VALIDATOR_SETUP.md](./BITTENSOR_VALIDATOR_SETUP.md) | Set up a Trinity-attested Bittensor validator on Subnet 11 using the BIT-0011 draft conviction mechanism (testnet only, mock backend). |
| [FILECOIN_SP_INTEGRATION.md](./FILECOIN_SP_INTEGRATION.md) | Integrate the Trinity Gamma B7 PoRep accelerator into a Filecoin SP sealing pipeline via a Lotus plugin stub (preliminary projections, awaiting silicon). |
| [HELIUM_HOTSPOT_MIGRATION.md](./HELIUM_HOTSPOT_MIGRATION.md) | Migrate a legacy Helium Gen1 hotspot to Trinity Duo (Phi + Gamma) for PUF-based sybil-proof Proof-of-Coverage, including a Gen1-vs-Duo compatibility matrix. |
| [PYTHON_SDK_TUTORIAL.md](./PYTHON_SDK_TUTORIAL.md) | Run your first verifiable inference in Python — connect the mock chip, call `prove_inference` on a toy model, inspect the `Attestation` object, and submit to mock Bittensor. |

---

## See Also

- [NeuronConstant Whitepaper §9 — Unified Computer Paradigm](../UNIFIED_COMPUTER_PARADIGM.md)
- [TTSKY26c Roadmap](../TTSKY26c_ROADMAP.md)
- [gHashTag/trinity-node](https://github.com/gHashTag/trinity-node)
- [gHashTag/trinity-sdk](https://github.com/gHashTag/trinity-sdk)

---

*Author: Dmitrii Vasilev \<admin@t27.ai\> · License: Apache-2.0 · Status: pre-silicon (tape-out 2026-12-16)*
