# Manual Freight Assembly Scenario

This scenario demonstrates Kargo's documented Freight Assembly pattern. The
Warehouse continuously discovers available image revisions, but does not
automatically produce Freight. A release manager manually assembles a compatible
release package in the Kargo UI by selecting specific versions of `store-front`,
`product-service`, and `order-service`. The assembled Freight is then promoted
through `dev`, `test`, and `prod` as a single unit.

## Why This Scenario Exists

Ebben a szcenárióban a release-csomag nem automatikusan jön létre, és nem is Git
manifestből származik. A release manager a Kargo UI-ban választja ki, hogy a
`store-front`, `product-service` és `order-service` mely verziói alkossanak egy
közös Freightet. Ez jól demonstrálja, hogy a Kargo nemcsak image tag updater,
hanem release composition és promotion platform is.

The scenario uses a separate Kargo Project, `aks-store-manual-freight`, so the
happy path, health-gate, and release-manifest scenarios remain isolated.

## Pattern Background

Kargo documents three related patterns:

- Grouped Services: one Warehouse can watch multiple artifact repositories, and
  artifacts referenced by one Freight move together between Stages.
- Freight Assembly: the Warehouse discovers artifact revisions, but users
  manually select compatible revisions and create Freight in the UI.
- Mixed Promotion Modes: Freight can be created automatically while users
  manually choose which Freight moves into each Stage.

This scenario implements Freight Assembly as the primary pattern.

## Difference From Release Manifest

The release-manifest scenario promotes a Git commit that defines the desired
component versions in `release-manifests/aks-store/current.yaml`.

This scenario promotes a manually assembled Freight made from image revisions
discovered by the `manual-release` Warehouse. No release manifest commit creates
the package.

## Build Demo Images

The app repository includes `release-service.yaml` so each service can be built
independently:

```sh
gh workflow run release-service.yaml \
  --repo chriskeAlerant/kargo-demo-aks-store-app \
  -f service=store-front \
  -f version=v1.0.7

gh workflow run release-service.yaml \
  --repo chriskeAlerant/kargo-demo-aks-store-app \
  -f service=product-service \
  -f version=v1.3.2

gh workflow run release-service.yaml \
  --repo chriskeAlerant/kargo-demo-aks-store-app \
  -f service=order-service \
  -f version=v1.1.9
```

Or dispatch all three demo builds:

```sh
GITHUB_OWNER=chriskeAlerant ./scripts/scenarios/manual-freight/build-demo-images.sh
```

## Apply Scenario

```sh
./scripts/scenarios/manual-freight/apply.sh
```

This applies only:

- `argocd/scenarios/manual-freight/applications.yaml`
- `kargo/scenarios/manual-freight/project.yaml`
- `kargo/scenarios/manual-freight/warehouse.yaml`
- `kargo/scenarios/manual-freight/promotiontask.yaml`
- `kargo/scenarios/manual-freight/stages.yaml`

## Check Discovery

```sh
./scripts/scenarios/manual-freight/status.sh
```

Expected Kargo resources:

- Project: `aks-store-manual-freight`
- Warehouse: `manual-release`
- Stages: `dev`, `test`, `prod`

The Warehouse uses `freightCreationPolicy: Manual`, so discovered image revisions
do not become Freight automatically.

## UI Flow

1. Open the Kargo UI.
2. Select the `aks-store-manual-freight` Project.
3. Open the `manual-release` Warehouse / Freight Assembly view.
4. Confirm no Freight was created automatically.
5. Start Freight Assembly.
6. Select:
   - `store-front:v1.0.7`
   - `product-service:v1.3.2`
   - `order-service:v1.1.9`
7. Create the Freight.
8. Set alias `manual-release-001` if the UI supports aliases.
9. Promote to `dev`.
10. Promote the same Freight to `test`.
11. Promote the same Freight to `prod`.

## Expected GitOps Diff

After promoting to `dev`, `environments-manual/dev/values.yaml` should change:

```diff
 images:
   storeFront:
-    tag: v1.0.0
+    tag: v1.0.7
   productService:
-    tag: v1.0.0
+    tag: v1.3.2
   orderService:
-    tag: v1.0.0
+    tag: v1.1.9
```

The promotion updates existing scalar keys only:

- `images.storeFront.tag`
- `images.productService.tag`
- `images.orderService.tag`

If the assembled Freight is missing any one of the three image revisions, the
promotion cannot resolve all `imageFrom(...).Tag` expressions and fails before
commit/push.

## Argo CD Checks

```sh
kubectl -n argocd get application aks-store-manual-dev
kubectl -n argocd get application aks-store-manual-test
kubectl -n argocd get application aks-store-manual-prod
```

Application authorization is stage-scoped:

- `aks-store-manual-dev` -> `aks-store-manual-freight:dev`
- `aks-store-manual-test` -> `aks-store-manual-freight:test`
- `aks-store-manual-prod` -> `aks-store-manual-freight:prod`

## Cleanup

```sh
./scripts/scenarios/manual-freight/cleanup.sh
```

Cleanup deletes only manual-freight scenario resources and namespaces.
