FROM debian:13-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    munin munin-node nginx dumb-init sudo cron tzdata \
    spawn-fcgi libfcgi-perl libcgi-fast-perl rrdcached

RUN apt-get update && apt-get install -y --no-install-recommends \
      msmtp-mta ca-certificates s-nail \
    && rm -rf /var/lib/apt/lists/*

# Runtime configuration comes from environment variables/secrets
COPY munin.conf /etc/munin/munin.conf
COPY default.conf /etc/nginx/sites-available/default

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/bin/bash", "/usr/local/bin/docker-entrypoint.sh"]
