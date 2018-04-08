if [[ -z $CONSUL_ACL_TOKEN ]]
then
    echo 'CONSUL_ACL_TOKEN cannot be empty.'
    exit 1
fi

if [[ -z $CONSUL_URI ]]
then
    echo 'CONSUL_URI cannot be empty.'
    exit 1
fi

secret_shares=$(curl --silent --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/secret_shares?raw)
if [[ -z secret_shares ]]
then
    echo 'secret_shares is invalid.'
    exit 1
fi

secret_threshold=$(curl --silent --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/secret_threshold?raw)
if [[ -z secret_shares ]]
then
    echo 'secret_threshold is invalid.'
    exit 1
fi

pgp_keys='['
for i in $(seq 1 $secret_shares)
do
    key=$(curl --silent --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/public_keys/pgp_keys/key$i.key?raw | tr -d '\n')
    if [[ -z secret_shares ]]
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
root_token_pgp_key=$(curl --silent --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/public_keys/root_token_pgp_key/key0.key?raw | tr -d '\n')
if [[ -z secret_shares ]]
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

initResponse=$(curl --request PUT --data "$initData" http://vault:8200/v1/sys/init)

keys_base64=$(echo "$initResponse" | jq --raw-output '.keys_base64 | .[]')
root_token=$(echo "$initResponse" | jq --raw-output '.root_token')
index=1
for key in $keys_base64
do
  curl --silent --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$key" $CONSUL_URI/v1/kv/vault_keys/seal_keys/key$index.base64.txt
  let index=$index+1
done

curl --silent --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$root_token" $CONSUL_URI/v1/kv/vault_keys/root_token.cipher.txt

#echo $initResponse