# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")

if [[ -z $MASTER_TOKEN ]]; then
    if [[ -z $1 ]]; then
        echo "MASTER_TOKEN environment variable cannot be empty.  Aborting."
        exit 1
    else
        export MASTER_TOKEN=$1
    fi
fi

until $(curl --output /dev/null --silent --fail http://consul.server:8500/v1/health/service/consul --header "X-Consul-Token: $MASTER_TOKEN" | jq '.'); do
    echo 'Waiting for successful connection to consul.'
    sleep 5
done

# Create Agent Token
echo 'Creating Agent Token'
agentToken=$(curl --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
'{
  "Name": "ACL Agent Token",
  "Type": "client",
  "Rules": "node \"\" { policy = \"write\" } service \"\" { policy = \"read\" }"
}' http://consul.server:8500/v1/acl/create)

echo $agentToken

# Extract Agent Token from the response.
token=$(echo $agentToken | jq --raw-output ".ID")

# Set the Agent Token
echo "Setting ACL Agent Token: $token"
curl --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
"{
  \"Token\": \"$token\"
}" https://consul.server:8500/v1/agent/token/acl_agent_token

# Set the Anonymous Token Policy
echo "Setting Anonymous Token Policy"
curl --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
'{
  "ID": "anonymous",
  "Type": "client",
  "Rules": "node \"\" { policy = \"read\" } service \"consul\" { policy = \"read\" } key \"\" { policy = \"deny\" }"
}'  https://consul.server:8500/v1/acl/update


# Create the acl configuration
echo "Writing ACL Config file."
sed "s/<<ACL_TOKEN>>/$agentToken/g" $SCRIPTPATH/acl.json.tmpl > ~/out/acl.json
docker config create acl.json ~/out/acl.json

# Load configuration into services
docker service update --config-add source=acl.json,target=/consul/config/acl.json,mode=0440 consul_server
docker service update --config-add source=acl.json,target=/consul/config/acl.json,mode=0440 consul_agent


echo 'Creating Traefik Token'
agentToken=$(curl --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
'{
  "Name": "Traefik",
  "Type": "client",
  "Rules": "session \"\" { policy = \"write\" } key \"traefik\" { policy = \"write\" }"
}' http://consul.server:8500/v1/acl/create)

traefikToken=$(echo $agentToken | jq --raw-output ".ID")


echo 'Creating Vault Token'
agentToken=$(curl --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
'{
  "Name": "Vault",
  "Type": "client",
  "Rules": "{\"key\": {\"vault/\": {\"policy\":\"write\"}},  \"node\": {\"\": {\"policy\": \"write\"}},\"service\": { \"vault\": {\"policy\": \"write\"}},\"agent\": {\"\": {\"policy\": \"write\"}},\"session\": {\"\": {\"policy\": \"write\"}}}"
}' http://consul.server:8500/v1/acl/create)

vaultToken=$(echo $agentToken | jq --raw-output ".ID")

echo 'Creating Vault Keygen Token'
agentToken=$(curl --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
'{
  "Name": "Vault",
  "Type": "client",
  "Rules": "{ "key":{ "vault_keys": { "policy":"write" } } }"
}' http://consul.server:8500/v1/acl/create)

vaultKeygenToken=$(echo $agentToken | jq --raw-output ".ID")

echo "Traefik ACL Token: export TRAEFIK_CONSUL_TOKEN='$traefikToken'"
echo "Vault ACL Token: export VAULT_CONSUL_TOKEN='$vaultToken'"
echo "Vault Keygen Token: export VAULT_KEGEN_TOKEN='$vaultKeygenToken'"