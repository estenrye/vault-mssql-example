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

update-ca-certificates

secret_shares_status_code=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --write-out %{http_code} --silent --output /dev/null --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/secret_shares?raw)
secret_shares=0
if [[ $secret_shares_status_code -eq 200 ]]
then
  echo 'Setting $secret_shares to existing value'
  secret_shares=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --silent --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/secret_shares?raw)
  let secret_shares=$secret_shares+1
fi

let index=$secret_shares
for arg in $*
do
  export GNUPGHOME="$(mktemp -d)"
  cat > request <<EOF
    %echo Generating a default key
    Key-Type: default
    Subkey-Type: default
    Name-Real: Vault Master Keyring $index
    Name-Comment: Master Keyring
    Name-Email: $index@keyring
    Expire-Date: 0
    Passphrase: $arg
    %commit
    %echo done
EOF
  gpg --batch --generate-key request
  cat > request <<EOF
    %echo exporting private key
    Passphrase: $arg
    %commit
    %echo done
EOF
  publickey=$(gpg --batch --export --local-user $index@keyring | base64)
  privatekey=$(gpg --batch --passphrase "$arg" --pinentry-mode loopback --export-secret-keys --local-user $index@keyring --armor $index@keyring)
  ownertrust=$(gpg --export-ownertrust)
  keypath='pgp_keys'
  if [[ $index -eq 0 ]]
  then
    echo 'Creating Root Token PGP Key'
    keypath='root_token_pgp_key'
  else
    echo 'Creating Secret Share PGP Key'
  fi
  curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$publickey" $CONSUL_URI/v1/kv/vault_keys/public_keys/$keypath/key$index.key
  curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$privatekey" $CONSUL_URI/v1/kv/vault_keys/private_keys/$keypath/key$index.key
  curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$ownertrust" $CONSUL_URI/v1/kv/vault_keys/private_keys/$keypath/key$index.ownertrust.txt
  curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$index" $CONSUL_URI/v1/kv/vault_keys/secret_shares
  curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$index" $CONSUL_URI/v1/kv/vault_keys/secret_threshold
  let "index+=1"
done 