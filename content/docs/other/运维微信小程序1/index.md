+++
date = '2026-04-29T20:00:00+08:00'
draft = false
title = '运维微信小程序1'
weight = 20
+++

## 前置准备
1. 申请一个个体工商户/企业，拿到营业执照
2. 开通一个对公账户的银行卡
3. 分别购买服务器资源（以阿里云为例）：
   - 云服务器ECS
   - 云数据库RDS
   - 对象存储OSS
   - 域名，需要用到营业执照
   
## 一. 云服务器
选购服务器最好至少需要购买4G+8G的，因为我们需要在一台服务器上配置很多软件。

选择“远程连接”进入命令行模式。

### redis安装配置
```
sudo dnf install -y redis
sudo systemctl enable --now redis
```
#### 配置文件
/etc/redis.conf中，配置
```
sudo tee /etc/redis.conf <<'EOF'
bind 0.0.0.0
port 6379
daemonize no
requirepass 你的强密码
supervised systemd 
dir /var/lib/redis
EOF
```
需要重启：`sudo systemctl restart redis`

#### 外网访问redis（可选）
在“网络与安全组”中，添加入方向规则，端口6379，IP/4 0.0.0.0/0
{{< figure src="ecs_redis_nolimit.png" width="700" >}}

## 二. 云数据库
### 1.进入数据库
购买RDS后，可以在实例列表中选择登录数据库。如果没有看到，则可以切换地域查看你购买的地域RDS。
{{< figure src="rds_1.png" width="700" >}}
点击登录数据库后，会进入DMS，此时系统可能会让你创建一个DMS用户进行管理。
{{< figure src="rds_2.png" width="700" >}}
进入数据库详情，也能在”账号管理“中看到DMS创建的用户。
{{< figure src="rds_3.png" width="700" >}}

### 2.配置安全组
需要配置ECS的安全组，让其中程序可以访问RDS。
{{< figure src="rds_4.png" width="700" >}}

### 3.配置外网直连数据库
新建一个用户，选择“普通账户”，选择可访问的数据库+读写权限，输入密码，点击确认。
{{< figure src="rds_nolimit_1.png" width="700" >}}
配置白名单，选择全部放开。
{{< figure src="rds_nolimit_2.png" width="700" >}}

## 三. 对象存储OSS
### 1.创建一个RAM账号并分配权限
首先进入RAM控制台，用户 -> 创建用户
{{< figure src="oss_ram_1.png" width="700" >}}
命名为oss，不选择访问配置
{{< figure src="oss_ram_2.png" width="700" >}}
进入oss用户，创建AccessKey，选其他，然后将accessKey、accessSecret写入代码配置中
{{< figure src="oss_ram_3.png" width="700" >}}
{{< figure src="oss_ram_4.png" width="700" >}}
{{< figure src="oss_ram_5.png" width="700" >}}
最后给这个oss用户分配仅oss的权限  
在列表页点击授权，搜索oss，选择AliyunOSSFullAccess，确认新增授权
{{< figure src="oss_ram_6.png" width="700" >}}
{{< figure src="oss_ram_7.png" width="700" >}}

### 2.创建OSS Bucket
首先进入OSS控制台，创建Bucket，注意地域需要跟ECS保持一致
{{< figure src="oss_1.png" width="700" >}}
进入新增后的Bucket，查看概览，即可获取endpoint
{{< figure src="oss_2.png" width="700" >}}

## 四. 发布后端
### 1.安装jdk8
```
sudo dnf install -y java-1.8.0-openjdk
```
### 2.上传jar包
选择目录图片，选择当前用户名右键，选择本地文件上传
{{< figure src="backend_1.png" width="700" >}}

### 3.运行jar包
```
java -jar XXX.jar 
```
检查是否报错，修复之。  
在浏览器输入：公网IP/模块/doc.html（如果使用springfox-swagger），可以进入接口文档页面。

### 4.后台运行jar包
```
# 安装screen
sudo dnf install -y screen 
# 运行一个名为java的会话
screen -S java  
# 运行程序
java -jar XXX.jar 
# 退出当前会话
ctrl + a, d
# 查看所有会话
screen -ls 
# 重连接会话
screen -r java
```

## 五. 发布前端
### 1.安装nginx
```
sudo dnf install -y nginx
sudo systemctl enable --now nginx
```
ECS 控制台 → 实例 → 安全组，入方向放行：80端口、443端口  
然后在浏览器输入：公网IP，查看是否进入默认页面

### 2.上传前端代码
```
sudo mkdir -p /var/www/my-site
sudo chown -R nginx:nginx /var/www/   # 转让所有者
sudo chmod -R 775 /var/www            # 授权写入
sudo usermod -aG nginx "$USER"        # 给当前用户分配到nignx组
```
重新登录，即可拥有上传权限。
```
# 本地打包build目录代码，压缩打包
tar -czvf build.tar.gz build
# 上传到服务器后，解压缩
tar -xzvf build.tar.gz
```

### 3.配置nginx
在/etc/nginx/conf.d/目录下新增mysite.conf
```
server {
    listen 80;
    server_name _;
    root /var/www/my-site;
    index index.html;
}
```
最后重载nginx：
```
sudo nginx -t && sudo systemctl reload nginx
```
在浏览器输入：公网IP，即可看到前端页面。

**特别注意**  
在我国，使用域名服务必须进行ICP备案，没备案的域名很快就会被封。  
我们可以准备一个静态的简单界面做官网，然后进行域名备案。  
备案成功后，可以使用nignx，将后端api、jenkins等所有服务都改为使用域名进行访问。  
