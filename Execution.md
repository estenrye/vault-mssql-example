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
On a manager node, run the following commands to write the consul server configuration.  These commands will also output a Consul ACL Master Token if no `MASTER_TOKEN` environment variable is specified.  The Master Token value is used to configure the Consul ACLs.
```sh
export AWS_REGION='my-region-here'
export MANAGER_COUNT=3
export ENCRYPTION_TOKEN='generated-token-here'
export TLD='top-level-domain-here'
docker run -it --rm \
    -e REGION=$AWS_REGION \
	-e MANAGER_COUNT=$MANAGER_COUNT \
	-e ENCRYPTION_TOKEN=$ENCRYPTION_TOKEN \
	-v /var/run/docker.sock:/var/run/docker.sock \
	estenrye/aws-consul-swarm-config-writer:latest
```

# Stack Deployment

### Build the overlay network
```sh
docker network create -d overlay --subnet=192.168.0.0/16 default_net
```

### Deploy traefik
```sh
docker stack deploy -c ./traefik/traefik.stack.yml traefik
```

### Deploy consul
```sh
docker stack deploy -c ./consul/consul.stack.yml consul
```

### Configure ACLs on consul
```sh
export MASTER_TOKEN='generated-token-here'
export TLD='top-level-domain-here.io'
export CONSUL_URI="http://consul-ui.$TLD"
docker run -it --rm \
    -e MASTER_TOKEN $MASTER_TOKEN \
	-e CONSUL_URI=$CONSUL_URI \
	-v /var/run/docker.sock:/var/run/docker.sock \
	estenrye/aws-consul-swarm-config-writer:acl
```