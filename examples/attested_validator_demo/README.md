---
Author: Dmitrii Vasilev <admin@t27.ai>
License: Apache-2.0
Status: pre-silicon (tape-out target 2026-12-16)
---

# Attested Validator Demo

Demonstrates a Bittensor **BIT-0011** mock validator that attests job results
using `trinity_bittensor.ConvictionAttestor`.

NeuronConstant's attestation layer binds hardware-signed proofs (from the Trinity
ASIC, anchor `0x47C0`) to Bittensor subnet validator logic.  This example uses a
software mock so you can explore the API without hardware.

See **whitepaper §9** for details on the conviction attestation model and how it
integrates with Bittensor subnet economics.

Performance target: **~1 GOPS @ ~50 MHz @ ~1 W ternary (projected, pending tape-out 2026-12-16)**.

---

## Requirements

```
pip install trinity-sdk trinity-bittensor
```

Python 3.10 or later is required.  The `trinity-bittensor` package ships a mock
`ConvictionAttestor` compatible with Bittensor BIT-0011 validator interface.

---

## Run

```bash
cd examples/attested_validator_demo
python main.py
```

---

## Expected Output

```
[trinity-bittensor] ConvictionAttestor initialised (mock, BIT-0011)
Attesting job 42...
Attestation result for job 42:
  status   : ATTESTED
  score    : 0.9742
  anchor   : 0x47C0
  signature: a3f1b2c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2
Validator response submitted (mock).
```

---

## Notes

- Replace `ConvictionAttestorMock` with the production `ConvictionAttestor` from
  `trinity-bittensor` once the subnet is live.
- Bittensor BIT-0011 defines the attestation wire format; see the BIT-0011 draft in
  `docs/bittensor/`.
- Anchor `0x47C0` is embedded in every attestation to prove hardware origin.

---

## See Also

- [whitepaper §9](../../docs/whitepaper/)
- [FPGA Emulator Guide](../../docs/devkit/FPGA_EMULATOR_GUIDE.md)
- [examples/INDEX.md](../INDEX.md)
