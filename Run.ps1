param([switch]$PasswordProtectKeys)

certificate_generation/Generate-CA.ps1 -PasswordProtectKeys:$PasswordProtectKeys
certificate_generation/Generate-ConsulCertificate.ps1 -PasswordProtectKeys:$PasswordProtectKeys