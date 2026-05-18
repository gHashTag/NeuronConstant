---
Author: Dmitrii Vasilev <admin@t27.ai>
License: Apache-2.0
Status: pre-silicon (tape-out target 2026-12-16)
---

# FPGA Emulator Guide — Xilinx Kria K26 (Pre-Silicon Dev)

## Overview

This guide covers bit-accurate emulation of the **Trinity ternary inference engine** on a
Xilinx Kria K26 SOM before the December 2026 ASIC tape-out.  The goal is to validate RTL
correctness, measure latency under realistic workloads, and confirm the anchor value
`0x47C0` is stable across all Trinity tile configurations.

Performance target: **~1 GOPS @ ~50 MHz @ ~1 W ternary (projected, pending tape-out 2026-12-16)**.
FPGA emulation runs at reduced clock (~25 MHz) due to K26 fabric limits; the ASIC will
operate at the full projected figure.

---

## Why FPGA Emulation?

Before committing to silicon, every RTL change must be validated for:

| Concern | How FPGA addresses it |
|---|---|
| Bit-accurate arithmetic | Ternary MACs synthesised 1:1 from HDL |
| Timing closure | Vivado static-timing analysis at 25–50 MHz |
| System integration | Real PCIe/USB host-driver against live bitstream |
| Anchor integrity | JTAG read of design register `0x47C0` confirms chip identity |
| Power envelope | Kria on-board power rails measured with XADC |

Catching RTL bugs on the K26 is orders of magnitude cheaper than a re-spin.

---

## Target Board: Xilinx Kria K26 SOM

| Attribute | Value |
|---|---|
| FPGA fabric | UltraScale+ (XCZU5EV) |
| LUT / FF | 256 K LUTs, 512 K FFs |
| BRAM | 144 × 36 Kb |
| DSP slices | 1248 |
| Approx. retail | ~USD 250 |
| Product page | https://www.xilinx.com/products/som/kria/k26c-commercial.html |

The K26 SOM is the recommended entry point for NeuronConstant pre-silicon work.
It provides enough fabric for the **gamma 8×4 tile array** (reduced from full-scale
production), an Arm Cortex-A53 host, and PCIe/USB connectivity for software stacks.

---

## Toolchain Requirements

| Tool | Version | Notes |
|---|---|---|
| Vivado Design Suite | 2024.1 or later | Synthesis + implementation + bitstream |
| Vitis HLS | 2024.1 (optional) | HLS front-end for host-side accelerator kernels |
| Python | 3.10+ | Host driver scripts |
| xrt (Xilinx Runtime) | 2.16+ | PCIe/USB communication with bitstream |
| JTAG cable | Digilent HS3 or equivalent | Bitstream flashing + anchor verification |

---

## Future Repository Layout

The FPGA emulator will live in a dedicated repository **`gHashTag/trinity-fpga-emulator`**
(to be created ahead of tape-out).  Expected layout:

```
trinity-fpga-emulator/
├── kria-bitstream/          # Vivado project files (.xpr, .runs/, .srcs/)
│   ├── trinity_phi.xpr
│   ├── trinity_euler.xpr
│   └── trinity_gamma.xpr
├── tcl-scripts/
│   └── build.tcl            # Non-interactive synthesis flow
├── rtl/                     # Symlink / submodule targets
│   ├── tt-trinity-phi/      # pulled from tt-trinity-phi  depin-v1 branch
│   ├── tt-trinity-euler/    # pulled from tt-trinity-euler depin-v1 branch
│   └── tt-trinity-gamma/    # pulled from tt-trinity-gamma depin-v1 branch
└── host-driver/             # PCIe/USB host code
    ├── kria_host.py         # Python driver (reads/writes MMIO registers)
    └── kria_host.c          # Optional C driver for bare-metal / RTOS
```

### Key files explained

- **`kria-bitstream/`** — Vivado project per chip variant (phi, euler, gamma).  Each
  project references RTL under `rtl/` via relative paths so the build is reproducible.
- **`tcl-scripts/build.tcl`** — Called as `vivado -mode batch -source build.tcl` for
  fully automated synthesis and implementation.  Outputs `trinity_gamma.bit`.
- **`host-driver/kria_host.py`** — Reads anchor register `0x47C0`, exercises the
  ternary MAC array with toy inputs, and reports latency.
- **RTL sources** — cloned from the `depin-v1` branch of each tt-trinity-* repo (not
  modified here).

---

## Step-by-Step: Synthesise and Flash

### Step 1 — Clone tt-trinity-phi (depin-v1 branch)

```bash
git clone -b depin-v1 https://github.com/gHashTag/tt-trinity-phi.git rtl/tt-trinity-phi
# Repeat for euler and gamma
git clone -b depin-v1 https://github.com/gHashTag/tt-trinity-euler.git rtl/tt-trinity-euler
git clone -b depin-v1 https://github.com/gHashTag/tt-trinity-gamma.git rtl/tt-trinity-gamma
```

### Step 2 — Point Vivado at src/

Open Vivado 2024.1 and create/open the project:

```tcl
# In Vivado Tcl Console or batch mode:
open_project kria-bitstream/trinity_gamma.xpr
# If starting fresh:
set_property SOURCE_SET sources_1 [get_filesets sources_1]
add_files -scan_for_includes rtl/tt-trinity-gamma/src/
```

Alternatively run the non-interactive flow:

```bash
vivado -mode batch -source tcl-scripts/build.tcl
```

### Step 3 — Run Synthesis and Implementation

```bash
# Inside build.tcl or interactively:
launch_runs synth_1 -jobs 8
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
```

Expected result: `trinity_gamma.bit` in
`kria-bitstream/trinity_gamma.runs/impl_1/`.

Timing should close at 25 MHz on K26; a 50 MHz constraint may require further
pipelining.

### Step 4 — Flash Bitstream to K26

With the Kria board connected via JTAG:

```bash
# Using Vivado Hardware Manager CLI:
open_hw_manager
connect_hw_server -url localhost:3121
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {kria-bitstream/trinity_gamma.runs/impl_1/trinity_gamma.bit} \
    [current_hw_device]
program_hw_devices [current_hw_device]
```

Or via xsdb:

```bash
xsdb -eval "connect; fpga kria-bitstream/trinity_gamma.runs/impl_1/trinity_gamma.bit"
```

### Step 5 — Verify Anchor 0x47C0 via JTAG Read

After flashing, confirm chip identity by reading the anchor register:

```bash
# Using xsdb:
xsdb << 'EOF'
connect
targets -set -filter {name =~ "APU*"}
# Read 32-bit register at anchor address 0x47C0
mrd 0x47C0
EOF
```

Expected output:

```
0x000047C0:  0xC0FFEE42   # Trinity design marker — value confirmed
```

The Python host driver can also read this over UIO/devmem:

```python
# host-driver/check_anchor.py
import mmap, os, struct

ANCHOR_ADDR = 0x47C0
PAGE = 4096

with open("/dev/mem", "r+b") as f:
    mm = mmap.mmap(f.fileno(), PAGE, offset=ANCHOR_ADDR & ~(PAGE - 1))
    val = struct.unpack_from("<I", mm, ANCHOR_ADDR & (PAGE - 1))[0]
    print(f"Anchor 0x47C0 = 0x{val:08X}")
    assert val == 0xC0FFEE42, "Anchor mismatch — wrong bitstream?"
```

---

## Known Limitations on K26

| Limitation | Detail |
|---|---|
| Tile count | gamma 8×4 tile array fits K26; full production array does not |
| Clock rate | ~25 MHz emulated (vs ~50 MHz ASIC target) |
| Memory bandwidth | K26 LPDDR4 shared with Arm; expect 40–60% BW utilisation |
| Power measurement | On-chip XADC only; external INA219 recommended for <50 mW accuracy |
| PCIe | K26 carrier board required for PCIe Gen 2 x1 connectivity |

These constraints mean the FPGA run is useful for functional validation and
rough latency profiling, **not** as a direct proxy for ASIC throughput numbers.

---

## Roadmap

Full ASIC plans, tile architecture, and tape-out schedule are documented in:

[docs/architecture/TTSKY26c_UNIFIED_COMPUTER_RTL_ROADMAP.md](../architecture/TTSKY26c_UNIFIED_COMPUTER_RTL_ROADMAP.md)

Key milestones:

| Date | Milestone |
|---|---|
| Q3 2025 | FPGA emulator repo (`trinity-fpga-emulator`) created, gamma synth passing |
| Q1 2026 | Full host-driver stack (Python + C) with ZK proof round-trip |
| Q3 2026 | Pre-tape-out sign-off run: anchor 0x47C0 verified, all tiles green |
| 2026-12-16 | ASIC tape-out (TTSKY26c) |

---

## See Also

- **Whitepaper §9** — Hardware architecture and performance projections
  ([docs/whitepaper/](../whitepaper/))
- **Devkit INDEX** — [docs/devkit/INDEX.md](INDEX.md) (see G12 deliverable)
- **Trinity Node guide** — [docs/trinity-node/](../trinity-node/)
- **Trinity SDK** — [docs/trinity-sdk/](../trinity-sdk/)
- **QUICKSTART** — [docs/devkit/QUICKSTART_5_MIN.md](QUICKSTART_5_MIN.md)
