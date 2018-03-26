export MASTER_TOKEN='MyBigFluffyBunny'
export REGION='us-east-2'
export MANAGER_COUNT=3
export ENCRYPTION_TOKEN='rp8BG/IebnT1lkKfp9hDyQ=='
export TLD='d.ryezone.com'
docker network create -d overlay --subnet=192.168.0.0/16 default_net
docker stack deploy -c ./traefik/traefik.stack.yml traefik
docker run --rm -it -e REGION=$REGION -e TLD=$TLD -v /var/run/docker.sock:/var/run/docker.sock estenrye/generate-certs
/bin/sh ./consul/configuration/configure.sh
docker stack deploy -c ./consul/consul.stack.yml consul
echo "Master Token: $MASTER_TOKEN"
