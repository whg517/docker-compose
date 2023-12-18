# PG

:ref [pg](https://hub.docker.com/_/postgres)

## 使用

启动前在 `docker-compose.yml` 同级新建 `.env` 文件，增加如下内容。

```env
POSTGRES_PASSWORD=yourpassword
POSTGRES_USER=postgres
POSTGRES_DB=postgres
```

注意：`POSTGRES_USER` 的默认值是 `postgres` ，`POSTGRES_DB` 的默认值是 `POSTGRES_USER` 的值
