#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/../../.." && pwd)

if [[ -z "${GITHUB_OWNER:-}" ]]; then
  GITHUB_OWNER=$(gh api user --jq .login)
fi

render_and_apply() {
  local file=$1
  local tmp
  tmp=$(mktemp)
  sed "s#chriskeAlerant#$GITHUB_OWNER#g" "$file" > "$tmp"
  kubectl apply -f "$tmp"
  rm -f "$tmp"
}

render_and_apply "$ROOT_DIR/argocd/scenarios/health-gate/applications.yaml"
render_and_apply "$ROOT_DIR/kargo/scenarios/health-gate/project.yaml"
kubectl wait --for=jsonpath='{.status.phase}'=Active namespace/aks-store-health-gate --timeout=60s || true
render_and_apply "$ROOT_DIR/kargo/scenarios/health-gate/analysis-template.yaml"
render_and_apply "$ROOT_DIR/kargo/scenarios/health-gate/warehouse.yaml"
render_and_apply "$ROOT_DIR/kargo/scenarios/health-gate/promotiontask.yaml"
render_and_apply "$ROOT_DIR/kargo/scenarios/health-gate/stages.yaml"

cat <<'NOTE'
Health-gate scenario resources applied.

Repository and registry credentials are intentionally not created by this script.
Add Kargo project credentials for GitHub pushes and private GHCR access if your
demo setup requires them.
NOTE
