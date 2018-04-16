#!/bin/bash

mkdir -p /etc/letsencrypt
mkdir -p /var/lib/letsencrypt
mkdir -p /var/log/letsencrypt

docker run --rm \
    -v "/etc/letsencrypt:/etc/letsencrypt" \
    -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
    -v "/var/log/letsencrypt:/var/log/letsencrypt" \
    -p "80:80" \
    -e "AWS_ACCESS_KEY_ID=$1" \
    -e "AWS_SECRET_ACCESS_KEY=$2" \
    certbot/dns-route53 \
    certonly \
    --dns-route53 \
    -d consul-ui.d.ryezone.com \
    -d consul.server.ryezone.com \
    --email esten.rye@ryezone.com \
    --agree-tos \
    --non-interactive \
    --cert-name consul