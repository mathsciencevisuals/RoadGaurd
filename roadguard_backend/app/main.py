from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette import status

from app.api.routes.device_routes import router as device_router
from app.api.routes.hazard_routes import router as hazard_router
from app.api.routes.health_routes import router as health_router
from app.api.routes.model_routes import router as model_router
from app.core.config import settings
from app.core.database import Base, engine
from app.core.security import apply_security_headers, get_or_create_request_id


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        debug=settings.debug,
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.middleware("http")
    async def request_context_middleware(request: Request, call_next):
        request_id = get_or_create_request_id(request)
        response = await call_next(request)
        apply_security_headers(response, request_id=request_id)
        return response

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        request: Request,
        exc: RequestValidationError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "message": "Request validation failed.",
                "errors": exc.errors(),
                "path": str(request.url.path),
            },
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(
        request: Request,
        exc: Exception,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "message": "An unexpected server error occurred.",
                "detail": str(exc) if settings.debug else "Internal server error.",
                "path": str(request.url.path),
            },
        )

    app.include_router(health_router)
    app.include_router(hazard_router, prefix=settings.api_prefix)
    app.include_router(device_router, prefix=settings.api_prefix)
    app.include_router(model_router, prefix=settings.api_prefix)

    return app


app = create_app()
