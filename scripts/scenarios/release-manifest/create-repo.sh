#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/../../.." && pwd)

cat <<NOTE
This scenario stores release manifests in the GitOps repo:

  $ROOT_DIR/release-manifests/aks-store/current.yaml

No separate GitHub repository is required. Commit and push this repo after
publishing baseline or mixed manifests so Kargo can discover the manifest commit.
NOTE
