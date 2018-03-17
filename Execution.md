Launch the CloudFormation Template:

On each manager node, run the following commands to write the consul server configuration:
```sh
mkdir -p /home/docker/consul
docker run --rm \
    -e REGION=$AWS_REGION \
	-e MANAGER_COUNT=$MANAGER_COUNT \
	-e ENCRYPTION_TOKEN=$ENCRYPTION_TOKEN \
	-v /home/docker/consul:/out \
	estenrye/aws-consul-swarm-config-writer:server
```