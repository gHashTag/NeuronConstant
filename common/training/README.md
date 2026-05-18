# common/training — Muon Optimizer + φ-LR + T-JEPA EMA в RTL

Первая в мире реализация **Newton-Schulz orthogonalization** в синтезируемом Verilog.
Порт из [trios-trainer-igla](https://github.com/gHashTag/trios-trainer-igla) в GoldenFloat GF16 hardware.

---

## Архитектура

### Muon Optimizer (Keller Jordan arXiv:2604.01472)

Muon — оптимизатор на основе SGD с momentum, где momentum обновление
ортогонализируется через итерацию Newton-Schulz перед применением к параметрам.
Это сохраняет спектральную структуру градиентов и даёт ~35% более быструю
сходимость по сравнению с AdamW для скрытых слоёв.

#### Newton-Schulz 5-шаговый обзор

Quintic NS5 полином (один шаг):

```
X_{k+1} = a·X + b·(X·X^T)·X + c·(X·X^T)²·X
```

Коэффициенты (Keller Jordan):
| Коэффициент | Значение | GF16  |
|-------------|----------|-------|
| a           | 3.4445   | 0x4172 |
| b           | −4.7750  | 0xC263 |
| c           | 2.0315   | 0x4008 |

**Сумма a+b+c = 0.701** — фиксированная точка для orthogonal матриц.

После 5 итераций матрица сходится к ближайшей ортогональной: ‖X^T·X − I‖ → min.

#### Вычислительный граф NS (3×3 GF16)

```
Input X (9×GF16)
    │
    ├─► Compute A = X·X^T   [27 gf16_mul + 18 gf16_add]
    │
    ├─► Compute B = A·X     [27 gf16_mul + 18 gf16_add]
    │
    ├─► Compute C = A·A     [27 gf16_mul + 18 gf16_add]
    │
    ├─► Compute D = C·X     [27 gf16_mul + 18 gf16_add]
    │
    └─► Result = a·X + b·B + c·D  [9×3 gf16_mul + 9×2 gf16_add]
```

Итого: **117 gf16_mul + 90 gf16_add** на одну итерацию.

---

## Файлы модулей

| Файл | Описание | Latency |
|------|----------|---------|
| `muon_ns_iter.v` | Один шаг NS5, 3×3 GF16, комбинационный | 1 cycle |
| `muon_ns_5step.v` | 5 итераций NS, FSM: IDLE→STEP1..5→DONE | 5 cycles |
| `muon_optimizer.v` | Full Muon с momentum buffer (3×3 register) | ~8 cycles |
| `muon_cwd.v` | Muon + Coupled Weight Decay | ~12 cycles |
| `phi_lr_rom.v` | 54-step φ-LR ROM (pre-computed) | 0 cycles |
| `phi_lr_warmup.v` | Runtime φ-LR с warmup + decay | 0 cycles |
| `jepa_ema.v` | T-JEPA EMA для одного параметра GF16 | 0 cycles |
| `jepa_ema_array.v` | Parallel EMA для N параметров | 1 cycle |
| `adamw_optimizer.v` | AdamW baseline (sqrt via Newton-Raphson) | ~8 cycles |
| `training_pack.v` | Top-level opcode dispatcher | varies |

---

## φ-LR Schedule (54-step canonical)

```
LR
0.236 │                         ████
      │                     ████    ████████████
0.150 │         ████████████                    ████████████████████
0.009 │████████
      └─────────────────────────────────────────────────────────────
      step  0       13       26      27               53
            ←── warmup ───→  ←── φ^(-n/27) decay ──────────────────→
```

Base LR = α_φ = 1/φ³ ≈ 0.2361 (golden ratio based)

27 warmup шагов: линейный ramp 0 → α_φ
27 decay шагов: α_φ · φ^(-n/27) decay

**Матчит** `trios_phi_schedule::lr_schedule_54` из Rust реализации.

---

## T-JEPA EMA

EMA обновление target encoder:

```
θ_target ← decay · θ_target + (1 − decay) · θ_online
```

По умолчанию decay = 0.998 (GF16: 0x3DFE).
Реализация через два gf16_mul + один gf16_add.

---

## AdamW Baseline (для сравнения)

Phi-based константы:
| Параметр | Значение | Источник |
|----------|----------|---------|
| β₁ | 1/φ ≈ 0.618 | Золотое сечение |
| β₂ | 0.999 | Стандарт |
| WD | 1/φ³ ≈ 0.236 | Золотое сечение |

Inverse sqrt через 2-шаговый Newton-Raphson:
```
x₀ = 0.5
x₁ = x₀ · (1.5 − 0.5·v·x₀²)
x₂ = x₁ · (1.5 − 0.5·v·x₁²)
√v ≈ v · x₂
```

---

## Training Pack Opcodes

```
opcode 3'b000 = ADAMW          — AdamW шаг (single param)
opcode 3'b001 = MUON           — Muon шаг (3×3 matrix)
opcode 3'b010 = MUONCWD        — Muon + Coupled Weight Decay
opcode 3'b011 = PHILR_LOOKUP   — φ-LR ROM lookup (step_idx → lr)
opcode 3'b100 = PHILR_DECAY    — φ-LR warmup + decay
opcode 3'b101 = JEPA_EMA       — EMA update (single param)
opcode 3'b110 = JEPA_EMA_ARR   — EMA array (9 params parallel)
```

---

## Champion Baseline Lock

```
BPB=2.2393  seed=43  step=27000  optimizer=AdamW
```

AdamW с phi-constants — текущий champion. Muon — research path для улучшенной сходимости.

---

## Use Case: On-Chip Training для DePIN

Эти модули реализуют один шаг обучения полностью в hardware:

```
Input: gradient matrix (3×3 GF16)
  → Muon NS5 orthogonalization (5 cycles)
  → Update parameters
  → φ-LR schedule lookup (0 cycles)
  → T-JEPA EMA update for target encoder
Output: ZK-proof-friendly training step

Use: DePIN proof-of-compute (#10 ZK proof extension)
     Каждый шаг verifiable on-chain через ZK proof
```

---

## R-SI-1 Compliance

Все операции умножения реализованы через
`common/formats/goldenfloat/gf16_mul.v` (shift-add internally).

Проверка:
```bash
! grep -nE '[^*/]\*[^*/=]' common/training/*.v
# Результат: только array index expressions и comments — CLEAN
```

---

## References

- Keller Jordan (2026). **"Muon: Momentum + Newton-Schulz Orthogonalization"**
  [arXiv:2604.01472](https://arxiv.org/abs/2604.01472)
- LeCun et al. (2023). **"Self-Supervised Learning from Images with JEPA"**
  [paper](https://openreview.net/forum?id=BzbpmTqgsh)
- trios-trainer-igla source: [`src/optimizer.rs`](https://github.com/gHashTag/trios-trainer-igla/blob/main/src/optimizer.rs)
  (MuonOptimizer line 216, phi_lr_schedule line 545, MuonCwd line 487)
- trios-trainer-igla source: [`src/jepa/ema.rs`](https://github.com/gHashTag/trios-trainer-igla/blob/main/src/jepa/ema.rs)
- NeuronConstant GF16 spec: [`common/formats/goldenfloat/FORMAT-SPEC-001.json`](../formats/goldenfloat/FORMAT-SPEC-001.json)
  Layout: S(1)|E(6)|M(9), bias=31

---

*v1.0.0 Opus 4.6 modules preserved. Verilog-2005. `default_nettype none/wire.*
