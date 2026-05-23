#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/../../.." && pwd)

kubectl delete -f "$ROOT_DIR/kargo/scenarios/health-gate/stages.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/kargo/scenarios/health-gate/promotiontask.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/kargo/scenarios/health-gate/warehouse.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/kargo/scenarios/health-gate/analysis-template.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/kargo/scenarios/health-gate/project.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/argocd/scenarios/health-gate/applications.yaml" --ignore-not-found
kubectl delete namespace aks-store-health-dev aks-store-health-test aks-store-health-prod --ignore-not-found
