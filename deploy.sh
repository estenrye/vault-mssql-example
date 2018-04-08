# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")

# Set up Enviornment Variables
export MASTER_TOKEN='MyBigFluffyBunny'
export REGION='us-east-2'
export MANAGER_COUNT=3
export ENCRYPTION_TOKEN='rp8BG/IebnT1lkKfp9hDyQ=='
export TLD='d.domain.com'
export EMAIL='email@d.domain.com'

# Set up Overlay Network
docker network create \
    -d overlay \
    --subnet=192.168.0.0/16 \
    --attachable \
    default_net

# Deploy Consul.  This provides our key-value store for everything that follows.
docker stack deploy -c ./consul/consul.stack.yml consul

# Configure Consul ACLs
docker run --rm \
    --network default_net \
    -e MASTER_TOKEN=$MASTER_TOKEN \
    -v /var/run/docker.sock:/var/run/docker.sock \
    estenrye/consul-acl

# Set up Traefik Consul ACL Token Environment variable output from the last command.
# Traefik needs this value to write its configuration.
export TRAEFIK_CONSUL_TOKEN='token-guid-here'
export VAULT_CONSUL_TOKEN='token-guid-here'
export VAULT_KEYGEN_TOKEN='token-guid-here'

# Deploy Traefik
docker stack deploy -c ./traefik/traefik.stack.yml traefik

# Deploy Vault on each master node.
/bin/sh $SCRIPTPATH/vault/deploy-vault.sh

# Generate GPG keys for root token and seal key tokens
 docker run --rm \
    -e CONSUL_ACL_TOKEN=$VAULT_KEYGEN_TOKEN \
    -e CONSUL_URI=https://consul-ui.$TLD \
    estenrye/vault-gpg-keygen\
    root_token_key_password \
    seal_key_password1 \
    seal_key_password2 \
    seal_key_password3 \
    seal_key_passwordn

# Initialize the Vault
docker run --rm \
    -e CONSUL_ACL_TOKEN=$VAULT_KEYGEN_TOKEN \
    -e CONSUL_URI=https://consul-ui.$TLD \
    --network default_net \
    estenrye/vault-init

# Unseal the vault
docker run --rm \
    -e CONSUL_ACL_TOKEN=$VAULT_KEYGEN_TOKEN \
    -e CONSUL_URI=https://consul-ui.$TLD \
    -e VAULT_URI=http://vault:8200 \
    --network default_net \
    estenrye/vault-unseal \
    seal_key_index \
    seal_keypassword