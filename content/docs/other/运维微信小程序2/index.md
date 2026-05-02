+++
date = '2026-05-02T20:00:00+08:00'
draft = false
title = '运维微信小程序2'
weight = 30
+++


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
不过，阿里云镜像地址不好用，笔者使用时经常会报错：`Error response from daemon: Get "https://registry-1.docker.io/v2/": context deadline exceeded (Client.Timeout exceeded while awaiting headers)`
解决方式有两种：
- 方式一：  
本地拉取导出镜像，然后上传到服务器。
- 方式二：  
在`https://github.com/dongyubin/DockerHub`寻找

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
      - /usr/bin/docker:/usr/bin/docker
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
搜索安装：Git、Docker Pipeline、SSH Agent

### 3. ssh秘钥和主机秘钥
1. 配置凭证  
现在需要让jenkins有权限访问git仓库。  
（1）在本地生成一个SSH，注意查看生成的地址和文件名
```
ssh-keygen -t rsa -C "邮箱"
```
秘钥文件在：~/.ssh/id_rsa

（2）在git仓库保存ssh公钥

（3）进入 Mange Jenkins - Credentials - Add Credentials， 选择 SSH Username with private key，输入秘钥并记录下ID
{{< figure src="jenkins_1.png" width="700" >}}
{{< figure src="jenkins_2.png" width="400" >}}
{{< figure src="jenkins_3.png" width="400" >}}

2. 配置主机秘钥  
jenkins需要信任仓库地址域名，添加主机秘钥。笔者采用设置known_hosts方式。  
（1）进入jenkins容器内部，设置known_hosts文件  
```
docker exec -it jenkins bash
# 进入后执行
mkdir -p /var/jenkins_home/.ssh
ssh-keyscan -t rsa gitee.com >> /var/jenkins_home/.ssh/known_hosts
# 如果后续构建失败，提示需要ED25519算法验证，则使用：
ssh-keyscan -t ed25519 gitee.com >> /var/jenkins_home/.ssh/known_hosts

# 尝试连接录入fingerprint，这一步可能会失败但不用处理
ssh -T git@gitee.com
```

（2）检查jenkins校验主机方式
进入：Manage Jenkins → Security → Git Host Key Verification Configuration  
选择：Known hosts file 即可。  
若选择：No Verification 则不会进行主机校验，非生产环境适用。

### 4.构建前端流水线-拉取代码
1. 创建一个流水线任务
{{< figure src="jenkins_4.png" width="700" >}}

2. 禁止并发构建和重启构建  
- Do not allow concurrent builds  
- Do not allow the pipeline to resume if the controller restarts  
勾选以上两项

3. 配置git仓库地址  
依次选择：Configure - Pipeline - Pipeline Script，并写入以下内容。点击保存。
```
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git branch: 'master', //填入分支
                    url: 'https://github.com/你的用户名/你的前端仓库.git',
                    credentialsId: '你的凭证ID'  // 私有库填，公开库删掉
                echo '✅ 代码拉取成功！'
            }
        }
    }
}
```
最后在这个项目中，点击Build Now，即可查看构建成功。

### 5.构建前端流水线-编译代码
在stages添加下列脚本
```
    stage('Build') {
    steps {
        script {
            docker.image('node:20-alpine').inside('-v $PWD:/app -w /app -v /var/jenkins_cache/npm:/root/.npm') {
                sh '''#!/bin/sh
                    set -eu

                    node -v
                    npm -v
                    pwd

                    # 检查锁文件
                    test -f package-lock.json

                    # 设置镜像源（加速下载）
                    npm config set registry https://registry.npmmirror.com

                    # 安装依赖（严格版本 + 优先使用缓存）
                    npm ci --prefer-offline --no-audit --no-fund

                    # 执行构建
                    npm run build

                    echo "✅ 构建完成"
                '''
            }
        }
    }
}
```

**QA**
1. 镜像拉取失败  
在宿主机拉取/上传对应版本的镜像，则构建时就可以直接使用镜像。

2. npm error `npm ci` can only install packages when your package.json and package-lock.json or npm-shrinkwrap.json are in sync. Please update your lock file with `npm install` before continuing.  
需要本地运行npm install，git重新提交package-lock.json。

### 6.构建前端流水线-部署发布
构建了一个新的docker来发布
```
stage('Deploy') {
    steps {
        script {
            sh '''#!/bin/sh
                set -eu

                echo "WORKSPACE=${WORKSPACE}"
                APP_NAME="${JOB_NAME}"
                HOST_PORT="8081"
                HOST_WORKSPACE_ROOT="/home/ecs-user/jenkins_home/workspace"
                HOST_WORKSPACE="${HOST_WORKSPACE_ROOT}/${JOB_NAME}"

                # 构建产物必须存在
                test -d "${WORKSPACE}/build"

                # 生成 nginx-conf/default.conf
                mkdir -p "${WORKSPACE}/nginx-conf"
                cat > "${WORKSPACE}/nginx-conf/default.conf" << 'NGINX_EOF'
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
    }
}
NGINX_EOF

test -f "${WORKSPACE}/nginx-conf/default.conf"
ls -la "${WORKSPACE}/nginx-conf"

                # 清理旧容器
                docker ps -q -f name="^${APP_NAME}$" | xargs -r docker stop || true
                docker ps -a -q -f name="^${APP_NAME}$" | xargs -r docker rm || true

                # 启动新容器（目录挂载，避免文件/目录类型冲突）
                # docker run 调用的是宿主机 Docker，-v 左侧路径必须使用宿主机路径
                docker run -d \
                    --name "${APP_NAME}" \
                    -p "${HOST_PORT}:80" \
                    -v "${HOST_WORKSPACE}/build:/usr/share/nginx/html:ro" \
                    -v "${HOST_WORKSPACE}/nginx-conf:/etc/nginx/conf.d:ro" \
                    nginx:1.26.2-alpine

                echo "✅ 部署完成：http://<你的主机IP>:${HOST_PORT}"
            '''
        }
    }
}
```

### 7.构建前端流水线-健康检查

```
stage('Health Check') {
    steps {
        script {
            sh '''#!/bin/sh
                set -eu

                APP_NAME="${JOB_NAME}"
                HEALTH_URL="http://127.0.0.1/"
                MAX_RETRIES=10
                SLEEP_SECONDS=5

                echo ">>> 开始健康检查，目标容器: ${APP_NAME}"

                i=1
                while [ "${i}" -le "${MAX_RETRIES}" ]; do
                    echo "尝试 ${i}/${MAX_RETRIES} ..."

                    # 在 nginx 容器内访问自身，避免 Jenkins 容器 localhost 指向错误
                    if docker exec "${APP_NAME}" wget -q -O /dev/null "${HEALTH_URL}"; then
                        echo "✅ 健康检查通过！"
                        break
                    fi

                    if [ "${i}" -lt "${MAX_RETRIES}" ]; then
                        echo "健康检查未通过，等待 ${SLEEP_SECONDS}s 后重试..."
                        sleep ${SLEEP_SECONDS}
                    else
                        echo "❌ 健康检查失败！已重试 ${MAX_RETRIES} 次仍无法访问"
                        docker logs "${APP_NAME}" || true
                        exit 1
                    fi

                    i=$((i + 1))
                done
            '''
        }
    }
}
```
最后，通过：公网IP:8081访问jenkins部署的前端网站。