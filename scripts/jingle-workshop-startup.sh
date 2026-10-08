#!/bin/bash
# =============================================================================
# 🎁 Jingle's workshop VM - startup script (runs on every boot)
# - first boot: installs Python + ADK and copies YOUR Jingle code from
#   gs://<Santa's Knowledge Vault>/app/jingle
# - every boot: reads KB_BUCKET / KB_FILE from VM metadata and (re)starts Jingle
# - ships Jingle's JSON logs (KB_LOOKUP, KB_READ_FAILED) to Cloud Logging
#   under the log name "jingle"
# Jingle's API: http://localhost:8080 (reachable only through IAP)
# Setup log: /var/log/jingle-setup.log
# =============================================================================
exec >> /var/log/jingle-setup.log 2>&1
echo "[jingle] boot `date -u`"
md()   { curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/$1"; }
attr() { md "instance/attributes/$1"; }

PROJECT="`md project/project-id`"
KB_BUCKET="`attr KB_BUCKET`"
KB_FILE="`attr KB_FILE`"; [ -z "$KB_FILE" ] && KB_FILE=north-pole-data.json
LOCATION="`attr GOOGLE_CLOUD_LOCATION`"
APP=/opt/jingle/app

# 1. Python + ADK (first boot only)
if [ ! -x /opt/jingle/venv/bin/adk ]; then
  echo "[jingle] installing Python and ADK"
  apt-get update -y && apt-get install -y python3-venv
  python3 -m venv /opt/jingle/venv
  /opt/jingle/venv/bin/pip install -q --upgrade pip google-adk google-cloud-storage
fi

# 2. Jingle's code from the vault (until it is present)
if [ ! -f "$APP/jingle/agent.py" ]; then
  mkdir -p "$APP"
  if gcloud storage cp -r "gs://$KB_BUCKET/app/jingle" "$APP/"; then
    echo "[jingle] code copied from gs://$KB_BUCKET/app/jingle"
  else
    echo "[jingle] NO CODE FOUND at gs://$KB_BUCKET/app/jingle - upload it, then restart the VM"
    exit 0
  fi
fi
rm -f "$APP/jingle/.env"

# 3. Settings from VM metadata (every boot)
cat > /etc/jingle.env <<ENV
GOOGLE_GENAI_USE_VERTEXAI=TRUE
GOOGLE_CLOUD_PROJECT=$PROJECT
GOOGLE_CLOUD_LOCATION=$LOCATION
KB_BUCKET=$KB_BUCKET
KB_FILE=$KB_FILE
ENV
echo "[jingle] KB_BUCKET=$KB_BUCKET KB_FILE=$KB_FILE LOCATION=$LOCATION"

# 4. Jingle service + log shipper
cat > /etc/systemd/system/jingle.service <<UNIT
[Unit]
Description=Jingle - North Pole customer-support agent (ADK API server)
After=network-online.target
[Service]
EnvironmentFile=/etc/jingle.env
ExecStart=/opt/jingle/venv/bin/adk api_server --host 0.0.0.0 --port 8080 $APP
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
cat > /usr/local/bin/jingle-logs.sh <<'SHIP'
#!/bin/bash
journalctl -u jingle -f -n 0 -o cat | while read -r line; do
  case "$line" in
    \{*\"message\"*) gcloud logging write jingle "$line" --payload-type=json >/dev/null 2>&1 ;;
  esac
done
SHIP
chmod +x /usr/local/bin/jingle-logs.sh
cat > /etc/systemd/system/jingle-logs.service <<UNIT
[Unit]
Description=Ship Jingle's JSON logs to Cloud Logging
After=jingle.service
[Service]
ExecStart=/usr/local/bin/jingle-logs.sh
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable jingle jingle-logs >/dev/null 2>&1
systemctl restart jingle jingle-logs
echo "[jingle] JINGLE IS AWAKE `date -u`"
