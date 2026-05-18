# TRI ↔ Silicon Support Matrix

> **Author:** Dmitrii Vasilev `<admin@t27.ai>`
> **License:** Apache-2.0
> **Date:** 2026-05-18
> **Purpose:** Точная карта что из $TRI экосистемы где живёт — кремний vs depin-v1 ветка vs софт. Без рекламы, без "63 tok/s/W", только факты.

## 0. TL;DR

| Слой | $TRI поддержка сегодня |
|---|---|
| **TTSKY26b Submitted кремний** (v1.0, tape-out 2026-12-16) | ❌ Нет TRI-специфичного HW |
| **depin-v1 ветки** (НЕ в кремнии, готовы к TTSKY26c) | ⚠️ Mining-receipt акселератор (B5) |
| **TTSKY26c кремний** (планируется Sep–Nov 2026 submit) | ✅ Аппаратное mining + attestation |
| **Софт** (daemon/SDK/contract/docs) | ✅ Готов как pre-silicon mock + on-chain |

Полная честность: **TTSKY26b чипы, которые поедут на тэйп-аут, не имеют TRI-специфичных хардварных блоков.** Они общего назначения. $TRI mining возможен через хост-софт + базовая криптография чипа, но без аппаратного ускорения именно для TRI.

## 1. Что в TTSKY26b Submitted кремнии — детально

### 1.1 Phi #4914 (1×1, hash `8a8fcaa`, artifact `7057262394` 1 030 KB)

| Блок | Назначение | TRI-связь |
|---|---|---|
| Lucas POST | Boot integrity check | Базис для proof-of-identity на mining запросе |
| φ-anchor `0x47C0` на `{uio_out, uo_out}` | Кросс-die инвариант (TG-TRIAD-X Theorem 36.1) | Используется хост-софтом как chip-ID для miner registration |
| PUF read | Уникальная аппаратная идентичность | Может подписывать mining proofs (через хост-софт) |
| CLARA Gap-4 | Программируемый trust evaluator | Универсальный, не TRI |
| v1.0.0 базовые модули (NF4, Posit16, GF4/16/256, `tri_mant_mul`, sacred opcodes) | Числовые форматы и арифметика | Универсальные, не TRI |

**TRI-специфичные HW блоки в Phi:** нет.

### 1.2 Euler #4915 (8×2, hash `def0457`, artifact `7057525599` 8 816 KB)

| Блок | Назначение | TRI-связь |
|---|---|---|
| e-engine | exp, ln, sigmoid аппроксимации | Универсальные |
| Базовые ZK примитивы | Hash, GF арифметика | Могут использоваться софтом для сборки mining-proof, но без специализированного pipeline |
| Master FSM + dot4/mesh result mux | Контроль | Универсальный |

**TRI-специфичные HW блоки в Euler:** нет. **B5 ZK Job Prover (Groth16-gated mining receipts) — НЕ в Submitted hash**, он в depin-v1 (§2).

### 1.3 Gamma #4913 (8×4, hash `1f8f9b8`, artifact `7057855656` 16 735 KB)

| Блок | Назначение | TRI-связь |
|---|---|---|
| 32-tile нейроморфный mesh | Параллельная инференция | Универсальный |
| Champion BPB lock 2.2393 | Бейзлайн | Универсальный |
| v1.0.0 базовые модули | Те же что в Phi/Euler | Универсальные |

**TRI-специфичные HW блоки в Gamma:** нет. **B7 PoRep (Filecoin storage proof) — НЕ в Submitted hash**, он в depin-v1.

### Итог §1

TTSKY26b кремний = **общее назначение**. Anchor `0x47C0` + PUF + базовая криптография позволяют хост-софту строить TRI mining proofs, но **никакого аппаратного ускорения именно под TRI mining в этом кремнии нет**.

## 2. Что в `depin-v1` ветках — НЕ в кремнии

depin-v1 ветки имеют зелёный gds в GitHub Actions, но **не Submitted**. Лежат для TTSKY26c.

| Чип | depin-v1 HEAD | Модули | TRI-связь |
|---|---|---|---|
| Phi | `08db239c` | B1 Root-of-Trust, B2 Bandwidth Attestation, B8 DID Personhood | B1 = HW-привязанная подпись для miner registration |
| Euler | `05a2ce1f` | B3 RPKI, **B5 ZK Job Prover (Groth16-gated mining receipts)**, B6 GKR sumcheck | **B5 = аппаратный mining receipt accelerator для $TRI** |
| Gamma | `4adde716` | B4 Mesh-8 router, B7 PoRep | B7 = storage-proof для DePIN-стороны экосистемы |

**Самое близкое к "TRI hardware" — B5 Euler ZK Job Prover.** Этот блок специально спроектирован под Groth16-доказательства mining receipt-ов. На silicon он попадёт только в TTSKY26c.

## 3. Что в смарт-контракте (commit `4e3671c`)

| Объект | Адрес / статус |
|---|---|
| TriToken (ERC-20) | predicted `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9` через `vm.computeCreateAddress` — **матч с актуальным** в Foundry dry-run |
| Supply | 7 625 597 484 987 TRI (3²⁷), 18 decimals |
| Pre-mine | 0% |
| Mineable | 100% |
| Halvings | 9 халвингов каждые 4 года |
| Era 0 | 1 000 TRI/proof |
| Networks | Base L2 (планируется) + Bittensor EVM + Solana SPL |
| Deployment status | **Foundry dry-run пройден (7/7 tests)**, на mainnet НЕ deployed. Анвил chain 84532 (Base Sepolia testnet) симулирован, gas estimate 5 364 040 = 0.0107 ETH |

`claimReward` функция контракта проверяет ZK-доказательство mining receipt. **Это доказательство сегодня генерируется софтом** (см. §4). После TTSKY26c — аппаратным B5 в Euler.

## 4. Что в софте — реальный pre-silicon стек

| Репо/файл | TRI-функция | Статус |
|---|---|---|
| [gHashTag/trinity-node](https://github.com/gHashTag/trinity-node) — `src/miner.rs` | `mine_loop()` каждые 12с выпускает SHA-256 proof, комментарий `Era 0 = 1000 TRI/proof` | Mock; CI зелёный |
| [gHashTag/trinity-node](https://github.com/gHashTag/trinity-node) — `src/attestation.rs` | 2-of-3 cross-die signing, anchor `0x47C0` verify | Mock; CI зелёный |
| [gHashTag/trinity-sdk](https://github.com/gHashTag/trinity-sdk) — `trinity/chip.py` | `submit_to_bittensor(subnet=11)` — mock submit attestation | 20/20 pytest |
| [gHashTag/trinity-bittensor](https://github.com/gHashTag/trinity-bittensor) — `conviction_attestor.py` | BIT-0011 attestor: HW-подпись + wallet-подпись + anchor | 12/12 pytest |
| `NeuronConstant/contracts/v2/Deploy.s.sol` | Foundry скрипт deploy TriToken на Base Sepolia | Dry-run OK, не deployed |
| `NeuronConstant/docs/tokenomics/v2/*.md` | 10 файлов tokenomics + Twitter тред | Готовы к публикации post-shuttle |
| `NeuronConstant/docs/business/*.md` | 9 файлов business pack — revenue streams, GTM, valuation comps | Готовы |
| `NeuronConstant/docs/devkit/*.md` | 5 quick-start guides + FPGA emulator guide | Готовы |
| `NeuronConstant/examples/triad_mining_demo/` | Демо mining loop в Python | Скомпилирован, runnable |

**Софт-стек полностью покрывает TRI до момента когда появится физический кремний (2026-12-16 для TTSKY26b).** После tape-out этот же софт будет работать против реального чипа — но **без аппаратного ускорения** до TTSKY26c.

## 5. Цепочка mining — где что происходит

```
[v1.0 TTSKY26b silicon — после tape-out Dec 2026]
        │
        │ PUF read + anchor 0x47C0 + базовая криптография
        ▼
[Хост-софт: trinity-node на CPU]
        │
        │ собирает работу → собирает SHA-256/ZK proof в софте
        │ (медленно: ~секунды на proof в Era 0, без HW)
        ▼
[Смарт-контракт TriToken.claimReward(proof)]
        │
        │ верифицирует Groth16 → emit TRI Era 0 = 1000 TRI/proof
        ▼
[Miner wallet получает TRI]


[v1.1 TTSKY26c silicon — после tape-out Q1 2027 (прогноз)]
        │
        │ PUF + anchor + B5 ZK Job Prover (аппаратный Groth16)
        ▼
[Хост-софт: trinity-node]
        │
        │ B5 выдаёт proof ~миллисекунды (×100-1000 быстрее софта)
        ▼
[Смарт-контракт.claimReward(proof)] → TRI
```

## 6. Резюме для коммуникации

- **"TRI поддержка в кремнии"** — корректное утверждение **только** для TTSKY26c (Q1 2027 silicon, после TTSKY26b → TTSKY26c шаттла Sep–Nov 2026).
- **"TRI можно майнить на TTSKY26b"** — да, через хост-софт + базовая криптография чипа, без HW ускорения. Чип используется для аппаратной идентичности и подписи; основной вычислительный труд proof-генерации — на CPU/GPU хоста.
- **"TRI экосистема готова"** — да на софт-уровне (контракт dry-run OK, daemon/SDK/attestor работают на mock-бэкенде; mainnet deploy TriToken — отдельное решение PI).
- **"TTSKY26b ships без TRI-hardware"** — да, это факт. Но Phi/Euler/Gamma — это публичная привязка Trinity TRI-NET к реальному кремнию через anchor `0x47C0`. Идентичность есть, ускорения mining нет.

## 7. См. также

- [docs/operations/CHANNEL_6_DECISION_BRIEF.md](../operations/CHANNEL_6_DECISION_BRIEF.md) — почему depin-v1 НЕ переподписываем в TTSKY26b
- [docs/architecture/TTSKY26c_UNIFIED_COMPUTER_RTL_ROADMAP.md](../architecture/TTSKY26c_UNIFIED_COMPUTER_RTL_ROADMAP.md) — план HW для TTSKY26c (B5 включён)
- [docs/tokenomics/v2/INDEX.md](v2/INDEX.md) — полный tokenomics пакет
- [docs/business/BUSINESS_MODEL_V1.md](../business/BUSINESS_MODEL_V1.md) — revenue streams (где TRI mining = revenue stream #2)

---

**End.** Sole author: Dmitrii Vasilev `<admin@t27.ai>`. Apache-2.0.
