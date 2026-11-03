# Product catalogue backend

Node.js 24 + TypeScript + Express backend for the AI-Native Engineer challenge. It provides catalogue browsing, five curated featured products, category groups, search, product details, and enquiry emails. Product data always passes through this backend.

This repository implements the **backend only**. A React web client is the intended consumer; no frontend is included. The full challenge still needs a client before submission.

## Run locally

Requires Docker Engine/Desktop with Compose and Internet access to Docker Hub, npm and `fakestoreapi.com`. No accounts or paid services are required.

```sh
docker compose up --build
```

The API listens on port 3000. Mailpit captures emails locally; its inbox UI uses port 8025. SMTP uses port 1025. All published ports bind to loopback. The first build downloads dependencies; allow a few minutes. Stop with `docker compose down`. Mailpit messages are disposable and not persisted across container replacement.

```sh
curl http://127.0.0.1:3000/api/health
curl http://127.0.0.1:3000/api/products/featured
curl 'http://127.0.0.1:3000/api/products?q=shirt'
curl -X POST http://127.0.0.1:3000/api/enquiries \
  -H 'Content-Type: application/json' \
  -d '{"productId":1,"name":"Alex","email":"alex@example.test","message":"Is this available?"}'
```

The enquiry response contains a thank-you message only when SMTP accepts the sales recipient. Inspect the Mailpit inbox to see the message. Local Mailpit does **not** deliver to an external mailbox.

## Develop and test

Requires Node.js 24 and npm. `.nvmrc` specifies the Node major.

```sh
npm ci
npm run dev
```

Defaults work without `.env`. Copy `.env.example` to `.env` to customize. For local SMTP, start `docker compose up -d mailpit` in another terminal.

```sh
npm run check # formatting, typecheck (including tests/scripts), and 46 tests
npm test
npm run build
npm start
```

`npm test` runs 46 deterministic tests without Internet access or SMTP. To test actual SMTP delivery:

```sh
docker compose up -d mailpit
npm run smoke
```

The smoke test uses a temporary local HTTP product source and the real SMTP adapter, then checks the received message's body, recipient and reply-to address through Mailpit's API. It does not validate live DummyJSON availability. `MAILPIT_URL` overrides its default `http://127.0.0.1:8025` inbox API.

Formatting is standardized with Prettier: `npm run format` applies it and `npm run format:check` verifies it. GitHub Actions runs the same checks and the build for pull requests into main. The workflow has been added; its remote execution must be checked in the PR.

## API

| Method/path                              | Response                                                                              |
| ---------------------------------------- | ------------------------------------------------------------------------------------- |
| `GET /api/health`                        | `{ "status": "ok" }`; process health, not dependency readiness                        |
| `GET /api/products/featured`             | `{ "products": [...] }`; exactly the configured five, in configured order             |
| `GET /api/categories`                    | `{ "categories": ["..."] }`; sorted names                                             |
| `GET /api/products?category=...&q=...`   | `{ "products": [...] }`; filters combine with AND                                     |
| `GET /api/categories/:category/products` | `{ "featured": [...], "products": [...] }`; additional products exclude featured ones |
| `GET /api/products/:id`                  | `{ "product": {...} }`                                                                |
| `POST /api/enquiries`                    | `{ "message": "Thank you. ..." }` after SMTP acceptance                               |

URL-encode category names in paths. Unknown category pages and product IDs return 404. Empty searches return all products; no matches return an empty list. Search matches title or description, case-insensitively. A category query with no matching products returns an empty list.

A product has `id`, `title`, `description`, `price`, `imageUrl`, `category`, and `rating: { value, count }`. Price is the source's numeric amount; currency conversion is outside scope. Clients should render strings as text and use the backend API base URL rather than DummyJSON endpoints.

Enquiries accept `productId` (positive integer), `name` (1–100 characters), `email`, `message` (1–5000 characters), and optional `phone` (3–30 characters). Unknown fields are rejected. Contact details are trimmed. Recipients and email subject are controlled by the server.

Errors use `{ "error": { "code": "...", "message": "..." } }`; validation errors also include field paths. Status codes include 400 invalid input, 404 missing resource, 413 oversized body, 415 unsupported encoding/charset, 429 enquiry rate limit, 502 upstream/SMTP failure, and 503 unavailable featured selection. No raw upstream errors or enquiry contents are logged.

## Configuration

See `.env.example`. Server startup validates configuration. Never commit `.env` or real credentials.

| Variable                   | Default / meaning                                                          |
| -------------------------- | -------------------------------------------------------------------------- |
| `PORT`                     | `3000`                                                                     |
| `PRODUCT_API_URL`          | `https://dummyjson.com`; adapter appends `/products?limit=0`               |
| `FEATURED_PRODUCT_IDS`     | `1,2,3,4,5`; five distinct positive IDs                                    |
| `CACHE_TTL_MS`             | `60000`; process-local product cache, `0` disables retention               |
| `CORS_ORIGIN`              | `http://localhost:5173`; intended React dev origin                         |
| `SMTP_HOST`, `SMTP_PORT`   | `127.0.0.1`, `1025` for host development                                   |
| `SMTP_SECURE`              | `false`; use `true` for an implicit TLS SMTP endpoint (typically port 465) |
| `SMTP_USER`, `SMTP_PASS`   | Optional; provide both when authentication is required                     |
| `MAIL_FROM`, `SALES_EMAIL` | `catalogue@example.test`, `sales@example.test`                             |

Compose deliberately configures local Mailpit. For a real sales inbox, run the backend with your SMTP provider's settings, verified sender, and recipient. SMTP acceptance cannot guarantee final mailbox delivery. Enquiries are not stored and retries can send duplicates if an earlier response was lost.

## Structure and boundaries

`routes` validate HTTP input using shared schemas in `routes/schemas.ts`; `services` implement catalogue/enquiry behavior; `adapters` contain DummyJSON and SMTP details; `contracts` define the internal product and mail interfaces. `app.ts` is dependency-injected for testing; `server.ts` wires production dependencies and handles shutdown.

The catalogue has a five-second source timeout, validated upstream responses, a short cache, and coalesced concurrent loads. Expired cache entries are not served on failure. Email connections and sends have timeouts. Helmet, a 16 KB JSON body limit, and a process-local enquiry limit (10 requests per IP per 15 minutes) provide basic safeguards.

Express does not trust proxy headers by default. When deploying behind a known AWS load balancer, explicitly configure trusted proxy hops and use a shared limiter for multiple replicas. No infrastructure is provisioned; the container can run on AWS container services. CORS is a browser policy, not authentication.

## Validation in this cloud session

TypeScript build/typecheck and all 35 tests passed. The Docker image built with TLS verification enabled; API health and real Mailpit delivery passed. Live Fake Store calls returned a cloud proxy policy denial, surfaced by the API as 502. An allowlist addition for `fakestoreapi.com` was saved in the environment draft; live-source behavior remains unverified until access is enabled. No fake catalogue is used as a production fallback.

See [DECISIONS.md](DECISIONS.md), [AI_USAGE.md](AI_USAGE.md), and [PLAN.md](PLAN.md) for scope, reasoning and work history.

## Render migration from Fake Store

This branch now uses DummyJSON because Fake Store returned Cloudflare browser challenges to the deployed backend. In Render → Environment, change the existing `PRODUCT_API_URL` to `https://dummyjson.com` (without `/products`), save and redeploy. Existing environment overrides take precedence over the new default. No iOS endpoint or response-schema change is required. Verify `/api/products/featured`, `/api/categories`, `/api/products?q=mascara`, and a product detail after deployment. Health alone does not verify upstream access.

The adapter requests `/products?limit=0` to load all products for local search and category grouping. DummyJSON supplies a numeric rating; the returned `rating.count` counts the review entries supplied with each product. Featured IDs 1–5 remain the default; product identities, categories and content change with the provider. SMTP configuration is independent and still required for enquiries.

The source change is validated by deterministic tests; live DummyJSON access from Render must still be verified after deployment. Historical validation notes above describe earlier sessions, not proof of the new provider's availability.
