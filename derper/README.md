# tailscale derper

自建 tailscale derper

ref:

- <https://tailscale.com/kb/1118/custom-derp-servers/>
- <https://github.com/fredliang44/derper-docker>

环境说明：

- isp: aliyun
- os: rockylinux 9.2

## feature

- [x] 支持 TLS ，使用 Caddy 自动申请证书
- [x] 使用 Caddy 代理 derper ，可以和现有的 Caddy 配置共存，当然也可以使用 nginx 代理
- [x] 使用 docker-compose 部署

## usage

### 环境准备

**域名配置：**

如果需要使用域名，请将域名解析到当前主机。

**iptables配置：**

使用 iptables 管理防火墙策略。虽然 rockylinux 在 9.0 弃用了 iptables ，但是 tailscale 依然使用 iptables 管理网络，为了
解决 tailscale 在 [CGNAT 上的问题](https://github.com/tailscale/tailscale/issues/3104)，需要使用 iptables 额外配置部分防火墙规则。

在 rockylinux 中启用 iptables 请参考 [Enabling iptables Firewall](https://docs.rockylinux.org/pt/guides/security/enabling_iptables_firewall/)

```bash
systemctl stop firewalld
systemctl disable firewalld
dnf install iptables-services iptables-utils
systemctl enable --now iptables
```

**docker安装：**

你需要在本地安装好 docker 环境。docker ce 可以根据 [Install Docker Engine](https://docs.docker.com/engine/install/) 操作。

在 rockylinux 中安装 docker

```bash
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl --now enable docker
```

### 安装并登录 tailscale

官网安装方式：

<https://pkgs.tailscale.com/stable/#fedora>

```bash
# Add the tailscale repository
sudo dnf -y config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
# Install Tailscale
sudo dnf -y install tailscale
# Enable and start tailscaled
sudo systemctl enable --now tailscaled
# Start Tailscale!
sudo tailscale up
```

由于国内网络环境，使用 dnf 下载不动，需要手动下载：

```bash
# 在本地开启代理，然后使用 wget 下载

latest_release=$(curl -s "https://api.github.com/repos/tailscale/tailscale/releases/latest" | grep -oP '"tag_name": "\K(.*)(?=")')
wget https://pkgs.tailscale.com/stable/fedora/x86_64/tailscale_${latest_release#v}_x86_64.rpm /tmp/

sudo systemctl enable --now tailscaled

sudo tailscale up
```

安装并登录 tailscale ，然后在开启 derp 的时候验证客户端，避免自己的 derp 服务被别人使用。详见 [限制加密流量的路由位置
](https://tailscale.com/kb/1118/custom-derp-servers/#to-restrict-where-encrypted-traffic-is-routed)

### 创建工作目录

```bash
# 创建工作目录
mkdir -p /opt/deploy/derper
# 创建 docker 数据目录
mkdir -p /data/docker

mkdir -p /data/docker/derper/config

# 创建 caddy 数据目录
mkdir -p /data/docker/caddy/config
mkdir /data/docker/caddy/data

# 创建网站目录
mkdir /data/wwwroot
```

### 配置文件

创建 compose 文件 `/opt/deploy/derper/docker-compose.yml`

```yaml
version: "3.9"

x-base: &default-config
  restart: unless-stopped
  ulimits:
    nproc: 65535
    nofile:
      soft: 20000
      hard: 40000
  stop_grace_period: 1m
  logging:
    driver: json-file
    options:
      max-size: '100m'
      max-file: '1'
  mem_swappiness: 0

services:
  derper:
    <<: *default-config
    image: fredliang/derper
    container_name: derper
    ports:
      - '3478:3478/udp'
    environment:
      DERP_ADDR: ":80"
      DERP_VERIFY_CLIENTS: true
    volumes:
      - /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock

  server:
    image: caddy:2
    << : *default-config
    env_file:
      - .env
    ports:
      - 80:80
      - 443:443
    volumes:
      - ${PWD}/Caddyfile:/etc/caddy/Caddyfile
      - /data/docker/caddy:/data/caddy
      - /data/wwwroot/:/wwwroot

```

说明：

- 配置 derp 服务使用 `:80` ，启动 HTTP 服务，而不是 HTTPS 。
- 使用 Caddy 代理 derp ，并提供域名，Caddy 会自动申请证书。
- derp 默认启用 stun ，所以需要暴露 `3478/udp` 端口。将 derp 容器的 3478/udp 端口映射到主机，供 tailscale 通信使用。
- 为了防止 derp 被别人使用，需要开启客户端验证，使用环境变量 `DERP_VERIFY_CLIENTS` 开启。同时需要在当前主机登录 tailscale ，并挂载 `tailscaled.sock` 。

#### 创建 caddy 配置

创建 Cadyfile 文件 `/opt/deploy/derper/Caddyfile`

```txt
{
    log {
        output stdout
        format console
    }
}

{$DERP_DOMAIN} {
    log {
        output stdout
        format console
    }
    route /.well-known/* {
        root * /data/wwwroot/{$DERP_DOMAIN}/
        file_server
    }
    reverse_proxy / derper {
        header_up Host {host}
        header_up X-Real-IP {remote}
        header_up X-Forwarded-For {remote}
        header_up X-Forwarded-Proto {scheme}
    }
}
```

说明：

caddy 配置文件中使用 `{$DERP_DOMAIN}` 从环境变量中读取域名，所以需要在 `.env` 文件中配置 `DERP_DOMAIN` 变量。

#### 创建配置文件

创建 `/opt/deploy/derper/.env` 文件

```ini
DERP_DOMAIN=derp.example.com
```

将 `DERP_DOMAIN` 换成你自己的域名。如果没有域名，可以使用当前公网IP。

#### 不使用 caddy 反向代理 （第二种操作）

```yaml
version: "3.9"

x-base: &default-config
  restart: unless-stopped
  ulimits:
    nproc: 65535
    nofile:
      soft: 20000
      hard: 40000
  stop_grace_period: 1m
  logging:
    driver: json-file
    options:
      max-size: '100m'
      max-file: '1'
  mem_swappiness: 0

services:
  derper:
    <<: *default-config
    image: fredliang/derper
    container_name: derper
    env_file:
      - .env
    ports:
      - 443:443
      - '3478:3478/udp
    # environment:
    #   DERP_ADDR: ":80"
    #   DERP_VERIFY_CLIENTS: true
    volumes:
      - /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock
```

### 启动

```bash
docker compose up -d
```

## FQA

### 阿里云网络问题

ref:

- [Tailscale出口节点无网络问题的调试与分析](https://nyan.im/p/troubleshoot-tailscale)
- [Tailscale 与阿里云八字不合的解决方法（下）：寻根](https://zhuanlan.zhihu.com/p/653295049)
- [FR: do not add ipfilter rule to drop 100.64.0.0/10 when ipv4 is disabled](https://github.com/tailscale/tailscale/issues/3837)
- [FR: netfilter CGNAT mode when non-Tailscale CGNAT addresses should be allowed](https://github.com/tailscale/tailscale/issues/3104)
