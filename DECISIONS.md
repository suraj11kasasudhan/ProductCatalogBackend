# Backend decisions and tradeoffs

## Context and authorship

The author reports approximately four hours for the initial design and implementation of the iOS frontend and Node.js backend combined. All code was written using AI, including application code, tests, configuration and documentation. The author supplied requirements, design direction, local execution feedback and approval. The estimate is author-reported; it is not a measured agent runtime or proof that all subsequent deployment troubleshooting and review fit that window.

The backend lives in ProductCatalogBackend. Its original feature PR has been merged into main, while Render currently tracks feat/catalogue-backend. The UIKit frontend lives independently in ProductCatalogiOS. There is no React frontend in this repository.

## Small modules and dependency injection

Node 24, TypeScript, Express 5 and native async handlers keep the service small and the toolchain explicit. The lockfile reproduces dependencies. Shared Zod schemas validate the HTTP boundary; services implement business behavior; adapters own external HTTP/SMTP details.

ProductSource isolates the upstream catalogue. ProductLookup exposes only get(id) to the enquiry service, so an enquiry can be tested without constructing a catalogue or HTTP app. Mailer isolates delivery. The SMTP adapter accepts a transport, the product adapter accepts a fetcher and clock, and createApp accepts services plus an optional rate-limit Store. These seams are enough for the current scope; a DI container, ORM or generic repository layer would add setup without solving an observed problem.

## Fake Store to DummyJSON

Fake Store was originally required. Render requests received HTTP 403 with Cloudflare as provider, cf-mitigated: challenge, and HTML instead of JSON. The endpoint worked in the author's browser, and changing Render regions did not fix hosted access. That confirms a browser challenge on those requests; it does not identify the exact firewall rule or prove a global ban on a hosting provider.

The author explicitly approved switching to another free API. DummyJSON now supplies products, mapped to the same public DTO consumed by iOS. This is an intentional departure from the original Fake Store requirement and must be disclosed rather than hidden behind a fake fallback.

The adapter requests /products?limit=0 to obtain the full catalogue, validates shape/completeness/unique IDs, maps thumbnail to imageUrl and numeric rating to rating.value, and counts supplied reviews for rating.count. Provider changes also change product identities and categories. Five configured IDs remain the editorial selection.

## Catalogue behavior

Featured means exactly the configured five editorial IDs, in configuration order; it does not mean the five highest ratings. Missing IDs fail explicitly with 503. Category pages intersect that selection with their category and return remaining products separately without duplicates. A category can have no featured products.

Search is a literal case-insensitive substring within title or description separately, so phrases do not match only by spanning the field boundary. Category and search filters combine. Empty queries return the catalogue; unknown resources return 404. The numeric price is passed through without inventing currency metadata.

The five-second timeout bounds upstream latency. A short per-process cache and coalesced misses reduce calls. Invalid or partial catalogues never enter the cache. Expired cache entries are not served on error; there is no stale/demo fallback. Fetchers and clocks are injected so cache/failure tests remain deterministic.

## Enquiry correctness

The server verifies product existence and constructs the product title, sender, recipient and subject. Customer input is plain text; contact fields and body sizes are bounded. SMTP success requires acceptance of the configured sales address, including supported string/address-object transport response forms; an unrelated accepted address must not produce success.

Synchronous SMTP allows a truthful acceptance response but does not guarantee inbox delivery. There is no persistent enquiry record, queue, idempotency key or automatic retry. A response lost after SMTP acceptance can produce a duplicate on manual resubmission. A durable outbox and idempotency are next steps only when delivery guarantees are required.

## Scaling and hosting boundaries

The current configuration is a small single-process service, not a fully configured distributed system. The default limiter and product cache are process-local and reset on restart. createApp's optional enquiryStore allows a compatible shared store when multiple replicas are introduced, but no Redis service or distributed-store integration is installed or validated by this change.

Express leaves proxy trust disabled. A production deployment must configure trusted proxy hops/addresses for its actual topology before relying on per-client IP limits. Blanket trust can permit spoofed forwarding headers; leaving trust disabled behind a proxy can aggregate callers under a proxy IP. This must be an explicit deployment decision.

Render's free service can sleep and blocks standard SMTP ports 25, 465 and 587. Catalogue browsing succeeding does not establish production email delivery. Use supported hosting/provider settings, a verified sender and real recipient for email. DummyJSON and free hosting are demo dependencies, not an availability SLA.

## Validation and follow-ups

The suite covers source mapping/cache/failure behavior, API filtering and validation, injected product lookup and mailer, injected rate-limit store enforcement, safe error classification, and SMTP recipient correctness. Local fixture tests do not establish live provider uptime or external mailbox delivery. Mailpit smoke testing is separate and must be reported only when run.

The author confirmed the hosted catalogue returns data after the DummyJSON migration. Multi-replica infrastructure, durable enquiry handling, production SMTP, request-level observability without personal data, and container-digest pinning remain follow-ups. Test/build counts and commands are kept in README.md; check CI for the matching commit before claiming remote deployment readiness.
