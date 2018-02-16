USE [master]

CREATE DATABASE Todo
GO

USE [Todo]

CREATE USER [APP_vault_securityAdmin] FOR LOGIN [APP_vault_securityAdmin];
ALTER ROLE [db_accessadmin] ADD MEMBER [APP_vault_securityAdmin];
ALTER ROLE [db_securityadmin] ADD MEMBER [APP_vault_securityAdmin];

CREATE TABLE TodoItem (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](256) NULL,
	[IsComplete] [bit] NOT NULL
)
GO