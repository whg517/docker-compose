# Caddy

ref:

- [Caddy document](https://caddyserver.com/docs/)
- [Caddy image](https://hub.docker.com/_/caddy)

提供 docker-compose 服务和 podman kube 服务。

## 使用

### 增加配置文件

创建 `Caddyfile` 文件，文件内容如下：

```text
:80 {
    root * /var/wwwroot/
    file_server
}
```

该文件表示启动一个 `80` 端口的 Web 服务，加载 `/var/wwwroot` 目录作为网站静态文件目录，默认会加载 `index.html` 。

后面操作将会挂在此文件到容器中，用来启动 caddy 服务。请将该文件放在你想放置目录。

### docker-compose

```bash
docker-compose up -d
```

### podman

启动：

```bash
podman play kube playkube.yml
```

销毁：

```bash
podman play kube --down playkube.yml
```
