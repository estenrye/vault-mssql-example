sed "s/<<REGION>>/${REGION}/g" /app/server.config.tmpl |
sed "s/<<MANAGER_COUNT>>/${MANAGER_COUNT}/g" |
sed "s/<<ENCRYPTION_TOKEN>>/${ENCRYPTION_TOKEN}/g" > /out/config.json
cat /out/config.json