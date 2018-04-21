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

if [[-z $VAULT_URI ]]
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

update-ca-certificates
echo "Retrieving Secret Shares."
secret_shares=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/secret_shares?raw)
echo "Secret Shares: $secret_shares"
if [[ -z $secret_shares ]]
then
    echo 'secret_shares is invalid.'
    exit 1
fi

echo "Retrieving Secret Threshold."
secret_threshold=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/secret_threshold?raw)
echo "Secret Threshold: $secret_threshold"

if [[ -z $secret_threshold ]]
then
    echo 'secret_threshold is invalid.'
    exit 1
fi

pgp_keys='['
for i in $(seq 1 $secret_shares)
do
    echo "Retrieving Public Key $i of $secret_shares"
    key=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/public_keys/pgp_keys/key$i.key?raw | tr -d '\n')
    if [[ -z $key ]]
    then
        echo "Key index $i is invalid."
        exit 1
    fi
    pgp_keys="$pgp_keys \"$key\""
    if [[ $i -ne $secret_shares ]]
    then
        pgp_keys="$pgp_keys, "
    fi
done
pgp_keys="$pgp_keys]"
echo "Retrieving Root Token Public Key"
root_token_pgp_key=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/public_keys/root_token_pgp_key/key0.key?raw | tr -d '\n')
if [[ -z $root_token_pgp_key ]]
then
    echo 'root_token_pgp_key is invalid.'
    exit 1
fi

initData=$(cat <<EOF
{
    "secret_shares":$secret_shares,
    "secret_threshold":$secret_threshold,
    "pgp_keys":$pgp_keys,
    "root_token_pgp_key":"$root_token_pgp_key"
}
EOF
)

echo "Sending Vault initialization request."
initResponse=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --data "$initData" $VAULT_URI/v1/sys/init)
echo "$initResponse"
if [[ -z "$initResponse" ]]
then
    echo 'Bad response'
    exit 1
fi
echo "Response received."
keys_base64=$(echo "$initResponse" | jq --raw-output '.keys_base64 | .[]')
root_token=$(echo "$initResponse" | jq --raw-output '.root_token')
index=1
for key in $keys_base64
do
  echo "Writing secret share ciphertext $index of $secret_shares to consul."
  curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$key" $CONSUL_URI/v1/kv/vault_keys/seal_keys/key$index.base64.txt
  let index=$index+1
done

echo "Writing root token ciphertext to consul"
curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$root_token" $CONSUL_URI/v1/kv/vault_keys/root_token.cipher.txt

echo "Operation complete"
#echo $initResponse