#!/usr/bin/env bash
set -euo pipefail

kubectl get warehouses -n aks-store-manual-freight
kubectl get freight -n aks-store-manual-freight
kubectl get stages -n aks-store-manual-freight
kubectl get promotions -n aks-store-manual-freight
kubectl get applications -n argocd | grep aks-store-manual || true

if command -v kargo >/dev/null 2>&1; then
  kargo get freight --project aks-store-manual-freight || true
fi
