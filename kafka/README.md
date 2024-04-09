# Kafka docker-compose.yml

:ref [bitnami/kafka](https://hub.docker.com/r/bitnami/kafka)

## 使用

```bash
$ docker-compose up -d
```

### 注意

如果内部和外部客户端都可以访问Apache Kafka，需要为他们分别设置对应的listener。

```diff
+     - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093,EXTERNAL://0.0.0.0:9094
+     - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092,EXTERNAL://localhost:9194
+     - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,EXTERNAL:PLAINTEXT,PLAINTEXT:PLAINTEXT

```

然后暴漏这个外部端口，比如：
```diff
    ports:
-     - '9092:9092'
+     - '9194:9094'
```
以上更新中 9194 是外部端口，9094 是内部端口。

**重要**： 如果外部机器需要访问Kafka，那么需要将 `KAFKA_CFG_ADVERTISED_LISTENERS` 配置中的 `EXTERNAL` 的 `localhost`替换为外部IP/域名; `KAFKA_CFG_LISTENERS` 配置中的 `EXTERNAL` 设置为 `0.0.0.0:9094`。


## 集群部署