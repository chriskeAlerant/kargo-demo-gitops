#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/../../.." && pwd)

kubectl delete -f "$ROOT_DIR/kargo/scenarios/manual-freight/stages.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/kargo/scenarios/manual-freight/promotiontask.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/kargo/scenarios/manual-freight/warehouse.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/kargo/scenarios/manual-freight/project.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/argocd/scenarios/manual-freight/applications.yaml" --ignore-not-found
kubectl delete namespace aks-store-manual-dev aks-store-manual-test aks-store-manual-prod --ignore-not-found
