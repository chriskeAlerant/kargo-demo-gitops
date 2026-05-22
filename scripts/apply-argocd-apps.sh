#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

if [[ -z "${GITHUB_OWNER:-}" ]]; then
  GITHUB_OWNER=$(gh api user --jq .login)
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

sed "s#chriskeAlerant#$GITHUB_OWNER#g" "$ROOT_DIR/argocd/applications.yaml" > "$tmp"
kubectl apply -f "$tmp"

echo "Argo CD Applications applied."
