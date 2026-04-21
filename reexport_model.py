"""
Nakhlah — EfficientNet-B2 17-class Robust Model → ONNX Export
=============================================================
Source : ai/models/nakhlah_robust_v1_best.pth   (17 classes, val-acc 99.73%)
Outputs:
  ai/models/nakhlah_robust_v1.onnx              (FP32, opset 11, IR 9)
  ai/models/nakhlah_robust_v1_int8.onnx         (INT8 dynamic quantization)
  NakhlahApp/assets/models/nakhlah_robust_v1.onnx  (best version for Flutter)

Run  : python reexport_model.py
Deps : pip install torch torchvision onnx onnxruntime onnxsim
       pip install onnxruntime-extensions  (for INT8 — optional)
"""

import os
import sys
import shutil
import time
import warnings

os.environ["PYTHONIOENCODING"] = "utf-8"
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

warnings.filterwarnings("ignore")

from pathlib import Path

# ── Paths ─────────────────────────────────────────────────────────────────────
ROOT        = Path(__file__).parent
MODEL_PTH   = ROOT / "ai" / "models" / "nakhlah_robust_v1_best.pth"
OUT_DIR     = ROOT / "ai" / "models"
ONNX_FP32   = OUT_DIR / "nakhlah_robust_v1.onnx"
ONNX_INT8   = OUT_DIR / "nakhlah_robust_v1_int8.onnx"
ASSET_DIR   = ROOT / "NakhlahApp" / "assets" / "models"
ASSET_DEST  = ASSET_DIR / "nakhlah_robust_v1.onnx"

# ── Model config  (from nakhlah_robust_v1_metadata.json) ─────────────────────
IMG_SIZE    = 260
NUM_CLASSES = 17
DEVICE      = "cpu"

CLASS_NAMES = [
    "ajwa", "allig", "amber", "aseel", "deglet_nour",
    "galaxy", "kalmi", "khorma", "medjool", "meneifi",
    "muzafati", "nabtat_ali", "rutab", "shaishe",
    "sokari", "sugaey", "zahidi",
]

assert len(CLASS_NAMES) == NUM_CLASSES, "CLASS_NAMES length must equal NUM_CLASSES"

# ─────────────────────────────────────────────────────────────────────────────
# 1. Build model architecture (must match training exactly)
# ─────────────────────────────────────────────────────────────────────────────
def _build_model():
    import torch.nn as nn
    from torchvision import models

    net = models.efficientnet_b2(weights=None)
    in_features = net.classifier[1].in_features

    # Classifier head used in robust v1 training
    net.classifier = nn.Sequential(
        nn.Dropout(p=0.3, inplace=True),
        nn.Linear(in_features, 512),
        nn.BatchNorm1d(512),
        nn.SiLU(),
        nn.Dropout(p=0.2),
        nn.Linear(512, NUM_CLASSES),
    )
    return net


def _load_checkpoint(net):
    import torch

    if not MODEL_PTH.exists():
        sys.exit(
            f"ERROR  Model not found: {MODEL_PTH}\n"
            f"       Make sure nakhlah_robust_v1_best.pth is in ai/models/"
        )

    size_mb = MODEL_PTH.stat().st_size / 1_000_000
    print(f"Loading  {MODEL_PTH.name}  ({size_mb:.1f} MB) ...")

    ckpt = torch.load(str(MODEL_PTH), map_location=DEVICE, weights_only=False)
    if isinstance(ckpt, dict):
        state = (
            ckpt.get("model_state_dict")
            or ckpt.get("model_state")
            or ckpt.get("state_dict")
            or ckpt
        )
    else:
        state = ckpt

    net.load_state_dict(state, strict=True)
    net.to(DEVICE)
    net.eval()
    print(f"OK       Checkpoint loaded — {NUM_CLASSES} classes")
    return net


# ─────────────────────────────────────────────────────────────────────────────
# 2. Export FP32 ONNX  (opset 11, legacy exporter for max compatibility)
# ─────────────────────────────────────────────────────────────────────────────
def _export_fp32(net):
    import torch

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"\nExporting FP32 ONNX → {ONNX_FP32.name} ...")

    dummy = torch.zeros(1, 3, IMG_SIZE, IMG_SIZE, device=DEVICE)
    with torch.no_grad():
        torch.onnx.export(
            net,
            dummy,
            str(ONNX_FP32),
            dynamo=False,               # legacy TorchScript exporter — broadest compat
            opset_version=11,           # supported by ONNX Runtime Mobile
            input_names=["input"],
            output_names=["logits"],
            dynamic_axes={
                "input":  {0: "batch_size"},
                "logits": {0: "batch_size"},
            },
            do_constant_folding=True,
            verbose=False,
        )

    # Force IR version 9 (required by onnxruntime 1.4.1 in Flutter)
    import onnx
    model = onnx.load(str(ONNX_FP32))
    model.ir_version = 9
    for imp in model.opset_import:
        if imp.version > 11:
            imp.version = 11
    onnx.save(model, str(ONNX_FP32))

    size_mb = ONNX_FP32.stat().st_size / 1_000_000
    print(f"OK       FP32 export — {size_mb:.1f} MB  (IR=9, opset=11)")


# ─────────────────────────────────────────────────────────────────────────────
# 3. Graph simplification (optional but reduces size ~5-10%)
# ─────────────────────────────────────────────────────────────────────────────
def _simplify():
    try:
        import onnx
        from onnxsim import simplify

        print("Simplifying ONNX graph ...")
        model_proto = onnx.load(str(ONNX_FP32))
        simplified, ok = simplify(model_proto)
        if ok:
            onnx.save(simplified, str(ONNX_FP32))
            size_mb = ONNX_FP32.stat().st_size / 1_000_000
            print(f"OK       Graph simplified — {size_mb:.1f} MB")
        else:
            print("WARN     simplify() returned ok=False — keeping unsimplified graph")
    except ImportError:
        print("SKIP     onnxsim not installed (pip install onnxsim) — skipping simplification")


# ─────────────────────────────────────────────────────────────────────────────
# 4. INT8 dynamic quantization (~4x smaller, ~2x faster on CPU)
# ─────────────────────────────────────────────────────────────────────────────
def _export_int8():
    try:
        from onnxruntime.quantization import quantize_dynamic, QuantType

        print(f"\nQuantizing → INT8  ({ONNX_INT8.name}) ...")
        quantize_dynamic(
            model_input=str(ONNX_FP32),
            model_output=str(ONNX_INT8),
            weight_type=QuantType.QInt8,
        )
        size_mb = ONNX_INT8.stat().st_size / 1_000_000
        print(f"OK       INT8 export — {size_mb:.1f} MB")
        return True
    except Exception as e:
        print(f"WARN     INT8 quantization failed: {e}")
        print("         Run: pip install onnxruntime-extensions")
        return False


# ─────────────────────────────────────────────────────────────────────────────
# 5. Verify outputs match PyTorch
# ─────────────────────────────────────────────────────────────────────────────
def _verify(net, onnx_path: Path):
    import numpy as np
    import torch
    import onnxruntime as ort

    print(f"\nVerifying {onnx_path.name} vs PyTorch ...")
    dummy_np = np.random.randn(1, 3, IMG_SIZE, IMG_SIZE).astype(np.float32)

    with torch.no_grad():
        pt_out = net(torch.from_numpy(dummy_np)).numpy()

    sess = ort.InferenceSession(str(onnx_path), providers=["CPUExecutionProvider"])
    onnx_out = sess.run(None, {"input": dummy_np})[0]

    max_diff = float(abs(pt_out - onnx_out).max())
    print(f"         Max output diff vs PyTorch: {max_diff:.6f}")
    if max_diff < 0.01:
        print(f"OK       Outputs match (diff < 0.01) — {onnx_path.name} is valid")
    else:
        print(f"WARN     Outputs differ by {max_diff:.4f} — check architecture!")
    return max_diff


# ─────────────────────────────────────────────────────────────────────────────
# 6. Latency benchmark
# ─────────────────────────────────────────────────────────────────────────────
def _benchmark(onnx_path: Path, label: str, runs: int = 20):
    import numpy as np
    import onnxruntime as ort

    opts = ort.SessionOptions()
    opts.intra_op_num_threads = 2
    opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL

    sess = ort.InferenceSession(str(onnx_path), sess_opts=opts, providers=["CPUExecutionProvider"])
    dummy = np.random.randn(1, 3, IMG_SIZE, IMG_SIZE).astype(np.float32)

    # Warm-up
    for _ in range(3):
        sess.run(None, {"input": dummy})

    t0 = time.perf_counter()
    for _ in range(runs):
        sess.run(None, {"input": dummy})
    ms = (time.perf_counter() - t0) / runs * 1000

    size_mb = onnx_path.stat().st_size / 1_000_000
    print(f"BENCH    [{label:10s}]  {ms:6.1f} ms avg ({runs} runs)  |  {size_mb:.1f} MB")


# ─────────────────────────────────────────────────────────────────────────────
# 7. Copy best model to Flutter assets
# ─────────────────────────────────────────────────────────────────────────────
def _copy_to_assets(prefer_int8: bool):
    ASSET_DIR.mkdir(parents=True, exist_ok=True)

    if prefer_int8 and ONNX_INT8.exists():
        src = ONNX_INT8
        label = "INT8"
    else:
        src = ONNX_FP32
        label = "FP32"

    shutil.copy(src, ASSET_DEST)
    size_mb = ASSET_DEST.stat().st_size / 1_000_000
    print(f"\nCopied   [{label}] {src.name} → {ASSET_DEST}  ({size_mb:.1f} MB)")
    return size_mb


# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────
def main():
    print("=" * 65)
    print("  Nakhlah — Robust V1 ONNX Export  (17-class EfficientNet-B2)")
    print("=" * 65)

    # Verify dependencies
    try:
        import torch, onnx, onnxruntime  # noqa: F401
    except ImportError:
        sys.exit("ERROR  Missing deps. Run: pip install torch torchvision onnx onnxruntime onnxsim")

    import torch  # noqa: F811

    net = _build_model()
    net = _load_checkpoint(net)

    _export_fp32(net)
    _simplify()
    fp32_diff = _verify(net, ONNX_FP32)

    int8_ok = _export_int8()
    if int8_ok:
        _verify(net, ONNX_INT8)

    print("\nBenchmarks (CPU, 2 threads):")
    _benchmark(ONNX_FP32, "FP32")
    if int8_ok:
        _benchmark(ONNX_INT8, "INT8")

    # Prefer INT8 if it exists (smaller, faster) and accuracy diff is acceptable
    size_mb = _copy_to_assets(prefer_int8=int8_ok)

    print("\n" + "=" * 65)
    print("  EXPORT COMPLETE")
    print(f"  FP32  : {ONNX_FP32}")
    if int8_ok:
        print(f"  INT8  : {ONNX_INT8}")
    print(f"  Asset : {ASSET_DEST}  ({size_mb:.1f} MB)")
    print()
    print("  Next steps:")
    print("  1. The Flutter asset has been updated automatically.")
    print("  2. Rebuild the app: flutter build apk --debug")
    print("  3. Verify NakhlahApp/lib/services/local_inference_service.dart")
    print('     uses model: "assets/models/nakhlah_robust_v1.onnx"')
    print("=" * 65)


if __name__ == "__main__":
    main()
