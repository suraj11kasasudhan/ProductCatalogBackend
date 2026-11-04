# Backend maintenance plan

The backend is merged into main. Render currently deploys feat/catalogue-backend. The iOS client lives independently in ProductCatalogiOS.

1. Preserve the public API and small routes → services → contracts/adapters structure.
2. Keep provider behavior behind ProductSource, ProductLookup and Mailer; use injected infrastructure in tests.
3. Validate changes with formatting, source/test/script type checks, automated tests and the production build. Run Mailpit smoke testing separately when SMTP integration needs verification.
4. Keep setup, provider migration, AI attribution and production limitations accurate in README.md, DECISIONS.md, AI_USAGE.md and AGENTS.md.
5. Add shared rate limiting/proxy configuration, durable enquiries and idempotency only when a deployment requires them. Do not claim these follow-ups are already deployed.
