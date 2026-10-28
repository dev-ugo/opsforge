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