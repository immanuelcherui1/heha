"""Assigned-booking conversation and private customer preparation progress."""
import from store { rows, one, uid, event }
import time;

# This module is not directly exposed as RPC. It is called after session validation.
def ensure_assigned(db: any, booking: dict, user: dict) {
    if user["role"] == "customer" and booking["customer_id"] == user["id"] { return; }
    if user["role"] == "mover" {
        assigned = rows(db, "SELECT q.id FROM quotes q JOIN movers m ON m.id=q.mover_id WHERE q.id=? AND m.user_id=? AND q.status='accepted'", (booking["accepted_quote"], user["id"]));
        if assigned { return; }
    }
    raise ValueError("Only the customer and their assigned mover can use this conversation.");
}

def messages_for(db: any, booking: dict, user: dict) -> list[dict] {
    if user["role"] == "admin" { return []; }
    try { ensure_assigned(db, booking, user); }
    except ValueError { return []; }
    return rows(db, "SELECT id,booking_id,author_name,author_role,body,created FROM messages WHERE booking_id=? ORDER BY created", (booking["id"],));
}

def send_message(db: any, booking: dict, user: dict, body: str) -> dict {
    ensure_assigned(db, booking, user);
    if booking["status"] not in ["confirmed", "in_transit", "completed"] {
        raise ValueError("Booking messages open after a quote is accepted.");
    }
    body = body.strip();
    if not body or len(body) > 1000 { raise ValueError("Write a message between 1 and 1000 characters."); }
    ident = uid();
    db.execute("INSERT INTO messages VALUES(?,?,?,?,?,?,?)", (ident, booking["id"], user["id"], user["name"], user["role"], body, time.time()));
    return {"message_id": ident};
}

def toggle_task(db: any, booking: dict, user: dict, code: str, valid_codes: list[str]) -> dict {
    if user["role"] != "customer" or booking["customer_id"] != user["id"] {
        raise ValueError("Only the booking customer can update their checklist.");
    }
    if code not in valid_codes { raise ValueError("This task is not part of the moving plan."); }
    if booking["status"] == "cancelled" { raise ValueError("This booking has been cancelled."); }
    existing = rows(db, "SELECT code FROM checklist WHERE booking_id=? AND code=?", (booking["id"], code));
    if existing { db.execute("DELETE FROM checklist WHERE booking_id=? AND code=?", (booking["id"], code)); }
    else { db.execute("INSERT INTO checklist VALUES(?,?,?)", (booking["id"], code, time.time())); }
    return {"completed": not bool(existing)};
}
