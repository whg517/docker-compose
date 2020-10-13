# README

为了更方便的科学上网，编写此 Dockerfile 启动代理服务。

功能点：

- 使用 [v2ray](https://github.com/v2ray/v2ray-core) 做代理
- 使用 [goproxy](https://github.com/snail007/goproxy) 做本地代理转换，以支持 http、http、socks5、ss

## 使用方法

```bash
docker-compose up -d
```

注意，请不要将 `config.json` 添加到仓库中。这么做会将你的配置暴露给其他人。

**其他用法：**

- 你可以修改 `docker-compose.yaml` 中 `goproxy` 服务的环境变量 `SOCKS5_ADDR` 来调整你的 v2ray 的主机和端口。
- 你可以修改 `docker-compose.yaml` 中 `goproxy` 服务的环境变量 `SPS_ADDR` 来调整你的 goproxy 的主机和端口。
- 对于 goproxy 你也可以使用[配置文件](https://snail.gitee.io/proxy/manual/zh/#/?id=_2-%e4%bd%bf%e7%94%a8%e9%85%8d%e7%bd%ae%e6%96%87%e4%bb%b6)来启动。 `proxy @configfile.txt`

    ```txt
    sps
    -S socks
    -T tcp
    -P v2ray:1080
    -t tcp
    -p :1081
    ```
