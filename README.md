# OpsForge

A hands-on DevOps/SRE learning project, starting with a local Kubernetes environment.

## Prerequisites

Ubuntu/WSL, a working Docker installation, Git, GNU Make, kubectl, and kind.

## Getting Started

1. Create the cluster using `make cluster-create` if it doesn't already exist.
2. Deploy NGINX using `make deploy`.
3. Check the resources using `make status`.
4. Run `make port-forward`, then open http://localhost:8080.

## Completed Exercises

- Deploy NGINX with two replicas.
- Delete a Pod and observe its automatic replacement.
- Scale the deployment from two to three replicas.

## Configuration

The files in the `k8s/` directory define the desired state.

`make deploy` reapplies this configuration, including the two replicas.

`make scale REPLICAS=3` updates the running cluster without modifying the YAML files.

## FastAPI Service

Build the image, load it into kind, and deploy two replicas:

    make api-deploy

Check the deployment, Pods, and Service:

    make api-status

Start local port forwarding in a dedicated terminal:

    make api-port-forward

Available endpoints at http://localhost:8000:

- `/`: service name, version, and Pod hostname.
- `/health`: application health check.
- `/docs`: interactive API documentation.

Kubernetes manifests are located in `k8s/api/`.

The readiness probe checks `/health` before making a Pod
available to receive traffic through the Service.

## Quality and Security Checks

Run the API HTTP contract tests:

    make api-test

Scan the runtime image for known vulnerabilities:

    make api-scan

The vulnerability scan fails when HIGH or CRITICAL findings
are detected. Review the affected packages and available fixes.

## Development workflow

Changes are proposed through pull requests targeting `main`.
The `Tests and security` CI check must pass before merging.

## Container images

After a successful CI run on `main`, the scanned runtime image is
published to `ghcr.io/<owner>/opsforge-api:<commit-sha>`.

Pull requests run tests and security checks without publishing images.

## HTTP metrics

The API exposes Prometheus metrics at `/metrics`.

- `opsforge_http_requests_total` counts requests by HTTP status.
- `opsforge_http_request_duration_seconds` measures processing time
  until response headers.

Health checks and metric scrapes are excluded.
Metrics are held in memory per process and reset on restart.

## Kubernetes monitoring

Prometheus and Grafana run in the `monitoring` namespace.

- `make monitoring-install`: install or update the monitoring stack.
- `make monitoring-status`: inspect monitoring workloads and storage.
- `make grafana-port-forward`: access Grafana at http://localhost:3000.
- `make monitoring-dashboard`: validate and deploy the API dashboard.

The dashboard source is `monitoring/dashboards/opsforge-api.json`.
Edit this file and redeploy it to update the dashboard.