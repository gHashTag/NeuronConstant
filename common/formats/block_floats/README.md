# Block-Floats: OCP MX + LNS + Q-Format + StochasticRound

**NeuronConstant / common/formats/block_floats/**

RTL-модули для числовых форматов класса **Blackwell B100/B200** и **AMD MI400**:
OCP Microscaling Formats (MX), Logarithmic Number System, Q-format fixed-point,
и Stochastic Rounding с LFSR-16.

Вся семантика форматов восходит к 66-format семье из репозитория  
[trios-trainer-igla/src/fake_quant.rs](https://github.com/gHashTag/trios-trainer-igla/blob/main/src/fake_quant.rs)
(FormatKind enum, IGLA RACE proof-of-training).

---

## Модули (10 RTL + dispatcher)

| Файл | Формат | Описание |
|------|--------|----------|
| `mxfp4.v` | OCP MX FP4 | 1S+2E+1M (E2M1), блок 32 эл., shared E8M0. Decode/encode + block\_decode/encode. Blackwell MX micro-format |
| `mxfp6.v` | OCP MX FP6 | Два варианта: E2M3 (1S+2E+3M, bias=1) и E3M2 (1S+3E+2M, bias=3) через параметр `VARIANT`. Shared E8M0 |
| `mxfp8.v` | OCP MX FP8 | E4M3 (bias=7) и E5M2 (bias=15) через `VARIANT`. Shared E8M0 block exponent |
| `mxfp_block_dot32.v` | MX Block Dot | 32-элементный dot product с shared exponent. Параметр `WIDTH={4,6,8}`. Shift-add ядро (R-SI-1) |
| `lns8.v` | LNS8 | 8-bit Logarithmic NS (1S + 7-bit log Q3.4). Decode via 128-entry LUT. Encode via leading-bit + shift |
| `lns8_mul.v` | LNS Multiply | Multiply = log\_add: `result_log = a_log + b_log`. R-SI-1 keystone — zero runtime `*` operators |
| `q15.v` | Q0.15 | 16-bit Q-format (15 frac bits, range [-1,1)). Shift-add 15×15 multiply, saturation, accumulator |
| `q31.v` | Q0.31 | 32-bit Q-format (31 frac bits). Loop-unrolled shift-add 31×31, saturation |
| `stoch_round.v` | StochRound | LFSR-16 stochastic rounding (opcode 0xE9, Wave-42, t27). WIDE→NARROW Bernoulli rounding |
| `stoch_round_dot4.v` | SR Dot4 | 4-element dot + stochastic rounding на аккумуляции. Uses shift\_add\_mul8u |
| `block_floats_pack.v` | Dispatcher | format\_id (4-bit) → маршрутизация к одному из 9 форматов |

---

## format_id таблица (block_floats_pack)

| format\_id | Формат |
|-----------|--------|
| 0 | MXFP4 (OCP MX FP4 E2M1) |
| 1 | MXFP6\_E2M3 |
| 2 | MXFP6\_E3M2 |
| 3 | MXFP8\_E4M3 |
| 4 | MXFP8\_E5M2 |
| 5 | LNS8 (Logarithmic NS) |
| 6 | Q15 (Q0.15 fixed-point) |
| 7 | Q31 (Q0.31 fixed-point) |
| 8 | StochRound (LFSR-16, 32→8) |

---

## Архитектура OCP MX (Microscaling Formats)

Каждый MX блок содержит **32 элемента**, разделяющих один **8-bit shared exponent E8M0**.

```
Block layout (FP4 example):
┌──────────┬──────────┬────── ... ──────┐
│ E8M0 exp │ fp4[0]   │  fp4[1..31]     │
│  8 bits  │  4 bits  │   4b × 31       │
└──────────┴──────────┴─────────────────┘

Decode: (-1)^S × 2^(block_exp - 127 + local_exp - bias) × (1 + mantissa/2^M)
```

**Hardware target**: NVIDIA Blackwell B100/B200, AMD MI400 MX support.  
**Spec**: [OCP Microscaling Formats (MX)](https://www.opencompute.org/projects/microscaling-formats-mx)

---

## Logarithmic Number System (LNS8)

```
Value = (-1)^S × 2^(log_index / 16 - 3)
Format: [7]=sign, [6:0]=log_index (0..127)
```

**Ключевое преимущество**: умножение становится сложением:
```
lns8_mul: result.log = a.log + b.log   // R-SI-1 native, zero * operators
```

LUT: 128 записей (log2 → linear, Q8.8 output).

---

## Stochastic Rounding (0xE9)

```
Sacred opcode: 0xE9 (OP_STOCH_ROUND), Wave-42, t27
LFSR-16: Galois, poly x^16+x^15+x^13+x^4+1 (0xB400)
P(round_up) = fractional_part / 2^drop_bits
```

**Свойство несмещённости**: статистически, `E[rounded] = exact`, что предотвращает
накопление ошибок квантования при обучении нейросетей.

---

## R-SI-1 Compliance

Мандат R-SI-1: **ZERO standalone `*` операторов** в runtime-логике.

- Все умножения реализованы через **shift-add** (`shift_add_mul8u` модуль)
- LNS multiply: **чистое сложение** в log-домене
- Q-format multiply: unrolled shift-add loop
- Generate-блоки: `N*i` для part select — это elaboration-time константы, не runtime операторы

```bash
# Проверка:
! grep -nE '[^*/]\*[^*/=]' common/formats/block_floats/*.v | \
  grep -v "always @(\*)" | grep -v "//"
```

---

## Testbenches

| TB | Ключевые проверки |
|----|-------------------|
| `tb/tb_mxfp4.v` | decode 1.0/0.5/1.5/-1.0/0; roundtrip encode→decode; block sharing |
| `tb/tb_mxfp6.v` | E2M3 и E3M2: 1.0/1.5/0.5/-1.0/0 |
| `tb/tb_mxfp8.v` | E4M3 и E5M2: 1.0/2.0/0.5/-1.0/1.5/0 |
| `tb/tb_mxfp_block_dot32.v` | 32×(0.5×1.0)=16.0; zeros dot=0 |
| `tb/tb_lns8.v` | log(1)=idx48, log(2)=idx64, log(4)=idx80; encode round-trip |
| `tb/tb_lns8_mul.v` | log\_add property; sign XOR; zero; R-SI-1 keystone |
| `tb/tb_q15.v` | 0.5×0.5=0.25; saturation; -1×-1 |
| `tb/tb_q31.v` | 0.5×0.5=0.25; saturation |
| `tb/tb_stoch_round.v` | bias < 2% over 1000 samples; deterministic at frac=0; LFSR randomness |
| `tb/tb_block_floats_pack.v` | round-trip каждого format\_id (0–8) |

Прогон:
```bash
cd <repo_root>
for f in tb_mxfp4 tb_mxfp6 tb_mxfp8 tb_mxfp_block_dot32 \
         tb_lns8 tb_lns8_mul tb_q15 tb_q31 tb_stoch_round tb_block_floats_pack; do
  base=$(echo $f | sed 's/^tb_//')
  iverilog -g2005-sv -o /tmp/sim_$f \
    common/formats/block_floats/tb/$f.v \
    common/formats/block_floats/*.v
  vvp /tmp/sim_$f | tail -3
done
```

---

## Связанные форматы

- **common/formats/ai/** — NF4, FP8, Posit16, bfloat16, tri\_mant\_mul (v1.0.0)
- **common/formats/goldenfloat/** — GF4–GF32 (v1.0.0)

---

## Ссылки

- [OCP Microscaling Formats (MX) Spec](https://www.opencompute.org/projects/microscaling-formats-mx)
- [NVIDIA Blackwell B200 Architecture](https://www.nvidia.com/en-us/data-center/b200/)
- [AMD MI400 MX support](https://www.amd.com/en/products/accelerators/instinct.html)
- [IGLA RACE fake_quant.rs — 66-format семья](https://github.com/gHashTag/trios-trainer-igla/blob/main/src/fake_quant.rs)
- [NeuronConstant Repository](https://github.com/gHashTag/NeuronConstant)

---

*Verilog-2005, `default_nettype none/wire`. R-SI-1 clean.*
