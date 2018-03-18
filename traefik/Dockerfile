FROM traefik:1.5.4-alpine
ENV TLD=foo.domain.com
COPY traefik.toml /etc/traefik/traefik.toml.tmpl
COPY run.sh /run.sh
ENTRYPOINT [ "/bin/sh", "/run.sh" ]
CMD ["traefik"]