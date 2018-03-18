sed "s/<<TLD>>/$TLD/g" /etc/traefik/traefik.toml.tmpl > /etc/traefik/traefik.toml
cat /etc/traefik/traefik.toml
/entrypoint.sh $@