from uuid import uuid4

from fastapi import Request, Response


REQUEST_ID_HEADER = "X-Request-ID"


def get_or_create_request_id(request: Request) -> str:
    return request.headers.get(REQUEST_ID_HEADER, str(uuid4()))


def apply_security_headers(response: Response, request_id: str) -> None:
    response.headers[REQUEST_ID_HEADER] = request_id
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"
