"""An explainable relocation planning agent with no external model dependency.

Each move becomes a graph of requirements. The walker evaluates each rule,
records evidence, and produces a preparation plan. This deliberately avoids
claiming to infer an exact distance, volume, insurance cover, or firm price.
"""
import re;

node PlanningContext {
    has inventory: str, rooms: int, packing: bool, budget: int;
}
node PlanningRule {
    has code: str, title: str, description: str, keywords: list[str];
    has priority: str = "normal", category: str = "preparation";
}
edge NeedsEvaluation { has phase: str = "observe"; }

walker MovePlanner {
    has inventory: str = "", rooms: int = 1, packing: bool = False, budget: int = 0;
    has tasks: list[dict] = [], risks: list[dict] = [], evidence: list[str] = [];
    has detected: list[str] = [], evaluated: int = 0;

    can observe with PlanningContext entry {
        self.inventory = here.inventory.lower();
        self.rooms = here.rooms;
        self.packing = here.packing;
        self.budget = here.budget;
        self.evidence.append("Read the inventory/access notes and declared household requirements.");
        visit [->:NeedsEvaluation:->];
    }

    can reason with PlanningRule entry {
        self.evaluated += 1;
        hits = [word for word in here.keywords if word in self.inventory];
        triggered = len(hits) > 0;
        if here.code == "inventory" { triggered = True; }
        if here.code == "access" { triggered = True; }
        if here.code == "utilities" { triggered = True; }
        if here.code == "packing" { triggered = self.packing; }
        if here.code == "self_pack" { triggered = not self.packing; }
        if here.code == "large_home" { triggered = self.rooms >= 4; }
        if here.code == "budget" { triggered = self.budget < self.rooms * 4500; }
        if here.code == "missing_notes" { triggered = len(self.inventory.strip()) < 15; }
        if not triggered { skip; }
        reason = "Detected: " + ", ".join(hits) if len(hits) > 0 else "Based on your declared moving requirements";
        item = {"code": here.code, "title": here.title, "description": here.description,
                "priority": here.priority, "category": here.category, "reason": reason};
        if here.category == "risk" { self.risks.append(item); }
        else { self.tasks.append(item); }
        for hit in hits {
            if hit not in self.detected { self.detected.append(hit); }
        }
    }

    can summarize with PlanningContext exit {
        self.evidence.append(f"Evaluated {self.evaluated} planning rules against the supplied notes.");
        self.evidence.append(f"Produced {len(self.tasks)} preparation tasks and {len(self.risks)} items to clarify with your mover.");
        self.evidence.append("The plan is advisory. A mover must inspect access, inventory and route before confirming scope.");
    }
}

def rules() -> list[PlanningRule] {
    return [
        PlanningRule(code="inventory", title="Make a room-by-room inventory", description="List large furniture, appliances and labelled boxes. Photograph valuable items before packing.", keywords=[]),
        PlanningRule(code="access", title="Confirm access at both properties", description="Share floor numbers, lift dimensions, loading space, gate restrictions and access hours with the mover.", keywords=[]),
        PlanningRule(code="utilities", title="Prepare your change-of-address checklist", description="Notify utilities and internet providers, arrange key handover and keep your first-night essentials separate.", keywords=[]),
        PlanningRule(code="packing", title="Agree on packing materials and responsibility", description="Ask whether cartons, reusable crates, wrapping and unpacking are included in the firm quote.", keywords=[], priority="high"),
        PlanningRule(code="self_pack", title="Pack and label before the crew arrives", description="Use sturdy boxes, keep heavy items in smaller cartons and label each box with its destination room.", keywords=[]),
        PlanningRule(code="fragile", title="Declare fragile belongings", description="Request protective wrapping and a handling plan for glass, mirrors, screens and breakable items. Confirm liability in writing.", keywords=["glass", "mirror", "tv", "television", "fragile", "artwork", "ceramic"], priority="high"),
        PlanningRule(code="appliances", title="Prepare appliances safely", description="Defrost and dry the fridge ahead of time. Ask a qualified person to disconnect gas, water and electrical fittings where needed.", keywords=["fridge", "freezer", "washing", "dishwasher", "cooker", "appliance"], priority="high"),
        PlanningRule(code="assembly", title="Confirm furniture disassembly", description="Check whether beds, wardrobes and large tables need dismantling, and whether reassembly and tools are included.", keywords=["bed", "wardrobe", "table", "desk", "bunk"], priority="normal"),
        PlanningRule(code="pets", title="Arrange a separate plan for pets", description="Keep animals away from loading activity and organise suitable transport, food, water and a quiet arrival space.", keywords=["pet", "dog", "cat", "kitten", "puppy"]),
        PlanningRule(code="plants", title="Prepare plants for transport", description="Ask whether the mover accepts plants. Stabilise pots and keep plants upright with suitable ventilation.", keywords=["plant", "flower", "garden"]),
        PlanningRule(code="documents", title="Keep documents and valuables with you", description="Carry identification, medication, cash, jewellery and important records personally rather than in the moving truck.", keywords=["document", "jewellery", "jewelry", "medicine", "medication", "passport"]),
        PlanningRule(code="stairs", title="Clarify stairs and manual handling charges", description="No lift or multiple floors may change crew size, time and price. Confirm the access surcharge before accepting a quote.", keywords=["stairs", "no lift", "no elevator", "third floor", "fourth floor", "5th floor"], category="risk", priority="high"),
        PlanningRule(code="heavy", title="Request a specialist handling assessment", description="Pianos, safes and unusually heavy items may need specialist equipment or a different crew. Do not rely on a standard room-based estimate.", keywords=["piano", "safe", "marble", "industrial", "heavy equipment"], category="risk", priority="high"),
        PlanningRule(code="storage", title="Confirm storage terms separately", description="Ask about storage location, access, duration, security, insurance and charges before agreeing to temporary storage.", keywords=["storage", "storehouse", "warehouse"], category="risk"),
        PlanningRule(code="large_home", title="Arrange a survey for a larger household", description="Room count alone does not measure volume. Request an inventory review or site survey to confirm vehicle capacity and crew requirements.", keywords=[], category="risk"),
        PlanningRule(code="budget", title="Your budget may need a scope discussion", description="Your budget is below the demo planning baseline for this household size. Compare firm quotes and discuss flexible dates or self-packing.", keywords=[], category="risk"),
        PlanningRule(code="missing_notes", title="Add inventory and access information", description="The notes contain little detail. List bulky items, fragile belongings and floor/lift access so movers can price the job accurately.", keywords=[], category="risk")
    ];
}

def build_plan(inventory: str, rooms: int, packing: bool, budget: int) -> dict {
    context = PlanningContext(inventory=inventory, rooms=rooms, packing=packing, budget=budget);
    for rule in rules() { context +>:NeedsEvaluation():+> rule; }
    agent = context spawn MovePlanner();
    # Box range is an explicit demo heuristic, not a volume survey.
    boxes_low = rooms * 8;
    boxes_high = rooms * 15;
    result = {"tasks": agent.tasks, "risks": agent.risks, "evidence": agent.evidence,
              "detected": agent.detected, "box_range": f"{boxes_low}–{boxes_high}",
              "box_note": "Rough planning guide: 8–15 boxes per declared room. Replace with your actual inventory.",
              "mode": "deterministic_graph", "rules_evaluated": agent.evaluated};
    for rule in [context-->] { del rule; }
    del context;
    return result;
}
