region=$(echo $REGION | sed 's/\//\\\//g')
encryption_token=$(echo $ENCRYPTION_TOKEN | sed 's/\//\\\//g')
sed "s/<<REGION>>/$region/g" /app/agent.config.tmpl |
sed "s/<<ENCRYPTION_TOKEN>>/$encryption_token/g" > /out/config.json
cat /out/config.json
mkdir data