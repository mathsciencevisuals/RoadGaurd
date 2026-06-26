from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.device import Device
from app.schemas.device_schema import DeviceRegister


class DeviceNotFoundError(Exception):
    pass


class DeviceService:
    def __init__(self, db: Session) -> None:
        self._db = db

    def register_device(self, payload: DeviceRegister) -> Device:
        device = self._db.get(Device, payload.id)
        now = datetime.now(timezone.utc)

        if device is None:
            device = Device(
                id=payload.id,
                platform=payload.platform,
                app_version=payload.app_version,
                os_version=payload.os_version,
                push_token=payload.push_token,
                last_seen_at=now,
            )
            self._db.add(device)
        else:
            device.platform = payload.platform
            device.app_version = payload.app_version
            device.os_version = payload.os_version
            device.push_token = payload.push_token
            device.last_seen_at = now

        self._db.commit()
        self._db.refresh(device)
        return device

    def get_device(self, device_id: str) -> Device:
        device = self._db.get(Device, device_id)
        if device is None:
            raise DeviceNotFoundError(f"Device '{device_id}' was not found.")
        return device
