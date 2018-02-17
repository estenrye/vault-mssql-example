#!/bin/bash

for i in {30..0}; do
  if sqlcmd -S localhost -U sa -P $SA_PASSWORD -Q 'SELECT 1;' &> /dev/null; then
    echo "$0: SQL Server started"
    break
  fi
  echo "$0: SQL Server startup in progress..."
  sleep 1
done

/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -i /scripts/CreateVaultUser.sql