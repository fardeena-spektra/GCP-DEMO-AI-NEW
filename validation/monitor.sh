P=$(gcloud config get-value project 2>/dev/null)
V=$(gcloud storage buckets list --format='value(name)' --filter='name~^santas-knowledge-vault-')
echo "==== [1/4] Project: $P | Vault: $V ===="
echo "==== [2/4] Services ===="; gcloud services list --enabled --format="value(config.name)" | grep -E "aiplatform|compute|iap|logging|^storage.googleapis" | sort
echo "==== [3/4] North Pole data ===="; gcloud storage ls -r gs://$V; gcloud storage cat gs://$V/north-pole-data.json | grep -E '"version"|"status"' | head -3
echo "==== [4/4] Jingle's permissions ===="
gcloud projects get-iam-policy $P --flatten="bindings[].members" --filter="bindings.members:jingle-sa" --format="value(bindings.role)"
gcloud storage buckets get-iam-policy gs://$V --format=json | python3 -c "
import sys,json
for b in json.load(sys.stdin).get('bindings',[]):
    if any('jingle-sa' in m for m in b['members']): print(b['role'])"
