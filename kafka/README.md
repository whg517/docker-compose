# Kafka docker-compose.yml

:ref [wurstmeister/kafka](https://hub.docker.com/r/wurstmeister/kafka)

## 使用

如果出现问题，请增加环境变量 `KAFKA_ADVERTISED_HOST_NAME=<docker host ip>`，正确配置
docker 宿主机 IP。

在 `docker-compose.yml` 同级目录新建 `.env` 文件，增加如下记录

```env
KAFKA_ADVERTISED_HOST_NAME=192.168.1.1
```

### 注意

docker-compose.yml 文件中有一个环境变量 `HOSTNAME_COMMAND: "route -n | awk '/UG[ \t]/{print $$2}'"`， 请
务必采用这种方式设置，虽然根据 [Docker compose 文档](https://docs.docker.com/compose/compose-file/#environment)
有两种方式配置。但仅在使用 `$$2` 的方式下传递到容器中的变量才是正常的，否则将无法正确获取变量。
