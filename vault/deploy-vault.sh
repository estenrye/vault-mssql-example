#!/bin/bash
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")

mkdir -p /home/docker/vault
sed "s/<<ACL_TOKEN>>/$VAULT_TOKEN/g" $SCRIPTPATH/vault.hcl > /home/docker/vault/vault.hcl

docker run -d --name vault \
    --network default_net \
    --restart always \
    -e 'VAULT_REDIRECT_INTERFACE=eth0' \
    -e "VAULT_CLUSTER_ADDR=https://vault.$TLD" \
    -v /home/docker/vault:/config \
    --cap-add IPC_LOCK \
    vault server -config=/config/vault.hcl