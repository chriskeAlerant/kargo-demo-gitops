#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
APP_DIR=${APP_DIR:-$(cd "$ROOT_DIR/.." && pwd)/kargo-demo-aks-store-app}

required_files=(
  "$ROOT_DIR/charts/aks-store/Chart.yaml"
  "$ROOT_DIR/charts/aks-store/values.yaml"
  "$ROOT_DIR/environments/dev/values.yaml"
  "$ROOT_DIR/environments/test/values.yaml"
  "$ROOT_DIR/environments/prod/values.yaml"
  "$ROOT_DIR/argocd/applications.yaml"
  "$ROOT_DIR/kargo/project.yaml"
  "$ROOT_DIR/kargo/warehouse.yaml"
  "$ROOT_DIR/kargo/promotiontask.yaml"
  "$ROOT_DIR/kargo/stages.yaml"
  "$APP_DIR/.github/workflows/release-frontend.yaml"
  "$APP_DIR/.github/workflows/release-backend-bundle.yaml"
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || {
    echo "Missing required file: $file" >&2
    exit 1
  }
done

for env in dev test prod; do
  values="$ROOT_DIR/environments/$env/values.yaml"
  grep -q "environment: $env" "$values"
  grep -q "storeFront:" "$values"
  grep -q "productService:" "$values"
  grep -q "orderService:" "$values"
  grep -q "tag: v1.0.0" "$values"

  if command -v helm >/dev/null 2>&1; then
    helm template "aks-store-$env" "$ROOT_DIR/charts/aks-store" -f "$values" >/dev/null
  else
    echo "Skipping helm template for $env because helm is not installed."
  fi
done

grep -q "name: frontend" "$ROOT_DIR/kargo/warehouse.yaml"
grep -q "name: backend-bundle" "$ROOT_DIR/kargo/warehouse.yaml"
grep -q "name: promote-frontend" "$ROOT_DIR/kargo/promotiontask.yaml"
grep -q "name: promote-backend-bundle" "$ROOT_DIR/kargo/promotiontask.yaml"

stage_count=$(grep -c '^kind: Stage$' "$ROOT_DIR/kargo/stages.yaml")
[[ "$stage_count" -eq 3 ]] || {
  echo "Expected exactly three Kargo stages, found $stage_count" >&2
  exit 1
}

grep -q "name: dev" "$ROOT_DIR/kargo/stages.yaml"
grep -q "name: test" "$ROOT_DIR/kargo/stages.yaml"
grep -q "name: prod" "$ROOT_DIR/kargo/stages.yaml"

old_stages=(
  frontend-dev
  frontend-test
  frontend-prod
  backend-dev
  backend-test
  backend-prod
)

for stage in "${old_stages[@]}"; do
  if grep -q "name: $stage" "$ROOT_DIR/kargo/stages.yaml"; then
    echo "Obsolete Kargo stage still exists: $stage" >&2
    exit 1
  fi
done

if grep -q "^[[:space:]]*if:" "$ROOT_DIR/kargo/stages.yaml"; then
  echo "Stage task references must not use if conditions; put conditions inside PromotionTask steps." >&2
  exit 1
fi

grep -q "ctx.targetFreight.origin.name == \"frontend\"" "$ROOT_DIR/kargo/promotiontask.yaml"
grep -q "ctx.targetFreight.origin.name == \"backend-bundle\"" "$ROOT_DIR/kargo/promotiontask.yaml"

grep -q "kargo.akuity.io/authorized-stage: aks-store:dev" "$ROOT_DIR/argocd/applications.yaml"
grep -q "kargo.akuity.io/authorized-stage: aks-store:test" "$ROOT_DIR/argocd/applications.yaml"
grep -q "kargo.akuity.io/authorized-stage: aks-store:prod" "$ROOT_DIR/argocd/applications.yaml"

if command -v kubectl >/dev/null 2>&1 && kubectl cluster-info >/dev/null 2>&1; then
  kubectl get ns argocd kargo aks-store-dev aks-store-test aks-store-prod >/dev/null 2>&1 || true
fi

echo "Smoke test passed."
