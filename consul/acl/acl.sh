# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")

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

if [[ -z $MASTER_TOKEN ]]; then
    if [[ -z $1 ]]; then
        echo "MASTER_TOKEN environment variable cannot be empty.  Aborting."
        exit 1
    else
        export MASTER_TOKEN=$1
    fi
fi

until $(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --output /dev/null --silent --fail https://consul-server.$PRIVATE_HOSTED_ZONE:8500/v1/health/service/consul --header "X-Consul-Token: $MASTER_TOKEN" | jq '.'); do
    echo 'Waiting for successful connection to consul.'
    sleep 5
done

# Create Agent Token
echo 'Creating Agent Token'
agentToken=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
'{
  "Name": "ACL Agent Token",
  "Type": "client",
  "Rules": "node \"\" { policy = \"write\" } service \"\" { policy = \"read\" }"
}' https://consul-server.$PRIVATE_HOSTED_ZONE:8500/v1/acl/create)

echo $agentToken

# Extract Agent Token from the response.
token=$(echo $agentToken | jq --raw-output ".ID")

# Set the Agent Token
echo "Setting ACL Agent Token: $token"
curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
"{
  \"Token\": \"$token\"
}" https://consul-server.$PRIVATE_HOSTED_ZONE:8500/v1/agent/token/acl_agent_token

# Set the Anonymous Token Policy
echo "Setting Anonymous Token Policy"
curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
'{
  "ID": "anonymous",
  "Type": "client",
  "Rules": "node \"\" { policy = \"read\" } service \"consul\" { policy = \"read\" } key \"\" { policy = \"deny\" }"
}'  https://consul-server.$PRIVATE_HOSTED_ZONE:8500/v1/acl/update


# Create the acl configuration
echo "Writing ACL Config file."
sed -i'' "s/<<ACL_TOKEN>>/$token/g" $SCRIPTPATH/acl.json
if [[ -z $(docker config ls -q --filter Name=acl.json) ]]; then
    docker config rm acl.json
fi

docker config create acl.json $SCRIPTPATH/acl.json

# Load configuration into services
# docker service update --config-add source=acl.json,target=/consul/config/acl.json,mode=0440 consul_server
# docker service update --config-add source=acl.json,target=/consul/config/acl.json,mode=0440 consul_agent


echo 'Creating Traefik Token'
agentToken=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
'{
  "Name": "Traefik",
  "Type": "client",
  "Rules": "session \"\" { policy = \"write\" } key \"traefik\" { policy = \"write\" }"
}' https://consul-server.$PRIVATE_HOSTED_ZONE:8500/v1/acl/create)

traefikToken=$(echo $agentToken | jq --raw-output ".ID")


echo 'Creating Vault Token'
agentToken=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
'{
  "Name": "Vault",
  "Type": "client",
  "Rules": "{\"key\": {\"vault/\": {\"policy\":\"write\"}},  \"node\": {\"\": {\"policy\": \"write\"}},\"service\": { \"vault\": {\"policy\": \"write\"}},\"agent\": {\"\": {\"policy\": \"write\"}},\"session\": {\"\": {\"policy\": \"write\"}}}"
}' https://consul-server.$PRIVATE_HOSTED_ZONE:8500/v1/acl/create)

vaultToken=$(echo $agentToken | jq --raw-output ".ID")

echo 'Creating Vault Keygen Token'
agentToken=$(curl --key /consul/certs/privkey.pem --cert /consul/certs/cert.pem --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
'{
  "Name": "Vault Keygen Token",
  "Type": "client",
  "Rules": "key \"vault_keys\" { policy = \"write\" }"
}' https://consul-server.$PRIVATE_HOSTED_ZONE:8500/v1/acl/create)

vaultKeygenToken=$(echo $agentToken | jq --raw-output ".ID")

echo "Consul ACL Token: export CONSUL_ACL_TOKEN='$token'"
echo "Traefik ACL Token: export TRAEFIK_CONSUL_TOKEN='$traefikToken'"
echo "Vault ACL Token: export VAULT_CONSUL_TOKEN='$vaultToken'"
echo "Vault Keygen Token: export VAULT_KEYGEN_TOKEN='$vaultKeygenToken'"