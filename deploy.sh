sudo apk add util-linux
docker network create -d overlay --subnet=192.168.0.0/16 default_net
docker stack deploy -c ./traefik/traefik.stack.yml traefik
MASTER_TOKEN=$(uuidgen)
REGION='us-east-2'
MANAGER_COUNT=3
ENCRYPTION_TOKEN='rp8BG/IebnT1lkKfp9hDyQ=='
./consul/configuration/configure.sh
docker stack deploy -c ./consul/consul.stack.yml consul
./consul/acl/acl.sh
echo "Master Token: $MASTER_TOKEN"
