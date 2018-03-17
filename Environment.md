# Environment
The environment I am testing in is a 3 manager, 3 worker linux swarm hosted in AWS.  It is based off of this template:
https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=Docker&templateURL=https://editions-us-east-1.s3.amazonaws.com/aws/stable/Docker.tmpl

The template is from the docker for aws documentation located here:
https://docs.docker.com/docker-for-aws/#docker-community-edition-ce-for-aws

The template sets up each of the managers to be deployed in a separate Availability Zone (AZ) to ensure Availability if a node goes down.