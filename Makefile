.DEFAULT_GOAL := status

KUBECTL := kubectl --context kind-opsforge --namespace default
REPLICAS ?= 2
SCAN_EXIT_CODE ?= 1
SCAN_SEVERITY ?= HIGH,CRITICAL

.PHONY: cluster-create deploy status scale port-forward

cluster-create:
	kind create cluster --name opsforge --wait 120s

deploy:
	$(KUBECTL) apply -f k8s/
	$(KUBECTL) rollout status deployment/demo-web --timeout=120s

status:
	$(KUBECTL) get deployment,replicaset,pods,services -l app=demo-web

scale:
	$(KUBECTL) scale deployment/demo-web --replicas=$(REPLICAS)
	$(KUBECTL) rollout status deployment/demo-web --timeout=120s

port-forward:
	$(KUBECTL) port-forward service/demo-web 8080:80

IMAGE ?= opsforge-api:0.1.0

.PHONY: api-build api-run

api-build:
	docker build -t $(IMAGE) .

api-run:
	docker run --rm --name opsforge-api -p 127.0.0.1:8000:8000 $(IMAGE)

.PHONY: api-load api-deploy api-status api-port-forward

api-load: api-build
	kind load docker-image $(IMAGE) --name opsforge

api-deploy:
	$(KUBECTL) apply -f k8s/api/
	$(KUBECTL) rollout status deployment/opsforge-api --timeout=120s

api-status:
	$(KUBECTL) get deployment,pods,services -l app=opsforge-api

api-port-forward:
	$(KUBECTL) port-forward service/opsforge-api 8000:80

TEST_IMAGE ?= opsforge-api-test:0.1.0

.PHONY: api-test

api-test:
	docker build --target test -t $(TEST_IMAGE) .
	docker run --rm --network none $(TEST_IMAGE)

TRIVY_IMAGE ?= aquasec/trivy:0.76.1

.PHONY: api-scan

api-scan: api-build
	mkdir -p .artifacts
	docker image save --output .artifacts/opsforge-api.tar "$(IMAGE)"
	docker run --rm \
		--mount type=bind,source="$(CURDIR)/.artifacts",target=/scan,readonly \
		--mount type=volume,source=opsforge-trivy-cache,target=/root/.cache/trivy \
		$(TRIVY_IMAGE) image \
		--input /scan/opsforge-api.tar \
		--scanners vuln \
		--severity "$(SCAN_SEVERITY)" \
		--exit-code "$(SCAN_EXIT_CODE)"

.PHONY: secret-scan

secret-scan:
	docker run --rm \
		--mount type=bind,source="$(CURDIR)",target=/workspace,readonly \
		--mount type=volume,source=opsforge-trivy-cache,target=/root/.cache/trivy \
		$(TRIVY_IMAGE) fs \
		--scanners secret \
		--skip-dirs /workspace/.git,/workspace/.artifacts,/workspace/.venv \
		--format template \
		--template '{{ range . }}{{ if .Secrets }}Potential secret found in {{ .Target }}{{ "\n" }}{{ end }}{{ end }}' \
		--exit-code 1 /workspace

MONITORING_CHART_VERSION ?= 92.17.0

.PHONY: monitoring-install monitoring-status grafana-port-forward

monitoring-install:
	helm upgrade --install monitoring \
		oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack \
		--version "$(MONITORING_CHART_VERSION)" \
		--kube-context kind-opsforge \
		--namespace monitoring \
		--create-namespace \
		--values monitoring/values-kind.yaml \
		--wait --timeout 10m

monitoring-status:
	kubectl --context kind-opsforge --namespace monitoring get pods,services,pvc

grafana-port-forward:
	kubectl --context kind-opsforge --namespace monitoring \
		port-forward --address 127.0.0.1 service/monitoring-grafana 3000:80

.PHONY: monitoring-dashboard-check monitoring-dashboard

monitoring-dashboard-check:
	python3 -m json.tool monitoring/dashboards/opsforge-api.json > /dev/null
	kubectl kustomize monitoring/dashboards/ > /dev/null

monitoring-dashboard: monitoring-dashboard-check
	kubectl --context kind-opsforge --namespace monitoring \
		apply -k monitoring/dashboards/