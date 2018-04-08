keyIndex=$1
passphrase=$2

privatekey=$(curl --silent --request GET --header "X-Consul-Token: $CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/private_keys/pgp_keys/key$keyIndex.key?raw)
ownertrust=$(curl --silent --request GET --header "X-Consul-Token: $CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/private_keys/pgp_keys/key$keyIndex.ownertrust.txt?raw)
ciphertext=$(curl --silent --request GET --header "X-Consul-Token: $CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/seal_keys/key$keyIndex.base64.txt?raw)

export GNUPGHOME="$(mktemp -d)"
echo "$privatekey" | gpg --batch --passphrase $passphrase --import
echo "$ownertrust" | gpg --batch --import-ownertrust
seal_key=$(echo "$ciphertext" | base64 -d | gpg --batch --passphrase $passphrase --pinentry-mode loopback --decrypt)

curl --request PUT --data "{ \"key\":\"$seal_key\"}" $VAULT_URI/v1/sys/unseal