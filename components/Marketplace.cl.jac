"""Shared presentation and booking interactions, written in Jac."""
import from .MovePlan { MovePlan }
def:pub money(amount: any) -> str { return "KES " + str(amount); }

def:pub MoverCard(mover: dict, index: int, matched: bool = False) -> JsxElement {
    return <article className="mover-card">
        <div className={"mover-art art-" + str(index % 4)}>
            <svg viewBox="0 0 260 150" aria-hidden="true"><circle cx="208" cy="35" r="40" fill="currentColor" opacity=".1"/><path d="M30 107h200" stroke="currentColor" opacity=".2"/><rect x="49" y="47" width="104" height="55" rx="5" fill="currentColor" opacity=".8"/><path d="M156 67h32l24 23v12h-56z" fill="currentColor" opacity=".5"/><path d="M166 74h18l15 15h-33z" fill="#fff" opacity=".7"/><circle cx="77" cy="104" r="13" fill="#203f34"/><circle cx="185" cy="104" r="13" fill="#203f34"/><circle cx="77" cy="104" r="5" fill="#fff"/><circle cx="185" cy="104" r="5" fill="#fff"/><path d="M88 62v24m-12-12h24" stroke="#fff" strokeWidth="4" opacity=".8"/></svg>
            <span className="verified">✓ Verified partner</span>
            {matched and <span className="match-score">{mover["score"]} fit score</span>}
        </div><div className="card-content">
            <div className="card-eyebrow"><span>{mover["area"]}, Kenya</span><span className="rating">★ {mover["rating"]}</span></div>
            <h3>{mover["name"]}</h3><p className="muted card-bio">{mover["bio"]}</p>
            <div className="tags">{[<span key={service}>{service.replace("-", " ")}</span> for service in str(mover["services"]).split(",")]}</div>
            {matched and <ul className="reasons">{[<li key={reason}>{reason}</li> for reason in mover["reasons"]]}</ul>}
            <div className="card-bottom"><div><small>{"Indicative total" if matched else "From / room"}</small><strong>{money(mover["estimate"] if matched else mover["rate"])}</strong></div><span className="small muted">{mover["jobs"]} moves · {mover["capacity"]} rooms max</span></div>
        </div></article>;
}

def:pub BookingCard(booking: dict, role: str, onAction: Callable[[str, dict], any], busy: bool) -> JsxElement {
    has amount: str = "15000", quoteMessage: str = "Transport, loading and unloading included.", rating: str = "5", comment: str = "", expanded: bool = False, planOpen: bool = False, messageBody: str = "";
    quotes = booking["quotes"] as list[dict]; events = booking["events"] as list[dict];
    payment = booking["payment"] as list[dict]; review = booking["review"] as list[dict];
    status = str(booking["status"]); bid = str(booking["id"]);
    messages = booking["messages"] as list[dict];
    async def act(action: str, extra: dict) { await onAction(action, {"booking_id": bid, **extra}); }
    return <article className="booking-card">
        <div className="booking-top"><span className={"status status-" + status}>{status.replace("_", " ")}</span><small className="muted">#{bid[:6]}</small></div>
        <div className="booking-route"><div><small>PICKUP</small><h3>{booking["pickup"]}</h3></div><span className="route-arrow">↗</span><div><small>DESTINATION</small><h3>{booking["destination"]}</h3></div></div>
        <div className="booking-meta"><span>▦ {booking["move_date"]}</span><span>⌂ {booking["size"]} room(s)</span><span>{"Packing required" if booking["packing"] else "No packing"}</span><span>Budget {money(booking["budget"])}</span></div>
        {booking["notes"] and <p className="booking-notes">{booking["notes"]}</p>}
        {role != "customer" and <p className="small muted">Requested by {booking["customer_name"]}</p>}
        {role == "mover" and status == "requested" and <div className="quote-composer"><h4>Send a firm quote</h4><div className="form-grid"><label>Total price (KES)<input aria-label="Quote amount" type="number" min="1000" value={amount} onChange={lambda e: ChangeEvent { amount = e.target.value; }}/></label><label>What is included?<input aria-label="Quote inclusions" value={quoteMessage} onChange={lambda e: ChangeEvent { quoteMessage = e.target.value; }}/></label></div><button className="btn btn-dark" disabled={busy} onClick={lambda { act("quote", {"amount": amount, "message": quoteMessage}); }}>Submit quote ↗</button></div>}
        {len(quotes) > 0 and <div className="quotes"><h4>{"Your quote" if role == "mover" else "Mover quotations"}</h4>{[<div className="quote-row" key={q["id"]}><div><strong>{q["mover_name"]}</strong><p className="small muted">{q["message"]}</p><span className="small">{q["status"]}</span></div><div className="quote-price"><strong>{money(q["amount"])}</strong>{role == "customer" and status == "requested" and <button className="btn btn-small" disabled={busy} onClick={lambda { act("accept", {"quote_id": q["id"]}); }}>Accept quote</button>}</div></div> for q in quotes]}</div>}
        {role == "customer" and status == "requested" and len(quotes) == 0 and <div className="empty-inline">Your request is live. Verified movers can now send you quotes.</div>}
        <div className="booking-actions">
            {role == "customer" and status == "confirmed" and len(payment) == 0 and <button className="btn btn-dark" disabled={busy} onClick={lambda { act("pay", {}); }}>Record demo 30% deposit</button>}
            {role == "mover" and status in ["confirmed", "in_transit"] and len([q for q in quotes if q["status"] == "accepted"]) > 0 and <button className="btn btn-dark" disabled={busy} onClick={lambda { act("progress", {}); }}>{"Mark as picked up" if status == "confirmed" else "Confirm delivery"}</button>}
            {role == "customer" and status in ["requested", "confirmed"] and <button className="btn btn-ghost danger" disabled={busy} onClick={lambda { if window.confirm("Cancel this moving request?") { act("cancel", {}); } }}>Cancel request</button>}
            <button className="btn btn-ghost" onClick={lambda { expanded = not expanded; }}>{"Hide history ↑" if expanded else "View history ↓"}</button>
            {role == "customer" and <button className="btn btn-ghost" onClick={lambda { planOpen = not planOpen; }}>{"Hide move plan ↑" if planOpen else "My move plan ↓"}</button>}
        </div>
        {len(payment) > 0 and <p className="payment-note">✓ Demo deposit: {money(payment[0]["amount"])} · {payment[0]["reference"]}<br/><small>Simulation only. No money was charged.</small></p>}
        {role == "customer" and status == "completed" and len(review) == 0 and <div className="quote-composer"><h4>How was your move?</h4><div className="form-grid"><label>Rating<select aria-label="Review rating" value={rating} onChange={lambda e: ChangeEvent { rating = e.target.value; }}><option value="5">5 — Excellent</option><option value="4">4 — Good</option><option value="3">3 — Okay</option><option value="2">2 — Poor</option><option value="1">1 — Very poor</option></select></label><label>Your review<input aria-label="Review comment" value={comment} onChange={lambda e: ChangeEvent { comment = e.target.value; }} maxLength={500}/></label></div><button className="btn" disabled={busy} onClick={lambda { act("review", {"rating": rating, "comment": comment}); }}>Publish review</button></div>}
        {len(review) > 0 and <p className="payment-note">★ {review[0]["rating"]}/5 verified review · {review[0]["comment"]}</p>}
        {expanded and <ol className="timeline">{[<li key={evt["id"]}><strong>{evt["actor"]}</strong><span>{evt["message"]}</span></li> for evt in events]}</ol>}
        {planOpen and role == "customer" and <MovePlan plan={booking["plan"] as dict} completed={booking["checklist"] as list[str]} onToggle={lambda code: str { act("checklist", {"code": code}); }} editable={status != "cancelled"} busy={busy}/>}
        {role != "admin" and status in ["confirmed", "in_transit", "completed"] and (role == "customer" or len([q for q in quotes if q["status"] == "accepted"]) > 0) and <section className="booking-messages"><h4>Coordinate with your {"mover" if role == "customer" else "customer"}</h4><p className="small muted">Private to this customer and the assigned moving company. Refresh to check for new messages.</p><div className="message-list">{[<article key={msg["id"]} className={"message-bubble own-message" if msg["author_role"] == role else "message-bubble"}><strong>{msg["author_name"]}</strong><p>{msg["body"]}</p></article> for msg in messages]}</div><label>Booking message<textarea aria-label="Booking message" maxLength={1000} value={messageBody} placeholder="Confirm arrival time, parking or access details…" onChange={lambda e: ChangeEvent { messageBody = e.target.value; }}/></label><button className="btn btn-outline btn-small" disabled={busy or not messageBody.strip()} onClick={lambda { act("message", {"body": messageBody}); messageBody = ""; }}>Send message ↗</button></section>}
    </article>;
}
