# Logstach

## Docker 部署相关引用

- [Docker Official Images](https://hub.docker.com/_/logstash)
- [Running Logstash on Docker](https://www.elastic.co/guide/en/logstash/current/docker.html)
- [Configuring Logstash for Docker](https://www.elastic.co/guide/en/logstash/current/docker-config.html)
- [Directory Layout of Docker Images](https://www.elastic.co/guide/en/logstash/current/dir-layout.html#docker-layout)
- [Logstash Configuration Files](https://www.elastic.co/guide/en/logstash/current/config-setting-files.html)
- [logstash.yml](https://www.elastic.co/guide/en/logstash/current/logstash-settings-file.html)

## 配置

Logstash 的配置包含两部分，一个是 `settings` 用来配置 Logstash 本身的，一个是 `conf` 用来配置任务的。

- `settings` 的配置默认位置在 `/usr/share/logstash/config` ，里面包含 `logstash.yml` 和 `jvm.options`
- `conf` 的默认位置在 `/usr/share/logstash/pipeline` ，里面默认是什么都没有的。你需要根据实际情况创建自己的配置。

如果你需要配置多工作流位置，需要在增加 `settings` 配置，即在 `/usr/share/logstash/config` 下新建 `pipelines.yml` 文件，增加自己的配置。
更多细节请查看 [Multiple Pipelines](https://www.elastic.co/guide/en/logstash/current/multiple-pipelines.html)

### Pipeline 配置

关于配置工作流的配置，可以查看 [Logstash Configuration Examples](https://www.elastic.co/guide/en/logstash/current/config-examples.html) 。

下面是一个简单的配置：

```conf
input {
  tcp {
    port => 5000
    type => syslog
  }
  udp {
    port => 5000
    type => syslog
  }
}

filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}

output {
  elasticsearch { hosts => ["localhost:9200"] }
  stdout { codec => rubydebug }
}
```

此示例配置通过监听 `tcp/5000` 端口，接收日志系统日志数据，然后写入 ES 。在实际使用过程中需要注意如下几点：

- 通过查看[`input-tcp` 插件文档](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-tcp.html#plugins-inputs-tcp-host) 得知，该插件会默认监听
  `0.0.0.0:5000` 。所以在 Docker 中使用时需要在 Logstash 容器所在子网中，通过主机名访问该端口写入数据。或者将此端口映射到宿主机，然后通过宿主机IP和映射的端口访问。
- 上述例子中的 `output-elasticsearch` 插件使用的地址是 `localhost` ，你应该根据实际情况修改，以便能正确写入到 ES 中。
