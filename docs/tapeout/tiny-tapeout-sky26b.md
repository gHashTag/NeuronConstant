# Tiny Tapeout SKY 26b — TRI-1 Triad Submission

**Shuttle:** TTSKY26b (SKY130A)  
**DOI:** [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)

---

## Status

| Item | Value |
|------|-------|
| Shuttle | TTSKY26b |
| Process node | SKY130A (SkyWater 130nm) |
| Shuttle close | **2026-05-18** |
| Chip delivery (est.) | **~2026-12-16** |
| Projects | **3 Assigned** |
| Total tiles consumed | **49/49** (1 + 16 + 32) |
| DevKit boards purchased | **3** |

---

## Project Assignments

| Slot | Project | Tiles | Top Module | Status |
|------|---------|-------|-----------|--------|
| **#4914** | TRI-1 Phi — φ-anchor | 1×1 = 1 tile | `tt_um_trinity_nano` | Assigned ✓ |
| **#4915** | TRI-1 Euler — e-engine | 8×2 = 16 tiles | `tt_um_ghtag_trinity_gf16` | Assigned ✓ |
| **#4913** | TRI-1 Gamma — γ-surface | 8×4 = 32 tiles | `tt_um_trinity_max_true` | Assigned ✓ |

---

## Submission Flow

Each project follows the standard Tiny Tapeout GitHub Actions workflow:

1. **RTL source** — `src/*.v` in each `tt-trinity-*` submission repo
2. **GitHub Actions** — `.github/workflows/gds.yaml` triggers on push to `main`
3. **Artifact** — `tt_submission` artifact contains `gds/`, `lef/`, `pnl/` outputs from OpenLane
4. **Submit revision** — upload to [app.tinytapeout.com](https://app.tinytapeout.com) via "Submit a new revision"
5. **Shuttle lock** — submissions frozen at shuttle close (2026-05-18)

```bash
# Verify submission status
gh run list -R gHashTag/tt-trinity-phi --workflow gds.yaml --limit 3
gh run list -R gHashTag/tt-trinity-euler --workflow gds.yaml --limit 3
gh run list -R gHashTag/tt-trinity-gamma --workflow gds.yaml --limit 3
```

---

## Tile Area Summary (SKY130A)

| Chip | Size | Tile footprint | Area (est.) |
|------|------|----------------|-------------|
| φ-anchor | 1×1 | 160×100 µm | ~0.016 mm² |
| e-engine | 8×2 | 1.28mm × 200 µm | ~0.256 mm² |
| γ-surface | 8×4 | 1.28mm × 400 µm | ~0.512 mm² |

---

## Cross-Die Architecture

The three chips are co-mounted on one DevKit board and communicate via board-level IO mux:

```
φ-anchor  ──(3-wire)──▶  e-engine  ──(D2D)──▶  γ-surface
 #4914                    #4915                   #4913
 MASTER                  COMPUTE                 NEURO
                         SLAVE                   SLAVE
```

Canonical cross-die anchor: `{uio_out, uo_out} = 0x47C0` on all three chips after reset.  
See [docs/interconnect.md](../interconnect.md) for full protocol.

---

## DevKit Board

- **Board:** Tiny Tapeout TTSKY26b DevKit (RP2040 + SPI IO mux + DIP-32 socket)
- **Clock:** 50 MHz shared oscillator → all three CLK pins
- **Reset:** RP2040 GPIO drives all three `rst_n` pins simultaneously
- **IO mux:** 3 dedicated channels (Phi, Euler, Gamma)
- **Handshake wires:** Wire A (LOAD_MODE), Wire B (SYNC_STROBE), Wire C (ACK)

See [`docs/tapeout/packaging.md`](packaging.md) for board layout and socket details.

---

## Notes

- The `tt-trinity-*` submission repos are **thin mirrors** of NeuronConstant tile RTL. Do not make RTL changes directly in them — update NeuronConstant and run `scripts/sync_from_trinity.sh`.
- Submission repos must remain public with the TT `info.yaml` at root.
- CLARA Coq proof count at submission: 297 Qed + 141 Admitted (consolidated 2026-05-12).
