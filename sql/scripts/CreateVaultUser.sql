USE [master]

CREATE LOGIN [APP_vault_securityAdmin] WITH 
	PASSWORD = N'vaultPassword1234',
	CHECK_EXPIRATION = OFF,
	CHECK_POLICY = OFF;

ALTER SERVER ROLE securityadmin ADD MEMBER [APP_vault_securityAdmin];
ALTER SERVER ROLE processadmin ADD MEMBER [APP_vault_securityAdmin]

PRINT 'Added vault user.'
GO