# Product Catalogue Backend

Node.js 24, TypeScript and Express 5 API for catalogue browsing, five curated featured products, category groups, search, details, and product enquiries. The [standalone UIKit iOS client](https://github.com/suraj11kasasudhan/ProductCatalogiOS) consumes this backend.

The current product source is **DummyJSON**. Fake Store was originally required, but requests from our Render deployment returned **HTTP 403 Cloudflare browser challenges**, with `cf-mitigated: challenge` and HTML instead of JSON. Browser access worked; changing Render regions did not resolve hosted access. The author approved switching providers while preserving the public API. This is a disclosed departure from the original Fake Store requirement, not a claim that Fake Store is universally unavailable.

## Run locally

Requires Docker Engine/Desktop with Compose and access to Docker Hub, npm, and `dummyjson.com`:

```sh
docker compose up --build
```

The API is published on port 3000. Mailpit captures local email, with its inbox on port 8025 and SMTP on port 1025. Ports are bound to loopback. Mailpit does not deliver to external inboxes and messages are disposable.

```sh
curl http://127.0.0.1:3000/api/health
curl http://127.0.0.1:3000/api/products/featured
curl 'http://127.0.0.1:3000/api/products?q=mascara'
curl -X POST http://127.0.0.1:3000/api/enquiries \
  -H 'Content-Type: application/json' \
  -d '{"productId":1,"name":"Alex","email":"alex@example.test","message":"Is this available?"}'
```

Stop with `docker compose down`. Health checks process availability, not product-source or SMTP readiness.

## Develop and test

Use Node.js 24 (`.nvmrc`) and the checked-in lockfile:

```sh
npm ci
npm run dev
npm run check
npm run build
```

`npm run check` runs Prettier verification, TypeScript checks for source/tests/scripts, and **53 automated tests**. Tests inject product sources, fetchers, clocks, lookup services, mail transports and rate-limit stores; they need neither live DummyJSON nor real SMTP. HTTP tests bind localhost, so run them in an environment that permits local sockets.

`npm start` runs the compiled build. Defaults work without `.env`; copy `.env.example` only when customizing configuration. For native development with local email, start `docker compose up -d mailpit`.

For the separate real-SMTP smoke test:

```sh
docker compose up -d mailpit
npm run smoke
```

The smoke script uses a local DummyJSON-format HTTP fixture, the actual adapter and SMTP transport, and verifies the received recipient, reply-to and message body in Mailpit. It does not test the live provider. `MAILPIT_URL` overrides its default inbox address.

GitHub Actions runs installation, checks and build on pushes to main/the deployment branch and pull requests to main. Check the workflow result for the matching commit; local tests do not prove a remote deployment succeeded.

## API contract

| Method and path                          | Response                                                                             |
| ---------------------------------------- | ------------------------------------------------------------------------------------ |
| `GET /api/health`                        | `{ "status": "ok" }`                                                                 |
| `GET /api/products/featured`             | `{ "products": [...] }`, exactly five configured IDs in selection order              |
| `GET /api/categories`                    | `{ "categories": ["..."] }`, sorted                                                  |
| `GET /api/products?category=...&q=...`   | `{ "products": [...] }`, filters combine with AND                                    |
| `GET /api/categories/:category/products` | `{ "featured": [...], "products": [...] }`, disjoint groups                          |
| `GET /api/products/:id`                  | `{ "product": {...} }`                                                               |
| `POST /api/enquiries`                    | `{ "message": "Thank you. ..." }` only after the sales recipient is accepted by SMTP |

A product contains `id`, `title`, `description`, numeric `price`, `imageUrl`, `category`, and `rating: { value, count }`. DummyJSON thumbnails map to imageUrl; rating.count counts supplied review entries, not an independently reported total. Currency is not invented. Clients should obtain metadata through this API.

Search is literal and case-insensitive within title or description. Empty search returns all products. Unknown category pages or product IDs return 404; searches with no matches return an empty list. Category path components must be URL-encoded. Missing featured IDs return 503 instead of silently shortening the selection.

Enquiries require positive integer `productId`, single-line `name` (1–100 characters), `email` (up to 254 characters), `message` (1–5000 characters), and optional `phone` (3–30 allowed characters). Input is trimmed; unknown fields are rejected. The server controls sender, recipient and subject. Success means SMTP acceptance, not guaranteed final mailbox delivery.

Errors use `{ "error": { "code": "...", "message": "..." } }`. Validation errors also include field paths. Statuses include 400, 404, 413, 415, 429, 502 and 503. Internal errors, credentials, response bodies and customer contact details are not returned or logged.

## Modules and dependency injection

| Module      | Responsibility                                                              |
| ----------- | --------------------------------------------------------------------------- |
| `routes`    | Parse input with shared schemas and translate service results to HTTP       |
| `services`  | Catalogue selection/filtering and enquiry orchestration                     |
| `contracts` | ProductSource, ProductLookup, Mailer, product and contact shapes            |
| `adapters`  | DummyJSON validation/mapping/cache and SMTP delivery                        |
| `app.ts`    | Inject services and optional enquiry rate-limit store; configure middleware |
| `server.ts` | Production dependency composition, listener and graceful shutdown           |

EnquiryService accepts the narrow ProductLookup contract rather than a concrete catalogue class. ProductSource/Mailer keep external providers replaceable. DummyJSONProducts accepts a fetcher and clock; SmtpMailer accepts a transport. `createApp` accepts `enquiryStore` for a compatible shared rate-limit store. No DI framework, database, queue or shared store is installed by default.

## Configuration and deployment

| Variable                   | Default / purpose                                                  |
| -------------------------- | ------------------------------------------------------------------ |
| `PORT`                     | `3000`; hosting platforms can supply their own                     |
| `PRODUCT_API_URL`          | `https://dummyjson.com`; adapter appends `/products?limit=0`       |
| `FEATURED_PRODUCT_IDS`     | `1,2,3,4,5`; five distinct positive IDs                            |
| `CACHE_TTL_MS`             | `60000`; `0` disables retained caching                             |
| `CORS_ORIGIN`              | `http://localhost:5173`; browser client origin, not authentication |
| `SMTP_HOST`, `SMTP_PORT`   | `127.0.0.1`, `1025` for native local development                   |
| `SMTP_SECURE`              | `false`; use `true` for implicit TLS, commonly port 465            |
| `SMTP_USER`, `SMTP_PASS`   | Optional pair; both are required when authentication is configured |
| `MAIL_FROM`, `SALES_EMAIL` | Local `.test` addresses; replace for real delivery                 |

Never commit `.env` or credentials. Set real secrets in your hosting platform. Startup validates configuration. Local Compose deliberately uses Mailpit; deploying only the web-service Dockerfile does not deploy that local inbox.

The author deployed the API at `https://productcatalogbackend-1.onrender.com/api` and confirmed catalogue data after the DummyJSON migration. Render uses Docker, repository-root context, `./Dockerfile`, and health path `/api/health`. Keep `PRODUCT_API_URL=https://dummyjson.com` without `/products`. Render supplies PORT; the server binds to `0.0.0.0`. The configured deployment branch is `feat/catalogue-backend`.

Free Render instances sleep after inactivity and block standard outbound SMTP ports 25, 465 and 587. Browsing can work while enquiries fail. Production email requires a supported hosting/email configuration; SMTP acceptance still does not guarantee final delivery.

## Reliability and scaling boundaries

- Product fetches time out after five seconds. Validated, complete catalogues are cached per process and concurrent cache misses share one request. Expired cache entries are not silently served on failure.
- Helmet, a 16 KB JSON limit, schema validation and an enquiry limit of 10 requests per IP per 15 minutes cover the current public-form workflow.
- The default limiter and cache are process-local and reset on restart. Before running multiple replicas, inject a shared Store into createApp and configure trusted proxies for the actual hosting topology. The injected-store test verifies the seam, not a production Redis deployment.
- Express does not trust forwarded IP headers by default. Review proxy handling before relying on per-client limits behind a load balancer; do not enable blanket trust.
- Enquiries have no persistence or idempotency key. A lost response can lead to duplicate email on manual retry. Durable delivery needs storage plus idempotency/outbox design; it is not supplied by synchronous SMTP.
- DummyJSON is a demo provider and free hosting is not a production availability guarantee. Safe upstream diagnostics distinguish HTTP/schema/timeout failures and Cloudflare challenges without exposing payloads or credentials.

## Development record

The author reports approximately **four hours** for the initial frontend/backend design and implementation combined. **All code was written using AI**, with the author providing requirements, decisions, local feedback and approval. This estimate is author-reported, not a measured time log or proof that subsequent revisions and verification happened within the same window.

See [AGENTS.md](AGENTS.md), [DECISIONS.md](DECISIONS.md), [AI_USAGE.md](AI_USAGE.md), and [PLAN.md](PLAN.md). Automated checks exercise fixtures and injected dependencies; live external mailbox delivery and multi-replica deployment are not claimed as verified.
