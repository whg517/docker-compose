# docker-compose

本项目为个人记录常用 docker-compose 文件的地方，方便统一管理和同步使用。

## 准备

首先需要一个容器环境，可以是 [Docker](https://docs.docker.com/get-started/) 也可以是 [containerd](https://containerd.io/) 。
鉴于 Docker 这几年政策的调整，和容器化社区的发展，如果你要在一个新的环境中使用容器，建议你使用 [containerd](https://containerd.io/) 。

安装环境不是本项目的重点，所以仅列出需要的技术和相关引用连接。

### containerd

参考 [Getting started](https://containerd.io/docs/getting-started/) 安装 containerd 。

参考 [containerd/nerdctl](https://github.com/containerd/nerdctl) 安装为 containerd 适配的 Docker 命令。让你像使用 Docker 和 docker-compose 一样
使用 containerd 。

### Docker

请参照 [Get Docker](https://docs.docker.com/get-docker/) 中安装最新的 Docker 环境。

然后参照 [Install Docker Compose](https://docs.docker.com/compose/install/) 安装最新版本的 docker-compose 。

## 服务

- Elastic APM
- ElasticSearch + Kibana
- gitlab-runner
- grafana
- jenkins
- kafka
- logstach
- mongodb
- mysql
- nifi
- portainer
- prometheus
- proxy
- rabbitmq
- redis
  - redis 单节点
  - redis HA
- redisinsight
- skywakling
- sonarqube
- splash

## 注意

如果你打算直接 Fork 该仓库然后直接使用。建议在使用自己的配置或者本地配置的时候，将文件名命名为 `local` 前缀，这样 Git 会忽略该文件。

不按建议提交任何有关安全（如用户名，密码等）的内容到 Git 上。如果确实需要传入，可以在 docker-compose 文件中读取目录下的 `.env` 文件。
该文件是不会被 Git 记录的。

该仓库中的任何示例都不应该使用具体的 IP ，如 `192.168.88.12` 或 `10.10.50.23` 等。内网环境下的真实 IP 地址不便于迁移，而且经常改动
会增加重复且不必要的提交记录。推荐规划 Docker 的子网，将容器加入到需要连接的容器所在在子网，然后通过主机名相互访问。

我的实践做法是创建三个子网：

- app 子网：应用相关容器所在子网。
- db 子网：存储数据相关容器所在子网
- other 子网：不符合上面的两种情况下，放在该子网。

容器需要连接的服务在哪个子网，就加入该子网。例如有个容器在 other 子网，但它需要和 MySQL 通信，又需要连接一个在 app 子网里面的 web 容器，
这个容器就会加入三个子网，然后通过主机名和两个容器通信。
