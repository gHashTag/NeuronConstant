# Trinity Node Hardware Kit — BOM & Mainnet Rollout Plan 2027

**Project:** Trinity TRI-NET DePIN Node  
**Author:** Dmitrii Vasilev (NeuronConstant / IGLA / Trinity TRI-27)  
**Date:** 2026-05-18 (strategy baseline) → 2027 execution plan  
**Status:** Product specification — pre-production draft  
**Version:** 1.0.0  
**License:** Apache-2.0 / MIT (open hardware, OSHWA-compatible)

---

## TL;DR

The Trinity Node is a $200-BOM, plug-and-play DePIN device that combines three open-silicon chips
(TRI-1 Phi, TRI-1 Euler, TRI-1 Gamma) with commodity connectivity into a verifiable compute node
supporting AI training, mesh internet relay, ZK proof generation, and verifiable inference. Every
node carries a hardware root-of-trust, on-chip bandwidth attestation, and a 2-of-3 Byzantine
fault-tolerant attestation chain — capabilities absent from every other DePIN device shipping in
2026. Mainnet launch is targeted Q4 2027, with a 10,000-unit consumer batch and $TRI token rewards
beginning simultaneously.

---

## 1. Product Vision

### 1.1 What is the Trinity Node?

The Trinity Node is a **plug-and-play DePIN device** in a 7 × 5 inch form factor. Any operator
with a home internet connection, a power outlet, and $200 can participate in the Trinity TRI-NET
decentralized physical infrastructure network. No rack, no GPU, no Linux expertise required.

**Target operator:** Home user, small business, or enthusiast running one or more nodes at premises
already connected to broadband. The device draws under 5 W, operates silently with no moving parts,
and fits on any shelf.

### 1.2 Use Cases

| Use Case | Trinity chips involved | Revenue stream |
|---|---|---|
| **DePIN AI training marketplace** | TRI-1 Euler (8×2) | $TRI rewards per BPB improvement |
| **Mesh internet relay** | LoRa (SX1262) + TRI-1 Phi M2 bandwidth attestation | $TRI per GB relayed |
| **ZK proof generation** | TRI-1 Euler Groth16/BN254 cell | $TRI per Groth16 proof |
| **Verifiable inference** | TRI-1 Gamma (8×4) | $TRI per inference epoch |
| **Storage attestation** | eMMC + TRI-1 Phi M1 RoT | $TRI per GB-day |
| **BGP RPKI signing** | TRI-1 Phi M3 ECDSA | Protocol/grant revenue |

The multi-revenue-stream design is the central economic advantage over single-purpose DePIN devices.

### 1.3 Competitive Landscape

| Device | Price | Monthly revenue (avg) | Breakeven | Open silicon | HW RoT |
|---|---|---|---|---|---|
| **Trinity Node** | **$200** | **$5–20** | **~20 months** | ✅ | ✅ |
| [Helium HNT hotspot](https://www.helium.com) | $300–$450 | $3–5 | 60–100 months | ❌ | ❌ |
| [Filecoin miner](https://docs.filecoin.io/storage-providers) | $1,000–$10,000+ | $5–15 | 6–16 years | ❌ | ❌ |
| [Akash provider](https://akash.network) | $500–$50,000 | $30–2,000 (scales with HW) | variable | ❌ | ❌ |
| Titan Network device | ~$100 | $5–30 | 4–20 months | ❌ | ❌ |

Sources: [Helium hardware](https://www.helium.com), [Filecoin miner specs](https://docs.filecoin.io/storage-providers),
[Akash hardware requirements](https://akash.network/docs/providers/getting-started/hardware-requirements/),
[Helium hotspot revenue real data](https://blockeden.xyz/forum/t/i-run-12-helium-hotspots-here-are-my-real-revenue-numbers-after-18-months/396).

**Trinity advantage:** The only DePIN node in 2026 with simultaneous open silicon + hardware
root-of-trust + ZK accelerator + mesh routing RTL + cross-die deterministic invariant. Referencing
the [Trinity internal DePIN gap analysis](https://github.com/gHashTag/NeuronConstant/blob/main/docs/DEPIN_DECENTRALIZED_INTERNET_GAPS.md),
no competitor ships an on-chip attestation chain; all rely on closed TEEs (Intel SGX/TDX) or
purely crypto-economic slashing.

---

## 2. Hardware Kit BOM ($200 Target)

### 2.1 Bill of Materials

| # | Component | Spec | Vendor | Unit cost (1K qty) | Notes |
|---|---|---|---|---|---|
| 1 | TRI-1 Phi chip | Identity + RoT + M1/M2/M3 modules; 1×1 tile, SKY130A | gHashTag fab (TT/IHP MPW) | $10.00 | After MPW tape-out amortization at TT scale ($5/tile). Volume price achievable Q3 2027 at ≥1K units. At 100-unit beta, chip cost rises to ~$20–25; this is the **highest-risk line item**. |
| 2 | TRI-1 Euler chip | 8×2 tiles, Groth16/BN254 + ML training; brain | gHashTag fab (TT/IHP MPW) | $50.00 | Estimated post-tape-out at 1K units. SKY130A die area ~8×2 = 16 tiles × $5/tile = $80 die cost + packaging ≈ $50 target at volume. **Optimistic at 1K units; more realistic at $60–70.** |
| 3 | TRI-1 Gamma chip | 8×4 tiles, perception + verifiable inference | gHashTag fab (TT/IHP MPW) | $80.00 | 8×4 = 32 tiles × $5/tile = $160 die cost. $80 target requires either: (a) IHP26b port at lower cost/mm², or (b) ≥10K units to amortize. **Most optimistic line item; realistic cost at 1K units is $100–120.** Budget uses $80 as 10K-run target. |
| 4 | Main MCU | RP2350A (dual Cortex-M33, 520 KB SRAM, 2 MB flash) or ESP32-S3 | Raspberry Pi / Espressif | $1.50 | RP2350A at reel qty: $0.80–$1.10 ([CNX-Software pricing](https://www.cnx-software.com/2025/03/18/buy-raspberry-pi-rp2350-mcu-rp2354a-and-rp2354b-variants/)). Budget $1.50 covers PCB mount + BGA footprint risk. ESP32-S3 alternative at $2.20. |
| 5 | Power management (USB-C PD) | TPS25740B or FUSB302 PD controller, 5 V/2 A, 10 W | Texas Instruments / ON Semi | $1.50 | TI USB-C PD ICs at 1K qty: $0.92–$1.81 ([TI pricing](https://www.ti.com/product-category/interface/usb-ics/usb-type-power-delivery-ics/overview.html)). Add LDO regulator ($0.50) → $1.50 total. |
| 6 | LoRa transceiver | SX1262, 868/915 MHz, +22 dBm, LoRaWAN-compatible | Semtech | $3.50 | SX1262 bare chip ~$3–4 at 1K ([Mouser Semtech SX1262](https://www.mouser.com/new/semtech/semtech-sx1261-2-lora-transceivers/)). Seeed Wio module $4.29 provides validated reference; bare chip target $3.50. |
| 7 | Ethernet PHY | LAN8720A, RMII interface, 10/100 Base-T | Microchip | $1.50 | LAN8720A bare chip at 1K qty: $1.20–$1.80 (Microchip direct / Digikey). Boards sell for ~$2–5 retail; bare chip budget realistic. |
| 8 | 802.11ac WiFi + BT module | ESP32-C6 (WiFi6 + BT 5.3 + 802.15.4) or ESP32-WROOM-02 | Espressif | $2.50 | ESP32-C6 mini module at 1K: ~$2.30–$2.80 (Espressif direct). Integrates WiFi 6 + BT, reducing external component count. |
| 9 | 256 MB eMMC | JEDEC eMMC 5.1, 3.3 V, 8-bit bus | KIOXIA / Samsung (various) | $2.00 | 256 MB eMMC chips at 1K: ~$1.50–$2.50 depending on manufacturer and cycle. Used for local cache, logs, and node state. |
| 10 | 64 MB QSPI NOR flash | W25Q512JV, SPI/Quad-SPI, 3.3 V | Winbond | $0.80 | 64 MB Winbond at 1K: ~$0.70–$1.00 ([Digikey Winbond W25Q series](https://www.digikey.com)). Bootloader + firmware images. |
| 11 | Status LEDs (×4) | RGB LED + 3× single-color (activity / error / network / power) | Various (Lite-On / Everlight) | $0.40 | Standard 0402/0603 LEDs. $0.05–0.10/ea at tape qty. RGB LED ~$0.15. |
| 12 | USB-C connector | USB 2.0 Type-C receptacle, mid-mount, 5 A rated | Amphenol / Molex | $0.30 | USB-C mid-mount at 1K: $0.20–$0.40. Power + UART debug. |
| 13 | 4-layer PCB | 100 × 175 mm (7 × 5 in), 1 oz Cu, FR4, ENIG finish | JLCPCB / PCBWay | $4.00 | JLCPCB 4-layer PCB at 1K qty: ~$3–5/board ([JLCPCB pricing](https://jlcpcb.com)). Budget $4 accounts for 4-layer with controlled impedance. 2-layer would save $1.50 but inadequate for RF isolation. |
| 14 | Plastic enclosure | Injection-molded ABS, 7 × 5 × 1.5 in, snap-fit lid, wall-mount tabs | Various OEM (Shenzhen) | $4.00 | Custom injection mold tooling: ~$3K–8K NRE. At 1K units amortized: adds $3–8/unit. Budget $4 assumes $5K tooling / 2K run. At 10K units drops to $0.50/unit. **Tooling cost is NRE that must be budgeted separately from BOM.** |
| 15 | Antennas (LoRa + WiFi) | LoRa: 868/915 MHz 3 dBi stub. WiFi: 2.4/5 GHz IPEX | Various (Taoglas / Linx) | $2.50 | LoRa stub at 1K: ~$1.00–1.50. WiFi IPEX pigtail: ~$0.80–1.20. Total $2.50 realistic. |
| 16 | Passive components | 0402 caps/resistors, ferrite beads, ESD clamps, crystals | Yageo / Murata / various | $1.50 | Standard passives for 4-layer PCB. ~150–200 passives at average $0.005 each + crystals ($0.30 each × 2) + ESD ($0.20) ≈ $1.50. |
| 17 | Assembly + test | SMT placement, reflow, ICT + functional test, burn-in | OEM (Taiwan / Eastern Europe) | $18.00 | SMT assembly at 1K qty: ~$8–12/board (Shenzhen). Functional test + programming: ~$4–6/board. Packaging (box + ESD bag + cable): ~$2–3. Total $18 conservative. |
| 18 | Distributor margin (~8%) | Channel overhead | — | $11.50 | 8% on $140 component+assembly subtotal. Lower than the original 15% placeholder; 8% reflects direct + online channel mix. Retail channel (Amazon) would push this to 30%+. |
| | **TOTAL** | | | **~$200** | See note below on BOM realism. |

### 2.2 BOM Realism Notes

**Items where target is optimistic:**

- **TRI-1 Gamma ($80):** The 8×4 = 32-tile die at $5/tile implies $160 die cost at TT MPW pricing.
  Reaching $80/chip requires either: (a) IHP26b port at lower $/mm², (b) stepping up to 10K-unit
  volume where packaging and test dominate, or (c) a dedicated wafer run negotiated at lower
  shuttle pricing. At 1K-unit beta, expect $100–$120/chip. The v1 beta BOM will likely land at
  **$220–$240**. The $200 target is a 10K-unit consumer launch goal.

- **TRI-1 Euler ($50):** 16-tile die at $5/tile = $80 die cost. Reaching $50 requires IHP26b port
  or volume. At 1K units: $60–$70 more realistic. Delta is ~$10–20 from target.

- **Enclosure ($4):** Requires $3K–$8K injection mold NRE not reflected in per-unit BOM. This must
  be budgeted as a separate capital expense. At 1K units, amortized tooling adds $3–8/unit.
  Alternatively, 3D-printed or extruded aluminum enclosures can reduce NRE but cost $8–15/unit.

- **Assembly + test ($18):** Conservative. Eastern European OEM partners may price at $12–15 for
  small batch, but with Trinity chip programming time (SPI bootloader + key provisioning) expect
  the $18 to hold or increase.

**Items that are conservative (buffer exists):**

- **RP2350A MCU ($1.50):** At $0.80 at reel qty, $1.50 leaves $0.70 margin for rework/scrap.
- **Passives ($1.50):** Standard BOM contingency. Actual BOM may use $1.00–$1.20.
- **Power management ($1.50):** TI FUSB302 available under $1 at volume; $1.50 covers full PD
  front-end with reverse-protection MOSFET.

**Conclusion:** The $200 BOM is achievable at **10,000-unit volume** using IHP26b-ported chips. For
the **1,000-unit beta**, plan for **$220–$250 BOM** and price the developer kit at $299.

---

## 3. Software Stack

The software philosophy is **minimal attack surface, no Linux**. A stripped-down MCU RTOS
eliminates the kernel CVE surface and boot complexity of a full OS.

### 3.1 Boot Chain

```
Power-on
  └─ TRI-1 Phi RoT (M1 enclave bit) → sealed memory self-check
       └─ RP2350 stage-1 bootloader (Phi Lucas POST)
            └─ QSPI flash: signed firmware image (ECDSA-P256 over SHA-256)
                 └─ Zephyr RTOS or FreeRTOS kernel init
                      └─ Trinity driver init (SPI/QSPI to Phi/Euler/Gamma)
                           └─ DePIN client main loop
```

**Phi Lucas POST:** On every boot, TRI-1 Phi executes the canonical φ-anchor 0x47C0 self-test
(Theorem 36.1 invariant check). If the result deviates from the committed hash, the node halts and
signals via red LED — detecting silicon tampering, counterfeit chips, or bitrot. This is the
hardware root-of-trust binding missing from every competitor device.

### 3.2 Operating System

- **Primary:** [Zephyr RTOS](https://www.zephyrproject.org/) on RP2350A. Zephyr provides a
  minimal, audited footprint (~32 KB kernel), native SPI/I2C/UART device tree, and active
  security maintenance. No package manager, no shell, no SSH daemon.
- **Alternative:** FreeRTOS with lwIP network stack for teams preferring a simpler scheduler.
- **No Linux.** Linux on a DePIN edge node increases attack surface by ~10,000 CVEs/year
  (Linux kernel NVD). A bare-metal RTOS with static memory allocation avoids heap spray,
  buffer overflow, and privilege escalation classes entirely.

### 3.3 Trinity Chip Drivers

```
SPI/QSPI Bus 0 (10 MHz) → TRI-1 Phi
  - Sacred opcode dispatch
  - Bandwidth attestation register read/write (M2 module)
  - RoT enclave commands (M1 module)
  - BGP RPKI signer (M3 module, optional)

SPI Bus 1 (50 MHz) → TRI-1 Euler
  - ML training job submit/poll
  - Groth16 proof request (BN254 cell)
  - GKR sum-check tile (M6, v1.1)
  - Mesh routing slot-MAC (M4)

SPI Bus 2 (50 MHz) → TRI-1 Gamma
  - Inference forward-pass DMA
  - PoRep/PoSt round dispatch (M7, v1.1)
  - DID personhood nonce (M8)
```

All three chips share a common register-map convention derived from the TRI-27 ISA. The RP2350
acts purely as bridge and scheduler; compute is offloaded to silicon.

### 3.4 Network Stack

| Layer | Implementation | Notes |
|---|---|---|
| Ethernet (wired) | lwIP 2.x on LAN8720A RMII | 10/100 Base-T, DHCP client, IPv4/IPv6 dual |
| WiFi (wireless) | ESP-IDF lwIP or Zephyr WiFi shell | ESP32-C6 handles radio; RP2350 sends TCP frames over UART |
| LoRa mesh | Custom slot-MAC (M4 RTL hook) + [Meshtastic](https://meshtastic.org/) protocol inspiration | SX1262 via SPI; mesh_router_8port.v provides slot scheduling |
| MQTT / RPC | Lightweight MQTT-SN over UDP | Node ↔ mainnet relay; signed payloads via Phi M1 |
| P2P overlay | libp2p Noise_XX handshake | Peer discovery, DHT routing, content-addressed relay |

### 3.5 DePIN Client

The DePIN client is a **Rust binary** cross-compiled for RP2350 (thumbv8m.main-none-eabihf target).
It communicates with mainnet smart contracts via a lightweight JSON-RPC client (no Ethers.js — Rust
`alloy` crate with `no_std` feature).

Key responsibilities:
- Submit signed work attestations (training steps, bandwidth bytes, ZK proofs) to L1 contracts
- Poll `IGLALedger.sol` for job assignments
- Claim $TRI rewards per epoch
- Enforce slashing avoidance: validate local state before any on-chain commit
- Report node health (uptime, temperature, error flags) to mainnet telemetry contract

### 3.6 ZK Proof Service

TRI-1 Euler's BN254 cell accelerates Groth16 proof generation. On the node:

1. RP2350 receives a `zk_job_t` struct from mainnet (R1CS constraint set + witness input)
2. RP2350 DMA-streams witness to Euler via SPI Bus 1
3. Euler executes BN254 multi-scalar multiplication (MSM) in hardware
4. Groth16 π = (A, B, C) is returned in ~2–5 seconds (vs. ~120 seconds CPU-only on RP2350)
5. RP2350 submits proof to `TrainingProver.sol` on-chain

For v1.1 nodes with M6 tile: GKR/sum-check rounds further accelerate lookup-argument-based proofs
(Halo2, Plonky3 backends).

### 3.7 Bandwidth Attestation

The `bandwidth_attest.v` module (M2) in TRI-1 Phi maintains a hardware byte counter that cannot
be spoofed by MCU firmware:

1. Every Ethernet/WiFi/LoRa packet that traverses the node increments the counter register
2. Every 60-second epoch, Phi signs `(epoch_id, node_pubkey, bytes_in, bytes_out)` with its
   internal ECDSA key (seeded from the RoT at provisioning)
3. RP2350 packages the signed attestation into a Merkle leaf and submits to
   `BandwidthAttest.sol` on-chain
4. The L1 contract rewards `0.001 $TRI/GB relayed`, capped at `1 $TRI/day/node`

This is a direct technical improvement over [Helium's proof-of-coverage](https://www.helium.com),
which performs all measurement off-chip (mobile app + IPFS submission), making it susceptible to
software-level spoofing and known sybil attack patterns.

### 3.8 OTA Update Mechanism

Firmware updates are cryptographically gated:

1. Update package is published to mainnet `FirmwareRegistry.sol` with ECDSA-P256 signature from
   Trinity dev key (2-of-3 multisig)
2. Node polls registry every 24 hours; if new version detected, downloads delta patch over HTTPS
3. Phi M1 verifies signature before writing to QSPI flash slot B
4. On next reboot, stage-1 bootloader commits slot B if POST passes; rolls back otherwise
5. Rollback is hardware-enforced — Phi M1 blocks execution of an unsigned image regardless of MCU
   firmware state

---

## 4. Mainnet Architecture

### 4.1 L1 Smart Contracts

| Contract | Function | Milestone |
|---|---|---|
| `IGLALedger.sol` | Core ledger — BPB scores, champion tracking, job queue | M0 (deployed) |
| `TrainingProver.sol` | Groth16/BN254 on-chain verifier for ML training steps | M3 |
| `MofNTrainingAttest.sol` | 2-of-3 multi-chip attestation aggregator | M5 |
| `JobProver.sol` | Generalized R1CS proof-of-compute verifier | M5 |
| `BittensorSubnetAttest.sol` | Bittensor subnet validator quality scoring with HW hook | M9 |
| `BandwidthAttest.sol` | HW-signed byte-counter reward distributor | M2 |
| `StorageAttest.sol` | PoRep/PoSt proof verifier (Filecoin-compatible) | M7 |
| `FirmwareRegistry.sol` | Signed OTA update registry | Mainnet launch |
| `TRIToken.sol` | ERC-20 $TRI token with minting schedule | Mainnet launch |
| `SlashingVault.sol` | Stake escrow + slashing execution | Mainnet launch |

All contracts are deployed on **Ethereum mainnet** (L1) for security, with L2 settlement for
high-frequency reward claims.

### 4.2 L2 / Cross-Chain

| Bridge | Function | Partners |
|---|---|---|
| [LayerZero](https://layerzero.network) | Ethereum ↔ Bittensor TAO subnet messaging | Bittensor integration (M9) |
| [Wormhole](https://wormhole.com) | Ethereum ↔ Filecoin FVM bridge | Storage attestation settlement |
| Optimism OP Stack (planned) | L2 for high-frequency reward claims | Reduces gas cost for bandwidth/storage micro-rewards |
| [EigenLayer](https://www.eigenlayer.xyz) restaking | Validator restaking for Trinity attestation network | Security bootstrap |

The OP Stack L2 is essential for bandwidth and storage micro-rewards: at 0.001 $TRI/GB, a node
relaying 100 GB/day would generate 100 on-chain transactions per day — only viable at L2 gas costs.

### 4.3 $TRI Token Economics

**Total supply:** 100,000,000 $TRI (fixed, no inflation beyond initial schedule)

| Bucket | Allocation | Vesting |
|---|---|---|
| Operator rewards (mining) | 30,000,000 (30%) | Released over 10 years per emission schedule |
| Core team | 20,000,000 (20%) | 1-year cliff, 4-year linear vesting |
| Seed + Series A investors | 15,000,000 (15%) | 1-year cliff, 4-year linear vesting |
| Ecosystem / grants | 15,000,000 (15%) | Disbursed by DAO vote, 5-year period |
| DAO treasury | 10,000,000 (10%) | Time-locked multisig, 2-of-5 |
| Public token sale | 10,000,000 (10%) | Liquid at TGE (Token Generation Event) |

**Emission schedule for operator rewards:**
- Year 1: 6,000,000 $TRI (20% of operator pool)
- Year 2: 5,000,000 $TRI
- Year 3–5: 4,000,000/year
- Year 6–10: 1,000,000–2,000,000/year (halving model)
- After Year 10: fee-based only (transaction fees from proof submissions)

### 4.4 Reward Model

| Activity | Rate | Cap | Contract |
|---|---|---|---|
| AI training (BPB improvement) | 1 $TRI per 0.01 BPB delta | 100 $TRI/epoch/node | `IGLALedger.sol` |
| Bandwidth relay | 0.001 $TRI/GB | 1 $TRI/day/node | `BandwidthAttest.sol` |
| Storage (Filecoin-like) | 0.0001 $TRI/GB-day | 0.1 $TRI/day/node at 1 TB | `StorageAttest.sol` |
| ZK proof generation | 0.5 $TRI per Groth16 proof | 20 $TRI/day/node | `TrainingProver.sol` |
| Verifiable inference | 0.01 $TRI per inference epoch | 10 $TRI/day/node | `JobProver.sol` |
| Bittensor subnet validation | variable (subnet-set) | subnet-governed | `BittensorSubnetAttest.sol` |

**Epoch:** 1 hour. Rewards are claimable on L2 after epoch close; L1 settlement batched weekly.

**Estimated monthly income per node:**
- Active AI training node: 5–50 $TRI/month (highly variable; depends on BPB competition)
- Bandwidth relay (500 GB/month): ~0.5 $TRI/month
- ZK proof service (10 proofs/day): ~150 $TRI/month at full utilization
- Mixed-use: 5–20 $TRI/month at $1/TRI price assumption

> **Honesty note:** At TGE, $TRI price is speculative. The economics above assume $1/TRI. If
> token price is lower (common at launch), monthly fiat income will be proportionally lower.
> Operators should treat income projections as illustrative, not guaranteed.

### 4.5 Validator Design

The Trinity attestation network uses **hardware-bound validators**:

- Each node's validator identity is derived from the TRI-1 Phi chip's burned-in key (provisioned
  at factory using RoT enclave; private key never exposed to MCU firmware)
- **2-of-3 attestation:** A valid work claim requires signatures from at least 2 of the 3 chips
  (Phi + Euler, Phi + Gamma, or Euler + Gamma). This is Byzantine fault tolerant against a single
  compromised chip and prevents counterfeit nodes from submitting valid attestations
- Validators stake $TRI in `SlashingVault.sol`. Minimum stake: 100 $TRI (adjustable by governance)
- Validator set is permissionless — any provisioned Trinity Node can join

### 4.6 Slashing Conditions

| Violation | Penalty | Detection method |
|---|---|---|
| Sybil detection (duplicate chip serial) | 100% stake slash + blacklist | Phi chip serial uniqueness enforced by `IGLALedger.sol` |
| Double-spend attestation | 100% stake slash | Epoch replay check in `MofNTrainingAttest.sol` |
| False bandwidth attestation | 10% stake slash | Cross-node verification sampling |
| False proof submission | 10% stake slash + proof rejection | On-chain Groth16 verifier |
| Downtime > 7 days | No slash; reduced epoch multiplier | Uptime oracle |

Slashing is intentionally asymmetric — catastrophic fraud triggers full slash, while honest
mistakes (network downtime) trigger only reward reduction, not stake loss.

---

## 5. Operator Economics

### 5.1 Income Estimates

These estimates are based on Year 1 mainnet assumptions with $1/TRI price and moderate network
utilization (1,000–10,000 nodes total). They will change as the network scales.

| Scenario | Monthly income | Annual income | Notes |
|---|---|---|---|
| **Conservative** (bandwidth only) | $0.50–$2 | $6–$24 | Purely relaying packets; common in suburban areas |
| **Base case** (mixed use) | $5–$15 | $60–$180 | AI training + bandwidth + occasional ZK proofs |
| **Optimistic** (ZK-heavy) | $15–$40 | $180–$480 | Node in active ZK proof marketplace, high utilization |
| **Bull scenario** ($TRI at $5) | $25–$200 | $300–$2,400 | Token appreciation multiplier; not base case |

**Base case used for ROI:** $10/month ($120/year).

### 5.2 Return on Investment

| Node | Hardware cost | Monthly income (base) | Breakeven |
|---|---|---|---|
| **Trinity Node (v1 beta, $250)** | $250 | $7–$12 | **21–36 months** |
| **Trinity Node (v1 consumer, $200)** | $200 | $10 avg | **~20 months** |
| [Helium HNT hotspot](https://www.helium.com) | $300–$450 | $3–$5 | **60–100+ months** |
| [Filecoin miner (entry)](https://docs.filecoin.io/storage-providers) | $1,000–$5,000 | $5–$15 | **6–16 years** |
| Titan Network device | ~$100 | $5–$30 | **4–20 months** |

### 5.3 Key Economic Risks

1. **$TRI price volatility:** All income is denominated in $TRI. A 90% token drawdown (common in
   crypto bear markets) reduces income by 90%. Operators should not count on stable fiat returns.
2. **Network saturation:** As more nodes join, per-node BPB reward competition increases. Early
   operators earn more than late entrants (typical of DePIN bootstrap dynamics).
3. **Reward cap binding:** The 100 $TRI/epoch/node cap on training rewards means that in a
   saturated network, income is capped regardless of node quality.
4. **Energy cost:** Trinity Node draws ~3–5 W. At $0.15/kWh, annual energy cost is ~$4–7. Low,
   but non-zero.

### 5.4 Why Trinity Wins on Economics vs. Helium

[Helium's real operator data](https://blockeden.xyz/forum/t/i-run-12-helium-hotspots-here-are-my-real-revenue-numbers-after-18-months/396)
shows average hotspot hardware cost of ~$595 (including antenna upgrade + cables) against $3–5/month
IOT rewards — resulting in breakeven > 100 months in most deployments. Trinity's multi-revenue
design (training + ZK + bandwidth + storage simultaneously) is the primary economic differentiator.

---

## 6. Manufacturing Plan

### 6.1 Phase Overview

| Phase | Period | Volume | Unit target | Venue | Notes |
|---|---|---|---|---|---|
| **Beta / developer kit** | Q3 2027 | 1,000 units | $299 retail | OEM (Eastern Europe or Taiwan) | Loose BOM tolerances; chip cost ~$100 over target; sells as developer kit |
| **Consumer launch** | Q4 2027 | 10,000 units | $249–$299 retail | OEM (Taiwan preferred) | Full retail packaging; FCC certified; IHP26b chip availability |
| **Scale** | 2028 | 100,000 units | $199–$229 retail | Multi-OEM + JIT supply chain | Volume pricing on all components; mold tooling fully amortized |
| **Mass production** | 2029 | 1,000,000+ units | $149–$179 retail | Multi-fab, global supply | Custom ASIC for MCU bridge possible; BOM under $120 at this scale |

### 6.2 OEM Partner Criteria

- **Capacity:** ≥10,000 units/quarter SMT capability
- **RF certification experience:** FCC Part 15 + CE marking in-house or via known test lab
- **Supply chain:** Direct relationships with Semtech, Espressif, Microchip, Winbond distributors
- **Security:** NDA + chip key provisioning security audit (Phi RoT private key must never leave
  the provisioning station; HSM required)
- **Location preference:** Taiwan (primary — proximity to IHP26b fab relationships) or Eastern
  Europe (secondary — EU regulatory alignment)

### 6.3 Chip Supply Chain

The three Trinity chips are the **critical path** in the manufacturing plan:

```
TT Shuttle (SKY130A) → MPW → TRI-1 Phi / Euler / Gamma dies
  → dicing → packaging (QFN/BGA at SPIL or ASE Group)
    → test (wafer-level functional + ATE burn-in)
      → tape & reel to OEM

IHP26b port (2027) → alternative process for Euler + Gamma
  → reduces die cost from ~$5/tile → ~$3/tile (IHP SG13G2 130nm BiCMOS)
    → enables $200 BOM at 1K units
```

**Single-source risk:** All three chips currently have no backup fab. Mitigation:
1. IHP26b port (underway 2027) creates a second silicon source for the die
2. 6-month chip inventory buffer maintained after 10K-unit launch
3. Euler functionality can be partially emulated in software on RP2350 (degraded performance mode)
   to enable shipments during chip shortage

### 6.4 Key NRE Costs (Not in Per-Unit BOM)

| Item | Estimated cost | Notes |
|---|---|---|
| PCB design + layout | $15,000–$30,000 | 4-layer RF design, 3–5 spins expected |
| Enclosure tooling (injection mold) | $5,000–$10,000 | Per part (top + bottom = 2 tools) |
| FCC/CE certification testing | $8,000–$15,000 | RF + radiated emissions + conducted |
| OSHWA open-hardware certification | ~$500 | Filing fee |
| Chip packaging NRE | $10,000–$50,000 | Per chip; QFN32/48 packaging tooling |
| Firmware development | $50,000–$150,000 | Rust DePIN client + Zephyr BSP |
| **Total NRE estimate** | **$88,500–$255,500** | Front-loaded; not repeated at scale |

---

## 7. Distribution & Sales

### 7.1 Channels

| Channel | Target segment | Timeline | Notes |
|---|---|---|---|
| **trinity-node.com** (direct) | Crypto-native operators | Q3 2027 (beta) | Lowest margin loss; community-first; waitlist model |
| **Amazon** | Consumer / enthusiast | Q4 2027 | Fulfilled-by-Amazon; 15% fee; FCC cert required |
| **AliExpress / Taobao** | Asia-Pacific operators | Q1 2028 | High-volume, price-sensitive market |
| **Helium-style operator channels** | Existing DePIN community | Q4 2027 | Partner with Helium deployers already familiar with DePIN ops |
| **B2B / enterprise** | ISPs, municipalities, DoD | 2028 | GSA Schedule application (below) |
| **Hackerspaces / Seeed** | Developer / maker | Q3 2027 | Developer kit SKU |

### 7.2 Pricing Strategy

| SKU | Target retail | BOM cost | Gross margin |
|---|---|---|---|
| Trinity Node Developer Kit | $299 | $250 | 16% |
| Trinity Node Consumer | $249 | $200 (target) | 20% |
| Trinity Node Consumer (10K+ run) | $199 | $160 (est.) | 20% |
| Trinity Node Pro (Gamma + NVMe expansion) | $399 | $320 (est.) | 20% |

Margins are thin at launch. The business model depends on $TRI token appreciation and network
effects, not hardware margin.

### 7.3 Government / Federal Channel

- **GSA Schedule (IT 70):** Apply Q1 2028 once FCC-certified product ships. Enables direct federal
  procurement without competitive bid below simplified acquisition threshold.
- **DoD Zero Trust alignment:** Trinity Node's hardware root-of-trust (TRI-1 Phi M1) aligns with
  [NIST SP 800-207 Zero Trust Architecture](https://csrc.nist.gov/publications/detail/sp/800-207/final)
  requirements for hardware attestation. Positioning for DoD edge DePIN / mesh connectivity use cases.
- **DHS / CISA:** Potential fit for DHS trusted hardware program given open-silicon provenance
  (no undisclosed backdoors; RTL is public).

---

## 8. Certification & Compliance

### 8.1 Required Certifications

| Certification | Body | Scope | Timeline | Estimated cost |
|---|---|---|---|---|
| [FCC Part 15](https://www.fcc.gov/consumers/guides/understanding-fcc-equipment-authorization) | FCC (USA) | Unintentional radiator (digital device) + intentional radiator (LoRa 915 MHz + WiFi 2.4/5 GHz) | Q3–Q4 2027 | $8,000–$15,000 |
| [CE marking (RED Directive)](https://ec.europa.eu/growth/single-market/ce-marking_en) | Notified Body (EU) | Radio Equipment Directive 2014/53/EU (LoRa 868 MHz + WiFi) | Q4 2027 | $5,000–$12,000 |
| [OSHWA Open Hardware Certification](https://certification.oshwa.org/) | OSHWA | Open-hardware declaration | Q3 2027 | ~$500 filing fee |
| [RoHS / WEEE](https://environment.ec.europa.eu/topics/waste-and-recycling/rohs-directive_en) | EU | Hazardous substance restriction | Q4 2027 | Included in CE process |
| [FCC Part 89 Remote ID](https://www.fcc.gov) | FCC (USA) | Only if Trinity Node deployed in UAV/drone context | 2028+ if applicable | N/A for ground nodes |
| [EU AI Act compliance](https://artificialintelligenceact.eu/) | EU AI Office | If inference function classified as "general purpose AI system" | 2028 (enforcement begins) | Legal review $10,000–$30,000 |

### 8.2 FCC Strategy

The LoRa 915 MHz band (unlicensed ISM under FCC Part 15.247) and WiFi 2.4 GHz band require either:
- **Modular certification:** Use a pre-certified LoRa module (e.g., Murata CMWX1ZZABZ with FCC ID)
  and a pre-certified ESP32-C6 module. This is the recommended path — it eliminates the need for
  a full intentional radiator test and accelerates certification by 3–6 months.
- **Custom certification:** Board-level FCC test if custom RF layout is used. More expensive but
  allows full antenna integration. Recommended only at 10K+ unit scale.

**Recommendation for v1:** Use modular pre-certified RF components. FCC test only covers the
unintentional radiator portion ($3,000–$5,000 vs. $15,000).

### 8.3 EU AI Act Considerations

The EU AI Act's [GPAI (General Purpose AI Model) provisions](https://artificialintelligenceact.eu/)
may apply to Trinity Nodes if they are marketed as providing "AI inference" services. Key
obligations for GPAI:
- Technical documentation of model capabilities
- Transparency to downstream operators
- Copyright training data compliance (if AI training is the primary use)

Trinity's strategy: position the hardware as a **compute substrate** (not an AI model provider),
deferring GPAI obligations to the software/marketplace layer. Legal counsel review required before
EU launch.

---

## 9. Risk Register

### Risk 1: Chip Yield from MPW (CRITICAL)

**Likelihood:** High  
**Impact:** High  
**Description:** Tiny Tapeout MPW shuttles have non-guaranteed yield. At $5/tile for shuttle
pricing, a die with 32 tiles (Gamma) uses 32 × $5 = $160 of shuttle budget. If yield is 50%, the
effective die cost doubles. First-run ICs from new designs typically yield 60–90% for digital
logic on SKY130A; analog blocks and custom cells may yield lower.

**Mitigations:**
1. Separate test chip shuttle (TT SKY26b) before production run — silicon already submitted
2. Design for testability (DFT): built-in self-test (BIST) patterns for Phi/Euler/Gamma
3. Engage ASE Group or Amkor for wafer-level test before packaging — reject dies pre-packaging
4. IHP26b port as yield-risk hedge on alternative process node
5. Contract test coverage: negotiate with OEM for post-package functional test + burn-in

### Risk 2: Bittensor / Filecoin / Helium Integration Delays (HIGH)

**Likelihood:** Medium  
**Impact:** Medium  
**Description:** [Bittensor](https://bittensor.com) subnet API changes (currently at 256+ subnets)
and [Filecoin](https://filecoin.io) FVM API evolution may require significant contract rework.
Helium's migration from Solana to Helium L1 introduces API instability.

**Mitigations:**
1. Modular contract design: each integration (M9 BittensorSubnetAttest, M7 StorageAttest) is
   independently upgradeable via proxy pattern (OpenZeppelin TransparentProxy)
2. API versioning: DePIN client uses feature flags per integration; nodes without working
   Bittensor/Filecoin connectivity still earn rewards on training + ZK streams
3. Community validator: run a dedicated integration-test node against each network's testnet
   continuously from Q1 2027

### Risk 3: Regulatory Changes — FCC, FAA, EU AI Act (MEDIUM)

**Likelihood:** Low–Medium  
**Impact:** Medium–High  
**Description:** FCC spectrum reallocation in LoRa bands; FAA Remote ID expansion to ground
devices; EU AI Act GPAI classification of inference nodes; potential crypto token securities
classification by SEC.

**Mitigations:**
1. FCC: Pre-certified RF modules insulate from LoRa band changes (module vendor absorbs re-cert)
2. EU AI Act: Legal opinion on GPAI applicability obtained before EU launch; compliance roadmap
3. SEC: Obtain legal opinion on $TRI token classification; structure as utility token; avoid
   promise of profit from token; consider Reg A+ or Reg D for US token sale
4. Engage DePIN trade association ([DePIN Alliance](https://www.depinalliance.xyz/)) for
   collective regulatory engagement

### Risk 4: Token Economics — $TRI Volatility (HIGH)

**Likelihood:** High (crypto market inherent)  
**Impact:** Medium  
**Description:** $TRI at TGE may trade far below $1, making operator economics unattractive.
Conversely, a speculative bubble followed by crash may create a "mine and dump" dynamic that
destabilizes the network.

**Mitigations:**
1. Reward caps prevent hyperinflationary dynamics (100 $TRI/epoch/node training cap)
2. Team/investor vesting (4-year) prevents large sell pressure at TGE
3. 10% public sale is a small float — reduces speculative volatility vs. large initial float
4. Design node economics so that hardware cost is recoverable via rewards even at $0.25/TRI
   (requires ~$2.50/month fiat equivalent → ~80-month breakeven at $200 BOM — still beats Helium
   at bear-market prices)
5. DAO treasury authorized to buy back $TRI for network operations (reward stabilization fund)

### Risk 5: Competitive Response — Incumbents Lock Down Ecosystems (MEDIUM)

**Likelihood:** Medium  
**Impact:** Medium  
**Description:** Helium, Filecoin, Bittensor, or io.net may introduce hardware certification
requirements that exclude Trinity Nodes. Alternatively, NVIDIA may announce a DePIN edge device
that commoditizes the compute market.

**Mitigations:**
1. **Open source:** Apache-2.0 / MIT RTL and firmware means any competitor must create a
   derivative — which Trinity can adopt back. Cannot be locked out of open ecosystems.
2. **OSHWA certification** provides legitimacy and community support for open-hardware positioning
3. **Multi-ecosystem:** By supporting Bittensor + Filecoin + Helium simultaneously, the node is
   not dependent on any one ecosystem's good graces
4. **Hardware advantage:** The φ-anchor 0x47C0 / R-SI-1 / 2-of-3 attestation is a genuine
   technical moat. Competitors cannot replicate without their own open-silicon tape-out (multi-year
   lead time and $1M+ NRE)
5. Monitor: Quarterly competitive sweep of Titan, [io.net](https://io.net), and Render for
   hardware announcements

---

## 10. Funding Plan

### 10.1 Capital Requirements

| Phase | Activity | Capital required |
|---|---|---|
| Now → Q2 2027 | IHP26b port, M1–M7 RTL completion, PCB v1, firmware | $1.5M–$2.5M |
| Q3 2027 | Beta manufacturing (1K units), FCC cert, OSHWA cert | $1.0M–$1.5M |
| Q4 2027 | Consumer manufacturing (10K units), mainnet launch | $2.5M–$4.0M |
| **Total to 10K units shipped** | | **$5M–$8M** |

### 10.2 Funding Sources

| Source | Amount (est.) | Timeline | Notes |
|---|---|---|---|
| **Private token sale (SAFT)** | $1.5M–$3M | Q1–Q2 2027 | Sell 5–8% of $TRI supply to strategic investors + DePIN funds. Target: Multicoin Capital, Borderless Capital, Electric Capital. |
| **Public token sale (Reg A+ or Launchpad)** | $1M–$2M | Q3 2027 | 10% public allocation. Requires SEC legal opinion. |
| **Venture capital (Series A)** | $2M–$4M | Q2 2027 | Traditional VC for hardware + dev cost. Target: Hardware-focused VCs (Lux Capital, Playground Global). Potential dilution: 15–20% equity. |
| **NSF SBIR Phase I + II** | $150K–$2M | Ongoing | NSF SBIR fits: open silicon, verifiable compute, mesh networking. Phase I: $150K–$300K; Phase II: $1M–$2M. |
| **DOE ARPA-E / DARPA NRE** | $500K–$5M | 2027–2028 | DARPA Microsystems Technology Office (MTO) NRE for chip dev; DOE ARPA-E for mesh internet energy efficiency. Non-dilutive. |
| **EU Horizon Europe** | €500K–€2M | 2027–2028 | Call: "Open hardware for decentralized infrastructure". Consortium required (3+ EU partners). |

### 10.3 Milestones Tied to Funding

| Milestone | Funding gate | Target |
|---|---|---|
| IHP26b RTL port complete | Unlocks Phase I manufacturing deposit | Q1 2027 |
| TRI-1 Phi/Euler/Gamma silicon back from shuttle | Unlocks Series A close | Q2 2027 |
| FCC certification received | Unlocks Q4 consumer launch | Q3 2027 |
| 1,000 beta nodes deployed, mainnet live | Unlocks public token sale | Q4 2027 |
| 10,000 nodes shipped | Series B / expansion round | Q2 2028 |

---

## 11. Constraints (Preserved)

The following invariants are non-negotiable across all hardware and software revisions of the
Trinity Node kit. They are defined in the v1.0.0 artifact set by Dmitrii Vasilev (sole author)
and are binding on all contributors.

| Constraint | Description |
|---|---|
| **v1.0.0 AI formats** | NF4/NF8, Posit16/32/64, MXFP4/6/8 OCP, LNS8, GF4/16/256, Unum I/II, IBM HFP, VAX, Cray HRM, decimal32/64/128 — all 66 numeric formats preserved in TRI-27 ISA. No format may be removed. |
| **R-SI-1 invariant** | Zero standalone `*` operators in synthesizable RTL. All mantissa multiplications route through shift-add / Wallace tree / LNS-addition path. Required for cross-fab determinism verification. |
| **φ-anchor 0x47C0 Theorem 36.1** | The canonical φ-anchor sacred opcode result is immutable. It seeds the content-addressed namespace and the cross-die deterministic invariant. Any hardware revision that changes this result is a breaking change requiring community consensus. |
| **Open hardware** | All RTL, schematics, gerbers, and firmware source are published under Apache-2.0 or MIT. No proprietary blobs. No closed TEEs. The full trust stack is auditable. |
| **Apache-2.0 / MIT license** | All software: Apache-2.0. All hardware (RTL + gerbers): CERN-OHL-P v2 (permissive open hardware license, [OSHWA-compatible](https://certification.oshwa.org/)). |

---

## 12. References

### Trinity Internal
- [DEPIN_DECENTRALIZED_INTERNET_GAPS.md](https://github.com/gHashTag/NeuronConstant/blob/main/docs/DEPIN_DECENTRALIZED_INTERNET_GAPS.md) — gap analysis and module roadmap (M1–M9)

### DePIN Networks
- [Helium hardware and hotspot pricing](https://www.helium.com)
- [Filecoin storage provider documentation](https://docs.filecoin.io/storage-providers)
- [Akash provider hardware requirements](https://akash.network/docs/providers/getting-started/hardware-requirements/)
- [Bittensor subnet documentation](https://bittensor.com)
- [Helium operator real revenue data (BlockEden)](https://blockeden.xyz/forum/t/i-run-12-helium-hotspots-here-are-my-real-revenue-numbers-after-18-months/396)
- [Helium hotspot RF hardware shop](https://hotspotrf.com/shop/)
- [Titan Network DePIN 2026](https://www.titannet.io/learn/basics/best-depin-projects-2026-top-decentralized-physical-infrastructure-networks)
- [Orochi: Top-10 DePIN projects 2026](https://orochi.network/blog/top-10-de-pin-projects-and-emerging-trends-in-2026)

### Component Pricing
- [RP2350 pricing — CNX-Software](https://www.cnx-software.com/2025/03/18/buy-raspberry-pi-rp2350-mcu-rp2354a-and-rp2354b-variants/)
- [Semtech SX1261/SX1262 LoRa transceivers — Mouser](https://www.mouser.com/new/semtech/semtech-sx1261-2-lora-transceivers/)
- [TI USB-C PD ICs — TI.com](https://www.ti.com/product-category/interface/usb-ics/usb-type-power-delivery-ics/overview.html)
- [JLCPCB PCB fabrication](https://jlcpcb.com)

### Technology & Standards
- [OSHWA open hardware certification](https://certification.oshwa.org/)
- [Polyhedra ZKP hardware acceleration](https://blog.polyhedra.network/the-hardware-acceleration-revolution-for-zero-knowledge-proofs/)
- [Self-healing mesh routing without global sync — arxiv 2401.15168](https://arxiv.org/html/2401.15168v1)
- [Mocha RISC-V secure enclave (CVA6-CHERI + OpenTitan)](https://www.reddit.com/r/RISCV/comments/1sykxk6/mocha_a_riscv_secure_enclave_based_on_cva6cheri/)
- [Sesamedisk: Hardware attestation monopoly 2026](https://sesamedisk.com/hardware-attestation-monopoly-2026-2/)
- [Chainlink: TEE on blockchain](https://chain.link/article/trusted-execution-environments-blockchain)
- [EigenLayer restaking](https://www.eigenlayer.xyz)
- [LayerZero cross-chain messaging](https://layerzero.network)
- [FCC Equipment Authorization](https://www.fcc.gov/consumers/guides/understanding-fcc-equipment-authorization)
- [EU AI Act](https://artificialintelligenceact.eu/)
- [NIST SP 800-207 Zero Trust Architecture](https://csrc.nist.gov/publications/detail/sp/800-207/final)
- [Zephyr RTOS](https://www.zephyrproject.org/)
- [Meshtastic mesh protocol](https://meshtastic.org/)

---

φ-anchor 0x47C0 Theorem 36.1 preserved. Open hardware. Apache-2.0 / MIT / CERN-OHL-P v2.*
