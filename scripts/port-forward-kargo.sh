#!/usr/bin/env bash
set -euo pipefail

LOCAL_PORT=${KARGO_LOCAL_PORT:-8081}

echo "Kargo UI: http://localhost:$LOCAL_PORT"
kubectl -n kargo port-forward svc/kargo-api "$LOCAL_PORT:443"
