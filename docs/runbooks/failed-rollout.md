# Failed image rollout recovery

Scope: `opsforge-api` Deployment in the `default` namespace
of the local `kind-opsforge` cluster.

## Symptoms

- The new Pod reports `ErrImagePull` or `ImagePullBackOff`.
- The rollout does not complete.
- Existing healthy Pods may continue serving requests.

## Recovery

Identify a previously verified healthy revision:

```bash
kubectl --context kind-opsforge --namespace default \
  rollout history deployment/opsforge-api
```

Set `OPSFORGE_GOOD_REVISION` to that revision number before
running recovery. Revision numbers vary between deployments.

```bash
kubectl --context kind-opsforge --namespace default \
  rollout undo deployment/opsforge-api \
  --to-revision="${OPSFORGE_GOOD_REVISION:?Set a verified healthy revision}"

kubectl --context kind-opsforge --namespace default \
  rollout status deployment/opsforge-api --timeout=120s

make api-status
```

With the API port-forward active, verify the health endpoint:

```bash
curl -fsS --max-time 3 http://localhost:8000/health
```

Expected result: two ready replicas and `{"status":"ok"}`.

## Validated exercise

An unavailable image tag prevented the new Pod from starting.
With two replicas and the default rolling update settings,
Kubernetes retained both healthy Pods.

Health checks succeeded during the failed rollout and after
restoring the previously verified revision.

The invalid image reference was applied directly to the cluster.
The Git manifest retained the approved image digest.