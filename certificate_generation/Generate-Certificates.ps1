# Create the path to the output directory for the Certificate Authorities
$scriptWorkingDirectory = Join-Path $PSScriptRoot ../output

# Set the working directory for the Intermediate Certificate Authority.
$intermediateWorkDir = Join-Path $scriptWorkingDirectory intermediate

# Generate a private key for Consul.
docker run `
	--rm `
	-v "$($intermediateWorkDir):/intermediate" `
	-it frapsoft/openssl genrsa -out /intermediate/ca/private/consul.key.pem 2048

# Generate a CSR for Consul
docker run `
	--rm `
	-v "$($intermediateWorkDir):/intermediate" `
	-it frapsoft/openssl req -config /intermediate/ca/openssl.cnf -new -sha256  `
	-key /intermediate/ca/private/consul.key.pem `
	-out /intermediate/ca/csr/consul.csr.pem

# Generate a Certificate for Consul
docker run `
	--rm `
	-v "$($intermediateWorkDir):/intermediate" `
	-it frapsoft/openssl ca -config /intermediate/ca/openssl.cnf `
	-extensions server_cert -days 375 -notext -md sha256 `
	-in /intermediate/ca/csr/consul.csr.pem `
	-out /intermediate/ca/certs/consul.cert.pem

docker run `
	--rm `
	-v "$($intermediateWorkDir):/intermediate" `
	-it frapsoft/openssl x509 -noout -text `
	-in /intermediate/ca/certs/consul.cert.pem