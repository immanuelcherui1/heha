# Heha Movers — written submission

## Description

Heha Movers is a Kenyan moving-services marketplace that makes relocation easier to compare and coordinate. A customer describes a move; independent moving companies provide firm quotes; the customer chooses a crew and follows the job through pickup and delivery. The same application supports customer preparation, private booking communication, a clearly simulated deposit and verified-booking reviews. Admins oversee bookings and verify moving partners.

## The problem and impact

Moving decisions often happen across scattered calls and messages. Customers struggle to compare scope and price, while smaller moving companies lack a consistent channel for discovering relevant jobs. Heha creates one shared workflow with explicit requirements, competing quotations and a visible job history. Its initial market is Kenyan household moves, with a later opportunity for student relocations and small-business moves.

## Meaningful use of Jac and Jaseci tooling

The application was scaffolded with the official Jac fullstack template and built using Jaclang and jac-client. Both server logic and reactive client screens are Jac. The matching agent is a Jac walker moving from a `MoveNeed` node over `EligibleRoute` edges to mover nodes. It filters constraints, ranks viable options and explains each result. The planning agent traverses requirement-rule nodes to generate a preparation checklist and evidence-based risk questions. Domain and browser acceptance tests are also Jac.

The agents are deterministic and rule-based; no unconfigured model API is misrepresented as working. SQLite supplies transactional persistence while graphs supply request-scoped planning/recommendation behavior. This hybrid approach keeps the demonstration reliable without external API keys.

## Working MVP demonstration

The automated browser scenario executes the complete workflow: discover → graph matching → preparation plan → customer request → saved checklist → mover quote → quote acceptance → simulated deposit → private two-way messages → pickup → delivery → review → reload persistence → admin oversight → mobile check. Eight Jac domain tests cover lifecycle and forbidden operations. The source-byte audit includes CSS and development/test code in its denominator and is available in `source-audit.json`.

## Limits and future work

The sample companies, ratings and accounts are fictional demo fixtures. Payments are simulated. Live M-Pesa, map routing/GPS, insurance verification, uploads and notifications are not integrated. A real launch requires secure admin provisioning, real mover vetting, abuse controls, identity/session hardening, privacy/retention controls and payment/dispute operations. Hosting on Jac Hammer has not been performed.

## Submission checklist from the attached guide

- [x] Repository: https://github.com/immanuelcherui1/heha
- [x] Fullstack software meaningfully built in Jac
- [x] Local source-byte audit at or above 80% Jac, with method disclosed
- [x] Automated browser walkthrough and reproducible recording script
- [x] Pitch deck and written project description
- [ ] Team confirms every member registered and checked in
- [ ] Team confirms all coding occurred within the event window and team has at most four people
- [ ] Team stars https://github.com/jaseci-labs/jac
- [ ] Team reviews the video and optionally records narration
- [ ] Optional: host and verify on Jac Hammer
- [ ] Team submits the repository, video, deck and description through the actual shared submission link/Devpost before the live deadline

The guide lists **Saturday 17 October 2026 at 3:30 PM, Africa/Nairobi** for submission. Confirm any organiser updates. Registration, starring and submission are personal/external actions and have not been performed by the coding assistant. No prize eligibility or submission acceptance is implied.
