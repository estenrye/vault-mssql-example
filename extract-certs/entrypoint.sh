tar xzvf /run/secrets/letsencrypt
mkdir -p /target/certs
cp letsencrypt/config/live/wildcard-$PRIVATE_HOSTED_ZONE/*.pem /target/certs