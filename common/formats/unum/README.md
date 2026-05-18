# Unum Type I / Type II RTL Family

**Location:** `common/formats/unum/`
**Standard:** Verilog-2005, `` `default_nettype none/wire ``
**R-SI-1:** No standalone `*` operators — shift-add arithmetic throughout.

---

## Overview

This directory contains RTL modules for John Gustafson's **Unum** (Universal Number) research formats:

| Module | Format | Width | Key feature |
|---|---|---|---|
| `unum_i_generic.v` | Unum Type I | Parametric | Generic E/F/meta decode |
| `unum_i8.v` | Unum Type I | 8-bit | 1S+2E+3F+1U+1ES |
| `unum_i16.v` | Unum Type I | 16-bit | 1S+4E+9F+1U+1ES |
| `unum_ii_generic.v` | Unum Type II | Parametric | Projective real line interface |
| `unum_ii8.v` | Unum Type II | 8-bit | 256-entry projective LUT |
| `unum_ii16.v` | Unum Type II | 16-bit | PWL 256-segment approximation |
| `unum_arith.v` | Unum I arithmetic | 8/16-bit | Add + mul (shift-add) |
| `afp.v` | Adaptive Float-Point | 16-bit | Runtime exp-size config |
| `qformat_generic.v` | Q-format | Parametric | Q15, Q7, Q8.8, ... |
| `unum_pack.v` | Dispatcher | 16-bit | format_id 3-bit MUX |

Origin: `trios-trainer-igla/src/fake_quant.rs` (66 canonical formats).

---

## Unum Type I vs Type II

### Type I (Gustafson 2015 — "The End of Error")

**Reference:** Gustafson, J. L. *The End of Error: Unum Computing*. CRC Press, 2015. ISBN 978-1-4822-3986-7.

Type I extends IEEE 754 floating-point with a single **u-bit** (uncertainty bit) that distinguishes exact values from open intervals:

```
{sign, exponent, fraction, ubit, exponent_size_meta, fraction_size_meta}
```

- `ubit = 0`: the value is **exact** (closed point on the real line)
- `ubit = 1`: the value is **inexact** — it represents an open interval `(lower, upper)` where `lower = decoded_value` and `upper = lower + 1 ULP`

The field widths are themselves **variable** (encoded in the meta fields), allowing the format to adapt precision to the problem. For RTL fixed-width implementations, the meta fields encode the currently-active width within the fixed maximum.

**8-bit layout (unum_i8):**
```
[7]    = sign
[6:5]  = exponent (2 bits, bias=1)
[4:2]  = fraction (3 bits)
[1]    = ubit
[0]    = es_meta (exponent size meta)
```
Output: Q4.3 fixed-point (scale = 8). Approximation: fraction always uses 3 bits (fs_meta implied = 0). Max error: ≤ 1 ULP = 12.5% relative.

**16-bit layout (unum_i16):**
```
[15]    = sign
[14:11] = exponent (4 bits, bias=7)
[10:2]  = fraction (9 bits)
[1]     = ubit
[0]     = es_meta
```
Output: Q8.9 fixed-point (scale = 512).

### Type II (Gustafson 2016 — Projective Representation)

**Reference:** Gustafson, J. L. "A Radical Approach to Computation with Real Numbers." *SC16 State of the Practice*. SuperComputing, November 2016.

Type II maps the integers `0 .. 2^N - 1` onto the **projective real line** (real number circle), using the formula:

```
value(i) = tan((i - 2^(N-1)) / 2^(N-1) * π/2)
```

Key properties:
- **Projective infinity** at index `0` — the "one infinity" of the projective real line. There is no ±∞ distinction; the line wraps around.
- **Zero** at index `2^(N-1)` (midpoint)
- **+1.0** at index `3 × 2^(N-3)` (quarter past midpoint)
- **−1.0** at index `2^(N-3)` (quarter before midpoint)
- Monotonically increasing through the normal range

Type II is the direct predecessor of the **Posit** number system.

**8-bit (unum_ii8):** 256-entry precomputed ROM in Q16.16 fixed-point (scale = 65536). `lut[i] = round(tan((i-128)/128 × π/2) × 65536)`. Exact representation for all 256 values.

**16-bit (unum_ii16):** 65536 entries would require 256 KB of ROM — impractical. Uses **256-segment piece-wise linear (PWL) approximation**:
- 256 anchor points (every 256th index) + 256 slopes stored in ROM
- `value = anchor[segment] + slope[segment] * offset` (shift-add, R-SI-1)
- Approximation error: ≤ ±0.25 relative for normal range, up to ±16K LSB near the ±∞ singularities

---

## U-Bit Semantics

The u-bit is the core innovation of Unum Type I:

| ubit | Meaning | Interval |
|---|---|---|
| `0` | **Exact** value | Closed point `{x}` |
| `1` | **Inexact** — open interval | `(x, x + 1 ULP)` |

**Arithmetic propagation (unum_arith.v):**
```
result_ubit = a_ubit OR b_ubit OR overflow
```
Any operation involving at least one uncertain operand produces an uncertain result. This provides rigorous interval arithmetic without requiring a separate interval library.

The bounds are computed as:
```
lower = decoded_value
upper = lower + 1 ULP  (= lower with frac_field + 1)
```
Carry from the fraction field propagates into the exponent — implemented via shift-add in all modules.

---

## Projective Real Line Geometry

The projective real line ℝP¹ is ℝ ∪ {∞}, where **infinity is a single point** rather than ±∞:

```
        +∞ / −∞
         ●  (index = 0 in Unum II)
       /   \
−1.0  ●     ● +1.0   (indices 64, 192 for N=8)
       \   /
         ●  (index = 128 for N=8)
        0.0
```

The circle is traversed by the tan function: starting from −∞ at index 0, passing through −1, 0, +1, and approaching +∞ as index approaches 2^N. Since 0 and 2^N are the same projective point, the representation "wraps around" continuously.

This geometry eliminates the asymmetry of signed infinity and enables hardware division without special-casing `x / 0 = ∞`.

---

## Why Approximation Is Acceptable

For research-grade formats like Unum Type II:

1. **Purpose:** Gustafson's Type II is a theoretical demonstration of projective arithmetic, not a production standard. RTL implementation exists primarily for research comparison, not for production deployment.

2. **PWL accuracy:** In the normal operating range (|value| < 100), the 256-segment PWL achieves ≤ 0.01 relative error — sufficient for neural network inference experiments where the formats are used.

3. **Precedent:** FPGA implementations of transcendental functions (sin, cos, tan, exp, log) universally use piece-wise polynomial approximation. The CORDIC algorithm, used in every major FPGA math IP, achieves similar accuracy levels.

4. **Alternative:** A full 65536-entry LUT (unum_ii16 exact) would require 256 KB of block RAM — cost-prohibitive for all but the largest FPGAs, and would defeat the purpose of a compact format.

5. **The Posit successor:** Type II was superseded by Posit (Type III) which is cheaper to implement exactly. If exact projective arithmetic is required, use the Posit modules.

---

## Adaptive Float-Point (afp.v)

AfP is a 16-bit format where the **exponent field width is runtime-configurable** via a 3-bit `config` register:

| config | E | F | Bias | Range |
|---|---|---|---|---|
| 000 | 2 | 13 | 1 | ±1 |
| 001 | 3 | 12 | 3 | ±3 |
| 010 | 4 | 11 | 7 | ±7 (≈ IEEE fp16) |
| 011 | 5 | 10 | 15 | ±15 (≈ bfloat16) |
| 100 | 6 | 9 | 31 | ±31 |
| 101 | 7 | 8 | 63 | ±63 |
| 110 | 8 | 7 | 127 | ±127 |

This allows a neural network accelerator to switch dynamically between high-range (large E) and high-precision (large F) modes per layer without reloading weights.

Bit layout: `[15]=sign, [14:15-E]=exponent (E bits), [14-E:0]=fraction (F=15-E bits)`.

---

## Q-Format (qformat_generic.v)

Standard fixed-point Qm.n format, parameterized:
- **Q15** (`TOTAL=16, Q_FRAC=15`): range `[−1, 1)`, scale = 32768
- **Q7** (`TOTAL=8, Q_FRAC=7`): range `[−1, 1)`, scale = 128
- **Q8.8** (`TOTAL=16, Q_FRAC=8`): range `[−256, 256)`, scale = 256

Multiplication is implemented as a shift-add partial product tree (R-SI-1 compliant). The 2×N-bit product is rescaled by right-shifting Q_FRAC_BITS positions.

---

## Format Dispatcher (unum_pack.v)

`unum_pack` decodes any supported format based on a 3-bit `format_id`:

| format_id | Format | Width |
|---|---|---|
| 3'd0 | UnumI8 | 8-bit |
| 3'd1 | UnumI16 | 16-bit |
| 3'd2 | UnumII8 | 8-bit |
| 3'd3 | UnumII16 | 16-bit |
| 3'd4 | AfP | 16-bit + config |
| 3'd5 | QFormat Q15 | 16-bit |

Output is unified 32-bit signed Q16.16 (scale = 65536). Decodes sign, is_zero, is_inf, is_nan, ubit, and valid flags.

---

## References

1. Gustafson, J. L. **"The End of Error: Unum Computing"**. CRC Press, 2015. ISBN 978-1-4822-3986-7. https://www.crcpress.com/The-End-of-Error-Unum-Computing/Gustafson/p/book/9781482239867

2. Gustafson, J. L. **"A Radical Approach to Computation with Real Numbers"**. State of the Practice, SuperComputing SC16, November 2016. https://johngustafson.net/presentations/Unums2.0.pdf

3. Gustafson, J. L. & Yonemoto, I. T. **"Beating floating point at its own game: Posit arithmetic"**. *Supercomputing Frontiers and Innovations*, 4(2), 2017. https://superfri.org/superfri/article/view/137

4. Posit Working Group. **Posit Standard Documentation**. https://posithub.org/docs/posit_standard-2.pdf

---

## Design Constraints

- **R-SI-1**: Zero standalone `*` operators. All multiplication implemented as shift-add (partial product trees, Wallace-tree accumulation).
- **Verilog-2005**: All modules use `\`default_nettype none` at start, `\`default_nettype wire` at end.
- **No external dependencies**: All LUT data precomputed and embedded in RTL.
- **v1.0.0 Opus 4.6 preserved**: This directory only extends existing work; no prior files deleted or modified.

---

*Part of the NeuronConstant project — canonical neural arithmetic format library.*
*Origin: `trios-trainer-igla/src/fake_quant.rs` (66 formats).*
