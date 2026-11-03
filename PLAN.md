# Backend implementation plan

Approved scope: implement the Node.js backend in this repository on a feature branch, validate it, and commit the changes. The full exercise also needs a frontend.

1. Scaffold Node 24, TypeScript, Express, configuration, lockfile and Docker/Mailpit setup.
2. Add product source contracts and Fake Store mapping, five curated featured products, category grouping, search and product details.
3. Add validated enquiries and replaceable SMTP delivery; return confirmation only after recipient acceptance.
4. Test the critical paths and failure cases. Build the image, start services and inspect an actual delivered Mailpit message.
5. Document setup, API behavior, assumptions, AI usage and limitations. Commit on `feat/catalogue-backend`.

The architecture stays small: routes → services → product/email adapters. No database or paid services are required. Additional features are listed in DECISIONS.md.
