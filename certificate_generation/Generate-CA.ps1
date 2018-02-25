# Create the path to the output directory for the Certificate Authorities
$scriptWorkingDirectory = Join-Path $PSScriptRoot ../output

Remove-Item -Recurse -Force $scriptWorkingDirectory

# Generate the underlying directory structure of the root and intermediate CAs
$caDirectories = @('root/ca', 'intermediate/ca')
$caSubdirectories = @('certs', 'crl', 'csr', 'newcerts', 'private')

foreach ($dir in $caDirectories)
{
	$caDirectory = (Join-Path $scriptWorkingDirectory $dir)
	if (-not (Test-Path $caDirectory))
	{
		New-Item -ItemType Directory $caDirectory -Force
		foreach ($subdir in $caSubdirectories)
		{
			$caSubdirectory = (Join-Path $caDirectory $subdir)
			if (-not (Test-Path $caSubdirectory))
			{
				New-Item -ItemType Directory $caSubdirectory -Force
			}
		}
		if (-not (Test-Path (Join-Path $caDirectory index.txt)))
		{
			New-Item -ItemType File (Join-Path $caDirectory index.txt)
		}
		if (-not (Test-Path (Join-Path $caDirectory serial)))
		{
			"1000" | Out-File -Force (Join-Path $caDirectory serial) -Encoding ascii -NoNewline
		}
		if (-not (Test-Path (Join-Path $caDirectory crlnumber)))
		{
			"1000" | Out-File -Force (Join-Path $caDirectory crlnumber) -Encoding ascii -NoNewline
		}
	}
}

# pull the frapsoft/openssl image.  this eliminates the need to install
# openssl locally on a windows machine.
docker pull frapsoft/openssl

# Set the working directory for the root certificate authority.
$rootWorkDir = Join-Path $scriptWorkingDirectory root

# Copy the root CA config to the Work Directory
Copy-Item $PSScriptRoot\conf\openssl_root.cnf (Join-Path $rootWorkDir ca\openssl.cnf) -Force

# Generate the Root Certificate Authority private key.
docker run `
	--rm `
	-v "$($rootWorkDir):/root" `
	-it frapsoft/openssl genrsa -aes256 -out /root/ca/private/ca.key.pem 4096

# Generate the Root Certificate Authority Certificate
docker run `
	--rm `
	-v "$($rootWorkDir):/root" `
	-it frapsoft/openssl req -config /root/ca/openssl.cnf `
	-key /root/ca/private/ca.key.pem `
	-new -x509 -days 7300 -sha256 -extensions v3_ca `
	-out /root/ca/certs/ca.cert.pem

# Verify the Root Certificate Authroity Certificate
docker run `
	--rm `
	-v "$($rootWorkDir):/root" `
	-it frapsoft/openssl x509 -noout -text -in /root/ca/certs/ca.cert.pem

# Set the working directory for the Intermediate Certificate Authority.
$intermediateWorkDir = Join-Path $scriptWorkingDirectory intermediate

# Copy the root CA config to the Work Directory
Copy-Item $PSScriptRoot\conf\openssl_intermediate.cnf (Join-Path $intermediateWorkDir ca\openssl.cnf) -Force

# Generate the Intermediate Certificate Authority private key.
docker run `
	--rm `
	-v "$($intermediateWorkDir):/intermediate" `
	-it frapsoft/openssl genrsa -aes256 -out /intermediate/ca/private/intermediate.key.pem 4096

# Use the Intermediate Certificate Authority private key to generate a CSR
docker run `
	--rm `
	-v "$($intermediateWorkDir):/intermediate" `
	-it frapsoft/openssl req -config /intermediate/ca/openssl.cnf -new -sha256 `
	-key /intermediate/ca/private/intermediate.key.pem `
	-out /intermediate/ca/csr/intermediate.csr.pem

# Sign the intermediate certificate authority's CSR with the Root Certificate Authority's certificate
docker run `
	--rm `
	-v "$($rootWorkDir):/root" `
	-v "$($intermediateWorkDir):/intermediate" `
	-it frapsoft/openssl ca -config /root/ca/openssl.cnf -extensions v3_intermediate_ca `
	-days 3650 -notext -md sha256 `
	-in /intermediate/ca/csr/intermediate.csr.pem `
	-out /intermediate/ca/certs/intermediate.cert.pem

# Verify the intermediate certificate
docker run `
	--rm `
	-v "$($rootWorkDir):/root" `
	-v "$($intermediateWorkDir):/intermediate" `
	-it frapsoft/openssl verify -CAfile /root/ca/certs/ca.cert.pem `
	/intermediate/ca/certs/intermediate.cert.pem

# Create the certificate chain file.
cat $intermediateWorkDir/ca/certs/intermediate.cert.pem | cat $rootWorkDir/ca/certs/ca.cert.pem > $intermediateWorkDir/ca/certs/ca-chain.cert.pem