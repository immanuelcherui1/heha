"""A deterministic planning agent: observe, filter, score, explain, recommend.

The agent traverses an ephemeral Jac graph built from current marketplace
records. It requires no model key and never accepts a quote autonomously.
"""
node MoveNeed {
    has area: str, size: int, packing: bool, budget: int;
}
node MoverCandidate { has profile: dict; }
edge EligibleRoute { has source: str = "marketplace"; }

walker MatchAgent {
    has area: str = "", size: int = 1, packing: bool = False, budget: int = 0;
    has candidates: list[dict] = [], trace: list[str] = [], examined: int = 0;

    can plan with MoveNeed entry {
        self.area = here.area; self.size = here.size;
        self.packing = here.packing; self.budget = here.budget;
        self.trace.append("Observed your route, household size, packing needs and budget.");
        visit [->:EligibleRoute:->];
    }

    can evaluate with MoverCandidate entry {
        self.examined += 1;
        m = here.profile;
        if not m["verified"] or int(m["capacity"]) < self.size { skip; }
        local = str(m["area"]).lower() in self.area.lower();
        services = str(m["services"]);
        if self.packing and "packing" not in services { skip; }
        estimate = int(m["rate"]) * self.size + (2500 if self.packing else 0);
        score: float = float(str(m["rating"])) * 10.0 + (25.0 if local else 0.0);
        reasons: list[str] = ["Verified moving partner", f"Capacity for {self.size} room(s)"];
        if local { reasons.append("Local crew near pickup"); }
        else { reasons.append("Confirm out-of-area transport with mover"); }
        if self.packing { reasons.append("Packing service available"); }
        if self.budget > 0 {
            if estimate <= self.budget { score += 20.0; reasons.append("Indicative estimate within budget"); }
            else { score -= 10.0; reasons.append("Estimate above budget; request a firm quote"); }
        }
        self.candidates.append({**m, "score": float(f"{score:.1f}"), "estimate": estimate, "reasons": reasons});
    }

    can explain with MoveNeed exit {
        self.trace.append(f"Traversed {self.examined} mover nodes; excluded unverified, undersized or incompatible crews.");
        self.trace.append("Ranked by service fit, pickup area, reputation and estimated budget fit.");
        self.trace.append("A human must request, review and accept a firm quote. Estimates exclude route-specific extras.");
    }
}

def rank_movers(profiles: list[dict], area: str, size: int, packing: bool, budget: int) -> dict {
    need = MoveNeed(area=area, size=size, packing=packing, budget=budget);
    for profile in profiles { need +>:EligibleRoute():+> MoverCandidate(profile=profile); }
    agent = need spawn MatchAgent();
    ranked = sorted(agent.candidates, key=lambda m: dict : float(str(m["score"])), reverse=True);
    result = {"matches": ranked, "trace": agent.trace};
    # Graph is request-scoped: no user inventory or PII is persisted in the graph.
    for candidate in [need-->] { del candidate; }
    del need;
    return result;
}
