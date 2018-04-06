secret_shares=$(curl --silent --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/secret_shares?raw)
secret_threshold=$(curl --silent --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/secret_threshold?raw)
pgp_keys='['
for i in $(seq 1 $secret_shares)
do
    key=$(curl --silent --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/public_keys/pgp_keys/key$i.key?raw | tr -d '\n')
    pgp_keys="$pgp_keys \"$key\""
    if [[ $i -ne $secret_shares ]]
    then
        pgp_keys="$pgp_keys, "
    fi
done
pgp_keys="$pgp_keys]"
root_token_pgp_key=$(curl --silent --request GET --header "X-Consul-Token:$CONSUL_ACL_TOKEN" $CONSUL_URI/v1/kv/vault_keys/public_keys/root_token_pgp_key/key0.key?raw | tr -d '\n')

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

keys=$($initResponse | jq --raw-output '.keys | .[]')
root_token=$($initResponse | jq --raw-output '.root_token')

index=1
for key in $keys
do
  curl --silent --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$publickey" $CONSUL_URI/v1/kv/vault_keys/seal_keys/key$index.cipher.txt
  let index=$index+1
done

curl --silent --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$publickey" $CONSUL_URI/v1/kv/vault_keys/root_token.cipher.txt

echo $initResponse