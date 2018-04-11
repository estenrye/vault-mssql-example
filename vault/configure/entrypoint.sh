VAULT_ADDR='http://0.0.0.0:8200'
VAULT_TOKEN='47469e55-ab29-659b-9094-3701085ef644'

# Enable the AppRole auth method
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type": "approle"}' \
    $VAULT_ADDR/v1/sys/auth/

# Create an App Role with desired set of policies
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{
        "bound_cidr_list":[],
        "secret_id_ttl":"10m",
        "token_num_uses":10,
        "token_ttl":"20m",
        "token_max_ttl"="30m",
        "secret_id_num_uses":40,
        "policies":[
            "default"
        ]
    }' \
    $VAULT_ADDR/v1/auth/approle/role/my-role

# Fetch the identifier of the role
roleIdentifierResponse=$(curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    $VAULT_ADDR/v1/auth/approle/role/my-role/role-id)

ROLE_ID=$(roleIdentifierResponse | jq --raw-output '.data.role_id')

# Create a new secret identifier under the role
secretIdentifierResponse=$(curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
     $VAULT_ADDR/v1/auth/approle/role/my-role/secret-id)

SECRET_ID=$(secretIdentifierResponse | jq --raw-output '.data.secret_id')

# Login using Role Id and Secret Id.
tokenResponse=$(curl \
    --request POST \
    --data "{
        \"role_id\":\"$ROLE_ID\",
        \"secret_id\":\"$SECRET_ID\"
    }" $VAULT_ADDR/v1/auth/approle/login)

# Enable the database secret backend
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data "{
        \"plugin_name\":\"mssql-database-plugin\",
        \"allowed_roles\":\"default\",
        \"connection_url\": \"sqlserver://$VAULT_DB_USER:$VAULT_DB_PASS@$DB_SERVER:$DB_PORT\",
        \"max_open_connections\": 5,
        \"max_connection_lifetime\": \"5s\",
        \"creation_statements\":[
            \"USE [master];\",
            \"CREATE LOGIN [{{name}}] WITH PASSWORD=N'{{password}}', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;\",
            \"GO\",
            \"USE [todoApi];\",
            \"CREATE USER [{{name}}] FOR LOGIN [{{name}}];\",
            \"ALTER ROLE [db_datareader] ADD MEMBER [{{name}}];\",
            \"ALTER ROLE [db_datawriter] ADD MEMBER [{{name}}];\",
            \"GO\"
        ],                                                                                                                                                                                                                                                                                                                                                                                                                                              
        \"revocation_statements\":[ 
            \"USE [todoApi];\",
            \"DROP USER [{{name}}];\",
            \"GO\",
            \"USE [master];\"
            \"DROP LOGIN [{{name}}];\",
            \"GO\"
        ]
    }" \
    $VAULT_ADDR/v1/database/config/mssql

# Create a simple policy
# curl \
#   --request POST \
#   --header "X-Vault-Token: ..." \
#   --data '{
#       "dev-policy":"path \"...\" {...} "
#       }' \
#   https://vault.hashicorp.rocks/v1/sys/policy/my-policy

