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