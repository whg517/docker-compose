# Redis HA

## 配置

### Master

server name: `redis-server-master`

redis-master.conf

```
port 6379

requirepass 123456

rename-command KEYS ""
```

**注意：**

请不要直接使用上述默认密码

### Slaver

redis-slave.conf

```
port 6379

requirepass 123456

rename-command KEYS ""

replicaof redis-server-master 6379  # 不推荐使用 slave 关键词

masterauth 123456
```

**注意：**

请不要直接使用上述默认密码

### Sentinel

redis-sentinel.config

```
port 26379

requirepass 123456

sentinel monitor local-master redis-server-master 6379 2

sentinel auth-pass local-master 123456
```

**注意：**

请不要直接使用上述默认密码

Sentinel 节点第一次初始化的时候会根据配置或者自动自动发现查找集群，然后修改配置文件。更多描述可以查看 [Sentinel 文档](https://redis.io/topics/sentinel) [Redis 默认配置文件](https://raw.githubusercontent.com/redis/redis/6.0/redis.conf)