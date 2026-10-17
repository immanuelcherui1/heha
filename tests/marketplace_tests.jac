"""Run with HEHA_DB=/tmp/heha-tests-<unique>.sqlite3 jac test -d tests -v."""
import from endpoints { marketplace }
import from datetime { date, timedelta }
import secrets;

def call(action: str, data: dict, token: str = "") -> dict {
    result = marketplace(action, data, token);
    assert result["ok"], str(result);
    return result["data"] as dict;
}

test "marketplace booking lifecycle and permissions" {
    customer = call("login", {"email": "customer@heha.demo", "password": "HehaDemo2026!"});
    mover = call("login", {"email": "mover@heha.demo", "password": "HehaDemo2026!"});
    customer_token = str(customer["token"]); mover_token = str(mover["token"]);
    result = call("request", {"pickup": "Kilimani, Nairobi", "destination": "Westlands, Nairobi", "move_date": (date.today() + timedelta(days=7)).isoformat(), "size": 2, "packing": True, "budget": 20000, "notes": "Second floor, lift available"}, customer_token);
    bid = str(result["booking_id"]);
    assert not marketplace("quote", {"booking_id": bid, "amount": 17000}, customer_token)["ok"];
    call("quote", {"booking_id": bid, "amount": 17000, "message": "Transport, packing, two crew members included"}, mover_token);
    board = call("dashboard", {}, customer_token);
    booking = [b for b in board["bookings"] if b["id"] == bid][0];
    quote_id = str(booking["quotes"][0]["id"]);
    call("accept", {"booking_id": bid, "quote_id": quote_id}, customer_token);
    assert not marketplace("accept", {"booking_id": bid, "quote_id": quote_id}, customer_token)["ok"];
    call("pay", {"booking_id": bid}, customer_token);
    assert not marketplace("pay", {"booking_id": bid}, customer_token)["ok"];
    call("progress", {"booking_id": bid}, mover_token);
    assert not marketplace("cancel", {"booking_id": bid}, customer_token)["ok"];
    call("progress", {"booking_id": bid}, mover_token);
    call("review", {"booking_id": bid, "rating": 5, "comment": "Excellent crew"}, customer_token);
    board = call("dashboard", {}, customer_token);
    booking = [b for b in board["bookings"] if b["id"] == bid][0];
    assert booking["status"] == "completed";
    assert booking["payment"][0]["amount"] == 5100;
    assert len(booking["events"]) == 7;
    assert len(booking["review"]) == 1;
}

test "registration isolation and validation" {
    email = secrets.token_hex(6) + "@example.test";
    newcomer = call("register", {"name": "New Customer", "email": email, "password": "StrongPassword123!", "role": "customer"});
    token = str(newcomer["token"]);
    assert call("dashboard", {}, token)["bookings"] == [];
    assert not marketplace("verify", {"mover_id": "x"}, token)["ok"];
    assert not marketplace("register", {"name": "Bad", "email": "bad@example.test", "password": "123", "role": "admin"})["ok"];
    assert not marketplace("request", {"pickup": "A", "destination": "B", "move_date": "2020-01-01", "size": 2, "budget": 10000}, token)["ok"];
    call("logout", {}, token);
    assert not marketplace("dashboard", {}, token)["ok"];
}

test "matching agent filters capacity and packing and explains ranking" {
    result = call("match", {"pickup": "Nairobi", "size": 3, "packing": True, "budget": 20000});
    assert len(result["matches"]) > 0;
    assert len(result["trace"]) == 4;
    for candidate in result["matches"] {
        assert candidate["verified"];
        assert candidate["capacity"] >= 3;
        assert "packing" in candidate["services"];
        assert len(candidate["reasons"]) >= 3;
    }
}
