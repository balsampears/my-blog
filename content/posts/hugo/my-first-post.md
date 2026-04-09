+++
date = '2026-04-09T13:49:15+08:00'
draft = true
title = '使用Hugo搭建个人博客'
menu = 'hugo'
+++

## 开始一个hugo项目
```
hugo new site quickstart
cd quickstart
git init
git submodule add https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/ananke
echo "theme = 'ananke'" >> hugo.toml
hugo server
```

## 创建一篇文章
```
hugo new content/posts/my-first-post.md
```

## 启动hugo
```
hugo server -D
```

## 发布
```
hugo
```