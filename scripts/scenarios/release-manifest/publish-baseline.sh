#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/../../.." && pwd)
MANIFEST="$ROOT_DIR/release-manifests/aks-store/current.yaml"

cat > "$MANIFEST" <<'YAML'
apiVersion: demo.kargo.io/v1alpha1
kind: ReleaseManifest
metadata:
  name: aks-store-baseline
spec:
  application: aks-store
  releaseId: aks-store-baseline
  components:
    storeFront:
      repository: ghcr.io/chriskealerant/kargo-demo-store-front
      tag: v1.0.0
    productService:
      repository: ghcr.io/chriskealerant/kargo-demo-product-service
      tag: v1.0.0
    orderService:
      repository: ghcr.io/chriskealerant/kargo-demo-order-service
      tag: v1.0.0
YAML

git -C "$ROOT_DIR" add release-manifests/aks-store/current.yaml
git -C "$ROOT_DIR" commit -m "release: aks-store-baseline" || {
  echo "No baseline manifest changes to commit."
  exit 0
}
git -C "$ROOT_DIR" push
