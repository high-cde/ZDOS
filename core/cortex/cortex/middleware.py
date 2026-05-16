from starlette.middleware.base import BaseHTTPMiddleware
from cortex.utils.logging import log

class RequestLogger(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        log(f"Request: {request.method} {request.url}")
        response = await call_next(request)
        log(f"Response: {response.status_code}")
        return response
