# AI authorship and development process

All code for the backend and iOS frontend was written using AI. OpenAI Codex generated application code, contracts, tests, configuration, documentation, and subsequent refactors. The project author supplied requirements and decisions, ran local/browser/simulator checks, shared screenshots and Render logs, and approved publication. No parallel agents were used in this session.

The author reports approximately four hours for the initial frontend/backend design and implementation combined. This is an author-provided estimate, not a measured time log, and does not imply that all later troubleshooting, revisions, or verification occurred within the same period.

## Decisions shaped by the author

- A small Node/TypeScript backend with replaceable product and mail adapters, and a separate UIKit/MVVM iOS client.
- Exactly five editorial products, category groups, search, complete details and an enquiry form.
- Truthful email confirmation after SMTP acceptance, with Mailpit for local inspection and no hidden demo fallback.
- A live Render deployment and a disclosed switch from Fake Store to DummyJSON after logs confirmed Cloudflare browser challenges on hosted requests.
- Focused refactors and explicit constructor injection rather than broad frameworks or speculative infrastructure.

## Review and corrections

Reviews corrected body-parser versus internal error classification, independent title/description matching, cancellation handling on iOS, and SMTP recipient checks. A regression test reproduced the adapter incorrectly accepting an unrelated recipient before the fix. The enquiry service now accepts a narrow ProductLookup contract, and the application accepts an optional rate-limit Store; no shared store is deployed by default.

Tests use injected fetchers, clocks, lookups, mailers, SMTP transports and stores. API tests run against local fixtures, not live providers. TypeScript checks include tests and smoke scripts. SMTP smoke verification requires Mailpit and is distinct from the automated suite. Prior Docker/Mailpit results do not establish that every later change has been tested against an external mailbox or new deployment.

AGENTS.md records maintenance guidance. DECISIONS.md records rationale and scope limits. Human review and ownership remain required for all AI-written work; documented test counts are not a substitute for a passing run on the matching commit.
