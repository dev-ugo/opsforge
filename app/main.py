from socket import gethostname
from time import perf_counter

from fastapi import FastAPI, Request, Response
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    CollectorRegistry,
    Counter,
    Histogram,
    generate_latest,
)

VERSION = "0.1.0"
app = FastAPI(title="OpsForge API", version=VERSION)

METRICS_REGISTRY = CollectorRegistry()

HTTP_REQUESTS = Counter(
    "opsforge_http_requests_total",
    "HTTP requests by status, excluding health checks and metrics.",
    ["status"],
    registry=METRICS_REGISTRY,
)

HTTP_DURATION = Histogram(
    "opsforge_http_request_duration_seconds",
    "HTTP processing duration until response headers, in seconds.",
    registry=METRICS_REGISTRY,
)


@app.middleware("http")
async def observe_requests(request: Request, call_next) -> Response:
    if request.url.path in {"/health", "/metrics"}:
        return await call_next(request)

    started_at = perf_counter()
    status_code = 500

    try:
        response = await call_next(request)
        status_code = response.status_code
        return response
    finally:
        HTTP_REQUESTS.labels(status=str(status_code)).inc()
        HTTP_DURATION.observe(perf_counter() - started_at)


@app.get("/")
def root() -> dict[str, str]:
    return {
        "service": "opsforge-api",
        "version": VERSION,
        "hostname": gethostname(),
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/metrics", include_in_schema=False)
def metrics() -> Response:
    return Response(
        content=generate_latest(METRICS_REGISTRY),
        headers={"Content-Type": CONTENT_TYPE_LATEST},
    )