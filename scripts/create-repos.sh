#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
GITOPS_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
APP_DIR=${APP_DIR:-$(cd "$GITOPS_DIR/.." && pwd)/kargo-demo-aks-store-app}

APP_REPO=${APP_REPO:-kargo-demo-aks-store-app}
GITOPS_REPO=${GITOPS_REPO:-kargo-demo-gitops}
VISIBILITY=${GITHUB_REPO_VISIBILITY:-public}

if [[ "$VISIBILITY" != "public" && "$VISIBILITY" != "private" ]]; then
  echo "GITHUB_REPO_VISIBILITY must be 'public' or 'private'." >&2
  exit 1
fi

if [[ -z "${GITHUB_OWNER:-}" ]]; then
  GITHUB_OWNER=$(gh api user --jq .login)
fi

if [[ ! -d "$APP_DIR" ]]; then
  echo "App directory not found: $APP_DIR" >&2
  exit 1
fi

replace_placeholders() {
  local dir=$1
  find "$dir" -type f \
    ! -path "*/.git/*" \
    ! -path "*/node_modules/*" \
    -exec sed -i "s#chriskeAlerant#$GITHUB_OWNER#g" {} +
}

ensure_github_repo() {
  local repo=$1
  local description=$2

  if gh repo view "$GITHUB_OWNER/$repo" >/dev/null 2>&1; then
    echo "GitHub repo already exists: $GITHUB_OWNER/$repo"
    return
  fi

  if [[ "$VISIBILITY" == "private" ]]; then
    gh repo create "$GITHUB_OWNER/$repo" --private --description "$description"
  else
    gh repo create "$GITHUB_OWNER/$repo" --public --description "$description"
  fi
}

push_local_repo() {
  local dir=$1
  local repo=$2
  local remote_url="https://github.com/$GITHUB_OWNER/$repo.git"

  (
    cd "$dir"
    if [[ ! -d .git ]]; then
      git init -b main
    fi

    git remote get-url origin >/dev/null 2>&1 && git remote set-url origin "$remote_url" || git remote add origin "$remote_url"
    git add .

    if git diff --cached --quiet; then
      echo "No staged changes in $dir"
    else
      git commit -m "Initial Kargo demo skeleton"
    fi

    git push -u origin HEAD:main
  )
}

echo "Using GitHub owner: $GITHUB_OWNER"
echo "Using repository visibility: $VISIBILITY"

replace_placeholders "$APP_DIR"
replace_placeholders "$GITOPS_DIR"

ensure_github_repo "$APP_REPO" "Application source for the Kargo AKS Store demo"
ensure_github_repo "$GITOPS_REPO" "GitOps configuration for the Kargo AKS Store demo"

push_local_repo "$APP_DIR" "$APP_REPO"
push_local_repo "$GITOPS_DIR" "$GITOPS_REPO"

echo "Done."
