# mysql 5.7 docker-compose.yml

:ref [mysql](https://hub.docker.com/_/mariadb)

## 使用

启动前在 `docker-compose.yml` 同级新建 `.env` 文件，增加如下内容。

```env
MYSQL_ROOT_PASSWORD=yourpassword
```

默认情况下使用 `/data/mysql` 作为 mysql 数据目录。
默认情况下使用当前目录下的 `./conf/` 下的配置作为 mysql 的配置目录。
