from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


ModelType = Literal[
    "object_detection",
    "pothole_detection",
    "road_segmentation",
    "depth_estimation",
]
PlatformType = Literal["android", "ios", "universal"]


class ModelVersionCreate(BaseModel):
    id: str = Field(min_length=1, max_length=64)
    model_name: str = Field(min_length=1, max_length=64)
    model_type: ModelType
    version: str = Field(min_length=1, max_length=32)
    platform: PlatformType
    download_url: HttpUrl
    checksum: str | None = Field(default=None, min_length=1, max_length=128)
    input_width: int = Field(ge=1, le=8192)
    input_height: int = Field(ge=1, le=8192)
    labels_url: HttpUrl | None = None
    is_active: bool = False

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "id": "rg-objdet-android-v1",
                "model_name": "roadguard_object_detection",
                "model_type": "object_detection",
                "version": "1.0.0",
                "platform": "android",
                "download_url": "https://cdn.example.com/models/roadguard_object_detection_android_v1.tflite",
                "checksum": "sha256:abcd1234",
                "input_width": 320,
                "input_height": 320,
                "labels_url": "https://cdn.example.com/models/labels.txt",
                "is_active": True,
            }
        }
    )


class ModelVersionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    model_name: str
    model_type: str
    version: str
    platform: str
    download_url: str
    checksum: str | None
    input_width: int
    input_height: int
    labels_url: str | None
    is_active: bool
    created_at: datetime


class ModelListResponse(BaseModel):
    models: list[ModelVersionResponse]
