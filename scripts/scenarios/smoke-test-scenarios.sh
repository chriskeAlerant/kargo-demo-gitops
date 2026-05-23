#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)

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
  "$ROOT_DIR/argocd/scenarios/health-gate/applications.yaml"
  "$ROOT_DIR/argocd/scenarios/release-manifest/applications.yaml"
  "$ROOT_DIR/release-manifests/aks-store/current.yaml"
  "$ROOT_DIR/scripts/scenarios/release-manifest/status.sh"
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

grep -q "kind: ReleaseManifest" "$ROOT_DIR/release-manifests/aks-store/current.yaml"
grep -q "storeFront:" "$ROOT_DIR/release-manifests/aks-store/current.yaml"
grep -q "productService:" "$ROOT_DIR/release-manifests/aks-store/current.yaml"
grep -q "orderService:" "$ROOT_DIR/release-manifests/aks-store/current.yaml"

echo "Scenario smoke test passed."
