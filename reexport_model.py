"""
Re-export nakhlah EfficientNet-B2 cleanly from .pth weights.
Uses the LEGACY torch.onnx exporter (dynamo=False) for opset=11 compatibility.
"""
import os
import sys

# Fix Windows console encoding
os.environ["PYTHONIOENCODING"] = "utf-8"
sys.stdout.reconfigure(encoding="utf-8")

from pathlib import Path
import numpy as np
import torch
import torch.nn as nn
from torchvision import models

MODEL_PTH = Path("ai/models/nakhlah_model_v2_final.pth")
OUT_ONNX  = Path("ai/models/nakhlah_v2_opset11.onnx")
ASSET_DST = Path("NakhlahApp/assets/models/nakhlah_v2_compat.onnx")

NUM_CLASSES = 9
IMG_SIZE    = 260

# ── 1. Build model ────────────────────────────────────────────────────────────
def build():
    net = models.efficientnet_b2(weights=None)
    in_f = net.classifier[1].in_features
    net.classifier = nn.Sequential(
        nn.Dropout(p=0.3, inplace=True),
        nn.Linear(in_f, 512),
        nn.BatchNorm1d(512),
        nn.SiLU(),
        nn.Dropout(p=0.2),
        nn.Linear(512, NUM_CLASSES),
    )
    return net

print("Loading checkpoint...")
net = build()
ckpt = torch.load(MODEL_PTH, map_location="cpu", weights_only=False)
state = (ckpt.get("model_state_dict") or ckpt.get("model_state")
         or ckpt.get("state_dict") or ckpt) if isinstance(ckpt, dict) else ckpt
net.load_state_dict(state, strict=True)
net.eval()
print("Checkpoint loaded OK")

# ── 2. Export with LEGACY exporter (dynamo=False) + opset=11 ──────────────────
print(f"Exporting to {OUT_ONNX} (opset=11, legacy exporter) ...")
dummy = torch.zeros(1, 3, IMG_SIZE, IMG_SIZE)

import warnings
warnings.filterwarnings("ignore")

with torch.no_grad():
    torch.onnx.export(
        net,
        dummy,
        str(OUT_ONNX),
        dynamo=False,               # CRITICAL: use proven legacy TorchScript-based exporter
        opset_version=11,
        input_names=["input"],
        output_names=["logits"],
        dynamic_axes={"input": {0: "batch_size"}, "logits": {0: "batch_size"}},
        do_constant_folding=True,
        verbose=False,
    )

size_mb = OUT_ONNX.stat().st_size / 1e6
print(f"Exported: {size_mb:.1f} MB")

# ── 3. Inspect and verify ─────────────────────────────────────────────────────
import onnx
import onnxruntime as ort

m = onnx.load(str(OUT_ONNX))
print(f"IR version : {m.ir_version}")
print(f"Opset      : {m.opset_import[0].version}")

print("Running inference with onnxruntime...")
sess = ort.InferenceSession(str(OUT_ONNX), providers=["CPUExecutionProvider"])
dummy_np = np.random.randn(1, 3, IMG_SIZE, IMG_SIZE).astype(np.float32)
out = sess.run(None, {"input": dummy_np})
print(f"Output shape: {out[0].shape}  -- OK")

# Compare with PyTorch
with torch.no_grad():
    pt_out = net(torch.from_numpy(dummy_np)).numpy()
diff = float(abs(pt_out - out[0]).max())
print(f"Max diff vs PyTorch: {diff:.6f}  -- {'OK' if diff < 0.01 else 'WARNING HIGH'}")

# ── 4. Copy to Flutter assets ─────────────────────────────────────────────────
import shutil
ASSET_DST.parent.mkdir(parents=True, exist_ok=True)
shutil.copy(OUT_ONNX, ASSET_DST)
dst_size = ASSET_DST.stat().st_size / 1e6
print(f"Copied to assets: {ASSET_DST.name} ({dst_size:.1f} MB)")
print()
print("SUCCESS -- Update local_inference_service.dart to use: nakhlah_v2_compat.onnx")
