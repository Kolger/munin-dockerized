#!/usr/bin/env bash
set -euo pipefail

# Timezone: use $TZ (or $TIMEZONE) without validation
TZ_VALUE="${TZ:-${TIMEZONE:-UTC}}"
ln -sf "/usr/share/zoneinfo/${TZ_VALUE}" /etc/localtime
echo "${TZ_VALUE}" > /etc/timezone
export TZ="${TZ_VALUE}"


# Enable/disable mail notifications by flag
USE_MAIL_NOTIFICATIONS=${USE_MAIL_NOTIFICATIONS:-0}
if [[ "$USE_MAIL_NOTIFICATIONS" == "1" ]]; then
  # Create msmtp config (system-wide, readable by munin)
  cat > /etc/msmtprc <<EOF
defaults
auth           ${SMTP_AUTH:-on}
tls            ${SMTP_TLS:-on}
tls_starttls   ${SMTP_STARTTLS:-on}
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/munin/msmtp.log

account default
host           ${SMTP_HOST}
port           ${SMTP_PORT:-587}
user           ${SMTP_USER}
password       ${SMTP_PASSWORD}
from           ${SMTP_FROM}
EOF
  # Allow user 'munin' to read the system msmtp config
  chown root:munin /etc/msmtprc
  chmod 640 /etc/msmtprc
fi

# Hand off control to your app/command (if needed)
# exec "$@"

# Make directories before setting permissions
mkdir -p /run/munin
mkdir -p /var/run/munin
mkdir -p /var/log/munin
mkdir -p /var/www/munin
mkdir -p /var/lib/munin/cgi-tmp

# Fix ownership
chown munin:munin \
  /var/log/munin /run/munin /var/run/munin /var/lib/munin /var/lib/munin/cgi-tmp /var/www/munin \
  /etc/munin/munin-conf.d /etc/munin/plugin-conf.d /etc/munin/munin.conf

### Generate Munin nodes and contacts config from env
mkdir -p /etc/munin/munin-conf.d

# Clean previously generated files
rm -f /etc/munin/munin-conf.d/05-contacts.conf /etc/munin/munin-conf.d/10-nodes.conf || true

# Contacts (only if mail notifications are enabled)
if [[ "${USE_MAIL_NOTIFICATIONS:-0}" == "1" ]]; then
  cat > /etc/munin/munin-conf.d/05-contacts.conf <<EOF
contact.myalert.command mailx -s "MUNIN - \${var:group} :: \${var:host}" -r "${ALERT_FROM}" ${ALERT_TO}
contact.myalert.always_send warning critical
EOF
fi

# Nodes (multi-line: one "name:address" pair per line)
if [[ -n "${NODES:-}" ]]; then
  {
    while IFS= read -r pair; do
      [ -z "$pair" ] && continue
      name="${pair%%:*}"
      addr="${pair#*:}"
      echo "[$name]"
      echo "    address $addr"
      echo "    use_node_name yes"
      if [[ "${USE_MAIL_NOTIFICATIONS:-0}" == "1" && -f /etc/munin/munin-conf.d/05-contacts.conf ]]; then
        echo "    contacts myalert"
      fi
      echo
    done <<EOF
${NODES}
EOF
  } > /etc/munin/munin-conf.d/10-nodes.conf
fi

### End of dynamic config



echo "Starting rrdcached"
sudo -u munin -- mkdir -p /var/lib/munin/rrdcached-journal
chown munin:munin /var/lib/munin/rrdcached-journal
rm -f /var/run/munin/rrdcached.pid || true
sudo -u munin -- /usr/bin/rrdcached \
  -p /var/run/munin/rrdcached.pid \
  -B -b /var/lib/munin/ \
  -F -j /var/lib/munin/rrdcached-journal/ \
  -m 0660 -l unix:/var/run/munin/rrdcached.sock \
  -w 1800 -z 1800 -f 3600

echo "Starting munin-cron once to create the database"
sudo -u munin /usr/bin/munin-cron munin

echo "Starting cron"
/usr/sbin/cron -f &

echo "Starting munin-cgi-graph (spawn-fcgi)"
rm -f /var/run/munin/fastcgi-graph.sock || true
sudo -u munin spawn-fcgi \
  -f /usr/lib/munin/cgi/munin-cgi-graph \
  -s /var/run/munin/fastcgi-graph.sock \
  -U munin -G munin -M 777 \
  -u munin -g munin -F 1
sudo chmod 777 /var/run/munin/fastcgi-graph.sock || true

echo "Starting munin-cgi-html (spawn-fcgi)"
rm -f /var/run/munin/fastcgi-html.sock || true
sudo -u munin spawn-fcgi \
  -f /usr/lib/munin/cgi/munin-cgi-html \
  -s /var/run/munin/fastcgi-html.sock \
  -U munin -G munin -M 777 \
  -u munin -g munin -F 1
sudo chmod 777 /var/run/munin/fastcgi-html.sock || true

echo "Starting nginx (foreground)"
nginx -g 'daemon off;'
