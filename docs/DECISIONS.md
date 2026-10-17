# Implementation decisions and live-launch boundary

## Why Jac throughout

The guide asks for meaningful Jac use and at least 80% Jac code. Client components compile through jac-client, the server runs Jac RPC functions, and two mobile procedures traverse typed graphs. Tests and browser acceptance are also Jac. The application uses Python's standard library through Jac imports for SQLite, hashing, random session tokens, clocks and filesystem operations. There is no separately maintained Python or JavaScript application backend.

## Agent behavior

The matching agent observes a move need, traverses `EligibleRoute` edges into `MoverCandidate` nodes, rejects incompatible or unverified companies, scores candidates and explains its reasons. Score: rating × 10; local pickup-area match +25; when a budget is supplied, indicative estimate within budget +20, otherwise −10. The demo estimate is rate per room × rooms plus KES 2,500 for packing. It is a comparison heuristic, not a measured route estimate.

The planning agent traverses 17 rule nodes. It combines explicit requirements with keyword evidence to produce preparation tasks, access/safety questions, and a rough box guide. It can flag missing information and low indicative budgets. Simple keyword matching can miss context or match substrings; it is advisory and intentionally does not claim natural-language understanding, generative reasoning, or complete hazard detection.

Both agents are deterministic and keyless. No `by llm` call, LLM provider, or hidden paid service is presented as working. These graph agents recommend and explain; only authorized humans book, pay in the demo, or change job status.

## Storage and consistency

SQLite stores users, hashed expiring sessions, movers, requests, quotes, booking events, demo deposits, reviews, messages and checklist completion. Jac graph objects are built per request and cleaned up. Transactions use `BEGIN IMMEDIATE` to serialize decisions such as accepting competing quotes. A unique booking key prevents duplicate payment or review records. The message query enforces membership and does not expose private conversation text to competing movers or the admin dashboard.

The web client uses explicit uncached same-origin POSTs because SQL writes behind a dispatcher are not visible to Jac's automatic reader/writer cache classifier. Data is refetched after each mutation; “Saved successfully” appears after that refresh. Refresh is manual across different signed-in browser sessions.

## Authentication boundary

Public account registration can create only customers or movers. Admin registration is not offered. Passwords use salted PBKDF2-SHA256 (210,000 iterations); opaque random sessions have 24-hour expiry and are stored as hashes in SQLite. The browser stores its token in sessionStorage, which is still readable by scripts on the origin. Use HTTPS and stronger session delivery/rotation before deployment with real data. The app's accounts are independent of Jac's built-in `/user` endpoints.

New movers are pending. Admin approval is required for quotes, and profile edits clear verification. Customers may accept only a quote on their own open request, from a currently verified mover. Only the chosen mover can progress a job. Only the owner of a completed request can review it. Reviews and simulated payments are unique per booking. The tests exercise both successful paths and forbidden operations.

## Run or host a demonstration

A host needs Python 3.12+, the pinned Jac packages, client build dependencies and a writable persistent disk. Build the client, then run `jac start main.jac --port 8000`; use a process supervisor and an HTTPS reverse proxy when exposing it. Back up the SQLite database, and keep the database path outside disposable build artifacts if the host replaces those on release. Only one application instance against local SQLite is the supported MVP deployment.

A cloud snapshot retains files, not server processes. Restart Jac in a new task. Keep the checkout in its existing isolated workspace; do not create a worktree for routine startup. A production client rebuild also needs a server restart to refresh the loaded bundle.

The application has been run and validated in the development cloud environment. Jac Hammer is encouraged by the guide, but no Hammer deployment has been performed or verified. Do not advertise a hosted URL until a deployment and external smoke check succeed.

## Before real customers or real money

- Use a fresh database with `HEHA_DEMO=0`; this flag does not delete seeded accounts. Provision an initial admin through a reviewed administrative process.
- Add login/registration throttling, bot/abuse controls, email verification, password reset, session revocation/rotation and explicit account deletion.
- Review HTTPS/session security, input size limits at the HTTP boundary, logging, dependency advisories and backups. Review Kenya data-protection obligations and document retention rules.
- Integrate M-Pesa using verified callbacks, idempotency keys, reconciliation and securely managed credentials. Define marketplace fees, mover settlement, cancellation/refund policy and dispute handling before collecting funds.
- Vet actual businesses, insurance and crew details. Do not present the demo verification toggle as a real-world background check.
- Add accepted quote expiry, date/crew availability, customer support/disputes, delivery proof and customer confirmation of completion. The MVP lets the assigned mover mark completion and does not perform availability locking.
- Add real route/distance estimates, licensed mapping, SMS/email and uploads only with consent and suitable privacy controls. The MVP does not upload documents or track GPS.

These are live-launch requirements, not claims of completed MVP integrations. The hackathon build is a functioning demonstration of marketplace coordination.
