from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


DevicePlatform = Literal["android", "ios"]


class DeviceRegister(BaseModel):
    id: str = Field(min_length=1, max_length=128)
    platform: DevicePlatform
    app_version: str = Field(min_length=1, max_length=32)
    os_version: str | None = Field(default=None, max_length=64)
    push_token: str | None = Field(default=None, max_length=512)


class DeviceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    platform: str
    app_version: str
    os_version: str | None
    push_token: str | None
    is_active: bool
    created_at: datetime
    last_seen_at: datetime
