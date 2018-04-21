keyIndex=$1
passphrase=$2

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

echo "Retrieving Private PGP key for Unseal Shard $keyIndex from Consul Server: $CONSUL_URI"
privatekey=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request GET --header "X-Consul-Token: $CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/private_keys/pgp_keys/key$keyIndex.key?raw)
if [[ -z $privatekey ]]
then
  echo 'Error retrieving private key.'
  exit 1
fi

echo "Retrieving Owner Trust for Unseal Shard $keyIndex from Consul Server: $CONSUL_URI"
ownertrust=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request GET --header "X-Consul-Token: $CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/private_keys/pgp_keys/key$keyIndex.ownertrust.txt?raw)
if [[ -z $ownertrust ]]
then
  echo 'Error retrieving owner trust.'
  exit 1
fi

echo "Retrieving Cipher Text for Unseal Shard $keyIndex from Consul Server: $CONSUL_URI"
ciphertext=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request GET --header "X-Consul-Token: $CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/seal_keys/key$keyIndex.base64.txt?raw)
if [[ -z $ciphertext ]]
then
  echo 'Error retrieving ciphertext.'
  exit 1
fi

export GNUPGHOME="$(mktemp -d)"
echo "Decrypting Unseal Key Shard $keyIndex"
echo "$privatekey" | gpg --batch --passphrase $passphrase --import
echo "$ownertrust" | gpg --batch --import-ownertrust
seal_key=$(echo "$ciphertext" | base64 -d | gpg --batch --passphrase $passphrase --pinentry-mode loopback --decrypt)
if [[ -z $seal_key ]]
then
  echo 'Error decrypting seal_key.'
  exit 1
fi

echo "Submitting Unseal Key Shard $keyIndex to Vault Server: $VAULT_URI."
curl --request PUT --data "{ \"key\":\"$seal_key\"}" $VAULT_URI/v1/sys/unseal
