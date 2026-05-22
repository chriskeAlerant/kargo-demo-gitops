#!/usr/bin/env bash
set -euo pipefail

KARGO_NAMESPACE=${KARGO_NAMESPACE:-kargo}
CERT_MANAGER_VERSION=${CERT_MANAGER_VERSION:-v1.16.1}
INSTALL_CERT_MANAGER=${INSTALL_CERT_MANAGER:-true}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need kubectl
need helm
need openssl

if [[ "$INSTALL_CERT_MANAGER" == "true" ]]; then
  kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/$CERT_MANAGER_VERSION/cert-manager.yaml"
  kubectl -n cert-manager rollout status deployment/cert-manager --timeout=300s
  kubectl -n cert-manager rollout status deployment/cert-manager-webhook --timeout=300s
  kubectl -n cert-manager rollout status deployment/cert-manager-cainjector --timeout=300s
fi

if [[ -z "${KARGO_ADMIN_PASSWORD_HASH:-}" ]]; then
  if ! command -v htpasswd >/dev/null 2>&1; then
    echo "htpasswd is required to generate a bcrypt password hash." >&2
    echo "Install apache2-utils, or set KARGO_ADMIN_PASSWORD_HASH yourself." >&2
    exit 1
  fi

  KARGO_ADMIN_PASSWORD=${KARGO_ADMIN_PASSWORD:-$(openssl rand -base64 48 | tr -d '=+/' | head -c 32)}
  KARGO_ADMIN_PASSWORD_HASH=$(htpasswd -bnBC 10 "" "$KARGO_ADMIN_PASSWORD" | tr -d ':\n')
  echo "Generated Kargo admin password: $KARGO_ADMIN_PASSWORD"
  echo "Store it somewhere safe; it is not written to this repository."
fi

KARGO_TOKEN_SIGNING_KEY=${KARGO_TOKEN_SIGNING_KEY:-$(openssl rand -base64 48 | tr -d '=+/' | head -c 32)}

helm upgrade --install kargo oci://ghcr.io/akuity/kargo-charts/kargo \
  --namespace "$KARGO_NAMESPACE" \
  --create-namespace \
  --set "api.adminAccount.passwordHash=$KARGO_ADMIN_PASSWORD_HASH" \
  --set "api.adminAccount.tokenSigningKey=$KARGO_TOKEN_SIGNING_KEY" \
  --wait

echo "Kargo is installed."
