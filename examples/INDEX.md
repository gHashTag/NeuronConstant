---
Author: Dmitrii Vasilev <admin@t27.ai>
License: Apache-2.0
Status: pre-silicon (tape-out target 2026-12-16)
---

# Examples Index

Five runnable reference applications for the NeuronConstant / Trinity SDK.
All examples use `MockBackend` and require no FPGA or ASIC hardware.

| # | Directory | One-liner |
|---|---|---|
| 1 | [verifiable_inference_demo/](verifiable_inference_demo/) | Run a toy model, emit a ZK proof, and verify it locally using the Trinity MockBackend. |
| 2 | [attested_validator_demo/](attested_validator_demo/) | Mock Bittensor BIT-0011 validator that attests job 42 via `ConvictionAttestor`. |
| 3 | [secure_iot_sensor_demo/](secure_iot_sensor_demo/) | PUF-based sensor identity (anchor `0x47C0`): sign a reading, verify on host. |
| 4 | [porep_storage_demo/](porep_storage_demo/) | Fake 32-byte Filecoin sector → mock PoRep commitment → verify digest. |
| 5 | [triad_mining_demo/](triad_mining_demo/) | 60-second mock mining loop; Era 0 = 1000 TRI/proof. |

See also:
- [FPGA Emulator Guide](../docs/devkit/FPGA_EMULATOR_GUIDE.md) — pre-silicon dev on Xilinx Kria K26
- [Whitepaper §9](../docs/whitepaper/) — architecture and performance projections
