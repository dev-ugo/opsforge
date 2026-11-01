from fastapi.testclient import TestClient
from prometheus_client.parser import text_string_to_metric_families

from app.main import app


def metric_value(text: str, name: str, labels: dict[str, str] | None = None) -> float:
    for family in text_string_to_metric_families(text):
        for sample in family.samples:
            if sample.name == name and sample.labels == (labels or {}):
                return sample.value
    return 0.0


def test_metrics_count_requests_and_exclude_monitoring():
    with TestClient(app) as client:
        before = client.get("/metrics")
        assert client.get("/").status_code == 200
        assert client.get("/missing").status_code == 404
        assert client.get("/health").status_code == 200
        after = client.get("/metrics")

    assert after.status_code == 200
    assert after.headers["content-type"].startswith("text/plain")

    for status in ("200", "404"):
        assert (
            metric_value(after.text, "opsforge_http_requests_total", {"status": status})
            - metric_value(before.text, "opsforge_http_requests_total", {"status": status})
        ) == 1

    assert (
        metric_value(after.text, "opsforge_http_request_duration_seconds_count")
        - metric_value(before.text, "opsforge_http_request_duration_seconds_count")
    ) == 2


def test_metrics_count_unhandled_server_errors(monkeypatch):
    def fail_hostname():
        raise RuntimeError("Simulated server error")

    monkeypatch.setattr("app.main.gethostname", fail_hostname)

    with TestClient(app, raise_server_exceptions=False) as client:
        before = client.get("/metrics").text
        response = client.get("/")
        after = client.get("/metrics").text

    assert response.status_code == 500
    assert (
        metric_value(after, "opsforge_http_requests_total", {"status": "500"})
        - metric_value(before, "opsforge_http_requests_total", {"status": "500"})
    ) == 1