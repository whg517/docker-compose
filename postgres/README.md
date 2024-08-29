# PostgreSQL 16

:ref

- [postgresql-16](https://catalog.redhat.com/software/containers/rhel9/postgresql-16/657b03866783e1b1fb87e142?image=66c2c29f373cc505bb0db872&architecture=amd64&container-tabs=overview)

## 使用

启动前在 `docker-compose.yml` 同级新建 `.env` 文件，增加如下内容。

```env
POSTGRESQL_ADMIN_PASSWORD=postgres
POSTGRESQL_USER=postgres
POSTGRESQL_PASSWORD=postgres
POSTGRESQL_DATABASE=postgres
```
