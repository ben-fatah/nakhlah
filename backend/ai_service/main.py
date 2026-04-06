"""
ai_service/main.py
Standalone FastAPI microservice that loads nakhlah_model_v1.pth
and serves POST /predict  →  classification result.

Preprocessing matches the notebook exactly:
  Resize(256) → CenterCrop(224) → ToTensor() → Normalize(ImageNet)
"""

import io
import os
import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
from fastapi import FastAPI, File, UploadFile, HTTPException, status

# ── Config ──────────────────────────────────────────────────────────────────
MODEL_PATH = os.environ.get("MODEL_PATH", "models/nakhlah_model_v1.pth")
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

CLASS_NAMES = [
    "Ajwa",
    "Galaxy",
    "Medjool",
    "Meneifi",
    "Nabtat Ali",
    "Rutab",
    "Shaishe",
    "Sokari",
    "Sugaey",
]
NUM_CLASSES = len(CLASS_NAMES)  # 9

# ── Preprocessing (mirrors test_transform from notebook) ────────────────────
PREPROCESS = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225],
    ),
])

# ── Model ───────────────────────────────────────────────────────────────────
def load_model() -> nn.Module:
    model = models.efficientnet_b0(weights=None)
    model.classifier[1] = nn.Linear(model.classifier[1].in_features, NUM_CLASSES)
    state = torch.load(MODEL_PATH, map_location=DEVICE)
    model.load_state_dict(state)
    model.to(DEVICE)
    model.eval()
    return model


print(f"Loading model from {MODEL_PATH} on {DEVICE} ...")
_model = load_model()
print("Model ready.")

# ── App ─────────────────────────────────────────────────────────────────────
app = FastAPI(title="Nakhlah AI Service", version="1.0.0")


@app.get("/health")
def health():
    return {"status": "ok", "device": str(DEVICE)}


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    # Read & decode image
    raw = await file.read()
    try:
        img = Image.open(io.BytesIO(raw)).convert("RGB")
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Could not decode image",
        )

    # Preprocess
    tensor = PREPROCESS(img).unsqueeze(0).to(DEVICE)  # [1, 3, 224, 224]

    # Inference
    with torch.no_grad():
        logits = _model(tensor)                        # [1, 9]
        probs = torch.softmax(logits, dim=1)[0]        # [9]

    # Build response
    all_preds = [
        {
            "label": CLASS_NAMES[i],
            "confidence": round(float(probs[i]), 4),
            "class_index": i,
        }
        for i in range(NUM_CLASSES)
    ]
    all_preds.sort(key=lambda x: x["confidence"], reverse=True)
    top = all_preds[0]

    return {
        "top": top,
        "all_predictions": all_preds,
    }
