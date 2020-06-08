# gitlab-runner docker-compose.yml

:ref [Run GitLab Runner in a container](https://docs.gitlab.com/runner/install/docker.html)

## gitlab-runner 配置

详细文档参考 [Registering Runners](https://docs.gitlab.com/runner/register/)

#### 进入容器：

```bash
docker exec -it  gitlab-runner /bin/bash
```

#### 注册 Runner：

参考 [One-line registration command](https://docs.gitlab.com/runner/register/#one-line-registration-command)

```bash
gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.com/" \
  --registration-token "PROJECT_REGISTRATION_TOKEN" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "docker-runner" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected"
```

#### 注册可以在任务中运行 docker 命令的 gitlab-runner：

参考 [Use Docker socket binding](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-socket-binding)

这里指定参数 `docker-volumes`，如果在使用任务中需要使用 docker 镜像进行 `docker` 相关命令操作，会将 `docker.sock` 挂在到
启动的 docker 容器中。这个参数是关键。

建议 runner 注册时都增加这个参数，方便以后需要使用 docker 命令的时候可用。

```yml
gitlab-runner register -n \
  --url https://gitlab.com/ \
  --registration-token REGISTRATION_TOKEN \
  --executor docker \
  --description "My Docker Runner" \
  --docker-image "alpine:latest" \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock
```

> 注册的时候可用手动增加 `-locked="false"` 指定共享该 runner 。注册之后也是可用更改的 参考：[Locking a specific Runner from being enabled for other projects](https://docs.gitlab.com/ee/ci/runners/#locking-a-specific-runner-from-being-enabled-for-other-projects)

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