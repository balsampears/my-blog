+++
date = '2026-04-09T13:49:15+08:00'
draft = false
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
笔者的思路是将二级菜单作为侧边栏的一级菜单使用
## (1).修改 menus.toml 中的配置
```
[[main]]
name = "Hugo教程"
url = "/posts/hugo/hugo-start"
weight = 20
identifier = "hugo"

[[main]]
name = "使用Hugo搭建个人博客"
url = "/posts/hugo/hugo-start"
weight = 10
parent = "hugo"

[[main]]
name = "Hugo高级用法"
url = "/posts/hugo/hugo-high"
weight = 20
parent = "hugo"
```
其中identifier指定一个父标识，parent指定父菜单

## (2).创建侧边栏文件 layouts/posts/single.html
```
{{ define "header" }}{{ partials.Include "page-header.html" . }}{{ end }}
{{ define "main" }}
  {{- $page := . -}}
  {{- $rootID := "" -}}

  {{/* Find current root item by URL matching against main menu and its children. */}}
  {{- $currentURL := strings.TrimSuffix "/" $page.RelPermalink -}}
  {{- with site.Menus.main -}}
    {{- range . -}}
      {{- $itemURL := strings.TrimSuffix "/" .URL -}}
      {{- if and (eq $rootID "") (ne .Identifier "") (eq $itemURL $currentURL) -}}
        {{- $rootID = .Identifier -}}
      {{- end -}}
      {{- with .Children -}}
        {{- range . -}}
          {{- $childURL := strings.TrimSuffix "/" .URL -}}
          {{- if and (eq $rootID "") (eq $childURL $currentURL) -}}
            {{- $rootID = .Parent -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  <div class="mw9 center ph3 ph4-ns mt4 flex-l">
    <aside class="w-25-l pr4-l mb4 mb0-l">
      {{- if ne $rootID "" -}}
        {{- range site.Menus.main -}}
          {{- if eq .Identifier $rootID -}}
            <h3 class="f5 mt0 mb3">{{ .Name }}</h3>
            {{- with .Children -}}
              <ul class="list pl0">
                {{- range . -}}
                  {{- $linkClass := "link dark-gray" -}}
                  {{- if $page.IsMenuCurrent .Menu . -}}
                    {{- $linkClass = printf "%s fw6 black" $linkClass -}}
                  {{- else if $page.HasMenuCurrent .Menu . -}}
                    {{- $linkClass = printf "%s fw6" $linkClass -}}
                  {{- end -}}
                  <li class="mb2">
                    <a class="{{ $linkClass }}" href="{{ .URL }}">{{ .Name }}</a>
                  </li>
                {{- end -}}
              </ul>
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    </aside>
    <article class="w-75-l">
      <h1 class="f2 mt0">{{ .Title }}</h1>
      <div class="nested-copy-line-height lh-copy f4 nested-links {{ $.Param "text_color" | compare.Default "mid-gray" }}">
        {{ .Content }}
      </div>
    </article>
  </div>
{{ end }}
```

最终效果图：
{{< figure src="image.png" alt="效果图" width="900" >}}