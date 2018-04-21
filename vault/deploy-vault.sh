#!/bin/bash
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")

export CONSUL_SERVER="consul-server.$PRIVATE_HOSTED_ZONE:8500"
export VAULT_SERVER="vault-$(docker info --format '{{.Name}}')"

mkdir -p /home/docker/vault
sed "s/<<ACL_TOKEN>>/$VAULT_CONSUL_TOKEN/g" $SCRIPTPATH/vault.hcl |
sed "s/<<CONSUL_SERVER>>/$CONSUL_SERVER/g" > /home/docker/vault/vault.hcl

docker run -d --name vault \
    --network default_net \
    --network-alias vault.${PRIVATE_HOSTED_ZONE} \
    --network-alias ${VAULT_SERVER} \
    --restart always \
    --add-host "$(docker info --format '{{.Name}}'):$(hostname -i)" \
    -e 'VAULT_REDIRECT_INTERFACE=eth0' \
    -e "VAULT_CLUSTER_ADDR=https://vault.${PRIVATE_HOSTED_ZONE}" \
    -e "VAULT_API_ADDR=https://$VAULT_SERVER:8200" \
    -e "VAULT_ADDR=https://$VAULT_SERVER:8200"
    -v /home/docker/vault:/config \
    -v /home/docker/consul/certs:/consul/certs \
    --cap-add IPC_LOCK \
    -p 8200:8200 \
    vault server -config=/config/vault.hcl