# Health-Gate Scenario

This scenario demonstrates a failed Kargo verification gate and a controlled
manual approval / bypass path.

It uses a separate Kargo Project named `aks-store-health-gate`, separate Argo CD
Applications, and separate Helm values under `environments-health/`. The happy
path `aks-store` Project and Applications are not reused.

## What It Shows

- A backend bundle Freight can promote to `dev`.
- The same Freight can promote to `test`.
- The `test` Stage starts a Kargo verification.
- The verification fails because the AnalysisTemplate calls a non-existent
  endpoint:

```text
http://non-existent-service.aks-store-health-test.svc.cluster.local:8080/health
```

- Because `test` is not verified, normal promotion to `prod` is blocked.
- A manual approval / bypass can explicitly mark the Freight promotable to
  `prod`.
- The bypass does not automatically create a Promotion. A separate explicit
  promotion to `prod` is still required.

## Files

- `project.yaml` creates the `aks-store-health-gate` Project.
- `warehouse.yaml` creates a backend-bundle Warehouse for product-service and
  order-service.
- `analysis-template.yaml` defines the intentionally failing health check.
- `stages.yaml` defines `dev -> test -> prod`; only `test` has verification.
- `promotiontask.yaml` updates backend image tags in `environments-health/`.
- `argocd/scenarios/health-gate/applications.yaml` defines the scenario Argo CD
  Applications.

## Apply

```sh
GITHUB_OWNER=<owner> ./scripts/scenarios/health-gate/apply.sh
```

If `GITHUB_OWNER` is not set, the script reads it with `gh api user --jq .login`.

## Status

```sh
./scripts/scenarios/health-gate/status.sh
```

Inspect the failed verification:

```sh
kubectl get analysisruns -n aks-store-health-gate
kubectl describe analysisrun -n aks-store-health-gate <analysisrun-name>
```

## Demo Flow

1. Ensure backend bundle images exist with the same semantic tag.
2. Wait for `backend-bundle` Freight in `aks-store-health-gate`.
3. Promote the Freight to `dev`.
4. Promote the same Freight to `test`.
5. Observe the `test` Stage enter verification.
6. Observe the AnalysisRun fail because the health endpoint does not exist.
7. Show that normal promotion to `prod` is blocked.
8. Manually approve the Freight for `prod`:

```sh
kargo approve \
  --project aks-store-health-gate \
  --freight <FREIGHT_NAME> \
  --stage prod
```

9. Explicitly promote it to `prod`:

```sh
kargo promote \
  --project aks-store-health-gate \
  --freight <FREIGHT_NAME> \
  --stage prod
```

## Demo Message

This scenario shows that a release cannot move toward production when an
automatic quality gate fails. After failed verification, only an explicit manual
approval / bypass can make the Freight eligible for `prod`, and that bypass is
an exception path, not the normal release process.

## Cleanup

```sh
./scripts/scenarios/health-gate/cleanup.sh
```
