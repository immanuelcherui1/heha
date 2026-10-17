"""Transparent moving-plan output; human-readable evidence and editable checklist."""
def:pub MovePlan(plan: dict, completed: list[str], onToggle: Callable[[str], any], editable: bool = False, busy: bool = False) -> JsxElement {
    has showEvidence: bool = False;
    tasks = plan["tasks"] as list[dict]; risks = plan["risks"] as list[dict];
    evidence = plan["evidence"] as list[str];
    return <section className="move-plan">
        <div className="section-heading compact"><div><span className="eyebrow">HEHA MOVE PLANNER</span><h2>A calmer move starts with a plan.</h2></div><span className="small muted">{len(completed)} / {len(tasks)} prepared</span></div>
        <p className="small muted">Planning guide: {plan["box_range"]} boxes. {plan["box_note"]}</p>
        <div className="planning-grid"><div><h4>Your preparation checklist</h4><ul className="plan-tasks">{[<li key={task["code"]} className={"task-done" if task["code"] in completed else ""}><label className="check-label"><input type="checkbox" checked={task["code"] in completed} disabled={not editable or busy} onChange={lambda { onToggle(str(task["code"])); }}/><span>{task["title"]}</span></label><p>{task["description"]}</p><small>{task["reason"]}</small></li> for task in tasks]}</ul>{not editable and <p className="small muted">Post a moving request to save your checklist progress.</p>}</div><div><h4>Clarify before moving day</h4>{[<article className="plan-risk" key={risk["code"]}><span className="status status-in_transit">{risk["priority"]} priority</span><strong>{risk["title"]}</strong><p>{risk["description"]}</p><small>{risk["reason"]}</small></article> for risk in risks]}{len(risks) == 0 and <p className="small muted">No extra flags from these notes. Confirm the final inventory and access with your mover.</p>}<div className="plan-disclaimer">Advisory planning only. Your mover confirms access, insurance, route and final price.</div></div></div>
        <button className="btn btn-ghost btn-small" onClick={lambda { showEvidence = not showEvidence; }}>{"Hide reasoning ↑" if showEvidence else "Show planner reasoning ↓"}</button>{showEvidence and <ol className="plan-evidence">{[<li key={line}>{line}</li> for line in evidence]}</ol>}
    </section>;
}
