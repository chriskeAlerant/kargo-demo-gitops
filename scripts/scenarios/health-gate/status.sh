#!/usr/bin/env bash
set -euo pipefail

kubectl get warehouses -n aks-store-health-gate
kubectl get stages -n aks-store-health-gate
kubectl get freight -n aks-store-health-gate
kubectl get promotions -n aks-store-health-gate
kubectl get analysisruns -n aks-store-health-gate || true
kubectl get applications -n argocd | grep aks-store-health || true
