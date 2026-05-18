# Your First Verifiable Inference in Python

<!--
Author: Dmitrii Vasilev <admin@t27.ai>
License: Apache-2.0
Status: pre-silicon (tape-out 2026-12-16)
-->

> **Status:** Pre-silicon — mock backend only.  
> Real hardware: tape-out 2026-12-16.  
> Performance target (projected, pending tape-out): ~1 GOPS @ ~50 MHz @ ~1 W ternary.

---

## Overview

This tutorial walks through using `trinity-sdk` to produce a cryptographically attested inference result on a toy model, inspect the `Attestation` object, and submit it to a mock Bittensor endpoint.

All code in this guide runs entirely in mock mode — no physical hardware required.

---

## Prerequisites

- Python 3.10+
- `trinity-node` running in mock mode (see [QUICKSTART_5_MIN.md](./QUICKSTART_5_MIN.md))
- `pip install git+https://github.com/gHashTag/trinity-sdk`

Confirm setup:

```bash
trinity-node --mock --port 7743 &
python3 -c "import trinity_sdk; print('SDK version:', trinity_sdk.__version__)"
# SDK version: 0.1.0-mock
```

---

## Step 1 — Install `trinity-sdk`

```bash
pip install git+https://github.com/gHashTag/trinity-sdk
```

The SDK provides:

| Module | Purpose |
|--------|---------|
| `trinity_sdk.TrinityClient` | Connect to `trinity-node` daemon |
| `trinity_sdk.MockChip` | In-process mock for unit tests (no daemon required) |
| `trinity_sdk.ProofRequest` | Build a proof/inference request |
| `trinity_sdk.Attestation` | Returned attestation with verification helpers |
| `trinity_sdk.bittensor` | Submit attestations to Bittensor (testnet) |

Full API reference: see `examples/` in the [gHashTag/trinity-sdk](https://github.com/gHashTag/trinity-sdk) repository.

---

## Step 2 — Connect to the Mock Chip

You can connect either via the running `trinity-node` daemon or via the in-process `MockChip` (useful in CI/CD or unit tests):

**Option A: Daemon connection**

```python
# connect_daemon.py
# Author: Dmitrii Vasilev <admin@t27.ai>
# License: Apache-2.0

from trinity_sdk import TrinityClient

# Connect to the running mock daemon
client = TrinityClient(host="127.0.0.1", port=7743)

info = client.get_chip_info()
print(f"Connected to: {info['model']}")
print(f"Anchor:       {info['anchor']}")   # 0x47C0
print(f"Mode:         {info['mode']}")     # mock
```

**Option B: In-process MockChip (no daemon needed)**

```python
# connect_mock.py
# Author: Dmitrii Vasilev <admin@t27.ai>
# License: Apache-2.0

from trinity_sdk import MockChip

# Instantiate an in-process mock — no network required
chip = MockChip(seed="my-deterministic-seed")

info = chip.get_chip_info()
print(f"Connected to: {info['model']}")
print(f"Anchor:       {info['anchor']}")   # 0x47C0
print(f"Mode:         {info['mode']}")     # mock-in-process
```

Use `TrinityClient` for integration testing against `trinity-node`; use `MockChip` for unit tests and offline development.

---

## Step 3 — Run `prove_inference` on a Toy Model

The following example runs a small dot-product "inference" (a stand-in for any model forward pass) and wraps the result in a Trinity attestation:

```python
# verifiable_inference.py
# Author: Dmitrii Vasilev <admin@t27.ai>
# License: Apache-2.0

import json
import numpy as np
from trinity_sdk import MockChip, InferenceRequest

# ── Toy model: simple linear layer (3-in, 2-out) ──────────────────────────────
weights = np.array([[0.5, -0.3], [0.2, 0.8], [-0.1, 0.4]], dtype=np.float32)
bias    = np.array([0.1, -0.05], dtype=np.float32)

def toy_model(x: np.ndarray) -> np.ndarray:
    return x @ weights + bias

# ── Input ─────────────────────────────────────────────────────────────────────
x = np.array([1.0, 2.0, 3.0], dtype=np.float32)
y = toy_model(x)
print(f"Raw output: {y}")   # e.g. [0.9, 1.75]

# ── Attest via MockChip ───────────────────────────────────────────────────────
chip = MockChip(seed="tutorial-seed")

req = InferenceRequest(
    model_id    = "toy-linear-v1",
    input_hash  = MockChip.hash_array(x),
    output_hash = MockChip.hash_array(y),
    proof_type  = "inference_attestation_v1",
)

attestation = chip.prove_inference(req)
print(json.dumps(attestation.to_dict(), indent=2))
```

Expected output:

```json
{
  "proof_type":   "inference_attestation_v1",
  "model_id":     "toy-linear-v1",
  "anchor":       "0x47C0",
  "phi_id":       "phi-a3f2c1...",
  "euler_id":     "euler-9d4b87...",
  "gamma_id":     "gamma-cc2011...",
  "input_hash":   "sha256:4f3e...",
  "output_hash":  "sha256:9c1a...",
  "timestamp":    1735000000,
  "signature":    "0xdeadbeef...",
  "valid":        true
}
```

---

## Step 4 — Inspect the `Attestation` Object

The `Attestation` object provides structured access and a `.verify()` method:

```python
# inspect_attestation.py
# Author: Dmitrii Vasilev <admin@t27.ai>
# License: Apache-2.0

# (continuing from verifiable_inference.py — attestation is in scope)

print("=== Attestation Inspection ===")
print(f"anchor   : {attestation.anchor}")          # "0x47C0"
print(f"phi_id   : {attestation.phi_id}")
print(f"euler_id : {attestation.euler_id}")
print(f"gamma_id : {attestation.gamma_id}")
print(f"valid    : {attestation.verify()}")        # True

# Check individual component signatures
print(f"phi_sig_ok   : {attestation.verify_component('phi')}")
print(f"gamma_sig_ok : {attestation.verify_component('gamma')}")

# Export for submission
payload = attestation.to_bytes()
print(f"serialized size: {len(payload)} bytes")
```

Key fields:

| Field | Description |
|-------|-------------|
| `anchor` | Always `0x47C0` — confirms Trinity hardware identity |
| `phi_id` | Phi sub-chip identity (RF processing) |
| `euler_id` | Euler sub-chip identity (coordination) |
| `gamma_id` | Gamma sub-chip identity (PUF root) |
| `signature` | Combined hardware signature over the proof payload |
| `valid` | `True` if all component signatures verify |

---

## Step 5 — Submit to Mock Bittensor

```python
# submit_bittensor.py
# Author: Dmitrii Vasilev <admin@t27.ai>
# License: Apache-2.0

from trinity_sdk.bittensor import MockBittensorClient

# Connect to the mock Bittensor endpoint (no real TAO required)
bt = MockBittensorClient(network="test", netuid=11)

receipt = bt.submit_attestation(
    attestation = attestation,
    wallet_name = "mock_wallet",
    hotkey      = "default",
)

print(f"submission status : {receipt.status}")       # "accepted"
print(f"conviction_score  : {receipt.conviction}")   # float, 0.0–1.0
print(f"tx_hash           : {receipt.tx_hash}")
```

In mock mode, the submission is validated locally and returns a synthetic conviction score. No real network calls are made.

---

## Pointers to More Examples

The [gHashTag/trinity-sdk](https://github.com/gHashTag/trinity-sdk) repository's `examples/` directory contains:

| File | What it demonstrates |
|------|---------------------|
| `examples/basic_proof.py` | Minimal attestation (equivalent to Step 3 above) |
| `examples/batch_inference.py` | Attesting multiple inferences in one call |
| `examples/verify_offline.py` | Verifying a serialized attestation without a live chip |
| `examples/bittensor_submit.py` | Full testnet submission with a real btcli wallet |
| `examples/filecoin_pc1_mock.py` | PC1 acceleration stub for Filecoin SPs |

---

## See Also

- [NeuronConstant Whitepaper §9 — Unified Computer Paradigm](../UNIFIED_COMPUTER_PARADIGM.md)
- [TTSKY26c Roadmap](../TTSKY26c_ROADMAP.md)
- [gHashTag/trinity-node](https://github.com/gHashTag/trinity-node)
- [gHashTag/trinity-sdk](https://github.com/gHashTag/trinity-sdk)

---

*Author: Dmitrii Vasilev \<admin@t27.ai\> · License: Apache-2.0 · Status: pre-silicon (tape-out 2026-12-16)*
