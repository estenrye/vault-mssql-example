FROM microsoft/mssql-server-linux
LABEL build="vault-example"
ENV ACCEPT_EULA=Y \
    SA_PASSWORD=testPassword1234 \
	MSSQL_PID=Developer

COPY scripts /scripts

CMD /bin/bash /scripts/entrypoint.sh