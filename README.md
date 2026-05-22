# Kargo Demo GitOps

GitOps repository skeleton for a Kargo continuous promotion demo using GitHub
Actions, GHCR, Helm, Argo CD, and Kargo.

The deployed application remains one Helm release per environment and one Argo CD
Application per environment:

- `aks-store-dev`
- `aks-store-test`
- `aks-store-prod`

The release model has two independent streams:

- `store-front` is independently releasable and independently promotable.
- `product-service` and `order-service` form a backend bundle and promote together.

Both streams update the same Helm values files:

- `environments/dev/values.yaml`
- `environments/test/values.yaml`
- `environments/prod/values.yaml`

## Architecture

```text
GitHub Actions -> GHCR -> Kargo Warehouse/Freight -> Helm values update
-> GitOps commit -> Argo CD sync
```

Frontend flow:

```text
release-frontend.yaml -> frontend Warehouse -> frontend-dev/test/prod
-> images.storeFront.tag
```

Backend bundle flow:

```text
release-backend-bundle.yaml -> backend-bundle Warehouse -> backend-dev/test/prod
-> images.productService.tag + images.orderService.tag
```

## Repository Layout

- `charts/aks-store` - one Helm chart for all three services and dependencies
- `environments/dev|test|prod/values.yaml` - environment-specific image tags
- `argocd/applications.yaml` - one Argo CD Application per environment
- `kargo/warehouse.yaml` - frontend and backend-bundle Warehouses
- `kargo/promotiontask.yaml` - frontend and backend bundle PromotionTasks
- `kargo/stages.yaml` - two explicit Kargo pipelines
- `scripts/*.sh` - local helper scripts retained from the bootstrap skeleton

## Release Workflows

Frontend-only release:

```sh
gh workflow run release-frontend.yaml \
  --repo chriskeAlerant/kargo-demo-aks-store-app \
  -f version=v1.0.4
```

This pushes:

```text
ghcr.io/chriskeAlerant/kargo-demo-store-front:v1.0.4
```

Backend bundle release:

```sh
gh workflow run release-backend-bundle.yaml \
  --repo chriskeAlerant/kargo-demo-aks-store-app \
  -f version=v1.2.1
```

This pushes both backend images with the same tag:

```text
ghcr.io/chriskeAlerant/kargo-demo-product-service:v1.2.1
ghcr.io/chriskeAlerant/kargo-demo-order-service:v1.2.1
```

All demo release tags must match:

```text
^v[0-9]+\.[0-9]+\.[0-9]+$
```

After the workflows finish, check that the public GHCR images are reachable from
the app repository checkout:

```sh
cd ../kargo-demo-aks-store-app
./scripts/check-ghcr-images.sh
```

## Kargo Model

Project:

- `aks-store`

Warehouses:

- `frontend` watches `ghcr.io/chriskeAlerant/kargo-demo-store-front`.
- `backend-bundle` watches `ghcr.io/chriskeAlerant/kargo-demo-product-service` and `ghcr.io/chriskeAlerant/kargo-demo-order-service`.

The backend Warehouse uses `freightCreationCriteria` so product-service and
order-service only form useful Freight when both images share the same semantic
version tag.

Frontend pipeline:

- `frontend-dev` auto-promotes from the `frontend` Warehouse when enabled.
- `frontend-test` promotes manually from `frontend-dev`.
- `frontend-prod` promotes manually from `frontend-test`.

Backend pipeline:

- `backend-dev` auto-promotes from the `backend-bundle` Warehouse when enabled.
- `backend-test` promotes manually from `backend-dev`.
- `backend-prod` promotes manually from `backend-test`.

Promotion tasks:

- `promote-frontend` updates only `images.storeFront.tag`.
- `promote-backend-bundle` updates only `images.productService.tag` and `images.orderService.tag`.

## Demo Flows

Frontend-only release:

1. Run `release-frontend.yaml` with `version=v1.0.4`.
2. Observe Freight in the `frontend` Warehouse.
3. Let `frontend-dev` auto-promote, or promote it manually if auto-promotion is disabled.
4. Promote the same Freight to `frontend-test` and `frontend-prod`.
5. Inspect the GitOps diff:

```sh
git diff HEAD~1 -- environments/dev/values.yaml
```

Expected frontend-only diff:

```text
images.storeFront.tag: v1.0.0 -> v1.0.4
```

Backend bundle release:

1. Run `release-backend-bundle.yaml` with `version=v1.2.1`.
2. Observe Freight in the `backend-bundle` Warehouse.
3. Let `backend-dev` auto-promote, or promote it manually if auto-promotion is disabled.
4. Promote the same Freight to `backend-test` and `backend-prod`.
5. Inspect the GitOps diff:

```sh
git diff HEAD~1 -- environments/dev/values.yaml
```

Expected backend-only diff:

```text
images.productService.tag: v1.0.0 -> v1.2.1
images.orderService.tag: v1.0.0 -> v1.2.1
```

## Argo CD Authorization Note

Kargo's documented `kargo.akuity.io/authorized-stage` annotation accepts a single
`<project>:<stage>` value for an Argo CD Application. This skeleton keeps one
Argo CD Application per environment as requested, so `argocd/applications.yaml`
contains comments showing the backend stage that corresponds to each frontend
authorization.

Until the target Kargo version or chosen operating pattern supports multiple
stage authorizations on one Application, there are two practical demo paths:

- authorize the stream currently being demonstrated before applying the Argo CD Application, or
- rely on Argo CD automated sync after the GitOps commit and treat `argocd-update` as the part that needs version-specific adjustment.

The split Warehouse, PromotionTask, and Stage skeleton is in place for both
streams.

## Inspect Argo CD

After a promotion commits to this repository, inspect the corresponding Argo CD
Application:

```sh
kubectl -n argocd get application aks-store-dev
kubectl -n argocd get application aks-store-test
kubectl -n argocd get application aks-store-prod
```

The cluster bootstrap and install scripts are still present, but this refactor
only changes the skeleton and release/promotion model.

## Validation

Run a local skeleton validation pass:

```sh
./scripts/smoke-test.sh
```

## Troubleshooting

GHCR image visibility:
Make sure the pushed packages are public for a public demo, or configure image
pull credentials later if you move to private packages.

Backend Freight not created:
Confirm both backend workflows pushed the same semantic tag for product-service
and order-service. The backend bundle Freight requires matching tags.

Unexpected GitOps diff:
Frontend promotion should only change `images.storeFront.tag`. Backend bundle
promotion should only change `images.productService.tag` and
`images.orderService.tag`.

Kargo credentials:
The skeleton does not create real credentials. Add repository credentials that
allow Kargo to clone and push the GitOps repo when you wire the cluster side.
