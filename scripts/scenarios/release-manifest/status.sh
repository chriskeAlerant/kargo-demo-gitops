#!/usr/bin/env bash
set -euo pipefail

kubectl get warehouses -n aks-store-release-manifest
kubectl get stages -n aks-store-release-manifest
kubectl get freight -n aks-store-release-manifest
kubectl get promotions -n aks-store-release-manifest
kubectl get applications -n argocd | grep aks-store-manifest || true
