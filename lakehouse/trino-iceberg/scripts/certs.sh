
# Generate a private key for the CA
openssl req \
    -x509 \
    -nodes \
    -newkey rsa:4096 \
    -sha256 \
    -days 36500 \
    -keyout ca.key \
    -out ca.crt \
    -subj "/C=CN/ST=ShangHai/L=ShangHai/O=example.com/CN=CA private example.com" \
    -addext "subjectKeyIdentifier=hash" \
    -addext "authorityKeyIdentifier=keyid:always,issuer" \
    -addext "keyUsage=digitalSignature,nonRepudiation,keyEncipherment,keyAgreement" \
    -addext "basicConstraints=critical,CA:true" 

# Generate a private key for the server
openssl req \
    -x509 \
    -nodes \
    -newkey rsa:4096 \
    -sha256 \
    -days 36500 \
    -CA ca.crt \
    -CAkey ca.key \
    -keyout trino.example.com.key \
    -out trino.example.com.crt \
    -subj "/C=CN/ST=ShangHai/L=ShangHai/O=example.com/CN=trino.example.com" \
    -addext "subjectKeyIdentifier=hash" \
    -addext "authorityKeyIdentifier=keyid:always,issuer" \
    -addext "keyUsage=digitalSignature,nonRepudiation,keyEncipherment,keyAgreement" \
    -addext "basicConstraints=critical,CA:false" \
    -addext "subjectAltName=DNS:trino.example.com"
