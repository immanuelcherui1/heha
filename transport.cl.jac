"""Fresh same-origin RPC transport for the transactional marketplace dispatcher.

Jac's auto-cache classifies SQL-backed dispatchers as readers. Explicit POSTs
avoid caching sign-in, mutations, and cross-user dashboard refreshes. Tokens
are sent in the JSON body, never in URLs, and never logged by application code.
"""
async def:pub requestMarket(action: str, data: dict, token: str) -> dict {
    response = (await fetch("/function/marketplace", {
        "method": "POST", "cache": "no-store", "credentials": "same-origin",
        "headers": {"Content-Type": "application/json"},
        "body": JSON.stringify({"action": action, "data": data, "token": token})
    })) as any;
    if not response.ok { return {"ok": False, "error": "The server could not complete this request. Refresh and try again."}; }
    envelope = await response.json();
    if not envelope["ok"] { return {"ok": False, "error": "The marketplace service is temporarily unavailable."}; }
    return envelope["data"]["result"] as dict;
}
