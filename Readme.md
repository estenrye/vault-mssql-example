# vault-mssql-example
This repository is the implementation result of my security research project for the SEIS 663 IT Security and Networking course at the University of St Thomas.  The goal of this repository is to provide a working reference architecture for connecting HashiCorp Vault, Microsoft SQL Server and EntityFrameworkCore for secure sharing of sql login credentials in linux docker containers.

# Problem Statement
To improve the availability of an application, an organization has elected to run their containers on Linux-based host systems instead of Windows-based host systems.  This decision has a downstream impact of forcing the organization to use SQL Logins to authenticate to its applications to its Microsoft SQL Server instances.  The DBA is concerned with this approach as it is commonly known within the DBA community that SQL Login authentication is much less secure than Windows Authentication because the application needs to know the username and password.  The current methods to provide these credentials using either environment variables or the docker secrets api currently allow a user with access to the container host to view these secrets in plain text.  Due to the existence of this risk, the DBA has asked the development team to investigate an alternative means to provide these credentials that minimizes the duration the SQL Server Logins must be accessible in plain text.

# Objective
Implement a proof of concept implementation of Hashicorp’s Vault product.  This project will explore how to configure Vault to provide temporal SQL Server Login credentials to a .Net Core Web API over a TLS encrypted channel using Vault’s AppRole authentication method.  This project will also investigate how to configure EntityFramework Core to communicate with SQL Server over an encrypted communication channel.  Lastly, this project will provide a reference architecture for developers within the organization to implement this security architecture within its applications.

# Applicable CISSP Domains
- Identity and Access Management
- Security and Risk Management
- Communications and Network Security

# Special Thanks To:
Jamie Nguyen - Your openssl tutorial is a thing of beauty, without which would have taken way more time to get a CA up and running.
- https://jamielinux.com/docs/openssl-certificate-authority/index.html