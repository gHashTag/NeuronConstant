# From Zero to First Trinity Attestation in 5 Minutes

<!--
Author: Dmitrii Vasilev <admin@t27.ai>
License: Apache-2.0
Status: pre-silicon (tape-out 2026-12-16)
-->

> **Status:** Pre-silicon — mock backend only.  
> Real hardware: tape-out 2026-12-16.  
> Performance target (projected, pending tape-out): ~1 GOPS @ ~50 MHz @ ~1 W ternary.

---

## Prerequisites

| Dependency | Minimum Version | Notes |
|------------|----------------|-------|
| Rust toolchain | 1.75+ | Install via [rustup.rs](https://rustup.rs) |
| Python | 3.10+ | `python3 --version` to confirm |
| git | 2.30+ | For source installs |
| cargo | Ships with Rust | Part of the standard toolchain |

Verify before continuing:

```bash
rustc --version   # rustc 1.75.0 or newer
python3 --version # Python 3.10.x or newer
git --version     # git version 2.30.x or newer
```

---

## Step 1 — Install `trinity-node`

`trinity-node` is the local daemon that simulates (and, post-tape-out, drives) the NeuronConstant Trinity chip.  
Install directly from source:

```bash
cargo install --git https://github.com/gHashTag/trinity-node trinity-node
```

The build will pull dependencies and compile the mock backend (~2-3 min on a modern machine).  
After installation confirm the binary is available:

```bash
trinity-node --version
# trinity-node 0.1.0-mock (pre-silicon)
```

---

## Step 2 — Install `trinity-sdk` (Python)

The SDK provides Python bindings for proof generation, attestation, and submission.

```bash
pip install git+https://github.com/gHashTag/trinity-sdk
```

Confirm the install:

```bash
python3 -c "import trinity_sdk; print(trinity_sdk.__version__)"
# 0.1.0-mock
```

---

## Step 3 — Run the Mock Daemon

Start `trinity-node` in mock mode. This launches a local JSON-RPC server on port `7743` that simulates the chip's attestation API:

```bash
trinity-node --mock --port 7743 --log-level info
```

You should see output similar to:

```
[INFO] trinity-node starting in MOCK mode
[INFO] Chip identity anchor: 0x47C0
[INFO] Listening on 127.0.0.1:7743
[INFO] Ready — awaiting RPC connections
```

Leave this terminal open. The anchor address `0x47C0` is the chip identity verification anchor used across all Trinity proof workflows.

---

## Step 4 — Run `first_proof.py`

Open a new terminal and create `first_proof.py`:

```python
# first_proof.py
# Author: Dmitrii Vasilev <admin@t27.ai>
# License: Apache-2.0

from trinity_sdk import TrinityClient, ProofRequest

# Connect to the mock daemon
client = TrinityClient(host="127.0.0.1", port=7743)

# Request chip identification
chip_info = client.get_chip_info()
print("chip_info:", chip_info)

# Build a minimal proof request
req = ProofRequest(
    payload=b"hello, NeuronConstant",
    proof_type="ternary_attestation_v1",
)

# Submit and retrieve attestation
attestation = client.prove(req)
print("attestation.anchor :", attestation.anchor)
print("attestation.phi_id  :", attestation.phi_id)
print("attestation.euler_id:", attestation.euler_id)
print("attestation.gamma_id:", attestation.gamma_id)
print("attestation.valid   :", attestation.verify())
```

Run it:

```bash
python3 first_proof.py
```

---

## Expected Output

```
chip_info: {
  "model": "Trinity-Mock-B7",
  "anchor": "0x47C0",
  "phi_id":   "phi-a3f2c1...",
  "euler_id": "euler-9d4b87...",
  "gamma_id": "gamma-cc2011...",
  "mode":     "mock",
  "version":  "0.1.0-mock"
}
attestation.anchor : 0x47C0
attestation.phi_id  : phi-a3f2c1...
attestation.euler_id: euler-9d4b87...
attestation.gamma_id: gamma-cc2011...
attestation.valid   : True
```

All three sub-chip IDs (`phi_id`, `euler_id`, `gamma_id`) plus the hardware anchor `0x47C0` confirm the attestation pipeline is working end-to-end.

---

## Troubleshooting

### Error: `ConnectionRefusedError: [Errno 111] Connection refused`

**Cause:** `trinity-node` is not running or bound to a different port.  
**Fix:** Start the daemon with `trinity-node --mock --port 7743` before running the Python script.

---

### Error: `ModuleNotFoundError: No module named 'trinity_sdk'`

**Cause:** SDK not installed in the active Python environment.  
**Fix:**
```bash
pip install git+https://github.com/gHashTag/trinity-sdk
# If using a virtualenv, activate it first.
```

---

### Error: `AttestationError: anchor mismatch (expected 0x47C0)`

**Cause:** The mock daemon version does not match the SDK version, or config was overridden.  
**Fix:** Re-install both components from their latest `main` branches:
```bash
cargo install --git https://github.com/gHashTag/trinity-node trinity-node --force
pip install --upgrade git+https://github.com/gHashTag/trinity-sdk
```

---

## Next Steps

- Integrate attestations into a Bittensor validator — see [`BITTENSOR_VALIDATOR_SETUP.md`](./BITTENSOR_VALIDATOR_SETUP.md)
- Add verifiable inference — see [`PYTHON_SDK_TUTORIAL.md`](./PYTHON_SDK_TUTORIAL.md)
- Explore Filecoin SP acceleration — see [`FILECOIN_SP_INTEGRATION.md`](./FILECOIN_SP_INTEGRATION.md)

---

## See Also

- [NeuronConstant Whitepaper §9 — Unified Computer Paradigm](../UNIFIED_COMPUTER_PARADIGM.md)
- [TTSKY26c Roadmap](../TTSKY26c_ROADMAP.md)
- [gHashTag/trinity-node](https://github.com/gHashTag/trinity-node)
- [gHashTag/trinity-sdk](https://github.com/gHashTag/trinity-sdk)

---

*Author: Dmitrii Vasilev \<admin@t27.ai\> · License: Apache-2.0 · Status: pre-silicon (tape-out 2026-12-16)*
