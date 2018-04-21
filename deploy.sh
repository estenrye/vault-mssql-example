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
export PRIVATE_HOSTED_ZONE='ec2.domain.com'
export AWS_ACCESS_KEY_ID='accessKey'
export AWS_SECRET_ACCESS_KEY='secretKey'

# Create internal Wildcard certificate with LetsEncrypt

mkdir -p /home/docker/letsencrypt/config
mkdir -p /home/docker/letsencrypt/workdir
mkdir -p /home/docker/letsencrypt/log

docker run --rm \
    -v "/home/docker/letsencrypt/config:/etc/letsencrypt" \
    -v "/home/docker/letsencrypt/workdir:/var/lib/letsencrypt" \
    -v "/home/docker/letsencrypt/log:/var/log/letsencrypt" \
    -p "80:80" \
    -e "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" \
    -e "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" \
    certbot/dns-route53 \
    certonly \
    --dns-route53 \
    -d "*.$PRIVATE_HOSTED_ZONE" \
    --email $EMAIL \
    --agree-tos \
    --non-interactive \
    --cert-name "wildcard-$PRIVATE_HOSTED_ZONE" \
    --server https://acme-v02.api.letsencrypt.org/directory

# load certicicates into Docker Secrets API
for file in $(sudo ls /home/docker/letsencrypt/config/live/wildcard-$PRIVATE_HOSTED_ZONE); do 
    sudo docker secret create "$(basename $file '')" "/home/docker/letsencrypt/config/live/wildcard-$PRIVATE_HOSTED_ZONE/$file"
done

# extract certificates to the consul directory
docker service create \
    --secret cert.pem \
    --secret chain.pem \
    --secret fullchain.pem \
    --secret privkey.pem \
    --restart-condition none \
    --mount "type=bind,source=/home/docker/consul,target=/target" \
    --mode global \
    estenrye/extract-certs:test.4

# Set up Overlay Network
docker network create \
    -d overlay \
    --subnet=192.168.0.0/16 \
    --attachable \
    default_net

# Deploy Consul.  This provides our key-value store for everything that follows.
docker stack deploy -c ./consul/consul.server.stack.yml consul_server

# Configure Consul ACLs
docker run --rm \
    --network default_net \
    -e "MASTER_TOKEN=$MASTER_TOKEN" \
    -e "PRIVATE_HOSTED_ZONE=$PRIVATE_HOSTED_ZONE" \
    -v /home/docker/consul/certs:/consul/certs \
    -v /var/run/docker.sock:/var/run/docker.sock \
    estenrye/consul-acl

# Set up Traefik Consul ACL Token Environment variable output from the last command.
# Traefik needs this value to write its configuration.
export CONSUL_ACL_TOKEN='token-guid-here'
export TRAEFIK_CONSUL_TOKEN='token-guid-here'
export VAULT_CONSUL_TOKEN='token-guid-here'
export VAULT_KEYGEN_TOKEN='token-guid-here'

# Deploy Consul.  This provides our key-value store for everything that follows.
docker stack deploy -c ./consul/consul.agent.stack.yml consul_agent

# Deploy Traefik
docker stack deploy -c ./traefik/traefik.stack.yml traefik

# Generate GPG keys for root token and seal key tokens
CONSUL_URI="https://$(docker info --format '{{.Name}}'):8500"

docker run --rm -it\
    -e CONSUL_ACL_TOKEN=$VAULT_KEYGEN_TOKEN \
    -e CONSUL_URI="https://consul-server.$PRIVATE_HOSTED_ZONE:8500" \
    --network default_net \
    -v /home/docker/consul/certs:/consul/certs \
    estenrye/vault-gpg-keygen\
    root_token_key_password \
    seal_key_password1 \
    seal_key_password2 \
    seal_key_password3 \
    seal_key_password4

export CONSUL_SERVER="consul-server.$PRIVATE_HOSTED_ZONE"
export VAULT_SERVER="vault-$PRIVATE_HOSTED_ZONE"   

# Deploy Vault on each master node.  Repeat this step for every valut instance.
/bin/sh $SCRIPTPATH/vault/deploy-vault.sh

# Initialize the Vault.  This step only needs to be run on the first vault instance
docker run --rm \
    -e CONSUL_ACL_TOKEN=$VAULT_KEYGEN_TOKEN \
    -e CONSUL_URI=https://$CONSUL_SERVER:8500 \
    -e VAULT_URI=https://$VAULT_SERVER:8200 \
    -v /home/docker/consul/certs:/consul/certs \
    --network default_net \
    estenrye/vault-init

# Unseal the vault.  Repeat these steps on every vault instance.
docker run --rm \
    -e CONSUL_ACL_TOKEN=$VAULT_KEYGEN_TOKEN \
    -e CONSUL_URI=https://$CONSUL_SERVER:8500 \
    -e VAULT_URI=https://$VAULT_SERVER:8200 \
    -v /home/docker/consul/certs:/consul/certs \
    --network default_net \
    estenrye/vault-unseal \
    1 \
    seal_key_password1

docker run --rm \
    -e CONSUL_ACL_TOKEN=$VAULT_KEYGEN_TOKEN \
    -e CONSUL_URI=https://$CONSUL_SERVER:8500 \
    -e VAULT_URI=https://$VAULT_SERVER:8200 \
    -v /home/docker/consul/certs:/consul/certs \
    --network default_net \
    estenrye/vault-unseal \
    2 \
    seal_key_password2

docker run --rm \
    -e CONSUL_ACL_TOKEN=$VAULT_KEYGEN_TOKEN \
    -e CONSUL_URI=https://$CONSUL_SERVER:8500 \
    -e VAULT_URI=https://$VAULT_SERVER:8200 \
    -v /home/docker/consul/certs:/consul/certs \
    --network default_net \
    estenrye/vault-unseal \
    3 \
    seal_key_password3

docker run --rm \
    -e CONSUL_ACL_TOKEN=$VAULT_KEYGEN_TOKEN \
    -e CONSUL_URI=https://$CONSUL_SERVER:8500 \
    -e VAULT_URI=https://$VAULT_SERVER:8200 \
    -v /home/docker/consul/certs:/consul/certs \
    --network default_net \
    estenrye/vault-unseal \
    4 \
    seal_key_password4

