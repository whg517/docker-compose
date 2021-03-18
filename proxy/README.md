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

`configfile.txt`

```txt
sps
-S socks
-T tcp
-P v2ray:1080
-t tcp
-p :1081
--max-conns-rate 100
```

文件中无法使用环境变量

## 故障排查

如果遇到像 `npm install` 出错或过慢的情况，则可能是并发数过低，根据[文档](https://snail.gitee.io/proxy/manual/zh/#/?id=_14-%e5%ae%a2%e6%88%b7%e7%ab%af%e5%b9%b6%e5%8f%91%e8%bf%9e%e6%8e%a5%e6%95%b0) 使用 `--max-conns-rate` 设置并发数。默认为 20，设置为 0 为不限制。
