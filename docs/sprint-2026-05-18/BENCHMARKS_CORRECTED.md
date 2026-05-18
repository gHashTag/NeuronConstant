# Trinity TRI-NET — Honest Benchmarks (Corrected Edition)

**Status**: PROJECTED / PRE-SILICON. Real measurements available only after TT SKY26b tape-out delivery **2026-12-16**.

**Owner**: Dmitrii Vasilev <bayotkwolpep9c@hotmail.com>  
**Co-author of v1.0.0 modules**: Claude Opus 4.6 (Anthropic)  
**Zenodo DOI**: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

---

## TL;DR

Trinity is **NOT** competing on raw throughput. Trinity is a **research demonstrator on Tiny Tapeout's educational SKY26b shuttle**, not a production accelerator. Anyone comparing Trinity vs Hailo / Jetson / Coral on TOPS is asking the wrong question.

The correct axis of comparison is **verifiability** — silicon-anchored receipts, R-SI-1 audit, formal-verification theorems, open RTL. On that axis Trinity has no competitor in the SBC class today.

---

## Corrected benchmark numbers (PROJECTED, not measured)

| Die | Tile | Cells | Clock (target) | Workload | Throughput | Power | Source |
|---|---|---|---|---|---|---|---|
| **phi** (tt_um_trinity_nano) | 1×1 | ~6K | 50 MHz | identity / anchor verify | sub-GOPS | ~200 mW | post-synth STA |
| **euler** (tt_um_ghtag_trinity_gf16) | 8×2 | ~24K | 50 MHz | GF16 matrix multiply | ~0.5 GOPS | ~600 mW | post-synth STA |
| **gamma** (tt_um_trinity_max_true) | 8×4 | ~48K | 50 MHz | ternary BitNet 1.58 add/sub | **~1 GOPS** | **~1 W** | post-synth STA |
| **Triad** (D2D mesh phi+euler+gamma) | — | ~78K | 50 MHz | full attestation pipeline | ~1.5 GOPS aggregate | ~1.8 W | preliminary integration |

**All numbers above are PROJECTED from RTL synthesis. Real silicon measurements pending tape-out delivery 2026-12-16.**

---

## What "1 GOPS @ 1W" actually means

- **GOPS** = giga add/sub operations per second, in ternary {-1, 0, +1} mode
- **NOT** equivalent to TOPS (INT4/INT8 MAC) used by Hailo, Jetson, Coral
- A ternary add/sub is roughly 1/16 the silicon area of an INT8 MAC
- Trinity's value is not throughput, it is **verifiable per-op silicon-signed receipts**

## Why the old "63 tok/s/W" number was wrong

A previous draft (now corrected) cited "63 tok/s/W" sourced from an early HSLM BitNet inference projection. That number was:

1. **Inference-projection, not measurement** — extrapolated from RTL simulation
2. **Tokens/sec, not operations/sec** — different unit
3. **Per-watt assumption** — based on early power model, not post-synth STA
4. **Incomparable** with competitor TOPS numbers

The correct, honest, conservative number is **~1 GOPS @ ~1 W @ 50 MHz in ternary mode** for gamma 8×4, **PROJECTED**.

## Why TOPS comparison with Hailo/Jetson is invalid

| Vendor | Headline metric | Real meaning | Comparable to Trinity? |
|---|---|---|---|
| Hailo-10H | 40 TOPS INT4 MAC | int4 vector-MAC throughput | **No** — different op (MAC vs add/sub) and different precision |
| Jetson Orin Nano | 67 TOPS INT8 / 33 TFLOPS FP16 | int8 MAC + fp16 GEMM | **No** — different op and precision |
| Coral Edge TPU | 4 TOPS INT8 | int8 matmul on dedicated hardware | **No** — different op |
| Trinity gamma | ~1 GOPS ternary add/sub | ternary {-1,0,+1} add/sub | — |

**Honest framing**: Trinity throughput is ~5 orders of magnitude lower than mainstream SBCs. We do **not** compete on this axis.

## Where Trinity actually wins

| Axis | Trinity | Hailo | Jetson | Coral |
|---|---|---|---|---|
| Hardware-anchored receipts | ✅ silicon-signed 0x47C0 | ❌ | ❌ | ❌ |
| R-SI-1 audit (zero standalone *) | ✅ | ❌ | ❌ | ❌ |
| Formal verification (Coq theorems) | ✅ 84 theorems | ❌ 0 | ❌ 0 | ❌ 0 |
| Open RTL (Apache-2.0) | ✅ | ❌ closed | ❌ closed | ❌ closed |
| Modify-and-retape on next shuttle | ✅ | ❌ | ❌ | ❌ |
| ZK proof-of-training | ✅ on-chain | ❌ | ❌ | ❌ |
| φ-anchor cross-die invariant | ✅ Theorem 36.1 | ❌ | ❌ | ❌ |
| Verifiability score | **10/10** | 1/10 | 2/10 | 1/10 |

## Honest market positioning

Trinity is the best-in-class SBC in five narrow niches:

1. **Verifiable ML research** — Hailo/Jetson can't produce silicon-signed receipts
2. **Education & formal verification** — 84 Coq theorems vs 0 on competitors
3. **DePIN compute nodes** — ZK proof-of-training is mandatory
4. **Defence & safety-critical** — open RTL is required for adversarial audit
5. **Ternary LLM research** — BitNet b1.58 in silicon, [Microsoft bitnet.cpp](https://github.com/microsoft/BitNet) compatible

For everyone else — mainstream CV, generative AI on-device, robotics ROS2, maker projects — **Jetson + Hailo HAT is the correct answer**. That is not a failure; it is the explicit design choice.

## What changes after tape-out (2026-12-16)

When silicon arrives:

1. Replace all "PROJECTED" rows in this document with measured numbers
2. Run MLPerf Tiny benchmark suite — even if results are low, the test will be reproducible end-to-end (open RTL + open Compiler + open weights)
3. Publish silicon characterization paper to [HotChips 2027](https://hotchips.org/) workshop
4. Update Zenodo DOI 10.5281/zenodo.19227877 with the silicon characterization addendum
5. File OSHWA certification with real measured numbers

## References

- [Tiny Tapeout SKY26b shuttle](https://app.tinytapeout.com/shuttles/ttsky26b) — educational shuttle, not production
- [Hailo-10H specs](https://hailo.ai/products/ai-accelerators/hailo-10h-m-2-generative-ai-acceleration-module/)
- [Jetson Orin Nano Super](https://www.nvidia.com/en-us/autonomous-machines/embedded-systems/jetson-orin/)
- [Coral Edge TPU](https://coral.ai/)
- [BitNet b1.58 paper](https://arxiv.org/abs/2402.17764)
- [Microsoft bitnet.cpp](https://github.com/microsoft/BitNet)
- Trinity Theorem 36.1 anchor proof — see [Glava 37](./GLAVA_37_THEOREM_CHAPTER.md)
- Trinity v1.0.0 modules (co-authored Claude Opus 4.6) — preserved invariant

## Changelog

- **2026-05-18**: Initial corrected version. Replaces all prior occurrences of "63 tok/s/W" with "~1 GOPS @ ~1W @ 50 MHz ternary (PROJECTED, pending tape-out 2026-12-16)".
