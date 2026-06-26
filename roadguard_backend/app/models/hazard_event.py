import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class HazardEvent(Base):
    __tablename__ = "hazard_events"

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    device_id: Mapped[str] = mapped_column(
        String(128),
        ForeignKey("devices.id", ondelete="CASCADE"),
        index=True,
    )
    user_id: Mapped[str | None] = mapped_column(String(128), nullable=True)
    hazard_type: Mapped[str] = mapped_column(String(64), index=True)
    risk_level: Mapped[str] = mapped_column(String(32), index=True)
    latitude: Mapped[float] = mapped_column(Float, index=True)
    longitude: Mapped[float] = mapped_column(Float, index=True)
    confidence: Mapped[float] = mapped_column(Float)
    estimated_distance_meters: Mapped[float] = mapped_column(Float)
    estimated_width_meters: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
    )
    estimated_depth_meters: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
    )
    image_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    detected_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
    )
    verified_count: Mapped[int] = mapped_column(Integer, default=0)
    false_positive_count: Mapped[int] = mapped_column(Integer, default=0)
