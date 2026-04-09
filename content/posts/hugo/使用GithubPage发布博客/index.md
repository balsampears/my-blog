+++
date = '2026-04-09T14:05:08+08:00'
draft = false
title = '使用GithubPage发布博客'
slug = "hugo-githubPage-publish"
+++

# 一. Github仓库配置
## 1.发布代码到Github
这里大家都会，省略
## 2.设置Github Page
![设置页](setting_github_page.png)
这样做的目的是指定github page使用什么分支的代码、什么目录下的代码。

# 二. 发布
## 1.发布前准备
修改 config/_default/hugo.toml中的baseURL，指定为：  
baseUrl = '[你的用户名].github.io/[Github仓库名]'

## 2.运行发布脚本
编写一个脚本，具体功能：
1.使用hugo --minify 生成public编译后的html
2.切换到public目录，切换gh-pages分支
3.将public目录下的代码发送到gh-pages分支上  

将下面脚本放在 scripts/deploy.sh，运行它（scripts/deploy.sh）
```
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
```

## 3.访问
[你的用户名].github.io/[Github仓库名]  
注意：当发布到gh-pages时，可能需要1~5分钟才会刷新页面

## 4.使用Github Action发布（可选）
如果想监听分支提交，自动发布文档则可以使用Github Action
1. 重新设置Github Page
![设置页](setting_github_action.png)

2. 编写工作流
创建 .github/workflows/hugo.yml。当监听到master代码提交时，触发一次hugo构建，并将public代码发布到gh-pages分支上
```
name: Deploy Hugo site to Pages

on:
  push:
    branches: ["master"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      HUGO_VERSION: "0.160.1"
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v3
        with:
          hugo-version: ${{ env.HUGO_VERSION }}
          extended: true

      - name: Build
        run: hugo --minify

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./public

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

检查Github Action观察是否构建成功
