# APM

[APM](https://www.elastic.co/guide/en/apm/get-started/7.12/index.html) 是 Elastic 下的一个应用程序监控解决方案。

## 部署相关文档

[APM-server 手动安装](https://www.elastic.co/guide/en/apm/server/7.12/installing.html)
[APM-server Docker 部署](https://www.elastic.co/guide/en/apm/server/7.12/running-on-docker.html)
[APM-server Docker 镜像](https://hub.docker.com/_/apm-server)
[APM-server Dockerfile](https://github.com/elastic/apm-server/blob/master/Dockerfile)
[APM-server 配置文档](https://www.elastic.co/guide/en/apm/server/7.12/configuration-process.html)

## 配置

[Configure APM Server on Docker](https://www.elastic.co/guide/en/apm/server/7.12/running-on-docker.html#_configure_apm_server_on_docker)

在配置 APM 时，支持多种方式。

### 通过命令传递配置

APM 启动命令支持使用 `-E` 传递配置：

```yml
version: "3.7"
services:
  apm:
    container_name: apm7
    image: docker.elastic.co/apm/apm-server:7.14.2
    # volumes: 
    #   - ./apm-server.docker.yml:/usr/share/apm-server/apm-server.yml:ro
    environment:
      output.elasticsearch.hosts: es7:9200
    # Default command: -e -d
    # -d show log to stderr
    # use -E pass overwrite configuration.
    command: -e -E output.elasticsearch.hosts=["es7:9200"] -E apm-server.kibana.enabled=true -E apm-server.kibana.host=http://kibana7:5601 -E apm-server.rum.enable=true
    ports: 
      - 8200:8200
    logging:
      options:
          max-size: "100M"
          max-file: "1"
    ulimits:
      memlock:
        soft: -1
        hard: -1

# es7 and kibana7 in db network.
networks:
  default:
    external: true
    name: db

```

### 使用配置文件覆盖默认配置

通过将 APM 的配置挂在到镜像中将配置传递到 `/usr/share/apm-server/apm-server.yml` 中，以覆盖默认配置。

```yaml
apm-server:
  host: "0.0.0.0:8200"
  rum:
    enabled: true
  kibana:
    enabled: true
    host: http://kibana7:5601

output:
  elasticsearch:
    hosts: es7:9200

queue.mem.events: 4096

max_procs: 4

```

## 使用

部署并正确连接到 ES 中后，可以在 Kibana 的左侧导航栏中的 `Observability` 二级导航下找到 `APM` ，点击 `设置说明` ，
在 `APM Server 状态` 后面有个 `检查 APM Server 状态` 的按钮，点击后可以检查 APM-server 状态。如果一切正常的话，
会显示绿色的提示 `您已正确设置 APM Server` 。此时 APM-server 就已经配置完成了。

后续就可以继续跟着 [APM-server 快速开始](https://www.elastic.co/guide/en/apm/get-started/current/install-and-run.html)的文档
进行后续的工作。
