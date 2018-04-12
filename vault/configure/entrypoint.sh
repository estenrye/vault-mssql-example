VAULT_ADDR='http://127.0.0.1:8200'
VAULT_TOKEN='47469e55-ab29-659b-9094-3701085ef644'

# Enable the AppRole auth method
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type": "approle"}' \
    $VAULT_ADDR/v1/sys/auth/

# Create a policy for the token used to retreive the app role's Role Id and Secret Id
curl \
  --request PUT \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  --data '{
      "policy":"path \"auth/approle/role/my-role/role-id\" { capabilities=[\"read\"] } path \"auth/approle/role/my-role/secret-id\" { capabilities=[\"update\"] }"
      }' \
  $VAULT_ADDR/v1/sys/policy/todo_role_read

# Create a policy for the app role's permissions 
curl \
  --request PUT \
  --header "X-Vault-Token: $SECRET_REQUEST_TOKEN" \
  --data '{
      "policy":"path \"database/creds/APP_todoApp_rw\" { capabilities=[\"read\"] } "
      }' \
  $VAULT_ADDR/v1/sys/policy/todo_cred_read

# Create an App Role with desired set of policies
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{
        "bound_cidr_list":[],
        "secret_id_ttl":"10m",
        "token_num_uses":10,
        "token_ttl":"20m",
        "token_max_ttl":"30m",
        "secret_id_num_uses":40,
        "policies":[
            "default",
            "todo_cred_read",
            "todo_role_read"
        ]
    }' \
    $VAULT_ADDR/v1/auth/approle/role/my-role

# Enable the database secret backend
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data "{
        \"type\":\"database\",
        \"description\":\"database credential store\"
    }" \
     $VAULT_ADDR/v1/sys/mounts/database

# Configure the mssql database plugin
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data "{
        \"plugin_name\":\"mssql-database-plugin\",
        \"allowed_roles\":\"APP_todoApp_rw\",
        \"connection_url\": \"sqlserver://$VAULT_DB_USER:$VAULT_DB_PASS@$DB_SERVER:$DB_PORT\",
        \"max_open_connections\": 5,
        \"max_connection_lifetime\": \"5s\"
    }" \
    $VAULT_ADDR/v1/database/config/mssql

# Configure a database role
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data "{
        \"db_name\":\"mssql\",
        \"creation_statements\":\"USE [master]; CREATE LOGIN [{{name}}] WITH PASSWORD=N'{{password}}', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF; USE [todoApi]; CREATE USER [{{name}}] FOR LOGIN [{{name}}]; ALTER ROLE [db_datareader] ADD MEMBER [{{name}}]; ALTER ROLE [db_datawriter] ADD MEMBER [{{name}}];\",
        \"revocation_statements\":\"USE [todoApi]; DROP USER [{{name}}]; USE [master]; DROP LOGIN [{{name}}];\"
    }" \
    $VAULT_ADDR/v1/database/roles/APP_todoApp_rw


# Create a token for accessing the role id and secret id.  Associate the appropriate policy
tokenResponse=$(curl \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{
      "no_parent":true,
      "policies":["todo_role_read"],
      "no_default_policy":true,
      "display_name":"todo_role_token"
  }' \
  $VAULT_ADDR/v1/auth/token/create)

SECRET_REQUEST_TOKEN=$($tokenResponse | jq --raw-output '.auth.client_token')

# Fetch the identifier of the role
roleIdentifierResponse=$(curl \
    --header "X-Vault-Token: $SECRET_REQUEST_TOKEN" \
    $VAULT_ADDR/v1/auth/approle/role/my-role/role-id)

ROLE_ID=$($roleIdentifierResponse | jq --raw-output '.data.role_id')

# Create a new secret identifier under the role
secretIdentifierResponse=$(curl \
    --header "X-Vault-Token: $SECRET_REQUEST_TOKEN" \
    --request POST \
     $VAULT_ADDR/v1/auth/approle/role/my-role/secret-id)

SECRET_ID=$($secretIdentifierResponse | jq --raw-output '.data.secret_id')

# Login using Role Id and Secret Id.
tokenResponse=$(curl \
    --request POST \
    --data "{
        \"role_id\":\"$ROLE_ID\",
        \"secret_id\":\"$SECRET_ID\"
    }" $VAULT_ADDR/v1/auth/approle/login)

ROLE_TOKEN=$($tokenResponse | jq --raw-output '.auth.client_token')

# Request a credential
curl \
    --header "X-Vault-Token: $ROLE_TOKEN" \
    $VAULT_ADDR/v1/database/creds/APP_todoApp_rw
