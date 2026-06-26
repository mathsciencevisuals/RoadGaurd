from fastapi import Depends, FastAPI, HTTPException, Query, status
from sqlalchemy.orm import Session

from backend.database import Base, engine, get_db
from backend.models import HazardEvent
from backend.schemas import (
    HazardCreate,
    HazardListResponse,
    HazardResponse,
    NearbyHazardsQuery,
)
from backend.services import HazardNotFoundError, HazardService


app = FastAPI(title="RoadGuard Hazard API", version="1.0.0")


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine, tables=[HazardEvent.__table__])


def get_hazard_service(db: Session = Depends(get_db)) -> HazardService:
    return HazardService(db)


@app.post(
    "/api/hazards",
    response_model=HazardResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_hazard(
    payload: HazardCreate,
    service: HazardService = Depends(get_hazard_service),
) -> HazardResponse:
    return HazardResponse.model_validate(service.create_hazard(payload))


@app.get(
    "/api/hazards/nearby",
    response_model=HazardListResponse,
)
def get_nearby_hazards(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    radius_meters: float = Query(..., gt=0, le=5000),
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
        hazards=[
            HazardResponse.model_validate(hazard)
            for hazard in hazards
        ]
    )


@app.post(
    "/api/hazards/{hazard_id}/verify",
    response_model=HazardResponse,
)
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


@app.post(
    "/api/hazards/{hazard_id}/false-positive",
    response_model=HazardResponse,
)
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
