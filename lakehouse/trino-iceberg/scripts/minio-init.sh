


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
