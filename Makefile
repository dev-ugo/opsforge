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