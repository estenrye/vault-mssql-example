keyIndex=$1
passphrase=$2

privatekey=$(curl --request GET --header "X-Consul-Token: $CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/private_keys/pgp_keys/key$keyIndex.key?raw)
if [[ -z $privatekey ]]
then
  echo 'Error retrieving private key.'
  exit 1
fi

ownertrust=$(curl --request GET --header "X-Consul-Token: $CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/private_keys/pgp_keys/key$keyIndex.ownertrust.txt?raw)
if [[ -z $ownertrust ]]
then
  echo 'Error retrieving owner trust.'
  exit 1
fi

ciphertext=$(curl --request GET --header "X-Consul-Token: $CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/seal_keys/key$keyIndex.base64.txt?raw)
if [[ -z $ciphertext ]]
then
  echo 'Error retrieving ciphertext.'
  exit 1
fi

export GNUPGHOME="$(mktemp -d)"
echo "$privatekey" | gpg --batch --passphrase $passphrase --import
echo "$ownertrust" | gpg --batch --import-ownertrust
seal_key=$(echo "$ciphertext" | base64 -d | gpg --batch --passphrase $passphrase --pinentry-mode loopback --decrypt)

seal_key=$(echo "$ciphertext" | base64 -d | gpg --batch --passphrase $passphrase --pinentry-mode loopback --decrypt)
if [[ -z $seal_key ]]
then
  echo 'Error decrypting seal_key.'
  exit 1
fi

curl --request PUT --data "{ \"key\":\"$seal_key\"}" http://vault:8200/v1/sys/unseal
