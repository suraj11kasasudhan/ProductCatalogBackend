# Decisions and assumptions

## Scope and choices

- Implement the requested Node.js backend; a React TypeScript client is the intended next component. The frontend acceptance criteria are not fully satisfied by APIs alone.
- Use Node 24, TypeScript and Express 5: a small service with async error handling, strict types and minimal framework machinery. The lockfile makes installation repeatable.
- Use interfaces only at expected replacement points: product source and mail provider. Fake Store schema mapping is isolated from the HTTP contract. A database-backed source can implement `ProductSource`; another provider can implement `Mailer`.
- No database, authentication, admin UI, payment, queues or cloud deployment in this iteration. None is needed to demonstrate the requested backend path. This keeps setup small and avoids paid accounts.

## Acceptance-criteria assumptions

- “I have chosen 5 products” means editorial selection, rather than the five highest numerical ratings. `FEATURED_PRODUCT_IDS` is the selection. Source ratings are still returned for display.
- Default selected IDs are 1–5. Selection order is preserved. If any selected ID disappears, featured endpoints fail explicitly instead of silently returning fewer than five; a category grouping also reports the invalid selection.
- Category featured products are the intersection of that global selection and the category. Remaining products are returned separately, with no duplicates. Some categories can have zero featured items.
- Search uses literal, case-insensitive substring matching in title/description. Empty input returns all products. Category and search filters combine.
- Contact means name and email, with optional phone and a required message. The submitted product must exist. No enquiry history or customer accounts are retained.
- A successful enquiry means SMTP accepted the sales recipient. It does not guarantee inbox placement. Mailpit is the local sales inbox and needs no external account.
- Product price is passed through as a numeric source amount. Currency localization is deferred; no currency information is invented.

## Reliability and trade-offs

A five-second product timeout bounds upstream latency. Responses are schema-validated before caching for 60 seconds. Concurrent cache misses share a request. The process cache is intentionally small because the source catalogue is small. There is no hidden demo fallback or stale-on-error mode.

Email is sent synchronously for a truthful confirmation. An SMTP failure returns 502. There is no queue or durable record, so a lost response followed by a retry can duplicate email. Persisted enquiries, idempotency keys and an outbox are appropriate next steps once durability is required.

Basic validation, fixed recipients, plain-text email, body limits and per-IP limits address the immediate public-form risks. Rate limits are per process and reset on restart. Proxy trust and a distributed rate-limit store must be set deliberately for production deployment. These are not a replacement for abuse monitoring.

## Another day

1. Build the React client: home, category, search, detail and enquiry states, including accessible errors and retry behavior.
2. Run the live product-source smoke check after cloud allowlist activation and add a browser critical-path test.
3. Add durable enquiries and idempotent submission if the entrepreneur needs delivery guarantees.
4. Add structured request identifiers/metrics without logging customer contact data; configure production SMTP and verified delivery.
5. Pin container digests and add deployment configuration when the target AWS service is chosen. CI now checks formatting, types, tests and build.

## Validation limitations

The current cloud policy blocks Fake Store API. Local HTTP fixtures validate the actual source adapter, while deterministic tests cover failure handling. The Docker backend and Mailpit work locally, but live catalogue access still needs the saved allowlist change applied. No external sales mailbox has been configured or tested.

## Refactor review

- Centralized request schemas and named enquiry input/contact contracts to keep HTTP validation and service boundaries readable.
- Added a small injectable SMTP transport boundary to test recipient rejection and server-controlled email headers directly. DNS now has an explicit timeout.
- Corrected error classification: internal SyntaxErrors return 500; malformed JSON returns 400; unsupported body encoding/charset returns 415. Already-started responses delegate to Express.
- Search checks title and description independently so a phrase cannot match only by spanning the boundary between fields.
- TypeScript checks now include tests and the smoke script. Prettier and GitHub Actions enforce the same development checks.
- Retained the existing product-source/mail-provider architecture; a larger dependency-injection framework or database is not required for this scope.
