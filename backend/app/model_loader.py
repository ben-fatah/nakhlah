"""
Loads the EfficientNet-B2 model ONCE at startup and holds it in memory.
All requests share the same instance — never reload per request.

Model file: nakhlah_robust_v1_best.pth
Architecture: EfficientNet-B2 with custom 6-layer classifier head, 9 classes
"""
import torch
import torch.nn as nn
from torchvision import models
from pathlib import Path
import logging

from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

CLASS_NAMES = [
    "Ajwa", "Galaxy", "Medjool", "Meneifi",
    "Nabtat Ali", "Rutab", "Shaishe", "Sokari", "Sugaey",
]

DATE_METADATA = {
    "Ajwa":       {"nameAr": "عجوة",      "originEn": "Al-Madinah, KSA",  "originAr": "المدينة المنورة، السعودية", "calories": 277, "carbs": 75, "fiber": 7,  "potassium": 696},
    "Galaxy":     {"nameAr": "جالاكسي",   "originEn": "Saudi Arabia",     "originAr": "المملكة العربية السعودية",  "calories": 270, "carbs": 72, "fiber": 6,  "potassium": 650},
    "Medjool":    {"nameAr": "مجدول",     "originEn": "Al-Madinah, KSA",  "originAr": "المدينة المنورة، السعودية", "calories": 277, "carbs": 75, "fiber": 7,  "potassium": 696},
    "Meneifi":    {"nameAr": "مينيفي",    "originEn": "Saudi Arabia",     "originAr": "المملكة العربية السعودية",  "calories": 265, "carbs": 70, "fiber": 5,  "potassium": 620},
    "Nabtat Ali": {"nameAr": "نبتة علي",  "originEn": "Saudi Arabia",     "originAr": "المملكة العربية السعودية",  "calories": 268, "carbs": 71, "fiber": 6,  "potassium": 630},
    "Rutab":      {"nameAr": "رطب",       "originEn": "Gulf Region",      "originAr": "منطقة الخليج",              "calories": 142, "carbs": 38, "fiber": 4,  "potassium": 380},
    "Shaishe":    {"nameAr": "شيشة",      "originEn": "Saudi Arabia",     "originAr": "المملكة العربية السعودية",  "calories": 272, "carbs": 73, "fiber": 6,  "potassium": 655},
    "Sokari":     {"nameAr": "سكري",      "originEn": "Al-Qassim, KSA",   "originAr": "القصيم، السعودية",          "calories": 320, "carbs": 85, "fiber": 8,  "potassium": 720},
    "Sugaey":     {"nameAr": "صقعي",      "originEn": "Riyadh, KSA",      "originAr": "الرياض، السعودية",          "calories": 290, "carbs": 78, "fiber": 7,  "potassium": 680},
}


class NakhlahModel:
    _instance = None

    def __init__(self):
        self.device = torch.device(settings.DEVICE)
        self.model  = self._load()
        self.model.eval()
        logger.info(f"Model ready on {self.device}")

    @classmethod
    def instance(cls) -> "NakhlahModel":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def _load(self) -> nn.Module:
        path = Path(settings.MODEL_PATH)

        if not path.exists():
            raise FileNotFoundError(
                f"\n{'='*60}\n"
                f"MODEL FILE NOT FOUND: {path.resolve()}\n"
                f"{'='*60}\n"
                f"Expected filename : nakhlah_robust_v1_best.pth\n"
                f"Expected location : /app/models/\n"
                f"Current MODEL_PATH: {settings.MODEL_PATH}\n\n"
                f"Fix options:\n"
                f"  1) Rebuild Docker image — Dockerfile downloads model automatically.\n"
                f"  2) Set MODEL_PATH env var on Render dashboard to correct path.\n"
                f"  3) HuggingFace URL (use /resolve/ not /blob/):\n"
                f"     https://huggingface.co/benfatah/NAKHLAH/resolve/main/nakhlah_robust_v1_best.pth\n"
                f"{'='*60}"
            )

        size_mb = path.stat().st_size / 1_000_000
        logger.info(f"Loading model: {path} ({size_mb:.1f} MB)")

        # Guard: reject suspiciously small files (probably a corrupted HTML download)
        if size_mb < 1.0:
            raise ValueError(
                f"Model file at {path} is only {size_mb:.2f} MB — likely corrupted.\n"
                f"Re-download using the /resolve/ HuggingFace URL (not /blob/)."
            )

        net = models.efficientnet_b2(weights=None)
        in_features = net.classifier[1].in_features
        net.classifier = nn.Sequential(
            nn.Dropout(p=0.3, inplace=True),
            nn.Linear(in_features, 512),
            nn.BatchNorm1d(512),
            nn.SiLU(),
            nn.Dropout(p=0.2),
            nn.Linear(512, settings.NUM_CLASSES),
        )

        checkpoint = torch.load(path, map_location=self.device, weights_only=False)

        # Handle both raw state_dict and full checkpoint dicts
        if isinstance(checkpoint, dict):
            state = checkpoint.get("model_state_dict",
                    checkpoint.get("model_state",
                    checkpoint.get("state_dict",
                    checkpoint)))
        else:
            state = checkpoint

        net.load_state_dict(state, strict=True)
        net.to(self.device)
        logger.info(f"Model loaded — {settings.NUM_CLASSES} classes, device={self.device}")
        return net

    @torch.no_grad()
    def predict(self, tensor: torch.Tensor) -> list[dict]:
        tensor = tensor.to(self.device)
        logits = self.model(tensor)
        probs  = torch.softmax(logits, dim=1)[0]
        results = [
            {
                "label":       CLASS_NAMES[i],
                "confidence":  round(float(probs[i]), 4),
                "class_index": i,
            }
            for i in range(len(CLASS_NAMES))
        ]
        return sorted(results, key=lambda x: x["confidence"], reverse=True)