# Setting Up a Trinity-Attested Bittensor Validator (BIT-0011)

<!--
Author: Dmitrii Vasilev <admin@t27.ai>
License: Apache-2.0
Status: pre-silicon (tape-out 2026-12-16)
-->

> **Status:** Pre-silicon — mock backend only.  
> **Testnet only:** Mock backend works on subtensor testnet, not mainnet.  
> Real hardware: tape-out 2026-12-16.  
> Performance target (projected, pending tape-out): ~1 GOPS @ ~50 MHz @ ~1 W ternary.

---

## What Is BIT-0011?

BIT-0011 ("Trinity Conviction") is a proposed Bittensor Improvement Proposal that introduces hardware-attested validator scoring for Subnet 11.  
Under BIT-0011, validators can present a cryptographic attestation produced by a Trinity chip (identity anchor `0x47C0`) as supplementary evidence of legitimate compute capacity.  
Attestation is not a replacement for stake or performance metrics — it acts as a **conviction boost** that reduces the probability of sybil-classifier downscoring.

Full Bittensor documentation and TAO tokenomics are maintained at [opentensor/bittensor](https://github.com/opentensor/bittensor).

> **Note:** BIT-0011 is a draft proposal. It has not been merged into the Bittensor protocol as of this writing. This guide targets the mock/testnet path.

---

## Prerequisites

| Dependency | Version | Purpose |
|------------|---------|---------|
| Rust 1.75+ | required | Build `trinity-node` |
| Python 3.10+ | required | `bittensor` SDK, `trinity-sdk` |
| `bittensor` Python package | ≥ 6.0 | Wallet + subtensor access |
| `trinity-node` | 0.1.0-mock | Local attestation daemon |
| `trinity-sdk` | 0.1.0-mock | Proof generation |
| TAO (testnet) | ≥ 100 TAO | Validator registration |
| A subtensor testnet endpoint | — | `wss://test.finney.opentensor.ai` |

Install Python dependencies:

```bash
pip install bittensor git+https://github.com/gHashTag/trinity-sdk
```

Install and start the mock daemon:

```bash
cargo install --git https://github.com/gHashTag/trinity-node trinity-node
trinity-node --mock --port 7743
```

---

## Step 1 — Register a Wallet on Subnet 11 (Testnet)

```bash
# Create a new coldkey (skip if you already have one)
btcli wallet new_coldkey --wallet.name my_validator

# Create a hotkey
btcli wallet new_hotkey --wallet.name my_validator --wallet.hotkey default

# Register on subnet 11 (testnet)
btcli subnet register \
  --wallet.name my_validator \
  --wallet.hotkey default \
  --netuid 11 \
  --subtensor.network test
```

Confirm registration:

```bash
btcli wallet overview --wallet.name my_validator --subtensor.network test
# UID column should show your assigned UID on netuid 11
```

---

## Step 2 — Point `trinity-node` at Subnet 11

Edit (or create) `~/.trinity/config.toml`:

```toml
[node]
mode       = "mock"          # switch to "hardware" post tape-out
rpc_port   = 7743
log_level  = "info"

[bittensor]
network    = "test"
netuid     = 11
subtensor  = "wss://test.finney.opentensor.ai"
wallet     = "my_validator"
hotkey     = "default"
```

Restart the daemon to pick up the config:

```bash
trinity-node --config ~/.trinity/config.toml
```

Log line to look for:

```
[INFO] Bittensor integration: subnet 11 (testnet)
[INFO] Chip identity anchor: 0x47C0
```

---

## Step 3 — Attest a Validator Job

With the daemon running, produce an attestation for a specific validation epoch:

```python
# attest_validator_job.py
# Author: Dmitrii Vasilev <admin@t27.ai>
# License: Apache-2.0

from trinity_sdk import TrinityClient, ProofRequest
import json, time

client = TrinityClient(host="127.0.0.1", port=7743)

req = ProofRequest(
    payload=f"validator-epoch-{int(time.time())}".encode(),
    proof_type="bittensor_conviction_v1",
    metadata={"netuid": 11, "network": "test"},
)

attestation = client.prove(req)
print(json.dumps(attestation.to_dict(), indent=2))
```

Sample output:

```json
{
  "proof_type": "bittensor_conviction_v1",
  "anchor":     "0x47C0",
  "phi_id":     "phi-a3f2c1...",
  "euler_id":   "euler-9d4b87...",
  "gamma_id":   "gamma-cc2011...",
  "netuid":     11,
  "network":    "test",
  "timestamp":  1735000000,
  "signature":  "0xdeadbeef...",
  "valid":      true
}
```

Save this JSON — it is submitted alongside your validator weights.

---

## Step 4 — View Conviction Boost

After submitting an attested epoch via the BIT-0011 reference implementation (see `trinity-node`'s `bittensor_submit` sub-command), query your conviction score:

```bash
trinity-node bittensor_status \
  --wallet my_validator \
  --hotkey default \
  --network test
```

Expected fields in response:

```
conviction_score : 0.87  (mock)
anchor_verified  : true  (0x47C0)
last_attested    : 2025-xx-xx ...
boost_applied    : true
```

> **Mock note:** In the mock backend, `conviction_score` is synthetic. Real scoring will depend on protocol adoption of BIT-0011.

---

## FAQ

**Q: How much TAO do I need on testnet?**  
A: Registration on testnet costs a small amount of test TAO (typically 0.1–1 TAO depending on subnet registration dynamics). Testnet TAO has no monetary value. Use `btcli wallet faucet` if available, or request tokens from the Bittensor Discord.

**Q: Does this work on mainnet?**  
A: Not yet. BIT-0011 is a draft proposal and mock mode is subtensor-testnet-only.  
Mainnet integration is planned post tape-out (December 2026).

**Q: What is the conviction boost mechanism?**  
A: Conviction boosts are applied at the meta-graph level to reduce sybil-classifier penalty weight on validated UIDs. The exact weight is defined in the BIT-0011 spec draft.

**Q: Can I use an existing validator UID?**  
A: Yes — you only need to start producing Trinity attestations for new epochs. Past epochs are not retroactively affected.

---

## See Also

- [NeuronConstant Whitepaper §9 — Unified Computer Paradigm](../UNIFIED_COMPUTER_PARADIGM.md)
- [TTSKY26c Roadmap](../TTSKY26c_ROADMAP.md)
- [gHashTag/trinity-node](https://github.com/gHashTag/trinity-node)
- [gHashTag/trinity-sdk](https://github.com/gHashTag/trinity-sdk)
- [opentensor/bittensor](https://github.com/opentensor/bittensor)

---

*Author: Dmitrii Vasilev \<admin@t27.ai\> · License: Apache-2.0 · Status: pre-silicon (tape-out 2026-12-16)*
