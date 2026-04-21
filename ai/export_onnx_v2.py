"""
Nakhlah — EfficientNet-B2 → ONNX Export (17 Classes)
=====================================================
Model  : nakhlah_robust_v1_best.pth
Output : assets/models/
         - nakhlah_v2.onnx
         - nakhlah_v2_int8.onnx
"""

import os
import sys
import time
import torch
import torch.nn as nn
from torchvision import models
from pathlib import Path

# ─────────────────────────────────────────────
# Config
# ─────────────────────────────────────────────

SRC_DIR   = Path(__file__).parent
MODEL_PTH = SRC_DIR / "models" / "nakhlah_robust_v1_best.pth"
OUT_DIR   = SRC_DIR / "assets" / "models"

ONNX_FP32 = OUT_DIR / "nakhlah_v2.onnx"
ONNX_INT8 = OUT_DIR / "nakhlah_v2_int8.onnx"

IMG_SIZE = 260
NUM_CLASSES = 17
DEVICE = torch.device("cpu")

CLASS_NAMES = [
    "Ajwa", "Allig", "Amber", "Aseel", "Deglet_Nour",
    "Galaxy", "Kalmi", "Khorma", "Medjool", "Meneifi",
    "Muzafati", "Nabtat_Ali", "Rutab", "Shaishe",
    "Sokari", "Sugaey", "Zahidi",
]

# ─────────────────────────────────────────────
# Model
# ─────────────────────────────────────────────

def build_model():
    net = models.efficientnet_b2(weights=None)
    in_features = net.classifier[1].in_features

    net.classifier = nn.Sequential(
        nn.Dropout(0.3),
        nn.Linear(in_features, 512),
        nn.BatchNorm1d(512),
        nn.SiLU(),
        nn.Dropout(0.2),
        nn.Linear(512, NUM_CLASSES),
    )
    return net


def load_model(net):
    if not MODEL_PTH.exists():
        sys.exit(f"Model not found: {MODEL_PTH}")

    print(f"Loading {MODEL_PTH.name}")

    ckpt = torch.load(MODEL_PTH, map_location=DEVICE, weights_only=False)

    state = (
        ckpt.get("model_state_dict")
        or ckpt.get("state_dict")
        or ckpt.get("model_state")
        or ckpt
    )

    net.load_state_dict(state, strict=True)
    net.eval()
    return net      




# ─────────────────────────────────────────────
# Export FP32 ONNX
# ─────────────────────────────────────────────

def export_fp32(net):
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    dummy = torch.randn(1, 3, IMG_SIZE, IMG_SIZE)

    print("Exporting FP32 ONNX...")

    torch.onnx.export(
        net,
        dummy,
        str(ONNX_FP32),
        opset_version=17,
        input_names=["input"],
        output_names=["logits"],
        dynamic_axes={
            "input": {0: "batch"},
            "logits": {0: "batch"}
        },
        do_constant_folding=True,
    )

    print("FP32 exported:", ONNX_FP32)


# ─────────────────────────────────────────────
# INT8 Quantization (Flutter Optimized)
# ─────────────────────────────────────────────

def export_int8():
    from onnxruntime.quantization import quantize_dynamic, QuantType

    print("Quantizing INT8...")

    quantize_dynamic(
        str(ONNX_FP32),
        str(ONNX_INT8),
        weight_type=QuantType.QInt8,
    )

    print("INT8 exported:", ONNX_INT8)


# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

def main():
    net = build_model()
    net = load_model(net)

    export_fp32(net)
    export_int8()

    print("\nDONE ✔")
    print("Put this in Flutter:")
    print("assets/models/nakhlah_v2_int8.onnx")


if __name__ == "__main__":
    main()