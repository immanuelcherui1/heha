# Heha Movers demo

## Three-minute narration

**0:00 — The problem.** Moving in Kenya often starts with scattered recommendations, unclear scope and prices, and little visibility after a booking. Heha is a marketplace connecting customers with independent moving companies.

**0:20 — Discover and explain.** Show the marketplace and sample mover cards. Enter Nairobi, two rooms, KES 20,000 and packing. Add “fridge, fragile mirror, third floor, no lift.” Run the Match Agent. Explain that Jac traverses candidate nodes, filters verification/capacity/packing, scores the remaining movers and presents reasons. Estimates are not firm quotes.

**0:45 — Plan the move.** Show the Move Planner's checklist and access/handling flags. It evaluates 17 explicit rules, shows evidence and keeps the final decision with the customer. It does not invent a route distance or insurance policy, and it needs no external model key.

**1:05 — Request and quote.** Sign in using Customer demo. Post a move to Ruaka with a future date and inventory notes. Save one checklist item. Sign out and use Mover demo. Find the request, enter KES 17,500 with clear inclusions and submit a quote.

**1:35 — Confirm and coordinate.** Return to the customer account, accept the quote and record the simulated 30% deposit. Point out “No money was charged.” Send an arrival/parking message. Return to the mover and reply. Only the booking customer and accepted mover can use this conversation.

**2:05 — Complete and review.** Mark pickup, then delivery as the mover. Return to the customer, leave a verified-booking review, expand history and reload. Booking data, messages, review and checklist progress persist in SQLite.

**2:30 — Marketplace trust.** Show Admin demo and verification controls. New movers remain pending and cannot quote. Editing a mover profile requires re-verification. A live service would need genuine identity, insurance and company checks; the sample demo is explicit about this boundary.

**2:50 — Close.** “Heha gives Kenya's independent movers a clearer route to customers, and customers a calmer route to their next chapter. Built with Jac, with explainable graph agents and human approval.”

## Included recording

`heha-demo.mp4` is an actual automated browser walkthrough generated from the tested UI with Chromium CDP and FFmpeg. It has no voiceover; add the narration above or record a fresh presentation. It is not a hosted deployment or evidence of real payment processing.

## Reproduce the walkthrough

1. Install the development requirements, an OS Chromium executable, and system FFmpeg.
2. Start a fresh demo instance (`HEHA_DEMO=1`, a fresh `HEHA_DB` file).
3. Run `HEHA_RECORD=1 HEHA_SLOW_MO=180 jac run qa/browser_workflow.jac`.
4. Read the command's pass/fail output. The video is written under `.jac/qa/recording/heha-demo.mp4`, and numbered screenshots under `.jac/qa`.
5. Watch the output before using it in a submission. Re-record with narration if your team wants a polished presentation.

The automated scenario uses the public sample accounts. It creates one completed booking per successful run and retains its audit history. Use an isolated demo database, never a live customer database. Cross-account changes are visible after the Refresh button; there is no claim of WebSocket/push updates.
