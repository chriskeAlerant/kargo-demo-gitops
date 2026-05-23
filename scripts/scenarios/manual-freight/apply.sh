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

render_and_apply "$ROOT_DIR/argocd/scenarios/manual-freight/applications.yaml"
render_and_apply "$ROOT_DIR/kargo/scenarios/manual-freight/project.yaml"
kubectl wait --for=jsonpath='{.status.phase}'=Active namespace/aks-store-manual-freight --timeout=60s || true
render_and_apply "$ROOT_DIR/kargo/scenarios/manual-freight/warehouse.yaml"
render_and_apply "$ROOT_DIR/kargo/scenarios/manual-freight/promotiontask.yaml"
render_and_apply "$ROOT_DIR/kargo/scenarios/manual-freight/stages.yaml"

cat <<'NOTE'
Manual Freight Assembly scenario resources applied.

Repository credentials are intentionally not created by this script. Add Kargo
project credentials for GitHub clone/push access if your demo setup requires them.
NOTE
