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