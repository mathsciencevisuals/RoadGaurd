from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.hazard_schema import (
    HazardCreate,
    HazardListResponse,
    HazardResponse,
    NearbyHazardsQuery,
)
from app.services.hazard_service import HazardNotFoundError, HazardService


router = APIRouter(prefix="/hazards", tags=["hazards"])


def get_hazard_service(db: Session = Depends(get_db)) -> HazardService:
    return HazardService(db)


@router.post(
    "",
    response_model=HazardResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_hazard(
    payload: HazardCreate,
    service: HazardService = Depends(get_hazard_service),
) -> HazardResponse:
    return HazardResponse.model_validate(service.create_hazard(payload))


@router.get("/nearby", response_model=HazardListResponse)
def get_nearby_hazards(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    radius_meters: float = Query(250, gt=0, le=5000),
    limit: int = Query(100, ge=1, le=250),
    service: HazardService = Depends(get_hazard_service),
) -> HazardListResponse:
    query = NearbyHazardsQuery(
        latitude=latitude,
        longitude=longitude,
        radius_meters=radius_meters,
        limit=limit,
    )
    hazards = service.get_nearby_hazards(query)
    return HazardListResponse(
        hazards=[HazardResponse.model_validate(hazard) for hazard in hazards],
    )


@router.get("/{hazard_id}", response_model=HazardResponse)
def get_hazard(
    hazard_id: str,
    service: HazardService = Depends(get_hazard_service),
) -> HazardResponse:
    try:
        hazard = service.get_hazard(hazard_id)
    except HazardNotFoundError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(error),
        ) from error

    return HazardResponse.model_validate(hazard)


@router.post("/{hazard_id}/verify", response_model=HazardResponse)
def verify_hazard(
    hazard_id: str,
    service: HazardService = Depends(get_hazard_service),
) -> HazardResponse:
    try:
        hazard = service.verify_hazard(hazard_id)
    except HazardNotFoundError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(error),
        ) from error

    return HazardResponse.model_validate(hazard)


@router.post("/{hazard_id}/false-positive", response_model=HazardResponse)
def mark_false_positive(
    hazard_id: str,
    service: HazardService = Depends(get_hazard_service),
) -> HazardResponse:
    try:
        hazard = service.mark_false_positive(hazard_id)
    except HazardNotFoundError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(error),
        ) from error

    return HazardResponse.model_validate(hazard)
