# AI Format Family — `common/formats/ai/`

Canonical RTL modules for industry-standard AI quantization and floating-point formats.
Verilog-2005. All multiplication via shift-add (R-SI-1 compliant — zero standalone `*` operators).

---

## Format Table

| Format | Bits | Layout | Range | Primary Use |
|--------|------|--------|-------|-------------|
| NF4 | 4 | non-uniform LUT (16 entries) | [−1, 1] | QLoRA weight quantization |
| FP4-E2M1 | 4 | 1s + 2e + 1m | ±6 | NVIDIA Blackwell inference |
| FP8-E4M3 | 8 | 1s + 4e + 3m | ±448 | NVIDIA Hopper H100 (precision) |
| FP8-E5M2 | 8 | 1s + 5e + 2m | ±57344 | NVIDIA Hopper H100 (range) |
| Posit\<16,1\> | 16 | sign + regime + 1e + fraction | tapered | Research / neuromorphic |
| bfloat16 | 16 | 1s + 8e + 7m | ±3.4×10³⁸ | AI training (TF/PyTorch) |

---

## Module List

| File | Description |
|------|-------------|
| `tri_mant_mul.v` | 4×4 unsigned mantissa multiplier, shift-add. Sacred primitive. Co-author Opus 4.6. |
| `tri_mant_mul8.v` | 8×8 unsigned mantissa multiplier, shift-add (for FP8 / Posit / bfloat16) |
| `nf4_codec.v` | NF4 encode (nearest LUT) + decode (LUT lookup) |
| `nf4_dot4.v` | Dot product of 4 NF4 pairs via tri_mant_mul |
| `fp4_e2m1.v` | FP4-E2M1 decode (→ int8 ×16) + encode |
| `fp8_e4m3.v` | FP8-E4M3 decode (→ int16 Q8.7) + encode |
| `fp8_e5m2.v` | FP8-E5M2 decode (→ int16 Q9.6) + encode |
| `posit16_add.v` | Posit\<16,1\> addition (decode → fixed-point add → encode) |
| `posit16_mul.v` | Posit\<16,1\> multiplication via tri_mant_mul8 |
| `bf16_mul.v` | bfloat16 multiplier via tri_mant_mul8 |

---

## R-SI-1 Compliance

**Rule R-SI-1**: Zero standalone `*` operators in synthesisable RTL.

All mantissa multiplication is implemented via explicit shift-add partial products in
`tri_mant_mul` and `tri_mant_mul8`. These are the canonical multiply primitives for
the entire NeuronConstant AI format family.

Verification: `! grep -nE '[^*/]\*[^*/=]' common/formats/ai/*.v`

---

## Relation to t27 GoldenFloat SSOT

This module family provides **bridge formats** for interoperability with industry-standard
AI hardware (NVIDIA Hopper/Blackwell, QLoRA, PyTorch/TensorFlow training pipelines).

The **canonical numeric kernel** for TRI-NET is **GoldenFloat (GF)**:
a sign-magnitude floating-point format with phi-driven exponent/mantissa split,
defined in [`t27/conformance/FORMAT-SPEC-001.json`](https://github.com/gHashTag/t27).

GoldenFloat family (from SSOT):

| Format | Bits | Layout | Notes |
|--------|------|--------|-------|
| GF4 | 4 | 1s + 1e + 2m | Minimal |
| GF8 | 8 | 1s + 3e + 4m | Compact |
| GF12 | 12 | 1s + 4e + 7m | Medium |
| GF16 | 16 | 1s + 6e + 9m | **PRIMARY** |
| GF20 | 20 | 1s + 7e + 12m | Extended |
| GF24 | 24 | 1s + 9e + 14m | High |
| GF32 | 32 | 1s + 12e + 19m | Full |

NF4 / FP4 / FP8 / Posit16 / bfloat16 are **PLANNED** in t27 (not yet implemented there).
This module family closes that gap in NeuronConstant — providing synthesisable RTL
implementations that feed into the TRI-NET pipeline.

### Planned Round-trip Bridge: each format → GF16

Each format in this family should eventually have a conversion to/from GF16 (PRIMARY
canonical format). Skeleton interfaces (TODO — to be implemented in a future PR):

```verilog
// TODO: fp8_e4m3 → GF16 bridge
// function [15:0] fp8_e4m3_to_gf16;
//   input [7:0] fp8_in;
//   // 1. Decode fp8_e4m3 → intermediate Q8.7
//   // 2. Re-encode as GF16: {sign, gf_exp[5:0], gf_mant[8:0]}
//   //    where gf_exp uses phi-driven split per FORMAT-SPEC-001
// endfunction

// TODO: fp8_e5m2 → GF16 bridge
// TODO: nf4    → GF16 bridge (via decode LUT → GF16 encoding)
// TODO: fp4_e2m1 → GF16 bridge
// TODO: posit16 → GF16 bridge (scale extraction compatible)
// TODO: bf16   → GF16 bridge (exponent re-bias + mant truncate)
```

The GF-format RTL modules live in `common/formats/gf/` (separate subagent / PR).
This AI family does **not** touch `common/formats/gf/`.

---

## Testbenches

Located in `tb/`. Each testbench prints `PASS` or `FAIL` and calls `$finish`.

Run all:
```bash
cd <repo-root>
for f in common/formats/ai/tb/tb_*.v; do
  base=$(basename $f .v | sed 's/^tb_//')
  iverilog -g2005-sv -I common/formats/ai \
    -o /tmp/sim_$base $f common/formats/ai/$base.v \
    common/formats/ai/tri_mant_mul*.v 2>&1
  vvp /tmp/sim_$base
done
```

---

## References

- Tim Dettmers et al., "QLoRA: Efficient Finetuning of Quantized LLMs" (NF4 format)
- IEEE 754-2019 (FP8 base conventions)
- John Gustafson, "Beating Floating Point at its Own Game: Posit Arithmetic" (Posit format)
- NVIDIA H100 Architecture Whitepaper (FP8-E4M3 / FP8-E5M2)
- t27 FORMAT-SPEC-001.json — TRI-NET GoldenFloat canonical SSOT: https://github.com/gHashTag/t27
