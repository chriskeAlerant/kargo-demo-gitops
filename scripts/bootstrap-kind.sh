#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
CLUSTER_NAME=${KIND_CLUSTER_NAME:-kargo-demo}
KIND_CONFIG=${KIND_CONFIG:-}
TEMP_CONFIG=

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need kind
need kubectl

if [[ -z "$KIND_CONFIG" ]]; then
  if [[ -f "$ROOT_DIR/../plan/kind-config.yaml" ]]; then
    KIND_CONFIG="$ROOT_DIR/../plan/kind-config.yaml"
  else
    TEMP_CONFIG=$(mktemp)
    KIND_CONFIG="$TEMP_CONFIG"
    cat > "$KIND_CONFIG" <<'YAML'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
  - role: worker
  - role: worker
networking:
  apiServerAddress: "0.0.0.0"
  apiServerPort: 6443
YAML
  fi
fi

cleanup() {
  [[ -n "$TEMP_CONFIG" ]] && rm -f "$TEMP_CONFIG"
}
trap cleanup EXIT

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  echo "kind cluster already exists: $CLUSTER_NAME"
else
  kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
fi

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace kargo --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace aks-store-dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace aks-store-test --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace aks-store-prod --dry-run=client -o yaml | kubectl apply -f -

echo "kind cluster and namespaces are ready."
