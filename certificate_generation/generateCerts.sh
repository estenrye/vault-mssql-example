store_secret() {
    SECRET_ID=$(docker secret ls --filter Name=$1 -q)
    if [[ -z $SECRET_ID ]]; then
        docker secret create $1 $2
    else
        docker secret rm $1
        docker secret create $1 $2
    fi
}

mkdir -p /ca/root/certs
mkdir -p /ca/root/crl
mkdir -p /ca/root/csr
mkdir -p /ca/root/newcerts
mkdir -p /ca/root/private
mkdir -p /ca/intermediate/certs
mkdir -p /ca/intermediate/crl
mkdir -p /ca/intermediate/newcerts
mkdir -p /ca/intermediate/private
touch /ca/root/index.txt
touch /ca/intermediate/index.txt
echo 1000 > /ca/root/serial
echo 1000 > /ca/intermediate/serial
echo 1000 > /ca/root/crlnumber
echo 1000 > /ca/intermediate/crlnumber
mkdir -p /out/consul

region=$(echo $REGION | sed 's/\//\\\//g')
sed "s/<<REGION>>/$region/g" /ca/intermediate/csr/consul.csr.cnf.tmpl > /ca/intermediate/csr/consul.csr.cnf


# Generate Root CA Private Key
openssl genrsa -out /ca/root/private/ca.key.pem 4096

# Generate the Root Certificate Authority Certificate
openssl req -config /ca/root/openssl.cnf \
	-subj '/C=US/ST=Minnesota/L=Minneapolis/O=Generic CA/OU=Generic Root Certificate Authority/CN=Generic Root CA/emailAddress=no-reply@doesnotexist.com' \
	-key /ca/root/private/ca.key.pem \
	-new -x509 -days 7300 -sha256 -extensions v3_ca \
	-out /ca/root/certs/ca.cert.pem

# Generate the Intermediate Certificate Authority private key.
openssl genrsa -out /ca/intermediate/private/intermediate.key.pem 4096

# Use the Intermediate Certificate Authority private key to generate a CSR
openssl req -config /ca/intermediate/openssl.cnf -new -sha256 \
	-subj '/C=US/ST=Minnesota/L=Minneapolis/O=Generic CA/OU=Generic Intermediate Certificate Authority/CN=Generic Intermediate CA/emailAddress=no-reply@doesnotexist.com' \
	-key /ca/intermediate/private/intermediate.key.pem \
	-out /ca/intermediate/csr/intermediate.csr.pem

# Sign the intermediate certificate authority's CSR with the Root Certificate Authority's certificate
openssl ca -config /ca/root/openssl.cnf -extensions v3_intermediate_ca \
	-batch -days 3650 -notext -md sha256 \
	-in /ca/intermediate/csr/intermediate.csr.pem \
	-out /ca/intermediate/certs/intermediate.cert.pem

# Create the certificate chain file.
cat /ca/intermediate/certs/intermediate.cert.pem | cat /ca/root/certs/ca.cert.pem > /out/ca-chain.cert.pem

store_secret ca-chain.cert.pem /out/ca-chain.cert.pem

# Generate a private key for Consul.
openssl genrsa -out /ca/intermediate/private/consul.key.pem 2048

# Generate a CSR for Consul
openssl req -config /ca/intermediate/csr/consul.csr.cnf -new -sha256  \
	-subj "/C=US/ST=Minnesota/L=Minneapolis/O=Hashcorp/OU=consul/CN=server.$REGION.consul/emailAddress=no-reply@doesnotexist.com" \
	-key /ca/intermediate/private/consul.key.pem \
	-out /ca/intermediate/csr/consul.csr.pem

# Generate a Certificate for Consul
openssl ca -config /ca/intermediate/openssl.cnf \
	-batch -extensions server_cert -days 3650 -notext -md sha256 \
	-in /ca/intermediate/csr/consul.csr.pem \
	-out /ca/intermediate/certs/consul.cert.pem

cp /ca/intermediate/private/consul.key.pem /out/consul/consul.key.pem
cp /ca/intermediate/certs/consul.cert.pem /out/consul/consul.cert.pem

store_secret consul.key.pem /out/consul/consul.key.pem
store_secret consul.cert.pem /out/consul/consul.cert.pem