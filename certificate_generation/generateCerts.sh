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

openssl req -x509 -subj '/C=US/ST=MN/L=Minneapolis/O=ConsulCorp/CN=ConsulCA' -newkey rsa:2048 -days 3650 -nodes -out /opt/consul/ssl/demo-root.cer -keyout /opt/consul/ssl/private.pem
openssl req -subj "/C=US/ST=MN/L=Minneapolis/O=ConsulCorp/CN=server.us-east-2.consul" -newkey rsa:1024 -nodes -out /opt/consul/ssl/server.csr -keyout /opt/consul/ssl/server.key
openssl ca -batch -config /opt/consul/ssl/demo.conf -notext -in /opt/consul/ssl/server.csr -out /opt/consul/ssl/server.cer
openssl x509 -noout -text -in /opt/consul/ssl/server.cer

ls

# store_secret ca.cert.pem ca.cert
# store_secret consul.cert.pem consul.cert
# store_secret consul.key.pem consul.key