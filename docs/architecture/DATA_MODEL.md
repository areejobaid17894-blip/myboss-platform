# Data model

> **Canonical schema:** [`../database/DATABASE.md`](../database/DATABASE.md)

This file is a **redirect stub**. All table definitions, relationships, demo seed IDs, and reset instructions are maintained in one place:

**[`docs/database/DATABASE.md`](../database/DATABASE.md)**

That guide includes:

- **Single shared database** — all microservices use `MARIADB_DATABASE=myboss`
- Service ownership per table (auth, user, config, squad, survey)
- Unified `users` table (auth eligibility + employee profile — no duplicates)
- Full column definitions including `terms_accepted_at`
- Entity relationship diagram
- Demo vs production storage model
- Shared seed constants (`@myboss/common/demo/demo-seed.constants.ts`)
- `reset-demo-data.sh` usage

Do not duplicate schema content here — update `DATABASE.md` instead.

---

*Orange — my boss app*
