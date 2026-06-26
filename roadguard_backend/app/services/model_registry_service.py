from sqlalchemy import Select, select
from sqlalchemy.orm import Session

from app.models.model_version import ModelVersion
from app.schemas.model_schema import ModelVersionCreate


class ModelVersionNotFoundError(Exception):
    pass


class ModelRegistryService:
    def __init__(self, db: Session) -> None:
        self._db = db

    def create_model(self, payload: ModelVersionCreate) -> ModelVersion:
        model = ModelVersion(
            id=payload.id,
            model_name=payload.model_name,
            model_type=payload.model_type,
            version=payload.version,
            platform=payload.platform,
            download_url=str(payload.download_url),
            checksum=payload.checksum,
            input_width=payload.input_width,
            input_height=payload.input_height,
            labels_url=str(payload.labels_url) if payload.labels_url else None,
            is_active=payload.is_active,
        )

        if payload.is_active:
            self._deactivate_active_models(
                model_type=payload.model_type,
                platform=payload.platform,
            )

        self._db.add(model)
        self._db.commit()
        self._db.refresh(model)
        return model

    def activate_model(self, model_id: str) -> ModelVersion:
        model = self._db.get(ModelVersion, model_id)
        if model is None:
            raise ModelVersionNotFoundError(
                f"Model version '{model_id}' was not found."
            )

        self._deactivate_active_models(
            model_type=model.model_type,
            platform=model.platform,
        )
        model.is_active = True
        self._db.commit()
        self._db.refresh(model)
        return model

    def list_models(
        self,
        platform: str | None = None,
        model_type: str | None = None,
    ) -> list[ModelVersion]:
        statement: Select[tuple[ModelVersion]] = select(ModelVersion).order_by(
            ModelVersion.created_at.desc(),
        )

        if platform:
            statement = statement.where(ModelVersion.platform == platform)

        if model_type:
            statement = statement.where(ModelVersion.model_type == model_type)

        return list(self._db.scalars(statement).all())

    def list_active_models(
        self,
        platform: str | None = None,
        model_type: str | None = None,
    ) -> list[ModelVersion]:
        statement: Select[tuple[ModelVersion]] = select(ModelVersion).where(
            ModelVersion.is_active.is_(True),
        )

        if platform:
            statement = statement.where(ModelVersion.platform == platform)

        if model_type:
            statement = statement.where(ModelVersion.model_type == model_type)

        statement = statement.order_by(ModelVersion.created_at.desc())
        return list(self._db.scalars(statement).all())

    def _deactivate_active_models(self, model_type: str, platform: str) -> None:
        statement: Select[tuple[ModelVersion]] = select(ModelVersion).where(
            ModelVersion.model_type == model_type,
            ModelVersion.platform == platform,
            ModelVersion.is_active.is_(True),
        )

        for active_model in self._db.scalars(statement).all():
            active_model.is_active = False
