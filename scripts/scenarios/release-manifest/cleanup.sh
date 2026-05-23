#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/../../.." && pwd)

kubectl delete -f "$ROOT_DIR/kargo/scenarios/release-manifest/stages.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/kargo/scenarios/release-manifest/promotiontask.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/kargo/scenarios/release-manifest/warehouse.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/kargo/scenarios/release-manifest/project.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/argocd/scenarios/release-manifest/applications.yaml" --ignore-not-found
kubectl delete namespace aks-store-manifest-dev aks-store-manifest-test aks-store-manifest-prod --ignore-not-found
