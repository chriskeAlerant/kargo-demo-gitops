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
release-frontend.yaml -> frontend Warehouse -> dev/test/prod
-> images.storeFront.tag
```

Backend bundle flow:

```text
release-backend-bundle.yaml -> backend-bundle Warehouse -> dev/test/prod
-> images.productService.tag + images.orderService.tag
```

## Repository Layout

- `charts/aks-store` - one Helm chart for all three services and dependencies
- `environments/dev|test|prod/values.yaml` - environment-specific image tags
- `argocd/applications.yaml` - one Argo CD Application per environment
- `kargo/warehouse.yaml` - frontend and backend-bundle Warehouses
- `kargo/promotiontask.yaml` - frontend and backend bundle PromotionTasks
- `kargo/stages.yaml` - shared environment Stages: dev, test, prod
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
ghcr.io/chriskealerant/kargo-demo-store-front:v1.0.4
```

Backend bundle release:

```sh
gh workflow run release-backend-bundle.yaml \
  --repo chriskeAlerant/kargo-demo-aks-store-app \
  -f version=v1.2.1
```

This pushes both backend images with the same tag:

```text
ghcr.io/chriskealerant/kargo-demo-product-service:v1.2.1
ghcr.io/chriskealerant/kargo-demo-order-service:v1.2.1
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

- `frontend` watches `ghcr.io/chriskealerant/kargo-demo-store-front`.
- `backend-bundle` watches `ghcr.io/chriskealerant/kargo-demo-product-service` and `ghcr.io/chriskealerant/kargo-demo-order-service`.

The backend Warehouse uses `freightCreationCriteria` so product-service and
order-service only form useful Freight when both images share the same semantic
version tag.

Stages:

- `dev` can receive Freight directly from both Warehouses and auto-promotes when enabled.
- `test` receives promoted Freight from `dev`.
- `prod` receives promoted Freight from `test`.

Each Stage can handle multiple Freight origins. A frontend Freight updates only
`images.storeFront.tag`; a backend-bundle Freight updates only
`images.productService.tag` and `images.orderService.tag`.

This model is intentional: Kargo's Argo CD Application authorization is
stage-based, while this demo has one Argo CD Application per environment. The
Stage therefore represents the environment, and the release stream is represented
by the Warehouse/Freight origin.

Argo CD authorization:

- `aks-store-dev` -> `aks-store:dev`
- `aks-store-test` -> `aks-store:test`
- `aks-store-prod` -> `aks-store:prod`

## Demo Flows

Frontend-only release:

1. Run `release-frontend.yaml` with `version=v1.0.4`.
2. Observe Freight in the `frontend` Warehouse.
3. Let `dev` auto-promote, or promote it manually if auto-promotion is disabled.
4. Promote the same Freight to `test` and `prod`.
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
3. Let `dev` auto-promote, or promote it manually if auto-promotion is disabled.
4. Promote the same Freight to `test` and `prod`.
5. Inspect the GitOps diff:

```sh
git diff HEAD~1 -- environments/dev/values.yaml
```

Expected backend-only diff:

```text
images.productService.tag: v1.0.0 -> v1.2.1
images.orderService.tag: v1.0.0 -> v1.2.1
```

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
