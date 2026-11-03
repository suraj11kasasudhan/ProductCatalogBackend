# AI usage

## Tools and responsibility

Work was planned and implemented with OpenAI Codex through this chat, using the GPT-6-based assistant available in the session. The precise model variant was not exposed. Tools included shell execution, npm, TypeScript, Vitest, Supertest, Docker Compose and local HTTP/SMTP checks. No parallel agents were used. No agent instruction files were added to this repository.

The assistant read the supplied challenge PDF, inspected the initially README-only repository, proposed the plan, and generated the implementation, tests and documentation. Human review and ownership of every line are still required before submitting the challenge.

## Prompts and moments that shaped the work

1. The user requested a Node.js backend plan before making changes. This led to the explicit boundaries and API plan in PLAN.md.
2. The user's approval to implement step by step led to a feature branch and staged implementation, rather than a direct change to main.
3. The challenge's expectation that data source and email provider will change led to ProductSource and Mailer contracts, without introducing a generic repository framework.
4. The ambiguity in “top rated” was resolved using the phrase “I have chosen 5”: explicitly configured selection, recorded in DECISIONS.md.
5. The requirement for an inspectable, free local flow led to Mailpit and a smoke check that verifies an actual received email.

## Mistakes and corrections

- The first cloud Docker build omitted the session CA mount. npm correctly rejected the proxy certificate chain. A build-secret CA mount and a runtime read-only CA mount fixed the cloud build; TLS verification stayed enabled.
- Initial host SMTP configuration used localhost. The smoke test failed, and a focused connection check identified a localhost DNS timeout. Using 127.0.0.1 resolved the failure, and the smoke test then verified the received recipient, reply-to and body.
- Installed Node types initially targeted a newer major. They were aligned to the selected Node 24 runtime before final validation.

## Review and evidence

Review focused on input validation, deterministic featured selection, category duplicates, source-schema isolation, SMTP failure behavior, secret handling and truthful success responses. TypeScript build/typecheck, 27 automated tests, Docker startup, and an actual Mailpit message were checked. Live Fake Store access was blocked by the cloud network policy and was not counted as passing. The API reports an upstream failure instead of silently inventing data.

## Time spent

Timing is approximate active assistant execution, excluding earlier cloud provisioning and the wait for user approval. This implementation session was roughly 15 minutes: planning/re-reading 1 minute, implementation 4 minutes, build/test/environment diagnosis 6 minutes, and review/documentation/commits 4 minutes. These are estimates, not a human candidate's time log; the submitter should add their actual review and frontend work before submitting.
