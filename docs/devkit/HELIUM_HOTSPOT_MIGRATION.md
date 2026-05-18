# Migrate Helium Hotspot Gen1 → Trinity Duo for Sybil-Proof PoC

<!--
Author: Dmitrii Vasilev <admin@t27.ai>
License: Apache-2.0
Status: pre-silicon (tape-out 2026-12-16)
-->

> **Status:** Pre-silicon — mock backend only.  
> Real hardware: tape-out 2026-12-16.  
> Performance target (projected, pending tape-out): ~1 GOPS @ ~50 MHz @ ~1 W ternary.

---

## Gen1 Limitations

Helium Gen1 hotspots (Bobcat 300, RAK V2, SyncroB.it, etc.) use a software ECC key stored in a standard eFuse or TPM.  
This design has well-documented weaknesses in the context of Proof-of-Coverage (PoC):

- **Key exportability:** The private key can be extracted from units with physical access, enabling identity cloning.
- **No hardware attestation:** The network cannot distinguish a genuine hotspot from software emulation (VMs, Docker containers).
- **Sybil surface:** A single operator can deploy hundreds of virtual hotspots that pass software-only PoC challenges, diluting rewards for legitimate participants.

Helium's transition to a Solana-based L1 improved reward economics but did not eliminate the hardware attestation gap.

---

## What Trinity Duo Brings

Trinity Duo pairs two sub-chips on a single module:

| Sub-chip | Role in PoC |
|----------|-------------|
| **Phi** | RF-adjacent signal processing; verifies that PoC beacon data was processed by genuine hardware |
| **Gamma** | PUF-based identity root; generates a non-exportable cryptographic identity anchored at `0x47C0` |

Together, Phi + Gamma produce an **attested PoC** response: the coverage beacon is signed by a key that was generated inside the hardware and cannot be cloned without destroying the device.

Key properties:

- **PUF-based identity:** The Gamma sub-chip derives its key from physical unclonable function (PUF) responses unique to each die. The key is never stored; it is re-derived on demand.
- **Anchor `0x47C0`:** Every attestation includes the hardware identity anchor `0x47C0`, enabling the Helium network (or any verifier) to confirm the response came from a genuine Trinity Duo device.
- **Attested PoC:** The full coverage proof includes a Trinity attestation field; validators can weight attested beacons higher than unattested ones.

---

## Migration Steps

### Step 0 — Verify Your Current Gen1 Status

```bash
# Check your hotspot's on-chain status
helium-wallet hotspots --address <your_hotspot_address>
```

Note your current hex location, assert height, and wallet address before proceeding.

---

### Step 1 — Decommission Gen1 Wallet

Transfer any pending HNT rewards before decommission.  
Use the Helium CLI or Helium Wallet App to move funds:

```bash
helium-wallet transfer --amount all --payee <your_main_wallet>
```

Once funds are clear, mark the hotspot inactive in the registry if the network supports a `decommission` transaction (varies by version).

---

### Step 2 — Register Trinity Duo Device

With `trinity-node` and `trinity-sdk` installed (see [QUICKSTART_5_MIN.md](./QUICKSTART_5_MIN.md)):

```bash
# Generate device identity from PUF (mock mode in pre-silicon phase)
trinity-node identity generate --output trinity_identity.json
```

The `trinity_identity.json` file contains:

```json
{
  "device_id":   "trinity-duo-<hash>",
  "anchor":      "0x47C0",
  "phi_id":      "phi-...",
  "gamma_id":    "gamma-...",
  "public_key":  "0x...",
  "attestation": "0x..."
}
```

Register on-chain (Helium Solana L1 or testnet):

```bash
trinity-node helium register \
  --identity trinity_identity.json \
  --network testnet
```

---

### Step 3 — Bind to Original Hex

Once registered, assert your Trinity Duo device at the same hex location as the decommissioned Gen1 unit:

```bash
# Assert location using the Helium CLI
helium-wallet assert \
  --gateway <trinity_device_public_key> \
  --lat <latitude> \
  --lng <longitude> \
  --gain <antenna_gain_dbi>
```

Confirm the hex binding:

```bash
helium-wallet hotspots --address <trinity_device_public_key>
# location, hex, gain should match your previous Gen1 assert
```

---

## Compatibility Matrix

| Feature | Helium Gen1 | Trinity Duo (Mock) | Trinity Duo (Silicon, Dec 2026) |
|---------|-------------|-------------------|---------------------------------|
| PoC Beacon Response | ✅ Software | ✅ Mock attestation | ✅ Hardware PUF attestation |
| Sybil Resistance | ❌ Weak (key-exportable) | ⚠️ Simulated | ✅ PUF non-exportable |
| Anchor `0x47C0` | ❌ None | ✅ Mock | ✅ Hardware |
| Attested PoC field | ❌ None | ✅ Mock | ✅ Hardware |
| Mainnet support | ✅ | ❌ Testnet only | ✅ Planned post tape-out |
| HNT reward eligibility | ✅ | ❌ Testnet only | ✅ Pending protocol adoption |
| Helium Solana L1 | ✅ | ✅ (testnet) | ✅ |

---

## FAQ

**Q: Can I migrate without losing my hex location?**  
A: Yes — as long as you assert the Trinity Duo device at the same GPS coordinates, it binds to the same hex. The hex is not tied to the old device identity.

**Q: Will Trinity Duo earn more HNT than Gen1?**  
A: The attestation boost depends on whether the Helium network formally adopts attested PoC weighting. The Trinity team is tracking this with the Helium Foundation. No earnings guarantee is made.

**Q: What happens if the PUF read fails after tape-out?**  
A: PUF read failures are handled by the Gamma sub-chip error correction layer. If re-derive attempts exceed threshold, the device enters a locked state and must be RMA'd. This is a hardware safety feature, not a bug.

**Q: Is the mock mode suitable for testing my migration scripts?**  
A: Yes — the mock daemon generates deterministic (but fake) identity values seeded from your machine's hostname. It exercises the full API surface without real hardware.

---

## See Also

- [NeuronConstant Whitepaper §9 — Unified Computer Paradigm](../UNIFIED_COMPUTER_PARADIGM.md)
- [TTSKY26c Roadmap](../TTSKY26c_ROADMAP.md)
- [gHashTag/trinity-node](https://github.com/gHashTag/trinity-node)
- [gHashTag/trinity-sdk](https://github.com/gHashTag/trinity-sdk)

---

*Author: Dmitrii Vasilev \<admin@t27.ai\> · License: Apache-2.0 · Status: pre-silicon (tape-out 2026-12-16)*
