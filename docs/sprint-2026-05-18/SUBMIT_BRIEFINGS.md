# TT SKY26b Submit Briefings — for generals's hands-on submit pass

Use these blocks on app.tinytapeout.com if the form asks for tagline / abstract / citation. Otherwise just verify and click **Submit**. The submission packet is already built from info.yaml + docs/info.md inside the GitHub artifact — most fields are auto-pulled.

---

## Project #4914 — TRI-1 Phi (phi-anchor)

**URL:** https://app.tinytapeout.com/projects/4914
**Repo:** [gHashTag/tt-trinity-phi](https://github.com/gHashTag/tt-trinity-phi)
**Commit:** `8a8fcaa477171d24654f590137cefe86b3e62a3d`
**Tier:** 1×1 single-cell (smallest SKU)
**Top module:** `tt_um_trinity_nano`
**Artifact:** `7056162644` (gds workflow, 1.05 MB tt_submission)

### Tagline (≤120 chars)
> Trinity φ-anchor — 1×1 Lucas POST proving φ²+φ⁻²=3 on power-up, canonical seed 0x47C0 (TG-TRIAD-X Theorem 36.1).

### One-line abstract
> Smallest of three TRI-1 SKUs. On reset drives canonical dot4(1.0,2.0,3.0,4.0)=0x47C0 directly onto {uio_out,uo_out}, matching e-engine (#4915) and γ-surface (#4913) — the cross-die anchor for the Trinity ledger. R-SI-1 verified, 66 numeric formats, sacred opcodes, CLARA Gap-4 restraint.

### Citation

---

## Project #4915 — TRI-1 Euler (e-engine)

**URL:** https://app.tinytapeout.com/projects/4915
**Repo:** [gHashTag/tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler)
**Commit:** `def0457b158e698cdfc4b6fd9aceda0e624dd95f`
**Tier:** 8×2 (16 GF16 cells + SUPER-CROWN + 10 CLARA Gaps)
**Top module:** `tt_um_ghtag_trinity_gf16`
**Artifact:** pending gds completion (~5-15 min)

### Tagline (≤120 chars)
> Trinity e-engine — 8×2 SUPER-CROWN SoC: 16 GF16 cells, BitNet b1.58 encoder, ALU-9 t27 ISA, 10 DARPA CLARA AI-safety gaps.

### One-line abstract
> Mid-tier brain SKU. 18 SUPER-CROWN modules (BLAKE3 anchor, VSA matmul 8×8 & 16×16, BitNet encoder, BPB counter, ALU-9 decoder, RING27 memory, φ-PLL, Wishbone-full) + 10 DARPA CLARA gaps (redteam_filter, K3 ALU, Datalog, restraint_ctrl, explainability, ASP solver, composition kernel, proof-trace, SAT, audit ring buffer) + D2D 4-port holo mesh. 0 DSP / 0 new `*` in synth RTL (R-SI-1). FPGA-validated 323 MHz @ XC7A100T.

### Citation

---

## Project #4913 — TRI-1 Gamma (γ-surface)

**URL:** https://app.tinytapeout.com/projects/4913
**Repo:** [gHashTag/tt-trinity-gamma](https://github.com/gHashTag/tt-trinity-gamma)
**Commit:** `1f8f9b82951331db62a909b0abb1175ce161b991`
**Tier:** 8×4 (MAX-TRUE NEUROMORPHIC FLAGSHIP, 32 tiles)
**Top module:** `tt_um_trinity_max_true`
**Artifact:** pending gds completion (~5-15 min)

### Tagline (≤120 chars)
> Trinity γ-surface — MAX-TRUE NEUROMORPHIC 32-tile: 8 cortical columns (LIF+BitNet), 20-PE GF16 mesh, 24 SUPER-CROWN + 10 CLARA gaps.

### One-line abstract
> Largest brain SKU. 8 cortical columns (~4100 LIF cells) + 20-PE GF16 mesh + 24 SUPER-CROWN modules + 6 PhD-anchored monitors (Cassini POST, PLRM, BPB lower-bound guard, NCA entropy, strobe-seed guard, φ-distance oracle) + 10 CLARA AI-safety gaps + D2D 4-port holo mesh + FHRR holo_lut_pe VSA binding (Glava 32) + S-13 dual-lib zoning (hd primary + hdll low-leakage on POST chains). TG-TRIAD-X canonical anchor 0x47C0 on {uio_out, uo_out} at reset.

### Citation

---

## Common across all 3

- **Anchor invariant:** φ² + φ⁻² = 3 → canonical 0x47C0 at reset (Theorem 36.1)
- **Champion lock:** BPB=2.2393 @ step=27000 seed=43 sha=`2446855`
- **R-SI-1:** zero standalone `*` in synth RTL across all 3 tiers (CI workflow `R-SI-1 no-star check` passes)
- **66 numeric formats:** NF4/NF8, Posit16/32/64, MXFP4/6/8 OCP, LNS8, GF4-256, Unum I/II, IBM HFP, VAX F/D/G/H, Cray HRM, decimal32/64/128, Q15/Q31, stoch_round
- **Toolchain:** Yosys/openXC7/OpenLane (all open-source)
- **License:** Apache-2.0 (RTL), MIT (Solidity bridges)
- **Companion repos:** [NeuronConstant](https://github.com/gHashTag/NeuronConstant), [trinity-clara](https://github.com/gHashTag/trinity-clara) (DARPA CLARA submission package)

---

## Pre-submit check (do this **before** clicking Submit on each project)

For each of #4914, #4915, #4913:

1. ☐ Page loads, shows latest commit (check 7-char SHA matches above)
2. ☐ GDS Action shows ✅ green
3. ☐ Documentation Action shows ✅ green
4. ☐ 3D viewer renders correctly (no missing area)
5. ☐ Pinout table populated (8 ui + 8 uo + 8 uio)
6. ☐ tt_submission artifact attached and ≥500 KB
7. ☐ Then click **Submit to TTSKY26b**

---

## Post-submit verification

After all 3 are submitted:

```bash
# Verify the tinytapeout shuttle index has all 3
curl -s https://app.tinytapeout.com/api/shuttles/ttsky26b/projects | jq '.[] | select(.author=="ghashtag" or .author=="Dmitrii Vasilev")'
```

Or just refresh each project page — status should change from `Assigned` → `Submitted` / `Merged`.

---

## Git tag commands (after all 3 confirmed Submitted)

```bash
# Tag each tape-out repo at the exact submitted commit
for R in phi euler gamma; do
  git -C /tmp/$R-final tag -a tt-sky26b-final -m "TT SKY26b shuttle final submit — TRI-1 Triad ($R tier)"
  git -C /tmp/$R-final push origin tt-sky26b-final
done

# Tag NeuronConstant at locked state
git -C /tmp/nc-depin tag -a tt-sky26b-final -m "NeuronConstant locked at TT SKY26b submit — champion BPB=2.2393 sha=2446855"
git -C /tmp/nc-depin push origin tt-sky26b-final

# Tag trinity-clara at addendum
git -C /tmp/trinity-clara tag -a tt-sky26b-final -m "CLARA addendum locked at TT SKY26b submit — 12 unique moats, 66 formats"
git -C /tmp/trinity-clara push origin tt-sky26b-final
```

---

## Zenodo DOI update (after tags pushed)

DOI: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

Update record description with:
- Final SHAs: phi `8a8fcaa`, euler `def0457`, gamma `1f8f9b8`, NeuronConstant `15bffba`, trinity-clara `f86e32f`
- Submitted artifact IDs: phi `7056162644`, euler `<TBD>`, gamma `<TBD>`
- Submit timestamp
