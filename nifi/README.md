# Nifi

```shell
docker run --name nifi \
  -p 9090:9090 \
  -d \
  -e NIFI_WEB_HTTP_PORT='9090' \
  apache/nifi:latest
```
