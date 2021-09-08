# APM

[APM](https://www.elastic.co/guide/en/apm/get-started/7.12/index.html) 是 Elastic 下的一个应用程序监控解决方案。

## 部署相关文档

[APM-server 手动安装](https://www.elastic.co/guide/en/apm/server/7.12/installing.html)
[APM-server Docker 部署](https://www.elastic.co/guide/en/apm/server/7.12/running-on-docker.html)
[APM-server Docker 镜像](https://hub.docker.com/_/apm-server)
[APM-server 配置文档](https://www.elastic.co/guide/en/apm/server/7.12/configuration-process.html)

## 配置

在部署时，由于 APM-server 的 Docker 部署不支持传入环境变量，传入 ES 的地址需要通过命令行参数，在 docker-compose 中使用有点麻烦。
所以采用加载 APM-server 配置文件的方式配置 APM-server 。

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
