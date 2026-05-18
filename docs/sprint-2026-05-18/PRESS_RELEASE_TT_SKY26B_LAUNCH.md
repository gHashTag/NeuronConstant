# PRESS RELEASE

**FOR IMMEDIATE RELEASE**
May 18, 2026, 23:59 UTC

---

## Trinity Triad: First Open-Silicon Verifiable AI Inference Accelerator Tapes Out on Tiny Tapeout SKY26b

**Cape Town, South Africa** — Trinity Triad, a cluster of three open-source silicon dies implementing hardware-anchored verifiable AI inference primitives, has been submitted to the Tiny Tapeout SKY26b shuttle (TTSKY26B) ahead of tonight's 23:59 UTC deadline. The submission marks the first formally specified, R-SI-1 compliant, hardware-attested AI inference accelerator on 130nm SkyWater open-process silicon.

The three dies — **phi** (`tt_um_trinity_nano`, 1×1 tile), **euler** (`tt_um_ghtag_trinity_gf16`, 8×2 tiles), and **gamma** (`tt_um_trinity_max_true`, 8×4 tiles) — implement a progressive stack of AI format modules: NF4 quantization, Posit16 arithmetic, GF4/GF16/GF256 Galois field accelerators, a tri-mantissa multiplier (`tri_mant_mul`), and a set of "sacred opcodes" for canonical inference attestation. All source code is open-source and published on GitHub under [gHashTag/tt-trinity-phi](https://github.com/gHashTag/tt-trinity-phi), [gHashTag/tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler), and [gHashTag/tt-trinity-gamma](https://github.com/gHashTag/tt-trinity-gamma). A Zenodo archival snapshot is available at [DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877).

**Hardware-Anchored Attestation**

The distinguishing feature of the Trinity Triad is a canonical hardware anchor: address `0x47C0`, hardwired across all three dies and formally established by Theorem 36.1 (TG-TRIAD-X) in the project's published specification corpus. Unlike software attestation schemes that rely on trusted execution environments or remote certificates, the anchor is a physical, immutable constant on each fabricated die — refreshable at up to 200 kHz with a design-wide power envelope of 5W.

"We treat the silicon as a notary, not a computer," said **Dmitrii Vasilev**, principal investigator and project lead, based in Cape Town, South Africa. "The goal is not maximum FLOPS. The goal is a cryptographic root of trust that is auditable at the mask level, reproducible by any fab with the right PDK, and compliant with emerging AI accountability frameworks from day one."


All three designs pass the R-SI-1 synthesis audit rule: zero standalone `*` (unqualified wildcard multiply) operations appear in the synthesis netlist. The v1.0.0 AI format modules — including the GF field accelerators and `tri_mant_mul` — were by Dmitrii Vasilev (sole author, admin@t27.ai) , establishing a novel precedent for human-AI collaborative silicon design under open license.

*[QUOTE PLACEHOLDER — Matt Venn, Tiny Tapeout founder: TBD]*


**Why It Matters**

The EU AI Act (effective August 2026) and U.S. Executive Order 14110 impose logging and auditability requirements on AI systems that current cloud infrastructure cannot satisfy with hardware-level proof. DARPA's CLARA program (Cryptographic Log and Attestation for Reasoning Agents) — to which a related proposal was submitted April 17, 2026 — identifies the same gap. In the DePIN (Decentralized Physical Infrastructure Network) sector, existing networks such as Bittensor lack any hardware root of trust; Helium's proof-of-coverage is known to be gameable. Trinity Triad is designed to close that gap with open, auditable silicon.

**Availability**

Fabricated dies from the TT SKY26b shuttle are expected to ship to backers in Q4 2026. The Trinity Node developer kit — a $200 board integrating all three dies — is targeted for Q1 2027. Enterprise licensing and AI Act compliance SaaS are under development.

**Contact**

GitHub Discussions: [gHashTag/NeuronConstant](https://github.com/gHashTag/NeuronConstant)
Zenodo archive: [DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

---

### About Trinity Triad


---
---

# ПРЕСС-РЕЛИЗ

**ДЛЯ НЕМЕДЛЕННОГО РАСПРОСТРАНЕНИЯ**
18 мая 2026 г., 23:59 UTC

---

## Trinity Triad: первый верифицируемый AI-акселератор на открытом кремнии выходит на производство в рамках шаттла Tiny Tapeout SKY26b

**Кейптаун, Южная Африка** — Trinity Triad, комплект из трёх открытых кремниевых кристаллов для аппаратно-заверенного ИИ-инференса, подан на шаттл Tiny Tapeout SKY26b (TTSKY26B) до дедлайна 23:59 UTC сегодняшней ночью. Это первый формально специфицированный, R-SI-1-совместимый, аппаратно-заверенный AI-акселератор инференса на 130-нм кремнии открытого процесса SkyWater.

Три кристалла — **phi** (`tt_um_trinity_nano`, тайл 1×1), **euler** (`tt_um_ghtag_trinity_gf16`, 8×2 тайла), и **gamma** (`tt_um_trinity_max_true`, 8×4 тайла) — реализуют прогрессивный стек AI-модулей: квантование NF4, арифметику Posit16, ускорители поля Галуа GF4/GF16/GF256, умножитель три-мантиссы (`tri_mant_mul`) и набор «священных опкодов» для канонической аттестации инференса. Весь исходный код открыт и опубликован на GitHub: [gHashTag/tt-trinity-phi](https://github.com/gHashTag/tt-trinity-phi), [gHashTag/tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler), [gHashTag/tt-trinity-gamma](https://github.com/gHashTag/tt-trinity-gamma). Архивная копия размещена на Zenodo: [DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877).

**Аппаратная аттестация**

Ключевая особенность Trinity Triad — канонический аппаратный якорь: адрес `0x47C0`, жёстко зашитый во все три кристалла и формально установленный Теоремой 36.1 (TG-TRIAD-X) в опубликованном корпусе технических спецификаций. В отличие от программных схем аттестации, основанных на доверенных средах исполнения или удалённых сертификатах, якорь является физической, неизменяемой константой на каждом изготовленном кристалле — с возможностью обновления до 200 кГц при суммарном энергопотреблении конструкции 5 Вт.

«Мы рассматриваем кремний как нотариуса, а не как вычислитель», — заявил **Дмитрий Васильев**, ведущий исследователь и руководитель проекта, работающий в Кейптауне. «Цель не в максимальном числе FLOPS. Цель — криптографический корень доверия, проверяемый на уровне маски, воспроизводимый любой фабрикой с нужным PDK и изначально соответствующий формирующимся нормам ответственного ИИ.»

**Соответствие R-SI-1 и соавторство с ИИ**


*[МЕСТО ДЛЯ ЦИТАТЫ — Мэтт Венн, основатель Tiny Tapeout: уточняется]*


**Почему это важно**

Регламент ЕС об ИИ (вступает в силу в августе 2026 г.) и Исполнительный указ США 14110 устанавливают требования к журналированию и аудируемости AI-систем, которые современная облачная инфраструктура не может выполнить на аппаратном уровне. Программа DARPA CLARA (криптографическое журналирование и аттестация агентов рассуждения), в которую была подана связанная заявка 17 апреля 2026 г., фиксирует тот же пробел. В секторе DePIN (децентрализованные сети физической инфраструктуры) существующие сети — Bittensor — лишены аппаратного корня доверия; доказательство покрытия Helium известно своей уязвимостью к фальсификации. Trinity Triad разработан для устранения этого пробела с помощью открытого, аудируемого кремния.

**Доступность**

Изготовленные кристаллы с шаттла TT SKY26b планируется поставить бекерам в четвёртом квартале 2026 г. Комплект разработчика Trinity Node — плата за $200, объединяющая все три кристалла — запланирован на первый квартал 2027 г. Корпоративное лицензирование и SaaS-решение для соответствия Акту ЕС об ИИ находятся в разработке.

**Контакт**

GitHub Discussions: [gHashTag/NeuronConstant](https://github.com/gHashTag/NeuronConstant)
Zenodo-архив: [DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

---

### О Trinity Triad


---

*###*
