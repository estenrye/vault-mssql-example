#!/bin/bash
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")

mkdir -p /home/docker/vault
cp $SCRIPTPATH/vault.hcl /home/docker/vault/vault.hcl

docker run -d --name vault \
    --network default_net \
    --restart always \
    -e 'VAULT_REDIRECT_INTERFACE=eth0' \
    -e "VAULT_CLUSTER_ADDR=vault.$TLD" \
    -v /home/docker/vault:/config \
    --label "traefik.backend=vault.server" \
    --label "traefik.docker.network=default_net" \
    --label "traefik.frontend.rule=Host:vault.$TLD" \
    --label "traefik.enable=true" \
    --label "traefik.port=8200" \
    --label "traefik.protocol=http" \
    --cap-add IPC_LOCK \
    vault server -config=/config/vault.hcl