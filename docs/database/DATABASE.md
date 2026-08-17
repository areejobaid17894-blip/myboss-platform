# Database Schema

**Audience:** Backend developers, DBAs, architects  
**Status:** Target is **MySQL 8**. Env keys: **`MYSQL_*`**. **Development and production** share corporate DB `my_boss` on **`10.1.165.105:3308`**. **Preprod (staging)** uses a dedicated DB (fill `MYSQL_*` in `.env.preprod.example` when DBA provides it). Enable with `DB_ENABLED=true` and keep `DB_SYNCHRONIZE=false`. Schema is owned by the corporate DB (this repo does not ship SQL dumps). Keep `MYSQL_CONNECTION_LIMIT=1`.

For API-level auth and roles, see [`../security/SECURITY.md`](../security/SECURITY.md) and [`../architecture/GOVERNANCE.md`](../architecture/GOVERNANCE.md).

---

## 1. Design principles

1. **One database** — The API uses `MYSQL_DATABASE=my_boss` (same host for all stages).
2. **Single source of truth** — No duplicated user, building, or squad snapshot columns.
3. **Real foreign keys** — Cross-table integrity enforced in MySQL (not logical FKs only).
4. **Eligibility + profile unified** — `users` table replaces separate `eligible_participants` + `user_profiles`.
5. **Squad membership authoritative** — `squad_members` is the only place squad assignment is stored; API `squadId` is derived at read time.
6. **OTP sessions ephemeral** — Hashed codes + expiry + attempt counter in `otp_sessions`.
7. **SSO / Maxit OTP** — Development and production use production Maxit; preprod uses preprod APIs. Same MySQL for all stages. See [`../deployment/STAGES.md`](../deployment/STAGES.md).
8. **Small pools** — `MYSQL_CONNECTION_LIMIT=1` to avoid taking the shared DB down.

---

## 2. Architecture

| Layer | Detail |
|-------|--------|
| **Database** | `my_boss` (MySQL 8 — shared across stages; preferred host `10.1.165.105:3308`) |
| **Connection** | `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE=my_boss`, `MYSQL_CONNECTION_LIMIT=1` |
| **TypeORM** | `type: 'mysql'` via `mysql2` (`libs/common` DatabaseModule) |
| **Services** | Single API process registers TypeORM entities against the same DB |
| **DDL** | Corporate MySQL `my_boss` (connection via `MYSQL_*`; no SQL dumps in this repo) |

### Module → table ownership (logical, same DB)

| Module | Primary tables |
|--------|----------------|
| **auth** | `users` (eligibility), `otp_sessions` |
| **users** | `users` (profile), `device_tokens` |
| **config** | `buildings`, `app_config`, `chat_messages` |
| **squads** | `squads`, `squad_members`, `squad_join_requests` |
| **surveys** | `surveys`, `survey_responses`, `gallery_items`, `notifications` |

---

## 3. Duplicates removed (vs old multi-DB design)

| Old duplication | Unified approach |
|-----------------|------------------|
| `eligible_participants` + `user_profiles` (same email/name twice) | Single `users` table |
| `user_profiles.building_name`, `governorate` | Join `buildings` via `building_id` FK |
| `user_profiles.squad_id` | Read from `squad_members` (no denormalized copy) |
| `squad_members.first_name`, `last_name`, `building`, `open_to_travel` | Join `users` + `buildings` at read time |
| `squad_join_requests` name/building snapshots | Join `users` at read time. Rows for a user are **deleted** when that user joins a squad (accept join, accept invite, create squad, or admin assign). |
| `survey_responses.governorate` | Derive from user → building or squad |
| `gallery_items.governorate` | Derive from squad or user |

---

## 4. Entity relationship

```mermaid
erDiagram
    users ||--o{ otp_sessions : "has"
    users }o--o| buildings : "building_id"
    users ||--o{ squad_members : "member"
    users ||--o{ squad_join_requests : "requests"
    squads ||--|{ squad_members : "has"
    squads ||--o{ squad_join_requests : "requests"
    squads ||--o{ survey_responses : "submissions"
    users ||--o{ survey_responses : "submits"
    users ||--o{ chat_messages : "sends"
    users ||--o{ gallery_items : "uploads"
    squads ||--o{ gallery_items : "album"
    notifications ||--|| gallery_items : "announcement"
```

---

## 5. Core tables

### `users` (replaces eligible_participants + user_profiles)

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK — same id across auth and profile |
| email | VARCHAR | UNIQUE — sign-in gate + profile |
| first_name, last_name | VARCHAR | |
| role | VARCHAR | `employee`, `admin`, `super_admin` |
| invited_at | DATETIME | Mass invitation tracking |
| is_active | BOOLEAN | Eligibility gate (auth checks this) |
| onboarding_completed | BOOLEAN | |
| terms_accepted_at | DATETIME | |
| vest_size | VARCHAR | |
| building_id | UUID | FK → buildings |
| open_to_travel | BOOLEAN | |
| preferred_governorates | JSON | |
| profile_edit_count | SMALLINT | Max 3 edits |

**Not stored:** `building_name`, `governorate`, `squad_id` — joined/derived at read time.

### `otp_sessions`

| Column | Type | Notes |
|--------|------|-------|
| user_id | UUID | FK → users (was participant_id) |
| code_hash | VARCHAR | bcrypt/argon2 |
| expires_at | DATETIME | Default 10 minutes |
| attempts | SMALLINT | Lock after 5 failures |

### `squad_members`

| Column | Type | Notes |
|--------|------|-------|
| squad_id | UUID | PK composite, FK → squads |
| user_id | UUID | PK composite, FK → users |
| role | ENUM | `leader`, `member` |

### `chat_messages`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK |
| `conversation_id` | VARCHAR(80) | e.g. `dm:userA:userB` or `support:userId` |
| `sender_id` | UUID | FK → `users` (includes system user `support`) |
| `recipient_id` | UUID | FK → `users` |
| `text` | VARCHAR(2000) | Message body |
| `created_at` | DATETIME | |

**Not stored:** `senderName` — joined from `users` at read time.

### Other tables

Schema for remaining domain tables (`buildings`, `squads`, `squad_join_requests`, surveys, gallery, notifications, device tokens, app config) lives in the corporate `my_boss` database.

---

## 6. Local setup

Use the shared corporate MySQL (`MYSQL_*` in `.env`). Do **not** run a local MariaDB or Redis container for this app.

In `.env`:

```
DB_ENABLED=true
MYSQL_HOST=10.1.165.105
MYSQL_PORT=3308
MYSQL_DATABASE=my_boss
MYSQL_USER=my_boss_app
MYSQL_PASSWORD=FILL_FROM_DBA
```

See [`INSTALL.md`](../INSTALL.md) and [`docker-compose.yml`](../../docker-compose.yml) for the two-container stack (`myboss-api`, `myboss-admin`).

---

## 7. Demo vs production

| Area | Demo today | With DB enabled |
|------|------------|-----------------|
| Storage | In-memory per service | Single `myboss` database |
| User eligibility + profile | Separate in-memory arrays | Single `users` row |
| Squad assignment | Denormalized `squadId` on profile (in-memory) | `squad_members` table only |
| OTP | In-memory plaintext | `otp_sessions` with hashed codes |
| Cross-service sync | HTTP + service token | Same DB — optional HTTP kept for demo compat |

---

## 8. Demo seed accounts

Shared demo identifiers live in `myboss-backend/libs/common/src/demo/demo-seed.constants.ts` (`DEMO_USER_IDS`, `DEMO_SQUAD_IDS`, `DEMO_BUILDING`, `DEMO_EMAILS`). Auth, user, and squad repositories import these so ids stay aligned.

| Email | User id | Onboarding | Squad | Purpose |
|-------|---------|------------|-------|---------|
| demo@orange.com | `4` | ✓ | Orange Amman Squad | Full happy path |
| omar.t@orange.com | `2` | ✓ | **None** | No-squad gating |
| nisreen.a@orange.com | `1` | ✓ | Orange Amman (leader) | Leader flows |
| laila.m@orange.com | `3` | ✗ | None | Onboarding |
| sara.h@orange.com | `leader-irbid` | ✓ | Orange Irbid (leader) | Join/browse other squads |
| khaled.r@orange.com | `leader-zarqa` | ✓ | Orange Zarqa (leader) | Join/browse other squads |
| admin@orange.com | `admin-1` | ✓ | — | Admin console (auth uses separate demo admin entity) |

### Demo data reset

In-memory state mutates during testing. Restore seed data with:

Shared MySQL is the source of truth. Restart the API container if you need a clean boot; do not run a local MariaDB.

| Module | Reset on restart | Notes |
|--------|------------------|-------|
| auth | ✅ `AuthRepository.resetDemoSeed()` | Eligible users in `users` when DB enabled |
| users | ✅ `UsersRepository.resetDemoSeed()` | Profiles in shared `users` table |
| squads | ✅ `SquadsRepository.resetDemoSeed()` | Squads, members, join requests |
| config | ❌ | Admin config changes persist until restart |
| surveys | ⚠️ partial | Survey catalog/responses re-seed on boot; gallery/notifications may persist on disk |

---

## Related documentation

| Document | Purpose |
|----------|---------|
| [`../architecture/GOVERNANCE.md`](../architecture/GOVERNANCE.md) | API errors, roles |
| [`../api/API_OVERVIEW.md`](../api/API_OVERVIEW.md) | REST endpoints |
| [`../devops/DEVOPS.md`](../devops/DEVOPS.md) | Deploy & infrastructure |

---

*Orange — my boss app — Database*
