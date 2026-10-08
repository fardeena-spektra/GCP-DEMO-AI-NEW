# 🔑 Instructor Answer Key – Day 1: Jingle Awakens (Developer)

> Not part of the learner guide. Use it to test the lab end to end. Run in Cloud Shell after **Prepare the North Pole** succeeds.

## Elf toolkit

```bash
export PROJECT_ID=$(gcloud config get-value project)
export VAULT=$(gcloud storage buckets list --format='value(name)' --filter='name~^santas-knowledge-vault-')
export REGION=$(gcloud storage buckets describe gs://$VAULT --format='value(location)' | tr '[:upper:]' '[:lower:]')
export JINGLE_SA=jingle-sa@${PROJECT_ID}.iam.gserviceaccount.com
export SUBNET=$(gcloud compute networks subnets list --filter='name~^north-pole-subnet-' --format='value(name)')
export ZONE=$(gcloud compute instances list --filter='name~^labvm-' --format='value(zone.basename())')
```

## Challenge 2 – Santa's Knowledge Vault

```bash
gcloud storage ls -r gs://$VAULT
gcloud storage cat gs://$VAULT/north-pole-data.json
```

## Challenge 3 – Toy Workshop

```bash
pip install --quiet --upgrade google-adk && export PATH=$HOME/.local/bin:$PATH && adk telemetry disable
mkdir -p ~/jingle && echo "from . import agent" > ~/jingle/__init__.py
printf "google-adk\ngoogle-cloud-storage\n" > ~/jingle/requirements.txt
printf "GOOGLE_GENAI_USE_VERTEXAI=TRUE\nGOOGLE_CLOUD_PROJECT=%s\nGOOGLE_CLOUD_LOCATION=%s\nKB_BUCKET=%s\nKB_FILE=north-pole-data.json\n" "$PROJECT_ID" "$REGION" "$VAULT" > ~/jingle/.env
curl -fsSL https://raw.githubusercontent.com/fardeena-spektra/GCP-DEMO-AI-NEW/refs/heads/main/solution/agent.py -o ~/jingle/agent.py      # completed version of the starter
cd ~ && nohup adk api_server --port 8000 > /tmp/adk-local.log 2>&1 & sleep 15
ask() { local s="s$RANDOM"; curl -s -X POST "http://localhost:$1/apps/jingle/users/elf/sessions/$s" -H "Content-Type: application/json" -d '{}' >/dev/null
  curl -s -X POST "http://localhost:$1/run" -H "Content-Type: application/json" -d "{\"app_name\":\"jingle\",\"user_id\":\"elf\",\"session_id\":\"$s\",\"new_message\":{\"role\":\"user\",\"parts\":[{\"text\":\"$2\"}]}}" \
  | jq -r '.[] | .content.parts[]? | if .functionCall then "TOOL CALL : \(.functionCall.name) \(.functionCall.args|tostring)" elif .text then "JINGLE    : \(.text)" else empty end'; }
ask 8000 "Where is my Christmas gift? My order is NP-1225."
ask 8000 "Can I change my delivery address?"
ask 8000 "What is the return policy?"
ask 8000 "When is the last Christmas delivery?"
pkill -f "adk api_server --port 8000"
```

## Challenge 4 – Santa's Vault

```bash
gcloud storage cp -r ~/jingle gs://$VAULT/app/
curl -fsSL https://raw.githubusercontent.com/fardeena-spektra/GCP-DEMO-AI-NEW/refs/heads/main/scripts/jingle-workshop-startup.sh -o ~/jingle-workshop-startup.sh
gcloud compute instances create jingle-workshop --zone=$ZONE --machine-type=e2-medium --subnet=$SUBNET --tags=jingle \
  --service-account=$JINGLE_SA --scopes=cloud-platform --image-family=debian-12 --image-project=debian-cloud \
  --metadata=KB_BUCKET=$VAULT,KB_FILE=north-pole-data.json,GOOGLE_CLOUD_LOCATION=$REGION \
  --metadata-from-file=startup-script=$HOME/jingle-workshop-startup.sh
for i in $(seq 1 40); do gcloud compute ssh jingle-workshop --zone=$ZONE --tunnel-through-iap --quiet \
  --command="curl -s -o /dev/null -w '%{http_code}' localhost:8080/list-apps" 2>/dev/null | grep -q 200 \
  && { echo "JINGLE IS AWAKE"; break; } || { echo "Waiting for Jingle... ($i)"; sleep 15; }; done
```

## Challenge 5 – Customers Are Waiting

```bash
nohup gcloud compute start-iap-tunnel jingle-workshop 8080 --local-host-port=localhost:8081 --zone=$ZONE > /tmp/iap.log 2>&1 & sleep 8
ask 8081 "Where is my Christmas gift? My order is NP-1225."
ask 8081 "Can I change my delivery address?"
ask 8081 "What is the return policy?"
ask 8081 "When is the last Christmas delivery?"
# wait 1 minute, then Validate
```
