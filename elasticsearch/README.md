# Elasticsearch 和 Kibana

## 1. Elasticsearch

Docker 部署相关引用:

- [Docker Official Images](https://hub.docker.com/_/elasticsearch)
- [Install Elasticsearch with Docker](https://www.elastic.co/guide/en/elasticsearch/reference/7.12/docker.html)

## 2. Kibana

Docker 部署相关引用:

- [Docker Official Images](https://hub.docker.com/_/kibana)
- [Install Kibana with Docker](https://www.elastic.co/guide/en/kibana/current/docker.html)

Kibana 支持国际化，可以通过修改容器中的 `/usr/share/kibana/config/kibana.yml` 配置文件的 `i18n.locale: "zh-CN"` 指定。
当然也可以挂在配置文件，然后调整。

注意：通过环境变量传入的配置会覆盖配置文件中的配置，但不会动态修改配置文件中的内容。所以如果你通过配置文件传入了 `ELASTICSEARCH_HOSTS` ，
配置文件中的 `elasticsearch.hosts` 值是不会生效的。

参考文档： [i18n settings in Kibana](https://www.elastic.co/guide/en/kibana/current/i18n-settings-kb.html)

### 2.1 配置项

- 国际化： `i18n.locale: "zh-CN"`

## 3. 注意

[docker-compose](./docker-compose.yml) 文件中使用了外部网络，并且没有挂载数据目录。
