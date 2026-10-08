# 🎁 Day 1: Jingle Awakens 🔔

### ⏱️ Estimated Duration: 60 Minutes

### 🛷 Track A: Developer &nbsp;|&nbsp; Level: Foundation &nbsp;|&nbsp; Points: 100 &nbsp;|&nbsp; 🎖️ Badge: **Elf Developer**

<p align="center">🔔 ✨ 🦌 🎅 🦌 ✨ 🔔</p>

## 🎅 The Mission

It's the Christmas rush at **North Pole Gifts** 🎁 and the customer-support elves 🧝 are drowning in messages. Santa has asked you to wake up **Jingle**, the North Pole's first AI customer-support agent.

Jingle must answer customers' questions such as:

- 🎁 *"Where is my Christmas gift?"*
- 🏠 *"Can I change my delivery address?"*
- ↩️ *"What is the return policy?"*
- 🛷 *"When is the last Christmas delivery?"*

Santa's one unbreakable rule: **Jingle never invents an answer.** Every date, status and rule must come from **Santa's Knowledge Vault**.

> 🧭 **This is a challenge lab.** Each challenge gives you a **goal**, the **rules** your solution must follow and a few **hints**. How you get there is up to you. The Elf Validators check the **result**, not the commands you used.

## 🗺️ Today's Route

| Stop | Challenge | Validated |
|:---:|---|:---:|
| 🎄 | **Challenge 1: North Pole Command Center** – prepare and explore your workshop | ✅ |
| 📚 | **Challenge 2: Santa's Knowledge Vault** – discover what Jingle may know | — |
| 🧸 | **Challenge 3: Toy Workshop** – build and test Jingle | — |
| 🔐 | **Challenge 4: Santa's Vault** – deploy Jingle privately | ✅ |
| 🎁 | **Challenge 5: Customers Are Waiting** – prove Jingle answers from the vault | ✅ |

## 🏗️ Jingle's Workshop

```
 Elf (Cloud Shell)
        │  Sleigh gate: IAP tunnel (no public port)
        ▼
 ┌──────────────────────────┐   lookup_north_pole()   ┌────────────────────────────┐
 │ VM: jingle-workshop      │ ──────────────────────▶ │ Santa's Knowledge Vault    │
 │ ADK agent "Jingle"       │   (runs as jingle-sa)   │   north-pole-data.json     │
 │ private, IAP only        │                         │                            │
 └────────────┬─────────────┘                         └────────────────────────────┘
              │ Gemini 2.5 Flash (<inject key="Region" enableCopy="false"/>)
              ▼
        Vertex AI                                 Cloud Logging ◀── Jingle's logs
```

## 🎄 Your North Pole

| Resource | Value |
|---|---|
| ☁️ Project ID | <inject key="ProjectId" enableCopy="true"/> |
| 🌍 Region | **<inject key="Region" enableCopy="true"/>** |
| 📚 Santa's Knowledge Vault | <inject key="KbBucket" enableCopy="true"/> |
| 🔐 Jingle's identity | <inject key="AgentServiceAccount" enableCopy="true"/> |
| 🧭 Workshop subnet | <inject key="subnetName" enableCopy="true"/> |

---

## 🎄 Challenge 1: North Pole Command Center

### ⚙️ Task 1: Prepare the North Pole

1. Wake up the North Pole: this one-time setup turns on the Google Cloud services, loads the North Pole data into Santa's Knowledge Vault and gives Jingle's identity its permissions.

1. Select the **Validate** button below and wait for the **Success** message before you continue. If you see a failure, wait one minute and select **Validate** again.

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   >
   > - Select the **Validate** button for the corresponding task. If you receive a success message, you can proceed to the next task.
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

   <validation step="9b3f1117-1528-4014-be9c-85b6a0de9c8c" />

### 🔐 Task 2: Enter the Command Center

1. On the lab VM desktop, open the **Google Cloud Console** shortcut and sign in:

   - Email/Username: <inject key="AzureADUserEmail" enableCopy="true"/>
   - Password: <inject key="AzureADUserPassword" enableCopy="true"/>

1. Select your project <inject key="ProjectId" enableCopy="false"/> and open **Cloud Shell** (**>_**).

1. Load your elf toolkit. These variables are used in every challenge:

   ```bash
   export PROJECT_ID=<inject key="ProjectId" enableCopy="false"/>
   export REGION=<inject key="Region" enableCopy="false"/>
   export VAULT=<inject key="KbBucket" enableCopy="false"/>
   export JINGLE_SA=<inject key="AgentServiceAccount" enableCopy="false"/>
   export SUBNET=<inject key="subnetName" enableCopy="false"/>
   gcloud config set project $PROJECT_ID
   ```

   > 📝 **Note:** If Cloud Shell restarts, load the toolkit again.

---

## 📚 Challenge 2: Santa's Knowledge Vault

🎯 **Goal:** Find out exactly what Jingle is allowed to know before you build it.

📜 **Rules**

- Explore Santa's Knowledge Vault (`$VAULT`) and open `north-pole-data.json`.
- Note the data `version`. You will need it to prove Jingle answers from the vault.

🔎 **Find the answers yourself**

- What is the status of order **NP-1225**, and when will it arrive?
- Until when can a customer change a delivery address?
- What is the last day to order for **standard** Christmas delivery?

💡 **Hints**

- `gcloud storage` can list and print objects in a bucket.

---

## 🧸 Challenge 3: Toy Workshop

🎯 **Goal:** Build Jingle as a Python **ADK** agent on **Gemini** and prove, locally, that it answers the four customer questions from the vault.

📜 **Rules**

- Jingle lives in a folder named **`~/jingle`** containing `__init__.py`, `agent.py` and `requirements.txt` (`google-adk`, `google-cloud-storage`).
- Start from the elves' starter file and complete its three **TODOs**. Starter file: `https://raw.githubusercontent.com/fardeena-spektra/GCP-DEMO-AI-NEW/refs/heads/main/starter/agent.py`

- Do **not** remove the `_log(...)` calls. The Elf Validators read those log lines.
- Jingle must use **Gemini on Vertex AI** in your region. Its settings go in `~/jingle/.env`:

   | Setting | Value |
   |---|---|
   | `GOOGLE_GENAI_USE_VERTEXAI` | `TRUE` |
   | `GOOGLE_CLOUD_PROJECT` | your project |
   | `GOOGLE_CLOUD_LOCATION` | your region |
   | `KB_BUCKET` | Santa's Knowledge Vault |
   | `KB_FILE` | `north-pole-data.json` |

- Before moving on, ask Jingle all four customer questions and confirm each answer comes from a **tool call** to `lookup_north_pole`, not from Gemini's imagination. For a question that is not about North Pole Gifts, Jingle should politely decline.

💡 **Hints**

- The ADK CLI can run Jingle in your terminal (`adk run`) or as a local API server (`adk api_server`).
- ADK reads a tool's **docstring** to decide when to call it. A vague docstring makes a forgetful elf.
- The **instruction** is Jingle's guardrail. Tell it what it must always do, and what it must never do.
- When a customer asks *"Where is my Christmas gift?"* without an order number, a good elf asks for one.

---

## 🔐 Challenge 4: Santa's Vault

🎯 **Goal:** Move Jingle out of your Cloud Shell and into its own **private** workshop VM, running under its **own identity**.

📜 **Rules**

- Upload your completed `~/jingle` folder to **`gs://$VAULT/app/jingle`**.
- Create a VM with these exact properties:

   | Property | Required value |
   |---|---|
   | Name | `jingle-workshop` |
   | Zone | the same zone as your lab VM (`labvm-…`) |
   | Subnet | `$SUBNET` |
   | Image | Debian 12 |
   | Service account | Jingle's identity (`$JINGLE_SA`), with the `cloud-platform` scope |
   | Network tag | `jingle` (the only tag allowed through the 🛷 sleigh gate) |
   | Metadata | `KB_BUCKET` = your vault, `KB_FILE` = `north-pole-data.json`, `GOOGLE_CLOUD_LOCATION` = your region |
   | Startup script | `https://raw.githubusercontent.com/fardeena-spektra/GCP-DEMO-AI-NEW/refs/heads/main/scripts/jingle-workshop-startup.sh` |

- The workshop must have **no open public port**. Only IAP may reach it.

💡 **Hints**

- `gcloud compute instances create` has flags for every property in the table. `--metadata-from-file` can attach a startup script.
- The first boot installs ADK and takes **3–5 minutes**. Jingle listens on port **8080** inside the VM.
- Stuck? The workshop writes its progress to `/var/log/jingle-setup.log`. You can reach the VM with `gcloud compute ssh … --tunnel-through-iap`.

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   >
   > - Select the **Validate** button for the corresponding task. If you receive a success message, you can proceed to the next task.
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

   <validation step="a53704ee-648c-4671-83fc-4a8d539a0d88" />

## 🎁 Challenge 5: Customers Are Waiting

🎯 **Goal:** Prove that the **deployed** Jingle answers real customers from Santa's Knowledge Vault.

📜 **Rules**

- Reach Jingle only through the 🛷 sleigh gate (an **IAP tunnel** to port 8080 of `jingle-workshop`).
- Ask the deployed Jingle all four customer questions from the mission.
- Wait about **1 minute** for Jingle's logs to reach Cloud Logging, then validate.

💡 **Hints**

- `gcloud compute start-iap-tunnel` can forward a local port in Cloud Shell to the VM.
- Jingle speaks the ADK API: create a session with `POST /apps/jingle/users/<user>/sessions/<session>`, then send a message with `POST /run` and a body like:

   ```json
   {"app_name": "jingle", "user_id": "elf", "session_id": "s1",
    "new_message": {"role": "user", "parts": [{"text": "When is the last Christmas delivery?"}]}}
   ```

- In **Logs Explorer**, Jingle's log is named `jingle`. Each `KB_LOOKUP` entry shows which file and version it read.

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   >
   > - Select the **Validate** button for the corresponding task. If you receive a success message, you can proceed to the next task.
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

   <validation step="ed2be13a-73d2-438c-a144-f5a161b2a830" />

## 🎖️ Badge Unlocked: Elf Developer

<p align="center">🎄 🎖️ <b>ELF DEVELOPER</b> 🎖️ 🎄</p>

You woke Jingle up! Today you:

- ✅ Built **Jingle**, a Python ADK agent on **Gemini**.
- ✅ Grounded every answer in **Santa's Knowledge Vault** with a tool.
- ✅ Deployed Jingle to a **private workshop**, behind the sleigh gate, with its **own identity**.
- ✅ Proved Jingle answers real customers without inventing anything.

🔜 **Next stop on the road to Save Christmas:** 😈 **The Grinch is watching...**

### 👉 Select **Next >>** to continue to the Elf Knowledge Check. 🧝
