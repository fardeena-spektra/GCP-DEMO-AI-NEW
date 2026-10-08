# 🎄 The 12 Days of AI Christmas – Day 1: Jingle Awakens (Developer) 🎁

Upload the **contents** of this folder to the **root** of `fardeena-spektra/GCP-DEMO-AI-NEW` (branch `main`).

## ☁️ CloudLabs template (raw URLs)

| Item | Raw URL |
|---|---|
| Template | https://raw.githubusercontent.com/fardeena-spektra/GCP-DEMO-AI-NEW/refs/heads/main/deployment/deploy.yaml |
| Parameters | https://raw.githubusercontent.com/fardeena-spektra/GCP-DEMO-AI-NEW/refs/heads/main/deployment/param.yaml |
| masterdoc | https://raw.githubusercontent.com/fardeena-spektra/GCP-DEMO-AI-NEW/refs/heads/main/lab-guides/Day-01-Developer/masterdoc.json |

CloudLabs VM configuration is unchanged (VM name `labvm-{GET-DEPLOYMENT-ID}`, outputs vmPublicIp / vmUsername / vmPassword / vmPrivateIp / vpcId / subnetId).

## ✅ Validation steps (PowerShellV2, Run As System, DeploymentId = GET-DEPLOYMENT-ID, projectname = GET-GCP-PROJECT)

| Step name | Step ID | Script | Score |
|---|---|---|:---:|
| Prepare the Lab Environment | 9b3f1117-1528-4014-be9c-85b6a0de9c8c | validation/LAB01A-EX1-TASK1.ps1 | 5 |
| Deploy the Agent to a Private Compute Engine VM | a53704ee-648c-4671-83fc-4a8d539a0d88 | validation/LAB01A-EX3-TASK1.ps1 | 45 |
| Verify Grounded Responses from the Deployed Agent | ed2be13a-73d2-438c-a144-f5a161b2a830 | validation/LAB01A-EX3-TASK2.ps1 | 44 |

Questions: 3 × 2 points. Total 100.

## 🎄 Resource names

| Resource | Name |
|---|---|
| Network / subnet | north-pole-vpc-&lt;id&gt; / north-pole-subnet-&lt;id&gt; |
| IAP-only firewall | sleigh-gate-iap-&lt;id&gt; (tag `jingle`) |
| Knowledge bucket | santas-knowledge-vault-&lt;id&gt; |
| Jingle's identity | jingle-sa |
| Jingle's VM (learner creates) | jingle-workshop |
| Jingle's log | jingle |

## 🔗 Files used at lab time

| Used by | Raw URL |
|---|---|
| Prepare validator | https://raw.githubusercontent.com/fardeena-spektra/GCP-DEMO-AI-NEW/refs/heads/main/assets/north-pole-data.json |
| Learner, Challenge 3 | https://raw.githubusercontent.com/fardeena-spektra/GCP-DEMO-AI-NEW/refs/heads/main/starter/agent.py |
| Learner, Challenge 4 | https://raw.githubusercontent.com/fardeena-spektra/GCP-DEMO-AI-NEW/refs/heads/main/scripts/jingle-workshop-startup.sh |
| Instructor answer key | https://raw.githubusercontent.com/fardeena-spektra/GCP-DEMO-AI-NEW/refs/heads/main/solution/agent.py |
