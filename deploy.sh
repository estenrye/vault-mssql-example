# Set up Enviornment Variables
export MASTER_TOKEN='MyBigFluffyBunny'
export REGION='us-east-2'
export MANAGER_COUNT=3
export ENCRYPTION_TOKEN='rp8BG/IebnT1lkKfp9hDyQ=='
export TLD='d.domain.com'
export EMAIL='email@d.domain.com'

# Set up Overlay Network
docker network create -d overlay --subnet=192.168.0.0/16 --attachable default_net

# Deploy Consul.  This provides our key-value store for everything that follows.
docker stack deploy -c ./consul/consul.stack.yml consul

# Configure Consul ACLs
docker run --rm -it -e MASTER_TOKEN=$MASTER_TOKEN -v /var/run/docker.sock:/var/run/docker.sock estenrye/consul-acl

# Set up Traefik Consul ACL Token Environment variable output from the last command.
# Traefik needs this value to write its configuration.
export TRAEFIK_CONSUL_TOKEN='token-guid-here'

# Deploy Traefik
docker stack deploy -c ./traefik/traefik.stack.yml traefik
