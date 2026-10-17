"""Async actions for the Heha marketplace shell."""
impl app.refresh(token: str) {
    action = "dashboard"; data: dict = {};
    result = await requestMarket(action, data, token);
    if not result["ok"] {
        sessionStorage.removeItem("heha_session"); session = ""; user = {};
        error = str(result["error"]); return;
    }
    payload = result["data"] as dict;
    user = payload["user"] as dict; bookings = payload["bookings"] as list[dict];
    movers = payload["movers"] as list[dict]; ownMover = payload["own_mover"] as list[dict];
    profiles = payload["own_mover"] as list[dict];
    if len(profiles) > 0 {
        profile = profiles[0]; companyName = str(profile["name"]); companyArea = str(profile["area"]); companyBio = str(profile["bio"]); companyRate = str(profile["rate"]); companyCapacity = str(profile["capacity"]); companyServices = str(profile["services"]);
    }
}
impl app.perform(action: str, data: dict) {
    busy = True; error = ""; notice = "";
    try {
        token = session;
        result = await requestMarket(action, data, token);
        if not result["ok"] { error = str(result["error"]); }
        else {
            await refresh(token); notice = "Your changes have been saved.";
            if action == "request" { page = "dashboard"; notice = "Your request was published. It is an invitation to quote, not a confirmed booking."; }
        }
    } except Exception { error = "Connection interrupted. Refresh to check the result before trying again."; }
    busy = False;
}
impl app.authenticate(loginEmail: str, loginPassword: str, mode: str) {
    busy = True; error = ""; notice = "";
    try {
        action = mode; token = "";
        data = {"email": loginEmail, "password": loginPassword, "name": name, "role": accountRole, "area": serviceArea};
        result = await requestMarket(action, data, token);
        if not result["ok"] { error = str(result["error"]); }
        else {
            newToken = str(result["data"]["token"]);
            sessionStorage.setItem("heha_session", newToken); session = newToken;
            await refresh(newToken); page = "dashboard"; password = "";
        }
    } except Exception { error = "Sign-in is unavailable. Please try again."; }
    busy = False;
}
impl app.logout() {
    try {
        action = "logout"; data: dict = {}; token = session;
        await requestMarket(action, data, token);
    } except Exception { }
    sessionStorage.removeItem("heha_session"); session = ""; user = {}; bookings = []; page = "discover"; notice = "You have signed out.";
}
impl app.findMatches(e: FormEvent) {
    e.preventDefault(); busy = True; error = "";
    try {
        action = "match"; token = ""; data = {"pickup": pickup, "size": size, "packing": packing, "budget": budget, "notes": notes};
        result = await requestMarket(action, data, token);
        if result["ok"] { matches = result["data"]["matches"] as list[dict]; trace = result["data"]["trace"] as list[str]; movePlan = result["data"]["plan"] as dict; page = "matches"; }
        else { error = str(result["error"]); }
    } except Exception { error = "The matching agent is unavailable. Please try again."; }
    busy = False;
}
impl app.postMove(e: FormEvent) {
    e.preventDefault();
    await perform("request", {"pickup": pickup, "destination": destination, "move_date": moveDate, "size": size, "packing": packing, "budget": budget, "notes": notes});
}
