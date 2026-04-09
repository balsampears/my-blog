# my-blog

## 本地预览

```bash
hugo server -D
```

访问：`http://localhost:1313/my-blog/`

## 一键发布到 GitHub Pages

首次执行前请确认：

- 已安装 Hugo（建议 Extended 版本）
- 仓库 `Settings > Pages` 已设置为 `gh-pages` 分支 + `/ (root)`

执行发布：

```bash
bash scripts/deploy.sh
```

发布地址：

`https://balsampears.github.io/my-blog/`
