#!/bin/bash

mkdir -p /etc/letsencrypt
mkdir -p /var/lib/letsencrypt
mkdir -p /var/log/letsencrypt

PRIVATE_HOSTED_ZONE=$1
AWS_ACCESS_KEY_ID=$2
AWS_SECRET_ACCESS_KEY=$3
EMAIL=$4

externalName="consul-server.$PRIVATE_HOSTED_ZONE"
nodeName=$(docker info --format '{{.Name}}' | sed "s/us-east-2.compute.internal/$PRIVATE_HOSTED_ZONE/g")

docker run --rm \
    -v "/etc/letsencrypt:/etc/letsencrypt" \
    -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
    -v "/var/log/letsencrypt:/var/log/letsencrypt" \
    -p "80:80" \
    -e "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" \
    -e "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" \
    certbot/dns-route53 \
    certonly \
    --dns-route53 \
    -d $externalName \
    -d $nodeName \
    --email $EMAIL \
    --agree-tos \
    --non-interactive \
    --cert-name consul