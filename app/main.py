from socket import gethostname

from fastapi import FastAPI

VERSION = "0.1.0"

app = FastAPI(title="OpsForge API", version=VERSION)

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