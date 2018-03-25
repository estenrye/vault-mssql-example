DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -z $MASTER_TOKEN ]]; then
    echo "MASTER_TOKEN environment variable cannot be empty.  Aborting."
    exit 1
fi

# Create Agent Token
agentToken=$(curl --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
'{
  "Name": "Agent Token",
  "Type": "client",
  "Rules": "node \"\" { policy = \"write\" } service \"\" { policy = \"read\" }"
}' http://localhost:8500/v1/acl/create)

# Extract Agent Token from the response.
token=$(echo $agentToken | jq --raw-output ".ID")

# Set the Agent Token
curl --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
'{
  "Token": "fe3b8d40-0ee0-8783-6cc2-ab1aa9bb16c1"
}' http://localhost:8500/v1/agent/token/acl_agent_token

# Set the Anonymous Token Policy
curl --request PUT --header "X-Consul-Token: $MASTER_TOKEN" --data \
'{
  "ID": "anonymous",
  "Type": "client",
  "Rules": "node \"\" { policy = \"read\" } service \"consul\" { policy = \"read\" } key \"\" { policy = \"deny\" }"
}'  http://localhost:8500/v1/acl/update

# Create the acl configuration
sed "s/<<ACL_TOKEN>>/$agentToken/g" $DIR/acl.json.tmpl > ~/out/acl.json
docker config create acl.json ~/out/acl.json

# Load configuration into services
docker service update --config-add source=acl.json,target=/consul/config/acl.json,mode=0440 consul_server
docker service update --config-add source=acl.json,target=/consul/config/acl.json,mode=0440 consul_agent


