"""
Loads the model ONCE at startup and holds it in memory.
All requests share the same model instance — never reload per request.
"""
import torch
import torch.nn as nn
from torchvision import models
from pathlib import Path
import logging

from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# ── Class names must match the training notebook exactly ──────────────────
CLASS_NAMES = [
    "Ajwa", "Galaxy", "Medjool", "Meneifi",
    "Nabtat Ali", "Rutab", "Shaishe", "Sokari", "Sugaey",
]

# Bilingual metadata returned alongside predictions
DATE_METADATA = {
    "Ajwa":      {"nameAr": "عجوة",      "originEn": "Al-Madinah, KSA",   "originAr": "المدينة المنورة، السعودية", "calories": 277, "carbs": 75, "fiber": 7,  "potassium": 696},
    "Galaxy":    {"nameAr": "جالاكسي",   "originEn": "Saudi Arabia",      "originAr": "المملكة العربية السعودية",  "calories": 270, "carbs": 72, "fiber": 6,  "potassium": 650},
    "Medjool":   {"nameAr": "مجدول",     "originEn": "Al-Madinah, KSA",   "originAr": "المدينة المنورة، السعودية", "calories": 277, "carbs": 75, "fiber": 7,  "potassium": 696},
    "Meneifi":   {"nameAr": "مينيفي",    "originEn": "Saudi Arabia",      "originAr": "المملكة العربية السعودية",  "calories": 265, "carbs": 70, "fiber": 5,  "potassium": 620},
    "Nabtat Ali":{"nameAr": "نبتة علي",  "originEn": "Saudi Arabia",      "originAr": "المملكة العربية السعودية",  "calories": 268, "carbs": 71, "fiber": 6,  "potassium": 630},
    "Rutab":     {"nameAr": "رطب",       "originEn": "Gulf Region",       "originAr": "منطقة الخليج",              "calories": 142, "carbs": 38, "fiber": 4,  "potassium": 380},
    "Shaishe":   {"nameAr": "شيشة",      "originEn": "Saudi Arabia",      "originAr": "المملكة العربية السعودية",  "calories": 272, "carbs": 73, "fiber": 6,  "potassium": 655},
    "Sokari":    {"nameAr": "سكري",      "originEn": "Al-Qassim, KSA",    "originAr": "القصيم، السعودية",          "calories": 320, "carbs": 85, "fiber": 8,  "potassium": 720},
    "Sugaey":    {"nameAr": "صقعي",      "originEn": "Riyadh, KSA",       "originAr": "الرياض، السعودية",          "calories": 290, "carbs": 78, "fiber": 7,  "potassium": 680},
}


class NakhlahModel:
    """
    Singleton wrapper. Call NakhlahModel.instance() to get the loaded model.
    """
    _instance = None

    def __init__(self):
        self.device = torch.device(settings.DEVICE)
        self.model  = self._load()
        self.model.eval()
        logger.info(f"✅ Model loaded on {self.device}")

    @classmethod
    def instance(cls) -> "NakhlahModel":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def _load(self) -> nn.Module:
        path = Path(settings.MODEL_PATH)
        if not path.exists():
            raise FileNotFoundError(f"Model not found at {path.resolve()}")

        # Build the same architecture used in the notebook
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

        checkpoint = torch.load(path, map_location=self.device)

        # Handle both raw state_dict and full checkpoint dicts
        state = checkpoint.get("model_state", checkpoint)
        net.load_state_dict(state)
        net.to(self.device)
        logger.info(f"Checkpoint loaded — keys: {list(checkpoint.keys())}")
        return net

    @torch.no_grad()
    def predict(self, tensor: torch.Tensor) -> list[dict]:
        """
        Args:
            tensor: preprocessed image tensor [1, 3, H, W]
        Returns:
            List of {label, confidence, class_index} sorted by confidence desc
        """
        tensor = tensor.to(self.device)
        logits = self.model(tensor)                         # [1, N]
        probs  = torch.softmax(logits, dim=1)[0]            # [N]

        results = [
            {
                "label":       CLASS_NAMES[i],
                "confidence":  round(float(probs[i]), 4),
                "class_index": i,
            }
            for i in range(len(CLASS_NAMES))
        ]
        return sorted(results, key=lambda x: x["confidence"], reverse=True)