+++
date = '2026-05-14T20:00:00+08:00'
draft = false
title = '命令与工具'
description= 'Go常用的命令与工具'
weight = 30
+++

## 一.编译与运行 - go run
go源代码是跨平台的，编译后的机器码是限制目标平台，直接运行在目标平台。java源代码和编译后的字节码都是跨平台的，运行在JVM。
- go 到处编译，直接运行
- java 一次编译，到处运行

### 1.编译并直接运行
`go run main.go`

### 2.编译并生成可执行文件
`go build ` 当前目录编译

### 3.编译目标平台
```
# 编译到windows 
GOOS=windows GOARCH=arm64 go build 
# 编译到linux 
GOOS=linux GOARCH=arm64 go build 
# 编译到mac 
GOOS=darwin GOARCH=arm64 go build 

# 查看所有合法架构
go tool dist list
```

## 二.包管理 - go install 
通过go install安装的通常是二进制可执行程序。
```
# 安装
go install <package>@latest

# 查看可执行程序
ls $(go env GOPATH)/bin

# 删除可执行程序
rm $(go env GOPATH)/bin/<tool-name>
# 删除指定包缓存
go clean -i <package>
# 删除模块缓存（下载了源码但没有生成二进制文件可通过这里命令删除）
go clean -modcache
```


## 三.模块管理 - go mod
在golang 1.16之后，go默认使用模块化管理。通过创建一个依赖描述文件，自动下载相关库，类似java中的maven、前端的package.json。

### 1.常见命令
```
# 初始化项目
go mod init <项目名>
# 自动安装引用项目中引用的依赖，移除未引用的依赖
go mod tidy
# 查询依赖
go mod graph

# 下载依赖
go get -u <package>
# 下载依赖最新版本
go get -u <package>@latest

```

### 2.查询依赖
[官网查询](https://pkg.go.dev/)

### 3.go mod与go install区别
- go mod
安装项目依赖库，安装的程序是项目需要的功能。如decimal提供精确化的小数操作。
- go install
安装可执行程序，安装的程序通常可以用命令行直接执行。

## 四.环境配置 - go env
```
# 查询所有环境变量
go env 
# 查询特定变量
go env GOPATH
# 设定环境变量
go env -w GOBIN=XXX
```

### 重要环境变量
- GOPATH 工作目录
- GOROOT Go安装目录
- GOBIN 安装目录，为空默认是GOPATH/bin

## 五.LSP - gopls
LSP（Language Server Protocol）是编辑器代码智能提示功能，而gopls是go官方提供的LSP。

### 安装
```
# 安装gopls
go install golang.org/x/tools/gopls@latest

# 查看
ps aux | grep gopls
```

### 工作流程
- 启动编辑器 -> gopls启动 -> 打开go文件 -> gopls分析代码
- 编辑go文件 -> gopls代码提示
- 关闭go文件 -> gopls代码补全
- 关闭编辑器 -> gopls关闭