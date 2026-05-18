---
Author: Dmitrii Vasilev <admin@t27.ai>
License: Apache-2.0
Status: pre-silicon (tape-out target 2026-12-16)
---

# Secure IoT Sensor Demo

Demonstrates PUF-based (Physically Unclonable Function) sensor identity using
the Trinity anchor `0x47C0`, signing a sensor reading, and verifying the
signature on the host.

On real Trinity hardware the PUF is derived from manufacturing variation in the
ternary cell array.  The anchor `0x47C0` is written into a locked register at
power-on and serves as a stable device identifier that cannot be cloned.

See **whitepaper §9** for the full PUF/identity scheme.

Performance target: **~1 GOPS @ ~50 MHz @ ~1 W ternary (projected, pending tape-out 2026-12-16)**.

---

## Requirements

```
pip install trinity-sdk
```

Python 3.10 or later.  The `trinity-sdk` package includes `MockPUF` and
`SensorSigner` classes for software-level testing.

---

## Run

```bash
cd examples/secure_iot_sensor_demo
python main.py
```

---

## Expected Output

```
[trinity-sdk] MockPUF initialised — anchor 0x47C0
PUF identity: 7a3f1b2c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1
Sensor reading: {'temperature_c': 23.4, 'humidity_pct': 61.2}
Signature: b2d4a6f8c0e2a4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2a4
Host verification: PASS
Device identity bound to anchor 0x47C0.
```

---

## Notes

- `MockPUF` returns a deterministic pseudo-PUF derived from a seed.  Real
  hardware PUF responses are non-reproducible across devices.
- The signature uses HMAC-SHA256 in this mock; the ASIC uses an on-chip
  signing primitive.
- Anchor `0x47C0` ensures the signature can be attributed to a specific
  Trinity die.

---

## See Also

- [whitepaper §9](../../docs/whitepaper/)
- [FPGA Emulator Guide](../../docs/devkit/FPGA_EMULATOR_GUIDE.md)
- [examples/INDEX.md](../INDEX.md)
