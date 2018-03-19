store_secret() {
    SECRET_ID=$(docker secret ls --filter Name=$1 -q)
    if [[ -z $SECRET_ID ]]; then
        docker secret create $1 $2
    else
        docker secret rm $1
        docker secret create $1 $2
    fi
}

mkdir -p /out
region=$(echo $REGION | sed 's/\//\\\//g')
manager_count=$(echo $MANAGER_COUNT | sed 's/\//\\\//g')
top_level_domain=$(echo $TLD | sed 's/\//\\\//g')
encryption_token=$(echo $ENCRYPTION_TOKEN | sed 's/\//\\\//g')

sed "s/<<REGION>>/$region/g" /app/server.config.tmpl |
sed "s/<<MANAGER_COUNT>>/$manager_count/g" |
sed "s/<<TLD>>/$top_level_domain/g" |
sed "s/<<ENCRYPTION_TOKEN>>/$encryption_token/g" > /out/server.config.json
store_secret consul.server.config.json /out/server.config.json

sed "s/<<REGION>>/$region/g" /app/agent.config.tmpl |
sed "s/<<TLD>>/$top_level_domain/g" |
sed "s/<<ENCRYPTION_TOKEN>>/$encryption_token/g" > /out/agent.config.json
store_secret consul.agent.config.json /out/agent.config.json