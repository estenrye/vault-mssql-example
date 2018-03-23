sudo apk add util-linux
docker network create -d overlay --subnet=192.168.0.0/16 default_net
docker stack deploy -c ./traefik/traefik.stack.yml traefik
MASTER_TOKEN=$(uuidgen)
docker run --rm \
    -e REGION=$REGION \
	-e MANAGER_COUNT=$MANAGER_COUNT \
	-e ENCRYPTION_TOKEN=$ENCRYPTION_TOKEN \
    -e MASTER_TOKEN=$MASTER_TOKEN \
	-v /var/run/docker.sock:/var/run/docker.sock \
	estenrye/consul-config
docker stack deploy -c ./consul/consul.stack.yml consul
CONSUL_URI="http://consul-ui.$TLD"
docker run --rm \
    -e MASTER_TOKEN $MASTER_TOKEN \
	-e CONSUL_URI=$CONSUL_URI \
	-v /var/run/docker.sock:/var/run/docker.sock \
	estenrye/consul-acl

echo "Master Token: $MASTER_TOKEN"
