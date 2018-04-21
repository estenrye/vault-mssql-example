passphrase=$1
VAULT_DB_USER=$2
VAULT_DB_PASS=$3

if [[ -z $passphrase ]]
then
    echo 'passphrase cannot be empty.  Did you forget to supply an argument?'
    exit 1
fi

if [[ -z $VAULT_DB_USER ]]
then
    echo 'VAULT_DB_USER cannot be empty.  Did you forget to supply an argument?'
    exit 1
fi

if [[ -z $VAULT_DB_PASS ]]
then
    echo 'VAULT_DB_PASS cannot be empty.  Did you forget to supply an argument?'
    exit 1
fi

if [[ -z $CONSUL_ACL_TOKEN ]]
then
    echo 'CONSUL_ACL_TOKEN cannot be empty.  Are you missing an environment variable?'
    exit 1
fi

if [[ -z $CONSUL_URI ]]
then
    echo 'CONSUL_URI cannot be empty.  Are you missing an environment variable?'
    exit 1
fi

if [[ -z $VAULT_URI ]]
then
    echo 'VAULT_URI cannot be empty.  Are you missing an environment variable?'
    exit 1
fi

if [[ -f /consul/certs/chain.pem ]]
then
    cp /consul/certs/chain.pem /usr/local/share/ca-certificates/chain.pem
else
    echo '/consul/certs/chain.pem could not be found.  Are you missing a volume mapping to /consul/certs?'
    exit 1
fi

if [[ -f /consul/certs/cert.pem ]]
then
    cp /consul/certs/cert.pem /usr/local/share/ca-certificates/cert.pem
else
    echo '/consul/certs/cert.pem could not be found.  Are you missing a volume mapping to /consul/certs?'
    exit 1
fi

if [[ -f /consul/certs/privkey.pem ]]
then
    cp /consul/certs/cert.pem /usr/local/share/ca-certificates/cert.pem
else
    echo '/consul/certs/privkey.pem could not be found.  Are you missing a volume mapping to /consul/certs?'
    exit 1
fi

if [[ -z $DB_SERVER ]]
then
    echo 'DB_SERVER cannot be empty.  Are you missing an environment variable?'
    exit 1
fi

if [[ -z $DB_PORT ]]
then
    echo 'DB_PORT cannot be empty.  Defaulting to port 1433.'
    DB_PORT=1433
fi

update-ca-certificates

echo "Retrieving Private PGP key for Root Token from Consul Server: $CONSUL_URI"
privatekey=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request GET --header "X-Consul-Token: $CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/private_keys/root_token_pgp_key/key0.key?raw)
if [[ -z $privatekey ]]
then
  echo 'Error retrieving private key.'
  exit 1
fi

echo "Retrieving Owner Trust for Root Token from Consul Server: $CONSUL_URI"
ownertrust=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request GET --header "X-Consul-Token: $CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/private_keys/root_token_pgp_key/key0.ownertrust.txt?raw)
if [[ -z $ownertrust ]]
then
  echo 'Error retrieving owner trust.'
  exit 1
fi

echo "Retrieving Cipher Text for Root Token from Consul Server: $CONSUL_URI"
ciphertext=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request GET --header "X-Consul-Token: $CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/root_token.cipher.txt?raw)
if [[ -z $ciphertext ]]
then
  echo 'Error retrieving ciphertext.'
  exit 1
fi

export GNUPGHOME="$(mktemp -d)"
echo "Decrypting Root Token"
echo "$privatekey" | gpg --batch --passphrase $passphrase --import
echo "$ownertrust" | gpg --batch --import-ownertrust
VAULT_TOKEN=$(echo "$ciphertext" | base64 -d | gpg --batch --passphrase $passphrase --pinentry-mode loopback --decrypt)
if [[ -z $VAULT_TOKEN ]]
then
  echo 'Error decrypting Root Token.'
  exit 1
fi

# Enable the AppRole auth method
curl --request POST --header "X-Vault-Token: $VAULT_TOKEN" --data @auth_enable_appRole.json $VAULT_URI/v1/sys/auth/approle

# Create a policy for the token used to retreive the app role's Role Id and Secret Id
curl --request PUT  --header "X-Vault-Token: $VAULT_TOKEN" --data @policy_todo_bootstrapToken.json $VAULT_URI/v1/sys/policy/todo_bootstrapToken

# Create a policy for the app role's permissions 
curl --request PUT  --header "X-Vault-Token: $VAULT_TOKEN" --data @policy_todo_acl.json $VAULT_URI/v1/sys/policy/todo_acl

# Create an App Role with desired set of policies
curl --request POST --header "X-Vault-Token: $VAULT_TOKEN" --data @auth_approle_todo.json $VAULT_URI/v1/auth/approle/role/todo

# Enable the database secret backend
curl --request POST --header "X-Vault-Token: $VAULT_TOKEN" --data @mount_database.json $VAULT_URI/v1/sys/mounts/database

# replace template values with variable values.
database_config=$(cat database_config_mssql.json \
    | sed "s/<<VAULT_DB_USER>>/$VAULT_DB_USER/g" \
    | sed "s/<<VAULT_DB_PASS>>/$VAULT_DB_PASS/g" \
    | sed "s/<<DB_SERVER>>/$DB_SERVER/g" \
    | sed "s/<<DB_PORT>>/$DB_PORT/g")

# Configure the mssql database plugin
curl --request POST --header "X-Vault-Token: $VAULT_TOKEN" --data "$database_config" $VAULT_URI/v1/database/config/mssql

# Configure a database role
curl --request POST --header "X-Vault-Token: $VAULT_TOKEN" --data @database_roles_todoApp_rw.json $VAULT_URI/v1/database/roles/todoApp_rw


# Create a token for accessing the role id and secret id.  Associate the appropriate policy
tokenResponse=$(curl --request POST --header "X-Vault-Token: $VAULT_TOKEN" --data @token_create_todo_bootstrapToken.json $VAULT_URI/v1/auth/token/create)
SECRET_REQUEST_TOKEN=$(echo $tokenResponse | ../bin/jq --raw-output '.auth.client_token')
echo "export BOOTSTRAP_TOKEN=$SECRET_REQUEST_TOKEN"
########################################################################################
# Get Credentials
########################################################################################

# Fetch the identifier of the role
roleIdentifierResponse=$(curl --request GET --header "X-Vault-Token: $SECRET_REQUEST_TOKEN" $VAULT_URI/v1/auth/approle/role/todo/role-id)
ROLE_ID=$(echo $roleIdentifierResponse | ../bin/jq --raw-output '.data.role_id')

# Create a new secret identifier under the role
secretIdentifierResponse=$(curl --request POST --header "X-Vault-Token: $SECRET_REQUEST_TOKEN" $VAULT_URI/v1/auth/approle/role/todo/secret-id)
SECRET_ID=$(echo $secretIdentifierResponse | ../bin/jq --raw-output '.data.secret_id')

# Login using Role Id and Secret Id.
tokenResponse=$(curl --request POST \
    --data "{
        \"role_id\":\"$ROLE_ID\",
        \"secret_id\":\"$SECRET_ID\"
    }" $VAULT_URI/v1/auth/approle/login)
ROLE_TOKEN=$(echo $tokenResponse | ../bin/jq --raw-output '.auth.client_token')

# Request a credential
curl --request GET --header "X-Vault-Token: $ROLE_TOKEN" $VAULT_URI/v1/database/creds/todoApp_rw
