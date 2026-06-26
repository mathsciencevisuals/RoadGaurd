from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.model_schema import (
    ModelListResponse,
    ModelVersionCreate,
    ModelVersionResponse,
)
from app.services.model_registry_service import (
    ModelRegistryService,
    ModelVersionNotFoundError,
)


router = APIRouter(prefix="/models", tags=["models"])


def get_model_service(db: Session = Depends(get_db)) -> ModelRegistryService:
    return ModelRegistryService(db)


@router.get("", response_model=ModelListResponse)
def list_models(
    platform: str | None = Query(default=None),
    model_type: str | None = Query(default=None),
    service: ModelRegistryService = Depends(get_model_service),
) -> ModelListResponse:
    models = service.list_models(
        platform=platform,
        model_type=model_type,
    )
    return ModelListResponse(
        models=[ModelVersionResponse.model_validate(model) for model in models],
    )


@router.post(
    "",
    response_model=ModelVersionResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_model(
    payload: ModelVersionCreate,
    service: ModelRegistryService = Depends(get_model_service),
) -> ModelVersionResponse:
    model = service.create_model(payload)
    return ModelVersionResponse.model_validate(model)


@router.get("/active", response_model=ModelListResponse)
def list_active_models(
    platform: str | None = Query(default=None),
    model_type: str | None = Query(default=None),
    service: ModelRegistryService = Depends(get_model_service),
) -> ModelListResponse:
    models = service.list_active_models(
        platform=platform,
        model_type=model_type,
    )
    return ModelListResponse(
        models=[ModelVersionResponse.model_validate(model) for model in models],
    )


@router.put("/{model_id}/activate", response_model=ModelVersionResponse)
def activate_model(
    model_id: str,
    service: ModelRegistryService = Depends(get_model_service),
) -> ModelVersionResponse:
    try:
        model = service.activate_model(model_id)
    except ModelVersionNotFoundError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(error),
        ) from error

    return ModelVersionResponse.model_validate(model)
