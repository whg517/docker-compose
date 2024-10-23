# mongo

ref:

- [MongoDB Docker](https://quay.io/repository/mongodb/mongodb-community-server?tab=tags)
- [Docker and MongoDB](https://www.mongodb.com/resources/products/compatibilities/docker)

## 生产环境副本集

ref:

- [部署自管理副本集](https://www.mongodb.com/zh-cn/docs/manual/tutorial/deploy-replica-set/)
- [The only local MongoDB replica set with Docker Compose guide you’ll ever need!](https://medium.com/workleap/the-only-local-mongodb-replica-set-with-docker-compose-guide-youll-ever-need-2f0b74dd8384)
- [通过docker-compose搭建mongo的replica set高可用](https://www.cnblogs.com/ricklz/p/13237419.html)

为了避免 IP 频繁变动，配置内部域名解析到主机 IP 或者外部能访问的主机地址。
在初始化副本集群时，会使用外部可访问的 IP 对应的域名。

```yaml
  mongo-init:
    image: quay.io/mongodb/mongodb-community-server:7.0.1-ubi9
    restart: "on-failure"
    depends_on:
      - mongo-rs-1
    command:
      - mongosh
      - mongodb://mongo.example.com:27017
      - --eval
      - |
        try {
          rs.status()
        } catch (e) {
          rs.initiate({
            _id: "rs0",
            members: [
              { _id: 0, host: "mongo.example.com:27017" },
              { _id: 1, host: "mongo.example.com:27018" },
              { _id: 2, host: "mongo.example.com:27019" },
            ]
          })
        }
```

这里使用 `mongo.example.com` 作为域名，需要在 `/etc/hosts` 中添加对应的解析。 docker 程序会自动根据 hosts 文件
更新容器内部的 DNS 解析。

### 开启认证

如果需要开启认证，需要先创建集群内部通信的 keyfile ，当然也可以使用 x509 证书。具体操作请参考：
[自管理内部/成员资格身份验证](https://www.mongodb.com/zh-cn/docs/manual/core/security-internal-authentication/)

### 副本集访问

下面是一个 python 示例代码，访问副本集，并列出数据库：

```python
from pymongo import MongoClient


def print_databases():
    # Replace the URI string with your MongoDB deployment's connection string.
    client = MongoClient(
        "mongodb://mongo.example.com:27017,mongo.example.com:27018,mongo.example.com:27019/?replicaSet=rs0"
        )

    # List all databases
    databases = client.list_database_names()
    print("Databases:")
    for db in databases:
        print(f"- {db}")

if __name__ == "__main__":
    print_databases()

```
