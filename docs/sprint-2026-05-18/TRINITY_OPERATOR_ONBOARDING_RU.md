# Trinity Node — Онбординг оператора

> **Версия:** 0.9-testnet · **Дата:** июнь 2026  
> **Сеть:** Trinity DePIN testnet · **Mainnet:** Q4 2026  
> **Репозитории:** [gHashTag/tt-trinity-phi](https://github.com/gHashTag/tt-trinity-phi) · [gHashTag/tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler) · [gHashTag/tt-trinity-gamma](https://github.com/gHashTag/tt-trinity-gamma)  
> **Провенанс:** [DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

---

## 1. Что такое Trinity Node

Trinity — децентрализованная сеть **verifiable AI inference** на open-кремнии. В отличие от proof-of-work (где майнеры сжигают электричество на бессмысленные хеши), Trinity использует **Proof-of-Useful-Work (PoUW)**: ты зарабатываешь токены $TRI за то, что твой чип реально делает полезную работу — ternary AI inference, криптографические аттестации, маршрутизацию пакетов.

Физическим вычислителем служит **SKY26b die** — чип, изготовленный на реальном кремниевом процессе SkyWater 130 nm через открытый шаттл [Tiny Tapeout TTSKY26b](https://efabless.com/). Каждый чип несёт аппаратный идентификатор **PUF (Physically Unclonable Function)** и якорный регистр `0x47C0` — детерминированное доказательство подлинности, описанное в [Теореме 36.1 / TG-TRIAD-X](https://doi.org/10.5281/zenodo.19227877). Сфабриковать его программно нельзя.

Сеть состоит из трёх типов чипов (SKU):
| SKU | Модуль | Тайлов | Роль |
|-----|--------|--------|------|
| **Phi** (φ-anchor) | `tt_um_trinity_nano` | 1×1 | POST seed, Lucas chain, CLARA Gap-4 |
| **Euler** (e-engine) | `tt_um_ghtag_trinity_gf16` | 8×2 | Ternary MLP inference, BLAKE3 signer |
| **Gamma** (γ-surface) | `tt_um_trinity_max_true` | 8×4 | Neuromorphic mesh, D2D роутер |

Ты можешь запустить ноду на одном Phi-чипе или собрать **Triad** (Phi + Euler + Gamma) для максимального вознаграждения.

---

## 2. Что нужно купить (BOM ~$213)

| Компонент | Где купить | Цена (USD) | Обязателен |
|-----------|-----------|-----------|------------|
| **TT06+ demo board** (TTSKY26b DevKit, efabless) | [efabless.com/shuttle-program](https://efabless.com/shuttle-program) | $135 | ✅ да |
| **Raspberry Pi 5** (4 GB) | [raspberrypi.com](https://www.raspberrypi.com/products/raspberry-pi-5/) | $60 | ✅ да |
| **USB-C PSU 5V/3A** (официальный RPi или аналог) | [raspberrypi.com/products/27w-power-supply](https://www.raspberrypi.com/products/27w-power-supply/) | $10 | ✅ да |
| **SD-карта 32 GB** (Class 10 / A1) | [amazon.com/dp/B06XWN9Q99](https://www.amazon.com/dp/B06XWN9Q99) | $8 | ✅ да |
| **Акриловый корпус** для RPi5 | [amazon.com/s?k=raspberry+pi+5+case](https://www.amazon.com/s?k=raspberry+pi+5+case) | $15 | ☑ опционально |

**Итого: ~$213** (без корпуса: ~$198)

> **Примечание.** SKY26b чипы (Phi/Euler/Gamma) поставляются **вместе с DevKit** — покупать их отдельно не нужно. Уточняй доступность на [efabless.com](https://efabless.com/) — первый шаттл TTSKY26b выходит в Q4 2026.

---

## 3. Подготовка железа

### 3.1 Прошивка Raspberry Pi OS

Скачай **Raspberry Pi Imager** с [raspberrypi.com/software](https://www.raspberrypi.com/software/) и прошей на SD-карту:

- ОС: **Raspberry Pi OS Lite 64-bit** (Bookworm)
- Включи SSH в настройках Imager
- Задай hostname: `trinity-node`, логин/пароль по желанию

Вставь SD в RPi5, **не включай питание** до завершения подключения к DevKit.

---

### 3.2 Подключение RPi5 к TT06+ DevKit (40-pin GPIO)

Соединяй DevKit с RPi5 **без питания**. Используй 40-pin GPIO-шлейф (FFC или Dupont, поставляется с DevKit):

```
RPi5 GPIO Header (40-pin)          TT06+ DevKit GPIO Connector
─────────────────────────          ────────────────────────────
Pin 1   (3.3V)         ──────────► 3.3V rail
Pin 2   (5V)           ──────────► 5V rail  (DevKit питается от RPi)
Pin 3   (SDA / GPIO2)  ──────────► SDA (I2C data)
Pin 5   (SCL / GPIO3)  ──────────► SCL (I2C clock)
Pin 19  (MOSI / GPIO10)──────────► SPI MOSI
Pin 21  (MISO / GPIO9) ──────────► SPI MISO
Pin 23  (SCLK / GPIO11)──────────► SPI SCLK
Pin 24  (CE0 / GPIO8)  ──────────► SPI CS0  (Phi)
Pin 26  (CE1 / GPIO7)  ──────────► SPI CS1  (Euler)
Pin 32  (GPIO12)       ──────────► SPI CS2  (Gamma)
Pin 6, 9, 14, 20, 25   ──────────► GND (общая земля)
```

> Полный pinout каждого die — в репозиториях:
> - [Phi pinout](https://github.com/gHashTag/tt-trinity-phi/blob/main/docs/PINOUT.md)
> - [Euler pinout](https://github.com/gHashTag/tt-trinity-euler/blob/main/docs/PINOUT.md)
> - [Gamma pinout](https://github.com/gHashTag/tt-trinity-gamma/blob/main/docs/PINOUT.md)

**Сигнал `rst_n`** (активный низкий) подаётся с GPIO17 RPi. После старта нода держит reset до инициализации стека.

---

### 3.3 Установка SKY26b TT-trinity die в DevKit сокет

1. Убедись, что питание отключено.
2. Вставь **TT-Phi tile** в слот #4914 DevKit (Tiny Tapeout MUXED socket).
3. Если у тебя Triad-комплект: Euler → слот #4915, Gamma → слот #4913.
4. Зафиксируй зажимы сокета. Keine rohe Gewalt — усилие минимально.
5. После подачи питания 7-сегментный дисплей DevKit должен показать `47C0` — это аппаратное подтверждение, что чип жив (канонический якорь `0x47C0`, Theorem 36.1).

---

### 3.4 Питание и загрузка

1. Подключи USB-C PSU к RPi5.
2. RPi5 питает DevKit через GPIO (5V, pin 2).
3. Подожди ~30 секунд — RPi загружается, `trinity-node` hostname доступен по SSH.
4. Если дисплей DevKit НЕ показывает `47C0` после загрузки ноды → см. Раздел 10 (Troubleshooting).

---

## 4. Установка софта

Подключись к RPi по SSH и выполни по очереди:

```bash
# 1. Обнови систему
sudo apt update && sudo apt upgrade -y

# 2. Установи Trinity Operator Stack
#    ⚠️  URL — заглушка. Реальный инсталлятор появится на mainnet launch Q4 2026.
#    Следи за анонсами: https://github.com/gHashTag/tt-trinity-phi/discussions
curl -sSf https://trinity.depin.dev/install.sh | sh

# 3. Включи автозапуск сервиса
sudo systemctl enable trinity-operator
sudo systemctl start trinity-operator

# 4. Проверь статус ноды
trinity-cli status
```

Ожидаемый вывод `trinity-cli status`:

```
Trinity Operator Node v0.9-testnet
Die(s) detected : phi [slot=4914, anchor=0x47C0 ✓]
Network         : testnet
Wallet          : (not set — run `trinity-cli wallet init`)
Uptime          : 0h 0m
Attestations    : 0
$TRI earned     : 0.000
```

---

## 5. Регистрация в сети

### 5.1 Создай кошелёк

```bash
trinity-cli wallet init
# → Генерирует seed-фразу (12 слов). Запиши офлайн — восстановить нельзя.
# → Выводит адрес: tri1qxxxxxxxxxxxxxxxxxx
```

### 5.2 Получи testnet $TRI

Перейди в Discord-канал **#testnet-faucet** (ссылка в Разделе 12) или воспользуйся кран-ботом:

```bash
trinity-cli faucet --address $(trinity-cli wallet address)
# Кран выдаёт 200 $TRI для тестнета
```

### 5.3 Стэйк Operator Bond (минимум 100 $TRI)

Operator bond — залог за честное поведение. Без него нода не принимает задачи.

```bash
trinity-cli stake --amount 100
# Транзакция в тестнет-блокчейн, подтверждение ~30 сек
```

### 5.4 Привяжи die-PUF к кошельку

PUF (Physically Unclonable Function) — аппаратный отпечаток чипа. Без привязки сеть не принимает аттестации от твоей ноды.

```bash
trinity-cli attach-die --slot phi
# Читает PUF-nonce с чипа через SPI, подписывает кошельком, регистрирует в сети

# Для Triad — повтори для каждого чипа:
trinity-cli attach-die --slot euler
trinity-cli attach-die --slot gamma
```

Ожидаемый вывод:

```
[PHI] PUF nonce : 0xA3F192...8C4E
[PHI] Anchor    : 0x47C0 ✓
[PHI] Registered: tx=0x7f3a...b291 (testnet)
```

---

## 6. Первая аттестация

Запусти тестовую инференс-аттестацию:

```bash
trinity-cli attest --type=inference --model=phi-1.5b
```

Ожидаемый вывод:

```
[ATTEST] model=phi-1.5b  die=phi  slot=4914
[ATTEST] Lucas POST      : PASS  seed=0x47C0
[ATTEST] CLARA Gap-4     : PASS  (bounded rationality)
[ATTEST] Compute receipt :
  {
    "job_id"    : "0x9f2c...a841",
    "die_puf"   : "0xA3F1...8C4E",
    "anchor"    : "0x47C0",
    "model"     : "phi-1.5b",
    "tokens_in" : 128,
    "tokens_out": 64,
    "latency_ms": 412,
    "receipt_sig": "0x4e2b...c9f0"
  }
[ATTEST] Anchor signer   : 0x47C0 ✓  (Theorem 36.1, TG-TRIAD-X)
[ATTEST] Submitted to testnet: receipt accepted
```

Receipt содержит подпись якоря `0x47C0` — это аппаратное доказательство, что вычисление выполнено реальным чипом, а не эмулятором.

---

## 7. Мониторинг

### Grafana Dashboard

```
http://<IP-твоей-ноды>:3000
# Логин: trinity / trinity  (измени после первого входа)
```

> ⚠️ Внешний Grafana Cloud dashboard — заглушка. URL появится на mainnet launch Q4 2026.  
> Следи: [github.com/gHashTag/tt-trinity-phi/discussions](https://github.com/gHashTag/tt-trinity-phi/discussions)

### Метрики

| Метрика | Значение | Где смотреть |
|---------|----------|-------------|
| `uptime` | % аптайма ноды | Grafana → Overview |
| `attestations_per_hour` | Скорость работы | Grafana → Performance |
| `tri_earned_total` | Накопленные $TRI | `trinity-cli status` |
| `slashing_events` | Штрафные события | Grafana → Slashing |
| `die_anchor_ok` | Якорь 0x47C0 ✓/✗ | `trinity-cli status` |

### CLI-мониторинг

```bash
# Статус в реальном времени (обновление каждые 5 сек)
watch -n 5 trinity-cli status

# Лог событий
journalctl -u trinity-operator -f

# Статистика за последние 24 ч
trinity-cli stats --period=24h
```

---

## 8. Что зарабатывает оператор

> **⚠️ Все цифры предварительные (preliminary), subject to mainnet economics. Mainnet Q4 2026.**

| Конфигурация | $TRI/день (testnet) | USD-экв. (preliminary) | Бонус |
|-------------|---------------------|------------------------|-------|
| 1× Phi (1×1) | ~10 $TRI | ~$0.50 | — |
| 1× Euler (8×2) | ~18 $TRI | ~$0.90 | — |
| 1× Gamma (8×4) | ~25 $TRI | ~$1.25 | — |
| **Triad** (Phi+Euler+Gamma) | **~35 $TRI** | **~$1.75** | **+17% триадный бонус** |

Триадный бонус (+17%) начисляется, когда все три die подтверждают совместный консенсус через якорь `0x47C0`. Реализация — в спеке [`TRI_TOKEN_ACCUMULATOR_SPEC.md`](https://github.com/gHashTag/tt-trinity-phi/blob/main/docs/TRI_TOKEN_ACCUMULATOR_SPEC.md):
- Phi: `reward_amount = 1` токен за аттестацию
- Euler: `reward_amount = 2`
- Gamma: `reward_amount = 4`

**Не жди обогащения.** Цель сети — честная оплата реальной вычислительной работы. Токеномика финализируется перед mainnet.

---

## 9. Slashing — за что наказывают

Слэшинг снимает часть твоего operator bond (стэйка). Источник: [Trinity Tokenomics Whitepaper](https://doi.org/10.5281/zenodo.19227877).

| Нарушение | Штраф от bond | Описание |
|-----------|--------------|----------|
| **Invalid attestation** | −10% | Receipt с неверной подписью или несоответствием якоря |
| **Double-sign** | −50% | Две разные аттестации одного job_id с одного PUF |
| **R-SI-1 violation** | −100% | Нода отправила синтезируемый код с оператором `*` (запрещено) |
| **Offline > 24h** | −5% | Нода недоступна сверх grace period |
| **PUF mismatch** | −100% | PUF-nonce не совпадает с зарегистрированным (подозрение на подмену чипа) |

> R-SI-1 — правило проекта Trinity: в синтезируемом RTL запрещены стандартные операторы `*`. Всё умножение — через GF16 LUT-примитивы. Подробнее: [CLARA TRIAD Manifest](https://github.com/gHashTag/tt-trinity-phi/blob/main/docs/CLARA_TRIAD_MANIFEST.md).

После слэшинга пополни bond до минимума (100 $TRI), иначе нода переходит в `SUSPENDED`.

---

## 10. Troubleshooting

### SKY26b die не отвечает (дисплей не показывает `47C0`)

```bash
# Проверь SPI-соединение
trinity-cli diag --slot phi

# Если ошибка "SPI timeout" — проверь GPIO-шлейф, пин CE0
# Перепрошей SPI-конфиг:
trinity-cli flash-spi --slot phi

# Проверь питание: DevKit должен получать 5V через GPIO pin 2
# Измерь напряжение мультиметром между pin 2 и GND (pin 6)
```

### Attestation rejected: "clock skew"

```bash
# Синхронизируй время через NTP
sudo timedatectl set-ntp true
sudo timedatectl status
# Должно быть: "System clock synchronized: yes"

# Если не помогло — принудительная синхронизация:
sudo chronyc makestep
```

### PUF unstable (флуктуирующий nonce между перезагрузками)

Die дефектный. Аппаратный PUF должен быть детерминированным.

```bash
# Проверь стабильность PUF (10 чтений подряд):
trinity-cli puf-test --slot phi --iterations 10
```

Если nonce меняется — обратись в **efabless RMA** ([efabless.com/contact](https://efabless.com/contact)), указав:
- Номер заказа DevKit
- Вывод `trinity-cli diag --slot phi`
- Симптомы

### Нода зависает после старта

```bash
# Посмотри логи:
journalctl -u trinity-operator --no-pager -n 50

# Перезапусти сервис:
sudo systemctl restart trinity-operator
```

### `trinity-cli: command not found`

```bash
# Добавь путь в .bashrc:
echo 'export PATH="$HOME/.trinity/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## 11. FAQ

**Q: Можно запустить ноду на VPS (облаке)?**  
A: Нет. Trinity Node требует физический SKY26b die. Аппаратный PUF невозможно эмулировать — сеть верифицирует подпись чипа по якорю `0x47C0`. VPS-ноды будут отклонены при регистрации.

**Q: Сколько потребляет электричества?**  
A: RPi5 + DevKit + 1 die ≈ **5 Вт**. Triad (3 die) ≈ **7–8 Вт**. За год ~44–70 кВт·ч — при тарифе $0.10/кВт·ч это ~$4–7/год.

**Q: Нужен ли whitelist для участия?**  
A: Testnet — **да**, whitelist. Заяву подай через Discord (Раздел 12). Mainnet — **нет**, permissionless.

**Q: Opus правда соавтор проекта?**  
A: Да. Claude Opus (Anthropic) внёс вклад в RTL через генерацию и ревью Verilog-кода начиная с v1.0.0. Это задокументировано в CHANGELOG и Zenodo-архиве ([DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)).

**Q: Что такое якорь `0x47C0` и почему это важно?**  
A: `0x47C0` = `dot4(1,2,3,4)` в GF16 — детерминированный результат после сброса. Это аппаратная подпись аутентичности die, описанная в [Theorem 36.1 / TG-TRIAD-X](https://doi.org/10.5281/zenodo.19227877). Если чип выдаёт другое значение — он неисправен или подменён.

**Q: Можно подключить больше 3 die?**  
A: Текущий протокол поддерживает Triad (1 Phi + 1 Euler + 1 Gamma). Поддержка нескольких Triad на одной ноде — в roadmap.

**Q: Когда mainnet и реальная цена $TRI?**  
A: **Q4 2026**. Все текущие цифры preliminary. Не инвестируй на основе testnet-статистики.

**Q: Как обновлять ПО ноды?**  
A: 
```bash
trinity-cli self-update
sudo systemctl restart trinity-operator
```
Критические обновления приходят в Discord-канал **#operator-alerts**.

**Q: Что такое CLARA Gap-4 и зачем это мне?**  
A: CLARA Gap-4 — аппаратный bounded rationality контроллер на чипе Phi. Он гарантирует, что AI-агент на чипе принимает решения за полиномиальное время и не выходит за пределы допустимого. Ты как оператор не управляешь этим напрямую — это часть верификации, за которую получаешь reward.

**Q: Можно ли использовать другие девборды (не официальный DevKit)?**  
A: Только при условии совместимости с TT06+ socket и соблюдении pinout. Неофициальные платы не гарантируют стабильного SPI/I2C и могут давать spurious PUF. Рекомендуется официальный DevKit от [efabless](https://efabless.com/).

---

## 12. Сообщество

| Канал | Ссылка | Что там |
|-------|--------|---------|
| **GitHub Discussions (Phi)** | [gHashTag/tt-trinity-phi/discussions](https://github.com/gHashTag/tt-trinity-phi/discussions) | Технические вопросы, roadmap |
| **GitHub Discussions (Euler)** | [gHashTag/tt-trinity-euler/discussions](https://github.com/gHashTag/tt-trinity-euler/discussions) | Inference, CLARA gaps |
| **GitHub Discussions (Gamma)** | [gHashTag/tt-trinity-gamma/discussions](https://github.com/gHashTag/tt-trinity-gamma/discussions) | Neuromorphic, D2D mesh |
| **Discord** | Ссылка в [tt-trinity-phi README](https://github.com/gHashTag/tt-trinity-phi) | Оперативная помощь, #testnet-faucet |
| **Telegram** | Ссылка в [tt-trinity-phi README](https://github.com/gHashTag/tt-trinity-phi) | Русскоязычные операторы |
| **Issues (баги)** | [github.com/gHashTag/tt-trinity-phi/issues](https://github.com/gHashTag/tt-trinity-phi/issues) | Bug reports, RFCs |

Разработчики: **gHashTag** (Dmitrii Vasilev) и **NeuronConstant**.  
Задавай вопросы смело — сообщество маленькое и отвечает быстро.

---

## 13. Что дальше

| Ресурс | Ссылка |
|--------|--------|
| **$TRI Tokenomics Whitepaper** | [DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) |
| **TG-TRIAD-X Theorems (Theorem 36.1)** | [DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) |
| **Repo: tt-trinity-phi** (φ-anchor, 1×1) | [github.com/gHashTag/tt-trinity-phi](https://github.com/gHashTag/tt-trinity-phi) |
| **Repo: tt-trinity-euler** (e-engine, 8×2) | [github.com/gHashTag/tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler) |
| **Repo: tt-trinity-gamma** (γ-surface, 8×4) | [github.com/gHashTag/tt-trinity-gamma](https://github.com/gHashTag/tt-trinity-gamma) |
| **CLARA formal proofs (Coq)** | [github.com/gHashTag/trinity-clara](https://github.com/gHashTag/trinity-clara) |
| **CLARA TRIAD Manifest** | [tt-trinity-phi/docs/CLARA_TRIAD_MANIFEST.md](https://github.com/gHashTag/tt-trinity-phi/blob/main/docs/CLARA_TRIAD_MANIFEST.md) |
| **Cross-Tile Interconnect Spec** | [tt-trinity-phi/docs/CROSS_TILE_INTERCONNECT.md](https://github.com/gHashTag/tt-trinity-phi/blob/main/docs/CROSS_TILE_INTERCONNECT.md) |
| **$TRI Token Accumulator Spec** | [tt-trinity-phi/docs/TRI_TOKEN_ACCUMULATOR_SPEC.md](https://github.com/gHashTag/tt-trinity-phi/blob/main/docs/TRI_TOKEN_ACCUMULATOR_SPEC.md) |
| **Efabless Shuttle Program** | [efabless.com/shuttle-program](https://efabless.com/shuttle-program) |
| **Tiny Tapeout** | [tinytapeout.com](https://tinytapeout.com) |

---

*Trinity DePIN testnet — честная сеть для разработчиков. Mainnet Q4 2026. Все экономические параметры preliminary.*
