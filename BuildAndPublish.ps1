docker build -t estenrye/aws-consul-swarm-config-writer:server .\consul\configuration\server
docker build -t estenrye/aws-consul-swarm-config-writer:agent .\consul\configuration\agent
docker push estenrye/aws-consul-swarm-config-writer:server
docker push estenrye/aws-consul-swarm-config-writer:agent