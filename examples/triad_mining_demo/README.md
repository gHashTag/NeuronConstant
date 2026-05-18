---
Author: Dmitrii Vasilev <admin@t27.ai>
License: Apache-2.0
Status: pre-silicon (tape-out target 2026-12-16)
---

# Triad Mining Demo

Demonstrates the NeuronConstant **TRIAD token** mining loop operating in **Era 0**,
where each accepted proof earns **1000 TRI**.

The mining loop submits mock proofs every few seconds, accumulates rewards, and
prints a running total.  The demo runs for 60 seconds then exits.

See **whitepaper §9** for the TRIAD tokenomics, era schedule, and proof-of-work
construction.

Performance target: **~1 GOPS @ ~50 MHz @ ~1 W ternary (projected, pending tape-out 2026-12-16)**.

---

## Requirements

```
pip install trinity-sdk
```

Python 3.10 or later.  The `trinity-sdk` package includes `MockMiner` for
software-level mining simulation without real hardware.

---

## Run

```bash
cd examples/triad_mining_demo
python main.py
```

The script runs for 60 seconds.  Press Ctrl+C to stop early.

---

## Expected Output

```
[trinity-sdk] MockMiner initialised — Era 0 reward: 1000 TRI/proof
[00:05] mined 1 proofs = 1000 TRI
[00:10] mined 2 proofs = 2000 TRI
[00:15] mined 3 proofs = 3000 TRI
...
[00:60] mined 12 proofs = 12000 TRI
Mining complete. Total: 12 proofs = 12000 TRI
```

(Exact proof count depends on system speed; ~1 proof/5 s is typical on a
modern laptop running the mock backend.)

---

## Notes

- Era 0 reward is fixed at 1000 TRI/proof.  Era 1 and beyond follow a halving
  schedule described in whitepaper §9.
- On real Trinity hardware the proof generation time is dominated by the ternary
  ZK circuit (~50 ms at ~50 MHz target clock), giving ~20 proofs/s.
- The mock backend generates proofs as fast as Python can hash, so actual count
  during 60 s will be higher than hardware.

---

## See Also

- [whitepaper §9](../../docs/whitepaper/)
- [FPGA Emulator Guide](../../docs/devkit/FPGA_EMULATOR_GUIDE.md)
- [examples/INDEX.md](../INDEX.md)
