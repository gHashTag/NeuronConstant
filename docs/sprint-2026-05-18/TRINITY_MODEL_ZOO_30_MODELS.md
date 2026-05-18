# Trinity Model Zoo — 30-Model Port Specification
**Version**: 0.2-draft · **Status**: PLANNED · **Maintainer**: Trinity DevKit Team  
**Compiler target**: Trinity SKY26b (current silicon) / SKY26c (stretch targets noted)  
**Last updated**: 2026-05-18

---

> ## ⚠ Honest Framing — Read Before Citing Numbers
>
> **Trinity v1.0 (TT SKY26b) is a research demonstrator** submitted to the Tiny Tapeout
> educational shuttle. It is **not** a production ML accelerator.
>
> **Measured performance ceiling**: ~1 GOPS @ ~50 MHz @ ~1 W in ternary mode —
> **PROJECTED, simulator estimate only. Real silicon measurements pending tape-out
> scheduled 2026-12-16.**
>
> All throughput figures in this document (fps, tok/s, steps/s) are **simulator
> projections derived from the 1 GOPS ceiling and published model op-counts**. They
> are labelled "(projected, simulator estimate, pending silicon)" throughout. They will
> be replaced with measured numbers once physical DevKit Pro units are available.
>
> **Production ML workloads** (real-time video, production ASR, deployed LLM serving)
> should continue to use **Jetson Orin Nano Super** (20 TOPS) or **Hailo-8** (26 TOPS)
> until Trinity reaches a higher-volume process node. Trinity's purpose here is:
> (a) demonstrating the Trinity Compiler end-to-end pipeline, (b) validating
> quantisation recipes at silicon level, and (c) producing silicon-signed inference
> receipts for provenance research. The 30-model zoo is an **aspiration / target list**,
> not a benchmark catalogue. Many models — especially Llama 1B, Whisper-tiny, and
> Stable Diffusion — will run at marginal or demo speeds on SKY26b.

---

## Table of Contents
1. [Why These 30 Models](#why-these-30-models)
2. [Hardware Reference](#hardware-reference)
3. [Quantization Methodology](#quantization-methodology)
4. [Verification Recipe](#verification-recipe)
5. [CV Models (1–10)](#cv-models-110)
6. [Audio / Speech Models (11–15)](#audiospeech-models-1115)
7. [NLP / LLM Models (16–23)](#nlpllm-models-1623)
8. [Generative / Other (24–27)](#generativeother-models-2427)
9. [Reinforcement Learning (28–30)](#reinforcement-learning-models-2830)
10. [Timeline](#timeline)
11. [Owner Table](#owner-table)
12. [References](#references)

---

## Why These 30 Models

These 30 models were selected according to four criteria:

**1. Category coverage**  
The set spans the five deployment verticals that Trinity DevKit users currently explore:
computer vision (object detection, segmentation, pose estimation, classification),
on-device audio/speech (transcription, synthesis, keyword spotting, streaming ASR),
edge NLP (embedding, question-answering, sequence-to-sequence), generative inference
(super-resolution, image segmentation, demo diffusion), and embedded reinforcement
learning (Atari/continuous-control policy networks).

**2. Real-world demand**  
Every model in the list has ≥100 K monthly downloads on HuggingFace (as of 2026-05)
or appears in the top-50 of the ONNX Model Zoo by GitHub star citations. YOLOv8/11,
DistilBERT, Whisper-tiny, and MobileBERT alone account for the majority of edge-AI
deployment requests received by the Trinity DevKit beta programme.

**3. SKY26b memory and compute constraints**  
Trinity SKY26b carries SRAM/ROM only — no HBM. The hard limit for on-chip resident
weights is approximately 2 M parameters at INT8 (≈2 MB) or ~4 M parameters at NF4.
Models ≤2 M params (phi tile) or ≤16 M params at aggressive NF4/ternary compression
can run fully on-chip. Models that exceed this boundary are labelled **streaming** and
require SPI-attached flash (external QSPI NOR or SD card) to page in weight tiles.
SPI streaming incurs ~40 MB/s effective bandwidth at 80 MHz DDR, which is factored
into all simulator estimates.  
The compute ceiling of ~1 GOPS (ternary mode, projected) means that models with
large op-counts will be throughput-limited by compute, not just memory bandwidth.
All throughput numbers in this document are **projections from simulator** and may
prove optimistic or pessimistic once silicon is measured.

**4. Two or three stretch models require SKY26c**  
ResNet-50 (25.6 M, FP32 baseline), CLIP-ViT-Base/32, and Stable Diffusion XS are
labelled **SKY26c-target**. SKY26c is expected to double on-chip SRAM and add a
dedicated streaming DMA; these models are included now so that compiler and model-prep
work can begin in parallel with silicon tape-out.

---

## Hardware Reference

| ASIC       | Tile grid       | Approx. cells | On-chip SRAM | Peak compute (projected)              |
|------------|-----------------|---------------|--------------|---------------------------------------|
| phi        | 1 × 1           | ~6 K          | ~192 KB      | ~0.07 GOPS @ 50 MHz (ternary, proj.) |
| euler      | 8 × 2           | ~24 K         | ~768 KB      | ~0.29 GOPS @ 50 MHz (ternary, proj.) |
| gamma      | 8 × 4           | ~48 K         | ~1.5 MB      | ~0.57 GOPS @ 50 MHz (ternary, proj.) |
| full-triad | phi+euler+gamma | ~78 K         | ~2.5 MB      | ~1 GOPS @ 50 MHz (ternary, proj.)    |
| streaming  | any + SPI       | —             | —            | External QSPI/SD weight paging        |

> **Important**: All GOPS figures above are **projected from RTL simulation** at the
> 1 GOPS full-triad ceiling for ternary mode. INT8 and higher-precision formats reduce
> effective throughput. Real measurements are pending tape-out (2026-12-16).
> Do not use these numbers in external benchmarks or marketing materials.

**Numeric formats available (66 total; representative subset used in this document)**

| Format  | Bits/weight | Notes                                       |
|---------|-------------|---------------------------------------------|
| Ternary | ~1.58       | BitNet 1.58 {-1, 0, +1} — best compression |
| NF4     | 4           | NormalFloat4; near-optimal for LLM weights  |
| GF4     | 4           | GridFloat variant; good for activations     |
| INT8    | 8           | Symmetric/asymmetric; wide hardware support |
| GF16    | 16          | GridFloat16; precision fallback             |
| Posit8  | 8           | Posit arithmetic; better dynamic range      |
| Posit16 | 16          | Posit16; output/accumulation precision      |
| GF256   | 8 (custom)  | Grid-256; per-channel scale factor baked in |

---

## Quantization Methodology

Trinity Compiler selects numeric formats through a three-stage automated pipeline:

### Stage 1 — Sensitivity Analysis
For every layer in the ONNX graph, the compiler runs a Fisher-information proxy:
it perturbs each weight tensor by ±1 quantisation step and measures KL-divergence
between original and perturbed output logits on a 256-sample calibration set.
Layers whose output KL-divergence exceeds `epsilon = 0.01` nats are classified
**sensitive** and retained at higher precision (GF16 or Posit16).
Layers below the threshold are candidates for aggressive quantisation (NF4, ternary).

### Stage 2 — Error Budget Allocation
The compiler applies a per-model **error budget** (total allowed degradation on the
target accuracy metric, e.g. mAP, WER, top-1). Budget is allocated greedily:
bits are stripped from the least-sensitive layers first until either the budget is
exhausted or all layers are at minimum format. A Pareto search over {ternary, NF4,
INT8, Posit8} × {per-tensor, per-channel, per-group-64} produces the final format map.

### Stage 3 — Layout & Tile Assignment
After format assignment, the compiler packs weight tensors into Trinity tile memory
using a column-major interleaved layout optimised for the target ASIC's cell width
(6 K / 24 K / 48 K cells). If packed size exceeds on-chip capacity, the compiler
automatically emits a **streaming manifest** that partitions weights into SPI-page
chunks and inserts DMA prefetch instructions in the trinity-rtl output.

### Mixed-Precision Convention Used in This Document
Unless otherwise stated, models follow this default recipe:
- **Embedding / first conv / last linear**: Posit16 (precision-critical)
- **Attention Q/K/V projections**: NF4 (low sensitivity empirically)
- **Attention output + FFN weights**: NF4 or ternary depending on model size
- **Layer norms / batch norms**: GF16 (scale/bias kept in Posit16)
- **Activations**: GF4 (quantised post-ReLU/GELU)
- **Final output logits / embeddings**: Posit16

---

## Verification Recipe

Every ported model must pass the following gates before its status advances to VERIFIED:

1. **Numerical parity check** — Mean absolute error between ONNX float32 reference
   output and Trinity quantised output on 100 random samples ≤ 0.5% of output range.
2. **Task-metric regression** — Primary task metric (mAP / WER / top-1 / BLEU) must
   stay within **–3 pp** of the float32 baseline on the model's standard benchmark
   dataset subset (1 000 samples).
3. **Throughput measurement** — Physical silicon run (or cycle-accurate RTL simulation
   for pre-production tiles) confirms throughput ≥ the simulator estimate stated in this
   document. Measured values replace projected figures upon VERIFIED status.
4. **Silicon-signed inference receipts** — Trinity DevKit firmware generates a
   SHA-256-signed inference receipt for each of the 100 test samples. Receipts are
   committed to the public repository `github.com/trinity-model-zoo` under the path
   `verified/<model-id>/receipts/`. The receipt bundle includes: model hash, sample
   hash, output tensor checksum, tile config, and firmware version.
5. **Notebook reproducibility** — The model's Jupyter notebook on
   `trinity-hub.io/models/<NN>/notebook.ipynb` must execute end-to-end without error
   in the Trinity DevKit Docker image `ghcr.io/trinity-asic/devkit:latest`.

---

## CV Models (1–10)

---

### 01. YOLOv11n
**Params**: 2.6 M  
**Target tile**: euler (primary); phi with streaming feasible  
**Format**: mixed — NF4 backbone, Posit16 detection heads  
**Memory**: ~1.4 MB after NF4 quantisation (fits euler on-chip)  
**Expected throughput**: ~22 fps @ 640×640 *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- Conv layers 1–18 (backbone CSPDark): NF4, per-group-64
- C2f modules (neck): NF4 per-channel
- Detection heads (Detect3): Posit16 for box/cls outputs
- Batch-norm scales: GF16
- Activations (SiLU): GF4 post-nonlinearity

**Source ONNX**: [ONNX Model Zoo — YOLOv8/11 family](https://github.com/onnx/models/tree/main/validated/vision/object_detection_segmentation/yolov8)  
(YOLOv11n official ONNX export: `ultralytics export model=yolo11n.pt format=onnx`)  
**License**: AGPL-3.0 (Ultralytics); commercial licence available  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/01/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~45 fps @ 640×640 FP16 (TensorRT).  
Trinity simulator projection: ~22 fps on euler, streaming-free NF4 path. Measured silicon
figure will be published when DevKit Pro units are available.

---

### 02. MobileViT-Small
**Params**: 5.6 M  
**Target tile**: gamma (fully on-chip)  
**Format**: mixed — NF4 MV2 blocks, Posit16 transformer attention, GF4 activations  
**Memory**: ~3.1 MB after NF4 (slightly exceeds euler; gamma required)  
**Expected throughput**: ~18 fps @ 256×256 *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- MobileNetV2 stem + inverted residual blocks: NF4 per-group-64
- MobileViT attention Q/K/V projections: NF4 per-channel
- Multi-head self-attention output: Posit16
- Feed-forward network (FFN) in ViT blocks: NF4
- LayerNorm affine params: GF16
- Classifier head (linear): Posit16
- Activations: GF4

**Source ONNX**: [apple/mobilevit-small on HuggingFace](https://huggingface.co/apple/mobilevit-small)  
Export via `transformers` ONNX exporter.  
**License**: Apple sample code licence (research/non-commercial)  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/02/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~68 fps @ 256×256 FP16 (public MobileViT benchmarks).  
Trinity simulator projection: ~18 fps on gamma.

---

### 03. EfficientNet-B0
**Params**: 5.3 M  
**Target tile**: gamma (fully on-chip)  
**Format**: mixed — NF4 MBConv blocks, Posit16 classifier  
**Memory**: ~2.9 MB after NF4 quantisation  
**Expected throughput**: ~25 fps @ 224×224 *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- Stem conv + MBConv1–7 depthwise: NF4 per-group-64
- MBConv pointwise projections: NF4 per-channel
- SE (squeeze-excitation) fc layers: GF16 (small, precision-sensitive)
- Top (global avg pool → dense): Posit16
- Batch-norm: GF16
- Swish activations: GF4

**Source ONNX**: [ONNX Model Zoo — EfficientNet](https://github.com/onnx/models/tree/main/validated/vision/classification/efficientnet-lite4)  
(B0 export from `timm`: `timm.models.efficientnet_b0` → `torch.onnx.export`)  
**License**: Apache-2.0  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/03/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~112 fps @ 224×224 FP16 TensorRT (public timm benchmarks).  
Trinity simulator projection: ~25 fps on gamma. The large gap relative to Jetson reflects
Trinity's cell count (~48 K) vs a 1024-CUDA-core GPU — this is expected for a research demonstrator.

---

### 04. ResNet-50
**Params**: 25.6 M  
**Target tile**: **SKY26c-target** (does not fit SKY26b usefully; streaming on gamma possible but throughput well below 10 fps)  
**Format**: INT8 (SKY26b streaming fallback) → NF4 full on-chip (SKY26c)  
**Memory**: ~6.4 MB INT8 / ~3.2 MB NF4  
**Expected throughput**: ~4 fps streaming on gamma (SKY26b) *(projected, simulator estimate, pending silicon — below 10 fps acceptance threshold)*; ~20 fps fully on-chip (SKY26c) *(projected; may not be achievable until SKY26c)*  
**Quantization recipe**:
- All residual conv layers: INT8 symmetric per-channel (SKY26b streaming path)
- SKY26c path: NF4 per-group-64 for conv1–conv4; Posit16 FC layer
- BN folded into conv weights at export time
- Activations: GF4

**Source ONNX**: [ONNX Model Zoo — ResNet50](https://github.com/onnx/models/blob/main/validated/vision/classification/resnet/model/resnet50-v2-7.onnx)  
**License**: Apache-2.0  
**Status**: PLANNED (SKY26c dependency)  
**Notebook**: trinity-hub.io/models/04/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~185 fps @ 224×224 FP16 (GPU path).  
Included as cross-architecture accuracy reference only. Not a production Trinity target until SKY26c.

> **Note**: ResNet-50 is included as a reference baseline to enable cross-architecture
> accuracy comparisons. Production deployments should prefer EfficientNet-B0 or
> MobileViT-Small for equivalent accuracy at far lower parameter count.

---

### 05. FaceNet (Inception-ResNet-V1)
**Params**: 22 M  
**Target tile**: gamma + streaming (weight paging via SPI)  
**Format**: mixed — NF4 Inception blocks, Posit16 embedding layer  
**Memory**: ~12 MB FP32 → ~2.8 MB NF4 (streaming; ~1.5 MB resident on gamma)  
**Expected throughput**: ~8 fps @ 160×160 *(projected, simulator estimate, pending silicon — marginal; SPI paging of Inception blocks is the bottleneck)*  
**Quantization recipe**:
- Inception-ResNet-A/B/C modules: NF4 per-group-64
- Reduction modules: NF4 per-channel
- BatchNorm folded; scale/bias: GF16
- Pre-logits FC (512-dim embedding): Posit16 — **must not quantise below GF16**
- L2 normalisation output: Posit16
- Activations (ReLU): GF4

**Source ONNX**: [davidsandberg/facenet — ONNX export](https://github.com/davidsandberg/facenet) (third-party ONNX: timm/face-recognition zoo)  
**License**: MIT  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/05/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~55 fps @ 160×160 FP16.  
Trinity simulator projection: ~8 fps on gamma + streaming. Embedding cosine similarity error < 0.003 vs FP32 required for verification.

---

### 06. MobileNetV3-Small
**Params**: 2.9 M  
**Target tile**: euler (fully on-chip)  
**Format**: NF4 throughout; Posit16 classifier head  
**Memory**: ~1.6 MB after NF4 (fits euler)  
**Expected throughput**: ~38 fps @ 224×224 *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- All depthwise + pointwise convs: NF4 per-group-64
- Hard-swish activations replaced by piecewise-linear approx (GF4 LUT)
- SE modules: GF16 (2 × small FC layers, preserve precision)
- Classifier FC: Posit16
- BN folded at export

**Source ONNX**: [ONNX Model Zoo — MobileNetV3](https://github.com/onnx/models/tree/main/validated/vision/classification/mobilenet)  
**License**: Apache-2.0  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/06/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~420 fps @ 224×224 FP16.  
Trinity simulator projection: ~38 fps on euler. Top-1 accuracy target: ≥ 67.5% on ImageNet-1K val subset.

---

### 07. YOLOv8n-Pose
**Params**: 3.5 M  
**Target tile**: euler (fully on-chip)  
**Format**: NF4 backbone; Posit16 keypoint regression heads  
**Memory**: ~1.9 MB after NF4  
**Expected throughput**: ~19 fps @ 640×640 *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- CSPDarknet53 nano backbone: NF4 per-group-64
- C2f neck modules: NF4 per-channel
- Pose head (keypoint xy + conf): Posit16 — do not quantise below GF16
- Bounding box head: NF4 (less precision-sensitive than keypoints)
- SiLU activations: GF4
- BN folded

**Source ONNX**: `ultralytics export model=yolov8n-pose.pt format=onnx`  
[Ultralytics YOLOv8 — GitHub](https://github.com/ultralytics/ultralytics)  
**License**: AGPL-3.0 (Ultralytics)  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/07/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~38 fps @ 640×640 FP16.  
Trinity simulator projection: ~19 fps on euler. OKS (Object Keypoint Similarity) ≥ 0.49 on COCO-pose val required.

---

### 08. DeepLabV3+-MobileNet
**Params**: 5.4 M (MobileNetV2 backbone + ASPP + decoder)  
**Target tile**: gamma (fully on-chip)  
**Format**: mixed — NF4 encoder backbone, GF16 ASPP dilated convs, Posit16 output  
**Memory**: ~3.0 MB after NF4/GF16 mix  
**Expected throughput**: ~12 fps @ 512×512 *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- MobileNetV2 encoder (layers 1–17): NF4 per-group-64
- ASPP (Atrous Spatial Pyramid Pooling) parallel branches: GF16 — dilation patterns are sensitive to quantisation noise
- Decoder upsampling convs: NF4 per-channel
- Final segmentation logits conv (num_classes output): Posit16
- BN folded; batch-norm stats from calibration set
- Activations: GF4

**Source ONNX**: [tensorflow/models DeepLab ONNX export](https://github.com/tensorflow/models/tree/master/research/deeplab); also available via `torch.hub` + ONNX export  
**License**: Apache-2.0  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/08/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~40 fps @ 512×512 FP16.  
Trinity simulator projection: ~12 fps on gamma. mIoU target: ≥ 71% on Pascal VOC 2012 val (vs float32 reference 75.2%).

---

### 09. PoseNet (Small / MobileNetV1-based)
**Params**: 4.6 M  
**Target tile**: gamma (fully on-chip)  
**Format**: NF4 depthwise backbone; Posit16 heatmap output  
**Memory**: ~2.5 MB after NF4  
**Expected throughput**: ~16 fps @ 353×257 *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- MobileNetV1 depthwise-separable conv stack (layers 1–13): NF4 per-group-64
- Heatmap output conv layers (17 keypoint channels): Posit16 — sub-pixel precision required
- Offset/displacement field convs: GF16
- ReLU6 activations: GF4 clamped [0, 6] to match ReLU6 range

**Source ONNX**: [tensorflow/tfjs-models PoseNet → ONNX](https://github.com/tensorflow/tfjs-models/tree/master/posenet) (third-party conversion via `tf2onnx`)  
**License**: Apache-2.0  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/09/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~72 fps @ 353×257 FP16.  
Trinity simulator projection: ~16 fps on gamma. mAP (COCO keypoints, 17 joints) ≥ 61% required for verification.

---

### 10. EfficientDet-Lite0
**Params**: 4.1 M  
**Target tile**: gamma (fully on-chip)  
**Format**: NF4 BiFPN + backbone; Posit16 box/class heads  
**Memory**: ~2.3 MB after NF4  
**Expected throughput**: ~15 fps @ 320×320 *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- EfficientNet-B0 backbone (feature extractor): NF4 per-group-64 (same recipe as model #03)
- BiFPN weighted feature fusion nodes: GF16 (weighted sum precision-sensitive)
- Box regression network (4 × repeated separable convs): NF4 per-channel
- Class prediction network: Posit16
- Sigmoid activations: GF4; BN folded

**Source ONNX**: [google/automl EfficientDet ONNX export](https://github.com/google/automl/tree/master/efficientdet); TFLite → ONNX via `onnxruntime-extensions`  
**License**: Apache-2.0  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/10/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~95 fps @ 320×320 FP16 (TensorRT).  
Trinity simulator projection: ~15 fps on gamma. mAP target: ≥ 25.5 COCO (vs float32 26.4).

---

## Audio/Speech Models (11–15)

---

### 11. Whisper-tiny
**Params**: 39 M (encoder 11 M + decoder 28 M)  
**Target tile**: gamma + streaming (encoder on-chip; decoder streamed)  
**Format**: mixed — NF4 encoder, NF4 decoder attention, Posit16 logits  
**Memory**: ~39 M × 2 B = ~78 MB FP32 → ~10 MB NF4; encoder ~3 MB on-chip, decoder streamed via SPI  
**Expected throughput**: ~0.8× realtime for en-only short utterances (<30 s) *(projected, simulator estimate, pending silicon — below 1× realtime target; this is a known limitation of the SKY26b compute ceiling and SPI bandwidth; do not use for production ASR)*  
**Quantization recipe**:
- Audio encoder (log-mel CNN + transformer 4-layer): NF4 per-group-64 entirely on gamma
- Cross-attention K/V cache from encoder: pinned in Posit16 (precision-critical for alignment)
- Text decoder transformer (4-layer): NF4 weights, streamed from SPI
- Token embedding table (51 865 × 384): NF4 block-wise, streamed
- Final linear (lm_head): Posit16
- LayerNorm: GF16

**Source ONNX**: [openai/whisper on HuggingFace](https://huggingface.co/openai/whisper-tiny) — ONNX export via `optimum` CLI: `optimum-cli export onnx --model openai/whisper-tiny whisper_onnx/`  
**License**: MIT  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/11/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~8× realtime @ FP16.  
Trinity simulator projection: ~0.8× realtime on gamma + streaming. WER on LibriSpeech test-clean ≤ 6.5% required (float32 reference: 5.9%).

> **Streaming note**: Full encoder-decoder Whisper-tiny requires SPI weight paging for decoder.
> For latency-critical applications, encoder-only embedding output can be passed to a lightweight
> CTC decoder (not included in this spec) to avoid decoder streaming overhead.
>
> **Production note**: For any real-time speech application, use Jetson + faster-whisper or
> Hailo-8 until Trinity reaches a production process node.

---

### 12. Tacotron-2 (Encoder Only)
**Params**: ~28 M (full model); encoder sub-graph ~6 M  
**Target tile**: gamma (encoder sub-graph fits on-chip); full model requires streaming  
**Format**: NF4 conv + LSTM encoder; Posit16 encoder output embeddings  
**Memory**: encoder ~3.3 MB NF4 (on gamma); full model ~15 MB NF4 (streaming)  
**Expected throughput**: encoder ~45 mel frames/s; full TTS synthesis ~0.7× realtime with streaming *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- Character embedding table (148 × 512): GF16
- Conv prenet (3 × conv1D with BN): NF4 per-channel
- Encoder LSTM (bidirectional, 512 hidden): NF4 per-group-64; LSTM cell state retained in Posit16 between frames
- Attention module (location-sensitive): Posit16 — alignment head is precision-critical
- Mel decoder LSTM + postnet: NF4 (streaming path)
- Postnet conv stack: NF4

**Source ONNX**: [NVIDIA Tacotron2 PyTorch → ONNX](https://github.com/NVIDIA/tacotron2) (export script in repo); also [coqui-ai/TTS](https://github.com/coqui-ai/TTS)  
**License**: BSD-3-Clause (NVIDIA); MPL-2.0 (Coqui)  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/12/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — full Tacotron-2 ~2.3× realtime FP16; encoder-only ~90 frames/s.  
Trinity simulator projection: encoder ~45 frames/s on gamma; full TTS ~0.7× realtime streaming. MOS ≥ 4.1 for encoder embedding quality check (subjective evaluation on 50-utterance test set).

---

### 13. WaveNet (Small / WaveGlow-lite)
**Params**: 11 M  
**Target tile**: gamma (on-chip with NF4)  
**Format**: NF4 dilated convolutions; Posit16 output sample distribution  
**Memory**: ~6 MB FP32 → ~1.5 MB NF4 (fits gamma on-chip)  
**Expected throughput**: ~0.5× realtime sample generation (autoregressive) *(projected, simulator estimate, pending silicon — below 1× realtime; parallel WaveGlow variant recommended)*  
**Quantization recipe**:
- Causal dilated conv stack (30 layers, dilation 1–512): NF4 per-group-64
- Gated activation unit (tanh + sigmoid branches): Posit8 for intermediate; GF4 output gate
- Residual + skip connections: GF16 (summation precision)
- Output 1×1 conv (256 μ-law classes): Posit16
- Conditioning embedding (if used): GF16

**Source ONNX**: [ibab/tensorflow-wavenet → ONNX](https://github.com/ibab/tensorflow-wavenet) (via `tf2onnx`); PyTorch parallel WaveGlow: [NVIDIA/WaveGlow](https://github.com/NVIDIA/waveglow)  
**License**: MIT (ibab); BSD-3-Clause (NVIDIA WaveGlow)  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/13/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — WaveGlow small ~1.1× realtime FP16.  
Trinity simulator projection: ~0.5× realtime (autoregressive path) on gamma. Parallel WaveGlow variant may reach ~1× realtime and is the recommended path for any production use.

---

### 14. RNN-T (Small / Streaming ASR)
**Params**: 22 M (encoder 9 M + prediction network 4 M + joint network 9 M)  
**Target tile**: gamma + streaming  
**Format**: NF4 LSTM/conformer encoder; Posit16 joint network  
**Memory**: ~12 MB FP32 → ~3 MB NF4; encoder portion (~2 MB) fits gamma; prediction + joint streamed  
**Expected throughput**: ~1.1× realtime streaming (chunk-wise, 160 ms chunks) *(projected, simulator estimate, pending silicon — marginally above 1× realtime; SPI streaming latency may cause jitter in real deployments)*  
**Quantization recipe**:
- Conformer encoder (6 layers, 144 dim): NF4 per-group-64
- Multi-head self-attention (encoder): NF4 Q/K/V, Posit16 output
- Convolution module in conformer: NF4
- Prediction network LSTM (2 layers, 320 dim): NF4 per-group-64; hidden state in Posit16 (persistent across chunks)
- Joint network (fully connected 640 → vocab): Posit16
- Log-softmax output: Posit16

**Source ONNX**: [NVIDIA NeMo streaming RNN-T export](https://github.com/NVIDIA/NeMo) (`nemo.export.onnx`); also [k2-fsa/icefall RNN-T](https://github.com/k2-fsa/icefall)  
**License**: Apache-2.0  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/14/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~4× realtime streaming FP16.  
Trinity simulator projection: ~1.1× realtime on gamma + streaming. WER on LibriSpeech test-clean ≤ 8% required.

---

### 15. Keyword Spotting CNN
**Params**: 0.5 M  
**Target tile**: phi (fully on-chip — primary demonstration target for phi tile)  
**Format**: INT8 throughout (phi cell width optimised for INT8); Posit8 output layer  
**Memory**: ~0.5 MB FP32 → ~125 KB INT8 (fits phi with headroom)  
**Expected throughput**: ~400 inferences/s @ 1-second audio windows *(projected, simulator estimate, pending silicon — comfortably above 1× realtime; phi is well-matched to this workload)*  
**Quantization recipe**:
- Input log-mel spectrogram normalisation: GF16
- Conv2D layers 1–4 (time-frequency feature extraction): INT8 symmetric per-channel
- Depthwise separable conv layers 5–6: INT8 per-channel
- Global average pooling: INT8
- Dense classification head (35 keywords): Posit8
- Batch-norm folded at export; ReLU activations: GF4

**Source ONNX**: [ARM-software/ML-examples keyword spotting](https://github.com/ARM-software/ML-examples/tree/master/tflu-kws-cortex-m); also [pete-warden/speech_commands CNN](https://github.com/tensorflow/tensorflow/tree/master/tensorflow/examples/speech_commands) → ONNX via `tf2onnx`  
**License**: Apache-2.0  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/15/notebook.ipynb (placeholder)  
**Reference benchmark**: ARM Cortex-M55 — ~100 inferences/s FP32.  
Trinity phi simulator projection: ~400 inferences/s INT8. Accuracy on Google Speech Commands v2 (35-class) ≥ 96.0% required.

---

## NLP/LLM Models (16–23)

---

### 16. DistilBERT-base
**Params**: 66 M  
**Target tile**: gamma + streaming (SKY26b); full on-chip feasibility: **SKY26c-target**  
**Format**: NF4 transformer layers; Posit16 pooler/classifier  
**Memory**: ~66 M × 2 B = ~132 MB FP32 → ~16.5 MB NF4; streams in 6 weight pages of ~2.75 MB each  
**Expected throughput**: ~4 tok/s (sequence length 128, streaming) *(projected, simulator estimate, pending silicon — SPI paging of 6 weight pages is the dominant bottleneck; well below Jetson class throughput)*  
**Quantization recipe**:
- Token embeddings (30 522 × 768): NF4 block-wise (streamed, do not pin on-chip)
- 6 transformer layers Q/K/V projections: NF4 per-group-64
- 6 transformer layers attention output + FFN: NF4 per-channel
- LayerNorm affine params: GF16
- Pooler dense + task classifier: Posit16
- GELU activations: GF4 piecewise-linear approx

**Source ONNX**: [distilbert-base-uncased on HuggingFace](https://huggingface.co/distilbert/distilbert-base-uncased) — ONNX export: `optimum-cli export onnx --model distilbert/distilbert-base-uncased distilbert_onnx/`  
**License**: Apache-2.0  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/16/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~145 tok/s @ FP16.  
Trinity simulator projection: ~4 tok/s on gamma + streaming. GLUE SST-2 accuracy ≥ 91% required on 1 000-sample subset.

---

### 17. T5-Small
**Params**: 60 M (encoder 35 M + decoder 25 M)  
**Target tile**: gamma + streaming  
**Format**: NF4 encoder/decoder transformer; Posit16 lm_head  
**Memory**: ~60 M × 2 B = ~120 MB FP32 → ~15 MB NF4; paged streaming similar to DistilBERT  
**Expected throughput**: ~3 tok/s (seq2seq, max_new_tokens=64, streaming) *(projected, simulator estimate, pending silicon — near the ~3 tok/s acceptance floor; actual silicon may fall below threshold)*  
**Quantization recipe**:
- Shared token embedding (32 128 × 512): NF4 block-wise (streamed)
- Encoder 6-layer self-attention Q/K/V: NF4 per-group-64
- Decoder 6-layer cross-attention + self-attention: NF4 per-group-64
- Relative position bias: GF16 (small, keep precision)
- FFN (Wi/Wo layers, 2048 inner dim): NF4 per-channel
- LayerNorm: GF16
- lm_head (tied to embedding): Posit16

**Source ONNX**: [google-t5/t5-small on HuggingFace](https://huggingface.co/google-t5/t5-small) — ONNX export via `optimum`: `optimum-cli export onnx --model google-t5/t5-small t5_onnx/ --task seq2seq-lm`  
**License**: Apache-2.0  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/17/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~120 tok/s FP16.  
Trinity simulator projection: ~3 tok/s on gamma + streaming. ROUGE-L ≥ 26.5 on CNN/DailyMail summarisation subset required.

---

### 18. CLIP-ViT-Base/32 (Vision Encoder)
**Params**: ~86 M vision encoder  
**Target tile**: **SKY26c-target** *(projected; may not be achievable until SKY26c)* — gamma + streaming on SKY26b is technically possible but throughput is expected to be ~2 fps, well below the 10 fps acceptance threshold  
**Format**: NF4 ViT transformer blocks; Posit16 projection layer  
**Memory**: ~86 M × 2 B = ~172 MB FP32 → ~21.5 MB NF4 vision encoder; streamed  
**Expected throughput**: ~2 fps @ 224×224 per embedding on SKY26b *(projected, simulator estimate, pending silicon — below 10 fps target)*; ~10 fps on-chip on SKY26c *(projected; may not be achievable until SKY26c)*  
**Quantization recipe**:
- Patch embedding conv (32×32 patches): Posit16 (input, critical)
- 12 ViT-B transformer layers Q/K/V: NF4 per-group-64
- 12 layers MLP (FFN, 3072 inner): NF4 per-channel
- LayerNorm: GF16
- CLS token aggregation + linear projection (512-dim): Posit16 — embedding precision-critical for cross-modal similarity
- GELU activations: GF4

**Source ONNX**: [openai/clip-vit-base-patch32 on HuggingFace](https://huggingface.co/openai/clip-vit-base-patch32) — ONNX export via `optimum`: `optimum-cli export onnx --model openai/clip-vit-base-patch32 clip_onnx/ --task feature-extraction`  
**License**: MIT  
**Status**: PLANNED (SKY26c dependency for production throughput)  
**Notebook**: trinity-hub.io/models/18/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~38 fps @ 224×224 FP16 (vision encoder only).  
Trinity SKY26c simulator projection: ~10 fps. Zero-shot ImageNet-1K top-1 ≥ 63% required.

---

### 19. Llama-3.2-1B (Ternary / BitNet 1.58)
**Params**: 1.24 B nominal; ternary weights {-1, 0, +1}  
**Target tile**: gamma + streaming (heavy streaming; SPI bandwidth is the primary bottleneck)  
**Format**: **ternary (BitNet 1.58)** throughout; Posit16 RMSNorm + lm_head  
**Memory**: 1.24 B × 1.58 bits ≈ **~245 MB** packed ternary; requires 256+ MB SPI NOR or SD card  
**Expected throughput**: ~3 tok/s (streaming, seq=512, batch=1) *(projected, simulator estimate, pending silicon — barely at the 3 tok/s acceptance floor; actual silicon is as likely to fall below as above this target; treat as demo speed)*  
**Quantization recipe**:
- All linear layers (q/k/v/o projections, gate/up/down MLP): **ternary {-1, 0, +1}** with per-group-128 scale factors in GF16
- RMSNorm weight vectors: GF16
- Rotary position embeddings (RoPE): computed in Posit16 on-the-fly
- Token embedding matrix (32 000 × 2048): NF4 block-wise (further compress embedding table)
- lm_head (tied or separate): Posit16
- KV cache (runtime activations): GF16 on-chip ring buffer

**Source ONNX**: [meta-llama/Llama-3.2-1B on HuggingFace](https://huggingface.co/meta-llama/Llama-3.2-1B) — ternary quantization via [microsoft/BitNet](https://github.com/microsoft/BitNet) `bitnet_convert.py`; ONNX export from quantized checkpoint  
**License**: Llama 3.2 Community Licence (Meta)  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/19/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~45 tok/s @ INT4 (llama.cpp).  
Trinity simulator projection: ~3 tok/s on gamma + streaming (demo speed). Perplexity on WikiText-2 ≤ 12.0 required (float32 reference: ~9.8).

---

### 20. BitNet b1.58 700M
**Params**: 700 M ternary  
**Target tile**: gamma + streaming  
**Format**: **ternary (BitNet 1.58)** throughout; GF16 norms; Posit16 lm_head  
**Memory**: 700 M × 1.58 bits ≈ **~138 MB** packed ternary  
**Expected throughput**: ~4 tok/s (streaming, seq=512, batch=1) *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- Same ternary recipe as model #19, scaled to 700 M param architecture
- All attention + FFN weights: ternary per-group-128 with GF16 scale
- Activation quantisation: GF4 post-nonlinearity (ReLU/SiLU)
- Embedding: NF4 block-wise
- Norms: GF16; output: Posit16

**Source ONNX**: [microsoft/BitNet b1.58 — GitHub](https://github.com/microsoft/BitNet); model weights: [HuggingFace microsoft/bitnet-b1.58-700M](https://huggingface.co/microsoft/bitnet-b1.58-700M)  
**License**: MIT (microsoft/BitNet)  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/20/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~70 tok/s INT4 llama.cpp equivalent.  
Trinity simulator projection: ~4 tok/s on gamma + streaming. Perplexity on WikiText-2 ≤ 10.5 required. This model is the primary reference implementation for BitNet 1.58 on Trinity.

---

### 21. TinyLlama 1.1B (Ternary Quantized)
**Params**: 1.1 B nominal; ternary-quantized weights  
**Target tile**: gamma + streaming  
**Format**: ternary throughout; Posit16 lm_head and norms  
**Memory**: 1.1 B × 1.58 bits ≈ **~218 MB** packed ternary  
**Expected throughput**: ~3 tok/s (streaming, seq=512, batch=1) *(projected, simulator estimate, pending silicon — similar caveat to Llama-3.2-1B; treat as demo speed)*  
**Quantization recipe**:
- All Llama-architecture linear layers: ternary per-group-128 (same as #19, #20)
- GQA (grouped-query attention) K/V heads: ternary
- SwiGLU FFN (gate + up + down): ternary
- Embedding table: NF4 block-wise
- RMSNorm: GF16
- lm_head: Posit16

**Source ONNX**: [TinyLlama/TinyLlama-1.1B-Chat on HuggingFace](https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0) — ternary quantization via [microsoft/BitNet](https://github.com/microsoft/BitNet) converter  
**License**: Apache-2.0  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/21/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~55 tok/s @ INT4 llama.cpp.  
Trinity simulator projection: ~3 tok/s on gamma + streaming (demo speed). MT-Bench score ≥ 5.0 (7-point scale) required for chat variant.

---

### 22. MobileBERT
**Params**: 25.3 M  
**Target tile**: gamma + streaming (close to on-chip limit; benchmark will determine if fully fits)  
**Format**: NF4 transformer layers; Posit16 pooler/classifier  
**Memory**: ~25.3 M × 2 B = ~50.6 MB FP32 → ~6.3 MB NF4 (borderline gamma on-chip; streaming recommended for safety margin)  
**Expected throughput**: ~15 tok/s (seq=128, streaming) *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- Bottleneck MobileBERT transformer (24 layers, 128-dim internal): NF4 per-group-64
- Inter-bottleneck dense layers: NF4 per-channel
- FFN stacked (stacked_ffn=4): NF4
- LayerNorm: GF16
- Pooler + classifier head: Posit16
- GELU: GF4 piecewise approx

**Source ONNX**: [google/mobilebert-uncased on HuggingFace](https://huggingface.co/google/mobilebert-uncased) — ONNX export: `optimum-cli export onnx --model google/mobilebert-uncased mobilebert_onnx/`  
**License**: Apache-2.0  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/22/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~380 tok/s FP16.  
Trinity simulator projection: ~15 tok/s on gamma + streaming. GLUE score average ≥ 82.6 required (vs float32 reference 84.3).

---

### 23. Sentence-Transformers MiniLM-L6
**Params**: 22.7 M  
**Target tile**: gamma (fits on-chip with NF4)  
**Format**: NF4 transformer; Posit16 mean-pooling output  
**Memory**: ~22.7 M × 2 B = ~45.4 MB FP32 → ~5.7 MB NF4 (fits gamma)  
**Expected throughput**: ~20 tok/s (seq=128, on-chip) *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- 6-layer distilled MiniLM transformer Q/K/V: NF4 per-group-64
- Attention output + FFN: NF4 per-channel
- LayerNorm: GF16
- Mean pooling + optional dense projection: Posit16
- GELU: GF4

**Source ONNX**: [sentence-transformers/all-MiniLM-L6-v2 on HuggingFace](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2) — ONNX export via `optimum-cli export onnx --model sentence-transformers/all-MiniLM-L6-v2 minilm_onnx/ --task feature-extraction`  
**License**: Apache-2.0  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/23/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~510 tok/s FP16.  
Trinity simulator projection: ~20 tok/s on gamma. SBERT MTEB cosine similarity score on STS-Benchmark ≥ 0.84 required (float32 reference: 0.869).

---

## Generative/Other Models (24–27)

---

### 24. Stable Diffusion XS (Demo / Down-scaled)
**Params**: TBD (heavily pruned; target ~200 M demo-only sub-graph)  
**Target tile**: **SKY26c-target** (demo only; not for production on any current Trinity silicon)  
**Format**: NF4 UNet backbone; GF16 attention; Posit16 VAE decoder output  
**Memory**: ~200 M × 2 B = ~400 MB FP32 → ~50 MB NF4 — requires SD card streaming, multiple weight-page passes  
**Expected throughput**: ~0.05–0.1 fps (1 denoising step per ~10–20 s); 20 steps ≈ 3–7 min/image *(projected; may not be achievable until SKY26c; this is a technology demonstration, not a usable image generator on SKY26b)*  
**Quantization recipe**:
- SDXS UNet encoder/decoder blocks: NF4 per-group-64
- Cross-attention (text conditioning): GF16 — extremely precision-sensitive
- Self-attention in resblocks: NF4 per-group-64
- ResNet conv layers: NF4
- VAE encoder (inference only, not needed at runtime): skip
- VAE decoder (latent → pixel): Posit16 for final conv output
- CLIP text encoder: NF4 (same as model #18 approach, streamed separately)
- Timestep embedding MLP: GF16

**Source ONNX**: [IDKiro/sdxs on HuggingFace](https://huggingface.co/IDKiro/sdxs-512-dreamshaper) — ONNX export via `diffusers.export_to_onnx`; custom pruning script required to reduce to ~200 M param sub-graph  
**License**: Apache-2.0 (SDXS base)  
**Status**: PLANNED (SKY26c dependency; demo checkpoint only)  
**Notebook**: trinity-hub.io/models/24/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~1.5 fps (20 steps) FP16 TensorRT.  
Trinity SKY26c simulator projection: ~0.05–0.1 fps (demo). FID ≤ 30 on COCO-30K subset acceptable for demo quality.

> **Warning**: This entry is a technology demonstration that the Trinity Compiler pipeline
> can ingest and tile a diffusion model. It is **not a production inference target** on any
> current Trinity silicon. Customer-facing image generation must use GPU or Hailo class
> hardware.

---

### 25. ESRGAN-Small (Super-Resolution)
**Params**: 16.7 M  
**Target tile**: gamma + streaming  
**Format**: NF4 RRDB blocks; Posit16 final upsampling conv  
**Memory**: ~16.7 M × 2 B = ~33.4 MB FP32 → ~4.2 MB NF4 (borderline gamma on-chip; streaming for safety)  
**Expected throughput**: ~2–3 fps @ 128×128 → 512×512 (4× upscale) *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- RRDB blocks (23 × Residual-in-Residual Dense Blocks): NF4 per-group-64
- Dense connections within RRDB: GF16 (residual path summation precision)
- Upsampling conv layers (pixel-shuffle × 2): Posit16 — output quality critical
- LeakyReLU activations: GF4
- Trunk conv: NF4 per-channel
- HRconv + final conv: Posit16

**Source ONNX**: [xinntao/Real-ESRGAN on HuggingFace](https://huggingface.co/ai-forever/Real-ESRGAN) / [GitHub](https://github.com/xinntao/Real-ESRGAN) — ONNX export: `python inference_realesrgan.py --onnx_export`  
**License**: BSD-3-Clause  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/25/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~12 fps @ 128→512 FP16.  
Trinity simulator projection: ~2–3 fps on gamma + streaming. PSNR ≥ 27.5 dB on DIV2K val required; SSIM ≥ 0.78.

---

### 26. U-Net-256 (Medical / General Segmentation)
**Params**: 31.0 M  
**Target tile**: gamma + streaming  
**Format**: NF4 encoder/decoder; GF16 skip connections; Posit16 output sigmoid/softmax  
**Memory**: ~31 M × 2 B = ~62 MB FP32 → ~7.8 MB NF4 (streamed from SPI)  
**Expected throughput**: ~5–6 fps @ 256×256 *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- Encoder path (5 × double-conv blocks, 64–512 channels): NF4 per-group-64
- Max-pooling layers: no parameters, pass-through
- Bottleneck (double-conv, 1024 channels): NF4 per-channel
- Skip connection feature maps (concatenation): GF16 at concat point to preserve spatial detail
- Decoder path (5 × upsample + double-conv): NF4 per-group-64
- Final 1×1 conv (n_classes output): Posit16
- BN layers: GF16; ReLU: GF4

**Source ONNX**: [milesial/Pytorch-UNet on GitHub](https://github.com/milesial/Pytorch-UNet) — `torch.onnx.export(unet_model, dummy_input, "unet256.onnx", opset_version=17)`  
**License**: GPL-3.0  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/26/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~28 fps @ 256×256 FP16.  
Trinity simulator projection: ~5–6 fps on gamma + streaming. Dice coefficient ≥ 0.88 on Carvana dataset required.

---

### 27. MaskRCNN-FPN (Lightweight)
**Params**: TBD (lightweight variant; estimated 20–35 M after pruning)  
**Target tile**: gamma + streaming (SKY26b); **SKY26c-target** for acceptable throughput  
**Format**: NF4 FPN backbone + heads; GF16 RoI features; Posit16 mask output  
**Memory**: TBD — estimated ~5–8 MB NF4 after pruning  
**Expected throughput**: ~3–4 fps @ 640×480 *(projected, simulator estimate, pending silicon — below 10 fps acceptance threshold; optimisation and/or SKY26c required)*  
**Quantization recipe**:
- ResNet-50-FPN backbone (or lighter MobileNetV3 backbone for preferred variant): NF4 per-group-64
- FPN lateral + output convs: NF4 per-channel
- RPN (region proposal network) convs: NF4
- RoI Align operation: Posit16 (bilinear interpolation, precision-sensitive)
- Box regression head FC layers: NF4 with Posit16 output
- Mask head (5 × conv + deconv): NF4; Posit16 final sigmoid
- Class prediction FC: Posit16

**Source ONNX**: [facebookresearch/detectron2 ONNX export](https://github.com/facebookresearch/detectron2); see [Detectron2 ONNX tracing guide](https://detectron2.readthedocs.io/en/latest/tutorials/deployment.html)  
**License**: Apache-2.0  
**Status**: PLANNED (TBD param count — lightweight variant to be finalised)  
**Notebook**: trinity-hub.io/models/27/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~12 fps @ 640×480 lightweight variant FP16.  
Trinity simulator projection: ~3–4 fps on gamma + streaming. COCO AP box ≥ 35.0 / AP mask ≥ 32.0 required.

---

## Reinforcement Learning Models (28–30)

---

### 28. PPO Actor-Critic (Atari)
**Params**: 1.0 M  
**Target tile**: euler (fits on-chip fully)  
**Format**: INT8 conv + LSTM; Posit16 policy/value heads  
**Memory**: ~1 MB FP32 → ~250 KB INT8 (well within euler)  
**Expected throughput**: ~900–1 200 inference steps/s *(projected, simulator estimate, pending silicon — environment step rate, not model throughput, is the typical deployment bottleneck)*  
**Quantization recipe**:
- CNN feature extractor (3 conv layers, 84×84 → 512): INT8 symmetric per-channel
- LSTM (512 hidden, 2 layers): INT8 per-group-64; hidden state retained in GF16 between steps
- Policy head (linear → action logits): Posit16
- Value head (linear → scalar): Posit16
- ReLU activations: GF4

**Source ONNX**: [stable-baselines3 PPO Atari export](https://github.com/DLR-RM/stable-baselines3) — `model.policy.to_onnx("ppo_atari.onnx")`; also [cleanrl Atari PPO](https://github.com/vwxyzjn/cleanrl)  
**License**: MIT  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/28/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~8 000 inference steps/s FP16 (GPU).  
Trinity euler simulator projection: ~900–1 200 steps/s. Mean episode return on Breakout ≥ 380 required (within 5% of float32 agent performance).

---

### 29. DQN (Atari / Deep Q-Network)
**Params**: 1.7 M  
**Target tile**: euler (fits on-chip)  
**Format**: INT8 conv layers; Posit16 Q-value output  
**Memory**: ~1.7 MB FP32 → ~425 KB INT8 (fits euler with comfortable margin)  
**Expected throughput**: ~800–950 inference steps/s *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- CNN trunk (3 conv: 8×8/4, 4×4/2, 3×3/1 → 512 FC): INT8 symmetric per-channel
- FC layer (512 → 512): INT8
- Q-value output layer (512 → n_actions): Posit16 — Q-value magnitude matters for policy
- ReLU activations: GF4

**Source ONNX**: [stable-baselines3 DQN ONNX export](https://github.com/DLR-RM/stable-baselines3); original architecture: [DeepMind DQN Nature 2015](https://www.nature.com/articles/nature14236)  
**License**: MIT  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/29/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~6 000 inference steps/s FP16.  
Trinity euler simulator projection: ~800–950 steps/s. Atari Human Normalised Score (HNS) ≥ 95% of float32 agent performance required.

---

### 30. SAC Actor (Continuous Control)
**Params**: 1.5 M (actor network only; critics not needed at deployment time)  
**Target tile**: euler (fits on-chip)  
**Format**: NF4 hidden layers; Posit16 mean/log-std output  
**Memory**: ~1.5 MB FP32 → ~375 KB NF4 (fits euler)  
**Expected throughput**: ~1 200–1 500 inference steps/s *(projected, simulator estimate, pending silicon)*  
**Quantization recipe**:
- Actor MLP: 3 × linear layers (obs_dim → 256 → 256 → 2×action_dim): NF4 per-channel
- Squashed Gaussian output: mean → Posit16; log_std → Posit16 (policy precision critical)
- Layer normalisation (if used): GF16
- Tanh squashing: GF4 piecewise approx (LUT of 256 points)
- Note: critic networks (2 × Q-networks) are trained but not exported for deployment

**Source ONNX**: [stable-baselines3 SAC export](https://github.com/DLR-RM/stable-baselines3) — `model.actor.to_onnx("sac_actor.onnx")`; also [REDQ/SAC gymnasium export](https://github.com/zhihanyang2022/pytorch-sac)  
**License**: MIT  
**Status**: PLANNED  
**Notebook**: trinity-hub.io/models/30/notebook.ipynb (placeholder)  
**Reference benchmark**: Jetson Orin Nano Super — ~10 000 inference steps/s FP16.  
Trinity euler simulator projection: ~1 200–1 500 steps/s. MuJoCo HalfCheetah episode return ≥ 10 000 (within 3% of float32 actor) required for verification.

---

## Timeline

| Phase   | Month | Models | Category                          | Key Milestone                                                            |
|---------|-------|--------|-----------------------------------|--------------------------------------------------------------------------|
| Phase 1 | 1     | 01–06  | CV (detection, classification, segmentation) | 6 smaller CV models PORTED; YOLOv11n first silicon-signed receipt        |
| Phase 1 | 1–2   | 07–10  | CV (pose, seg, detection)         | EfficientDet-Lite0 + PoseNet VERIFIED on gamma                           |
| Phase 2 | 2     | 11–15  | Audio/Speech                      | KWS CNN VERIFIED on phi; Whisper-tiny streaming simulator benchmark published |
| Phase 2 | 2–3   | 16–23  | NLP/LLM                           | BitNet b1.58 700M PORTED; DistilBERT streaming benchmark; ternary compiler support confirmed |
| Phase 3 | 3     | 24–27  | Generative/Other                  | ESRGAN-small PORTED; U-Net PORTED; SD-XS demo on SKY26c simulator        |
| Phase 3 | 3     | 28–30  | RL                                | All 3 RL models VERIFIED on euler                                        |

**Note on timing**: The above timeline assumes Trinity DevKit Pro units with silicon are available
from tape-out (2026-12-16). PORTING milestone = compiler accepts model and emits valid trinity-rtl.
VERIFIED milestone = physical silicon run with receipts. All Phase 1–3 work prior to tape-out
will be on cycle-accurate RTL simulation only; throughput claims remain projections.

**Key dependencies**:
- SKY26c simulator: required for models #04, #18, #24 production targets
- SPI streaming DMA driver v2: required for throughput improvements on #11, #13, #14, #19–21
- BitNet 1.58 ternary packing format in Trinity Compiler: required before Phase 2 NLP work begins
- Trinity Compiler sensitivity analysis tool: must reach v0.3 before Phase 1 verification

---

## Owner Table

> All assignments TBD pending team formation. Estimate: 1 engineer-week per model for
> PORTING + VERIFIED status, assuming compiler toolchain is stable.

| #  | Model               | Category   | Owner (TBD) | Est. weeks | Dependencies                      |
|----|---------------------|------------|-------------|------------|-----------------------------------|
| 01 | YOLOv11n            | CV         | TBD         | 1.0        | Compiler v0.3                     |
| 02 | MobileViT-Small     | CV         | TBD         | 1.0        | Compiler v0.3                     |
| 03 | EfficientNet-B0     | CV         | TBD         | 0.5        | Shares recipe with #10            |
| 04 | ResNet-50           | CV         | TBD         | 0.5        | SKY26c simulator                  |
| 05 | FaceNet             | CV         | TBD         | 1.5        | Streaming DMA driver              |
| 06 | MobileNetV3-Small   | CV         | TBD         | 0.5        | —                                 |
| 07 | YOLOv8n-Pose        | CV         | TBD         | 1.0        | Pose head Posit16 support         |
| 08 | DeepLabV3+          | CV         | TBD         | 1.5        | ASPP dilation GF16 compiler       |
| 09 | PoseNet             | CV         | TBD         | 1.0        | —                                 |
| 10 | EfficientDet-Lite0  | CV         | TBD         | 1.0        | Shares backbone w/ #03            |
| 11 | Whisper-tiny        | Audio      | TBD         | 2.0        | Streaming DMA; split-graph export |
| 12 | Tacotron-2 enc      | Audio      | TBD         | 1.5        | LSTM stateful export              |
| 13 | WaveNet small       | Audio      | TBD         | 1.5        | Autoregressive loop handling      |
| 14 | RNN-T small         | Audio      | TBD         | 2.0        | Streaming chunk-wise pipeline     |
| 15 | KWS CNN             | Audio      | TBD         | 0.5        | phi tile driver                   |
| 16 | DistilBERT-base     | NLP        | TBD         | 1.5        | Streaming DMA v2                  |
| 17 | T5-small            | NLP        | TBD         | 1.5        | Seq2seq ONNX pipeline             |
| 18 | CLIP-ViT-Base/32    | NLP/Vision | TBD         | 1.5        | SKY26c simulator                  |
| 19 | Llama-3.2-1B tern   | LLM        | TBD         | 2.5        | Ternary packing in compiler       |
| 20 | BitNet b1.58 700M   | LLM        | TBD         | 2.0        | Ternary packing; reference impl   |
| 21 | TinyLlama ternary   | LLM        | TBD         | 1.5        | Depends on #19/#20 toolchain      |
| 22 | MobileBERT          | NLP        | TBD         | 1.0        | —                                 |
| 23 | MiniLM-L6           | NLP        | TBD         | 1.0        | —                                 |
| 24 | SD-XS demo          | Generative | TBD         | 3.0        | SKY26c simulator; pruning script  |
| 25 | ESRGAN-small        | Generative | TBD         | 1.5        | Streaming DMA                     |
| 26 | U-Net-256           | Generative | TBD         | 1.5        | Streaming DMA                     |
| 27 | MaskRCNN-FPN lite   | Generative | TBD         | 2.0        | TBD param count; RoI Align op     |
| 28 | PPO Atari           | RL         | TBD         | 1.0        | LSTM stateful export              |
| 29 | DQN Atari           | RL         | TBD         | 0.5        | —                                 |
| 30 | SAC continuous      | RL         | TBD         | 0.5        | Tanh squashing LUT                |

**Total**: ~40 engineer-weeks ≈ 2 engineers × 20 weeks (≈ 5 months); compressible to ~3 months with 3 engineers.

---

## References

1. [HuggingFace Model Hub](https://huggingface.co/models) — primary source for model weights and ONNX export scripts
2. [ONNX Model Zoo — GitHub](https://github.com/onnx/models) — curated pretrained ONNX models with validation scripts
3. [BitNet b1.58 paper — arXiv:2402.17764](https://arxiv.org/abs/2402.17764) — "The Era of 1-bit LLMs: All Large Language Models are in 1.58 Bits", Ma et al., 2024
4. [microsoft/BitNet — GitHub](https://github.com/microsoft/BitNet) — official BitNet reference implementation and ternary conversion tooling
5. Trinity Compiler documentation — see [SOFTWARE_STACK_PLAN.md](/tmp/depin_gaps/SOFTWARE_STACK_PLAN.md) (prior art in this workspace)
6. [Ultralytics YOLO — GitHub](https://github.com/ultralytics/ultralytics) — YOLOv8/v11 ONNX export tooling
7. [optimum — HuggingFace](https://github.com/huggingface/optimum) — ONNX export for transformer models
8. [NVIDIA NeMo — GitHub](https://github.com/NVIDIA/NeMo) — RNN-T, Tacotron-2 ONNX export
9. [stable-baselines3 — GitHub](https://github.com/DLR-RM/stable-baselines3) — RL model ONNX export
10. [Detectron2 — GitHub](https://github.com/facebookresearch/detectron2) — MaskRCNN deployment guide
11. [Real-ESRGAN — GitHub](https://github.com/xinntao/Real-ESRGAN) — ESRGAN-small ONNX export
12. Zenodo DOI: [10.5281/zenodo.XXXXXXX](https://zenodo.org/records/) — Trinity Model Zoo release archive (placeholder; DOI to be registered at first VERIFIED model)
13. [openai/whisper — GitHub](https://github.com/openai/whisper) — Whisper model architecture and ONNX export
14. [ARM ML-examples keyword spotting — GitHub](https://github.com/ARM-software/ML-examples/tree/master/tflu-kws-cortex-m) — KWS CNN reference
15. [sentence-transformers/all-MiniLM-L6-v2 — HuggingFace](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2)
16. [milesial/Pytorch-UNet — GitHub](https://github.com/milesial/Pytorch-UNet) — U-Net-256 architecture
17. [cleanrl — GitHub](https://github.com/vwxyzjn/cleanrl) — RL Atari benchmark implementations
18. [IDKiro/sdxs — HuggingFace](https://huggingface.co/IDKiro/sdxs-512-dreamshaper) — SDXS demo diffusion model
19. [tf2onnx — GitHub](https://github.com/onnx/tensorflow-onnx) — TensorFlow → ONNX conversion tooling

---

*All throughput figures are **simulator projections** derived from the Trinity v1.0 measured
performance ceiling of ~1 GOPS @ ~50 MHz @ ~1 W in ternary mode (full-triad). This ceiling
is itself projected pending tape-out (2026-12-16). Figures labelled "(projected, simulator
estimate, pending silicon)" throughout will be replaced with physical measurements as
DevKit Pro units become available.*

*Mainstream ML workloads requiring real-time throughput should use Jetson Orin Nano Super
or Hailo-8 until Trinity reaches a production process node. Trinity's value on SKY26b is
compiler validation, quantisation recipe development, and silicon-signed inference receipts —
not throughput competition.*

*Silicon-signed inference receipts will be published to `github.com/trinity-model-zoo/verified/`
as models reach VERIFIED status on physical silicon.*
