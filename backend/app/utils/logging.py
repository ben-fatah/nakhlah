import logging
import sys
import time
from fastapi import Request


def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
        stream=sys.stdout,
    )


async def log_requests(request: Request, call_next):
    """Middleware: log method, path, status, and latency for every request."""
    start   = time.perf_counter()
    response = await call_next(request)
    elapsed  = (time.perf_counter() - start) * 1000
    logging.getLogger("access").info(
        f"{request.method} {request.url.path} → {response.status_code} [{elapsed:.1f}ms]"
    )
    return response