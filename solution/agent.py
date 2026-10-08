import json
import os

from google.adk.agents import Agent
from google.cloud import storage

def _log(severity: str, message: str, **fields) -> None:
    """Write a structured log line that Cloud Logging parses automatically."""
    print(json.dumps({"severity": severity, "message": message, **fields}), flush=True)

def lookup_north_pole(query: str) -> dict:
    """Looks up official North Pole Gifts information: order tracking, delivery address changes,
    the returns policy and the last Christmas delivery dates.

    Args:
        query: An order number or keyword, for example "NP-1225", "change address", "returns" or "last Christmas delivery".

    Returns:
        A dict with a status, the data version and the matching records.
    """
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
    instruction=(
        "You are Jingle, the cheerful North Pole Gifts customer-support elf. "
        "For ANY question about orders, gift tracking, delivery addresses, returns or Christmas delivery dates "
        "you MUST call the lookup_north_pole tool and answer only from its result. Never invent dates, "
        "statuses or rules. If a customer asks where their gift is without an order number, ask for it "
        "(order numbers look like NP-1225). If the tool returns an error, apologise and suggest the "
        "customer contacts the North Pole help desk. Politely decline anything not about North Pole Gifts."
    ),
    tools=[lookup_north_pole],
)
