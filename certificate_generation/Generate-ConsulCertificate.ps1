param([switch]$PasswordProtectKeys)

# Create the path to the output directory for the Certificate Authorities
$scriptWorkingDirectory = Join-Path $PSScriptRoot ../output

# Set the working directory for the Intermediate Certificate Authority.
$intermediateWorkDir = Join-Path $scriptWorkingDirectory intermediate

Copy-Item $PSScriptRoot/conf/openssl_consul.cnf $intermediateWorkDir/ca/csr/consul.csr.cnf

# Generate a private key for Consul.
if ($PasswordProtectKeys)
{
	docker run `
		--rm `
		-v "$($intermediateWorkDir):/intermediate" `
		-it frapsoft/openssl genrsa -aes256 -out /intermediate/ca/private/consul.key.pem 2048
}
else 
{
	docker run `
		--rm `
		-v "$($intermediateWorkDir):/intermediate" `
		-it frapsoft/openssl genrsa -out /intermediate/ca/private/consul.key.pem 2048
}

# Generate a CSR for Consul
docker run `
	--rm `
	-v "$($intermediateWorkDir):/intermediate" `
	-it frapsoft/openssl req -config /intermediate/ca/csr/consul.csr.cnf -new -sha256  `
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

$targetDir = "$PSScriptRoot/../consul/tls"
if (-not (Test-Path $targetDir))
{
	New-Item -ItemType Directory $targetDir -Force
	New-Item -ItemType Directory (Join-Path $targetDir private)
	New-Item -ItemType Directory (Join-Path $targetDir certs)
}
Copy-Item $intermediateWorkDir/ca/certs/consul.cert.pem $targetDir/certs/consul.cert.pem -Force
Copy-Item $intermediateWorkDir/ca/private/consul.key.pem $targetDir/private/consul.key.pem -Force
Copy-Item $intermediateWorkDir/ca/certs/ca-chain.cert.pem $targetDir/certs/ca-chain.cert.pem -Force