index=1
for arg in $*
do
  echo "Arg #$index = $arg"
  export GNUPGHOME="$(mktemp -d)"
  echo "GNUPGHOME=$GNUPGHOME"
  cat > request <<EOF
    %echo Generating a default key
    Key-Type: default
    Subkey-Type: default
    Name-Real: Vault Master Keyring $index
    Name-Comment: Master Keyring
    Name-Email: $index@keyring
    Expire-Date: 0
    Passphrase: $arg
    %commit
    %echo done
EOF
  gpg --batch --generate-key request
  cat > request <<EOF
    %echo exporting private key
    Passphrase: $arg
    %commit
    %echo done
EOF
  publickey=$(gpg --batch --export --armor $index@keyring)
  privatekey=$(gpg --batch --passphrase "$arg" --pinentry-mode loopback --export-secret-keys --armor $index@keyring)
  ownertrust=$(gpg --export-ownertrust)
  curl --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$publickey" $CONSUL_URI/v1/kv/vault_keys/public_keys/key$index.key
  curl --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$privatekey" $CONSUL_URI/v1/kv/vault_keys/private_keys/key$index.key
  curl --request PUT --header "X-Consul-Token: $CONSUL_ACL_TOKEN" --data "$ownertrust" $CONSUL_URI/v1/kv/vault_keys/owner_trusts/key$index.txt
  let "index+=1"
done 