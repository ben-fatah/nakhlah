from fastapi import Security, HTTPException, status
from fastapi.security.api_key import APIKeyHeader

from app.config import get_settings

settings       = get_settings()
api_key_header = APIKeyHeader(name=settings.API_KEY_HEADER, auto_error=False)


async def require_api_key(key: str = Security(api_key_header)) -> str:
    if key != settings.API_KEY:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API key.",
        )
    return key