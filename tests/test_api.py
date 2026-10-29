from fastapi.testclient import TestClient

from app.main import app


def test_health_endpoint_returns_success():
    with TestClient(app) as client:
        response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_root_returns_service_metadata():
    with TestClient(app) as client:
        response = client.get("/")

    assert response.status_code == 200

    payload = response.json()

    assert payload["service"] == "opsforge-api"
    assert isinstance(payload["version"], str)
    assert payload["version"]
    assert isinstance(payload["hostname"], str)
    assert payload["hostname"]