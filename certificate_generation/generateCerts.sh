store_secret() {
    SECRET_ID=$(docker secret ls --filter Name=$1 -q)
    if [[ -z $SECRET_ID ]]; then
        docker secret create $1 $2
    else
        docker secret rm $1
        docker secret create $1 $2
    fi
}

mkdir /etc/consul.d/ssl
mkdir /etc/consul.d/ssl/CA
chmod 0700 /etc/consul.d/ssl/CA
cd /etc/consul.d/ssl/CA
echo "000a" > serial
touch certindex

openssl req -x509 -subj '/C=US/ST=MN/L=Minneapolis/O=ConsulCorp/CN=ConsulCA/emailAddress=admin@dev.null.com' -newkey rsa:2048 -days 3650 -nodes -out ca.cert -keyout privkey.pem
openssl req -subj "/C=US/ST=MN/L=Minneapolis/O=ConsulCorp/CN=*.$TLD/emailAddress=admin@dev.null.com" -newkey rsa:1024 -nodes -out consul.csr -keyout consul.key
openssl ca -batch -config myca.conf -notext -in consul.csr -out consul.cert

store_secret ca.cert.pem ca.cert
store_secret consul.cert.pem consul.cert
store_secret consul.key.pem consul.key