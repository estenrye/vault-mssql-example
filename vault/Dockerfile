FROM vault:0.9.1
LABEL build="vault"
WORKDIR /scripts
COPY ./vault.config /vault/config/
COPY ./configure-vault.sh ./entrypoint.sh ./
ENTRYPOINT [ "/bin/sh", "./entrypoint.sh" ]