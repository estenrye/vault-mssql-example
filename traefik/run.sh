sed "s/<<TLD>>/$TLD/g" /etc/traefik/traefik.toml.tmpl |
sed "s/<<EMAIL>>/$EMAIL/g" > /etc/traefik/traefik.toml
cat /etc/traefik/traefik.toml
/entrypoint.sh $@