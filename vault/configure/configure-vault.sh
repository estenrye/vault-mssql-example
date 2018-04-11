#!/bin/sh
vault server -config=/vault/config/vault.config &

# need to write logic to generate ssl keys to eliminate the
# need to use the -address flag on every command.

# also need to file an issue with hashicorp to fix documentation.
# possibly a pull request.

vault init -address=http://127.0.0.1:8200

# logic to extract keys from stdout
# logic to extract initial root token

vault unseal -address=http://127.0.0.1:8200 key1
vault unseal -address=http://127.0.0.1:8200 key2
vault unseal -address=http://127.0.0.1:8200 key3

vault auth -address=http://127.0.0.1:8200 token

vault secrets enable -address=http://127.0.0.1:8200 database

# need to start a compose file that launches sql server first.
# vault and mssql need to be on the same docker network.
# before I can execute the following commands.

vault write -address=http://127.0.0.1:8200 \
        database/config/my-sql-database \
        plugin_name=mssql-database-plugin \
        connection_url='sqlserver://APP_vault_securityAdmin:vaultPassword1234@mssql-server:1433' \
        allowed_roles="todo-api-role"

vault write -address=http://127.0.0.1:8200 database/roles/todo-api-role \
    db_name=Todo \
    creation_statements="CREATE LOGIN [{{name}}] WITH PASSWORD = '{{password}}'; \
                         CREATE USER [{{name}}] FOR LOGIN [{{name}}]; \
                         ALTER ROLE db_reader ADD MEMBER [{{name}}]; \
                         ALTER ROLE db_writer ADD MEMBER [{{name}}];" \
    default_ttl="5m" \
    max_ttl="10m"

vault auth enable -address=http://127.0.0.1:8200 approle

vault write -address=http://127.0.0.1:8200 auth/approle/role/todo-api-role \
    token_ttl=20m \
    token_max_ttl=30m

vault read -address=http://127.0.0.1:8200 auth/approle/role/todo-api-role/role-id
vault write -address=http://127.0.0.1:8200 -f auth/approle/role/todo-api-role/secret-id