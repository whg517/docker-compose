# mongo

ref: <https://www.cnblogs.com/ricklz/p/13237419.html>

## 生产环境副本集

需要将容器IP换成宿主机IP

```js
rs.initiate({
          _id: "rs0",
          members: [
            { _id: 0, host: "<host-ip>:27017" },
            { _id: 0, host: "<host-ip>:27018" },
            { _id: 0, host: "<host-ip>:27019" },
          ]
        })
```
