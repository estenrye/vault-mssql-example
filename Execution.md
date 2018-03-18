# Launch the CloudFormation Template:

### Stack Template Location
To be uploaded to S3 for convenience, for now [cloudformation\template.json](cloudformation\template.json)

### Prerequisite values:
Download Consul locally.  Run the following command locally to generate the Consul Encryption token:
```sh
consul keygen
```
Copy the ouptut into the `ConsulEncryptionToken` field of the stack template.

Select an SSH Key and configure the remaining values as you please.

# Local Setup
### Prerequisite values:
Download Consul locally.  Run the following command locally to generate the Consul Encryption token:
```sh
consul keygen
```

### Write Consul Configuration
On each manager node, run the following commands to write the consul server configuration:
```sh
export AWS_REGION='my-region-here'
export MANAGER_COUNT=3
export ENCRYPTION_TOKEN='generated-token-here'
mkdir -p /home/docker/consul/server
docker run --rm \
    -e REGION=$AWS_REGION \
	-e MANAGER_COUNT=$MANAGER_COUNT \
	-e ENCRYPTION_TOKEN=$ENCRYPTION_TOKEN \
	-v /home/docker/consul/server:/out \
	estenrye/aws-consul-swarm-config-writer:server
```

On each worker node, run the following commands to write the consul agent configuration:
```sh
export AWS_REGION='my-region-here'
export ENCRYPTION_TOKEN='generated-token-here'
mkdir -p /home/docker/consul/agent
docker run --rm \
    -e REGION=$AWS_REGION \
	-e ENCRYPTION_TOKEN=$ENCRYPTION_TOKEN \
	-v /home/docker/consul/agent:/out \
	estenrye/aws-consul-swarm-config-writer:agent
```