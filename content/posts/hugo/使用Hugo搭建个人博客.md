+++
date = '2026-04-09T13:49:15+08:00'
draft = true
title = '使用Hugo搭建个人博客'
slug = "hugo-start"
+++

# 一. 开始
## 1.开始一个hugo项目
```
hugo new site quickstart
cd quickstart
git init
# 下载并应用一个主题
git submodule add https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/ananke
echo "theme = 'ananke'" >> hugo.toml
hugo server
```
## 1.创建一篇文章
```
hugo new content/posts/my-first-post.md
```
文章的头元数据如下：
```
+++
date = '2026-04-09T13:49:15+08:00'
draft = true #代表是草稿状态，草稿状态正常不会展示到个人博客上  
title = '使用Hugo搭建个人博客'
+++
```

## 3.启动hugo
```
hugo server -D # -D可以让草稿状态的文章也正常显示
```

# 二.创建菜单
## 1.更新配置
为了更好的维护配置，不要把配置都全部放在hugo.toml一个文件中
1. 创建目录 config/_default/，并将hugo.toml移入该目录

## 2.创建一级菜单配置
在 config/_default/ 创建 menus.toml 然后写入
```
[[main]]
name = "首页"
pageRef = "/"
weight = 10

[[main]]
name = "文章"
url = "/posts/hugo/hugo-start"
weight = 20
```
右上角即可出现一级菜单

## 3.创建二级菜单配置
ananke主题默认只展开一级菜单（site.Menus.main），所以需要自行添加二级菜单