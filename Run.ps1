param([switch]$PasswordProtectKeys)

& "$PSScriptRoot/certificate_generation/Generate-CA.ps1" -PasswordProtectKeys:$PasswordProtectKeys
& "$PSScriptRoot/certificate_generation/Generate-ConsulCertificate.ps1" -PasswordProtectKeys:$PasswordProtectKeys