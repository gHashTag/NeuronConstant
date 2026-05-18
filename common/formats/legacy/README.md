# Legacy Float Formats — RTL Modules

**Path:** `common/formats/legacy/`
**Standard:** Verilog-2005, `\`default_nettype none`, R-SI-1 clean (no `*` operator in RTL)
**Origin:** [`trios-trainer-igla/src/fake_quant.rs`](https://github.com/gHashTag/NeuronConstant/blob/main/trios-trainer-igla/src/fake_quant.rs) — `FormatKind` variants

---

## Format Table

| # | Module | Width | Format | Level | Note |
|---|--------|-------|--------|-------|------|
| 0 | `decimal32.v` | 32-bit | IEEE 754-2008 Decimal32 BID | **SUPPORTED** | Sign/exp/coeff extraction |
| 1 | `decimal64.v` | 64-bit | IEEE 754-2008 Decimal64 BID | **SUPPORTED** | Storage + field decode |
| 2 | `decimal128.v` | 128-bit | IEEE 754-2008 Decimal128 BID | **IDENTITY** | unsupported_in_f32 |
| 3 | `fp80.v` | 80-bit | x87 Extended Precision | **IDENTITY** | unsupported_in_f32; explicit integer bit |
| 4 | `binary128.v` | 128-bit | IEEE binary128 Quad | **IDENTITY** | unsupported_in_f32 |
| 5 | `binary256.v` | 256-bit | IEEE binary256 Octuple | **IDENTITY** | unsupported_in_f32 |
| 6 | `bcd_packed.v` | 8-bit | Packed BCD (2 digits/byte) | **SUPPORTED** | BCD adder, no `*` |
| 7 | `bcd8.v` | 8-bit | 8-bit BCD (2 decimal digits) | **SUPPORTED** | Wraps bcd_packed |
| 8 | `bcd16.v` | 16-bit | 16-bit BCD (4 decimal digits) | **SUPPORTED** | 2× bcd_packed cascade |
| 9 | `bcd_add.v` | N×4-bit | Generic N-digit BCD adder | **SUPPORTED** | Parameterized, generate |
| 10 | `ibm_hfp_short.v` | 32-bit | IBM S/360 HFP Short (base-16) | **SUPPORTED** | Decode + ×16/×256 shifts |
| 11 | `ibm_hfp_long.v` | 64-bit | IBM S/360 HFP Long (base-16) | **IDENTITY** | unsupported_in_f32 |
| 12 | `vax_f.v` | 32-bit | VAX F-float (bias=128) | **SUPPORTED** | PDP-11 byte order decode/encode |
| 13 | `vax_d.v` | 64-bit | VAX D-float (bias=128) | **IDENTITY** | unsupported_in_f32 |
| 14 | `vax_g.v` | 64-bit | VAX G-float (bias=1024) | **IDENTITY** | unsupported_in_f32; IEEE-like |
| 15 | `vax_h.v` | 128-bit | VAX H-float (bias=16384) | **IDENTITY** | unsupported_in_f32 |
| 16 | `cray_float.v` | 64-bit | Cray-1 (bias=16384, no implicit 1) | **SUPPORTED** | Decode/encode + normalized flag |
| 17 | `minifloat.v` | 4–32-bit | Configurable S/E/M/BIAS minifloat | **SUPPORTED** | E4M3, E5M2, FP4 etc. |
| — | `legacy_pack.v` | 256-bit | Format dispatcher (format_id[4:0]) | **DISPATCHER** | Identity passthrough per format |

**Levels:**
- **SUPPORTED** — decode/encode fields implemented, arithmetic via shifts (no `*`)
- **IDENTITY** — storage struct + identity passthrough (decode = raw, encode = input); faithful arithmetic deferred Phase 2
- **DISPATCHER** — routes data bus by `format_id`, wraps individual sub-modules

> **Honest disclaimer:** IDENTITY formats are _not_ faithful implementations. They store and return raw bits unchanged. Arithmetic operations are not implemented. This follows the IGLA `fake_quant.rs` Phase C L-C2 approach for `unsupported_in_f32` variants.

---

## Bit Layouts

### IEEE 754-2008 Decimal32 BID (32-bit)
```
[31]    [30:26]      [25:0]
  S   Combination   Trailing Significand (T)
```
- Combination field `[30:29] == 2'b11`: short exponent in `[28:21]`, T in `[20:0]`
- Combination field `[30:29] != 2'b11`: exponent in `[29:22]`, T in `[21:0]`

### x87 fp80 Extended Precision (80-bit)
```
[79]  [78:64]  [63]        [62:0]
  S    EXP     J(integer)  Mantissa (explicit)
```
- Bias = 16383; J=1 for normalized numbers (explicit leading bit, unlike IEEE)

### IBM HFP Short (32-bit)
```
[31]  [30:24]     [23:0]
  S   EXP(b16)   Hex Mantissa (0.HHHHHH)
```
- Base: **16** (not 2)
- Exponent bias = 64
- 1.0 = `0x41100000`: exp=0x41=65 (true_exp=1), mant=`0x100000` → 0.0625×16¹=1.0

### VAX F-float (32-bit, PDP-11 word order)
```
Physical 32-bit register:
[31:16]          [15]  [14:7]      [6:0]
Mantissa[22:7]    S    EXP[7:0]   Mantissa[6:0]
```
- First 16-bit word (W1) = `{S, EXP[7:0], M[6:0]}` at bits `[15:0]`
- Second 16-bit word (W0) = `M[22:7]` at bits `[31:16]`
- 1.0 = `0x00004080`: W1=`0x4080` → S=0, EXP=`0x81`=129 (bias=128, true_exp=1), M=0

### Cray-1 (64-bit)
```
[63]  [62:48]    [47:0]
  S   EXP(15b)   Mantissa (explicit, no implicit leading 1)
```
- Bias = 16384
- Convention: value = (−1)ˢ × 2^(E−16384) × 0.M
- Normalized: bit 47 of mantissa must be 1
- 1.0 = `0x4001800000000000`: exp=0x4001=16385, mant=`0x800000000000` → 0.5×2¹=1.0

### Minifloat (parameterized)
```
[WIDTH-1 : WIDTH-S_BITS]  [WIDTH-S_BITS-1 : M_BITS]  [M_BITS-1 : 0]
        Sign                      Exponent                Mantissa
```
- Examples: E4M3 (8-bit, BIAS=7), E5M2 (8-bit, BIAS=15), FP4 (4-bit, BIAS=1)

---

## IBM HFP Base-16 vs IEEE Base-2

| Property | IBM HFP | IEEE 754 |
|----------|---------|----------|
| Exponent base | **16** | 2 |
| Normalization unit | Hex digit (4 bits) | Binary bit (1 bit) |
| Leading digit guarantee | non-zero hex digit | bit = 1 (implicit) |
| Precision loss | Up to 3 bits per operation (subnormal hex digit) | ≤ 0.5 ULP |
| Exponent bias (short) | 64 | 127 |
| 1.0 encoding | `0x41100000` | `0x3F800000` |

IBM HFP can represent the same value with up to 4 different bit patterns (unnormalized), causing up to 3 bits of precision loss compared to IEEE.

---

## VAX Byte Ordering Note (PDP-11 Origin)

VAX floats use **PDP-11 byte ordering** — a historical artifact from the PDP-11 architecture:

- 32-bit values are stored as two 16-bit words in **little-endian word** order, but each word is in **big-endian bit** order for the fields
- The sign and exponent are in the **first physical 16-bit word** (lower address), not in the most-significant bits of the 32-bit integer
- For VAX F-float: bits `[15:0]` = `{S, EXP[7:0], M[6:0]}` (the "first word")
- This differs from IEEE 754 where sign+exponent are always in the most-significant bits

When exchanging VAX floats with IEEE systems, byte-swapping is required. DEC provided the `CVT` instruction family for conversion.

---

## Test Vectors

| Test | Module | Input | Expected | Status |
|------|--------|-------|----------|--------|
| BCD add | bcd16, bcd_add | 1234 + 5678 | **6912** | PASS |
| IBM HFP 1.0 | ibm_hfp_short | `0x41100000` | sign=0, exp=0x41, mant=0x100000 | PASS |
| IBM HFP 2.0 | ibm_hfp_short | `0x41200000` | mant=0x200000 | PASS |
| VAX F 1.0 | vax_f | `0x00004080` | sign=0, exp=0x81, enc=0x00004080 | PASS |
| Cray 1.0 | cray_float | `0x4001800000000000` | exp=0x4001, mant=0x800000000000, normalized=1 | PASS |
| Round-trip | decimal32/64/128, fp80, binary128/256, minifloat | arbitrary | in==out | PASS |

---

## Files

```
common/formats/legacy/
├── decimal32.v        # Decimal32 BID, field extract
├── decimal64.v        # Decimal64 BID, storage+decode
├── decimal128.v       # Decimal128, identity
├── fp80.v             # x87 80-bit, identity
├── binary128.v        # IEEE quad, identity
├── binary256.v        # IEEE octuple, identity
├── bcd_packed.v       # Packed BCD 2-digit adder
├── bcd8.v             # 8-bit BCD adder
├── bcd16.v            # 16-bit BCD adder
├── bcd_add.v          # N-digit BCD adder (parameterized)
├── ibm_hfp_short.v    # IBM HFP 32-bit, decode+shifts
├── ibm_hfp_long.v     # IBM HFP 64-bit, identity
├── vax_f.v            # VAX F 32-bit, decode/encode
├── vax_d.v            # VAX D 64-bit, identity
├── vax_g.v            # VAX G 64-bit, identity
├── vax_h.v            # VAX H 128-bit, identity
├── cray_float.v       # Cray-1 64-bit, decode/encode
├── minifloat.v        # Configurable S/E/M/BIAS
├── legacy_pack.v      # format_id[4:0] dispatcher
└── tb/
    ├── tb_decimal32.v
    ├── tb_bcd.v
    ├── tb_ibm_hfp.v
    ├── tb_vax.v
    ├── tb_cray.v
    └── tb_identity.v
```

---

*v1.0.0 Opus 4.6 preserved. R-SI-1 clean. Verilog-2005.*
