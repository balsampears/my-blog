#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="${REPO_ROOT}/.deploy-gh-pages"
TARGET_BRANCH="gh-pages"
SITE_URL="https://balsampears.github.io/my-blog/"

cd "${REPO_ROOT}"

if ! command -v hugo >/dev/null 2>&1; then
  echo "Error: hugo not found. Please install Hugo first."
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: current directory is not a git repository."
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: working tree is not clean. Please commit or stash changes first."
  exit 1
fi

echo "==> Building site with Hugo..."
hugo --minify

echo "==> Preparing ${TARGET_BRANCH} worktree..."
if [[ -d "${DEPLOY_DIR}" ]]; then
  git worktree remove "${DEPLOY_DIR}" --force
fi

if git ls-remote --exit-code --heads origin "${TARGET_BRANCH}" >/dev/null 2>&1; then
  git worktree add -B "${TARGET_BRANCH}" "${DEPLOY_DIR}" "origin/${TARGET_BRANCH}"
else
  git worktree add -B "${TARGET_BRANCH}" "${DEPLOY_DIR}"
fi

echo "==> Syncing public/ to ${TARGET_BRANCH}..."
rm -rf "${DEPLOY_DIR:?}/"*
cp -R "${REPO_ROOT}/public/." "${DEPLOY_DIR}/"

cd "${DEPLOY_DIR}"

touch .nojekyll
git add -A

if git diff --cached --quiet; then
  echo "==> No changes to publish."
else
  COMMIT_MSG="发布: $(date '+%Y-%m-%d %H:%M:%S')"
  git commit -m "${COMMIT_MSG}"
  git push -u origin "${TARGET_BRANCH}"
  echo "==> Publish complete: ${SITE_URL}"
fi

cd "${REPO_ROOT}"
git worktree remove "${DEPLOY_DIR}" --force
