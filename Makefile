.DEFAULT_GOAL := status

KUBECTL := kubectl --context kind-opsforge --namespace default
REPLICAS ?= 2

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

api-deploy: api-load
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
		--severity HIGH,CRITICAL \
		--exit-code 1