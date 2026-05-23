#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)
APP_DIR=${APP_DIR:-$(cd "$ROOT_DIR/.." && pwd)/kargo-demo-aks-store-app}

required_files=(
  "$ROOT_DIR/kargo/project.yaml"
  "$ROOT_DIR/kargo/warehouse.yaml"
  "$ROOT_DIR/kargo/promotiontask.yaml"
  "$ROOT_DIR/kargo/stages.yaml"
  "$ROOT_DIR/kargo/scenarios/health-gate/project.yaml"
  "$ROOT_DIR/kargo/scenarios/health-gate/analysis-template.yaml"
  "$ROOT_DIR/kargo/scenarios/health-gate/stages.yaml"
  "$ROOT_DIR/kargo/scenarios/release-manifest/project.yaml"
  "$ROOT_DIR/kargo/scenarios/release-manifest/warehouse.yaml"
  "$ROOT_DIR/kargo/scenarios/release-manifest/promotiontask.yaml"
  "$ROOT_DIR/kargo/scenarios/release-manifest/stages.yaml"
  "$ROOT_DIR/kargo/scenarios/manual-freight/project.yaml"
  "$ROOT_DIR/kargo/scenarios/manual-freight/warehouse.yaml"
  "$ROOT_DIR/kargo/scenarios/manual-freight/promotiontask.yaml"
  "$ROOT_DIR/kargo/scenarios/manual-freight/stages.yaml"
  "$ROOT_DIR/kargo/scenarios/manual-freight/README.md"
  "$ROOT_DIR/argocd/scenarios/health-gate/applications.yaml"
  "$ROOT_DIR/argocd/scenarios/release-manifest/applications.yaml"
  "$ROOT_DIR/argocd/scenarios/manual-freight/applications.yaml"
  "$ROOT_DIR/release-manifests/aks-store/current.yaml"
  "$ROOT_DIR/scripts/scenarios/release-manifest/status.sh"
  "$ROOT_DIR/scripts/scenarios/manual-freight/apply.sh"
  "$ROOT_DIR/scripts/scenarios/manual-freight/status.sh"
  "$ROOT_DIR/scripts/scenarios/manual-freight/cleanup.sh"
  "$ROOT_DIR/scripts/scenarios/manual-freight/build-demo-images.sh"
  "$APP_DIR/.github/workflows/release-service.yaml"
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || {
    echo "Missing required file: $file" >&2
    exit 1
  }
done

grep -q "name: aks-store-health-gate" "$ROOT_DIR/kargo/scenarios/health-gate/project.yaml"
grep -q "kind: AnalysisTemplate" "$ROOT_DIR/kargo/scenarios/health-gate/analysis-template.yaml"
grep -q "verification:" "$ROOT_DIR/kargo/scenarios/health-gate/stages.yaml"
grep -q "name: intentionally-failing-health-check" "$ROOT_DIR/kargo/scenarios/health-gate/stages.yaml"
grep -q "non-existent-service.aks-store-health-test.svc.cluster.local" "$ROOT_DIR/kargo/scenarios/health-gate/stages.yaml"

grep -q "name: aks-store-release-manifest" "$ROOT_DIR/kargo/scenarios/release-manifest/project.yaml"
grep -q "git:" "$ROOT_DIR/kargo/scenarios/release-manifest/warehouse.yaml"
grep -q "includePaths:" "$ROOT_DIR/kargo/scenarios/release-manifest/warehouse.yaml"
grep -q "release-manifests/aks-store/current.yaml" "$ROOT_DIR/kargo/scenarios/release-manifest/warehouse.yaml"
grep -q "uses: yaml-parse" "$ROOT_DIR/kargo/scenarios/release-manifest/promotiontask.yaml"
grep -q "uses: yaml-update" "$ROOT_DIR/kargo/scenarios/release-manifest/promotiontask.yaml"
grep -q "images.storeFront.repository" "$ROOT_DIR/kargo/scenarios/release-manifest/promotiontask.yaml"
grep -q "images.storeFront.tag" "$ROOT_DIR/kargo/scenarios/release-manifest/promotiontask.yaml"
grep -q "images.productService.repository" "$ROOT_DIR/kargo/scenarios/release-manifest/promotiontask.yaml"
grep -q "images.productService.tag" "$ROOT_DIR/kargo/scenarios/release-manifest/promotiontask.yaml"
grep -q "images.orderService.repository" "$ROOT_DIR/kargo/scenarios/release-manifest/promotiontask.yaml"
grep -q "images.orderService.tag" "$ROOT_DIR/kargo/scenarios/release-manifest/promotiontask.yaml"

grep -q "kargo.akuity.io/authorized-stage: aks-store-health-gate:dev" "$ROOT_DIR/argocd/scenarios/health-gate/applications.yaml"
grep -q "kargo.akuity.io/authorized-stage: aks-store-health-gate:test" "$ROOT_DIR/argocd/scenarios/health-gate/applications.yaml"
grep -q "kargo.akuity.io/authorized-stage: aks-store-health-gate:prod" "$ROOT_DIR/argocd/scenarios/health-gate/applications.yaml"

grep -q "kargo.akuity.io/authorized-stage: aks-store-release-manifest:dev" "$ROOT_DIR/argocd/scenarios/release-manifest/applications.yaml"
grep -q "kargo.akuity.io/authorized-stage: aks-store-release-manifest:test" "$ROOT_DIR/argocd/scenarios/release-manifest/applications.yaml"
grep -q "kargo.akuity.io/authorized-stage: aks-store-release-manifest:prod" "$ROOT_DIR/argocd/scenarios/release-manifest/applications.yaml"


grep -q "service:" "$APP_DIR/.github/workflows/release-service.yaml"
grep -q "store-front" "$APP_DIR/.github/workflows/release-service.yaml"
grep -q "product-service" "$APP_DIR/.github/workflows/release-service.yaml"
grep -q "order-service" "$APP_DIR/.github/workflows/release-service.yaml"
grep -Fq "version must match ^v[0-9]+\.[0-9]+\.[0-9]+$" "$APP_DIR/.github/workflows/release-service.yaml"

grep -q "name: aks-store-manual-freight" "$ROOT_DIR/kargo/scenarios/manual-freight/project.yaml"
grep -q "name: manual-release" "$ROOT_DIR/kargo/scenarios/manual-freight/warehouse.yaml"
grep -q "freightCreationPolicy: Manual" "$ROOT_DIR/kargo/scenarios/manual-freight/warehouse.yaml"
grep -q "kargo-demo-store-front" "$ROOT_DIR/kargo/scenarios/manual-freight/warehouse.yaml"
grep -q "kargo-demo-product-service" "$ROOT_DIR/kargo/scenarios/manual-freight/warehouse.yaml"
grep -q "kargo-demo-order-service" "$ROOT_DIR/kargo/scenarios/manual-freight/warehouse.yaml"
grep -q "allowTagsRegexes:" "$ROOT_DIR/kargo/scenarios/manual-freight/warehouse.yaml"
grep -q "discoveryLimit: 50" "$ROOT_DIR/kargo/scenarios/manual-freight/warehouse.yaml"
grep -q "name: promote-manual-release" "$ROOT_DIR/kargo/scenarios/manual-freight/promotiontask.yaml"
grep -q "images.storeFront.tag" "$ROOT_DIR/kargo/scenarios/manual-freight/promotiontask.yaml"
grep -q "images.productService.tag" "$ROOT_DIR/kargo/scenarios/manual-freight/promotiontask.yaml"
grep -q "images.orderService.tag" "$ROOT_DIR/kargo/scenarios/manual-freight/promotiontask.yaml"
grep -q "warehouse('manual-release')" "$ROOT_DIR/kargo/scenarios/manual-freight/promotiontask.yaml"

manual_stage_count=$(grep -c '^kind: Stage$' "$ROOT_DIR/kargo/scenarios/manual-freight/stages.yaml")
[[ "$manual_stage_count" -eq 3 ]] || {
  echo "Expected exactly three manual-freight stages, found $manual_stage_count" >&2
  exit 1
}

grep -q "name: dev" "$ROOT_DIR/kargo/scenarios/manual-freight/stages.yaml"
grep -q "name: test" "$ROOT_DIR/kargo/scenarios/manual-freight/stages.yaml"
grep -q "name: prod" "$ROOT_DIR/kargo/scenarios/manual-freight/stages.yaml"
grep -q "name: manual-release" "$ROOT_DIR/kargo/scenarios/manual-freight/stages.yaml"

grep -q "aks-store-manual-dev" "$ROOT_DIR/argocd/scenarios/manual-freight/applications.yaml"
grep -q "aks-store-manual-test" "$ROOT_DIR/argocd/scenarios/manual-freight/applications.yaml"
grep -q "aks-store-manual-prod" "$ROOT_DIR/argocd/scenarios/manual-freight/applications.yaml"
grep -q "kargo.akuity.io/authorized-stage: aks-store-manual-freight:dev" "$ROOT_DIR/argocd/scenarios/manual-freight/applications.yaml"
grep -q "kargo.akuity.io/authorized-stage: aks-store-manual-freight:test" "$ROOT_DIR/argocd/scenarios/manual-freight/applications.yaml"
grep -q "kargo.akuity.io/authorized-stage: aks-store-manual-freight:prod" "$ROOT_DIR/argocd/scenarios/manual-freight/applications.yaml"
grep -q "environments-manual/dev/values.yaml" "$ROOT_DIR/argocd/scenarios/manual-freight/applications.yaml"
grep -q "environments-manual/test/values.yaml" "$ROOT_DIR/argocd/scenarios/manual-freight/applications.yaml"
grep -q "environments-manual/prod/values.yaml" "$ROOT_DIR/argocd/scenarios/manual-freight/applications.yaml"

for env in dev test prod; do
  values="$ROOT_DIR/environments-manifest/$env/values.yaml"
  [[ -f "$values" ]] || {
    echo "Missing manifest scenario values file: $values" >&2
    exit 1
  }
  grep -q "environment: $env" "$values"
  grep -q "storeFront:" "$values"
  grep -q "productService:" "$values"
  grep -q "orderService:" "$values"
done

for env in dev test prod; do
  values="$ROOT_DIR/environments-manual/$env/values.yaml"
  [[ -f "$values" ]] || {
    echo "Missing manual Freight scenario values file: $values" >&2
    exit 1
  }
  grep -q "environment: $env" "$values"
  grep -q "images:" "$values"
  grep -q "storeFront:" "$values"
  grep -q "productService:" "$values"
  grep -q "orderService:" "$values"
  grep -q "tag: v1.0.0" "$values"
done

grep -q "kind: ReleaseManifest" "$ROOT_DIR/release-manifests/aks-store/current.yaml"
grep -q "storeFront:" "$ROOT_DIR/release-manifests/aks-store/current.yaml"
grep -q "productService:" "$ROOT_DIR/release-manifests/aks-store/current.yaml"
grep -q "orderService:" "$ROOT_DIR/release-manifests/aks-store/current.yaml"

echo "Scenario smoke test passed."
