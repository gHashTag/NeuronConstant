---
Author: Dmitrii Vasilev <admin@t27.ai>
License: Apache-2.0
Status: pre-silicon (tape-out target 2026-12-16)
---

# Verifiable Inference Demo

Demonstrates running a toy model on the Trinity MockBackend, generating a
zero-knowledge proof of correct inference, and verifying that proof locally.

This example illustrates the NeuronConstant verifiable inference pipeline described
in **whitepaper §9**.  On real hardware, the proof is generated inside the Trinity
ASIC (anchor `0x47C0`) and can be verified by any third party without re-running the
inference.

Performance target: **~1 GOPS @ ~50 MHz @ ~1 W ternary (projected, pending tape-out 2026-12-16)**.

---

## Requirements

```
pip install trinity-sdk
```

Python 3.10 or later is required.  The `trinity-sdk` package ships a `MockBackend`
that runs entirely in software, so no FPGA or ASIC hardware is needed for this demo.

---

## Run

```bash
cd examples/verifiable_inference_demo
python main.py
```

---

## Expected Output

```
[trinity-sdk] MockBackend initialised (pre-silicon simulation)
Running toy inference with input shape (1, 128)...
Proof generated.
Proof digest: 3a7f2c1b9e4d5a0f8b2e6c4d1a3f7e9b2c5d8a0f1e4b7c2d9a6f3e0b8c5d2a1
Verification: PASS
Anchor: 0x47C0 (identity confirmed, mock)
```

---

## Notes

- The `MockBackend` mimics the Trinity ternary MAC array in pure Python.
- Replace `MockBackend` with `TrinityBackend` (hardware) once the ASIC is available
  post tape-out (2026-12-16).
- See **whitepaper §9** for ZK proof circuit details.

---

## See Also

- [whitepaper §9](../../docs/whitepaper/)
- [FPGA Emulator Guide](../../docs/devkit/FPGA_EMULATOR_GUIDE.md)
- [examples/INDEX.md](../INDEX.md)
