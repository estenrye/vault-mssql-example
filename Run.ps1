$targetDir = "$PSScriptRoot/consul/tls"
if (-not (Test-Path $targetDir))
{
	New-Item -ItemType Directory $targetDir -Force
}
$targetDir = (Resolve-Path $targetDir).Path
Write-Host $targetDir
docker run --rm -v "$($targetDir):/out" estenrye/ca