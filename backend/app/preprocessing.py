"""
Image preprocessing — matches eval_transform in the training notebook.
All operations are CPU-only and stateless (safe to call concurrently).
"""
import io
import logging
from PIL import Image, UnidentifiedImageError
import torchvision.transforms as T
import torch

from app.config import get_settings

logger   = logging.getLogger(__name__)
settings = get_settings()

SZ = settings.MODEL_IMG_SIZE  # 260

# Matches notebook's eval_transform exactly
_TRANSFORM = T.Compose([
    T.Resize(SZ + 32),          # 292
    T.CenterCrop(SZ),            # 260
    T.ToTensor(),
    T.Normalize(
        mean=[0.485, 0.456, 0.406],
        std =[0.229, 0.224, 0.225],
    ),
])


def bytes_to_tensor(image_bytes: bytes) -> torch.Tensor:
    """
    Decode raw image bytes → normalized float tensor [1, 3, 260, 260].
    Raises ValueError on bad input.
    """
    try:
        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except UnidentifiedImageError:
        raise ValueError("Cannot decode image — unsupported format or corrupted file.")

    # Optional: reject suspiciously tiny images
    if img.width < 32 or img.height < 32:
        raise ValueError(f"Image too small ({img.width}×{img.height}). Minimum 32×32 px.")

    tensor = _TRANSFORM(img).unsqueeze(0)  # [1, 3, 260, 260]
    logger.debug(f"Preprocessed image — original {img.size}, tensor {tuple(tensor.shape)}")
    return tensor