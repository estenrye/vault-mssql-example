[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -OutFile $PSScriptRoot\consul.zip -UseBasicParsing https://releases.hashicorp.com/consul/1.0.6/consul_1.0.6_windows_amd64.zip
Expand-Archive -Force $PSScriptRoot\consul.zip -DestinationPath $PSScriptRoot