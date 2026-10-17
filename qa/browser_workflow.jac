"""Real-browser marketplace acceptance scenario, implemented in Jac.

Start the application first. Then run:
  jac run qa/browser_workflow.jac
Optional: HEHA_URL, HEHA_CHROMIUM, HEHA_ARTIFACT_DIR, HEHA_SLOW_MO.
This creates one demo booking and leaves its completed audit trail intact.
"""
import os;
import secrets;
import from pathlib { Path }
import from datetime { date, timedelta }
import from playwright.sync_api { sync_playwright }

def sign_in(page: any, account: str) {
    signout = page.get_by_role("button", name="Sign out", exact=True);
    if signout.count() > 0 { signout.click(); }
    page.get_by_role("button", name="Log in", exact=True).first.click();
    page.get_by_role("button", name=account.capitalize() + " demo", exact=False).click();
    page.get_by_role("button", name="Refresh", exact=False).wait_for();
}

def booking_card(page: any, marker: str) -> any {
    card = page.locator(".booking-card").filter(has_text=marker);
    card.wait_for();
    return card;
}

def snapshot(page: any, destination: str, name: str) {
    page.screenshot(path=destination + "/" + name + ".png", full_page=True);
}

with entry:__main__ {
    base = os.getenv("HEHA_URL", "http://127.0.0.1:8000");
    destination = os.getenv("HEHA_ARTIFACT_DIR", ".jac/qa");
    Path(destination).mkdir(parents=True, exist_ok=True);
    marker = "Browser acceptance " + secrets.token_hex(4);
    engine = sync_playwright().start();
    browser = engine.chromium.launch(executable_path=os.getenv("HEHA_CHROMIUM", "/usr/bin/chromium"), headless=True, args=["--no-sandbox"], slow_mo=int(os.getenv("HEHA_SLOW_MO", "0")));
    context = browser.new_context(viewport={"width": 1440, "height": 1050});
    page = context.new_page(); page.set_default_timeout(15000);
    errors: list[str] = [];
    page.on("pageerror", lambda exc: any { errors.append(str(exc)); });
    try {
        page.goto(base, wait_until="networkidle");
        page.get_by_role("heading", name="New beginnings.", exact=False).wait_for();
        assert page.locator(".mover-card").count() >= 6;
        snapshot(page, destination, "01-marketplace");
        print("PASS: marketplace loads verified demo partners");

        page.get_by_label("Planning notes", exact=True).fill("Fridge, fragile mirror, third floor with no lift");
        page.get_by_role("button", name="Find my movers", exact=False).click();
        page.get_by_text("Here’s how your shortlist was made", exact=True).wait_for();
        page.get_by_role("heading", name="A calmer move starts with a plan.", exact=True).wait_for();
        assert page.locator(".mover-card").count() > 0;
        assert page.get_by_text("Clarify stairs and manual handling charges", exact=True).count() > 0;
        snapshot(page, destination, "02-agent-plan");
        print("PASS: graph matching and evidence-based preparation plan");

        sign_in(page, "customer");
        page.get_by_role("heading", name="Your next chapter, organised.", exact=True).wait_for();
        page.get_by_role("button", name="New moving request", exact=False).click();
        page.get_by_label("Pickup location", exact=True).fill("Kilimani, Nairobi");
        page.get_by_label("Destination", exact=True).fill("Ruaka, Kiambu");
        page.get_by_label("Moving date", exact=True).fill((date.today() + timedelta(days=14)).isoformat());
        page.get_by_label("Inventory notes", exact=True).fill(marker + ". Fridge, glass table, sofa, 12 boxes. Third floor, no lift.");
        page.get_by_role("button", name="Request quotes", exact=False).click();
        page.get_by_role("status").filter(has_text="Your move is live.").wait_for();
        card = booking_card(page, marker);
        assert card.locator(".status").first.text_content().strip() == "requested";
        card.get_by_role("button", name="My move plan", exact=False).click();
        card.get_by_label("Make a room-by-room inventory", exact=True).click();
        page.get_by_role("status").filter(has_text="Saved successfully").wait_for();
        assert card.get_by_label("Make a room-by-room inventory", exact=True).is_checked();
        snapshot(page, destination, "03-customer-request");
        print("PASS: customer posts move and saves preparation checklist");

        sign_in(page, "mover");
        card = booking_card(page, marker);
        card.get_by_label("Quote amount", exact=True).fill("17500");
        card.get_by_label("Quote inclusions", exact=True).fill("Transport, packing, two crew members, loading and unloading included.");
        card.get_by_role("button", name="Submit quote", exact=False).click();
        card.get_by_text("KES 17500", exact=True).wait_for();
        snapshot(page, destination, "04-mover-quote");
        print("PASS: verified mover submits a firm quote");

        sign_in(page, "customer");
        card = booking_card(page, marker);
        card.get_by_role("button", name="Accept quote", exact=True).click();
        card.locator(".status-confirmed").wait_for();
        card.get_by_role("button", name="Record demo 30% deposit", exact=True).click();
        card.get_by_text("Simulation only. No money was charged.", exact=True).wait_for();
        card.get_by_label("Booking message", exact=True).fill("Please arrive at 8 AM. Parking is arranged.");
        card.get_by_role("button", name="Send message", exact=False).click();
        card.get_by_text("Please arrive at 8 AM. Parking is arranged.", exact=True).wait_for();
        snapshot(page, destination, "05-confirmed-deposit");
        print("PASS: quote accepted, simulated deposit recorded, private message sent");

        sign_in(page, "mover");
        card = booking_card(page, marker);
        card.get_by_text("Please arrive at 8 AM. Parking is arranged.", exact=True).wait_for();
        card.get_by_label("Booking message", exact=True).fill("Confirmed. Your crew will arrive with wrapping materials.");
        card.get_by_role("button", name="Send message", exact=False).click();
        card.get_by_text("Confirmed. Your crew will arrive with wrapping materials.", exact=True).wait_for();
        card.get_by_role("button", name="Mark as picked up", exact=True).click();
        card.locator(".status-in_transit").wait_for();
        card.get_by_role("button", name="Confirm delivery", exact=True).click();
        card.locator(".status-completed").wait_for();
        print("PASS: assigned mover coordinates pickup and confirms delivery");

        sign_in(page, "customer");
        card = booking_card(page, marker);
        card.get_by_label("Review comment", exact=True).fill("Careful packing and a friendly crew. A smooth new beginning.");
        card.get_by_role("button", name="Publish review", exact=True).click();
        card.get_by_text("5/5 verified review", exact=False).wait_for();
        card.get_by_role("button", name="View history", exact=False).click();
        assert card.locator(".timeline li").count() == 7;
        snapshot(page, destination, "06-completed-review");
        page.reload(wait_until="networkidle");
        page.get_by_role("button", name="Dashboard", exact=True).click();
        card = booking_card(page, marker);
        card.get_by_text("5/5 verified review", exact=False).wait_for();
        card.get_by_role("button", name="My move plan", exact=False).click();
        assert card.get_by_label("Make a room-by-room inventory", exact=True).is_checked();
        print("PASS: completed booking, review, session and checklist survive reload");

        sign_in(page, "admin");
        page.get_by_role("heading", name="Moving partner verification", exact=True).wait_for();
        assert page.locator(".admin-row").count() >= 6;
        snapshot(page, destination, "07-admin-workspace");
        print("PASS: admin sees marketplace oversight and verification controls");

        mobile = browser.new_page(viewport={"width": 390, "height": 844});
        mobile.goto(base, wait_until="networkidle");
        mobile.get_by_role("heading", name="New beginnings.", exact=False).wait_for();
        assert mobile.evaluate("document.documentElement.scrollWidth <= window.innerWidth");
        snapshot(mobile, destination, "08-mobile-marketplace");
        mobile.close();
        assert len(errors) == 0, str(errors);
        print("PASS: mobile layout has no horizontal overflow; no browser runtime errors");
    } finally {
        context.close(); browser.close(); engine.stop();
    }
}
