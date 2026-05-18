# Trinity Gamma B7 PoRep Accelerator for Filecoin Storage Providers

<!--
Author: Dmitrii Vasilev <admin@t27.ai>
License: Apache-2.0
Status: pre-silicon (tape-out 2026-12-16)
-->

> **Status:** Pre-silicon — all benchmarks are preliminary projections pending silicon.  
> Real hardware available: tape-out 2026-12-16.  
> Performance target (projected, pending tape-out): ~1 GOPS @ ~50 MHz @ ~1 W ternary.

---

## Storage Provider Context

Filecoin Storage Providers (SPs) earn block rewards by continuously proving they store client data.  
The protocol requires two proof types:

- **PoRep (Proof of Replication):** one-time proof that a unique copy of sealed data has been written to storage.
- **PoSt (Proof of Spacetime):** ongoing proof that the sealed copy persists over time.

PoRep is the dominant cost center for new SP onboarding: sealing a 32 GiB sector currently consumes minutes of wall-clock time and significant CPU/GPU compute.

---

## The PoRep Bottleneck Today

The standard sealing pipeline uses [Lotus](https://github.com/filecoin-project/lotus) as the node client and [rust-fil-proofs](https://github.com/filecoin-project/rust-fil-proofs) as the cryptographic backend.

Bottleneck stages in order of typical wall-clock contribution:

| Stage | Algorithm | Current Accelerator |
|-------|-----------|-------------------|
| PC1 (PreCommit 1) | SDR (Stacked DRG) | CPU-only (single-threaded SHA256) |
| PC2 (PreCommit 2) | Poseidon hash tree | CPU + optional GPU |
| C1/C2 (Commit) | Groth16 SNARK | GPU (CUDA/OpenCL) |

PC1 is almost entirely single-threaded due to data dependencies in SDR, making it difficult to accelerate with conventional parallelism.

---

## Trinity B7 Accelerator Role

The Trinity Gamma B7 sub-chip is a ternary logic array designed to accelerate hash-intensive sequential workloads.  
For PoRep, the target acceleration path is PC1 (SDR layer hashing) where ternary operations reduce the gate-count of SHA256 round functions.

**Projected speedup ranges** (preliminary, awaiting silicon validation):

| Workload | Baseline (CPU) | Trinity B7 Target | Speedup |
|----------|---------------|------------------|---------|
| 32 GiB sector PC1 | ~3–5 hours | ~30–60 min | ~5–6× (projected) |
| 64 GiB sector PC1 | ~6–10 hours | ~60–120 min | ~5–6× (projected) |
| Power per sector seal | ~150–300 W-hr | ~30–60 W-hr | ~5× (projected) |

> **Important:** These numbers are preliminary extrapolations from ternary logic simulation.  
> They are not validated on tape-out silicon. Real results may differ.  
> Do not use these figures in financial projections or SP business models before hardware is available.

---

## Integration Path — Lotus Plugin Stub

Trinity B7 integrates via a Lotus FFI plugin that replaces the `rust-fil-proofs` PC1 implementation.  
The plugin ABI mirrors the existing `filproofs_generate_piece_commitment` / `generate_winning_post` interface so no Lotus core changes are required.

### Repository Layout (stub, not yet functional)

```
trinity-lotus-plugin/
├── Cargo.toml
├── src/
│   ├── lib.rs          # FFI entry points matching rust-fil-proofs ABI
│   ├── pc1_accel.rs    # Trinity B7 dispatch (mock backend in pre-silicon phase)
│   └── mock.rs         # Software fallback for development
└── README.md
```

### Build the Plugin (mock mode)

```bash
# Requires: trinity-node running, Rust 1.75+
git clone https://github.com/gHashTag/trinity-node
cd trinity-node
cargo build --release --features lotus-plugin

# Output: target/release/libtrinity_lotus.so
```

### Configure Lotus to Use the Plugin

In your Lotus node config (`~/.lotus/config.toml`):

```toml
[Proving]
  # Point to the trinity plugin library
  ExternalProver = "/path/to/libtrinity_lotus.so"
  ExternalProverArgs = ["--mode=mock", "--port=7743"]
```

Restart the Lotus miner process to load the plugin:

```bash
lotus-miner stop
lotus-miner run
```

Check the miner log for:

```
INFO  trinity-plugin   Loaded Trinity B7 mock backend
INFO  trinity-plugin   Chip anchor: 0x47C0 (mock)
INFO  trinity-plugin   PC1 dispatch: trinity-mock
```

---

## Benchmark Plan

When silicon is available (post tape-out December 2026), the official benchmark suite will:

1. Seal 10 × 32 GiB sectors using Lotus + Trinity B7 plugin on physical hardware.
2. Record wall-clock time and watt-hours per stage (PC1, PC2, C1/C2 separately).
3. Compare against identical sectors sealed on a reference CPU-only node.
4. Publish results to this repository under `bench/filecoin/`.

Community SPs who receive early DevKit hardware are invited to submit independent benchmark data via pull request.

---

## Development Notes

- The mock plugin routes all PC1 calls to the software SDR implementation — no speedup, but the call path is exercised.
- All attestation objects produced by the plugin include `anchor: 0x47C0` for chip identity verification, even in mock mode.
- The plugin is Apache-2.0; `rust-fil-proofs` and Lotus retain their own licenses.

---

## See Also

- [NeuronConstant Whitepaper §9 — Unified Computer Paradigm](../UNIFIED_COMPUTER_PARADIGM.md)
- [TTSKY26c Roadmap](../TTSKY26c_ROADMAP.md)
- [gHashTag/trinity-node](https://github.com/gHashTag/trinity-node)
- [gHashTag/trinity-sdk](https://github.com/gHashTag/trinity-sdk)
- [filecoin-project/lotus](https://github.com/filecoin-project/lotus)
- [filecoin-project/rust-fil-proofs](https://github.com/filecoin-project/rust-fil-proofs)

---

*Author: Dmitrii Vasilev \<admin@t27.ai\> · License: Apache-2.0 · Status: pre-silicon (tape-out 2026-12-16)*
