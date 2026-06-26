from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


RiskLevel = Literal["low", "medium", "high", "critical"]


class HazardCreate(BaseModel):
    device_id: str = Field(min_length=1, max_length=128)
    user_id: str | None = Field(default=None, min_length=1, max_length=128)
    hazard_type: str = Field(min_length=1, max_length=64)
    risk_level: RiskLevel
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    confidence: float = Field(ge=0, le=1)
    estimated_distance_meters: float = Field(gt=0, le=1000)
    estimated_width_meters: float | None = Field(default=None, gt=0, le=100)
    estimated_depth_meters: float | None = Field(default=None, gt=0, le=100)
    image_url: HttpUrl | None = None
    detected_at: datetime

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "device_id": "android-pixel-8a",
                "user_id": "user_123",
                "hazard_type": "pothole",
                "risk_level": "high",
                "latitude": 40.7128,
                "longitude": -74.0060,
                "confidence": 0.93,
                "estimated_distance_meters": 18.2,
                "estimated_width_meters": 0.8,
                "estimated_depth_meters": 0.15,
                "image_url": "https://cdn.example.com/hazards/abc123.jpg",
                "detected_at": "2026-06-26T07:30:00Z",
            }
        }
    )


class HazardResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    device_id: str
    user_id: str | None
    hazard_type: str
    risk_level: str
    latitude: float
    longitude: float
    confidence: float
    estimated_distance_meters: float
    estimated_width_meters: float | None
    estimated_depth_meters: float | None
    image_url: str | None
    detected_at: datetime
    created_at: datetime
    verified_count: int
    false_positive_count: int


class NearbyHazardsQuery(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    radius_meters: float = Field(gt=0, le=5000)
    limit: int = Field(default=100, ge=1, le=250)


class HazardListResponse(BaseModel):
    hazards: list[HazardResponse]
