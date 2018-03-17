# Environment
The environment I am testing in is a 3 manager, 3 worker linux swarm hosted in AWS.  It is based off of this template:
https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=Docker&templateURL=https://editions-us-east-1.s3.amazonaws.com/aws/stable/Docker.tmpl

The template is from the docker for aws documentation located here:
https://docs.docker.com/docker-for-aws/#docker-community-edition-ce-for-aws

The template sets up each of the managers to be deployed in a separate Availability Zone (AZ) to ensure Availability if a node goes down.

The first modification to this stack was to add logic to the userdata script on the managers that would export the AWS_REGION, MANAGER_COUNT and ENCRYPTION_TOKEN values from the cloud formation stack into `/home/docker/.profile`.  The following was added to the above template:

```json
{
    // excerpted out for brevity  
    "Parameters": {
        // excerpted out for brevity
        "ConsulEncryptionToken": {
            "Type":"String",
            "Description": "Token used to encrypt the Gossip protocol commuincation between consul server instances.",
            "MaxLength":24,
            "MinLength":24
        }
    }
    // excerpted out for brevity
}
```
```json
{
    // excerpted out for brevity
    "Resources": {
        // excerpted out for brevity
        "ManagerLaunchConfig17121ceaws1": {
            // excerpted out for brevity
            "Properties": {
                // excerpted out for brevity
                "UserData": {
                    "Fn::Base64": {
                        "Fn::Join": [
                            "",
                            [
                                // excerpted for brevity
                                "echo \"export AWS_REGION='",
                                {
                                    "Ref": "AWS::Region"
                                },
                                "'\" > /home/docker/.profile\n",
                                "echo 'export MANAGER_COUNT=",
                                {
                                    "Ref": "ManagerSize"
                                },
                                "' >> /home/docker/.profile\n",
                                "echo \"export ENCRYPTION_TOKEN='",
                                {
                                    "Ref":"ConsulEncryptionToken"
                                },
                                "'\" >> /home/docker/.profile\n",
                                // excerpted for brevity
                            ]
                        ]
                    }
                }
            },
            // excerpted out for brevity
        },
        // excerpted out for brevity
    }
}
```
