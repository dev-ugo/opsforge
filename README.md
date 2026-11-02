# OpsForge

A hands-on DevOps, SRE, and security learning project built around a small
FastAPI service running on a local Kubernetes cluster.

The application provides a simple workload for learning how to test, package,
deploy, secure, monitor, and recover a service.

## Current capabilities

- Two API replicas with a readiness probe and container security settings.
- API tests, secret scanning, and image vulnerability checks in GitHub Actions.
- Scanned images published to GitHub Container Registry (GHCR).
- Kubernetes deployment using an image pinned by digest.
- Prometheus metrics and a Grafana dashboard defined in Git.
- A validated failed-rollout recovery exercise.

See the [architecture guide](docs/architecture.md) for component roles,
diagrams, request and delivery flows, and the current limitations.
The [security assessment](SECURITY.md) records the vulnerability policy and
controls; the [recovery runbook](docs/runbooks/failed-rollout.md) documents
failed image rollout recovery.

## Prerequisites

Ubuntu/WSL, a working Docker installation, Git, GNU Make, kubectl, kind, Helm,
and Python 3. Internet access is needed to download images and Helm charts.

Run commands from the repository root. The Makefile explicitly targets the
`kind-opsforge` context. Application resources use the `default` namespace;
monitoring resources use `monitoring`.

## Introductory Kubernetes lab

The original NGINX workload remains available for basic Kubernetes exercises.
The FastAPI service and monitoring setup are described in the sections below.

1. Create the cluster using `make cluster-create` if it doesn't already exist.
2. Deploy NGINX using `make deploy`.
3. Check the resources using `make status`.
4. Run `make port-forward`, then open http://localhost:8080.

## Completed Exercises

- Deploy NGINX with two replicas.
- Delete a Pod and observe its automatic replacement.
- Scale the deployment from two to three replicas.
- Run API and metrics tests in a container.
- Deploy a GHCR image pinned by digest.
- Recover from a failed image rollout using an explicit rollback.
- Collect metrics from both API replicas and provision a Grafana dashboard.

## Configuration

The files in the `k8s/` directory define the desired state.

`make deploy` reapplies this configuration, including the two replicas.

`make scale REPLICAS=3` updates the running cluster without modifying the YAML files.

## FastAPI Service

Create the cluster with `make cluster-create` if it does not already exist.
Deploy the image referenced in the Kubernetes manifest with two replicas:

    make api-deploy

This command applies `k8s/api/` and waits for the rollout. The manifest currently
references a public GHCR image by digest; no local build or kind image load is
required. Building with `make api-build` does not update that image reference.

Check the deployment, Pods, and Service:

    make api-status

Start local port forwarding in a dedicated terminal:

    make api-port-forward

Available endpoints at http://localhost:8000:

- `/`: service name, version, and Pod hostname.
- `/health`: application health check.
- `/metrics`: Prometheus HTTP metrics.
- `/docs`: interactive API documentation.

With port forwarding running, verify the health response from another terminal:

```bash
curl -fsS --max-time 3 http://localhost:8000/health
```

Expected response: `{"status":"ok"}`.

The Service uses port `80` inside Kubernetes and forwards to the container's
named `http` port (`8000`). Local port forwarding selects one Pod; it does not
demonstrate load balancing across replicas. Restart it if that Pod disappears.

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

Scan current files for potential secrets:

    make secret-scan

This scan excludes Git history. Local `make api-scan` blocks HIGH and CRITICAL
findings by default. CI currently blocks CRITICAL findings and retains HIGH
findings as reports while their review is paused. See [SECURITY.md](SECURITY.md).

## Development workflow

Changes are proposed through pull requests targeting `main`.
The `Tests and security` CI check must pass before merging.

## Container images

After a successful CI run on `main`, the scanned runtime image is
published to `ghcr.io/<owner>/opsforge-api:<commit-sha>`.

Pull requests run tests and security checks without publishing images.

The publisher loads the image archive that passed the critical-vulnerability
gate instead of rebuilding it. Publishing does not update the local cluster:
deploying a chosen image requires updating `k8s/api/deployment.yaml` and running
`make api-deploy`.

## HTTP metrics

The API exposes Prometheus metrics at `/metrics`.

- `opsforge_http_requests_total` counts requests by HTTP status.
- `opsforge_http_request_duration_seconds` measures processing time
  until response headers.

Health checks and metric scrapes are excluded.
Metrics are held in memory per process and reset on restart.

The histogram measures server processing until response headers, excluding
client network time. Traffic panels need request observations and multiple
Prometheus scrapes before rate queries produce useful results.

## Kubernetes monitoring

Prometheus and Grafana run in the `monitoring` namespace.

With the cluster and API running, install the stack and apply the API-specific
monitoring resources:

```bash
make monitoring-install
kubectl --context kind-opsforge --namespace monitoring \
  apply -f monitoring/manifests/api-servicemonitor.yaml
make monitoring-dashboard
make monitoring-status
```

`monitoring-install` installs the Helm release. The ServiceMonitor and dashboard
are applied separately by the remaining commands. The stack also includes
Prometheus Operator, Alertmanager, kube-state-metrics, and node-exporter.

- `make monitoring-install`: install or update the monitoring stack.
- `make monitoring-status`: inspect monitoring workloads and storage.
- `make grafana-port-forward`: access Grafana at http://localhost:3000.
- `make monitoring-dashboard`: validate and deploy the API dashboard.

The dashboard source is `monitoring/dashboards/opsforge-api.json`.
Edit this file and redeploy it to update the dashboard. Local
`make monitoring-dashboard-check` validates JSON syntax and renders the
Kustomization; CI currently validates the dashboard's JSON syntax only.

Keep `make grafana-port-forward` running in a dedicated terminal, then open
[OpsForge API Overview](http://localhost:3000/d/opsforge-api-overview).
The username is `admin`. Retrieve the generated password locally:

```bash
kubectl --context kind-opsforge --namespace monitoring \
  get secret monitoring-grafana \
  -o jsonpath='{.data.admin-password}' | base64 --decode
printf '\n'
```

Keep the password out of commits, screenshots, and shared logs.

The dashboard displays metrics targets, request rate, HTTP 5xx rate, and mean
API processing time. A target count of two means both metrics endpoints were
scraped successfully; it does not establish that a new deployment succeeded.
See the [architecture guide](docs/architecture.md#metrics-and-dashboard) for
the meaning of each panel and the limits of this single-node lab.