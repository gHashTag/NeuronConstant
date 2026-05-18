---
Author: Dmitrii Vasilev <admin@t27.ai>
License: Apache-2.0
Status: pre-silicon (tape-out target 2026-12-16)
---

# PoRep Storage Demo

Demonstrates how the Trinity ASIC accelerates Filecoin **Proof of Replication
(PoRep)** by offloading the ternary hash pipeline to on-chip compute.

This example mocks the PoRep flow: generate a fake 32-byte sector commitment,
run the mock PoRep computation, and print the resulting sector digest.

See **whitepaper §9** for the ternary PoRep acceleration architecture.

Performance target: **~1 GOPS @ ~50 MHz @ ~1 W ternary (projected, pending tape-out 2026-12-16)**.

---

## Requirements

```
pip install trinity-sdk
```

Python 3.10 or later.  The `trinity-sdk` package includes a `MockPoRep` class
that simulates the on-chip ternary hash pipeline in software.

---

## Run

```bash
cd examples/porep_storage_demo
python main.py
```

---

## Expected Output

```
[trinity-sdk] MockPoRep initialised (pre-silicon simulation)
Sector ID  : 0x0000000000000001
Sector data: d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5
PoRep commitment computed.
Sector digest: 1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2
PoRep: VALID (mock)
```

---

## Notes

- The mock PoRep uses SHA-256 as a stand-in for the ternary hash pipeline.
  Real hardware uses a custom ternary Merkle construction described in
  whitepaper §9.
- Sector size is 32 bytes in this demo; production Filecoin sectors are 32 GiB.
- Hardware speedup over software PoRep is the key value proposition for
  storage-provider operators.

---

## See Also

- [whitepaper §9](../../docs/whitepaper/)
- [FPGA Emulator Guide](../../docs/devkit/FPGA_EMULATOR_GUIDE.md)
- [examples/INDEX.md](../INDEX.md)
