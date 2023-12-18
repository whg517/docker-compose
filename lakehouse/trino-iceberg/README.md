# lakehouse

本文介绍了如何在 docker 环境下使用 minio ，postgres ， hive-metastore ，trino 搭建 lakehouse 环境。

在搭建过程中由于 hive 的容器缺少依赖 jar ，采用 gradle 作为初始化镜像，拉取需要的依赖，并通过卷共享的方式合并
hive 的 jar 。

文章分为三个主题：

- 快速流程搭建：快速准备文件和 docker-file ，然后启动，最后验证
- 手动分步骤搭建：拆分步骤，并详细解释标准搭建流程
- 不使用 s3 搭建：采用本地目录存储数据，减少 s3 服务占用资源

**注意：如果需要将相关端口暴漏公网，请对相关服务进行安全加固。**
**注意：实际操作时，请务必修改相关密码，并避免机密信息泄漏。**

## 使用方式

快速搭建分一下步骤进行：

- 准备配置文件
- 安装 minio
- 初始化环境
- 安装 hive-metastore
- 安装 trino

每一步为一个 docker-compose 文件。

### 快速流程搭建

```bash
# 创建 .env 环境变量文件，用于环境变量共享，同时不应被 git 追踪，避免机密信息泄漏
cat <<'EOF' > .env
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin

LAKEHOUSE_USER=trino
LAKEHOUSE_PASSWORD=iNAMZLtirahV

POSTGRES_DB=metastore_db
POSTGRES_USER=hive
POSTGRES_PASSWORD=hive
EOF

mkdir -p config/trino/catalog

cat <<\EOF > config/trino/catalog/iceberg.properties
connector.name=iceberg
iceberg.catalog.type=hive_metastore
hive.metastore.uri=thrift://metastore:9083
hive.s3.aws-access-key=trino
hive.s3.aws-secret-key=iNAMZLtirahV
hive.s3.endpoint=http://minio:9000
hive.s3.path-style-access=true
hive.s3.ssl.enabled=false
hive.s3.region=us-east-1

EOF

mkdir -p config/hive

cat > config/hive/hive-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>

    <!-- ak 和 sk 可以有环境变量提供，参见 https://hadoop.apache.org/docs/r3.1.2/hadoop-aws/tools/hadoop-aws/index.html#Authenticating_via_the_AWS_Environment_Variables -->
    <!-- <property>
        <name>fs.s3a.access.key</name>
        <description>AWS access key ID.
            Omit for IAM role-based or provider-based authentication.</description>
    </property>

    <property>
        <name>fs.s3a.secret.key</name>
        <description>AWS secret key.
            Omit for IAM role-based or provider-based authentication.</description>
    </property> -->

    <property>
        <name>fs.s3a.connection.maximum</name>
        <value>15</value>
        <description>Controls the maximum number of simultaneous connections to S3.</description>
    </property>

    <property>
        <name>fs.s3a.connection.ssl.enabled</name>
        <value>false</value>
        <description>Enables or disables SSL connections to S3.</description>
    </property>

    <property>
        <name>fs.s3a.endpoint</name>
        <value>
            http://minio:9000
        </value>
        <description>AWS S3 endpoint to connect to. An up-to-date list is
            provided in the AWS Documentation: regions and endpoints. Without this
            property, the standard region (s3.amazonaws.com) is assumed.
        </description>
    </property>

    <property>
        <name>fs.s3a.endpoint.region</name>
        <value>us-east-1</value>
        <description>AWS S3 region for a bucket, which bypasses the parsing of
            fs.s3a.endpoint to know the region. Would be helpful in avoiding errors
            while using privateLink URL and explicitly set the bucket region.
            If set to a blank string (or 1+ space), falls back to the
            (potentially brittle) SDK region resolution process.
        </description>
    </property>

    <property>
        <name>fs.s3a.path.style.access</name>
        <value>true</value>
        <description>Enable S3 path style access ie disabling the default virtual hosting behaviour.
            Useful for S3A-compliant storage providers as it removes the need to set up DNS for
            virtual hosting.
        </description>
    </property>

    <property>
        <name>fs.s3a.impl</name>
        <value>org.apache.hadoop.fs.s3a.S3AFileSystem</value>
        <description>The implementation class of the S3A Filesystem</description>
    </property>

    <property>
        <name>fs.AbstractFileSystem.s3a.impl</name>
        <value>org.apache.hadoop.fs.s3a.S3A</value>
        <description>The implementation class of the S3A AbstractFileSystem.</description>
    </property>

</configuration>
EOF

cat > config/hive/build.gradle <<EOF
apply plugin: 'base'

repositories {
    maven { url 'https://maven.aliyun.com/repository/public/' }
    mavenLocal()
    mavenCentral()
}

configurations {
    toCopy
}

dependencies {
    toCopy 'org.postgresql:postgresql:42.6.0'
    toCopy 'org.apache.hadoop:hadoop-aws:3.3.1'
    toCopy 'org.apache.hadoop:hadoop-client:3.3.1'
}

task download(type: Copy) {
    from configurations.toCopy 
    into '/jars'
}
EOF

mkdir -p scripts

cat > scripts/minio-init.sh <<\EOT

## config mc
# update local server config for mc
mc alias set local http://minio:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}
mc admin info local

## add user
pwgen="tr -dc '[:alnum:]' < /dev/urandom | fold -w 12 | head -n 1"
# access_key=trino    # usernmae
# secret_key=$(eval $pwgen)   # eg: iNAMZLtirahV
# mc admin user add local ${access_key} ${secret_key}
: ${LAKEHOUSE_USER:=trino} 
: ${LAKEHOUSE_PASSWORD}
mc admin user add local ${LAKEHOUSE_USER} ${LAKEHOUSE_PASSWORD}
mc admin user list local

## add bucket
: ${LAKEHOUSE_BUCKET:=lake-house}
mc mb local/${LAKEHOUSE_BUCKET}
mc ls local

## add policy

cat <<EOF > /tmp/lake_house_policy.json
{
    "Version": "2012-10-17",
    "Id": "LakeHouseBuckeyPolicy",
    "Statement": [
        {
            "Sid": "Stment01",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListBucketVersions",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload"
            ],
            "Resource": [
                "arn:aws:s3:::${LAKEHOUSE_BUCKET}/*",
                "arn:aws:s3:::${LAKEHOUSE_BUCKET}"
            ]
        }
    ]
}
EOF
mc admin policy create local lake_house /tmp/lake_house_policy.json
mc admin policy list local

## attach policy
mc admin policy entities --user trino local | grep lake_house
if [ $? -eq 0 ]; then
    echo "policy already attached"
else
    echo "attaching policy to user"
    mc admin policy attach local lake_house --user ${LAKEHOUSE_USER}
fi
EOT

chmod +x scripts/minio-init.sh
```

### 安装 minio

```bash

cat > docker-compose-minio.yml <<\EOF
version: "3.9"
services:
  minio:
    image: quay.io/minio/minio:RELEASE.2023-08-16T20-17-30Z
    command: server /data --console-address ":9001"
    hostname: minio
    # ports:
    #   - 127.0.0.1:9000:9000
    #   - 127.0.0.1:9001:9001
    env_file:
      - .env
    volumes:
      - lakehouse-minio:/data
    # environment:
      # MINIO_ROOT_USER: minioadmin
      # MINIO_ROOT_PASSWORD: minioadmin
    healthcheck:
      test: 
        - "CMD"
        - "curl"
        - "-f"
        - "http://localhost:9000/minio/health/live"
      interval: 30s
      timeout: 20s
      retries: 3

volumes:
  lakehouse-minio:
EOF

docker compose -f docker-compose-minio.yml up -d

```

### 初始化环境

```bash
cat <<\EOF > docker-compose-init.yml
version: '3.9'

services:
  # use gradle as init container to download hive jars
  # https://stackoverflow.com/a/32402694/11722440
  metastore-init-jars-download:
    image: gradle:8
    restart: on-failure
    volumes:
      - type: volume
        source: lakehouse-hive-jars
        target: /jars
      - type: bind  # 使用 bind 挂载单个文件到容器中
        source: ${PWD}/config/hive/build.gradle
        target: /home/gradle/build.gradle
    command: |
      bash -c '
      gradle download
      '

  # merge hive jars
  # https://stackoverflow.com/a/32402694/11722440
  metastore-init-jars-merge:
    image: apache/hive:4.0.0-beta-1
    restart: on-failure
    user: root
    volumes:
      - lakehouse-hive-jars:/jars:rw
    entrypoint: |
      bash -c '
      cp -R /opt/hive/lib/* /jars
      '

  # minio s3 init
  minio-s3-init:
    image: quay.io/minio/minio:RELEASE.2023-08-16T20-17-30Z
    restart: on-failure
    env_file:
      - .env
    volumes:
      - type: bind
        source: ${PWD}/scripts/minio-init.sh
        target: /minio-init.sh
    entrypoint: |
      bash -c '
      /minio-init.sh
      '

  trino-init-catalog:
    image: debian:latest
    restart: on-failure
    user: root
    env_file:
      - .env
    volumes:
      - ${PWD}/config/trino/catalog:/catalog:rw
    command: |
      bash -c '
      sed -i "s/\(^hive.s3.aws-access-key=\).*$/\1${LAKEHOUSE_USER}/" /catalog/iceberg.properties
      sed -i "s/\(^hive.s3.aws-secret-key=\).*$/\1${LAKEHOUSE_PASSWORD}/" /catalog/iceberg.properties
      '

volumes:
  lakehouse-hive-jars:
EOF

docker compose -f docker-compose-init.yml up
```

### 安装 hive-metastore

```bash
cat <<\EOF > docker-compose-hive.yml
version: "3.9"
services:
  # pg server
  postgres:
    image: postgres:15.4
    restart: unless-stopped
    hostname: postgres
    env_file:
      - .env
    # ports:
    #   - '127.0.0.1:5432:5432'
    # environment:
    #   POSTGRES_PASSWORD: postgres
    #   POSTGRES_USER: postgres
    #   POSTGRES_DB: postgres
    volumes:
      - lakehouse-postgres:/var/lib/postgresql/data

  # hive-metastore server
  metastore:
    image: apache/hive:4.0.0-beta-1
    # user: root
    depends_on:
      - postgres
    restart: unless-stopped
    hostname: metastore
    env_file:
      - .env
    environment:
      DB_DRIVER: postgres
      AWS_ACCESS_KEY_ID: ${LAKEHOUSE_USER}
      AWS_SECRET_ACCESS_KEY: ${LAKEHOUSE_PASSWORD}
      AWS_DEFAULT_REGION: us-east-1
      SERVICE_NAME: 'metastore -hiveconf hive.root.logger=INFO,console'
      SERVICE_OPTS: '-Xmx1G -Djavax.jdo.option.ConnectionDriverName=org.postgresql.Driver
                     -Djavax.jdo.option.ConnectionURL=jdbc:postgresql://postgres:5432/${POSTGRES_DB}
                     -Djavax.jdo.option.ConnectionUserName=${POSTGRES_USER}
                     -Djavax.jdo.option.ConnectionPassword=${POSTGRES_PASSWORD}
                     '
    # ports:
    #   - '127.0.0.1:9083:9083'
    volumes:
      - lakehouse-hive-jars:/opt/hive/lib
      - type: bind
        source: ${PWD}/config/hive/hive-site.xml
        target: /opt/hive/conf/hive-site.xml
        read_only: true

volumes:
  lakehouse-hive-jars:
  lakehouse-postgres:
EOF

docker compose -f docker-compose-hive.yml up -d
```

### 安装 trino

```bash

cat <<'EOF' > docker-compose-trino.yml
version: '3.9'

services:
  # trino server
  trino:
    image: trinodb/trino:424
    hostname: trino
    restart: unless-stopped
    env_file:
      - .env
    # ports:
    #   - 127.0.0.1:8080:8080
    volumes:
      - ${PWD}/config/trino/catalog:/etc/trino/catalog
      - trino-data:/var/trino/data

volumes:
  trino-data:
EOF

docker compose -f docker-compose-trino.yml up -d

```

### 验证

example:

```sql
CREATE SCHEMA iceberg.example_schema_s3
WITH (location = 's3a://lake-house/example/');

USE iceberg.example_schema_s3;

CREATE TABLE example_table (
    id INTEGER,
    name VARCHAR,
    age INTEGER
);

INSERT INTO example_table VALUES (1, 'Alice', 32), (2, 'Bob', 28);

SELECT * FROM example_table;
```

## 手动分步骤操作

### minio

ref: <https://github.com/minio/minio/blob/master/docs/orchestration/docker-compose/docker-compose.yaml>
ref: <https://min.io/docs/minio/linux/reference/minio-mc-admin.html#command-mc.admin>

首先通过 docker compose 安装 minio ，然后在 minio 中创建用户，创建桶，创建 policy，绑定 policy。

#### 安装 minio

安装 minio 分如下几步

- 创建 docker-compose 文件
- 创建环境变量文件
- 启动 minio

**创建 docker-compose 文件:**

创建 `docker-compose-minio.yml` 文件，增加如下内容。

根据环境考虑是否暴露 minio 的端口，如果需要外网访问，则删除 `127.0.0.1` 即可。

```yml
version: "3.9"
services:
  minio:
    image: quay.io/minio/minio:RELEASE.2023-08-16T20-17-30Z
    command: server /data --console-address ":9001"
    hostname: minio
    # ports:
    #   - 127.0.0.1:9000:9000
    #   - 127.0.0.1:9001:9001
    env_file:
      - .env
    volumes:
      - lakehouse-minio:/data
    # environment:
      # MINIO_ROOT_USER: minioadmin
      # MINIO_ROOT_PASSWORD: minioadmin
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

volumes:
  lakehouse-minio:
```

**配置环境变量:**

默认情况下，minio 使用 `minioadmin` 作为用户名密码，为了方便管理和避免泄漏，建议使用 `.env` 文件配置环境变量。

创建  `.env` 文件，增加如下内容。

```ini
# 创建环境变量文件，配置默认用户名密码
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
```

**启动 minio:**

```bash

# 启动 minio
docker compose -f docker-compose-minio.yml up -d

docker ps
```

#### manage minio

为了做到隔离，在创建问 minio 后，需要创建服务专用账户，和服务专用的桶，并对其进行访问权限关联。一下给出两种方式。

**docker-compose-init-minio.yml:**

```yaml
version: "3.9"
services:
  minio-s3-init:
    image: quay.io/minio/minio:RELEASE.2023-08-16T20-17-30Z
    restart: on-failure
    env_file:
      - .env
    volumes:
      - type: bind
        source: ${PWD}/scripts/minio-init.sh
        target: /minio-init.sh
    entrypoint: |
      bash -c '
      /minio-init.sh
      '
```

在前面的环境变量文件 `.env` 中增加如下内容：

```ini
LAKEHOUSE_USER=trino
LAKEHOUSE_PASSWORD=iNAMZLtirahV
```

创建 `/scripts/minio-init.sh` 文件，并增加如下内容。

```bash

## config mc
# update local server config for mc
mc alias set local http://${MINIO_HOST:=minio}:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}
mc admin info local

## add user
pwgen="tr -dc '[:alnum:]' < /dev/urandom | fold -w 12 | head -n 1"
# access_key=trino    # usernmae
# secret_key=$(eval $pwgen)   # eg: iNAMZLtirahV
# mc admin user add local ${access_key} ${secret_key}
: ${LAKEHOUSE_USER:=trino} 
: ${LAKEHOUSE_PASSWORD}
mc admin user add local ${LAKEHOUSE_USER} ${LAKEHOUSE_PASSWORD}
mc admin user list local

## add bucket
: ${LAKEHOUSE_BUCKET:=lake-house}
mc mb local/${LAKEHOUSE_BUCKET}
mc ls local

## add policy

cat <<EOF > /tmp/lake_house_policy.json
{
    "Version": "2012-10-17",
    "Id": "LakeHouseBuckeyPolicy",
    "Statement": [
        {
            "Sid": "Stment01",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListBucketVersions",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload"
            ],
            "Resource": [
                "arn:aws:s3:::${LAKEHOUSE_BUCKET}/*",
                "arn:aws:s3:::${LAKEHOUSE_BUCKET}"
            ]
        }
    ]
}
EOF
mc admin policy create local lake_house /tmp/lake_house_policy.json
mc admin policy list local

## attach policy
mc admin policy entities --user trino local | grep lake_house
if [ $? -eq 0 ]; then
    echo "policy already attached"
else
    echo "attaching policy to user"
    mc admin policy attach local lake_house --user ${LAKEHOUSE_USER}
fi
```

执行：

```bash
docker compose -f docker-compose-init-minio.yml up 

# 当逻辑执行完后会自动退出
```

**手动管理：**

使用 [mc](https://min.io/docs/minio/linux/reference/minio-mc-admin.html) 命令通过命令后台管理 minio 。

主要做如下操作：

- 配置 mc 命令
- 添加用户
- 添加 bucket
- 添加 policy
- 绑定 policy

```bash
## config mc
# update local server config for mc
mc alias set local http://localhost:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}
mc admin info local

## add user
pwgen="tr -dc '[:alnum:]' < /dev/urandom | fold -w 12 | head -n 1"
access_key=trino    # usernmae
secret_key=$(eval $pwgen)   # eg: iNAMZLtirahV
mc admin user add local ${access_key} ${secret_key}
mc admin user list local

## add bucket
mc mb local/lake-house

## add policy

cat <<EOF > /tmp/lake_house_policy.json
{
    "Version": "2012-10-17",
    "Id": "LakeHouseBuckeyPolicy",
    "Statement": [
        {
            "Sid": "Stment01",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListBucketVersions",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload"
            ],
            "Resource": [
                "arn:aws:s3:::lake-house/*",
                "arn:aws:s3:::lake-house"
            ]
        }
    ]
}
EOF
mc admin policy create local lake_house /tmp/lake_house_policy.json
mc admin policy list local

## attach policy
mc admin policy attach local lake_house --user trino
```

### hive-metastore

#### hive 环境初始化

ref: <https://github.com/apache/hive/blob/master/packaging/src/docker/docker-compose.yml>
ref: [How can I use Gradle to just download JARs?](https://stackoverflow.com/a/32402694/11722440)

由于在使用 hive 时需要搭配 s3 ，所以在 hive 环境中需要有 hadoop-aws 的依赖，并增加相关配置才能
正常使用。

在增加依赖 jar 的时候使用 gradle 方案，并通过共享卷将 jar 合并后挂载到 hive 容器。

创建 `config/hive/build.gradle` 文件，并增加如下内容。

```groovy
apply plugin: 'base'

repositories {
    maven { url 'https://maven.aliyun.com/repository/public/' }
    mavenLocal()
    mavenCentral()
}

configurations {
    toCopy
}

dependencies {
    toCopy 'org.postgresql:postgresql:42.6.0'
    toCopy 'org.apache.hadoop:hadoop-aws:3.3.1'
    toCopy 'org.apache.hadoop:hadoop-client:3.3.1'
}

task download(type: Copy) {
    from configurations.toCopy 
    into '/jars'
}
```

创建 `docker-compose-init-hive.yml` 文件，增加如下内容。

```yaml
version: '3.9'

services:
  # use gradle as init container to download hive jars
  # https://stackoverflow.com/a/32402694/11722440
  metastore-init-jars-download:
    image: gradle:8
    restart: on-failure
    volumes:
      - type: volume
        source: lakehouse-hive-jars
        target: /jars
      - type: bind  # 使用 bind 挂载单个文件到容器中
        source: ${PWD}/config/hive/build.gradle
        target: /home/gradle/build.gradle
    command: |
      bash -c '
      gradle download
      '

  # merge hive jars
  # https://stackoverflow.com/a/32402694/11722440
  metastore-init-jars-merge:
    image: apache/hive:4.0.0-beta-1
    restart: on-failure
    user: root
    volumes:
      - lakehouse-hive-jars:/jars:rw
    entrypoint: |
      bash -c '
      cp -R /opt/hive/lib/* /jars
      '

volumes:
  lakehouse-hive-jars:
```

执行：

```bash
docker compose -f docker-compose-init-hive.yml up
# 当逻辑执行完后会自动退出
```

#### 安装 hive-metastore

安装 hive-metastore 需要如下几步：

- 配置环境变量
- 配置 hive-site
- 创建 docker-compose 文件
- 启动 hive-metastore

##### 配置环境变量

由于安装 hive-metastore 是需要使用关系数据库，我们本地选择 postgresql ，为了便于管理和避免机密信息泄漏，
使用 `.env` 管理 postgresql 认证信息。

在前面创建的 `.env` 文件中增加如下内容：

```ini
POSTGRES_DB=metastore_db
POSTGRES_USER=hive
POSTGRES_PASSWORD=hive
```

##### 创建配置文件

创建 `config/hive/hive-site.xml` 文件，并增加如下内容：

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>

    <!-- ak 和 sk 可以有环境变量提供，参见 https://hadoop.apache.org/docs/r3.1.2/hadoop-aws/tools/hadoop-aws/index.html#Authenticating_via_the_AWS_Environment_Variables 
    export AWS_ACCESS_KEY_ID=my.aws.key
    export AWS_SECRET_ACCESS_KEY=my.secret.key
    -->
    <!-- <property>
        <name>fs.s3a.access.key</name>
        <description>AWS access key ID.
            Omit for IAM role-based or provider-based authentication.</description>
    </property>

    <property>
        <name>fs.s3a.secret.key</name>
        <description>AWS secret key.
            Omit for IAM role-based or provider-based authentication.</description>
    </property> -->

    <property>
        <name>fs.s3a.connection.maximum</name>
        <value>15</value>
        <description>Controls the maximum number of simultaneous connections to S3.</description>
    </property>

    <property>
        <name>fs.s3a.connection.ssl.enabled</name>
        <value>false</value>
        <description>Enables or disables SSL connections to S3.</description>
    </property>

    <property>
        <name>fs.s3a.endpoint</name>
        <value>http://minio:9000</value>
        <description>AWS S3 endpoint to connect to. An up-to-date list is
            provided in the AWS Documentation: regions and endpoints. Without this
            property, the standard region (s3.amazonaws.com) is assumed.
        </description>
    </property>

    <property>
        <name>fs.s3a.endpoint.region</name>
        <value>us-east-1</value>
        <description>AWS S3 region for a bucket, which bypasses the parsing of
            fs.s3a.endpoint to know the region. Would be helpful in avoiding errors
            while using privateLink URL and explicitly set the bucket region.
            If set to a blank string (or 1+ space), falls back to the
            (potentially brittle) SDK region resolution process.
        </description>
    </property>

    <property>
        <name>fs.s3a.path.style.access</name>
        <value>true</value>
        <description>Enable S3 path style access ie disabling the default virtual hosting behaviour.
            Useful for S3A-compliant storage providers as it removes the need to set up DNS for
            virtual hosting.
        </description>
    </property>

    <property>
        <name>fs.s3a.impl</name>
        <value>org.apache.hadoop.fs.s3a.S3AFileSystem</value>
        <description>The implementation class of the S3A Filesystem</description>
    </property>

    <property>
        <name>fs.AbstractFileSystem.s3a.impl</name>
        <value>org.apache.hadoop.fs.s3a.S3A</value>
        <description>The implementation class of the S3A AbstractFileSystem.</description>
    </property>

</configuration>
```

##### 创建 docker-compose 文件

```yaml
version: "3.9"
services:
  # pg server
  postgres:
    image: postgres:15.4
    restart: unless-stopped
    hostname: postgres
    env_file:
      - .env
    # ports:
    #   - '127.0.0.1:5432:5432'
    # environment:
    #   POSTGRES_PASSWORD: postgres
    #   POSTGRES_USER: postgres
    #   POSTGRES_DB: postgres
    volumes:
      - lakehouse-postgres:/var/lib/postgresql/data

  # hive-metastore server
  metastore:
    image: apache/hive:4.0.0-beta-1
    # user: root
    depends_on:
      - postgres
    restart: unless-stopped
    hostname: metastore
    env_file:
      - .env
    environment:
      DB_DRIVER: postgres
      AWS_ACCESS_KEY_ID: ${LAKEHOUSE_USER}
      AWS_SECRET_ACCESS_KEY: ${LAKEHOUSE_PASSWORD}
      AWS_DEFAULT_REGION: us-east-1
      SERVICE_NAME: 'metastore -hiveconf hive.root.logger=INFO,console'
      SERVICE_OPTS: '-Xmx1G -Djavax.jdo.option.ConnectionDriverName=org.postgresql.Driver
                     -Djavax.jdo.option.ConnectionURL=jdbc:postgresql://postgres:5432/${POSTGRES_DB}
                     -Djavax.jdo.option.ConnectionUserName=${POSTGRES_USER}
                     -Djavax.jdo.option.ConnectionPassword=${POSTGRES_PASSWORD}
                     '
    # ports:
    #   - '127.0.0.1:9083:9083'
    volumes:
      - lakehouse-hive-jars:/opt/hive/lib
      - type: bind
        source: ${PWD}/config/hive/hive-site.xml
        target: /opt/hive/conf/hive-site.xml
        read_only: true

volumes:
  lakehouse-hive-jars:
  lakehouse-postgres:
```

这个配置文件中有几个点需要强调一下：

- 启动服务的时候，hive 和 pg 会一起启动，通过使用 `.env` 文件中的环境变量。
- hive 镜像使用 4.0 版本，可以将初始化 schema 和更新一并执行， 3.x 镜像中执行 `-InitOrUpgradeSchema` 的命令是不存在的。
- 初始化 schema 的参数全部由环境变量提供，分两部分。一部分是 `SERVICE_NAME` 提供服务类型，这里有个BUG，就是可在参数后面直接接 hive 的配置，有点漏洞注入的感觉。另一部分是 `SERVICE_OPTS` 提供参数，这里提供了一些 jdbc 的参数，用来连接 pg 数据库，对于机密信息同样从环境变量获取，而不是写在 compose 文件中，这部分信息不需要写在 `hive-site.xml` 文件中。
- 前面提到的 s3 使用的配置，根据 AWS 规范可以设置成环境变量，并在使用中直接通过环境获取。
- 使用 `hive-jars` 的卷挂载前面初始化后的 jar 。
- 使用 `type: bind` 挂载指令，将单个文件挂载到指定目录。

##### 启动 hive-metastore

```bash
docker compose -f docker-compose-hive.yml up -d
```

### trino

#### 创建配置

创建 `config/trino/catalog/config.properties` 文件，并增加如下内容。

```ini
connector.name=iceberg
iceberg.catalog.type=hive_metastore
hive.metastore.uri=thrift://metastore:9083
hive.s3.aws-access-key=trino
hive.s3.aws-secret-key=iNAMZLtirahV
hive.s3.endpoint=http://minio:9000
hive.s3.path-style-access=true
hive.s3.ssl.enabled=false
hive.s3.region=us-east-1
```

#### 创建 docker-compose 文件

创建 `docker-compose-trino.yml` 文件，并增加如下内容。

```yaml
version: '3.9'

services:
  # trino server
  trino:
    image: trinodb/trino:424
    hostname: trino
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - 8080:8080
    volumes:
      - ${PWD}/config/trino/catalog:/etc/trino/catalog
      - trino-data:/var/trino/data

volumes:
  trino-data:
```

#### 启动 trino

```bash
docker compose -f docker-compose-trino.yml up -d
```

#### 测试

example:

```sql
CREATE SCHEMA iceberg.example_schema_s3
WITH (location = 's3a://lake-house/example/');

USE iceberg.example_schema_s3;

CREATE TABLE example_table (
    id INTEGER,
    name VARCHAR,
    age INTEGER
);

INSERT INTO example_table VALUES (1, 'Alice', 32), (2, 'Bob', 28);

SELECT * FROM example_table;

```

## 不使用 s3

考虑到使用 s3 时，minio 本身会消耗性能，同时在 hive 基于 s3 对象读写时也会消耗一定的性能，在实际方案中可以酌情选择移除 s3 ，让
湖仓方案的数据保存在 trino 的本地目录。

一下操作方式不在进行分布详细阐述部署流程。

### 准备文件

```bash

mkdir -p config/trino/catalog

cat <<\EOF > config/trino/catalog/iceberg.properties
connector.name=iceberg
iceberg.catalog.type=hive_metastore
hive.metastore.uri=thrift://metastore:9083
EOF

# env
cat <<\EOF > .env
POSTGRES_DB=metastore_db
POSTGRES_USER=hive
POSTGRES_PASSWORD=hive
EOF

# gradle
mkdir -p config/hive
cat <<EOF > config/hive/build.gradle
apply plugin: 'base'

repositories {
    maven { url 'https://maven.aliyun.com/repository/public/' }
    mavenLocal()
    mavenCentral()
}

configurations {
    toCopy
}

dependencies {
    toCopy 'org.postgresql:postgresql:42.6.0'
    toCopy 'org.apache.hadoop:hadoop-aws:3.3.1'
    toCopy 'org.apache.hadoop:hadoop-client:3.3.1'
}

task download(type: Copy) {
    from configurations.toCopy 
    into '/jars'
}
EOF
```

### 初始化环境

```bash
cat <<\EOF > docker-compose-init.yml
version: '3.9'

services:
  # use gradle as init container to download hive jars
  # https://stackoverflow.com/a/32402694/11722440
  metastore-init-jars-download:
    image: gradle:8
    restart: on-failure
    volumes:
      - type: volume
        source: lakehouse-hive-jars
        target: /jars
      - type: bind  # 使用 bind 挂载单个文件到容器中
        source: ${PWD}/config/hive/build.gradle
        target: /home/gradle/build.gradle
    command: |
      bash -c '
      gradle download
      '

  # merge hive jars
  # https://stackoverflow.com/a/32402694/11722440
  metastore-init-jars-merge:
    image: apache/hive:4.0.0-beta-1
    restart: on-failure
    user: root
    volumes:
      - lakehouse-hive-jars:/jars:rw
    entrypoint: |
      bash -c '
      cp -R /opt/hive/lib/* /jars
      '

volumes:
  lakehouse-hive-jars:
EOF

docker compose -f docker-compose-init.yml up

```

### 安装 hive-metastore

```bash
cat <<\EOF > docker-compose-hive.yml
version: "3.9"
services:
  # pg server
  postgres:
    image: postgres:15.4
    restart: unless-stopped
    hostname: postgres
    env_file:
      - .env
    # ports:
    #   - '127.0.0.1:5432:5432'
    # environment:
    #   POSTGRES_PASSWORD: postgres
    #   POSTGRES_USER: postgres
    #   POSTGRES_DB: postgres
    volumes:
      - lakehouse-postgres:/var/lib/postgresql/data

  # hive-metastore server
  metastore:
    image: apache/hive:4.0.0-beta-1
    depends_on:
      - postgres
    restart: unless-stopped
    hostname: metastore
    env_file:
      - .env
    # ports:
    #   - '127.0.0.1:9083:9083'
    environment:
      DB_DRIVER: postgres
      SERVICE_NAME: 'metastore -hiveconf hive.root.logger=INFO,console'
      SERVICE_OPTS: '-Xmx1G -Djavax.jdo.option.ConnectionDriverName=org.postgresql.Driver
                     -Djavax.jdo.option.ConnectionURL=jdbc:postgresql://postgres:5432/${POSTGRES_DB}
                     -Djavax.jdo.option.ConnectionUserName=${POSTGRES_USER}
                     -Djavax.jdo.option.ConnectionPassword=${POSTGRES_PASSWORD}
                     '
    volumes:
      - lakehouse-hive-jars:/opt/hive/lib

volumes:
  lakehouse-hive-jars:
  lakehouse-postgres:
EOF

docker compose -f docker-compose-hive.yml up -d

```

### 安装 trino

在启动 trino 的时候，需要使用特权用户，否则对于挂载的数据目录没有写入权限。

```bash

cat <<'EOF' > docker-compose-trino.yml
version: '3.9'

services:
  # trino server
  trino:
    image: trinodb/trino:424
    user: root
    hostname: trino
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - 8080:8080
    volumes:
      - ${PWD}/config/trino/catalog:/etc/trino/catalog
      - trino-data:/var/trino/data

volumes:
  trino-data:

EOF

docker compose -f docker-compose-trino.yml up -d

```

说明

在使用不使用 s3 的方案下， 湖仓数据是由 trino 写入到 trino 容器的本地目录的。但是由于 hive 的原因，依然会在 hive 的本地目录创建相同的
目录，但不会保存实际数据。

### 验证

```sql

CREATE SCHEMA iceberg.example_schema_local;

USE iceberg.example_schema_local;

CREATE TABLE example_table (
    id INTEGER,
    name VARCHAR,
    age INTEGER
);

INSERT INTO example_table VALUES (1, 'Alice', 32), (2, 'Bob', 28);

SELECT * FROM example_table;
```
