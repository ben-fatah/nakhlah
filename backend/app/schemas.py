from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class Prediction(BaseModel):
    label:       str
    confidence:  float = Field(..., ge=0.0, le=1.0)
    class_index: int


class DateMetadata(BaseModel):
    nameAr:     str
    originEn:   str
    originAr:   str
    calories:   int
    carbs:      int
    fiber:      int
    potassium:  int


class PredictResponse(BaseModel):
    # Top-1 result
    label:       str
    nameAr:      str
    confidence:  float
    originEn:    str
    originAr:    str
    calories:    int
    carbs:       int
    fiber:       int
    potassium:   int

    # Full ranking
    all_predictions: list[Prediction]

    # Meta
    model_version: str = "v2"
    processed_at:  datetime


class ErrorResponse(BaseModel):
    detail: str
    code:   str