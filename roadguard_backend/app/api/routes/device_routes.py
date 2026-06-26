from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.device_schema import DeviceRegister, DeviceResponse
from app.services.device_service import DeviceNotFoundError, DeviceService


router = APIRouter(prefix="/devices", tags=["devices"])


def get_device_service(db: Session = Depends(get_db)) -> DeviceService:
    return DeviceService(db)


@router.post("/register", response_model=DeviceResponse)
def register_device(
    payload: DeviceRegister,
    service: DeviceService = Depends(get_device_service),
) -> DeviceResponse:
    return DeviceResponse.model_validate(service.register_device(payload))


@router.get("/{device_id}", response_model=DeviceResponse)
def get_device(
    device_id: str,
    service: DeviceService = Depends(get_device_service),
) -> DeviceResponse:
    try:
        device = service.get_device(device_id)
    except DeviceNotFoundError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(error),
        ) from error

    return DeviceResponse.model_validate(device)
