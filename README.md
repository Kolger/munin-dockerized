Munin Docker Stack
==================

Production‑ready Munin master in Docker (Debian 13). It renders static HTML via cron, optionally serves on‑the‑fly graphs via FastCGI, and supports e‑mail alerts via msmtp. Nodes and contacts are generated from environment variables.

Quick Start
-----------

1) Copy env and edit values

    cp .env.sample .env

2) Build and run

    docker compose up -d --build

3) Open the UI

    http://localhost:${NGINX_PORT_HTTP:-80}/

Features
--------

- Static HTML generation by cron (default)
- CGI graph rendering (FastCGI on `/munin-cgi/munin-cgi-graph/`)
- E‑mail alerts using your own SMTP server (off by default)
- Nodes/contacts generated from `.env`
- Timezone configurable via `TZ`
- Bind mounts for persistence under `./data`


Data & Logs
-----------

Bind mounts (created automatically):

- `./data/munin/lib` -> `/var/lib/munin`
- `./data/munin/www` -> `/var/www/munin`
- `./data/log/nginx` -> `/var/log/nginx`
- `./data/log/munin` -> `/var/log/munin` (also contains `msmtp.log`)

Environment
-----------

All settings live in `.env` (see `.env.sample`).

Parameter Table
---------------

| Variable | Default | Description | Example |
| --- | --- | --- | --- |
| `NGINX_PORT_HTTP` | `80` | Host port mapped to container `80/tcp`. | `82` |
| `TZ` | `UTC` | Container timezone. | `Europe/Moscow` |
| `USE_MAIL_NOTIFICATIONS` | `0` | Enable e‑mail alerts (`1` to enable). | `1` |
| `NODES` | empty | Multi‑line `name:address` pairs (one per line). | `server1:10.0.0.101`<br>`server2:10.0.0.102` |
| `ALERT_FROM` | — | Envelope sender for alerts (used when mail is enabled). | `noreply@example.com` |
| `ALERT_TO` | — | Space‑separated recipient list (used when mail is enabled). | `ops@example.com` |
| `SMTP_HOST` | — | SMTP server host (mail on). | `smtp.example.com` |
| `SMTP_PORT` | `587` | SMTP server port (mail on). | `587` |
| `SMTP_USER` | — | SMTP username (mail on). | `noreply@example.com` |
| `SMTP_PASSWORD` | — | SMTP password (mail on). | `••••••` |
| `SMTP_AUTH` | `on` | SMTP auth toggle (mail on). | `on` |
| `SMTP_TLS` | `on` | Use TLS (mail on). | `on` |
| `SMTP_STARTTLS` | `on` | Use STARTTLS (mail on). | `on` |
| `SMTP_FROM` | — | From header (display name + address). | `"Munin Bot <noreply@example.com>"` |
