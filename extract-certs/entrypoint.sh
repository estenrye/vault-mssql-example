tar xzvf /run/secrets/letsencrypt
mkdir -p /target/certs
cp -r letsencrypt/config/live/wildcard-$PRIVATE_HOSTED_ZONE /target/certs