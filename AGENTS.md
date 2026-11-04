# Working on ProductCatalogBackend

## Scope

- Keep changes focused, minimal and compatible with the API consumed by suraj11kasasudhan/ProductCatalogiOS. Preserve unrelated user files and existing work.
- This task has an isolated checkout. Use it; do not create a Git worktree unless explicitly requested.
- Read README.md, DECISIONS.md and AI_USAGE.md before changing architectural assumptions. Do not add frameworks, databases, queues or generic repositories without a concrete task need.
- main contains the merged backend. The Render deployment currently tracks feat/catalogue-backend; preserve history and keep requested publication targets clear. Do not force-push or reset unrelated changes.

## Module boundaries

- Routes validate HTTP input with routes/schemas.ts and call services. Keep vendor/network details in adapters.
- CatalogueService depends on ProductSource. EnquiryService depends on ProductLookup and Mailer. Prefer narrow structural contracts over concrete implementations at replaceable boundaries.
- Inject fetchers, clocks, SMTP transports and rate-limit stores for deterministic tests. Construct production dependencies in server.ts and keep createApp importable without starting a listener.
- Preserve cancellation/timeout behavior, public error envelopes, exactly-five featured selection, independent title/description search, and disjoint category groups.
- Keep SMTP sender, recipient and subject server-controlled. A success response requires the configured sales recipient to be accepted; never equate that with guaranteed inbox delivery.

## Providers and deployment

- The approved source is DummyJSON. Fake Store was replaced after Render requests received confirmed Cloudflare browser challenges, not because the iOS URL or CORS was wrong.
- PRODUCT_API_URL defaults to https://dummyjson.com; the adapter appends /products?limit=0. Validate complete catalogues before caching.
- Cache and default rate limits are process-local. Multi-replica deployments require an explicitly injected shared Store and reviewed proxy trust; do not claim these are already configured.
- No enquiry persistence or idempotency is implemented. Never introduce automatic POST retries or hide SMTP/provider failures with fake success responses.
- Keep TLS/checksum verification enabled. Never log secrets, contact details, raw upstream bodies, arbitrary error messages or credential-bearing URLs. Never commit .env values.

## Checks and documentation

- Use Node 24 and npm ci with the lockfile. Run npm run check and npm run build for code changes. Local HTTP tests need permission to bind localhost.
- For SMTP integration, use local Mailpit and npm run smoke. Distinguish automated fixture tests from live provider, mailbox or deployment checks.
- Format only changed files with the repository's Prettier. Check git diff --check and preserve source/configuration unrelated to the task.
- Report exact test outcomes and remaining limitations. Do not turn an unrun smoke/deployment check into a passing claim.
- Keep README.md, DECISIONS.md, AI_USAGE.md and this guidance consistent. Preserve the author's disclosure: all code was AI-written and the initial combined frontend/backend work took approximately four hours according to the author.
