# gitlab-runner docker-compose.yml

:ref [Run GitLab Runner in a container](https://docs.gitlab.com/runner/install/docker.html)

为项目配置 gitlab runner。

## 使用说明

### 1. 启动 runner

  ```bash
  docker-compose up -d
  ```

### 2. 配置 runner

先进入容器内部

```bash
docker exec -it  gitlab-runner /bin/bash
```

在 runner 容器中运行 `gitlab-runner register` 命令注册。需要修改的参数有

- `--url` 为你的 gitlab 的地址
- `--registration-token` 为项目 runner 的 token

```bash
gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.com/" \
  --registration-token "PROJECT_REGISTRATION_TOKEN" \
  --executor "docker" \
  --docker-image "alpine:latest" \
  --description "docker-runner" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected"
```

一个 Runner 可以注册多个项目，如果某个项目不需要了，可以直接在项目上移除 runner 然后把对应的配置从 `/etc/gitlab-runner/config.toml`
中移除，然后使用 `gitlab-runner restart` 重启就可以了。或者直接将注册的 runner 设置为共享，其他项目可以直接启动，而不需要再次注册。

跟多使用参考后面说明，或者查看相关文档。

## gitlab-runner 配置

详细文档参考 [Registering Runners](https://docs.gitlab.com/runner/register/)

### 进入容器

```bash
docker exec -it  gitlab-runner /bin/bash
```

### 注册 Runner

参考 [One-line registration command](https://docs.gitlab.com/runner/register/#one-line-registration-command)

```bash
gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.com/" \
  --registration-token "PROJECT_REGISTRATION_TOKEN" \
  --executor "docker" \
  --docker-image "alpine:latest" \
  --description "docker-runner" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected"
```

### 注册可以在任务中运行 docker 命令的 gitlab-runner

场景描述：

有时候需要在 ci 中使用 `docker build` 或者 `docker run` 这些 docker 命令。这时候就需要使用支持 docker 运行的 runner 了。
使用这种 runner 并不会影响正常的 python 环境构建。因为该 runner 仅仅是一个执行器，用来解析 ci 文件，然后发起对应的 stage。
在 ci 文件中可以使用 `image: python:3.7` 标注后面的的 stage 默认全使用 python3.7 环境，如果对应 stage 需要使用其他环境，
只需要在对应 stage 中显式标注就行了，如在 Docker 构建的 stage 中需要使用 Docker 镜像，就需要标注为 `image: docker:19.03.8` 了。

参考 [Use Docker socket binding](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-socket-binding)

这里指定参数 `docker-volumes`，如果在使用任务中需要使用 docker 镜像进行 `docker` 相关命令操作，会将 `docker.sock` 挂在到
启动的 docker 容器中。这个参数是关键。

建议 runner 注册时都增加这个参数，方便以后需要使用 docker 命令的时候可用。

```bash
gitlab-runner register -n \
  --url https://gitlab.com/ \
  --registration-token REGISTRATION_TOKEN \
  --executor docker \
  --description "My Docker Runner" \
  --docker-image "alpine:latest" \
  --locked "false"
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock"
```

> 注册的时候可用手动增加 `--locked="false"` 指定共享该 runner 。注册之后也是可用更改的 参考：[Locking a specific Runner from being enabled for other projects](https://docs.gitlab.com/ee/ci/runners/#locking-a-specific-runner-from-being-enabled-for-other-projects)

或者手动增加如下配置，然后重启 gitlab-runner

```toml
[[runners]]
  url = "https://gitlab.com/"
  token = REGISTRATION_TOKEN
  executor = "docker"
  [runners.docker]
    tls_verify = false
    image = "docker:19.03.8"
    privileged = false
    disable_cache = false
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
  [runners.cache]
    Insecure = false
```

注册这个 runner 的项目就可以运行类似如下任务了：

```yml
build:
  image: docker:19.03.8
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

更多用法，请参考官方文档：[GitLab Docs](https://docs.gitlab.com/ee/README.html) 和 [GitLab Runner Docs](https://docs.gitlab.com/runner/)