# Validation record

Validated in the development cloud environment on 17 October 2026 (Africa/Nairobi).

| Check | Result |
| --- | --- |
| Fresh project virtual environment from `requirements-dev.txt` | Installed successfully |
| `jac install` in the checkout | Installed client dependencies; repeated installation reported no changes |
| `make build` | Production client bundle built successfully |
| `make check` | All 11 application Jac files passed; nonblocking compiler warnings remain |
| Jac checks for browser workflow, recorder and source audit | All three passed |
| `make test` | Eight Jac tests passed across two files (3 + 5); isolated temporary SQLite database |
| Chromium browser acceptance | Full customer/mover/admin scenario passed; no browser runtime errors |
| Saved data after browser reload | Completed booking, review and checklist retained; session restored |
| Mobile 390 × 844 | Rendered successfully with no horizontal overflow |
| Source audit | Passed local 80% Jac threshold; exact count in `source-audit.json` |
| Pitch deck export | Eight-page PDF generated and a representative rendered slide visually inspected |
| Browser screencast | Actual interactions recorded through Chromium CDP and encoded to H.264 MP4 |

Browser acceptance verifies these operations through the rendered UI: public mover listing, graph shortlist and planning evidence, customer request, saved checklist, mover quotation, customer acceptance, simulated deposit, private customer/mover messages, pickup/delivery progression, completed-booking review, history, session/checklist persistence, admin oversight and mobile layout.

The domain tests separately exercise rejected role changes, unauthorized mutations, competing acceptance, duplicate deposits, cancelled booking rules, session revocation through logout, private conversation membership and mover verification gates. No test assertions are disabled, and no empty test run is reported as passing.

This is current-instance evidence. External hosting, a fresh cloud-task restoration, Jac Hammer publication, real M-Pesa, real notifications/maps, real mover verification and hackathon submission are not verified or claimed.
