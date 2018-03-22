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
On a manager node, run the following commands to write the consul server configuration:
```sh
export AWS_REGION='my-region-here'
export MANAGER_COUNT=3
export ENCRYPTION_TOKEN='generated-token-here'
export TLD='top-level-domain-here'
mkdir -p /home/docker/consul/server
docker run -it --rm \
    -e REGION=$AWS_REGION \
	-e MANAGER_COUNT=$MANAGER_COUNT \
	-e ENCRYPTION_TOKEN=$ENCRYPTION_TOKEN \
	-e TLD=$TLD \
	-v /var/run/docker.sock:/var/run/docker.sock \
	estenrye/aws-consul-swarm-config-writer:latest
docker run -it --rm \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-e TLD=d.ryezone.com \
	estenrye/ca
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

### Generate 4 PGP public-private keys.
The next step in deployment of vault is to generate the PGP public-private keyrings we will use to intialize vault.  Once you have generated the keyrings, export the public key for each keyring and upload each key to consul with the following keys:
- /vaultautomation/publickey1
- /vaultautomation/publickey2
- /vaultautomation/publickey3
- /vaultautomation/tokenkey
