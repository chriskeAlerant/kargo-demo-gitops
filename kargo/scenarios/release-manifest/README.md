# Release Manifest Scenario

This scenario demonstrates manifest-driven promotion for mixed-version releases.

In this scenario, Kargo does not promote the newest images from the registry and
does not require all components to share one version. A Git-versioned release
manifest defines the exact service versions that belong to one release package.
Kargo treats the manifest commit as Freight, then promotion reads the manifest
and updates the Helm values files with those explicit versions.

## Why This Exists

Enterprise releases are often explicit release definitions. A frontend can move
with one version, product-service with another, and order-service with a third.
The release package is the approved combination, not the latest registry state.

This keeps three concerns separate:

- app source lives in `kargo-demo-aks-store-app`
- deploy configuration lives in this GitOps repo
- release definition lives in `release-manifests/aks-store/current.yaml`

The manifest is stored in this GitOps repo to keep the local demo small. The
same model can be moved to a separate `kargo-demo-release-manifests` repo later.

## Resources

Kargo Project:

```text
aks-store-release-manifest
```

Warehouse:

```text
release-manifest
```

The Warehouse watches this Git path only:

```text
release-manifests/aks-store/current.yaml
```

Scenario Argo CD Applications:

```text
aks-store-manifest-dev
aks-store-manifest-test
aks-store-manifest-prod
```

Scenario values files:

```text
environments-manifest/dev/values.yaml
environments-manifest/test/values.yaml
environments-manifest/prod/values.yaml
```

## Manifest Shape

```yaml
apiVersion: demo.kargo.io/v1alpha1
kind: ReleaseManifest
metadata:
  name: aks-store-mixed-001
spec:
  application: aks-store
  releaseId: aks-store-mixed-001
  components:
    storeFront:
      repository: ghcr.io/chriskealerant/kargo-demo-store-front
      tag: v1.0.4
    productService:
      repository: ghcr.io/chriskealerant/kargo-demo-product-service
      tag: v1.2.1
    orderService:
      repository: ghcr.io/chriskealerant/kargo-demo-order-service
      tag: v1.1.8
```

The demo assumes every referenced image tag already exists in GHCR.

## Apply

```sh
./scripts/scenarios/release-manifest/apply.sh
```

The script applies the scenario Argo CD Applications, Project, Warehouse,
PromotionTask, and Stages. It does not create Git credentials.

## Publish Manifests

Baseline:

```sh
./scripts/scenarios/release-manifest/publish-baseline.sh
```

Mixed-version release:

```sh
./scripts/scenarios/release-manifest/publish-mixed-release.sh
```

Each script writes `release-manifests/aks-store/current.yaml`, commits it, and
pushes. The Warehouse `includePaths` filter ensures only changes to that file
create manifest Freight.

## Promotion Flow

1. Commit and push a manifest change.
2. Kargo discovers a Git Freight from `release-manifest`.
3. Promote the Freight to `dev`, then `test`, then `prod`.
4. The PromotionTask checks out the manifest commit.
5. `yaml-parse` reads `releaseId`, repositories, and tags.
6. `yaml-update` writes the chosen versions into `environments-manifest/<env>/values.yaml`.
7. `argocd-update` refreshes `aks-store-manifest-<env>`.

Expected mixed-version GitOps diff:

```text
images.storeFront.tag: v1.0.4
images.productService.tag: v1.2.1
images.orderService.tag: v1.1.8
```

## Status

```sh
./scripts/scenarios/release-manifest/status.sh
```

## Cleanup

```sh
./scripts/scenarios/release-manifest/cleanup.sh
```
