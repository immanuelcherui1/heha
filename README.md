# Heha Movers

Heha Movers is a Jac full-stack marketplace foundation for connecting customers in Kenya with independent moving companies. The application supports customer and mover registration, pending mover profiles, administrator approval, move requests, quotations, booking coordination and deterministic graph-based matching and preparation assistance.

**This repository is not production-ready and does not claim live payment, settlement, contact verification, insured-company verification, GPS tracking, notifications, uploads, or password recovery.** No demo accounts, fictional companies, reviews, bookings or payment records are created automatically. An empty database is expected to produce an empty marketplace.

## Current capabilities and limits

- Jac client and server mounted on one application origin.
- Customer and mover registration with password hashing and expiring opaque sessions.
- Server-enforced role and ownership checks for existing marketplace operations.
- Mover profiles start unapproved; public browse and quote eligibility require administrator approval.
- Customer move requests, mover quotations, quote acceptance, booking status updates and booking conversations.
- Deterministic rule-based Jac graph agents for matching and move preparation. They do not use an LLM or make decisions on a customer's behalf.
- No public mover listings until genuine companies register and are explicitly approved.
- The payment operation is deliberately disabled. It creates no transaction record and makes no assertion that funds moved.

The existing schema and operations are an MVP foundation, not a complete fulfillment of the production requirements. In particular, registration does not verify email/phone ownership, admin provisioning and stronger admin authentication need a secure operator process, mover onboarding lacks private evidence-document handling and payment-provider onboarding, and booking availability/resource reservation is not implemented.

## Requirements and local development

Use Python 3.12 or later, Node.js 20 or later, Git, and a Jac installation compatible with the project. This workspace targets Jac 0.34.23. Install dependencies in the project environment:

```bash
python -m pip install -r requirements.txt
jac install
jac check main.jac
jac start --dev main.jac
```

Open the application URL printed by Jac. The client and API share the same origin. Do not use production data for development. The default local database path is `.jac/data/heha.sqlite3`; point `HEHA_DB` to a fresh isolated file for tests or a local environment. Protect this file and back it up; never commit database files, credentials, or session data.

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `HEHA_DB` | `.jac/data/heha.sqlite3` | Local SQLite database file. Use durable managed storage and a transactional production database before launch. |

There are no provider credentials configured in this project. Do not enable customer payments until a provider and its marketplace collection, settlement, reconciliation, refund, callback-authentication and commercial requirements have been confirmed. Supply secrets only through the deployment platform's secret manager or JacHammer Settings, never source control or chat.

The current SQLite initialization uses `CREATE TABLE IF NOT EXISTS`; a versioned schema migration framework, PostgreSQL adapter, operational backup schedule and tested restoration procedure remain outstanding. Do not point multiple production workers at a local SQLite file.

## Architecture

```text
Browser (Jac client) -- same-origin RPC --> Jac full-stack entry (main.jac)
                                             |
                                             +-- endpoints.sv.jac: validation, authentication and authorization
                                             +-- store.jac: SQLite persistence and password/session helpers
                                             +-- matching.jac: request-scoped Jac graph matching agent
                                             +-- planning.jac: request-scoped preparation graph agent
                                             +-- coordination.jac: booking conversation and checklist rules
                                             +-- frontend.cl.jac / frontend.impl.jac: client shell and handlers
```

`main.jac` registers the marketplace endpoint and mounts the client. `transport.cl.jac` performs uncached same-origin RPC. Persistence is currently SQLite-backed SQL; the Jac agent graphs are request-scoped and are not the durable marketplace database. Company records originate in registration, and public browse filters to approved records. Do not interpret a verification flag as proof of insurance or background checks.

## Testing

The existing tests in `tests/` were written for fictional seeded users and listings; they are obsolete for the no-fixture policy and are expected to fail without those fixtures. Do not restore production seeding to make them pass or run them against a live database. Replace them with isolated tests that create their own temporary database and cover genuine registration, pending-company visibility, admin authorization, quote acceptance concurrency, payment denial, ownership isolation and provider callback failure cases before using a suite as a release gate.

For a local code check:

```bash
jac check main.jac
```

For future automated tests, run against a newly created temporary database, never production. Integration staging must use official provider sandbox environments and isolated accounts. Browser validation should cover the empty marketplace, real registration, pending company status and permission-denied actions on both mobile and desktop.

## Environments and deployment

Maintain separate development, staging and production environments and distinct database instances, credentials, provider accounts, storage and logs. This repository does not include a deployment pipeline or cloud-specific deployment configuration. Deployment requirements depend on the selected host and are not verified here; do not treat a local preview or successful local build as evidence of external production readiness.

Before a production deployment, establish:

1. A supported hosting target and public HTTPS origin for UI and API, with health/readiness probes.
2. Managed PostgreSQL (or a documented equivalent), versioned migrations, durable private file storage, automated backups, and a restoration rehearsal.
3. Secure secret management, environment-specific configuration, session expiry/revocation, contact verification, account recovery, rate limiting, abuse protection and administrator MFA.
4. A secure first-administrator provisioning process; public registration must never create an administrator.
5. Real mover review policy and evidence handling with private, controlled document access and auditable decisions.
6. An approved Kenyan marketplace payment route and provider commercial approval. Implement authenticated webhooks, idempotency, amount verification, reconciliation, reversals, refunds and settlements before any paid status is shown. Keep booking, payment and settlement states separate. No escrow claim without an actual legal and commercial arrangement.
7. Background workers for retries/reconciliation, transactional notification providers, structured logs, error monitoring, alerting, and retention/deletion procedures.
8. Reviewed cancellation, service, privacy, dispute, damage and consumer-protection policies; applicable Kenya Data Protection Act and cross-border-processing review.
9. CI checks, migration tests, permission tests, realistic provider failure tests, mobile/accessibility checks, controlled rollout and an incident response procedure.

No cloud target, provider approval, external endpoint, operational monitoring or restoration test has been verified for this project. Obtain and configure provider credentials through secure settings only after provider approval. Keep payment capability disabled until then.

## Data integrity and launch prerequisites

Never load fabricated company profiles, user accounts, reviews, bookings or transaction records into production. Test fixtures, if added, must live in isolated test-only databases. Do not display review counts, insurance or background-check claims without source evidence. A published move request is an invitation to quote, not a confirmed booking. A browser action is never evidence of a successful external payment or notification.

Production launch remains blocked on the infrastructure, identity, company-evidence, provider, policy, security, monitoring, backup/restore and integration testing requirements above. This project makes no production-readiness claim.
