# =============================================================================
# 🎁 Jingle Awakens - starter file
# Complete the three TODOs so Jingle answers ONLY from Santa's Knowledge Vault.
# Do not remove the _log(...) calls: the Elf Validators read these log lines.
# =============================================================================
import json
import os

from google.adk.agents import Agent
from google.cloud import storage

def _log(severity: str, message: str, **fields) -> None:
    """Write a structured log line that Cloud Logging parses automatically."""
    print(json.dumps({"severity": severity, "message": message, **fields}), flush=True)

def lookup_north_pole(query: str) -> dict:
    # TODO 1: Write a docstring. Gemini reads it to decide WHEN to call this tool,
    #         so describe what it looks up and what "query" can contain.
    bucket_name = os.environ.get("KB_BUCKET")
    file_name = os.environ.get("KB_FILE", "north-pole-data.json")
    try:
        blob = storage.Client().bucket(bucket_name).blob(file_name)
        data = json.loads(blob.download_as_text())
    except Exception as exc:
        _log("ERROR", "KB_READ_FAILED", bucket=bucket_name, file=file_name, error=str(exc))
        return {"status": "error", "message": "The North Pole records are unavailable."}

    q = query.lower()
    matches = [
        r for r in data.get("records", [])
        if q in r["name"].lower() or any(k in q or q in k for k in r.get("keywords", []))
    ]
    _log("INFO", "KB_LOOKUP", query=query, file=file_name,
         kb_version=data.get("version"), matches=len(matches))
    return {"status": "success", "kb_version": data.get("version"),
            "records": matches or data.get("records", [])}

root_agent = Agent(
    name="jingle",
    model=os.environ.get("AGENT_MODEL", "gemini-2.5-flash"),
    description="Jingle, the North Pole Gifts customer-support agent.",
    # TODO 2: Write Jingle's instruction (its guardrail). Jingle must ALWAYS use the tool
    #         for order, address, returns and delivery-date questions, never invent facts,
    #         and ask for an order number when a customer does not give one.
    instruction="",
    # TODO 3: Give Jingle its tool.
    tools=[],
)
