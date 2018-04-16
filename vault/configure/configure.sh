VAULT_ADDR='http://127.0.0.1:8200'
VAULT_TOKEN='41e066eb-21b0-bc2f-eff6-ec880b5ecd37'
DB_SERVER='server'
DB_PORT=1433
VAULT_DB_USER='user'
VAULT_DB_PASS='password'

# Enable the AppRole auth method
curl --request POST --header "X-Vault-Token: $VAULT_TOKEN" --data @auth_enable_appRole.json $VAULT_ADDR/v1/sys/auth/approle

# Create a policy for the token used to retreive the app role's Role Id and Secret Id
curl --request PUT  --header "X-Vault-Token: $VAULT_TOKEN" --data @policy_todo_bootstrapToken.json $VAULT_ADDR/v1/sys/policy/todo_bootstrapToken

# Create a policy for the app role's permissions 
curl --request PUT  --header "X-Vault-Token: $VAULT_TOKEN" --data @policy_todo_acl.json $VAULT_ADDR/v1/sys/policy/todo_acl

# Create an App Role with desired set of policies
curl --request POST --header "X-Vault-Token: $VAULT_TOKEN" --data @auth_approle_todo.json $VAULT_ADDR/v1/auth/approle/role/todo

# Enable the database secret backend
curl --request POST --header "X-Vault-Token: $VAULT_TOKEN" --data @mount_database.json $VAULT_ADDR/v1/sys/mounts/database

# replace template values with variable values.
database_config=$(cat database_config_mssql.json \
    | sed "s/<<VAULT_DB_USER>>/$VAULT_DB_USER/g" \
    | sed "s/<<VAULT_DB_PASS>>/$VAULT_DB_PASS/g" \
    | sed "s/<<DB_SERVER>>/$DB_SERVER/g" \
    | sed "s/<<DB_PORT>>/$DB_PORT/g")

# Configure the mssql database plugin
curl --request POST --header "X-Vault-Token: $VAULT_TOKEN" --data "$database_config" $VAULT_ADDR/v1/database/config/mssql

# Configure a database role
curl --request POST --header "X-Vault-Token: $VAULT_TOKEN" --data @database_roles_todoApp_rw.json $VAULT_ADDR/v1/database/roles/todoApp_rw


# Create a token for accessing the role id and secret id.  Associate the appropriate policy
tokenResponse=$(curl --request POST --header "X-Vault-Token: $VAULT_TOKEN" --data @token_create_todo_bootstrapToken.json $VAULT_ADDR/v1/auth/token/create)
SECRET_REQUEST_TOKEN=$(echo $tokenResponse | ../bin/jq --raw-output '.auth.client_token')
echo "Bootstrap Token: $SECRET_REQUEST_TOKEN"
########################################################################################
# Get Credentials
########################################################################################

# Fetch the identifier of the role
roleIdentifierResponse=$(curl --request GET --header "X-Vault-Token: $SECRET_REQUEST_TOKEN" $VAULT_ADDR/v1/auth/approle/role/todo/role-id)
ROLE_ID=$(echo $roleIdentifierResponse | ../bin/jq --raw-output '.data.role_id')

# Create a new secret identifier under the role
secretIdentifierResponse=$(curl --request POST --header "X-Vault-Token: $SECRET_REQUEST_TOKEN" $VAULT_ADDR/v1/auth/approle/role/todo/secret-id)
SECRET_ID=$(echo $secretIdentifierResponse | ../bin/jq --raw-output '.data.secret_id')

# Login using Role Id and Secret Id.
tokenResponse=$(curl --request POST \
    --data "{
        \"role_id\":\"$ROLE_ID\",
        \"secret_id\":\"$SECRET_ID\"
    }" $VAULT_ADDR/v1/auth/approle/login)
ROLE_TOKEN=$(echo $tokenResponse | ../bin/jq --raw-output '.auth.client_token')

# Request a credential
curl --request GET --header "X-Vault-Token: $ROLE_TOKEN" $VAULT_ADDR/v1/database/creds/todoApp_rw
