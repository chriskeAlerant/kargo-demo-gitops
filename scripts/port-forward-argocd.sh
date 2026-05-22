#!/usr/bin/env bash
set -euo pipefail

LOCAL_PORT=${ARGOCD_LOCAL_PORT:-8080}

echo "Argo CD UI: https://localhost:$LOCAL_PORT"
echo "Initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo

kubectl -n argocd port-forward svc/argocd-server "$LOCAL_PORT:443"
