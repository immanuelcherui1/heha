"""Public RPC boundary; every protected action validates its session and role."""
import from store { initialize, connect, uid, rows, one, current_user, public_user, password_hash, add_user, require_role, event }
import from matching { rank_movers }
import sqlite3;
import secrets;
import hashlib;
import hmac;
import time;
import from datetime { date }

def text(data: dict, key: str, limit: int = 500) -> str {
    value = str(data.get(key, "")).strip();
    if len(value) > limit { raise ValueError(f"{key} is too long (maximum {limit} characters)."); }
    return value;
}

def number(data: dict, key: str, minimum: int, maximum: int) -> int {
    try { value = int(data.get(key, 0)); }
    except (ValueError, TypeError) { raise ValueError(f"{key} must be a whole number."); }
    if value < minimum or value > maximum { raise ValueError(f"{key} must be between {minimum} and {maximum}."); }
    return value;
}

def dashboard(db: any, user: dict) -> dict {
    role = user["role"];
    if role == "customer" {
        bookings = rows(db, "SELECT b.*,u.name customer_name FROM bookings b JOIN users u ON u.id=b.customer_id WHERE customer_id=? ORDER BY created DESC", (user["id"],));
    } elif role == "mover" {
        mover = one(db, "SELECT * FROM movers WHERE user_id=?", (user["id"],));
        bookings = rows(db, "SELECT b.*,u.name customer_name FROM bookings b JOIN users u ON u.id=b.customer_id WHERE b.status='requested' OR b.id IN (SELECT booking_id FROM quotes WHERE mover_id=?) ORDER BY created DESC", (mover["id"],));
    } else {
        bookings = rows(db, "SELECT b.*,u.name customer_name FROM bookings b JOIN users u ON u.id=b.customer_id ORDER BY created DESC");
    }
    for booking in bookings {
        params = (booking["id"],);
        sql = "SELECT q.*,m.name mover_name,m.rating FROM quotes q JOIN movers m ON m.id=q.mover_id WHERE q.booking_id=?";
        if role == "mover" {
            sql += " AND m.user_id=?"; params = (booking["id"], user["id"]);
        }
        booking["quotes"] = rows(db, sql, params);
        booking["events"] = rows(db, "SELECT * FROM events WHERE booking_id=? ORDER BY created", (booking["id"],));
        booking["payment"] = rows(db, "SELECT * FROM payments WHERE booking_id=?", (booking["id"],));
        booking["review"] = rows(db, "SELECT * FROM reviews WHERE booking_id=?", (booking["id"],));
        # Mover leads intentionally expose route and requirements, never customer email.
    }
    return {"user": public_user(user), "bookings": bookings,
            "movers": rows(db, "SELECT * FROM movers ORDER BY verified DESC,rating DESC"),
            "own_mover": rows(db, "SELECT * FROM movers WHERE user_id=?", (user["id"],))};
}

def execute(db: any, action: str, data: dict, token: str) -> dict {
    if action == "browse" {
        return {"movers": rows(db, "SELECT * FROM movers WHERE verified=1 ORDER BY rating DESC"), "demo": __import__("os").getenv("HEHA_DEMO", "1") == "1"};
    }
    if action in ["login", "register"] {
        email = text(data, "email", 160).lower(); password = text(data, "password", 128);
        if action == "register" {
            name = text(data, "name", 80); role = text(data, "role", 20);
            if not name or "@" not in email or len(password) < 10 { raise ValueError("Enter your name, a valid email, and a password of at least 10 characters."); }
            if role not in ["customer", "mover"] { raise ValueError("Choose a customer or mover account."); }
            ident = add_user(db, name, email, password, role);
            if role == "mover" {
                area = text(data, "area", 80) or "Nairobi";
                db.execute("INSERT INTO movers VALUES(?,?,?,?,?,?,?,?,?,?,?)", (uid(), ident, name, area, "New moving partner — verification pending.", 5000, 3, 0, 0, 0, "packing"));
            }
        }
        found = rows(db, "SELECT * FROM users WHERE email=?", (email,));
        if not found or not hmac.compare_digest(str(found[0]["password_hash"]), password_hash(password, str(found[0]["salt"]))) {
            raise ValueError("Email or password is incorrect.");
        }
        user = found[0]; session = secrets.token_urlsafe(32);
        db.execute("DELETE FROM sessions WHERE expires<?", (time.time(),));
        db.execute("INSERT INTO sessions VALUES(?,?,?)", (hashlib.sha256(session.encode()).hexdigest(), user["id"], time.time() + 86400));
        return {"token": session, "user": public_user(user)};
    }
    if action == "match" {
        profiles = rows(db, "SELECT * FROM movers WHERE verified=1");
        return rank_movers(profiles, text(data, "pickup", 120), number(data, "size", 1, 6), bool(data.get("packing", False)), number(data, "budget", 0, 1000000));
    }
    user = current_user(db, token);
    if action == "logout" {
        db.execute("DELETE FROM sessions WHERE token_hash=?", (hashlib.sha256(token.encode()).hexdigest(),)); return {};
    }
    if action == "dashboard" { return dashboard(db, user); }
    if action == "request" {
        require_role(user, "customer");
        pickup = text(data, "pickup", 120); destination = text(data, "destination", 120);
        moving = text(data, "move_date", 10);
        if not pickup or not destination or pickup.lower() == destination.lower() { raise ValueError("Enter different pickup and destination locations."); }
        try { day = date.fromisoformat(moving); }
        except ValueError { raise ValueError("Choose a valid moving date."); }
        if day < date.today() { raise ValueError("Your moving date cannot be in the past."); }
        ident = uid();
        db.execute("INSERT INTO bookings VALUES(?,?,?,?,?,?,?,?,?,?,?,?)", (ident, user["id"], pickup, destination, moving, number(data, "size", 1, 6), int(bool(data.get("packing", False))), number(data, "budget", 1000, 1000000), text(data, "notes", 1000), "requested", None, time.time()));
        event(db, ident, str(user["name"]), "Move requested. Verified movers can submit itemised quotes.");
        return {"booking_id": ident};
    }
    if action == "profile" {
        require_role(user, "mover");
        name = text(data, "name", 80); area = text(data, "area", 80);
        if not name or not area { raise ValueError("Company name and service area are required."); }
        db.execute("UPDATE movers SET name=?,area=?,bio=?,rate=?,capacity=?,services=?,verified=0 WHERE user_id=?", (name, area, text(data, "bio", 500), number(data, "rate", 1000, 100000), number(data, "capacity", 1, 6), text(data, "services", 200), user["id"]));
        return {"message": "Profile saved and submitted for admin verification."};
    }
    if action == "verify" {
        require_role(user, "admin");
        m = one(db, "SELECT * FROM movers WHERE id=?", (text(data, "mover_id", 32),));
        db.execute("UPDATE movers SET verified=? WHERE id=?", (0 if m["verified"] else 1, m["id"]));
        return {};
    }
    booking = one(db, "SELECT * FROM bookings WHERE id=?", (text(data, "booking_id", 32),));
    if action == "quote" {
        require_role(user, "mover"); mover = one(db, "SELECT * FROM movers WHERE user_id=?", (user["id"],));
        if not mover["verified"] { raise ValueError("An admin must verify your company before you can quote."); }
        if booking["status"] != "requested" { raise ValueError("This move is no longer accepting quotes."); }
        if int(mover["capacity"]) < int(booking["size"]) { raise ValueError("This job exceeds your registered capacity."); }
        if booking["packing"] and "packing" not in str(mover["services"]) { raise ValueError("This job requires packing service."); }
        db.execute("INSERT INTO quotes VALUES(?,?,?,?,?,?,?) ON CONFLICT(booking_id,mover_id) DO UPDATE SET amount=excluded.amount,message=excluded.message,created=excluded.created", (uid(), booking["id"], mover["id"], number(data, "amount", 1000, 1000000), text(data, "message", 500) or "Transport, loading and unloading included.", "pending", time.time()));
        event(db, str(booking["id"]), str(mover["name"]), "Submitted a firm quote."); return {};
    }
    if action == "progress" {
        require_role(user, "mover");
        accepted = one(db, "SELECT q.* FROM quotes q JOIN movers m ON q.mover_id=m.id WHERE q.id=? AND m.user_id=?", (booking["accepted_quote"], user["id"]));
        next_status = {"confirmed": "in_transit", "in_transit": "completed"};
        if booking["status"] not in next_status { raise ValueError("This booking cannot advance right now."); }
        status = str(next_status[booking["status"]]);
        db.execute("UPDATE bookings SET status=? WHERE id=?", (status, booking["id"]));
        if status == "completed" { db.execute("UPDATE movers SET jobs=jobs+1 WHERE id=?", (accepted["mover_id"],)); }
        event(db, str(booking["id"]), str(user["name"]), "Move " + status.replace("_", " ") + "."); return {};
    }
    if booking["customer_id"] != user["id"] { raise ValueError("You can only change your own bookings."); }
    require_role(user, "customer");
    if action == "accept" {
        if booking["status"] != "requested" { raise ValueError("A quote has already been accepted or the booking is closed."); }
        quote = one(db, "SELECT q.* FROM quotes q JOIN movers m ON q.mover_id=m.id WHERE q.id=? AND q.booking_id=? AND m.verified=1", (text(data, "quote_id", 32), booking["id"]));
        db.execute("UPDATE quotes SET status=CASE WHEN id=? THEN 'accepted' ELSE 'declined' END WHERE booking_id=?", (quote["id"], booking["id"]));
        db.execute("UPDATE bookings SET status='confirmed',accepted_quote=? WHERE id=?", (quote["id"], booking["id"]));
        event(db, str(booking["id"]), str(user["name"]), "Quote accepted. Your moving team is confirmed."); return {};
    }
    if action == "cancel" {
        if booking["status"] not in ["requested", "confirmed"] { raise ValueError("Only requested or confirmed moves can be cancelled."); }
        db.execute("UPDATE bookings SET status='cancelled' WHERE id=?", (booking["id"],));
        db.execute("UPDATE quotes SET status='cancelled' WHERE booking_id=?", (booking["id"],));
        event(db, str(booking["id"]), str(user["name"]), "Booking cancelled. Any demo payment remains recorded for audit; no real money moved."); return {};
    }
    if action == "pay" {
        if booking["status"] != "confirmed" { raise ValueError("Confirm a quote before recording a demo deposit."); }
        quote = one(db, "SELECT * FROM quotes WHERE id=?", (booking["accepted_quote"],));
        amount = max(1, int(quote["amount"]) * 30 // 100);
        db.execute("INSERT INTO payments VALUES(?,?,?,?,?)", (uid(), booking["id"], amount, "DEMO-" + secrets.token_hex(4).upper(), time.time()));
        event(db, str(booking["id"]), str(user["name"]), "Demo 30% deposit recorded. No real M-Pesa transaction."); return {};
    }
    if action == "review" {
        if booking["status"] != "completed" { raise ValueError("Reviews are available after the move is completed."); }
        quote = one(db, "SELECT * FROM quotes WHERE id=?", (booking["accepted_quote"],));
        db.execute("INSERT INTO reviews VALUES(?,?,?,?,?,?)", (uid(), booking["id"], quote["mover_id"], number(data, "rating", 1, 5), text(data, "comment", 500), time.time()));
        db.execute("UPDATE movers SET rating=(SELECT AVG(rating) FROM reviews WHERE mover_id=?) WHERE id=?", (quote["mover_id"], quote["mover_id"]));
        event(db, str(booking["id"]), str(user["name"]), "Posted a verified booking review."); return {};
    }
    raise ValueError("Unknown marketplace action.");
}

def:pub marketplace(action: str, data: dict, token: str = "") -> dict {
    initialize();
    try {
        with connect() as db {
            # Serialize marketplace mutations: a booking can have only one accepted quote.
            db.execute("BEGIN IMMEDIATE");
            result = execute(db, action, data, token);
        }
        return {"ok": True, "data": result};
    } except sqlite3.IntegrityError {
        return {"ok": False, "error": "This email, payment or review already exists. Refresh and try again."};
    } except ValueError as exc {
        return {"ok": False, "error": str(exc)};
    }
}
