# Kargo Demo GitOps

GitOps repository skeleton for a Kargo continuous promotion demo using GitHub
Actions, GHCR, Helm, Argo CD, Kargo, and a local kind cluster.

The flow is:

```text
GitHub Actions -> GHCR -> Kargo Warehouse/Freight -> Helm values update
-> GitOps commit -> Argo CD sync -> kind
```

## Repository Layout

- `charts/aks-store` - Helm chart for the demo workload
- `environments/dev|test|prod/values.yaml` - environment-specific image tags
- `argocd/applications.yaml` - Argo CD Applications for each environment
- `kargo/*.yaml` - Kargo Project, Warehouse, PromotionTask, and Stages
- `scripts/*.sh` - local bootstrap and apply helpers

## Placeholders

Files use `chriskeAlerant` where your GitHub owner is needed. The helper scripts
replace this at apply time, or during repository creation when you run:

```sh
GITHUB_OWNER=<owner> ./scripts/create-repos.sh
```

Do not commit real credentials or tokens. Kargo GitHub/GHCR credentials should
be created later as Kubernetes secrets or through your preferred credential
management flow.

## Bootstrap

From this repository:

```sh
# 1. Create the two GitHub repositories and push initial content.
# Defaults to public. Use GITHUB_REPO_VISIBILITY=private for private repos.
GITHUB_OWNER=<owner> ./scripts/create-repos.sh

# 2. Build v1.0.0 images.
# In GitHub, run the kargo-demo-aks-store-app workflow:
# .github/workflows/release-images.yaml with version=v1.0.0

# 3. Bootstrap kind.
./scripts/bootstrap-kind.sh

# 4. Install Argo CD.
./scripts/install-argocd.sh

# 5. Install Kargo.
./scripts/install-kargo.sh

# 6. Apply Argo CD Applications.
GITHUB_OWNER=<owner> ./scripts/apply-argocd-apps.sh

# 7. Apply Kargo resources.
GITHUB_OWNER=<owner> ./scripts/apply-kargo-resources.sh

# 8. Release v1.1.0.
# In GitHub, run the app repo workflow again with version=v1.1.0.

# 9. Observe Kargo promotion.
./scripts/port-forward-kargo.sh

# 10. Promote to test and prod from the Kargo UI.
```

Run a local validation pass:

```sh
./scripts/smoke-test.sh
```

## Argo CD

Open the Argo CD UI:

```sh
./scripts/port-forward-argocd.sh
```

The Applications are:

- `aks-store-dev`
- `aks-store-test`
- `aks-store-prod`

Each Application points at `charts/aks-store` and uses a different values file.
The `kargo.akuity.io/authorized-stage` annotations allow Kargo to update and
refresh the matching Application.

## Kargo

The Warehouse watches three GHCR image repositories:

- `ghcr.io/<owner>/kargo-demo-store-front`
- `ghcr.io/<owner>/kargo-demo-product-service`
- `ghcr.io/<owner>/kargo-demo-order-service`

Only tags matching `^v[0-9]+\.[0-9]+\.[0-9]+$` are eligible. Freight creation
also requires all three images to have the same tag, so the services promote as
one unit.

The promotion flow is:

- `dev` receives Freight directly from the Warehouse and is eligible for auto-promotion.
- `test` promotes manually from `dev`.
- `prod` promotes manually from `test`.

The `PromotionTask` updates existing scalar keys in the target environment
values file with `yaml-update`, commits the change, pushes to GitHub, and asks
Argo CD to sync the matching Application.

## Troubleshooting

GHCR image visibility:
Make sure the pushed packages are public for a public demo, or configure image
pull credentials in the target namespaces for private packages.

`ImagePullBackOff`:
Check the image repository owner, package visibility, tag spelling, and whether
`v1.0.0` has been built before applying the Applications.

Argo CD sync errors:
Confirm the `repoURL` owner was replaced, the repo is accessible to Argo CD, and
the Helm value file path is visible from `charts/aks-store`.

Kargo credentials:
The skeleton does not create real credentials. Add repository credentials that
allow Kargo to clone and push the GitOps repo. Add registry credentials if GHCR
packages are private.
