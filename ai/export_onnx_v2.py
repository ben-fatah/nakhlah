"""
Nakhlah — EfficientNet-B2 → ONNX Export Script
================================================
Model  : nakhlah_model_v2_final.pth
Output : models/nakhlah_v2.onnx (+ nakhlah_v2_int8.onnx)
Run    : python export_onnx_v2.py

Requirements:
    pip install torch==2.2.2 torchvision==0.17.2 onnx onnxruntime onnxsim
"""

import os
import sys
import time
import torch
import torch.nn as nn
from torchvision import models
from pathlib import Path

# ── 0. Verify onnx / onnxsim are installed ────────────────────────────────────
try:
    import onnx
    import onnxruntime as ort
except ImportError:
    sys.exit("❌  Run: pip install onnx onnxruntime onnxsim")

# ── 1. Configuration ──────────────────────────────────────────────────────────

SRC_DIR   = Path(__file__).parent
MODEL_PTH = SRC_DIR / "models" / "nakhlah_model_v2_final.pth"
OUT_DIR   = SRC_DIR / "models"
ONNX_FP32 = OUT_DIR / "nakhlah_v2.onnx"
ONNX_INT8  = OUT_DIR / "nakhlah_v2_int8.onnx"

IMG_SIZE    = 260   # trained at 260 — keep for accuracy
NUM_CLASSES = 9
DEVICE      = torch.device("cpu")

CLASS_NAMES = [
    "Ajwa", "Galaxy", "Medjool", "Meneifi",
    "Nabtat Ali", "Rutab", "Shaishe", "Sokari", "Sugaey",
]

# ── 2. Rebuild model architecture (must match training) ───────────────────────

def build_model() -> nn.Module:
    net = models.efficientnet_b2(weights=None)
    in_features = net.classifier[1].in_features
    net.classifier = nn.Sequential(
        nn.Dropout(p=0.3, inplace=True),
        nn.Linear(in_features, 512),
        nn.BatchNorm1d(512),
        nn.SiLU(),
        nn.Dropout(p=0.2),
        nn.Linear(512, NUM_CLASSES),
    )
    return net


def load_checkpoint(net: nn.Module) -> nn.Module:
    if not MODEL_PTH.exists():
        sys.exit(f"❌  Model not found: {MODEL_PTH}")

    size_mb = MODEL_PTH.stat().st_size / 1_000_000
    print(f"📦  Loading: {MODEL_PTH.name}  ({size_mb:.1f} MB)")

    ckpt = torch.load(MODEL_PTH, map_location=DEVICE, weights_only=False)
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
    print(f"✅  Checkpoint loaded — {NUM_CLASSES} classes")
    return net


# ── 3. Export FP32 ONNX ───────────────────────────────────────────────────────

def export_fp32(net: nn.Module) -> None:
    import onnx
    from onnx import helper

    dummy = torch.zeros(1, 3, IMG_SIZE, IMG_SIZE, device=DEVICE)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"\n🔄  Exporting ONNX → {ONNX_FP32.name}")

    with torch.no_grad():
        torch.onnx.export(
            net,
            dummy,
            str(ONNX_FP32),
            opset_version=17,
            input_names=["input"],
            output_names=["logits"],
            dynamic_axes={
                "input":  {0: "batch_size"},
                "logits": {0: "batch_size"},
            },
            do_constant_folding=True,
        )

    size_mb = ONNX_FP32.stat().st_size / 1_000_000
    print(f"✅ Export done: {ONNX_FP32.name} — {size_mb:.1f} MB")

def downgrade_ir() -> None:
    print(f"\n🔄 Downgrading IR version to 9 for ONNXRuntime 1.4.1 compat")
    import onnx
    model = onnx.load(str(ONNX_FP32))
    
    # downgrade IR
    model.ir_version = 9
    
    # downgrade opset for compatibility if needed
    for imp in model.opset_import:
        if imp.version > 17:
            imp.version = 17

    onnx.save(model, str(ONNX_FP32))
    print("✅  IR version downgraded to 9")
# ── 4. Graph simplification (onnxsim) ─────────────────────────────────────────

def simplify_graph() -> None:
    try:
        from onnxsim import simplify
        print("🔄  Simplifying ONNX graph …")
        model_proto = onnx.load(str(ONNX_FP32))
        simplified, ok = simplify(model_proto)
        if ok:
            onnx.save(simplified, str(ONNX_FP32))
            size_mb = ONNX_FP32.stat().st_size / 1_000_000
            print(f"✅  Graph simplified  —  {size_mb:.1f} MB")
        else:
            print("⚠️   simplify() returned ok=False — keeping original graph")
    except ImportError:
        print("⚠️   onnxsim not installed — skipping simplification")
        print("     Run: pip install onnxsim")


# ── 5. INT8 Dynamic Quantization ──────────────────────────────────────────────
# Dynamic quant: weights → INT8, activations quantized at runtime.
# No calibration data needed. Reduces model ~4x, inference ~2x faster on CPU.

def export_int8() -> None:
    from onnxruntime.quantization import quantize_dynamic, QuantType

    print(f"\n🔄  Quantizing → INT8  ({ONNX_INT8.name})")
    quantize_dynamic(
        model_input=str(ONNX_FP32),
        model_output=str(ONNX_INT8),
        weight_type=QuantType.QInt8,
    )
    size_mb = ONNX_INT8.stat().st_size / 1_000_000
    print(f"✅  INT8 ONNX exported  —  {size_mb:.1f} MB")


# ── 6. Latency benchmark ──────────────────────────────────────────────────────

def benchmark(onnx_path: Path, label: str, runs: int = 30) -> None:
    import numpy as np

    sess_opts = ort.SessionOptions()
    sess_opts.intra_op_num_threads = 2
    sess_opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL

    sess = ort.InferenceSession(str(onnx_path), sess_opts=sess_opts,
                                providers=["CPUExecutionProvider"])
    inp_name = sess.get_inputs()[0].name
    dummy_np  = np.random.randn(1, 3, IMG_SIZE, IMG_SIZE).astype(np.float32)

    # Warm-up
    for _ in range(5):
        sess.run(None, {inp_name: dummy_np})

    t0 = time.perf_counter()
    for _ in range(runs):
        sess.run(None, {inp_name: dummy_np})
    elapsed_ms = (time.perf_counter() - t0) / runs * 1000

    print(f"⚡  [{label}] avg inference: {elapsed_ms:.1f} ms  ({runs} runs)")


# ── 7. Sanity-check against PyTorch outputs ───────────────────────────────────

def verify_outputs(net: nn.Module) -> None:
    import numpy as np
    print("\n🔬  Verifying ONNX vs PyTorch outputs …")
    dummy_np = np.random.randn(1, 3, IMG_SIZE, IMG_SIZE).astype(np.float32)
    dummy_pt = torch.from_numpy(dummy_np)

    with torch.no_grad():
        pt_out = net(dummy_pt).numpy()

    sess = ort.InferenceSession(str(ONNX_FP32),
                                providers=["CPUExecutionProvider"])
    onnx_out = sess.run(None, {"input": dummy_np})[0]

    max_diff = float(abs(pt_out - onnx_out).max())
    print(f"   Max absolute output diff: {max_diff:.6f}")
    if max_diff < 1e-4:
        print("✅  Outputs match (diff < 1e-4)")
    else:
        print(f"⚠️   Outputs differ by {max_diff:.4f} — check architecture")


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    print("=" * 60)
    print("  Nakhlah ONNX Export — nakhlah_model_v2_final.pth")
    print("=" * 60)

    net = build_model()
    net = load_checkpoint(net)

    export_fp32(net)
    simplify_graph()
    downgrade_ir()
    verify_outputs(net)

    try:
        export_int8()
    except Exception as e:
        print(f"⚠️   INT8 export failed: {e}")
        print("     Install: pip install onnxruntime-extensions")

    print("\n📊  Benchmarks:")
    benchmark(ONNX_FP32, "FP32")
    if ONNX_INT8.exists():
        benchmark(ONNX_INT8, "INT8")

    print("\n" + "=" * 60)
    print("  ✅  Export complete!")
    print(f"     FP32  : {ONNX_FP32}")
    if ONNX_INT8.exists():
        print(f"     INT8  : {ONNX_INT8}")
    print()
    print("  📱  For Flutter: copy nakhlah_v2_int8.onnx")
    print("      (INT8 is ~4x smaller, ~2x faster on CPU)")
    print("=" * 60)


if __name__ == "__main__":
    main()
