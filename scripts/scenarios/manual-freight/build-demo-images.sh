#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${GITHUB_OWNER:-}" ]]; then
  GITHUB_OWNER=$(gh api user --jq .login)
fi

REPO="${GITHUB_OWNER}/kargo-demo-aks-store-app"

gh workflow run release-service.yaml \
  --repo "$REPO" \
  -f service=store-front \
  -f version=v1.0.7

gh workflow run release-service.yaml \
  --repo "$REPO" \
  -f service=product-service \
  -f version=v1.3.2

gh workflow run release-service.yaml \
  --repo "$REPO" \
  -f service=order-service \
  -f version=v1.1.9

echo "Dispatched manual Freight demo image builds in $REPO."
