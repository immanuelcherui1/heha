"""Planning, private messaging, checklist ownership and mover verification tests."""
import from endpoints { marketplace }
import from planning { build_plan }
import from datetime { date, timedelta }
import secrets;

def api(action: str, data: dict, token: str = "") -> dict {
    response = marketplace(action, data, token);
    assert response["ok"], str(response);
    return response["data"] as dict;
}

def demo_session(account: str) -> str {
    response = api("login", {"email": account + "@heha.demo", "password": "HehaDemo2026!"});
    return str(response["token"]);
}

def new_move(token: str, notes: str = "Glass table, fridge, third floor with no lift") -> str {
    response = api("request", {"pickup": "Nairobi", "destination": "Kiambu", "move_date": (date.today() + timedelta(days=10)).isoformat(), "size": 2, "packing": True, "budget": 22000, "notes": notes}, token);
    return str(response["booking_id"]);
}

def find_booking(token: str, ident: str) -> dict {
    board = api("dashboard", {}, token); bookings = board["bookings"] as list[dict];
    return [b for b in bookings if b["id"] == ident][0];
}

test "planner gives evidence based safety preparation without inventing distance" {
    plan = build_plan("Fragile mirror, fridge, piano, no lift, dog and plants", 4, True, 9000);
    tasks = plan["tasks"] as list[dict]; risks = plan["risks"] as list[dict];
    codes = [t["code"] for t in tasks]; risk_codes = [r["code"] for r in risks];
    assert "fragile" in codes and "appliances" in codes;
    assert "pets" in codes and "plants" in codes;
    assert "packing" in codes and "self_pack" not in codes;
    assert "stairs" in risk_codes and "heavy" in risk_codes;
    assert "large_home" in risk_codes and "budget" in risk_codes;
    assert plan["rules_evaluated"] == 17;
    assert plan["box_range"] == "32–60";
    assert "distance" not in plan;
    assert plan["mode"] == "deterministic_graph";
    for risk in risks { assert risk["reason"]; }
}

test "planner adapts to missing notes and self packing" {
    plan = build_plan("", 1, False, 20000);
    tasks = plan["tasks"] as list[dict]; risks = plan["risks"] as list[dict];
    assert "self_pack" in [t["code"] for t in tasks];
    assert "packing" not in [t["code"] for t in tasks];
    assert "missing_notes" in [r["code"] for r in risks];
    assert "heavy" not in [r["code"] for r in risks];
    assert "budget" not in [r["code"] for r in risks];
}

test "checklist persists and remains private to its customer" {
    customer = demo_session("customer"); mover = demo_session("mover");
    bid = new_move(customer);
    api("checklist", {"booking_id": bid, "code": "inventory"}, customer);
    assert "inventory" in find_booking(customer, bid)["checklist"];
    assert not marketplace("checklist", {"booking_id": bid, "code": "inventory"}, mover)["ok"];
    assert not marketplace("checklist", {"booking_id": bid, "code": "invented"}, customer)["ok"];
    api("checklist", {"booking_id": bid, "code": "inventory"}, customer);
    assert "inventory" not in find_booking(customer, bid)["checklist"];
    api("cancel", {"booking_id": bid}, customer);
    assert not marketplace("checklist", {"booking_id": bid, "code": "inventory"}, customer)["ok"];
}

test "conversation is limited to the booking owner and accepted mover" {
    customer = demo_session("customer"); mover = demo_session("mover"); rival = demo_session("green"); admin = demo_session("admin");
    bid = new_move(customer);
    assert not marketplace("message", {"booking_id": bid, "body": "Too early"}, customer)["ok"];
    api("quote", {"booking_id": bid, "amount": 19000}, mover);
    api("quote", {"booking_id": bid, "amount": 18000}, rival);
    b = find_booking(customer, bid); quotes = b["quotes"] as list[dict];
    chosen = [q for q in quotes if q["mover_name"] == "Nairobi Swift Movers"][0];
    api("accept", {"booking_id": bid, "quote_id": chosen["id"]}, customer);
    api("message", {"booking_id": bid, "body": "Please arrive at 8 AM; parking is arranged."}, customer);
    api("message", {"booking_id": bid, "body": "Confirmed. Our crew will bring protective wrapping."}, mover);
    assert len(find_booking(customer, bid)["messages"]) == 2;
    assert len(find_booking(mover, bid)["messages"]) == 2;
    assert find_booking(rival, bid)["messages"] == [];
    assert find_booking(admin, bid)["messages"] == [];
    assert not marketplace("message", {"booking_id": bid, "body": "I was not chosen"}, rival)["ok"];
    assert not marketplace("message", {"booking_id": bid, "body": ""}, mover)["ok"];
    outsider = api("register", {"name": "Other customer", "email": secrets.token_hex(8) + "@example.test", "password": "AnotherPassword123!", "role": "customer"});
    assert not marketplace("message", {"booking_id": bid, "body": "Unauthorised"}, str(outsider["token"]))["ok"];
}

test "new mover cannot self verify or quote until admin approval" {
    customer = demo_session("customer"); admin = demo_session("admin");
    suffix = secrets.token_hex(6);
    registered = api("register", {"name": "Test Movers " + suffix, "email": suffix + "@movers.test", "password": "StrongMoverPassword123!", "role": "mover", "area": "Nairobi"});
    token = str(registered["token"]);
    board = api("dashboard", {}, token);
    profile = board["own_mover"][0];
    assert not profile["verified"];
    bid = new_move(customer);
    assert not marketplace("quote", {"booking_id": bid, "amount": 15000}, token)["ok"];
    assert not marketplace("verify", {"mover_id": profile["id"]}, token)["ok"];
    api("verify", {"mover_id": profile["id"]}, admin);
    api("quote", {"booking_id": bid, "amount": 15000}, token);
    api("profile", {"name": "Updated Movers", "area": "Nairobi", "bio": "Careful moving crew", "rate": 4500, "capacity": 3, "services": "packing,assembly"}, token);
    board = api("dashboard", {}, token);
    assert not board["own_mover"][0]["verified"];
    assert not marketplace("quote", {"booking_id": bid, "amount": 16000}, token)["ok"];
}
