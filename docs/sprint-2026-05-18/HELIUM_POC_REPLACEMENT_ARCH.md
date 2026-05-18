# Trinity HW-PoC: Architecture Spec for Replacing Helium Proof-of-Coverage

**Status:** Preliminary Design — v0.1 | 2025-Q3  
**Audience:** Protocol engineers, DePIN architects, Helium migration evaluators  
**Classification:** Public draft — mark sections `[PRELIMINARY]` as unmeasured

---

## Table of Contents

1. [What Helium PoC Is and Why It's Broken](#1-what-helium-poc-is-and-why-its-broken)
2. [Trinity HW-PoC Primitives](#2-trinity-hw-poc-primitives)
3. [Proof-of-Inference-Coverage (PoIC)](#3-proof-of-inference-coverage-poic)
4. [Proof-of-Bandwidth-Coverage (PoBC)](#4-proof-of-bandwidth-coverage-pobc)
5. [Anti-Gaming Guarantees](#5-anti-gaming-guarantees)
6. [Protocol Flow](#6-protocol-flow)
7. [Bridge from Helium](#7-bridge-from-helium)
8. [On-Chain Anchoring](#8-on-chain-anchoring)
9. [Failure Modes & Mitigations](#9-failure-modes--mitigations)
10. [Comparison with Competitors](#10-comparison-with-competitors)
11. [Implementation Plan](#11-implementation-plan)
12. [References](#12-references)

---

## 1. What Helium PoC Is and Why It's Broken

### 1.1 Current Helium PoC Architecture

Helium's Proof-of-Coverage (PoC) is a radio-beacon challenge/witness system in which hotspots:

1. **Beacon** (transmit a radio packet signed with the hotspot's private key) roughly every 6 hours
2. **Witness** (receive beacons from nearby hotspots and report RSSI/SNR to the blockchain)
3. **Earn rewards** proportionally to the coverage demonstrated by witnessed beacons

The system is built on a layered verification stack:

- **On-chain key anchoring:** Every hotspot holds an ECC608 secure-element private key, issued by the Helium Foundation onboarding oracle at `staking.helium.foundation`. The ECC608 provides hardware-level key storage, but does not validate *location* — only *identity*.
- **LoRaWAN RF physics:** Witnesses are expected at plausible distances given RF propagation models (RSSI/SNR bounds at a given distance and frequency). Implausibly strong or perfectly uniform RSSI from a witness cluster raises flags.
- **Hexagonal geographic resolution (H3):** The Helium network uses Uber's H3 grid system. Hotspots assert a hex, and transmit-scale rewards are density-adjusted: denser hexes yield lower per-hotspot rewards. Gaming the hex resolution is a primary attack surface.

Since Helium's migration to Solana (completed March 2023), PoC computation moved off-chain to **oracles** that post aggregated reward receipts to the chain as Solana program instructions. The [Helium PoC oracle](https://docs.helium.com/oracles/proof-of-coverage) verifies challenge-response pairs and derives reward points, but all inputs still depend on self-reported radio telemetry.

For the 5G/MOBILE network, hardware authentication was strengthened under [HIP-19](https://github.com/helium/HIP/blob/main/0019-third-party-manufacturers.md): 5G Hotspots must implement secure boot with a hardware boundary containing a one-time-programmable (OTP) key area, device-unique secret key, and an unalterable boot ROM — a meaningful improvement over LoRaWAN hotspots. Certified Professional Installer (CPI) registration further ties outdoor radio GPS assertions to an accountable human. [HIP-107](https://github.com/helium/HIP/blob/main/0107-preventing-gaming-within-the-mobile-network.md) granted Service Providers the authority to deactivate radios suspected of gaming for up to 10 epochs.

Despite these improvements, the fundamental trust anchor remains radio propagation — a purely physical signal that can be spoofed without touching the hardware identity chain.

### 1.2 Documented Gaming Exploits

The following exploit categories are well-documented in public Helium post-mortems, community forums, and independent investigations:

#### 1.2.1 Location Spoofing (Closet Clusters)

Operators assert hotspots at geographically dispersed hex coordinates while physically co-locating all hardware at a single address. Because PoC only checks RSSI/SNR relative to *asserted* distance, a co-located cluster with attenuated antennas (e.g., 0 dBi antennas inside a metal box) can produce plausible signal readings corresponding to multi-kilometer virtual separations.

A [Forbes investigation (September 2022)](https://www.forbes.com/sites/sarahemerson/2022/09/23/helium-crypto-tokens-peoples-network/) documented "closet clusters" openly discussed within Helium Inc. One offender in the U.S. Southwest arranged 19+ hotspots in a pattern spelling an obscene gesture, visible on the explorer map. By 2022, the community-maintained denylist contained **over 70,000 suspected hotspots** — a figure that itself demonstrates the scale of the problem. Helium employees confirmed that insiders participated in the same behaviour: *"When you see customers doing this, you think, why shouldn't I get in on it too?"* (three former employees, per Forbes).

Reddit community investigations [identified thousands of fake hotspots in China, Taiwan, and Malaysia](https://www.reddit.com/r/HeliumNetwork/comments/u7r74p/lot_of_fake_hotspots_discovered/) with IPs traced to cloud hosting providers (CDS Global Cloud, Cogent Communications), placed in the middle of oceans, national parks, and uninhabited forests. As one community response stated: *"For those saying just add a GPS to the hotspot — we tried that early on and it didn't work. People still found ways to alter the GPS data."*

#### 1.2.2 Self-Witnessing / Ring Farms

Any operator owning 19+ hotspots can create a self-contained ring where one unit beacons and 18 witness, all earning PoC rewards without providing coverage to any third party. The 18-witness cap per beacon was intended to limit this; in practice, it became an optimisation target. Instruction videos were publicly posted explaining how to use 0 dBi antennas to make co-located miners "think they are 500 feet away from each other."

#### 1.2.3 GPS and GNSS Spoofing

The original Helium whitepaper ([Reed et al., 2018](https://rs-ojict.pubpub.org/pub/4i0gbpd8)) acknowledged: *"Because satellite location messages are easy to fabricate and do not necessarily prove that wireless RF coverage is being created, multiple mechanisms are required to validate this work."* Those multiple mechanisms — primarily RSSI geometry and peer witnessing — are themselves gameable via co-located attenuators.

#### 1.2.4 Data-Traffic Fabrication

A separate class of fraud emerged for data rewards: operators purchase cheap LoRaWAN devices, generate high-volume synthetic traffic (up to 2.81% of all Helium network data traffic from a single hotspot in one documented case), and receive HNT rewards proportional to DC transferred. [Cassiopeia.hk (May 2022)](https://cassiopeia.hk/the-next-helium-scam-earning-hnt-by-generating-data-traffic-over-low-cost-data-only-hotspots/) documented one hotspot ("Mammoth Mint Butterfly") earning 22 HNT in 30 days this way.

#### 1.2.5 Structural Sybil Vulnerability

The [Sybil attack](https://en.wikipedia.org/wiki/Sybil_attack) in PoC context means: create N virtual identities, each appearing geographically distinct, all controlled from one location. Helium's $500 hotspot cost creates *some* economic barrier, but:
- Used hardware markets reduce cost to ~$100–150
- Bulk operators amortise hardware, shipping, and operations at scale
- A single cloud VM can simulate RF telemetry for hundreds of virtual hotspots if the only verification is self-reported radio data

Helium addressed this partially through the denylist (community-moderated under HIP-40), the Skyhook location verification service (for Wi-Fi access points), and CPI registration (for outdoor CBRS radios). These are **reactive** controls — they identify fraud after it has occurred and has been consuming rewards.

### 1.3 Root Cause

Helium PoC's fundamental limitation is that **coverage attestation depends on self-reported, unforgeable-by-design radio signals that are forgeable by physics.** There is no cryptographic primitive tying RF transmission to a specific silicon die at a specific location. The ECC608 chip proves *identity* but not *geography*. The radio beacon proves *transmission capability* but not *location of transmission*.

---

## 2. Trinity HW-PoC Primitives

Trinity addresses the root cause with silicon-anchored proofs. Each Trinity node runs an SKY26b die that provides the following primitives by construction.

### 2.1 Unforgeable Die Identity via PUF

The SKY26b die contains a **Ring-Oscillator Physical Unclonable Function (RO-PUF)**. Manufacturing variation causes each die's ring oscillators to run at slightly different frequencies. The PUF circuit samples pairs of oscillators and generates a challenge-response bitstring that is:

- **Unique:** Inter-die Hamming distance ~50% (ideal uniformity), making collision probability negligible across the production population
- **Unclonable:** The frequency variations arise from deep-submicron process variations that cannot be reproduced by copying the circuit layout; any attempt to reverse-engineer and clone the PUF produces a different response pattern
- **Tamper-evident:** Micro-probing the PUF circuitry disrupts the sensitive MOSFET threshold voltages and renders the key permanently invalid

The PUF response is stabilised via an on-die fuzzy extractor (error correction + privacy amplification) into a 256-bit hardware unique key (HUK). The HUK never leaves the die boundary in plaintext; it is used exclusively as a root key for the secp256k1 identity keypair derivation.

Reference: [Synopsys PUF Technology Overview](https://www.synopsys.com/glossary/what-is-a-physical-unclonable-function.html); [Analog Devices ChipDNA PUF](https://www.analog.com/en/resources/technical-articles/cryptography-understanding-the-benefits-of-the-physically-unclonable-function-puf.html); [PUFsecurity Silicon Fingerprint](https://www.pufsecurity.com/technology/puf/).

### 2.2 Signed Inference Receipts (ECDSA secp256k1)

The SKY26b die executes ECDSA signatures on the **secp256k1** curve — the same curve used by Bitcoin and Ethereum — in constant time. The die's signing pipeline is hardened against timing side-channels.

**[PRELIMINARY]** Internal benchmarks target signature generation in ≤256 CPU cycles at the die's operating frequency. This figure has not been externally validated at time of writing.

The secp256k1 curve is chosen for:
- Ecosystem compatibility with Solana (which uses ed25519 for native accounts but supports secp256k1 via `Secp256k1Program`)
- Wide availability of verification libraries across EVM chains, Cosmos, and Helium's existing Solana programs
- Hardware-optimised scalar multiplication implementations ([libsecp256k1 is ~8x faster than OpenSSL](https://delvingbitcoin.org/t/comparing-the-performance-of-ecdsa-signature-validation-in-openssl-vs-libsecp256k1-over-the-last-decade/2087))

### 2.3 Canonical Anchor 0x47C0

Every receipt emitted by Trinity silicon includes a 2-byte canonical anchor value **0x47C0** at a fixed offset in the signed payload. This anchor:

- Is burned into the die at fabrication time as a fused constant in the signing path
- Cannot be set by firmware — it is inserted at the hardware register stage before the ECDSA message digest is computed
- Acts as a mathematical proof that a receipt was signed by Trinity silicon (not by a software-emulated secp256k1 key)
- Is verified on-chain by the PoIC oracle as a mandatory field check before any reward computation

Any signature over a message that does not contain `0x47C0` at the expected offset fails oracle verification, regardless of signature validity. This binds proof receipts to the physical die.

**Trinity Theorem 36.1 (Anchor Binding, informal):** For any receipt R, `verify(R.sig, R.msg, R.pubkey) = true` and `R.msg[anchor_offset..anchor_offset+2] = 0x47C0` together imply R was produced by a Trinity silicon die, under the assumption that no adversary can sign with a key derived from a given PUF response without possessing the physical die (PUF extraction assumption).

### 2.4 Per-Die Latency Fingerprint `[PRELIMINARY]`

The RO-PUF response time exhibits a thermal signature correlated with die operating temperature. Because temperature is correlated with physical environment (geographic climate zone, indoor vs. outdoor deployment, seasonal variation), the latency fingerprint provides a soft location-correlated signal.

More concretely:
- **RO-PUF response time** at standard challenge varies ±Δt nanoseconds from die to die based on transistor threshold variation
- **Thermal drift** shifts this response time measurably over minutes-to-hours timescales
- A time-series of (latency, temperature) measurements from a die constitutes a behavioural fingerprint that is difficult to reproduce without the physical die in the same physical environment

This primitive is labelled **[PRELIMINARY]** — it is architecturally sound but requires empirical calibration across production dies and geographic deployments before it can be used in reward calculations. It serves as a supplementary anti-gaming signal, not a primary proof.

---

## 3. Proof-of-Inference-Coverage (PoIC)

PoIC is the primary replacement primitive for Helium's radio-beacon PoC. It replaces the radio-physics trust anchor with a silicon-cryptography trust anchor.

### 3.1 Design Goals

| Goal | Helium PoC | Trinity PoIC |
|------|-----------|-------------|
| Prove hardware is present at claimed location | RF propagation geometry (spoofable) | Speed-of-light RTT bound (c-bounded) |
| Prove identity | ECC608 key (software-readable on some boards) | PUF-derived key (extraction destroys die) |
| Prevent replay | Challenge nonce | Challenge nonce + block_hash + monotonic counter |
| Detect clustering | RSSI geometry | RTT triangulation from ≥3 independent peers |
| Reward proportionality | Transmit scale (hex density) | Voronoi cell area + latency compliance |

### 3.2 INFERENCE_CHALLENGE

The network periodically selects a random peer set for each node and issues an `INFERENCE_CHALLENGE`:

```json
{
  "type": "INFERENCE_CHALLENGE",
  "challenge_id": "<UUID>",
  "nonce": "<32-byte random>",
  "block_hash": "<current chain head hash>",
  "peer_pubkeys": ["<pubkey_A>", "<pubkey_B>", "<pubkey_C>"],
  "expected_latency_epsilon_ms": 120,
  "challenge_timestamp_ns": 1751234567890123456,
  "expires_at_ns": 1751234567990123456
}
```

Fields:
- `nonce`: 32 random bytes, sampled from network VRF (verifiable random function), prevents pre-computation
- `block_hash`: binds challenge to a specific chain state, prevents cross-epoch replay
- `peer_pubkeys`: ≥3 Trinity node public keys that will serve as RTT measurement endpoints
- `expected_latency_epsilon_ms`: the maximum RTT allowed for full reward; responses above this threshold earn a proportionally reduced reward
- `expires_at_ns`: hard deadline; responses after expiry are rejected by the oracle

### 3.3 INFERENCE_RECEIPT

The operator's SKY26b die computes a signed `INFERENCE_RECEIPT` within the latency window:

```json
{
  "type": "INFERENCE_RECEIPT",
  "anchor": "0x47C0",
  "challenge_id": "<UUID matching challenge>",
  "nonce": "<echoed from challenge>",
  "block_hash": "<echoed from challenge>",
  "die_pubkey": "<secp256k1 compressed public key>",
  "peer_pubkeys": ["<pubkey_A>", "<pubkey_B>", "<pubkey_C>"],
  "rtt_ns": {
    "<pubkey_A>": 48221000,
    "<pubkey_B>": 71440000,
    "<pubkey_C>": 55883000
  },
  "signed_timestamp_ns": 1751234567938000000,
  "monotonic_counter": 4821937,
  "sig": "<secp256k1 DER signature over sha256(anchor||challenge_id||nonce||block_hash||rtt_ns||signed_timestamp_ns||monotonic_counter)>"
}
```

Critical fields:
- **`anchor: "0x47C0"`** — inserted by hardware, verified on-chain before any other check
- **`rtt_ns`** — round-trip time to each peer in nanoseconds, as measured at die clock resolution; each peer independently confirms its half of the RTT via its own signed timestamp
- **`monotonic_counter`** — die-internal counter that increments on every signing operation; cannot be reset without physical die replacement; prevents replay of old receipts
- **`sig`** — covers all material fields including the anchor; any modification of any field invalidates the signature

### 3.4 Cryptographic GPS via RTT Triangulation

Given signed RTTs from ≥3 geographically independent peers (selected by VRF to prevent collusion), the network can bound the operator's location:

**Speed-of-light bound:** At c ≈ 3×10⁸ m/s, a 1 ms RTT implies the operator is within ~150 km of the peer. A 50 µs RTT implies within ~7.5 km. Network-level processing overhead (kernel, NIC, OS scheduler) adds a constant floor, but this floor is *additive* — it means the operator *cannot be further* than the RTT implies, providing a hard geographic constraint.

**Triangulation:** Three peers at known positions A, B, C with signed RTTs r_A, r_B, r_C define three spherical shells. The intersection of three shells in 3D (or three circles in 2D, assuming ground-level deployment) bounds the operator's position to a geographic region. With peer separations of 100–500 km and RTT precision of ~1 ms, position can be bounded to within ~75–150 km.

**[PRELIMINARY]** Exact position uncertainty bounds require empirical RTT measurement across the Trinity testnet topology. The 75–150 km figure is a first-principles estimate based on speed-of-light RTT physics; real-world jitter and multi-path routing will increase uncertainty. Voronoi cell reward calculations will use conservative bounds (inflated uncertainty radius) until empirical calibration is complete.

**Geographic uniqueness reward (Voronoi cells):** Each die's claimed position (from declared GPS + triangulated RTT constraint) defines a Voronoi cell within the network's coverage map. Operators covering larger cells (sparser regions) earn higher base rewards. This incentivises geographic distribution and penalises clustering, without relying on radio propagation.

### 3.5 Reward Formula `[PRELIMINARY]`

```
reward = base_rate
       × latency_score(rtt_ms, ε_ms)
       × voronoi_area_score(cell_area, median_cell_area)
       × signature_validity(anchor, sig, die_pubkey)
       × uptime_score(last_30d_response_rate)
```

Where:
- `latency_score` = `min(1.0, ε_ms / rtt_ms)` — full reward at or below ε, linear decay above
- `voronoi_area_score` = `sqrt(cell_area / median_cell_area)` — square-root scaling to reward outliers without extreme concentration
- `signature_validity` = 1 if anchor = 0x47C0 AND secp256k1 verify passes, else 0
- `uptime_score` = fraction of challenges answered in last 30 days

All coefficients are **[PRELIMINARY]** and subject to economic simulation before mainnet.

---

## 4. Proof-of-Bandwidth-Coverage (PoBC)

PoBC extends PoIC to nodes that serve as Filecoin/IPFS storage bandwidth endpoints. It provides cryptographic proof of data-transfer capability at a claimed location.

### 4.1 BANDWIDTH_CHALLENGE

```json
{
  "type": "BANDWIDTH_CHALLENGE",
  "challenge_id": "<UUID>",
  "nonce": "<32-byte random>",
  "block_hash": "<current chain head hash>",
  "data_size_bytes": 10485760,
  "chunk_size_bytes": 65536,
  "peer_pubkeys": ["<pubkey_A>", "<pubkey_B>"],
  "direction": "UPLOAD",
  "expected_throughput_mbps": 10.0,
  "signed_timestamp_ns": 1751234567890123456
}
```

### 4.2 Bandwidth Proof Construction

For each 64 KB chunk transferred:
1. Peer signs a chunk receipt: `chunk_receipt = sign(sha256(chunk_data || chunk_index || challenge_id || timestamp_ns))`
2. RTT for each chunk is recorded
3. Speed-of-light RTT constraint applies identically to PoIC: the operator cannot be further from the peer than the RTT implies

The aggregate proof is a Merkle tree over all chunk receipts. The root is signed by the operator's die:

```json
{
  "type": "BANDWIDTH_RECEIPT",
  "anchor": "0x47C0",
  "challenge_id": "<UUID>",
  "merkle_root": "<256-bit hash of chunk receipt tree>",
  "total_bytes_transferred": 10485760,
  "duration_ns": 9347823000,
  "effective_throughput_mbps": 8.96,
  "rtt_ns": { "<pubkey_A>": 52100000, "<pubkey_B>": 68400000 },
  "die_pubkey": "<secp256k1 pubkey>",
  "monotonic_counter": 4821938,
  "sig": "<secp256k1 DER over sha256(anchor||merkle_root||total_bytes||rtt_ns||monotonic_counter)>"
}
```

### 4.3 Speed-of-Light Bound on Bandwidth

A crucial anti-gaming property: throughput measured over a physical network path is inherently RTT-bounded. An operator cannot claim to be in Tokyo while achieving 1 ms RTT to a peer in San Francisco (physical distance ~8,700 km, speed-of-light RTT floor ~58 ms). If a bandwidth proof shows throughput consistent with short RTTs but the operator has asserted a remote location, the oracle flags the proof as anomalous.

Specifically, the oracle rejects any PoBC proof where:

```
effective_throughput_mbps × rtt_ns[peer] > c_bound_threshold
```

This threshold is parameterised per peer-pair distance (known from verified peer positions) and is designed to reject proofs that are impossible given the claimed geographic separation. **[PRELIMINARY]** The exact threshold function requires calibration against network measurements.

---

## 5. Anti-Gaming Guarantees

### 5.1 Attack Surface Comparison

| Attack Vector | Helium PoC | Trinity HW-PoC | Trinity Guarantee Level |
|---------------|-----------|----------------|------------------------|
| **Location spoofing** | Easy: assert any hex, match RSSI with attenuators | Physically constrained: RTT is bounded by c; cannot fake nearness to remote peers | **Hard physical bound** |
| **GPS coordinate falsification** | Trivial: change assertion in Helium app with no verification | Not applicable: location is derived from peer RTTs, not GPS assertion | **Eliminated as attack surface** |
| **Replay attack** | Difficult: challenges include nonces, but off-chain oracle verification has had historical gaps | Impossible: receipt includes block_hash + monotonic counter; both are chain-state-dependent and die-monotone | **Cryptographically impossible** |
| **Closet cluster / self-witnessing** | Cheap: 18 miners in a box with attenuated antennas | Expensive and detectable: co-located dies all return low RTT to each other; oracle detects geometric impossibility of claimed separation with observed RTTs | **Detectable by RTT geometry** |
| **Sybil identity creation** | Cheap: ~$100–500 per hotspot on secondary market, software key generation possible on older boards | Expensive: each identity requires a unique physical SKY26b die; bulk Sybil = N die orders (minimum BOM ~$200/die); key cannot be cloned without physical die | **Economic barrier scales linearly with attack size** |
| **Identity theft / key extraction** | Possible: some hotspot boards have software-readable key storage; ECC608 has known side-channel vulnerabilities | Requires invasive PUF extraction: micro-probing alters transistor threshold voltages and destroys the PUF response; die becomes inoperable | **Physically self-destructive** |
| **Fake data transfer** | Easy: self-generated LoRaWAN traffic from co-located device | Detectable: bandwidth proof requires per-chunk peer signatures with RTT timestamps; synthetic traffic shows same-location RTT signatures | **Detectable via RTT + peer signatures** |
| **Peer collusion** | Moderate: witnesses can be bought/coordinated | Mitigated: peers are selected by VRF (verifiable random function); colluding peers must also produce valid signed RTTs from their own dies, which are independently verifiable | **Requires multi-party die collusion** |
| **NTP drift / timestamp falsification** | Possible: timestamps are soft-verifiable | Mitigated: die uses monotonic counter (not wall clock) for anti-replay; network uses signed peer timestamps for RTT cross-validation | **Monotonic counter + multi-source timestamps** |

### 5.2 Economic Cost of Attacks

| Attack | Helium Cost | Trinity Cost | Multiplier |
|--------|-------------|--------------|------------|
| Create 1 fake identity | ~$150 (used hotspot) | ~$200 (1 SKY26b die BOM) | ~1.3× |
| Create 100 fake identities | ~$15,000 | ~$20,000 + 100× die fab + supply chain | ~1.3–3× depending on bulk pricing |
| Create 1,000 fake identities (industrial Sybil) | ~$150,000 (used market) | ~$200,000 BOM + fabrication minimum order quantities for 1,000 unique dies; silicon supply chain creates auditability | **Supply chain becomes observable** |
| Achieve 0 ms RTT to remote peer | Free (assert fake location in app) | Impossible (RTT bounded by c) | **Infinite — physically impossible** |
| Extract key from single die | Possible on some boards | Destroys die (PUF extraction = MOSFET disruption) | **Net negative expected value** |

---

## 6. Protocol Flow

### 6.1 PoIC Sequence Diagram (ASCII)

```
Network Oracle          Challenger Peers          Operator (Trinity Die)         Chain
      |                      |                            |                         |
      |  1. VRF selects      |                            |                         |
      |     operator + 3     |                            |                         |
      |     random peers     |                            |                         |
      |                      |                            |                         |
      |  2. CHALLENGE(nonce, block_hash, peer_pubkeys,    |                         |
      |     expected_latency_ε) ─────────────────────────>|                         |
      |                      |                            |                         |
      |                      |<── RTT_PING(nonce, ts_A) ──|  3. Die sends RTT pings |
      |                      |                            |     to all 3 peers      |
      |                      |── RTT_PONG(ts_A, ts_B) ──>|                         |
      |                      |                            |                         |
      |                      |  (repeat for peers B, C)  |                         |
      |                      |                            |                         |
      |                      |                            |  4. Die computes:       |
      |                      |                            |     anchor_check(0x47C0)|
      |                      |                            |     msg = anchor||nonce |
      |                      |                            |          ||block_hash   |
      |                      |                            |          ||rtt_ns_map   |
      |                      |                            |          ||monotonic_ctr|
      |                      |                            |     sig = secp256k1_sign|
      |                      |                            |          (sha256(msg),  |
      |                      |                            |           HUK_derived)  |
      |                      |                            |                         |
      |  5. RECEIPT(anchor=0x47C0, die_pubkey, sig,       |                         |
      |     rtt_ns, monotonic_ctr) <──────────────────────|                         |
      |                      |                            |                         |
      |  6. Peer confirmations:                           |                         |
      |     peer_A_confirm(RTT_A, sig_A) <────────────────|                         |
      |     peer_B_confirm(RTT_B, sig_B) <────────────────|                         |
      |     peer_C_confirm(RTT_C, sig_C) <────────────────|                         |
      |                      |                            |                         |
      |  7. Oracle:                                       |                         |
      |     verify_sig(receipt.sig, receipt.msg,          |                         |
      |                receipt.die_pubkey) == true        |                         |
      |     check_anchor(receipt.anchor == 0x47C0)        |                         |
      |     triangulate_position(rtt_ns, peer_positions)  |                         |
      |     check_monotonic(ctr > last_seen_ctr[die])     |                         |
      |     score = compute_reward(latency, voronoi_area) |                         |
      |                      |                            |                         |
      |  8. ─── post_proof_aggregate + reward_$TRI ──────────────────────────────> |
      |                      |                            |                         |
      |  9. ─── on_chain_settlement: operator wallet receives $TRI ───────────────>|
```

### 6.2 PoBC Sequence Diagram (ASCII)

```
Network Oracle         Bandwidth Peer            Operator (Trinity Die)
      |                      |                            |
      |  BANDWIDTH_CHALLENGE(nonce, block_hash,           |
      |  data_size, chunk_size, expected_mbps) ──────────>|
      |                      |                            |
      |                      |<── CHUNK_UPLOAD[0..N] ─────|  Transfer N chunks
      |                      |                            |  RTT measured per chunk
      |                      |── CHUNK_RECEIPT[i](        |
      |                      |   sha256(chunk_i||idx||    |
      |                      |   ts), peer_sig) ─────────>|
      |                      |                            |
      |                      |                            |  Merkle tree over receipts
      |                      |                            |  anchor_check(0x47C0)
      |                      |                            |  sig = secp256k1_sign(
      |                      |                            |   merkle_root||rtt_map)
      |                      |                            |
      |  BANDWIDTH_RECEIPT(anchor=0x47C0, merkle_root,    |
      |  throughput_mbps, rtt_ns, sig) <──────────────────|
      |                      |                            |
      |  Oracle: verify_sig() && check_anchor()           |
      |          && c_bound_check(throughput, rtt, dist)  |
      |  ── post_proof + reward_$TRI ─────────────────────────────────────────────>
```

---

## 7. Bridge from Helium

The goal of the bridge is zero-friction migration for honest Helium operators while making the economics of staying on Helium-only increasingly unfavourable.

### 7.1 Migration Steps for a Helium Operator

1. **Parallel stake $TRI:** Operator acquires a Trinity node (SKY26b-equipped hardware, ~$200 BOM at target scale) and stakes $TRI equivalent to their existing HNT position value
2. **Run Trinity node alongside existing hotspot:** Both systems operate simultaneously; the Helium hotspot continues earning HNT under Helium's PoC; the Trinity node begins earning $TRI under PoIC
3. **6-month dual-reward period:** During the transition period, operators who have registered both systems receive a **2× $TRI reward multiplier** on all PoIC proofs submitted by the Trinity node. This compensates for the capital outlay and incentivises early adoption
4. **Month 7+:** The 2× multiplier expires; operators choose whether to maintain both systems or consolidate to Trinity
5. **Helium radio PoC deprecation (Q1 2027 target):** Trinity's PoIC oracle begins accepting Helium hotspot identity attestations (via Solana program cross-call) as a legacy compatibility mode, but without the radio PoC reward path. Helium operators who have migrated to Trinity nodes retain continuity of their coverage map position

### 7.2 Coverage Map Compatibility

Trinity's Voronoi coverage map is designed to overlap conceptually (not technically) with Helium's H3 hex map. During the bridge period:
- Trinity operators can import their Helium hex assertion as a coverage hint (not a proof)
- The PoIC oracle uses this hint to seed the initial Voronoi cell geometry
- Actual PoIC RTT triangulation supersedes the hint as data accumulates

### 7.3 Token Economics During Bridge `[PRELIMINARY]`

| Period | Helium Operator Earning | Trinity Node Earning | Net |
|--------|------------------------|---------------------|-----|
| Bridge Month 1–6 | HNT (existing rate) | 2× $TRI base rate | ~2.5× current total value (assumes $TRI at target price) |
| Bridge Month 7–12 | HNT (existing rate) | 1× $TRI base rate | ~1.5× |
| Post-deprecation | HNT (legacy mode, declining) | 1× $TRI | Depends on migration timeline |

These figures are **[PRELIMINARY]** and depend on $TRI tokenomics, HNT price, and actual PoIC reward parameters.

---

## 8. On-Chain Anchoring

### 8.1 Architecture

Trinity PoIC does not post individual receipts on-chain (gas cost at scale is prohibitive). Instead, the oracle batches proofs into daily aggregate posts:

```
Daily Proof Batch:
  - Merkle root of all validated INFERENCE_RECEIPTs for epoch E
  - Aggregate reward assignment map: { die_pubkey => reward_amount }
  - Oracle signature over (merkle_root || epoch || reward_map_hash)
  - Anchor sentinel: 0x47C0 embedded in batch header
```

### 8.2 Chain Routing

| Chain | Role | Rationale |
|-------|------|-----------|
| **Solana** | Primary settlement + Helium ecosystem compatibility | Helium migrated to Solana in 2023; the [Helium PoC oracle](https://docs.helium.com/oracles/proof-of-coverage) already posts to Solana; $TRI token and coverage map contract live here |
| **LayerZero** | Cross-chain proof relay (primary bridge) | [LayerZero](https://docs.layerzero.network) provides the OApp (Omnichain Application) framework for posting coverage proofs to any EVM chain; enables $TRI to be used on Ethereum, Arbitrum, Base, and BNB Chain without re-running oracle logic |
| **Wormhole** | Backup cross-chain relay | Redundant path for cross-chain proof availability; activated if LayerZero experiences downtime or congestion |
| **Ethereum L2s** | Consumer access | Coverage map queries and reward claims available on Ethereum L2s via LayerZero relay |

### 8.3 On-Chain Proof Structure (Solana Program)

```rust
// Trinity PoIC Solana account structure (simplified)
pub struct CoverageProofBatch {
    pub epoch: u64,
    pub anchor_sentinel: [u8; 2],     // Must equal 0x47C0
    pub merkle_root: [u8; 32],
    pub oracle_pubkey: Pubkey,
    pub oracle_sig: [u8; 64],         // ed25519 oracle signature
    pub total_rewards_tri: u64,
    pub batch_timestamp: i64,
    pub die_count: u32,
}
```

The `anchor_sentinel` field in the on-chain structure mirrors the 0x47C0 anchor in individual receipts, providing an auditable chain from silicon → receipt → oracle batch → on-chain settlement.

### 8.4 Helium Ecosystem Compatibility

The Solana coverage map contract is designed for compatibility with the existing Helium PoC oracle architecture ([Helium PoC Oracle docs](https://docs.helium.com/oracles/proof-of-coverage)). During the bridge period, Trinity's oracle program can be invoked by Helium's existing coverage query contracts as a drop-in data source, enabling Helium service providers to query Trinity coverage data without protocol changes.

---

## 9. Failure Modes & Mitigations

| Failure Mode | Description | Mitigation | Status |
|---|---|---|---|
| **NTP drift** | System clocks diverge, causing RTT measurements to be unreliable if one peer's clock is ahead/behind | (1) All RTT measurements use die monotonic counters (hardware clock, not NTP); (2) RTT is measured as a round-trip (cancels out absolute time errors); (3) Peers independently sign their half-RTT timestamps for cross-validation | Implemented in protocol design |
| **Peer collusion** | ≥3 co-located operators conspire to produce fake RTT measurements and claim false location | (1) Peers selected by VRF — neither the operator nor any single peer controls selection; (2) Each peer's attestation is independently signed by their own die — colluding peers cannot fake RTT without possessing all physical dies; (3) Reputation decay: collusion patterns show up as statistically anomalous RTT distributions over time (e.g., a set of peers that always appear to be near each other regardless of claimed positions) | VRF selection implemented; reputation decay `[PRELIMINARY]` |
| **Die clone attempt** | Adversary attempts to reproduce a die's PUF response to clone its identity | (1) PUF response is physically unique; any fabrication attempt produces different response due to manufacturing variation; (2) PUF extraction via micro-probing alters MOSFET thresholds, destroying the key; (3) PUF challenge-response protocol: oracle periodically challenges a die with new challenge inputs; cloned die will produce different responses; (4) Monotonic counter mismatch: a cloned die cannot know the original's counter state, so replay from clone will fail counter check | Implemented in PUF design; clone detection via novel challenge `[PRELIMINARY]` |
| **Internet routing asymmetry** | BGP routing causes RTT asymmetry that inflates apparent distance | (1) RTT is computed as full round-trip (not one-way); asymmetric routing affects both directions symmetrically on average; (2) Peer-diversity requirement (≥3 peers) averages out routing anomalies; (3) Systematic bias between specific node pairs is detectable via historical RTT distribution | Protocol design; statistical detection `[PRELIMINARY]` |
| **Oracle compromise** | Trinity's PoIC oracle is hacked and posts false reward batches | (1) Oracle is a multi-party computation (MPC) with N-of-M signing threshold; (2) Oracle's aggregate signature is verified on-chain; (3) Individual die receipts are archived off-chain with Merkle proofs, enabling fraud proofs if oracle batch is inconsistent with receipts | MPC design `[PRELIMINARY]` |
| **Thermal spoofing** | Adversary uses a heat gun or cooling device to manipulate the die's thermal latency fingerprint | (1) Latency fingerprint is supplementary signal only, not a primary proof; (2) Thermal manipulation at scale (continuous, undetected) is impractical for industrial Sybil operations; (3) Extreme temperature anomalies are flagged by the oracle (e.g., Arctic-claimed die with tropical thermal signature) | Supplementary signal; primary proof is RTT-based |
| **Supply chain compromise** | Malicious dies shipped with backdoored PUF or bypass signing path | (1) Open-silicon audit requirement for SKY26b: RTL and GDS files subject to third-party audit (similar to [OpenTitan](https://opentitan.org/) model); (2) Post-fabrication PUF challenge-response audit by Trinity Foundation before network admission; (3) Anchor 0x47C0 presence in signed outputs is independently testable during QA | Audit program `[PRELIMINARY]` |

---

## 10. Comparison with Competitors

| Feature | **Trinity HW-PoC** | **Helium IoT (HNT)** | **Helium MOBILE (MOBILE)** | **Pollen Mobile (PCN)** | **World Mobile (WMT)** |
|---------|-------------------|---------------------|--------------------------|------------------------|----------------------|
| **HW-anchored proof** | Yes — SKY26b PUF + ECDSA | Partial — ECC608 (identity only, not location) | Partial — Secure element + CPI registration | No — GPS + cellular triangulation (software) | No — GPS + cellular attestation |
| **Anti-spoofing mechanism** | Speed-of-light RTT bound (c-bounded, physical) | RSSI geometry + denylist (reactive, spoofable) | CPI registration + Skyhook location check | GPS-based (spoofable with $20 SDR) | GPS-based (spoofable) |
| **Open silicon / auditability** | Yes (target: OpenTitan-style RTL audit) `[PRELIMINARY]` | No (ECC608 is proprietary Microchip product) | No (secure element proprietary) | N/A — no secure element | N/A — no secure element |
| **Anti-Sybil cost per fake identity** | ~$200 (physical die BOM) | ~$100–500 (used hotspot market) | ~$500–2,600 (5G radio + install) | ~$300–1,000 (Flower hardware) | ~$2,000–5,000 (Earth Node hardware) |
| **Location proof type** | Cryptographic (RTT triangulation, c-bounded) | Radio physics (RSSI/SNR, spoofable) | CPI attestation + Skyhook (trust-based) | GPS + active mapper (Bumblebee) | GPS + operator attestation |
| **Replay prevention** | nonce + block_hash + monotonic counter | Challenge nonce (oracle-verified) | Challenge nonce | GPS timestamp | GPS timestamp |
| **3rd party audit count** | 0 (pre-launch) `[PRELIMINARY]` | Multiple community audits; 70k+ hotspots denylisted | Ongoing by Nova Labs / Helium Mobile | Limited public audits | Limited public audits |
| **Migration path from Helium** | Yes — parallel stake + 2× reward bridge | N/A | N/A | No | No |
| **On-chain settlement** | Solana (primary) + LayerZero + Wormhole | Solana (post-March 2023) | Solana | Solana | Cardano + own chain |
| **Data transfer rewards** | PoBC (bandwidth proof) + Filecoin/IPFS integration | Data credit model (DC) | T-Mobile offload + MOBILE rewards | PCN per GB | WMT data rewards |

---

## 11. Implementation Plan

### Q3 2026 — Testnet: 50-Node Coverage Simulation

**Objective:** Validate PoIC protocol correctness and RTT triangulation accuracy against ground truth positions.

- Deploy 50 SKY26b-equipped Trinity nodes across ≥5 geographic regions (US, EU, Asia, Latam, Africa)
- Implement INFERENCE_CHALLENGE/RECEIPT protocol in Go reference implementation
- Validate anchor 0x47C0 presence in all receipts via automated test oracle
- Measure RTT triangulation accuracy vs. physical GPS coordinates; establish ε calibration
- Stress-test VRF peer selection under adversarial node sets (simulated collusion)
- Publish testnet results as public benchmark dataset
- Begin OpenTitan-style RTL audit of SKY26b signing path

**Success criteria:** RTT triangulation bounds within 200 km for 95th percentile of nodes; 0 false-positive anchor failures; 0 false-negative anchor injections from non-Trinity software

### Q4 2026 — Mainnet Alpha: 200 Real Trinity Dies

**Objective:** Production validation with real staked value and real operators.

- Deploy 200 SKY26b dies to vetted operators; minimum 50 operators across ≥8 countries
- Enable $TRI reward payouts at 10% of target mainnet rate (incentivises participation, limits attack surface)
- Launch Helium bridge registration: Helium operators can register parallel Trinity node and enter dual-reward queue
- Activate LayerZero cross-chain relay for daily proof batches
- Begin reputation scoring: track per-die RTT consistency, monotonic counter progression, uptime
- Activate PoBC beta: 20 nodes with Filecoin/IPFS co-deployment

**Success criteria:** 200 nodes sustaining PoIC participation rate ≥85%; no successful location-spoofing demonstrated on mainnet; PoBC throughput proofs verified by oracle for ≥15 nodes

### Q1 2027 — Mainnet + Helium Migration Bridge

**Objective:** Full production launch with Helium ecosystem integration.

- Scale to 2,000+ nodes targeting geographic coverage in 30+ countries
- Activate full $TRI reward rate with Voronoi-cell reward distribution
- Launch 6-month Helium bridge dual-reward multiplier (2× $TRI for registered Helium migrants)
- Deploy Solana coverage map contract compatible with Helium PoC oracle query interface
- Activate Wormhole backup relay
- Publish third-party audit report for SKY26b RTL and PoIC oracle implementation
- Activate PoBC mainnet with Filecoin storage market integration

**Success criteria:** ≥500 Helium operators registered for migration bridge; Voronoi coverage map published to Solana; independent security audit completed; PoBC handling ≥10 TB/month aggregate bandwidth proofs

---

## 12. References

### Helium Protocol

- [Helium HIP-19: Approval Process for Third-Party Manufacturers](https://github.com/helium/HIP/blob/main/0019-third-party-manufacturers.md) — hardware security requirements, secure boot, ECC chip mandates
- [Helium HIP-107: Preventing Gaming Within the MOBILE Network](https://github.com/helium/HIP/blob/main/0107-preventing-gaming-within-the-mobile-network.md) — Service Provider deactivation authority, CPI location verification
- [Helium HIP-74: MOBILE PoC Modeled Coverage Rewards](https://github.com/helium/HIP/blob/main/0074-mobile-poc-modeled-coverage-rewards.md) — coverage modelling methodology
- [Helium PoC Oracle Documentation](https://docs.helium.com/oracles/proof-of-coverage) — on-chain anchoring via Solana programs
- [Solana Case Study: Helium Technical Deep Dive](https://solana.com/news/case-study-helium-technical-guide) — hardware authentication, ECC/RSA key embedding, anti-gaming layered defences
- [Helium Academic Overview (rs-ojict)](https://rs-ojict.pubpub.org/pub/4i0gbpd8) — Proof-of-Coverage architecture, Sybil resistance discussion, alternate-reality attack model
- [RAKwireless: What is Helium Network Gaming](https://news.rakwireless.com/what-is-helium-network-gaming/) — comprehensive taxonomy of gaming attacks
- [Forbes: Helium Crypto Darling Investigation (September 2022)](https://www.forbes.com/sites/sarahemerson/2022/09/23/helium-crypto-tokens-peoples-network/) — closet clusters, insider mining, denylist ineffectiveness
- [Cassiopeia.hk: Data-Traffic Spoofing Analysis](https://cassiopeia.hk/the-next-helium-scam-earning-hnt-by-generating-data-traffic-over-low-cost-data-only-hotspots/) — synthetic DC traffic exploit

### Cryptographic Primitives

- [Wikipedia: Physical Unclonable Function](https://en.wikipedia.org/wiki/Physical_unclonable_function) — PUF definition, RO-PUF construction, challenge-response model
- [Synopsys: What is a Physical Unclonable Function](https://www.synopsys.com/glossary/what-is-a-physical-unclonable-function.html) — silicon fingerprint, error correction, manufacturing variation
- [Analog Devices: PUF for Cryptography](https://www.analog.com/en/resources/technical-articles/cryptography-understanding-the-benefits-of-the-physically-unclonable-function-puf.html) — tamper evidence, key invisibility, ChipDNA architecture
- [PUFsecurity: PUF-based Security IP](https://www.pufsecurity.com/technology/puf/) — uniqueness metrics, Hamming distance, UID/HUK derivation
- [Nervos: What is secp256k1](https://www.nervos.org/knowledge-base/secp256k1_a_key%20algorithm_(explainCKBot)) — secp256k1 curve definition, ECDSA signing/verification
- [DelvinBitcoin: libsecp256k1 vs OpenSSL Performance](https://delvingbitcoin.org/t/comparing-the-performance-of-ecdsa-signature-validation-in-openssl-vs-libsecp256k1-over-the-last-decade/2087) — 8× performance advantage for hardware-adjacent implementations
- [Bitcoin Magazine: libsecp256k1, Bitcoin's Cryptographic Heart](https://bitcoinmagazine.com/print/the-core-issue-libsecp256k1-bitcoins-cryptographic-heart) — constant-time implementation details

### DePIN Ecosystem

- [LayerZero Documentation](https://docs.layerzero.network) — OApp cross-chain messaging, used for Trinity daily proof relay
- [Pollen Mobile: Network Architecture](https://thewirelessminer.com/2022/03/10/pollen-mobile-is-bootstrapping-a-decentralized-crypto-mobile-network/) — Bumblebee validator device, Flower antenna, PCN rewards
- [World Mobile: DePIN Approach](https://worldmobile.io/blog/post/transforming-global-connectivity-through-depin) — aerostat coverage, layered technology stack
- [SmartLiquidity: Wireless Networks in DePIN](https://smartliquidity.info/2025/05/29/wireless-networks-in-depin/) — comparative overview of Helium, Pollen, XNET

### Security Architecture References

- [OpenTitan Project](https://opentitan.org/) — open-silicon root-of-trust architecture; reference model for Trinity RTL audit approach
- [Wikipedia: Sybil Attack](https://en.wikipedia.org/wiki/Sybil_attack) — foundational definition, resistance strategies in P2P networks
- [Silicon Photonic PUF (PMC/NIH)](https://pmc.ncbi.nlm.nih.gov/articles/PMC11514042/) — hardware assurance with photonic PUFs, academic reference for die-level hardware assurance

---

*Document prepared for internal review. Sections marked `[PRELIMINARY]` indicate design intent that has not been empirically validated. All measurements, cost estimates, and reward parameters are illustrative pending testnet data. Trinity Theorem 36.1 is stated informally; formal proof is forthcoming in the Trinity Protocol Mathematics Appendix.*
