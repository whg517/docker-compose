# docker-compose

> 最近发现有不少人关注到了我的这个仓库。非常荣幸我的过往经验形成的知识能给大家提供帮助。
> 为了方便大家对仓库变更有具体的了解，我增加了一个 [ChangeLog](./ChangeLog.md) 文件，记录了每次变更的内容。
> 如果你有任何问题，欢迎提 ISSUE 。

本项目为个人记录常用 docker-compose 文件的地方，方便统一管理和同步使用。

将常用的 docker-compose 放在 Github 中管理，可以在使用的很方便的找到。如果是在常用的开发环境，只需要将项目克隆到工作目录，
在后续使用时，如果有调整或者增加的服务，都能很方便的同步。如果不是常用环境，只需要在浏览器中打开本项目，将需要的配置文件
复制下来即可。

## 环境准备

首先需要一个容器环境，可以是 [Docker](https://docs.docker.com/get-started/) 也可以是 [containerd](https://containerd.io/) 。
鉴于 Docker 这几年政策的调整，和容器化社区的发展，如果你要在一个新的环境中使用容器，建议你使用 [containerd](https://containerd.io/) 。

安装环境不是本项目的重点，所以仅列出需要的技术和相关引用连接。

### containerd

推荐使用 [containerd](https://containerd.io/) 作为后端容器工具，即使未来再安装 kubernetes 时，也可以轻松应对。

参考 [Getting started](https://containerd.io/docs/getting-started/) 安装 containerd 。

参考 [containerd/nerdctl](https://github.com/containerd/nerdctl) 安装为 containerd 适配的 Docker 命令。让你像使用 Docker 和 docker-compose 一样
使用 containerd 。

### Docker

请参照 [Get Docker](https://docs.docker.com/get-docker/) 中安装最新的 Docker 环境。

然后参照 [Install Docker Compose](https://docs.docker.com/compose/install/) 安装最新版本的 docker-compose 。

## 初始化网络

推荐先对容器环境做子网规划，并预先初始化外部子网。在启动服务时，将容器关联到子网。

在服务间容器通信时，不依赖宿主机地址，通过内部主机名(容器名)即可通信。这样也避免了
一些不需要暴露出来的端口。例如对于一个 Web 服务，有三个容器，分别是 `app` 、
`restapi` 和 `pgsql` 。其中 `app` 容器对外暴露 `8080` 端口，可以将该端口映射到宿主机，然后
通过宿主机的 `9090` 访问前端页面。对于 `app` 访问后端 `restapi` 容器，只需要通过内部主机名和
端口就可以了。而后端容器 `restapi` 在访问 `pgsql` 时，也是以同样的方式。外部其实无法访问到
服务的后端容器，甚至不知道后端数据库的内容。既减少了端口占用，又能保证后端和数据库服务的
安全性。

我的做法是除了默认的几个网络之外，会在创建三个网络：

- app 子网：应用相关容器所在子网。
- db 子网：存储数据相关容器所在子网
- other 子网：不符合上面的两种情况下，放在该子网。

所有 docker-compose 都不应该依赖具体主机 IP ，例如 `192.168.22.102` 。

## 使用

克隆项目

```bash
https://github.com/whg517/docker-compose.git
```

然后切换到你想要启动的服务的目录，执行 `nerdctl compose up -d` 或者 `docker-compose up -d` 。

如果有自定义需求，更改文件即可。

## 已有服务

- [alist](https://alist.nn.ci/)：一个可以连接多种后端存储用来做网盘的开源项目
- Elastic APM
- [aria2](https://aria2.github.io/)：一个突破单线程下载的下载工具，通过油猴脚本可以突破百度云限速
- [caddy](https://caddyserver.com/docs/)：一个使用 go 开发的代理服务器，本地运行可以将某个目录作为文件服务器在内网共享
- ElasticSearch + Kibana
- gitlab-runner
- grafana
- jenkins
- kafka
- lakehouse
  - trino-iceberg：基于docker实现的 pg+minio+trino+iceberg 的湖仓方案，详细文档已完成
- logstach
- mariadb
- minio
- mongodb
- mysql
- nifi
- postgres
- portainer
- prometheus
- proxy：一个使用 v2fly 客户端服务，为本地提供代理
- rabbitmq
- redis
  - redis 单节点
  - redis HA
- redisinsight
- skywakling
- sonarqube
- splash
- [wiki.js](https://js.wiki/)：一个轻量的文档管理系统，可以用来做个人 wiki

## 注意

如果你打算直接 Fork 该仓库然后直接使用。建议在使用自己的配置或者本地配置的时候，将文件名命名为 `local` 前缀，这样 Git 会忽略该文件。

不按建议提交任何有关安全（如用户名，密码等）的内容到 Git 上。如果确实需要传入，可以在 docker-compose 文件中读取目录下的 `.env` 文件。
该文件是不会被 Git 记录的。
