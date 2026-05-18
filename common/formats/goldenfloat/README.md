# GoldenFloat (GF\*) — Canonical Bridge Module Family

**Status: CANONICAL** | **SSOT: [t27/conformance/FORMAT-SPEC-001.json](https://github.com/gHashTag/t27/blob/main/conformance/FORMAT-SPEC-001.json)**

---

## What is GoldenFloat?

**GoldenFloat (GF\*)** is a sign-magnitude floating-point format family where the exponent/mantissa
bit split is driven by the golden ratio **φ ≈ 1.618**. The target ratio
`exp_bits / mant_bits → φ / (φ + 1)` minimises the metric `phi_dist = |ratio − φ/(φ+1)|`.

**GF16 is the primary format** (phi_dist = 0.0486, closest to optimal in the family).

### Value Formula

```
value = (-1)^S * 2^(E - bias) * (1 + M / 2^mant_bits)
```

Source of truth: [github.com/gHashTag/t27](https://github.com/gHashTag/t27/blob/main/conformance/FORMAT-SPEC-001.json)

### φ² = φ + 1 Identity

```
φ² = φ + 1    (exact in f64, Ring 45 proven)

φ   (f64 hex) = 0x1.9E3779B97F4A8p+0  = 1.6180339887498950...
φ²  (f64 hex) = 0x1.4F1BBCDCBFA54p+1  = 2.6180339887498953...
φ+1 (f64 hex) = 0x1.4F1BBCDCBFA54p+1  = 2.6180339887498953...
residual = 0.0 (PASS — Ring 45 proven)
```

---

## Format Family (S+E+M+bias)

| Format | Bits | S | E  | M  | Bias  | exp/mant ratio | phi_dist     | Notes     |
|--------|------|---|----|----|-------|----------------|--------------|-----------|
| GF4    | 4    | 1 | 1  | 2  | 0     | 0.500          | 0.118        | All values are subnormals |
| GF8    | 8    | 1 | 3  | 4  | 3     | 0.750          | 0.132        |           |
| GF12   | 12   | 1 | 4  | 7  | 7     | 0.571          | 0.047        |           |
| **GF16** | **16** | **1** | **6** | **9** | **31** | **0.667** | **0.0486** | **PRIMARY** |
| GF20   | 20   | 1 | 7  | 12 | 63    | 0.583          | 0.035        |           |
| GF24   | 24   | 1 | 9  | 14 | 255   | 0.643          | 0.025        |           |
| GF32   | 32   | 1 | 12 | 19 | 2047  | 0.633          | 0.014        |           |

---

## Bit Layout (ASCII)

```
GF4  [3:0]:   [ S | E | M M ]
                 1   1   2

GF8  [7:0]:   [ S | E E E | M M M M ]
                 1   3       4

GF12 [11:0]:  [ S | E E E E | M M M M M M M ]
                 1   4         7

GF16 [15:0]:  [ S | E E E E E E | M M M M M M M M M ]
                 1   6             9            PRIMARY

GF20 [19:0]:  [ S | E E E E E E E | M M M M M M M M M M M M ]
                 1   7               12

GF24 [23:0]:  [ S | E E E E E E E E E | M M M M M M M M M M M M M M ]
                 1   9                   14

GF32 [31:0]:  [ S | E E E E E E E E E E E E | M M M M M M M M M M M M M M M M M M M ]
                 1   12                        19
```

Layout: MSB to LSB: `[sign | exponent | mantissa]`

---

## Special Cases

All formats follow the same encoding rules:

| Condition         | Encoding                  | Meaning          |
|-------------------|---------------------------|------------------|
| `E==0, M==0`      | Signed zero               | ±0.0             |
| `E==0, M!=0`      | Subnormal                 | `(-1)^S * 2^(1-bias) * (M / 2^mant_bits)` |
| `E==ALL_ONES, M==0` | ±Infinity               | ±∞               |
| `E==ALL_ONES, M!=0` | NaN                     | Not-a-Number     |
| otherwise         | Normal                    | See value formula |

**Note for GF4:** With E=1 bit, `ALL_ONES = 1'b1`. GF4 has **no normal encodings** — all
finite non-zero values are subnormals. This is by design; GF4 serves as an ultra-low-precision
format for ternary/binary weight networks.

---

## Modules

### Core (parameterised)

| File | Module | Description |
|------|--------|-------------|
| `gf_generic.v` | `gf_generic_decode` | Parameterised decoder: `EXP_BITS`, `MANT_BITS`, `BIAS` |
| `gf_generic.v` | `gf_generic_encode` | Structural pack (sign+exp+mant → raw) |
| `gf_generic_mul.v` | `gf_generic_mul` | Full multiply via `tri_mant_mul_wide`, sign XOR, exp add |
| `tri_mant_mul_wide.v` | `tri_mant_mul_wide` | `WIDTH × WIDTH → 2*WIDTH` shift-add (R-SI-1 keystone) |

### Per-width wrappers

| File | Decode module | Mul module | Format |
|------|--------------|-----------|--------|
| `gf4.v`  | `gf4_decode`  | `gf4_mul`  | GF4 (custom subnormal multiply) |
| `gf8.v`  | `gf8_decode`  | `gf8_mul`  | GF8 |
| `gf12.v` | `gf12_decode` | `gf12_mul` | GF12 |
| `gf16.v` | `gf16_decode`, `gf16_decode_full` | `gf16_mul` | GF16 PRIMARY |
| `gf20.v` | `gf20_decode` | `gf20_mul` | GF20 |
| `gf24.v` | `gf24_decode` | `gf24_mul` | GF24 |
| `gf32.v` | `gf32_decode` | `gf32_mul` | GF32 |

### Specialised

| File | Module | Description |
|------|--------|-------------|
| `gf16_mul.v` | `gf16_mul_opt` | Optimised GF16 PRIMARY multiplier: explicit 10×10 shift-add |
| `gf_family_pack.v` | `gf_family_pack` | Format-id dispatcher: `format_id[2:0]` → routes to gfN_mul |

### `gf16_decode_full` interface (PRIMARY)

Pinout-compatible with `gen/verilog/numeric/gf16.v` from t27:

```verilog
module gf16_decode_full (
    input  wire [15:0] raw,
    output wire        sign,
    output wire signed [6:0] exp_unbiased,
    output wire [9:0]  mant_normalized_q,   // 1.mant Q1.9
    output wire        is_zero,
    output wire        is_inf,
    output wire        is_nan,
    output wire        is_subnormal
);
```

### `gf_family_pack` dispatch table

```
format_id  | Format | Width
-----------+--------+------
3'd0       | GF4    | 4-bit
3'd1       | GF8    | 8-bit
3'd2       | GF12   | 12-bit
3'd3       | GF16   | 16-bit  ← PRIMARY
3'd4       | GF20   | 20-bit
3'd5       | GF24   | 24-bit
3'd6       | GF32   | 32-bit
3'd7       | reserved → NaN
```

Operands `a`, `b` passed as 32-bit holders (right-aligned, zero-extended).

---

## R-SI-1 Compliance

**R-SI-1 mandate: ZERO standalone `*` operators for mantissa multiplication.**

All mantissa multiplies use shift-add (partial-product expansion):

- `tri_mant_mul_wide.v`: `WIDTH × WIDTH` via `generate` loop — each partial product is
  `b[i] ? (a << i) : 0`, summed in a chain.
- `gf16_mul_opt.v`: explicit 10×10 partial products `pp0..pp9` (same as tiles/*/rtl/gf16_mul.v).
- `gf4_mul`: 2×2 subnormal product via `pp0_gf4 + pp1_gf4`, result `>> 1`.

Parameter expressions like `2*WIDTH` in `[2*WIDTH-1:0]` are **compile-time constants**
(Verilog parameter arithmetic), not runtime signal multiplications.

---

## Relation to `tiles/*/rtl/gf16_*.v`

**Verified: the existing `tiles/{phi-anchor,e-engine,gamma-surface}/rtl/gf16_*.v`
are GoldenFloat, NOT Galois Field.**

Evidence (from `tiles/phi-anchor/rtl/gf16_mul.v`):
```verilog
localparam BIAS = 6'd31;
wire sign_a = a[15];          // S bit
wire [5:0] exp_a = a[14:9];   // E=6 bits
wire [8:0] mant_a = a[8:0];   // M=9 bits
```

This matches GF16 (S=1, E=6, M=9, bias=31) exactly.
Those files are per-tile **copies**; the canonical version lives here in `common/formats/goldenfloat/`.

**Canonical `gf16_mul_opt.v` here is pinout-identical to `tiles/phi-anchor/rtl/gf16_mul.v`**
and additionally exposes `overflow` and `underflow` ports.

---

## Bridge to AI Formats (`common/formats/ai/`)

Planned conversion roadmap (separate sub-agent deliverable):

| Source format | Target GF format | Notes |
|---------------|-----------------|-------|
| NF4 (4-bit NF) | GF4             | Value-level LUT conversion |
| FP8 E4M3      | GF8             | Bias remapping (E4M3 bias=7 = GF8 bias=3+4) |
| FP8 E5M2      | GF8/GF16        | Precision loss; GF8 preferred |
| Posit(8,0)    | GF16            | GF16 wider range; accuracy within phi_dist |
| FP16 IEEE     | GF16            | Bias remapping (IEEE bias=15 vs GF16 bias=31) |

The bridge modules (when ready) will live in `common/formats/ai/` and import
GoldenFloat wrappers from this directory.

---

## Conformance Vectors

Mirrored from t27 SSOT in `vectors/`:

```
vectors/gf4_vectors.json   (6 vectors)
vectors/gf8_vectors.json   (32 vectors)
vectors/gf12_vectors.json  (7 vectors)
vectors/gf16_vectors.json  (36 vectors)
vectors/gf20_vectors.json  (33 vectors)
vectors/gf24_vectors.json  (33 vectors)
vectors/gf32_vectors.json  (36 vectors)
```

Key vectors per format: `zero_positive`, `one_point_zero`, `phi`, `phi_squared`,
`max_value`, `inf_pos`, `inf_neg`, `nan`, `subnormal_min`.

---

## Testbenches

Run with `iverilog` + `vvp` (Icarus Verilog):

```bash
# Individual TBs
iverilog -g2005-sv -I common/formats/goldenfloat \
  -o /tmp/sim_tb_gf16 \
  common/formats/goldenfloat/tb/tb_gf16.v \
  common/formats/goldenfloat/gf_generic.v \
  common/formats/goldenfloat/gf_generic_mul.v \
  common/formats/goldenfloat/tri_mant_mul_wide.v \
  common/formats/goldenfloat/gf16.v
vvp /tmp/sim_tb_gf16
```

All testbenches output `PASS GF<N>` or `FAIL GF<N> at vector <name>`.

**TB results (verified):**

| Testbench | Status | Key vectors |
|-----------|--------|-------------|
| tb_gf4    | PASS   | zero, one, max, half, neg_half, inf, nan |
| tb_gf8    | PASS   | zero, one, phi≈1.625, neg_phi, max, inf, nan, subnormal |
| tb_gf16   | PASS   | zero, one, two, half, neg_one, phi≈1.617, phi²≈2.617, inf, nan, subnormal |
| tb_gf32   | PASS   | zero, one, phi≈1.618034, neg_phi, inf, nan, subnormal |
| tb_gf16_mul | PASS | 1×1=1, 2×0.5=1, 1×(−1)=−1, inf×0=NaN, nan×1=NaN, inf×inf=inf, φ×φ≈φ+1 |
| tb_gf_family_pack | PASS | all 7 formats: 1.0×1.0=1.0; GF16 φ×φ≈φ+1; reserved→NaN |

---

## Design Constraints

- **Verilog-2005** (`iverilog -g2005-sv`)
- **`\`default_nettype none`** / **`\`default_nettype wire`** guards in every file
- **R-SI-1**: ZERO standalone `*` operators on signals (shift-add only)
- No system tasks in synthesisable code
- Timing-independent (combinational decode + multiply only)

---

*SSOT: https://github.com/gHashTag/t27/blob/main/conformance/FORMAT-SPEC-001.json*
*Format registry: https://github.com/gHashTag/t27/blob/main/FORMAT_REGISTRY.md*
*NeuronConstant: https://github.com/gHashTag/NeuronConstant*
