region=$(echo $REGION | sed 's/\//\\\//g')
manager_count=$(echo $MANAGER_COUNT | sed 's/\//\\\//g')
encryption_token=$(echo $ENCRYPTION_TOKEN | sed 's/\//\\\//g')
sed "s/<<REGION>>/$region/g" /app/server.config.tmpl |
sed "s/<<MANAGER_COUNT>>/$manager_count/g" |
sed "s/<<ENCRYPTION_TOKEN>>/$encryption_token/g" > /out/config.json
cat /out/config.json
mkdir data