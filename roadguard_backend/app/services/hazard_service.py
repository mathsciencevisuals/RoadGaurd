from sqlalchemy import Select, func, select
from sqlalchemy.orm import Session

from app.models.hazard_event import HazardEvent
from app.schemas.hazard_schema import HazardCreate, NearbyHazardsQuery


EARTH_RADIUS_METERS = 6371000.0


class HazardNotFoundError(Exception):
    pass


class HazardService:
    def __init__(self, db: Session) -> None:
        self._db = db

    def create_hazard(self, payload: HazardCreate) -> HazardEvent:
        hazard = HazardEvent(
            device_id=payload.device_id,
            user_id=payload.user_id,
            hazard_type=payload.hazard_type,
            risk_level=payload.risk_level,
            latitude=payload.latitude,
            longitude=payload.longitude,
            confidence=payload.confidence,
            estimated_distance_meters=payload.estimated_distance_meters,
            estimated_width_meters=payload.estimated_width_meters,
            estimated_depth_meters=payload.estimated_depth_meters,
            image_url=str(payload.image_url) if payload.image_url else None,
            detected_at=payload.detected_at,
        )
        self._db.add(hazard)
        self._db.commit()
        self._db.refresh(hazard)
        return hazard

    def get_hazard(self, hazard_id: str) -> HazardEvent:
        hazard = self._db.get(HazardEvent, hazard_id)
        if hazard is None:
            raise HazardNotFoundError(f"Hazard '{hazard_id}' was not found.")
        return hazard

    def verify_hazard(self, hazard_id: str) -> HazardEvent:
        hazard = self.get_hazard(hazard_id)
        hazard.verified_count += 1
        self._db.commit()
        self._db.refresh(hazard)
        return hazard

    def mark_false_positive(self, hazard_id: str) -> HazardEvent:
        hazard = self.get_hazard(hazard_id)
        hazard.false_positive_count += 1
        self._db.commit()
        self._db.refresh(hazard)
        return hazard

    def get_nearby_hazards(self, query: NearbyHazardsQuery) -> list[HazardEvent]:
        distance_expression = self._distance_expression(
            latitude=query.latitude,
            longitude=query.longitude,
        )

        statement: Select[tuple[HazardEvent]] = (
            select(HazardEvent)
            .where(distance_expression <= query.radius_meters)
            .order_by(distance_expression.asc(), HazardEvent.detected_at.desc())
            .limit(query.limit)
        )

        return list(self._db.scalars(statement).all())

    def _distance_expression(self, latitude: float, longitude: float):
        latitude_radians = func.radians(latitude)
        longitude_radians = func.radians(longitude)
        hazard_latitude_radians = func.radians(HazardEvent.latitude)
        hazard_longitude_radians = func.radians(HazardEvent.longitude)

        return EARTH_RADIUS_METERS * 2 * func.asin(
            func.least(
                1.0,
                func.sqrt(
                    func.pow(
                        func.sin(
                            (hazard_latitude_radians - latitude_radians) / 2,
                        ),
                        2,
                    )
                    + func.cos(latitude_radians)
                    * func.cos(hazard_latitude_radians)
                    * func.pow(
                        func.sin(
                            (hazard_longitude_radians - longitude_radians) / 2,
                        ),
                        2,
                    )
                ),
            ),
        )
