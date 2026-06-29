+++
date = '2026-05-26T20:00:00+08:00'
draft = false
title = '配置https'
description= 'https添加ssl证书认证，防止不安全的连接'
tags = ['项目']
weight = 40
+++

## 一. 获取SSL免费证书
进入阿里云，搜索SSL（现在名称为[数字证书管理服务](https://yundun.console.aliyun.com/?spm=5176.2020520163.console-base_search-panel.dtab-product_cas.108b3711tGJKXi&p=cas#/instance/buy/cn-hangzhou)）

{{< figure src="https_1.png" width="700" >}}
点击购买证书，刚开始我们使用免费SSL即可，每个用户可以用20个/年，每个证书有效期3个月。

## 二. 申请SSL证书
购买成功后，回到SSL证书管理，点击申请证书，填写完资料提交后，一般10分钟之内会有结果。成功后，状态变为已签发。

## 三. 配置nignx
### 1. 下载证书
{{< figure src="https_2.png" width="700" >}}
点击下载，选择nginx类型，下载并解压缩后获得xxx.key xxx.pem，其中xxx是你申请的域名。

### 2. 上传证书
将xxx.key xxx.pem两个证书文件上传的云服务器中的/etc/nginx/cert/目录下

### 3. 配置nignx
修改对应网站的nginx配置，/etc/nginx/conf.d/default.conf
```
# HTTP → HTTPS 重定向
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

# HTTPS 服务
server {
    listen 443 ssl http2;
    server_name _;

    # ---------- 证书配置（请替换为实际路径）----------
    ssl_certificate      /etc/nginx/cert/xxx.pem;   
    ssl_certificate_key  /etc/nginx/cert/xxx.key;

    # ---------- 安全增强（推荐）----------
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # ---------- 代理到前端 ----------
    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;   
    }

    # ---------- 代理到后端 ----------
    location /api {
        proxy_pass http://127.0.0.1:8090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
**注意**  
proxy_pass要看末尾加/需要看情况：
1. 若后端请求时需要去除/api，则使用http://127.0.0.1:8090/
2. 若后端请求时保留/api，则使用http://127.0.0.1:8090
 

### 4. 重新nginx
```
sudo nginx -t && sudo systemctl reload nginx
```
在浏览器输入：https://域名，完成。