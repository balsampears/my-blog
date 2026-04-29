+++
date = '2026-04-09T20:00:00+08:00'
draft = true
title = '运维一个微信小程序'
weight = 100
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

## 六. 自动构建

### 1.Docker安装配置
```
# 使用阿里镜像源安装docker
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce

# 设置开机启动，现在立刻启动
sudo systemctl enable --now docker

# 给当前用户添加docker用户组，避免使用docker命令总需要sudo（重新登录生效）
sudo usermod -aG docker ecs-user
```

#### 配置加速镜像源
为了后续拉取镜像方便，可以在阿里云找“镜像容器服务”，获取加速器地址。
```
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://你的ID.mirror.aliyuncs.com"]
}
EOF

# 重新加载配置并重启docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```
不过，即使是配置了镜像地址，也不一定可以获取镜像，这时只能本地拉取导出镜像，然后上传到服务器。


#### docker常见命令
```
# 镜像操作
# 查询镜像列表
docker images 
# 删除镜像
docker images rm 镜像名
# 拉取镜像
docker pull 镜像名:版本号

# 容器操作
# 查询容器列表
docker ps
# 开始/停止/重启容器
docker start/stop/restart 容器名
# 删除容器
docker rm 容器名
# 容器详情
docker inspect 容器名

# 通过docker-compose.yml拉取并后台启动一个容器
# 在docker-compose.yml同一个目录下执行：
docker compose up -d

# 查看docker信息
docker info
```

### 2.Jenkins安装配置
1. 创建一个jenkins目录，并且创建jenkins的docker文件
```
mkdir jenkins_home
cd jenkins_home
# 创建文件
cat > docker-compose.yml <<'EOF'
services:
  jenkins:
    image: jenkins/jenkins:2.555.1-lts
    container_name: jenkins
    restart: always
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - ~/jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    user: root
EOF

# 根据docker-compose文件创建容器
sudo docker compose up -d
```
需要注意的是，如果使用sudo执行，则jenkins容器卷volume目录会在/root/jenkins_home，而不是当前用户的/home/ecs_user/jenkins_home。

2. 启动成功后，查询jenkins密码：
```
sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

3. 在阿里云ECS，安全组-入方向，添加8080端口放行
   
4. 在浏览器输入：公网IP:8080 即可进入jenkins。
   - 选择“选择插件来安装”，选择“无”后安装
   - 选择不创建用户。
   - 实例配置中，直接选择”保存并完成“。
  
5. 创建一个用户  
依次选择 Manage Jenkins - Manage User - Create User， 然后就可以创建一个用户  

6. 替换插件安装源（可选）  
如果安装插件速度很慢，可以替换源  
Manage Jenkins > Plugins > Advanced：  
https://mirrors.huaweicloud.com/jenkins/updates/update-center.json

7. 安装插件  
进入 Manage Jenkins - Plugins - Available plugins  

//todo 未完待续