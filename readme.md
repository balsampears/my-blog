# my-blog

个人博客项目，使用 Hugo 构建并发布到 GitHub Pages。

线上地址：`https://balsampears.github.io/my-blog/`

---

## 1. 环境搭建（Go / Hugo / Git）

### 1.1 必需环境

- Git（用于拉取与发布代码）
- Hugo Extended（用于本地预览和构建）

> 说明：使用 Hugo CLI 本身不强依赖本机安装 Go；只有在你要自行编译 Hugo、开发 Go 程序或部分高级扩展场景时才需要 Go。

### 1.2 macOS 安装（推荐）

```bash
# Git（通常系统已自带）
git --version

# Hugo Extended
brew install hugo
hugo version
```

---

## 2. 启动项目（本地预览）

在仓库根目录执行：

```bash
hugo server -D
```

访问地址：

- `http://localhost:1313/my-blog/`

参数说明：

- `-D`：包含草稿文章（`draft: true`）

---

## 3. 构建与发布流程

### 3.1 本地构建（不发布）

```bash
hugo --minify
```

构建产物目录：`public/`

### 3.2 一键发布到 GitHub Pages

执行：

```bash
bash scripts/deploy.sh
```

脚本会自动完成：

1. 校验本地环境与 git 状态
2. 执行 `hugo --minify`
3. 将 `public/` 内容同步到 `gh-pages` 分支
4. 提交并推送到远端

### 3.3 GitHub Pages 必要配置（首次）

仓库设置路径：`Settings > Pages`

- Source: `Deploy from a branch`
- Branch: `gh-pages`
- Folder: `/(root)`

首次推送后通常需要等待几分钟生效。

---

## 4. 编写博客文档（文章）

### 4.1 新建文章

```bash
hugo new posts/my-new-post/index.md
```

生成后编辑：`content/posts/my-new-post/index.md`

### 4.2 常用 Front Matter

```toml
+++
title = "文章标题"
date = 2026-04-09T20:00:00+08:00
draft = true
tags = ["hugo", "blog"]
categories = ["技术"]
+++
```

建议：

- 写作阶段保持 `draft = true`
- 准备发布前改为 `draft = false`

### 4.3 插入图片

推荐把图片放到文章目录下，例如：

- `content/posts/my-new-post/cover.png`

在文章中引用：

```md
![封面图](cover.png)
```

### 4.4 发布前检查清单

- 文章 `draft` 已关闭（或你确认发布草稿）
- 本地预览无样式/链接异常
- 执行过 `bash scripts/deploy.sh`
- 等待 1-5 分钟后访问线上地址确认

---

## 5. 常见问题

### 5.1 发布成功但网页 404

优先检查：

- 是否访问了正确地址：`https://balsampears.github.io/my-blog/`
- `Settings > Pages` 是否配置为 `gh-pages` + `/(root)`
- 是否刚发布，尚在生效中（等几分钟）

### 5.2 本地命令找不到 `hugo`

重新安装并确认：

```bash
brew install hugo
hugo version
```
